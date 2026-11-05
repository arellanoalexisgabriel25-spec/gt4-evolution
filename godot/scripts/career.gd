extends RefCounted
class_name EvolutionCareer

const Tuning = preload("res://scripts/tuning.gd")
const Money = preload("res://scripts/money.gd")
const Rivals = preload("res://scripts/rivals.gd")
const LapRecords = preload("res://scripts/lap_records.gd")
const DragRecords = preload("res://scripts/drag_records.gd")

# Legacy event simulation and validated results from the physical race module.
# Each event pays only once. Licenses depend on achievements, not cash.
const EVENTS := [
    {"id":"debut", "name":"Copa de Debutantes", "license":"R", "fee":120, "distance":12, "target":62.0, "rewards":[700, 400, 200]},
    {"id":"local", "name":"Sprint del Club Local", "license":"R", "fee":180, "distance":18, "target":69.0, "rewards":[850, 500, 250]},
    {"id":"regional", "name":"Turismos Regionales", "license":"B", "fee":380, "distance":32, "target":76.0, "rewards":[1650, 900, 450]},
    {"id":"endurance", "name":"Desafío de Resistencia", "license":"B", "fee":500, "distance":60, "target":81.0, "rewards":[2300, 1200, 600]},
    {"id":"national", "name":"Copa Nacional", "license":"A", "fee":900, "distance":90, "target":87.0, "rewards":[4200, 2200, 900]}
]
const LICENSE_LEVELS := {"R":0, "B":1, "A":2}

var license: String = "R"
var reputation: int = 0
var completed: Array[String] = []
var results: Array[Dictionary] = []
var rivalries: Dictionary = {}
var lap_records = LapRecords.new()
var drag_records = DragRecords.new()
var stock_drag_records = DragRecords.new()
var _track_entry: Dictionary = {}
var _track_game

func event_by_id(event_id: String) -> Dictionary:
    for event in EVENTS:
        if str(event["id"]) == event_id:
            return event
    return {}

func can_enter(game, event_id: String, vehicle_id: int) -> String:
    var event := event_by_id(event_id)
    if event.is_empty():
        return "Evento desconocido."
    if completed.has(event_id):
        return "Evento completado: no se puede cobrar el premio dos veces."
    if int(LICENSE_LEVELS.get(license, -1)) < int(LICENSE_LEVELS.get(event["license"], 100)):
        return "Licencia insuficiente: se requiere %s." % str(event["license"])
    var car: Dictionary = game.find_car(vehicle_id)
    if car.is_empty() or car.get("owner", "") != "player":
        return "Necesitás un vehículo propio."
    if not game.eligible(car):
        return "El vehículo no está apto para competir."
    if game.balance < int(event["fee"]):
        return "Saldo insuficiente para la inscripción."
    return ""

func simulate_event(game, event_id: String, vehicle_id: int) -> String:
    if not _track_entry.is_empty():
        return "Hay una carrera 3D en curso."
    var issue := can_enter(game, event_id, vehicle_id)
    if not issue.is_empty():
        return issue
    var event := event_by_id(event_id)
    var car: Dictionary = game.find_car(vehicle_id)
    # Snapshot BEFORE wear so event performance is evaluated at the starting condition.
    var initial_condition := float(game.condition(car)) + Tuning.new().performance_bonus(car)
    var field_result: Dictionary = Rivals.new().classify(initial_condition, event_id)
    if field_result.is_empty():
        return "No hay rivales configurados para esta prueba."
    var position: int = field_result["position"]
    var fee := int(event["fee"])
    var reward := int(event["rewards"][position - 1])
    # This call must succeed because the same car/eligibility constraints were checked above.
    # No mutation happens before this, preserving transaction safety for invalid entrants.
    var driving_result: String = game.drive(vehicle_id, int(event["distance"]), 2.5)
    if not driving_result.begins_with("Prueba"):
        return driving_result
    game.balance -= fee
    game.balance += reward
    var net := reward - fee
    game._record(car, "carrera:" + event_id, net)
    var victories := {}
    for opponent in field_result["opponents"]:
        victories[opponent["id"]] = initial_condition > float(opponent["score"])
    _record_result({"id":event_id,"vehicle_id":vehicle_id,"position":position,"fee":fee,"reward":reward,"net":net,"opponents":field_result["opponents"].duplicate(true),"source":"simulated"}, victories)
    return "%s · Puesto %d · Premio %s · Neto %s · Licencia %s" % [event["name"], position, Money.format(reward), Money.format(net,true), license]

# GameSession requests a paid admission before entering the scene. The career
# owns that admission, so an unpaid or stale report can never award a prize.
func has_pending_track_entry() -> bool:
    return not _track_entry.is_empty()

func begin_track_entry(game, event_id: String, vehicle_id: int) -> String:
    if not _track_entry.is_empty():
        return "Ya hay una inscripción de pista en curso."
    if event_id != "debut":
        return "Evento 3D no disponible."
    var issue := can_enter(game, event_id, vehicle_id)
    if not issue.is_empty():
        return issue
    var fee := int(event_by_id(event_id)["fee"])
    _track_entry = {"id":event_id, "vehicle_id":vehicle_id, "fee":fee, "started":false}
    _track_game = game
    game.balance -= fee
    game._record(game.find_car(vehicle_id), "inscripcion_3d:" + event_id, -fee)
    return ""

func mark_track_started() -> void:
    if not _track_entry.is_empty():
        _track_entry["started"] = true

func cancel_track_entry(game, refund_unstarted: bool = false) -> void:
    if _track_entry.is_empty() or game != _track_game:
        return
    if refund_unstarted:
        if _track_entry["started"]:
            return
        var fee: int = _track_entry["fee"]
        game.balance += fee
        game._record(game.find_car(_track_entry["vehicle_id"]), "reembolso_3d:" + str(_track_entry["id"]), fee)
    _track_entry = {}
    _track_game = null

func award_track_result(game, event_id: String, vehicle_id: int, report: Dictionary) -> Dictionary:
    if _track_entry.is_empty() or _track_game != game or _track_entry["id"] != event_id or _track_entry["vehicle_id"] != vehicle_id or not _track_entry["started"]:
        return {"ok":false, "message":"No hay inscripción de pista pagada y activa."}
    if event_id != "debut" or completed.has(event_id):
        return {"ok":false, "message":"Evento no disponible o premio ya cobrado."}
    var car: Dictionary = game.find_car(vehicle_id)
    if car.is_empty() or car.get("owner") != "player":
        return {"ok":false, "message":"Vehículo de carrera no disponible."}
    if report.get("laps") != 2 or typeof(report.get("standings")) != TYPE_ARRAY or report["standings"].size() != 3:
        return {"ok":false, "message":"Resultado de pista incompleto."}
    var expected := {"player":true}
    for driver in Rivals.new().field_for_event(event_id):
        expected[driver["id"]] = true
    var player := {}
    var opponents: Array[Dictionary] = []
    var seen := {}
    var victories := {}
    var previous_finish := -1.0
    var dnf_started := false
    for i in range(3):
        var row = report["standings"][i]
        if typeof(row) != TYPE_DICTIONARY or not expected.has(row.get("id")) or seen.has(row.get("id")) or row.get("position") != i + 1 or typeof(row.get("dnf")) != TYPE_BOOL:
            return {"ok":false, "message":"Clasificación de pista inválida."}
        var time = row.get("time")
        if typeof(time) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(time)):
            return {"ok":false, "message":"Cronometraje inválido."}
        if row["dnf"]:
            dnf_started = true
            if float(time) >= 0.0:
                return {"ok":false, "message":"Abandono con tiempo de llegada inválido."}
        elif dnf_started or float(time) <= 0.0 or row.get("laps") != 2 or float(time) < previous_finish:
            return {"ok":false, "message":"Llegada de pista inválida."}
        else:
            previous_finish = float(time)
        seen[row["id"]] = true
        if row["id"] == "player":
            player = row
        else:
            opponents.append(row.duplicate(true))
    if bool(player["dnf"]):
        return {"ok":false, "message":"Abandono: no hay premio ni progreso de licencia."}
    var event := event_by_id(event_id)
    var position: int = player["position"]
    var reward: int = event["rewards"][position - 1]
    game.balance += reward
    game._record(car, "premio_3d:" + event_id, reward)
    for opponent in opponents:
        victories[opponent["id"]] = position < int(opponent["position"])
    _record_result({"id":event_id,"vehicle_id":vehicle_id,"position":position,"fee":event["fee"],"reward":reward,"net":reward - int(event["fee"]),"opponents":opponents,"source":"track","laps":2,"time":player["time"]}, victories)
    _track_entry = {}
    _track_game = null
    return {"ok":true, "message":"%s · Puesto %d · Premio %s · Licencia %s" % [event["name"], position, Money.format(reward), license]}

func _record_result(result: Dictionary, victories: Dictionary) -> void:
    completed.append(str(result["id"]))
    var position: int = result["position"]
    reputation += 4 if position == 1 else (3 if position == 2 else 2)
    results.append(result)
    for rival_id in victories:
        var previous: Dictionary = rivalries.get(rival_id, {"encounters":0,"victories":0,"defeats":0})
        previous["encounters"] = int(previous["encounters"]) + 1
        var outcome := "victories" if victories[rival_id] else "defeats"
        previous[outcome] = int(previous[outcome]) + 1
        rivalries[rival_id] = previous
    _promote()

func _promote() -> void:
    if license == "R" and completed.has("debut") and completed.has("local") and reputation >= 4:
        license = "B"
    if license == "B" and completed.has("regional") and completed.has("endurance") and reputation >= 8:
        license = "A"

func to_dict() -> Dictionary:
    return {"schema_version":1, "license":license, "reputation":reputation, "completed":completed.duplicate(), "results":results.duplicate(true), "rivalries":rivalries.duplicate(true), "lap_records":lap_records.to_dict(),"drag_records":drag_records.to_dict(),"stock_drag_records":stock_drag_records.to_dict(),"drag_record_history":drag_records.history_to_dict(),"stock_drag_record_history":stock_drag_records.history_to_dict()}

func from_dict(data: Dictionary) -> bool:
    if typeof(data.get("stock_drag_records",{}))!=TYPE_DICTIONARY:
        return false
    var candidate_stock = DragRecords.new()
    if not candidate_stock.from_dict(data.get("stock_drag_records",{})):
        return false
    if typeof(data.get("drag_records",{})) != TYPE_DICTIONARY:
        return false
    var candidate_drag = DragRecords.new()
    if not candidate_drag.from_dict(data.get("drag_records",{})):
        return false
    for entry in [["drag_record_history",candidate_drag],["stock_drag_record_history",candidate_stock]]:
        var archive = data.get(entry[0],{})
        if typeof(archive)!=TYPE_DICTIONARY or not entry[1].history_from_dict(archive):
            return false
    if typeof(data.get("lap_records", {})) != TYPE_DICTIONARY:
        return false
    var candidate_records = LapRecords.new()
    if not candidate_records.from_dict(data.get("lap_records", {})):
        return false
    if data.get("schema_version") != 1 or not LICENSE_LEVELS.has(data.get("license", "")):
        return false
    if typeof(data.get("reputation")) != TYPE_INT or int(data["reputation"]) < 0 or typeof(data.get("completed")) != TYPE_ARRAY or typeof(data.get("results")) != TYPE_ARRAY:
        return false
    var known := {}
    for event in EVENTS:
        known[event["id"]] = true
    var seen := {}
    for event_id in data["completed"]:
        if typeof(event_id) != TYPE_STRING or not known.has(event_id) or seen.has(event_id):
            return false
        seen[event_id] = true
    if data["results"].size() != data["completed"].size():
        return false
    var seen_results := {}
    for result in data["results"]:
        if typeof(result) != TYPE_DICTIONARY or typeof(result.get("id")) != TYPE_STRING:
            return false
        var id: String = result["id"]
        if not seen.has(id) or seen_results.has(id) or typeof(result.get("position")) != TYPE_INT or int(result["position"]) < 1 or int(result["position"]) > 3:
            return false
        seen_results[id] = true
    if data["license"] == "B" and (not seen.has("debut") or not seen.has("local")):
        return false
    if data["license"] == "A" and (not seen.has("debut") or not seen.has("local") or not seen.has("regional") or not seen.has("endurance")):
        return false
    if typeof(data.get("rivalries", {})) != TYPE_DICTIONARY:
        return false
    for rival_id in data.get("rivalries", {}):
        if Rivals.new().driver_by_id(str(rival_id)).is_empty():
            return false
        var r = data["rivalries"][rival_id]
        if typeof(r) != TYPE_DICTIONARY or typeof(r.get("encounters")) != TYPE_INT or typeof(r.get("victories")) != TYPE_INT or typeof(r.get("defeats")) != TYPE_INT:
            return false
        if int(r["encounters"]) < 0 or int(r["victories"]) < 0 or int(r["defeats"]) < 0 or int(r["encounters"]) != int(r["victories"]) + int(r["defeats"]):
            return false
    license = str(data["license"])
    reputation = int(data["reputation"])
    completed.clear()
    for id in data["completed"]:
        completed.append(id)
    results.clear()
    for result in data["results"]:
        results.append(result.duplicate(true))
    rivalries = data.get("rivalries", {}).duplicate(true)
    lap_records = candidate_records
    drag_records = candidate_drag
    stock_drag_records = candidate_stock
    return true
