extends SceneTree

const Axles = preload("res://scripts/axle_traction.gd")
const EngineTorque = preload("res://scripts/engine_torque.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Model = preload("res://scripts/manual_powertrain.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func axle_force(mode: String) -> Dictionary:
    var config = Config.new()
    config.drivetrain = mode
    var state = Axles.new()
    state.omega = Vector2.ONE*10/config.wheel_radius
    state.filtered_acceleration = 6.0
    var total := 0.0
    for i in range(240):
        var force: float = state.step(1.0/480.0,10,2000,0,config,100,true)
        if i>120:
            total += force
    return {"force":total/119.0,"state":state,"config":config}

func kinetic(model) -> float:
    return model.config.mass*model.speed_mps*model.speed_mps*0.5+model.config.wheel_inertia*(model.axles.omega.x*model.axles.omega.x+model.axles.omega.y*model.axles.omega.y)*0.5

func stop_with(health: float, brakes: float = 100.0) -> Dictionary:
    var model = Model.new()
    model.config.tire_health = health
    model.config.brake_health = brakes
    model.speed_mps = 30
    model.wheel_omega = 30/model.config.wheel_radius
    var distance := 0.0
    var abs_seen := false
    for i in range(1200):
        model.step(1.0/120.0,0,1,1)
        distance += model.speed_mps/120.0
        abs_seen = abs_seen or model.axles.abs_active
        if model.speed_mps<0.15:
            break
    return {"distance":distance,"speed":model.speed_mps,"abs":abs_seen}

func _initialize() -> void:
    check(is_equal_approx(Axles.friction_curve(0),0.0),"Matched rolling speed does not invent longitudinal tire force")
    check(Axles.friction_curve(0.12)>Axles.friction_curve(1.0),"Grip peaks then declines progressively during wheelspin")
    check(is_equal_approx(Axles.friction_curve(-0.2),-Axles.friction_curve(0.2)),"Braking and acceleration slip have opposite physical force signs")
    var front := axle_force("FWD")
    var rear := axle_force("RWD")
    var all := axle_force("AWD")
    check(rear.force>front.force,"Rearward launch load benefits RWD while unloading the driven FWD axle")
    check(all.force>rear.force,"AWD can use both axle contact patches with the same total input torque")
    var weight: float = rear.config.mass*9.81
    check(is_equal_approx(rear.state.normal_loads.x+rear.state.normal_loads.y,weight),"Dynamic front and rear normal loads conserve total vehicle weight")
    check(rear.state.normal_loads.y>weight*0.5 and rear.state.normal_loads.x<weight*0.5,"Positive longitudinal acceleration transfers load to the rear")
    check(rear.state.omega.y>rear.state.omega.x and front.state.omega.x>front.state.omega.y,"Driven and undriven axles rotate independently during lost traction")
    var coast = Model.new()
    coast.speed_mps = 25
    coast.wheel_omega = 25/coast.config.wheel_radius
    var energy := kinetic(coast)
    for i in range(240):
        coast.step(1.0/120.0,0,1,0)
    check(coast.speed_mps<25 and kinetic(coast)<energy,"Neutral coasting dissipates energy instead of receiving hidden propulsion")
    var good_stop := stop_with(100)
    var worn_stop := stop_with(40)
    check(good_stop.speed<0.15 and worn_stop.speed<0.15,"Wheel brake torques stop the actual longitudinal model")
    check(worn_stop.distance>good_stop.distance,"Worn tires measurably increase braking distance")
    check(good_stop.abs,"ABS responds to measured locking slip rather than adding tire grip")
    var worn_brakes := stop_with(100,25)
    check(worn_brakes.speed<0.15 and worn_brakes.distance>good_stop.distance,"Mechanical brake condition affects the available braking torque")
    var turbo = EngineTorque.new()
    var config = Config.new()
    config.turbo_fraction = 0.45
    var early: float = turbo.boost_factor(0.05,5000,1,true,config)
    var late := early
    for i in range(240):
        late = turbo.boost_factor(1.0/120.0,5000,1,true,config)
    check(late>early and turbo.boost<=1.0,"Turbo torque builds over time under engine load")
    var boost_before: float = turbo.boost
    for i in range(60):
        turbo.boost_factor(1.0/120.0,5000,0,false,config)
    check(turbo.boost<boost_before*0.2,"Lifting during a change releases boost instead of retaining full torque")
    var naturally = EngineTorque.new()
    config.turbo_fraction = 0
    check(naturally.boost_factor(1,5000,1,true,config)==1.0 and naturally.boost==0,"Naturally aspirated cars do not inherit artificial turbo lag")
    var controlled = Model.new()
    controlled.config.peak_torque = 450
    controlled.traction_control = true
    controlled.gear = 2
    controlled.rpm = 6000
    controlled.speed_mps = 15
    controlled.wheel_omega = 90
    var grip: float = controlled.config.grip
    for i in range(30):
        controlled.step(1.0/120.0,1,0,0,false)
    check(controlled.tcs_cut<0.95 and controlled.config.grip==grip,"Optional TCS cuts engine delivery without increasing the tire coefficient")
    var before: float = controlled.rpm
    controlled.step(0.1,NAN,0,0)
    check(controlled.rpm==before and is_finite(controlled.speed_mps),"Non-finite pedal input cannot poison the simulation state")
    print("Axle evidence: FWD %.0f N / RWD %.0f N / AWD %.0f N; braking good %.2f m / worn %.2f m" % [front.force,rear.force,all.force,good_stop.distance,worn_stop.distance])
    if not failed:
        print("PASS: %d axle and torque assertions" % checks)
    quit(1 if failed else 0)
