extends SceneTree

const Axles = preload("res://scripts/axle_traction.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Tire = preload("res://scripts/tire_model.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func configuration():
    var config = Config.new()
    config.mass = 1000.0
    config.front_weight_bias = 0.5
    config.grip = 1.0
    config.drivetrain = "FWD"
    config.abs_assist = false
    return config

func hot_axles():
    var axles = Axles.new()
    axles.temperatures = Vector2(45.0,45.0)
    return axles

func rotational_energy(axles, config) -> float:
    return 0.5*config.wheel_inertia*axles.omega.length_squared()

func brake_run(config, dt: float) -> Dictionary:
    var axles = Axles.new()
    axles.omega = Vector2(30.0,20.0)
    var initial := rotational_energy(axles,config)
    var heat := 0.0
    for i in range(int(1.0/dt)):
        axles.step(dt,0.0,0.0,0.25,config,100.0,true,Vector2.ZERO)
        heat += axles.brake_power*dt
    return {"initial":initial,"remaining":rotational_energy(axles,config),"heat":heat}

func _initialize() -> void:
    var config = configuration()
    var dt := 1.0/480.0
    var air = hot_axles()
    air.forces = Vector2(4905.0,4905.0)
    air.omega = Vector2(80.0,80.0)
    var front_before: float = air.omega.x
    var rear_before: float = air.omega.y
    var force: float = air.step(dt,20.0,500.0,0.0,config,100.0,true,Vector2.ZERO)
    check(force==0.0 and air.forces==Vector2.ZERO and air.normal_loads==Vector2.ZERO,"Airborne axles lose road force and normal load immediately despite retained contact history")
    check(air.omega.x>front_before and air.omega.y==rear_before,"The airborne driven wheel receives motor torque while the free axle retains inertia")
    check(air.slip_power==0.0 and air.tread_wear_points()==0.0,"Airborne wheelspin cannot generate road-contact heat or tread abrasion")
    check(air.temperatures.x<45.0 and air.temperatures.y<45.0,"Airflow still cools unsupported wheels")
    var brake_before := rotational_energy(air,config)
    air.step(0.1,20.0,0.0,1.0,config,100.0,true,Vector2.ZERO)
    check(rotational_energy(air,config)<brake_before and air.brake_power>0.0 and not air.abs_active,"Brakes still slow airborne wheel inertia without fabricating contact or ABS engagement")

    var partial = hot_axles()
    partial.step(dt,20.0,0.0,0.0,config,100.0,true,Vector2(0.0,0.5))
    check(partial.normal_loads.x==0.0 and absf(partial.normal_loads.y-2452.5)<0.001,"A half-supported rear axle does not inherit missing front-axle weight")
    partial.step(dt,20.0,0.0,0.0,config,100.0,true,Vector2(-1.0,2.0))
    check(partial.normal_loads.x==0.0 and absf(partial.normal_loads.y-4905.0)<0.001,"Contact fractions remain bounded to the supplied axle's own support")

    for direction in [-1.0,1.0]:
        var edge = hot_axles()
        edge.forces = Vector2.ONE*4905.0*direction
        edge.omega = Vector2.ONE*20.0*(1.0+0.12*direction)/config.wheel_radius
        edge.step(dt,20.0,0.0,0.0,config,100.0,false)
        check(absf(edge.forces.x)<=1962.001 and absf(edge.forces.y)<=1962.001,"Entering a low-grip surface caps relaxed acceleration and braking forces immediately")
        check(signf(edge.forces.x)==direction and signf(edge.forces.y)==direction,"The surface limit preserves the actual sign of tire slip")
    var split = hot_axles()
    split.forces = Vector2(4905.0,4905.0)
    split.omega = Vector2.ONE*20.0*1.12/config.wheel_radius
    split.step(dt,20.0,0.0,0.0,config,100.0,true,Vector2.ONE,Vector2(0.4,1.0))
    check(absf(split.forces.x-1962.0)<0.001 and split.forces.y>1962.0,"Front and rear axles receive independent surface-grip limits")
    split.step(dt,20.0,0.0,0.0,config,100.0,true,Vector2(NAN,1.0))
    check(split.normal_loads==Vector2.ZERO and split.forces==Vector2.ZERO,"A malformed contact sample fails closed without poisoning axle state")
    var frozen: Vector2 = split.omega
    check(split.step(0.0,20.0,0.0,0.0,config,100.0,true)==0.0 and split.omega==frozen,"A zero-duration update does not divide by zero or alter wheel inertia")

    var stopping = Axles.new()
    stopping.omega = Vector2.ONE
    var energy_before := rotational_energy(stopping,config)
    stopping.step(0.1,0.0,0.0,1.0,config,100.0,true,Vector2.ZERO)
    check(stopping.omega==Vector2.ZERO and absf(stopping.brake_power*0.1-energy_before)<0.00001,"Stopping both wheels within a step accounts for all removed rotational energy as brake heat")
    stopping.step(0.1,0.0,0.0,1.0,config,100.0,true,Vector2.ZERO)
    check(stopping.brake_power==0.0,"Holding a motionless brake does not invent heat")
    var coasting = Axles.new()
    coasting.omega = Vector2(30.0,20.0)
    energy_before = rotational_energy(coasting,config)
    coasting.step(dt,0.0,0.0,0.0,config,100.0,true,Vector2.ZERO)
    check(coasting.brake_power==0.0 and rotational_energy(coasting,config)==energy_before,"A free airborne coast preserves rotational energy and registers no brake work")
    var with_drive = Axles.new()
    with_drive.omega = Vector2(30.0,20.0)
    energy_before = rotational_energy(with_drive,config)
    with_drive.step(dt,0.0,500.0,0.25,config,100.0,true,Vector2.ZERO)
    var pre_brake := Vector2(30.0+500.0*dt/config.wheel_inertia,20.0)
    var drive_energy: float = 0.5*config.wheel_inertia*pre_brake.length_squared()-energy_before
    check(absf(with_drive.brake_power*dt-(energy_before+drive_energy-rotational_energy(with_drive,config)))<0.0001,"Brake heat excludes the motor's work before the brake operator")
    var coarse := brake_run(config,1.0/60.0)
    var fine := brake_run(config,1.0/480.0)
    check(coarse.remaining==0.0 and fine.remaining==0.0 and absf(coarse.heat-coarse.initial)<0.001 and absf(fine.heat-fine.initial)<0.001,"Integrated brake heat matches the same full stop at 60 and 480 Hz")

    var tire = Tire.new()
    tire.temperature = 100.0
    tire.wear = 0.2
    tire.step_contact(1.0,100000.0,0.0,5000.0,30.0,false)
    check(tire.temperature<100.0 and tire.wear==0.2,"No-load tire samples cool without counting supplied bogus contact heat or baseline abrasion")
    var legacy = Tire.new()
    legacy.step(1.0,0.0,0.0)
    check(legacy.wear>0.0,"The existing generic tire-step behavior remains backward compatible")
    var baseline = hot_axles()
    baseline.omega = Vector2.ONE*20.0*1.12/config.wheel_radius
    baseline.step(dt,20.0,0.0,0.0,config,100.0,true)
    check(absf(baseline.normal_loads.x+baseline.normal_loads.y-9810.0)<0.001 and baseline.forces.x>0.0,"Legacy pure-model callers retain full dry-road support by default")
    if not failed: print("PASS: %d axle contact and brake-energy assertions" % checks)
    quit(1 if failed else 0)
