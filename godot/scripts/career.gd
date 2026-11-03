extends RefCounted
class_name EvolutionCareer

# Competition is an explicitly simulated result until the driving module exists.
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
        return "Créditos insuficientes para la inscripción."
    return ""

func simulate_event(game, event_id: String, vehicle_id: int) -> String:
    var issue := can_enter(game, event_id, vehicle_id)
    if not issue.is_empty():
        return issue
    var event := event_by_id(event_id)
    var car: Dictionary = game.find_car(vehicle_id)
    # Snapshot BEFORE wear so event performance is evaluated at the starting condition.
    var initial_condition := float(game.condition(car))
    var position := 3
    if initial_condition >= float(event["target"]):
        position = 1
    elif initial_condition >= float(event["target"]) - 13.0:
        position = 2
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
    completed.append(event_id)
    reputation += 4 if position == 1 else (3 if position == 2 else 2)
    results.append({"id":event_id,"vehicle_id":vehicle_id,"position":position,"fee":fee,"reward":reward,"net":net})
    _promote()
    return "%s · Puesto %d · Premio %d Cr. · Neto %+d Cr. · Licencia %s" % [event["name"], position, reward, net, license]

func _promote() -> void:
    if license == "R" and completed.has("debut") and completed.has("local") and reputation >= 4:
        license = "B"
    if license == "B" and completed.has("regional") and completed.has("endurance") and reputation >= 8:
        license = "A"

func to_dict() -> Dictionary:
    return {"schema_version":1, "license":license, "reputation":reputation, "completed":completed.duplicate(), "results":results.duplicate(true)}

func from_dict(data: Dictionary) -> bool:
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
    license = str(data["license"])
    reputation = int(data["reputation"])
    completed.clear()
    for id in data["completed"]:
        completed.append(id)
    results.clear()
    for result in data["results"]:
        results.append(result.duplicate(true))
    return true
