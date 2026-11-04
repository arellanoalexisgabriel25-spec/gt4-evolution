extends RefCounted

# One owner for measured usage: recovery and leaving settle the difference from
# cumulative counters, so an attempt cannot erase wear or debit it a second time.
var game
var career
var vehicle_id := 0
var measured_distance := 0.0
var settled_distance := 0.0
var settled_wear := {"motor":0.0,"transmision":0.0,"neumaticos":0.0,"frenos":0.0}
var recorded_attempt := false

func begin(economy, profession, id: int) -> bool:
    var vehicle: Dictionary = economy.find_car(id)
    if vehicle.is_empty() or vehicle.get("owner") != "player" or not economy.eligible(vehicle) or profession.has_pending_track_entry():
        return false
    game = economy
    career = profession
    vehicle_id = id
    return true

func settle(wear: Dictionary, damage = null) -> bool:
    if game == null or vehicle_id <= 0 or not is_finite(measured_distance) or measured_distance < settled_distance:
        return false
    var vehicle: Dictionary = game.find_car(vehicle_id)
    if vehicle.is_empty() or vehicle.get("owner") != "player":
        return false
    if damage!=null and not damage.valid_pending():
        return false
    var delta := {}
    for component in settled_wear:
        var value = wear.get(component)
        if typeof(value) not in [TYPE_FLOAT,TYPE_INT] or not is_finite(float(value)) or float(value)<float(settled_wear[component]) or float(value)>10000.0:
            return false
        delta[component] = float(value)-float(settled_wear[component])
    if not game.record_distance(vehicle_id,measured_distance-settled_distance,1.0):
        return false
    for component in delta:
        vehicle["health"][component] = maxf(0,float(vehicle["health"][component])-float(delta[component]))
        settled_wear[component] = wear[component]
    settled_distance = measured_distance
    if damage!=null:
        damage.settle(game,vehicle_id)
    return true

func record_finish(ticket: Dictionary) -> bool:
    if recorded_attempt or career == null:
        return false
    if not load("res://scripts/drag_records.gd").valid_ticket(ticket):
        return false
    recorded_attempt = true
    return career.drag_records.consider(vehicle_id,ticket)

func next_attempt() -> void:
    recorded_attempt = false
