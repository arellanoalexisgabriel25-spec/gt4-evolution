extends SceneTree

const Pitch = preload("res://scripts/suspension_pitch.gd")
const Differential = preload("res://scripts/axle_differential.gd")
const Axles = preload("res://scripts/axle_traction.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Surfaces = preload("res://scripts/track_surface.gd")
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
    config.drivetrain = "FWD"
    config.grip = 1.0
    config.abs_assist = false
    return config

func split_force(kind: String) -> Dictionary:
    var config = configuration()
    config.differential_type = kind
    var axle = Axles.new()
    axle.temperatures = Vector2(45,45)
    axle.omega = Vector2(40.0,10.0)/config.wheel_radius
    var samples := [{"contact":1.0,"grip":1.0},{"contact":1.0,"grip":0.1},{"contact":1.0,"grip":1.0},{"contact":1.0,"grip":1.0}]
    for frame in range(120):
        axle.step(1.0/480.0,10.0,4000.0,0.0,config,100.0,true,Vector2.ONE,Vector2(0.55,1.0),0.0,9.81,0.0,Vector2.ONE,samples)
    return {"force":axle.forces.x,"cap":axle.differential_capacities.x,"normal":axle.normal_loads,"omega":axle.omega}

func _initialize() -> void:
    check(Differential.capacity(1000,4000,"open",3.0,0.0)==2000.0,"An open differential transmits equal wheel torque limited by the weaker contact")
    check(Differential.capacity(1000,4000,"limited_slip",3.0,0.0)==4000.0,"A finite three-to-one bias reaches only the permitted strong-side traction")
    check(Differential.capacity(1000,4000,"locked",3.0,0.0)==5000.0,"Locked traction uses both contact capacities without increasing their sum")
    check(Differential.capacity(0,4000,"open",3.0,0.0)==0.0,"An open differential cannot pull through a completely unsupported wheel")
    check(Differential.capacity(0,4000,"limited_slip",3.0,500.0)==500.0,"Limited-slip preload supplies a finite reaction when one contact is absent")
    check(Differential.capacity(1000,4000,"limited_slip",100.0,10000.0)<=5000.0,"Bias and preload can never exceed the physical tire envelope")
    check(Differential.capacity(NAN,4000,"open",3.0,0.0)==0.0,"Malformed differential data cannot poison contact state")
    var open := split_force("open")
    var limited := split_force("limited_slip")
    var locked := split_force("locked")
    check(open.force>0 and limited.force>open.force and locked.force>limited.force,"The live axle produces distinct open/LSD/locked propulsion on split grip")
    check(open.normal==limited.normal and limited.normal==locked.normal,"Differential choice neither creates vehicle weight nor redistributes missing support")
    check(open.force<=open.cap and limited.force<=limited.cap and locked.force<=locked.cap,"Each actual tire force remains inside its differential envelope")
    var config = configuration()
    var air = Axles.new()
    air.omega = Vector2(40.0,10.0)/config.wheel_radius
    var partial := [{"contact":1.0,"grip":1.0},{"contact":0.0,"grip":0.0},{"contact":1.0,"grip":1.0},{"contact":1.0,"grip":1.0}]
    air.step(1.0/480.0,10.0,4000.0,0.0,config,100.0,true,Vector2(0.5,1),Vector2.ONE,0.0,9.81,0.0,Vector2.ONE,partial)
    check(air.forces.x==0.0 and absf(air.normal_loads.x-2452.5)<0.001,"An airborne driven wheel removes open-diff traction without inventing load on its mate")
    var samples := Surfaces.combine([Surfaces.at(Vector3.ZERO),Surfaces.at(Vector3(10,0,0)),{},{}])
    check(samples.wheel_surfaces.size()==4 and samples.wheel_surfaces[0].grip==1.0 and samples.wheel_surfaces[1].grip==0.52 and samples.wheel_surfaces[2].contact==0.0,"Four real surface samples retain left/right grip and unsupported wheels")
    var before: Vector2 = air.omega
    air.step(0.1,10.0,4000.0,0.0,config,100.0,true,Vector2.ONE,Vector2.ONE,0.0,9.81,0.0,Vector2.ONE,[{},{}])
    check(air.omega==before,"An incomplete per-wheel sample rejects the update before changing wheel inertia")
    var pitch = Pitch.new()
    var moment := 5000.0
    var first: float = pitch.step(1.0/480.0,moment,config)
    check(first>0.0 and first<moment and pitch.angle_rad>0.0,"Sprung-body load transfer builds through spring/damper motion instead of appearing instantaneously")
    var coarse = Pitch.new()
    var fine = Pitch.new()
    for frame in range(30): coarse.step(1.0/30.0,moment,config)
    for frame in range(480): fine.step(1.0/480.0,moment,config)
    check(absf(coarse.angle_rad-fine.angle_rad)<0.0000001 and absf(coarse.angular_velocity-fine.angular_velocity)<0.0000001,"The exact pitch response agrees at 30 and 480 Hz for the same moment")
    for damping in [0.0,config.suspension_pitch_damping_nms_rad,2.0*sqrt(config.suspension_pitch_inertia_kg_m2*config.suspension_pitch_stiffness_nm_rad),4.0*sqrt(config.suspension_pitch_inertia_kg_m2*config.suspension_pitch_stiffness_nm_rad)]:
        var candidate = config.duplicate()
        candidate.suspension_pitch_damping_nms_rad = damping
        var free = Pitch.new()
        free.angle_rad = 0.05
        free.angular_velocity = 0.2
        var initial: float = free.energy_j(candidate)
        var previous := initial
        var passive := true
        for frame in range(120):
            free.step(1.0/60.0,0.0,candidate)
            var energy: float = free.energy_j(candidate)
            if energy>previous+0.000001: passive=false
            previous = energy
        check(passive,"A free suspension oscillator never creates spring/rotational energy across damping regimes")
        check(absf(previous-initial)<0.00001 if damping==0.0 else previous<initial,"Undamped pitch conserves energy while actual damping dissipates it")
    var healthy = Pitch.new()
    var worn = Pitch.new()
    var worn_config = config.duplicate()
    worn_config.suspension_health = 0.0
    healthy.angle_rad = 0.05
    worn.angle_rad = 0.05
    for frame in range(120):
        healthy.step(1.0/60.0,0.0,config)
        worn.step(1.0/60.0,0.0,worn_config)
    check(worn.energy_j(worn_config)>healthy.energy_j(config),"Worn dampers leave more residual sprung-body oscillation")
    var loads = Axles.new()
    loads.filtered_acceleration = 6.0
    loads.step(1.0/480.0,0.0,0.0,0.0,config,100.0,true)
    check(absf(loads.normal_loads.x+loads.normal_loads.y-config.mass*9.81)<0.001 and loads.normal_loads.x<config.mass*9.81*0.5,"Dynamic suspension transfers load without creating or losing supported weight")
    check(loads.forces==Vector2.ZERO,"Suspension motion alone cannot propel a stationary car")
    print("Chassis evidence: split-grip forces ",open.force," / ",limited.force," / ",locked.force," N; pitch ",coarse.angle_rad," rad")
    if not failed: print("PASS: %d suspension and differential assertions" % checks)
    quit(1 if failed else 0)
