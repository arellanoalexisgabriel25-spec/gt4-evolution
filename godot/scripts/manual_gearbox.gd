extends RefCounted

# Gear selection is separate from crankshaft speed. With an open clutch the
# synchronizer works on the gearbox input shaft, never on the free-revving motor.
var phase := "neutral"
var input_omega := 0.0
var sync_target_rpm := 0.0
var synchronizer_work_j := 0.0
var remaining := 0.0
var elapsed := 0.0

static func ratio(gear: int, config) -> float:
    if gear<0: return -config.reverse_ratio*config.final_drive
    if gear==0: return 0.0
    return config.gear_ratios[gear-1]*config.final_drive

func select(previous: int, selected: int, wheel_speed: float, config) -> float:
    if previous!=0: input_omega = wheel_speed*ratio(previous,config)
    var target := wheel_speed*ratio(selected,config)
    sync_target_rpm = target*60.0/TAU
    var mismatch := absf(input_omega-target)
    remaining = maxf(config.shift_time,mismatch*config.gearbox_input_inertia/maxf(config.synchronizer_torque,0.1))
    remaining = minf(remaining,config.synchronizer_max_time)
    elapsed = 0.0
    phase = "shifting"
    return remaining

func advance(dt: float, selected: int, wheel_speed: float, engine_speed: float, engagement: float, config) -> void:
    if phase=="shifting":
        elapsed += dt
        var target := wheel_speed*ratio(selected,config)
        sync_target_rpm = target*60.0/TAU
        var before := input_omega
        input_omega = move_toward(input_omega,target,config.synchronizer_torque/maxf(config.gearbox_input_inertia,0.001)*dt)
        synchronizer_work_j += maxf(0.0,0.5*config.gearbox_input_inertia*(pow(before-target,2.0)-pow(input_omega-target,2.0)))
        remaining = maxf(0.0,remaining-dt)
        if remaining<=0.0:
            # A time limit cannot supply the missing synchronizer impulse. A
            # rejected dog engagement leaves the shaft at its actual speed;
            # the powertrain consumes this state once and selects neutral.
            var mismatch_rpm := absf(input_omega-target)*60.0/TAU
            if selected==0:
                phase = "neutral"
            elif mismatch_rpm<=config.synchronizer_tolerance_rpm:
                phase = "engaged"
            elif elapsed<config.synchronizer_max_time:
                # Wheel speed can change during a shift (e.g. wheelspin
                # recovery). The initial duration was an estimate, not a
                # deadline; pursue the moving target within the actual timeout.
                remaining = minf(config.synchronizer_max_time-elapsed,maxf(dt,absf(input_omega-target)*config.gearbox_input_inertia/maxf(config.synchronizer_torque,0.1)))
            else:
                phase = "rejected"
    elif phase=="rejected":
        return
    elif selected!=0:
        input_omega = wheel_speed*ratio(selected,config)
        phase = "engaged"
    else:
        input_omega = lerpf(input_omega,engine_speed,1.0-exp(-engagement*30.0*dt))
        input_omega = move_toward(input_omega,0.0,dt*20.0*(1.0-engagement))
        phase = "neutral"
