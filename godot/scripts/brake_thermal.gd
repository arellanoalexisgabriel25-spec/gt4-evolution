extends RefCounted

# Two axle-equivalent thermal masses, not disc surface temperatures. Heat enters
# only through measured brake work. Capacities/fade/cooling need vehicle-specific
# validation; no contact work or throttle can heat a stationary brake.
var temperatures := Vector2(20.0,20.0)

func reset(ambient: float = 20.0) -> void:
    temperatures = Vector2.ONE*ambient

func factors(config) -> Vector2:
    var result := Vector2.ONE
    for axle in range(2):
        result[axle] = lerpf(1.0,config.brake_hot_factor,clampf((temperatures[axle]-config.brake_fade_start_c)/maxf(config.brake_fade_end_c-config.brake_fade_start_c,1.0),0.0,1.0))
    return result

func step(dt: float, energy: Vector2, speed: float, config) -> void:
    if not is_finite(dt) or dt<=0.0 or not energy.is_finite() or not is_finite(speed): return
    for axle in range(2):
        var capacity: float = config.brake_heat_capacity[axle]
        var cooling: float = config.brake_cooling_w_per_k*(1.0+absf(speed)*0.055)
        var rate := cooling/maxf(capacity,1.0)
        var equilibrium: float = config.brake_ambient_c+maxf(0.0,energy[axle])/dt/maxf(cooling,0.001)
        temperatures[axle] = equilibrium+(temperatures[axle]-equilibrium)*exp(-rate*dt)
