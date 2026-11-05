extends RefCounted

# Equivalent friction-pack temperature and wear. Heat is dissipated mechanical
# work, not a reward/penalty triggered by a button. Coefficients are estimates.
var temperature := 20.0
var wear_points := 0.0

static func pressure(pedal: float, config) -> float:
    return 1.0-smoothstep(config.clutch_bite_pedal,config.clutch_release_pedal,clampf(pedal,0.0,1.0))

func capacity_factor(config) -> float:
    return lerpf(1.0,0.30,clampf((temperature-config.clutch_fade_start_c)/maxf(config.clutch_fade_end_c-config.clutch_fade_start_c,1.0),0.0,1.0))

func step(dt: float, work_j: float, speed: float, config) -> float:
    if not is_finite(dt) or dt<=0.0 or not is_finite(work_j) or not is_finite(speed):
        return 0.0
    var capacity: float = maxf(config.clutch_heat_capacity,1.0)
    var cooling: float = maxf(config.clutch_cooling_w_per_k,0.0)*(1.0+absf(speed)*0.015)
    var cooling_interval: float = cooling*dt/capacity
    var decay := exp(-cooling_interval)
    # Integrate uniform friction power and linear cooling together. This form
    # also has the insulated limit delta T = work / heat capacity; a series
    # near zero avoids cancellation when the cooling coefficient is tiny.
    var heating_fraction: float = 1.0-cooling_interval*0.5+cooling_interval*cooling_interval/6.0 if cooling_interval<0.00001 else (1.0-decay)/cooling_interval
    temperature = 20.0+(temperature-20.0)*decay+maxf(work_j,0.0)/capacity*heating_fraction
    var abuse := 1.0+30.0*clampf((temperature-config.clutch_fade_start_c)/150.0,0.0,3.0)
    var loss: float = maxf(work_j,0.0)*config.clutch_wear_per_joule*abuse
    wear_points += loss
    return loss
