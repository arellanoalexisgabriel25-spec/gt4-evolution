extends RefCounted

# Original approximation: full-load torque curve and a separate boost transient.
# Turbo pressure changes torque availability, never the tire friction coefficient.
var boost := 0.0

static func curve_factor(rpm: float, config) -> float:
    var curve: PackedFloat32Array = config.torque_curve
    var knots: PackedFloat32Array = config.torque_rpm
    if curve.size()<2 or knots.size()!=curve.size():
        return 1.0
    if rpm<=knots[0]:
        return curve[0]
    for index in range(knots.size()-1):
        if rpm<=knots[index+1]:
            return lerpf(curve[index],curve[index+1],(rpm-knots[index])/maxf(knots[index+1]-knots[index],1.0))
    return curve[curve.size()-1]

func boost_factor(dt: float, rpm: float, throttle: float, loaded: bool, config) -> float:
    if config.turbo_fraction<=0.0:
        boost = 0.0
        return 1.0
    var target := clampf((rpm-config.spool_rpm)/1400.0,0,1)*throttle*(1.0 if loaded else 0.25)
    var response: float = config.turbo_response if target>boost else 9.0
    boost = lerpf(boost,target,1.0-exp(-response*dt))
    return (1.0+config.turbo_fraction*boost)/(1.0+config.turbo_fraction)
