extends RefCounted

const Run = preload("res://scripts/drag_run.gd")
var records: Dictionary = {}
var history: Dictionary = {}

static func normalized(ticket: Dictionary) -> Dictionary:
    var result := {}
    for key in ["distance","et","reaction","total","trap_kmh","finish_kmh","sixty_ft","eighth"]:
        result[key] = float(ticket[key])
    if ticket.has("physics_profile"):
        result["physics_profile"] = ticket["physics_profile"]
    return result

static func valid_profile(value: Variant) -> bool:
    if typeof(value)!=TYPE_STRING or value.is_empty() or value.length()>96:
        return false
    var pattern := RegEx.new()
    pattern.compile("^[a-z0-9_]+$")
    return pattern.search(value)!=null

static func valid_ticket(ticket: Dictionary) -> bool:
    if ticket.has("physics_profile") and not valid_profile(ticket["physics_profile"]):
        return false
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

# A changed physical profile starts a comparable PB series. Its previous ticket
# remains untouched until the first new valid finish, then moves to history.
# Failed/duplicate runs cannot erase or relabel a previous version's best.
func consider_for_profile(vehicle_id: int, ticket: Dictionary, profile: String) -> bool:
    if profile.is_empty():
        return consider(vehicle_id,ticket)
    if vehicle_id<=0 or profile=="legacy" or not valid_profile(profile) or not valid_ticket(ticket):
        return false
    if ticket.has("physics_profile") and ticket["physics_profile"]!=profile:
        return false
    var key := str(vehicle_id)
    var current: Dictionary = records.get(key,{})
    if current.get("physics_profile","")==profile and float(current.et)<=float(ticket.et):
        return false
    var next := normalized(ticket)
    next["physics_profile"] = profile
    if not current.is_empty() and current.get("physics_profile","")!=profile:
        var old_profile := str(current.get("physics_profile","legacy"))
        if not history.has(key): history[key] = {}
        var previous: Dictionary = history[key].get(old_profile,{})
        if previous.is_empty() or float(current.et)<float(previous.et):
            history[key][old_profile] = current.duplicate(true)
    records[key] = next
    return true

func best_for_profile(vehicle_id: int, profile: String) -> Dictionary:
    var current := best(vehicle_id)
    return current if profile.is_empty() or current.get("physics_profile","")==profile else {}

# Display-only history; it must never be used as the new profile's target time.
func previous_best(vehicle_id: int, profile: String) -> Dictionary:
    if profile.is_empty(): return {}
    var previous: Dictionary = {}
    var candidates: Array = history.get(str(vehicle_id),{}).values()
    candidates.append(best(vehicle_id))
    for ticket in candidates:
        if ticket.is_empty() or ticket.get("physics_profile","")==profile:
            continue
        if previous.is_empty() or float(ticket.et)<float(previous.et):
            previous = ticket
    return previous.duplicate(true)

func history_to_dict() -> Dictionary:
    return history.duplicate(true)

func history_from_dict(data: Dictionary) -> bool:
    var ids := RegEx.new()
    ids.compile("^[1-9][0-9]*$")
    var candidate := {}
    for key in data:
        if typeof(key)!=TYPE_STRING or ids.search(key)==null or typeof(data[key])!=TYPE_DICTIONARY:
            return false
        candidate[key] = {}
        for profile in data[key]:
            var ticket = data[key][profile]
            if not valid_profile(profile) or typeof(ticket)!=TYPE_DICTIONARY or not valid_ticket(ticket):
                return false
            if str(ticket.get("physics_profile","legacy"))!=profile:
                return false
            candidate[key][profile] = normalized(ticket)
    history = candidate
    return true
