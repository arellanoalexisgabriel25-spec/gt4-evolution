extends SceneTree

const Run = preload("res://scripts/drag_run.gd")
const Duel = preload("res://scripts/drag_duel.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func pair(index: float = 0.0, limit: float = 125.0, rules_profile: String = "legacy_practice") -> Dictionary:
    var player = Run.new()
    var rival = Run.new()
    player.arm(0,0)
    rival.arm(0,0)
    var duel = Duel.new()
    if not duel.begin(player,rival,index,limit,rules_profile):
        push_error("Test fixture could not begin")
        failed = true
    return {"player":player,"rival":rival,"duel":duel}

# Advance actual beam models on one shared clock, rather than fabricating times.
func run_pair(player_wait: float, rival_wait: float, player_speed: float = 20.0, rival_speed: float = 20.0, index: float = 0.0, rules_profile: String = "legacy_practice") -> Dictionary:
    var race := pair(index,125.0,rules_profile)
    var clock := 0.0
    var positions := Vector2.ZERO
    for i in range(5000):
        var delta := 0.01
        clock += delta
        if clock>=player_wait: positions.x += player_speed*delta
        if clock>=rival_wait: positions.y += rival_speed*delta
        race.player.advance(delta,positions.x,player_speed if clock>=player_wait else 0.0)
        race.rival.advance(delta,positions.y,rival_speed if clock>=rival_wait else 0.0)
        race.duel.advance(delta)
        if race.duel.finished: break
    return race

func _initialize() -> void:
    var invalid = Duel.new()
    check(not invalid.begin(null,null),"Missing lanes cannot start a race")
    var same = Run.new()
    same.arm(0,0)
    check(not invalid.begin(same,same),"A car cannot race against the same timer instance")
    var unstaged = Run.new()
    check(not invalid.begin(same,unstaged),"Both physical lanes must be staged and armed")
    unstaged.arm(0,0)
    unstaged.clock=0.2
    check(not invalid.begin(same,unstaged),"The common tree cannot be attached after one lane's clock advances")
    unstaged.clock=0.0
    check(not invalid.begin(same,unstaged,NAN) and not invalid.begin(same,unstaged,0,INF),"Non-finite competition configuration is rejected atomically")
    check(not invalid.started and invalid.report().is_empty(),"Rejected starts leave no partial race or result")
    var equal_cars := run_pair(2.25,2.75)
    check(equal_cars.duel.finished and equal_cars.duel.report().winner=="player","The better reaction wins between equally fast cars")
    var report: Dictionary = equal_cars.duel.report()
    check(absf(float(report.entries.player.ticket.et)-float(report.entries.rival.ticket.et))<0.00001,"Equal-speed measured passes retain equal ET independently of reaction")
    check(absf(float(report.margin_s)-0.5)<0.011,"Winning margin follows measured arrival difference from the common green")
    var holeshot := run_pair(3.0,2.10,21.0,20.5)
    var holeshot_report: Dictionary = holeshot.duel.report()
    check(holeshot_report.entries.player.ticket.et<holeshot_report.entries.rival.ticket.et and holeshot_report.winner=="rival","A faster ET loses when late reaction puts its actual arrival behind the opponent")
    var tie := run_pair(2.25,2.25)
    check(tie.duel.report().outcome=="tie" and tie.duel.report().winner.is_empty(),"An actual simultaneous arrival does not arbitrarily favor the player")
    report.entries.player.ticket.et=1.0
    report.winner="rival"
    check(equal_cars.duel.report().winner=="player" and equal_cars.duel.report().entries.player.ticket.et>10,"Consumers cannot mutate the frozen result or nested timing tickets")
    var frozen: Dictionary = equal_cars.duel.report()
    equal_cars.player.elapsed=1.0
    equal_cars.player.reason="CHANGED"
    equal_cars.duel.advance(1000)
    check(equal_cars.duel.report()==frozen and not equal_cars.duel.begin(same,unstaged),"Late callbacks and duplicate starts cannot replace an adjudicated result")
    var red := run_pair(1.0,2.25)
    check(red.duel.report().winner=="rival" and red.duel.report().entries.player.status=="invalid" and red.duel.report().entries.player.reason=="LARGADA EN FALSO","A measured false start loses to the opponent's valid finish")
    var both_red := run_pair(1.0,1.0)
    check(both_red.duel.report().outcome=="no_winner" and both_red.duel.report().winner.is_empty(),"Two invalid starts cannot generate a fabricated victory")
    var lane := pair()
    lane.player.advance(0.1,0,0,false)
    lane.rival.invalidate("FUERA DE CARRIL")
    lane.duel.advance(0.1)
    check(lane.duel.report().outcome=="no_winner" and lane.duel.report().entries.player.reason=="FUERA DE CARRIL","Lane infringements are preserved as explicit failures")
    var timeout := pair(0,0.5)
    timeout.duel.advance(0.49)
    check(not timeout.duel.finished and timeout.duel.report().is_empty(),"An unfinished race remains pending until its deadline")
    timeout.duel.advance(0.01)
    check(timeout.duel.finished and timeout.duel.report().outcome=="no_winner" and timeout.duel.report().entries.rival.status=="timeout","A deadline closes both uncompleted lanes without inventing times")
    check(timeout.duel.report().entries.player.ticket.is_empty(),"Timeouts do not carry a fake finish ticket")
    var solo_finish := pair(0,24.0)
    var clock := 0.0
    var position := 0.0
    for i in range(2500):
        clock += 0.01
        if clock>=2.25: position += 0.2
        solo_finish.player.advance(0.01,position,20.0 if clock>=2.25 else 0.0)
        solo_finish.rival.advance(0.01,0,0)
        solo_finish.duel.advance(0.01)
        if solo_finish.duel.finished: break
    check(solo_finish.duel.report().winner=="player" and solo_finish.duel.report().entries.rival.status=="timeout","A real valid finisher defeats an opponent that never completes the course")
    check(solo_finish.duel.report().entries.player.ticket.et>20 and solo_finish.duel.report().entries.rival.ticket.is_empty(),"The deadline preserves the valid measured ticket and leaves no fake opponent time")
    var paused := pair()
    paused.duel.advance(0)
    paused.duel.advance(NAN)
    check(not paused.duel.finished and paused.duel.entries().player.status=="pending","Zero or malformed delta cannot advance adjudication")
    paused.player.advance(0.2,0,0)
    paused.rival.advance(0.1,0,0)
    paused.duel.advance(0.2)
    check(paused.duel.report().outcome=="no_winner" and paused.duel.report().entries.player.reason=="ÁRBOL DESINCRONIZADO","Asynchronous live trees are rejected instead of comparing incomparable arrivals")
    var indexed := run_pair(2.25,2.25,21.0,20.0,19.5)
    check(indexed.duel.report().winner=="rival" and indexed.duel.report().entries.player.status=="breakout","An explicitly configured practice floor disqualifies an under-index ET")
    check(indexed.duel.report().ruleset=="indexed_practice" and indexed.duel.report().minimum_et==19.5,"A game index is labelled practice rather than an invented official category")
    var double_breakout := run_pair(2.25,2.25,21.0,22.0,25.0)
    check(double_breakout.duel.report().outcome=="no_winner","Without verified double-breakout rules, neither invalid indexed pass is declared the winner")
    var corrupt := pair()
    corrupt.player.phase="finished"
    corrupt.rival.invalidate("ABANDONO")
    corrupt.duel.advance(0.1)
    check(corrupt.duel.report().outcome=="no_winner" and corrupt.duel.report().entries.player.reason=="TICKET INVÁLIDO","A terminal flag without a valid measured ticket cannot manufacture victory")
    var reset_lane := pair()
    reset_lane.player.phase="preparation"
    reset_lane.rival.invalidate("ABANDONO")
    reset_lane.duel.advance(0.01)
    check(reset_lane.duel.report().outcome=="no_winner" and reset_lane.duel.report().entries.player.reason=="CRONOMETRAJE REINICIADO","Resetting a timer during a race is an explicit invalid result")
    check(not invalid.begin(same,unstaged,0,123,"unknown") and not invalid.started,"Unknown rules profiles are rejected before binding either lane")
    var legacy_red_breakout := run_pair(1.0,2.25,20.0,21.0,19.5)
    check(legacy_red_breakout.duel.report().outcome=="no_winner" and legacy_red_breakout.duel.report().rules_profile=="legacy_practice","Existing practice calls retain the old false-start versus breakout behavior")
    var arg_red_breakout := run_pair(1.0,2.25,20.0,21.0,19.5,"argentina_reference")
    var arg_report: Dictionary = arg_red_breakout.duel.report()
    check(arg_report.winner=="rival" and arg_report.exception=="art12_single_false_start","Supplied Art.12 awards the measured non-red finisher even when its ET falls below the class floor")
    check(arg_report.entries.rival.status=="breakout" and arg_report.entries.rival.index_exempt and arg_report.entries.rival.ticket.et<19.5,"The exception preserves the actual under-index ticket instead of rewriting ET or hiding the breakout")
    check(arg_red_breakout.rival.phase=="finished" and arg_red_breakout.player.reason=="LARGADA EN FALSO","The Art.12 case comes from actual interpolated timing sensors")
    check(arg_report.ruleset=="argentina_reference" and arg_report.source_status=="user_supplied_reference_not_live" and arg_report.rules_source_sha256.length()==64,"Results identify the supplied reference and never claim live official verification")
    check(arg_report.distance_m==402.336 and arg_report.entries.rival.ticket.distance==402.336,"The source's rounded 402 m wording does not alter the persistent quarter-mile course")
    var arg_player_exempt := run_pair(2.25,1.0,21.0,20.0,19.5,"argentina_reference")
    check(arg_player_exempt.duel.report().winner=="player" and arg_player_exempt.duel.report().entries.player.index_exempt,"Art.12 applies symmetrically when the player is the under-index finisher")
    var arg_single_red := run_pair(1.0,2.25,20.0,20.0,19.5,"argentina_reference")
    check(arg_single_red.duel.report().winner=="rival" and not arg_single_red.duel.report().entries.rival.index_exempt,"A legal above-floor finisher also wins a single-red race without fabricating an index violation")
    var arg_both_red := run_pair(1.0,1.0,20.0,20.0,19.5,"argentina_reference")
    check(arg_both_red.duel.report().outcome=="no_winner" and arg_both_red.duel.report().reason=="AMBOS ADELANTADOS · ART.12","Both red lights eliminate both racers in a normal round")
    check(arg_both_red.duel.report().competition_scope=="single_normal_round" and not invalid.begin(same,unstaged,0,123,"argentina_final"),"Final reruns, championship brackets and prize rules are outside this normal-round profile")
    var arg_double_breakout := run_pair(2.25,2.25,21.0,22.0,25.0,"argentina_reference")
    check(arg_double_breakout.duel.report().outcome=="no_winner" and arg_double_breakout.duel.report().reason=="AMBOS CAÍDOS DE TIEMPO · ART.20","Two below-floor passes leave the normal round without a winner")
    var arg_lane := pair(19.5,125,"argentina_reference")
    arg_lane.player.advance(1.0,0,0)
    arg_lane.rival.advance(1.0,0,0)
    arg_lane.duel.advance(1.0)
    arg_lane.player.advance(0.1,0.3,3)
    arg_lane.rival.advance(0.1,0,0,false)
    arg_lane.duel.advance(0.1)
    check(arg_lane.duel.report().outcome=="no_winner" and arg_lane.duel.report().exception.is_empty(),"Art.12 does not waive an opponent's independently measured lane infringement")
    var arg_no_finish := pair(19.5,3.0,"argentina_reference")
    var no_finish_position := 0.0
    for i in range(301):
        if i>=100: no_finish_position+=0.03
        arg_no_finish.player.advance(0.01,no_finish_position,3.0 if i>=100 else 0.0)
        arg_no_finish.rival.advance(0.01,0,0)
        arg_no_finish.duel.advance(0.01)
        if arg_no_finish.duel.finished: break
    check(arg_no_finish.player.reason=="LARGADA EN FALSO" and arg_no_finish.duel.report().outcome=="no_winner" and arg_no_finish.duel.report().entries.rival.status=="timeout","A sole red light cannot invent a finish for an opponent that never completes the course")
    var boundary_measurement := run_pair(2.25,2.25)
    var measured_et: float = boundary_measurement.duel.report().entries.player.ticket.et
    var arg_boundary := run_pair(2.25,2.25,20.0,20.0,measured_et,"argentina_reference")
    check(arg_boundary.duel.report().outcome=="tie" and arg_boundary.duel.report().entries.player.status=="finished","ET exactly at the class floor is legal under the supplied strict comparison")
    var arg_just_below := run_pair(2.25,2.25,20.0,20.0,measured_et+0.0000005,"argentina_reference")
    var legacy_just_below := run_pair(2.25,2.25,20.0,20.0,measured_et+0.0000005)
    check(arg_just_below.duel.report().entries.player.status=="breakout" and legacy_just_below.duel.report().entries.player.status=="finished","Only legacy practice retains the former one-microsecond class-floor allowance")
    var arg_holeshot := run_pair(3.0,2.10,21.0,20.5,18.0,"argentina_reference")
    check(arg_holeshot.duel.report().winner=="rival" and arg_holeshot.duel.report().entries.player.ticket.et<arg_holeshot.duel.report().entries.rival.ticket.et,"Two legal class passes are still decided by measured arrival from the common green")
    if not failed: print("PASS: %d drag duel assertions" % checks)
    quit(1 if failed else 0)
