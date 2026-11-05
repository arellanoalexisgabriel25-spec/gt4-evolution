extends Resource

# SI units. Standard dry air is a development baseline, not measured Gálvez weather.
const REVISION := "longitudinal_023"
const STANDARD_GRAVITY := 9.81
const DRY_AIR_GAS_CONSTANT := 287.05
@export var air_temperature_c := 20.0
@export var pressure_pa := 101325.0
@export var wind_velocity := Vector3.ZERO

func density() -> float:
    return air_density(air_temperature_c,pressure_pa)

static func air_density(temperature_c: float, pressure: float) -> float:
    if not is_finite(temperature_c) or not is_finite(pressure) or temperature_c<=-273.15 or pressure<=0.0:
        return 0.0
    return pressure/(DRY_AIR_GAS_CONSTANT*(temperature_c+273.15))

static func aerodynamic_force(speed: float, wind_along: float, density_value: float, drag_area: float) -> float:
    var relative := speed-wind_along
    # Positive opposes forward motion. A strong tailwind can push a coasting car.
    return 0.5*density_value*drag_area*relative*absf(relative)

static func frame(forward: Vector3, normal: Vector3, gravity: Vector3) -> Dictionary:
    var n := normal.normalized()
    var tangent := forward.slide(n).normalized()
    return {"tangent":tangent,"normal":n,"normal_g":maxf(0.0,-gravity.dot(n)),"grade_acceleration":gravity.dot(tangent)}

static func record_profile(base: String) -> String:
    return (base if not base.is_empty() else "legacy_estimate")+"__"+REVISION
