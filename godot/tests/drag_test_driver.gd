extends RefCounted

# Deterministic test/capture driver, never enabled by the player's game mode.
var shift_fraction := 0.92
var launch_rpm := 3400.0
var reaction_delay := 0.12
var shift_hold := 0.0

func controls(model, clock: float, delta: float) -> Dictionary:
    if model.gear == 0 and model.shift_timer == 0.0:
        model.shift(1,1.0)
    if clock < 2.0+reaction_delay:
        return {"throttle":clampf((launch_rpm-model.rpm)/1100.0,0,0.8),"clutch":1.0,"brake":1.0,"steer":0.0}
    if shift_hold > 0.0:
        shift_hold = maxf(0,shift_hold-delta)
        return {"throttle":0.0,"clutch":1.0,"brake":0.0,"steer":0.0}
    if model.gear < model.config.gear_ratios.size() and model.rpm >= model.config.redline_rpm*shift_fraction and model.shift_timer == 0.0 and model.clutch_engagement > 0.9:
        model.shift(1,1.0)
        shift_hold = 0.22
        return {"throttle":0.0,"clutch":1.0,"brake":0.0,"steer":0.0}
    return {"throttle":0.7 if model.speed_mps<6.0 else 1.0,"clutch":0.0,"brake":0.0,"steer":0.0}
