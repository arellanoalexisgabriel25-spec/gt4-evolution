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
    # Wait for the previous gear to synchronize. A still-revving engine after
    # clutch release is not a new rising shift point; requesting again there
    # skipped through several gears in physical validation runs.
    var synchronized := true
    if model.gear>0 and model.config.transmission_type=="manual":
        var coupled_rpm: float = model.wheel_omega*model.config.gear_ratios[model.gear-1]*model.config.final_drive*60.0/TAU
        synchronized = absf(model.rpm-coupled_rpm)<model.config.redline_rpm*0.12
    if synchronized and model.gear < model.config.gear_ratios.size() and model.rpm >= model.config.redline_rpm*shift_fraction and model.shift_timer == 0.0 and model.clutch_engagement > 0.9:
        model.shift(1,1.0)
        shift_hold = 0.22
        return {"throttle":0.0,"clutch":1.0,"brake":0.0,"steer":0.0}
    return {"throttle":0.7 if model.speed_mps<6.0 else 1.0,"clutch":0.0,"brake":0.0,"steer":0.0}

# Exercise the real preparation/alignment/ready-hold path with short fixture
# timings. Never invoke the player's former manual tree command or move cars.
# Production defaults are covered separately by the procedure's own tests.
static func await_automatic_start(scene) -> bool:
    var was_active: bool = scene.is_physics_processing()
    # A retry may already have auto-started if a caller advanced it first.
    # Never reset a live procedure independently of its timing run.
    if scene.run.phase != "preparation" or scene.paused or not scene.enabled:
        return false
    if not scene.procedure.configure(0.05,5.0,0.05):
        return false
    scene.set_physics_process(true)
    for frame in range(600):
        await scene.get_tree().physics_frame
        if scene.run.phase == "countdown":
            scene.set_physics_process(was_active)
            return true
        if scene.run.phase == "invalid" or scene.procedure.phase == "expired":
            break
    scene.set_physics_process(was_active)
    return false
