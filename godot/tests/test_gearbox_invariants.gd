extends SceneTree

const Model = preload("res://scripts/manual_powertrain.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Gearbox = preload("res://scripts/manual_gearbox.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    var config = Config.new()
    config.gear_ratios = PackedFloat32Array([3.4,2.1,1.5,1.15,0.9,0.75])
    check(Gearbox.ratio(6,config)>0.0 and Gearbox.ratio(6,config)<Gearbox.ratio(5,config),"The same gearbox accepts an explicit six-speed data resource")
    check(Gearbox.ratio(-1,config)<0.0 and Gearbox.ratio(0,config)==0.0,"Reverse and neutral have signed, distinct mechanical ratios")
    # Efficiency must dissipate power with both shaft directions and both torque
    # directions; using the sign of torque alone gets reverse engine braking wrong.
    for shaft_speed in [-100.0,100.0]:
        for clutch_torque in [-80.0,80.0]:
            for ratio in [-12.0,12.0]:
                var wheel_speed: float = shaft_speed/ratio
                var wheel_torque: float = Model.transmitted_torque(clutch_torque,ratio,0.9,shaft_speed)
                var crank_power: float = clutch_torque*shaft_speed
                var axle_power: float = wheel_torque*wheel_speed
                check(crank_power-axle_power>=-0.000001,"Signed gear power flow always dissipates energy, including reverse/coast")
    var synchronizer = Gearbox.new()
    var duration: float = synchronizer.select(2,3,30.0,config)
    check(duration>=config.shift_time and synchronizer.phase=="shifting","Lever selection starts a finite synchronizer interval")
    var previous_error: float = absf(synchronizer.input_omega-30.0*Gearbox.ratio(3,config))
    var previous_work := 0.0
    for i in range(120):
        synchronizer.advance(1.0/240.0,3,30.0,600.0,0.0,config)
        var error: float = absf(synchronizer.input_omega-30.0*Gearbox.ratio(3,config))
        if error>previous_error+0.000001 or synchronizer.synchronizer_work_j<previous_work:
            failed = true
            push_error("Synchronizer creates mismatch energy instead of dissipating it")
        previous_error = error
        previous_work = synchronizer.synchronizer_work_j
    check(synchronizer.phase=="engaged" and previous_error<0.00001 and previous_work>0.0,"Shaft synchronization converges without changing the independent engine")
    var moving_target = Gearbox.new()
    var initial_duration: float = moving_target.select(2,3,30.0,config)
    var extended := false
    for i in range(120):
        moving_target.advance(1.0/240.0,3,30.0 if i<35 else 10.0,600.0,0.0,config)
        if moving_target.elapsed>initial_duration and moving_target.phase=="shifting": extended = true
    check(extended,"A recovering wheel changes the synchronizer target and can extend the initial duration estimate")
    check(moving_target.phase=="engaged" and absf(moving_target.input_omega-10.0*Gearbox.ratio(3,config))<0.00001,"A moving target can synchronize within the real timeout without a false rejection")
    var weak_config = Config.new()
    weak_config.synchronizer_torque = 0.1
    weak_config.synchronizer_max_time = 0.04
    var weak = Gearbox.new()
    weak.select(1,2,100.0,weak_config)
    var shaft_before: float = weak.input_omega
    for i in range(20): weak.advance(1.0/240.0,2,100.0,600.0,0.0,weak_config)
    check(weak.phase=="rejected" and absf(weak.input_omega-100.0*Gearbox.ratio(2,weak_config))*60.0/TAU>weak_config.synchronizer_tolerance_rpm,"A finite-time synchronizer cannot force an unmatched dog engagement")
    check(absf(weak.input_omega-shaft_before)<1.0,"Timeout preserves actual shaft momentum instead of teleporting to the target")
    var blocked = Model.new()
    blocked.config.synchronizer_torque = 0.1
    blocked.config.synchronizer_max_time = 0.04
    blocked.gear = 1
    blocked.speed_mps = 25.0
    blocked.wheel_omega = 25.0/blocked.config.wheel_radius
    blocked.rpm = 5000.0
    check(blocked.shift(1,1.0),"A lever attempt can begin before synchronizer failure becomes observable")
    for i in range(10): blocked.step(1.0/120.0,1.0,1.0,0.0)
    check(blocked.gear==0 and blocked.missed_shifts==1 and blocked.shift_quality=="rejected" and blocked.wear.transmision>0.0,"A timed-out physical change falls to neutral with one rejected event and damage")
    check(blocked.wheel_torque_nm==0.0 and blocked.rpm>4000.0,"Failed synchronization never reconnects engine power or assigns wheel-imposed engine RPM")
    var pedal = Model.new()
    pedal.config.clutch_release_pedal = 0.9
    check(pedal.request_shift(1,0.8),"A lever edge may wait briefly for the configured clutch release threshold")
    pedal.step(0.02,1.0,0.8,0.0)
    check(pedal.gear==0 and pedal.pending_shift_direction==1 and pedal.missed_shifts==0,"A configurable pedal threshold does not reject the gear before its input window expires")
    pedal.step(0.02,1.0,1.0,0.0)
    check(pedal.gear==1 and pedal.pending_shift_direction==0 and pedal.missed_shifts==0,"Finishing the clutch stroke within the window accepts the held-throttle shift")
    var rejected = Model.new()
    rejected.gear = 2
    rejected.rpm = 6100.0
    rejected.speed_mps = 20.0
    rejected.wheel_omega = 20.0/rejected.config.wheel_radius
    var rpm_before: float = rejected.rpm
    check(not rejected.shift(1,0.0),"An unmatched clutchless request is mechanically rejected")
    check(rejected.gear==2 and rejected.rpm==rpm_before and rejected.wear.transmision>0.0,"Rejection preserves the existing selected gear and engine speed while recording wear")
    rejected.wear.motor = 86.0
    rejected.reset()
    check(not rejected.engine_running and rejected.wear.motor==86.0,"Recovery never repairs a persistently damaged engine")
    if not failed: print("PASS: %d gearbox invariant assertions" % checks)
    quit(1 if failed else 0)
