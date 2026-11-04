extends RefCounted

# Tire temperature and tread wear for one car. Pure logic: no scenes, input or
# persistence. Feed it how hard the tires are being used and read grip_multiplier().
# Provisional arcade balance; these are not recovered GT4 values.
const AMBIENT := 20.0
const MAX_TEMPERATURE := 200.0
const COMPOUNDS := {
    "street": {"optimal": 45.0, "window": 45.0, "cold_floor":0.90, "wear_rate": 2.4e-4, "peak": 1.0, "severity": 1.0},
    "sport": {"optimal": 65.0, "window": 40.0, "cold_floor":0.72, "wear_rate": 4.2e-4, "peak": 1.12, "severity": 1.25},
    "slick": {"optimal": 75.0, "window": 30.0, "cold_floor":0.55, "wear_rate": 9.0e-4, "peak": 1.25, "severity": 1.6},
}
var compound := "street"
var temperature := AMBIENT
var wear := 0.0 # session tread loss: 0 = untouched this session, 1 = destroyed
var demand_integral := 0.0 # demand * seconds, for the session average
var elapsed := 0.0

static func for_vehicle(vehicle: Dictionary) -> String:
    var kind := str(vehicle.get("tire_compound","sport" if vehicle.get("upgrades",[]).has("tires") else "street"))
    return kind if COMPOUNDS.has(kind) else "street"

static func title(kind: String) -> String:
    return {"street":"calle","sport":"deportivos","slick":"slick de drag"}.get(kind,"calle")

func _init(kind: String = "street") -> void:
    compound = kind if COMPOUNDS.has(kind) else "street"

func reset() -> void:
    temperature = AMBIENT
    wear = 0.0
    demand_integral = 0.0
    elapsed = 0.0

# Fraction of available grip being used: acceleration magnitude / (grip * g).
static func demand_from(acceleration: float, grip: float) -> float:
    if not is_finite(acceleration) or not is_finite(grip):
        return 0.0
    return clampf(absf(acceleration) / maxf(grip * 9.81, 0.1), 0.0, 2.0)

# demand: 0 coasting, ~0.6 pushing, 1+ at or over the limit. Heating relaxes
# exponentially toward an equilibrium, so results do not depend on tick rate.
func step(delta: float, demand: float, speed: float, on_road: bool = true) -> void:
    if delta <= 0.0 or not is_finite(delta) or not is_finite(demand) or not is_finite(speed):
        return
    var load_demand := clampf(demand, 0.0, 2.0)
    _advance(delta,load_demand,absf(speed),on_road,12.0*load_demand*load_demand)

# The live axle model supplies actual dissipated slip power, not impact-derived
# chassis acceleration. Rolling demand alone cannot create a stationary burnout.
func step_contact(delta: float, slip_power: float, normal_load: float, force: float, speed: float, on_road: bool = true) -> void:
    if not is_finite(delta) or delta<=0.0 or not is_finite(slip_power) or not is_finite(normal_load) or not is_finite(force) or not is_finite(speed):
        return
    if normal_load<=0.0:
        # A spinning airborne wheel still cools in the airflow, but there is no
        # road-contact heat or tread abrasion, including the usual baseline wear.
        _advance(delta,0.0,absf(speed),on_road,0.0,false)
        return
    var load_demand := clampf(maxf(absf(force)/maxf(normal_load,100.0),sqrt(maxf(0,slip_power)/maxf(normal_load*8.0,100.0))),0,2)
    var heat := maxf(0,slip_power)/3500.0+0.2*load_demand*load_demand
    _advance(delta,load_demand,absf(speed),on_road,heat)

func _advance(delta: float, load_demand: float, speed: float, on_road: bool, heat: float, wear_contact: bool = true) -> void:
    var data: Dictionary = COMPOUNDS[compound]
    var airflow := clampf(speed, 0.0, 100.0)
    var cooling := 0.03 + 0.002 * airflow
    var equilibrium := AMBIENT + heat / cooling
    temperature = clampf(temperature + (equilibrium - temperature) * (1.0 - exp(-cooling * delta)), AMBIENT, MAX_TEMPERATURE)
    var overheat := clampf((temperature - float(data["optimal"]) - float(data["window"]) * 0.5) / float(data["window"]), 0.0, 1.0)
    demand_integral += load_demand * delta
    elapsed += delta
    var surface := 1.0 if on_road else 2.0
    if wear_contact:
        wear = clampf(wear + float(data["wear_rate"]) * delta * (0.2 + 3.0 * load_demand * load_demand) * surface * (1.0 + overheat), 0.0, 1.0)

func mean_demand() -> float:
    return demand_integral / elapsed if elapsed > 0.0 else 0.0

# Wear severity for Economy.record_distance(): the persistent tire health (and the
# rest of the car) wears faster the harder the session was driven. Without data: 1.0.
func severity() -> float:
    if elapsed <= 0.0:
        return 1.0
    var mean := mean_demand()
    var data: Dictionary = COMPOUNDS[compound]
    return clampf((0.6 + 3.0 * mean * mean) * float(data["severity"]), 0.5, 5.0)

# Standstill burnout: spins the driven tires to bring them to working temperature.
# About 3 s takes cold street tires from ambient to roughly 70 C; capped at 8 s.
func burnout(seconds: float) -> void:
    if not is_finite(seconds) or seconds <= 0.0:
        return
    var remaining := minf(seconds, 8.0)
    while remaining > 0.0:
        var slice := minf(remaining, 0.05)
        step(slice, 1.2, 0.0)
        remaining -= slice

func temperature_factor() -> float:
    var data: Dictionary = COMPOUNDS[compound]
    var offset := (temperature - float(data["optimal"])) / float(data["window"])
    var factor := 1.0 - 0.25 * minf(offset * offset, 1.4)
    return maxf(float(data["cold_floor"]),factor) if offset<0.0 else factor

func wear_factor() -> float:
    return 1.0 - 0.30 * pow(wear, 1.2)

# Multiply the car's grip by this value. Wear here is session-only: lasting tire
# condition already enters through Handling.parameters() (tire health), so persist
# it with severity() instead of writing `wear` into the car.
func grip_multiplier() -> float:
    var data: Dictionary = COMPOUNDS[compound]
    return maxf(float(data["peak"]) * temperature_factor() * wear_factor(), 0.3)

# The axle caller already subtracts cumulative session tread loss from health.
# Excluding wear here avoids counting that same loss twice in contact grip.
func thermal_grip() -> float:
    return float(COMPOUNDS[compound]["peak"])*temperature_factor()

func to_dict() -> Dictionary:
    return {"compound": compound, "temperature": temperature, "wear": wear}

# Validates before touching state; returns false for malformed or non-finite data.
func restore(data: Dictionary) -> bool:
    var kind = data.get("compound", "")
    var heat = data.get("temperature", null)
    var tread = data.get("wear", null)
    if typeof(kind) != TYPE_STRING or not COMPOUNDS.has(kind):
        return false
    if (typeof(heat) != TYPE_FLOAT and typeof(heat) != TYPE_INT) or (typeof(tread) != TYPE_FLOAT and typeof(tread) != TYPE_INT):
        return false
    if not is_finite(float(heat)) or not is_finite(float(tread)) or float(tread) < 0.0 or float(tread) > 1.0 or float(heat) < AMBIENT - 0.001 or float(heat) > MAX_TEMPERATURE:
        return false
    compound = kind
    temperature = float(heat)
    wear = float(tread)
    demand_integral = 0.0
    elapsed = 0.0
    return true
