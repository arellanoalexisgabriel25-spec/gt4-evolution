extends RefCounted

# Crash damage and mechanical handicaps. Pure logic: it reads velocity changes
# reported by the caller, accumulates damage per component during a session and
# settles it once into the persistent car health used by the economy.
# Provisional arcade balance; not recovered GT4 values.
const COMPONENTS := ["motor", "transmision", "suspension", "frenos", "neumaticos", "chasis", "electrico"]
const MIN_IMPACT := 3.0 # m/s of sudden speed change ignored below this (scrapes, car taps)
const COOLDOWN := 0.5 # seconds; follow-up frames of the same crash are not counted again
const MAX_IMPACT_POINTS := 150.0
# Share of an impact absorbed by each component, by impact zone.
const ZONES := {
    "front": {"chasis": 0.40, "motor": 0.25, "suspension": 0.20, "frenos": 0.10, "electrico": 0.05},
    "rear": {"chasis": 0.45, "transmision": 0.25, "suspension": 0.20, "electrico": 0.10},
    "side": {"chasis": 0.40, "suspension": 0.30, "neumaticos": 0.20, "frenos": 0.10},
}
var pending := {} # component -> health points waiting to be settled
var cumulative := {} # lifetime of this visit; settlement never erases the report
var impacts := 0
var worst_change := 0.0
var cooldown := 0.0
var event_points := 0.0 # points already counted for the crash in progress
var latest_damage := {} # component deltas from the latest accepted impact

static func points_for(change: float) -> float:
    if not is_finite(change) or change <= MIN_IMPACT:
        return 0.0
    return minf(1.2 * pow(change - MIN_IMPACT, 1.5), MAX_IMPACT_POINTS)

# change: velocity after - velocity before, in world space. forward: unit heading.
static func classify(change: Vector2, forward: Vector2) -> String:
    var along := change.dot(forward)
    var lateral := absf(change.dot(Vector2(-forward.y, forward.x)))
    if absf(along) >= lateral:
        return "front" if along < 0.0 else "rear"
    return "side"

func tick(delta: float) -> void:
    if is_finite(delta) and delta > 0.0:
        cooldown = maxf(0.0, cooldown - delta)

# Returns the damage points newly counted; 0 when ignored. Frames within the
# cooldown belong to the same crash: only the increase over what was already
# counted is added, so a later, harder frame is not lost.
func record(before: Vector2, after: Vector2, forward: Vector2, engine_position: String = "front") -> float:
    latest_damage.clear()
    if engine_position not in ["front","mid","rear"]: return 0.0
    if not before.is_finite() or not after.is_finite() or not forward.is_finite() or forward.length() < 0.5:
        return 0.0
    var change := after - before
    var points := points_for(change.length())
    if points <= 0.0:
        return 0.0
    var fresh := cooldown <= 0.0
    var counted := points if fresh else points - event_points
    if counted <= 0.0:
        return 0.0
    var direction := classify(change,forward.normalized())
    var zone: Dictionary = ZONES[direction].duplicate()
    # Coarse compartment layout: rear/mid engines receive direct rear impact
    # damage instead of inheriting the front-engine car's allocation. Shares
    # still sum to one; total crash severity and once-only settlement are intact.
    if engine_position in ["rear","mid"]:
        if direction=="front":
            zone["chasis"] += float(zone.get("motor",0.0))
            zone.erase("motor")
        elif direction=="rear":
            zone["chasis"] -= 0.25
            zone["motor"] = 0.25
    for component in zone:
        var added := counted * float(zone[component])
        pending[component] = float(pending.get(component, 0.0)) + added
        cumulative[component] = float(cumulative.get(component,0.0))+added
        latest_damage[component] = added
    if fresh:
        impacts += 1
    event_points = points
    cooldown = COOLDOWN
    worst_change = maxf(worst_change, change.length())
    return counted

# Mechanical overspeed and clutch slip remain owned by manual_powertrain.gd.
# An electronic limiter is not treated as a mechanical over-rev event here.
func total_pending() -> float:
    var total := 0.0
    for component in pending:
        total += float(pending[component])
    return total

# Applies pending damage to a player-owned car exactly once. Returns the applied
# points per component; invalid cars leave the pending damage untouched.
func settle(game, car_id: int) -> Dictionary:
    var car: Dictionary = game.find_car(car_id)
    if car.is_empty() or car.get("owner") != "player" or typeof(car.get("health")) != TYPE_DICTIONARY:
        return {}
    if not valid_pending():
        return {}
    var applied := {}
    var total := 0.0
    for component in pending:
        if not car["health"].has(component):
            continue
        var before := float(car["health"][component])
        var after := clampf(before - float(pending[component]), 0.0, 100.0)
        if before - after > 0.0:
            applied[component] = before - after
            total += before - after
        car["health"][component] = after
    pending.clear()
    if total > 0.0 and typeof(car.get("history")) == TYPE_ARRAY:
        car["history"].append({"event": "danos", "points": snappedf(total, 0.01)})
    return applied

func valid_pending() -> bool:
    for component in pending:
        var value = pending[component]
        if not COMPONENTS.has(component) or typeof(value) not in [TYPE_FLOAT,TYPE_INT] or not is_finite(float(value)) or float(value)<0.0 or float(value)>10000.0:
            return false
    return true

# Multipliers for systems that Handling.parameters() does not already cover
# (motor, brakes and tires are handled there). Missing components count as healthy.
static func handicaps(health: Dictionary) -> Dictionary:
    var transmission := 1.0 - clampf(float(health.get("transmision", 100.0)) / 100.0, 0.0, 1.0)
    var suspension := 1.0 - clampf(float(health.get("suspension", 100.0)) / 100.0, 0.0, 1.0)
    var chassis := 1.0 - clampf(float(health.get("chasis", 100.0)) / 100.0, 0.0, 1.0)
    return {
        "acceleration": 1.0 - 0.20 * transmission,
        "grip": 1.0 - 0.20 * suspension,
        "steering": 1.0 - 0.10 * chassis,
    }
