extends RefCounted

# Pure adjudication of two independently measured lanes. DragRun owns each
# vehicle's beams and interpolation; the duel never moves cars, changes tickets,
# awards money or writes progress. Both runs must arm on the same tree clock.
const Run = preload("res://scripts/drag_run.gd")
const Records = preload("res://scripts/drag_records.gd")
const TIE_TOLERANCE := 0.001 # display/timing resolution, seconds
const CLOCK_TOLERANCE := 0.000001
const TERMINAL := ["finished","invalid","timeout","breakout"]
const RULES_PROFILES := ["legacy_practice","argentina_reference"]
const SPORT_REFERENCE := "Reglamento deportivo aportado por el usuario · Texto pegado.txt · arts. 7, 12, 13, 20 y 21"
const SPORT_REFERENCE_SHA256 := "46b13eb02fac46a50381509129a82a2eaa623754d7d0bd262d35e5c9cc089acc"
var _runs: Dictionary = {}
var _entries: Dictionary = {}
var _result: Dictionary = {}
var _elapsed := 0.0
var _minimum_et := 0.0
var _time_limit := 123.0
var _rules_profile := "legacy_practice"
var started: bool:
    get: return not _runs.is_empty()
var finished: bool:
    get: return not _result.is_empty()

# Default calls preserve the original practice rules. argentina_reference applies
# the supplied sports text to one normal round, not a live/complete championship.
# Class lookup and entry validation belong to the caller. The source's rounded
# "402 metros" description does not change DragRun's persistent 402.336 m course.
# A fresh duel is required for the next race, preventing accidental result resets.
func begin(player_run, rival_run, minimum_et: float = 0.0, time_limit: float = 123.0, rules_profile: String = "legacy_practice") -> bool:
    if started or not RULES_PROFILES.has(rules_profile) or not is_finite(minimum_et) or minimum_et<0.0 or not is_finite(time_limit) or time_limit<=0.0:
        return false
    if not (player_run is RefCounted) or not (rival_run is RefCounted) or player_run==rival_run:
        return false
    if player_run.get_script()!=Run or rival_run.get_script()!=Run:
        return false
    if player_run.phase!="countdown" or rival_run.phase!="countdown":
        return false
    if not is_finite(player_run.clock) or not is_finite(rival_run.clock) or absf(player_run.clock-rival_run.clock)>CLOCK_TOLERANCE:
        return false
    if absf(player_run.clock)>CLOCK_TOLERANCE:
        return false
    _runs = {"player":player_run,"rival":rival_run}
    _entries = {"player":_pending(),"rival":_pending()}
    _minimum_et = minimum_et
    _time_limit = time_limit
    _rules_profile = rules_profile
    return true

func _pending() -> Dictionary:
    return {"status":"pending","reason":"","ticket":{}}

func _fault(status: String, reason: String) -> Dictionary:
    return {"status":status,"reason":reason,"ticket":{}}

func _observe(run) -> Dictionary:
    if not is_finite(run.clock):
        return _fault("invalid","RELOJ INVÁLIDO")
    if run.phase=="invalid":
        return _fault("invalid",str(run.reason))
    if run.phase=="finished":
        var ticket: Dictionary = run.report()
        if not Records.valid_ticket(ticket):
            return _fault("invalid","TICKET INVÁLIDO")
        var normalized: Dictionary = Records.normalized(ticket)
        # Art.20 says strictly below the class floor. Keep the old epsilon only
        # for legacy practice, where existing callers already rely on it.
        var floor := _minimum_et if _rules_profile=="argentina_reference" else _minimum_et-CLOCK_TOLERANCE
        if _minimum_et>0.0 and float(normalized["et"])<floor:
            var reason := "CAÍDA DEL TIEMPO DE CLASE · ART.20" if _rules_profile=="argentina_reference" else "BAJO EL ÍNDICE DE PRÁCTICA"
            return {"status":"breakout","reason":reason,"ticket":normalized}
        return {"status":"finished","reason":"","ticket":normalized}
    if run.phase not in ["countdown","running"]:
        return _fault("invalid","CRONOMETRAJE REINICIADO")
    return _pending()

# Call once per unpaused physics step, AFTER advancing both physical DragRuns.
# Resolution waits for both terminal states, allowing a complete two-car ticket.
# The deadline closes an unfinished lane explicitly; it never invents its time.
func advance(delta: float) -> void:
    if not started or finished or not is_finite(delta) or delta<=0.0:
        return
    _elapsed = minf(_elapsed+delta,_time_limit)
    for id in ["player","rival"]:
        if not TERMINAL.has(_entries[id]["status"]):
            _entries[id] = _observe(_runs[id])
    if _entries["player"]["status"]=="pending" and _entries["rival"]["status"]=="pending":
        if absf(_runs["player"].clock-_runs["rival"].clock)>CLOCK_TOLERANCE:
            _entries["player"] = _fault("invalid","ÁRBOL DESINCRONIZADO")
            _entries["rival"] = _fault("invalid","ÁRBOL DESINCRONIZADO")
    if _elapsed>=_time_limit:
        for id in ["player","rival"]:
            if _entries[id]["status"]=="pending":
                _entries[id] = _fault("timeout","TIEMPO MÁXIMO AGOTADO")
    if TERMINAL.has(_entries["player"]["status"]) and TERMINAL.has(_entries["rival"]["status"]):
        _resolve()

func _resolve() -> void:
    var player_valid: bool = _entries["player"]["status"]=="finished"
    var rival_valid: bool = _entries["rival"]["status"]=="finished"
    var winner := ""
    var outcome := "no_winner"
    var reason := "AMBOS CORREDORES SIN LLEGADA VÁLIDA"
    var margin := 0.0
    var exception := ""
    if _rules_profile=="argentina_reference":
        var player_false := _false_start("player")
        var rival_false := _false_start("rival")
        if player_false!=rival_false:
            var other := "rival" if player_false else "player"
            # Art.12: the sole non-red-light competitor wins regardless of ET.
            # Art.7 still requires a measured finish by the car's own means in
            # its lane. Do not infer an unrecorded finish, waive lane invasion,
            # or invent a result for a broken car from the phrase "automáticamente".
            if _entries[other]["status"] in ["finished","breakout"]:
                exception = "art12_single_false_start"
                _entries[other]["index_exempt"] = _entries[other]["status"]=="breakout"
                player_valid = other=="player"
                rival_valid = other=="rival"
        elif player_false and rival_false:
            reason = "AMBOS ADELANTADOS · ART.12"
        elif _entries["player"]["status"]=="breakout" and _entries["rival"]["status"]=="breakout":
            reason = "AMBOS CAÍDOS DE TIEMPO · ART.20"
    if player_valid and rival_valid:
        # Total is ET + reaction from the same green. Fastest ET alone is not
        # enough to win if the other driver reacted and crossed earlier.
        var difference: float = float(_entries["player"]["ticket"]["total"])-float(_entries["rival"]["ticket"]["total"])
        margin = absf(difference)
        if margin<=TIE_TOLERANCE:
            outcome = "tie"
            reason = "EMPATE EN LA RESOLUCIÓN DE CRONOMETRAJE"
        else:
            winner = "player" if difference<0.0 else "rival"
            outcome = "win"
            reason = "PRIMERA LLEGADA VÁLIDA"
    elif player_valid or rival_valid:
        winner = "player" if player_valid else "rival"
        outcome = "win"
        reason = "VICTORIA POR ADELANTAMIENTO DEL RIVAL · ART.12" if not exception.is_empty() else "ÚNICA LLEGADA VÁLIDA"
    var reference := _rules_profile=="argentina_reference"
    _result = {
        "winner":winner,"outcome":outcome,"reason":reason,"margin_s":margin,
        "elapsed":_elapsed,"minimum_et":_minimum_et,"distance_m":Run.DISTANCE,
        "ruleset":"argentina_reference" if reference else ("heads_up" if _minimum_et==0.0 else "indexed_practice"),
        "rules_profile":_rules_profile,
        "rules_source":SPORT_REFERENCE if reference else "GT4 Evolution · reglas propias de práctica",
        "rules_source_url":"http://cuartodemilla.com.ar/" if reference else "",
        "rules_source_sha256":SPORT_REFERENCE_SHA256 if reference else "",
        "source_status":"user_supplied_reference_not_live" if reference else "game_rules_not_official",
        "competition_scope":"single_normal_round" if reference else "practice_duel",
        "exception":exception,"entries":_entries.duplicate(true)
    }

func _false_start(id: String) -> bool:
    return _entries[id]["status"]=="invalid" and _entries[id]["reason"]=="LARGADA EN FALSO"

# Deep copies keep HUD/career consumers from mutating an adjudicated result.
func report() -> Dictionary:
    return _result.duplicate(true)

func entries() -> Dictionary:
    return _entries.duplicate(true)
