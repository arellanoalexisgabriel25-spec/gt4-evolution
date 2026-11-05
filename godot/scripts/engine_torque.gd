extends RefCounted

# Original approximation: full-load torque curve and a separate boost transient.
# Turbo pressure changes torque availability, never the tire friction coefficient.
var boost := 0.0
const WATTS_PER_CV := 735.49875
const WATTS_PER_MECHANICAL_HP := 745.6998715822702

static func kgfm_to_nm(value: float) -> float:
    return value*9.80665

static func torque_for_cv_at_rpm(cv: float, rpm: float) -> float:
    if not is_finite(cv) or not is_finite(rpm) or cv<0.0 or rpm<=0.0:
        return 0.0
    return cv*WATTS_PER_CV/(rpm*TAU/60.0)

static func kw_to_cv(power_kw: float) -> float:
    return power_kw*1000.0/WATTS_PER_CV

static func kw_to_hp(power_kw: float) -> float:
    return power_kw*1000.0/WATTS_PER_MECHANICAL_HP

static func power_kw(torque_nm: float, rpm: float) -> float:
    return torque_nm*rpm*TAU/60000.0

static func curve_factor(rpm: float, config) -> float:
    if not is_finite(rpm):
        return 0.0
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

# Torque is interpolated linearly in RPM. Power is therefore quadratic between
# knots; sampling just the torque knots can miss the true power maximum.
static func maximum_power(config) -> Dictionary:
    var best := {"kw":0.0,"rpm":float(config.idle_rpm)}
    var knots: PackedFloat32Array = config.torque_rpm
    var curve: PackedFloat32Array = config.torque_curve
    var candidates: Array[float] = [float(config.idle_rpm),float(config.redline_rpm)]
    if knots.size()==curve.size() and knots.size()>1:
        for index in range(knots.size()):
            candidates.append(float(knots[index]))
            if index+1<knots.size() and knots[index+1]>knots[index]:
                var slope: float = (curve[index+1]-curve[index])/(knots[index+1]-knots[index])
                if slope<0.0:
                    var intercept: float = curve[index]-slope*knots[index]
                    var stationary := -intercept/(2.0*slope)
                    if stationary>knots[index] and stationary<knots[index+1]:
                        candidates.append(stationary)
    for rpm in candidates:
        if rpm<float(config.idle_rpm) or rpm>float(config.redline_rpm):
            continue
        var value := power_kw(config.peak_torque*curve_factor(rpm,config),rpm)
        if value>float(best["kw"]):
            best = {"kw":value,"rpm":rpm}
    return best

func boost_factor(dt: float, rpm: float, throttle: float, loaded: bool, config) -> float:
    if config.turbo_fraction<=0.0:
        boost = 0.0
        return 1.0
    var target := clampf((rpm-config.spool_rpm)/maxf(config.boost_span_rpm,1.0),0,1)*throttle*(1.0 if loaded else 0.25)
    var response: float = config.turbo_response if target>boost else 9.0
    boost = lerpf(boost,target,1.0-exp(-response*dt))
    return (1.0+config.turbo_fraction*boost)/(1.0+config.turbo_fraction)
