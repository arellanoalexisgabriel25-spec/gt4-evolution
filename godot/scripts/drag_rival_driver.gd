extends RefCounted

# Original deterministic driver policy. It operates the same pedals, clutch and
# manual gearbox as the player; it never writes speed, position, grip or torque.
const GREEN_TIME := 2.0
const PROFILES := {
    "conservative":{"reaction_delay":0.34,"launch_rpm":2400.0,"shift_fraction":0.82,"shift_hold":0.30,"launch_throttle":0.55,"slip_target":0.14},
    "technical":{"reaction_delay":0.16,"launch_rpm":3100.0,"shift_fraction":0.92,"shift_hold":0.22,"launch_throttle":0.78,"slip_target":0.20},
    "aggressive":{"reaction_delay":0.09,"launch_rpm":3900.0,"shift_fraction":0.98,"shift_hold":0.18,"launch_throttle":1.0,"slip_target":0.38}
}
const LIMITS := {
    "reaction_delay":[0.0,2.0],"launch_rpm":[1200.0,5000.0],
    "shift_fraction":[0.72,0.99],"shift_hold":[0.18,0.60],
    "launch_throttle":[0.30,1.0],"slip_target":[0.08,0.50]
}
var profile := "technical"
var reaction_delay := 0.16
var launch_rpm := 3100.0
var shift_fraction := 0.92
var shift_hold := 0.22
var launch_throttle := 0.78
var slip_target := 0.20
var shifts_requested := 0
var _phase := "ready"
var _hold_remaining := 0.0
var _last_clock := -1.0

func _init(kind: String = "technical", overrides: Dictionary = {}) -> void:
    profile = kind if PROFILES.has(kind) else "technical"
    for key in LIMITS:
        var value = overrides.get(key,PROFILES[profile][key])
        if typeof(value) not in [TYPE_FLOAT,TYPE_INT] or not is_finite(float(value)):
            value = PROFILES[profile][key]
        var bounds: Array = LIMITS[key]
        set(key,clampf(float(value),float(bounds[0]),float(bounds[1])))

func reset() -> void:
    shifts_requested = 0
    _phase = "ready"
    _hold_remaining = 0.0
    _last_clock = -1.0

static func _hold() -> Dictionary:
    return {"throttle":0.0,"clutch":1.0,"brake":1.0,"steer":0.0}

static func _shift_pedals() -> Dictionary:
    return {"throttle":0.0,"clutch":1.0,"brake":0.0,"steer":0.0}

func controls(model, clock: float, delta: float) -> Dictionary:
    if model==null or not is_instance_valid(model) or not is_finite(clock) or clock<0.0 or not is_finite(delta) or delta<0.0:
        return _hold()
    if model.config==null or not is_finite(float(model.config.redline_rpm)) or model.config.redline_rpm<=0.0:
        return _hold()
    if not is_finite(float(model.rpm)) or not is_finite(float(model.speed_mps)) or not is_finite(float(model.wheelspin)) or not is_finite(float(model.shift_timer)) or not is_finite(float(model.clutch_engagement)) or not model.engine_running:
        return _hold()
    if _last_clock>=0.0 and clock+0.001<_last_clock:
        reset()
    _last_clock = clock
    var dt := minf(delta,0.1)
    if model.gear==0:
        _phase = "ready"
        _hold_remaining = 0.0
        if model.shift_timer<=0.0 and model.clutch_engagement<=0.25:
            if model.shift(1,1.0):
                shifts_requested += 1
    if clock<GREEN_TIME+reaction_delay:
        var staged := _hold()
        var target := minf(launch_rpm,float(model.config.redline_rpm)*0.70)
        staged["throttle"] = clampf((target-float(model.rpm))/1000.0,0.0,0.85)
        return staged
    if _phase=="disengage":
        if model.clutch_engagement<=0.25 and model.shift_timer<=0.0:
            if model.shift(1,1.0):
                shifts_requested += 1
                _phase = "hold"
                _hold_remaining = shift_hold
        return _shift_pedals()
    if _phase=="hold":
        _hold_remaining = maxf(0.0,_hold_remaining-dt)
        if _hold_remaining>0.0 or model.shift_timer>0.0:
            return _shift_pedals()
        _phase = "ready"
    if model.gear>0 and model.gear<model.config.gear_ratios.size() and model.rpm>=model.config.redline_rpm*shift_fraction and model.shift_timer<=0.0 and model.clutch_engagement>0.9:
        _phase = "disengage"
        return _shift_pedals()
    var accelerator := 1.0
    if model.speed_mps<8.0:
        accelerator = launch_throttle
        if model.speed_mps>1.0 and model.wheelspin>slip_target:
            accelerator *= clampf(slip_target/maxf(float(model.wheelspin),0.001),0.45,1.0)
    return {"throttle":accelerator,"clutch":0.0,"brake":0.0,"steer":0.0}
