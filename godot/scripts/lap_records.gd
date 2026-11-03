extends RefCounted

var best: Dictionary = {}

func get_best(vehicle_id: int, circuit_id: String = "club_oval") -> float:
    return float(best.get("%s:%d" % [circuit_id, vehicle_id], 0.0))

func consider(vehicle_id: int, seconds: float, circuit_id: String = "club_oval") -> bool:
    if vehicle_id <= 0 or circuit_id != "club_oval" or not is_finite(seconds) or seconds <= 0.0:
        return false
    var previous := get_best(vehicle_id, circuit_id)
    if previous > 0.0 and previous <= seconds:
        return false
    best["%s:%d" % [circuit_id, vehicle_id]] = seconds
    return true

func to_dict() -> Dictionary:
    return best.duplicate()

func from_dict(data: Dictionary) -> bool:
    var key_pattern := RegEx.new()
    key_pattern.compile("^club_oval:[1-9][0-9]*$")
    for key in data:
        if typeof(key) != TYPE_STRING or key_pattern.search(key) == null:
            return false
        var seconds = data[key]
        if typeof(seconds) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(seconds)) or float(seconds) <= 0.0:
            return false
    best = data.duplicate()
    return true
