extends RefCounted

const Run = preload("res://scripts/drag_run.gd")
var records: Dictionary = {}

static func normalized(ticket: Dictionary) -> Dictionary:
    var result := {}
    for key in ["distance","et","reaction","total","trap_kmh","finish_kmh","sixty_ft","eighth"]:
        result[key] = float(ticket[key])
    return result

static func valid_ticket(ticket: Dictionary) -> bool:
    for key in ["distance","et","reaction","total","trap_kmh","finish_kmh","sixty_ft","eighth"]:
        var value = ticket.get(key)
        if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)):
            return false
    return is_equal_approx(float(ticket["distance"]),Run.DISTANCE) and float(ticket["et"])>0.0 and float(ticket["reaction"])>=-0.000001 and absf(float(ticket["total"])-float(ticket["et"])-float(ticket["reaction"]))<0.001 and float(ticket["trap_kmh"])>0.0 and float(ticket["trap_kmh"])<500.0 and float(ticket["finish_kmh"])>0.0 and float(ticket["finish_kmh"])<500.0 and float(ticket["sixty_ft"])>0.0 and float(ticket["sixty_ft"])<float(ticket["eighth"]) and float(ticket["eighth"])<float(ticket["et"])

func consider(vehicle_id: int, ticket: Dictionary) -> bool:
    if vehicle_id <= 0 or not valid_ticket(ticket):
        return false
    var key := str(vehicle_id)
    if records.has(key) and float(records[key]["et"]) <= float(ticket["et"]):
        return false
    records[key] = normalized(ticket)
    return true

func best(vehicle_id: int) -> Dictionary:
    return records.get(str(vehicle_id),{}).duplicate(true)

func to_dict() -> Dictionary:
    return records.duplicate(true)

func from_dict(data: Dictionary) -> bool:
    var pattern := RegEx.new()
    pattern.compile("^[1-9][0-9]*$")
    for key in data:
        if typeof(key) != TYPE_STRING or pattern.search(key) == null or typeof(data[key]) != TYPE_DICTIONARY or not valid_ticket(data[key]):
            return false
    var candidate := {}
    for key in data:
        candidate[key] = normalized(data[key])
    records = candidate
    return true
