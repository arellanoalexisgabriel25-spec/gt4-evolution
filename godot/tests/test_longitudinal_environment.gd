extends SceneTree

const Atmosphere = preload("res://scripts/driving_environment.gd")
const Model = preload("res://scripts/manual_powertrain.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Thermal = preload("res://scripts/brake_thermal.gd")
const Axles = preload("res://scripts/axle_traction.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func free_model(mass: float = 1000.0):
    var model = Model.new()
    model.config.mass = mass
    model.config.grip = 0.0
    model.config.drag_area = 0.0
    model.config.rolling_resistance = 0.0
    model.engine_running = false
    model.rpm = 0.0
    return model

func slope_frame(angle: float) -> Dictionary:
    var frame := Atmosphere.frame(Vector3.FORWARD,Vector3(0,cos(angle),sin(angle)),Vector3.DOWN*9.81)
    return {"normal_g":frame.normal_g,"grade_acceleration":frame.grade_acceleration}

func stop_distance(temperature: float) -> float:
    var model = Model.new()
    model.speed_mps = 100.0/3.6
    model.axles.omega = Vector2.ONE*model.speed_mps/model.config.wheel_radius
    model.brakes.temperatures = Vector2.ONE*temperature
    var distance := 0.0
    for step in range(6000):
        model.step(1.0/120.0,0.0,1.0,1.0)
        distance += absf(model.speed_mps)/120.0
        if absf(model.speed_mps)<0.02: break
    return distance

func _initialize() -> void:
    check(absf(Atmosphere.air_density(15.0,101325.0)-1.225)<0.001,"Ideal gas units reproduce standard dry-air density")
    check(Atmosphere.air_density(35.0,101325.0)<Atmosphere.air_density(15.0,101325.0),"Hotter air reduces drag density at the same pressure")
    check(Atmosphere.air_density(20.0,80000.0)<Atmosphere.air_density(20.0,101325.0),"Reduced pressure lowers density independently of temperature")
    check(Atmosphere.air_density(NAN,101325.0)==0.0 and Atmosphere.air_density(-273.15,101325.0)==0.0,"Invalid thermodynamic input cannot poison simulation state")
    var force := Atmosphere.aerodynamic_force(20.0,0.0,1.225,0.7)
    check(absf(Atmosphere.aerodynamic_force(40.0,0.0,1.225,0.7)-4.0*force)<0.000001,"Aerodynamic drag grows with relative air speed squared")
    check(Atmosphere.aerodynamic_force(20.0,-10.0,1.225,0.7)>force and Atmosphere.aerodynamic_force(20.0,10.0,1.225,0.7)<force,"Headwind and tailwind use the actual relative velocity")
    check(Atmosphere.aerodynamic_force(20.0,20.0,1.225,0.7)==0.0 and Atmosphere.aerodynamic_force(0.0,20.0,1.225,0.7)<0.0,"Matched air speed gives zero drag and a strong tailwind can push")
    var angle := deg_to_rad(10.0)
    var contact := slope_frame(angle)
    check(absf(contact.normal_g-9.81*cos(angle))<0.00001 and absf(contact.grade_acceleration+9.81*sin(angle))<0.00001,"Incline forces resolve gravity into normal and tangent components")
    var light = free_model()
    var heavy = free_model(2000.0)
    for step in range(120):
        light.step(1.0/120.0,0,1,0,true,contact)
        heavy.step(1.0/120.0,0,1,0,true,contact)
    check(absf(light.speed_mps+9.81*sin(angle))<0.0001 and light.speed_mps<0.0,"An unbraked neutral car rolls backward down the incline instead of clamping to zero")
    check(absf(light.speed_mps-heavy.speed_mps)<0.0001,"Gravity acceleration is independent of vehicle mass")
    check(absf(light.axles.normal_loads.x+light.axles.normal_loads.y-light.config.mass*contact.normal_g)<0.01,"Front and rear normal loads conserve the incline's supported weight")
    var stopped = Model.new()
    stopped.rpm = 0.0
    stopped.engine_running = false
    for step in range(240): stopped.step(1.0/120.0,0,1,1,true,contact)
    check(stopped.speed_mps==0.0 and stopped.brake_heat_j==0.0,"Static brakes hold a moderate grade without motion or fabricated heat")
    var slippery = Model.new()
    slippery.config.grip = 0.08
    slippery.rpm = 0.0
    slippery.engine_running = false
    for step in range(120): slippery.step(1.0/120.0,0,1,1,true,contact)
    check(slippery.speed_mps < -0.5,"Brakes cannot hold an incline beyond the tire friction cone")
    var still = Model.new()
    for step in range(240): still.step(1.0/120.0,0,1,0)
    check(still.speed_mps==0.0,"Rolling resistance cannot accelerate a stationary neutral car backward")
    var coast = free_model()
    coast.config.grip = 1.0
    coast.speed_mps = 12.0
    coast.axles.omega = Vector2(15.0,8.0)/coast.config.wheel_radius
    var previous: float = coast.kinetic_energy_j()
    var passive := true
    for step in range(600):
        coast.step(1.0/480.0,0,1,0)
        var energy: float = coast.kinetic_energy_j()
        # Wheel vectors use float32. Compare within its relative roundoff bound.
        if energy>previous+maxf(0.00001,previous*0.00000005): passive=false
        previous = energy
    check(passive,"Tire contact alone never creates kinetic energy even while wheel slips reverse")
    var wheel = Axles.new()
    wheel.omega = Vector2.ONE*10.01/coast.config.wheel_radius
    wheel.forces = Vector2.ONE*4905.0
    var initial: float = 0.5*coast.config.mass*100.0+0.5*coast.config.wheel_inertia*wheel.omega.length_squared()
    var force_at_contact: float = wheel.step(1.0/60.0,10.0,0.0,0.0,coast.config,100.0,true)
    var velocity: float = 10.0+force_at_contact/60.0/coast.config.mass
    var final: float = 0.5*coast.config.mass*velocity*velocity+0.5*coast.config.wheel_inertia*wheel.omega.length_squared()
    check(final<=initial+0.001,"A retained near-limit force cannot inject energy when the tire is almost synchronized at a coarse time step")
    var config = Config.new()
    var heat = Thermal.new()
    heat.step(0.1,Vector2(48000.0,0.0),0.0,config)
    check(absf(heat.temperatures.x-30.0)<0.01 and heat.temperatures.y==20.0,"Brake work in joules heats only the axle that dissipated it")
    var coarse = Thermal.new()
    var fine = Thermal.new()
    coarse.step(1.0,Vector2(48000.0,26000.0),10.0,config)
    for step in range(100): fine.step(0.01,Vector2(480.0,260.0),10.0,config)
    check(coarse.temperatures.distance_to(fine.temperatures)<0.0001,"The thermal solution is stable across time steps for constant brake power")
    var before: Vector2 = coarse.temperatures
    coarse.step(10.0,Vector2.ZERO,30.0,config)
    check(coarse.temperatures.x<before.x and coarse.temperatures.y<before.y,"Unpowered brakes cool in airflow without repairing wear")
    heat.temperatures = Vector2(700.0,20.0)
    check(heat.factors(config).x<0.5 and heat.factors(config).y==1.0,"Hot-brake fade reduces hardware torque on its own axle")
    var cold_stop := stop_distance(20.0)
    var hot_stop := stop_distance(700.0)
    check(hot_stop>cold_stop*1.15,"The same actual longitudinal car takes farther to stop with overheated brakes")
    var original: float = still.speed_mps
    still.step(0.1,1,0,0,true,{"grade_acceleration":NAN})
    check(still.speed_mps==original,"Malformed environment input rejects the update atomically")
    print("Physics evidence: neutral rollback ",light.speed_mps," m/s; 100–0 cold ",cold_stop," m / hot ",hot_stop," m")
    if not failed: print("PASS: %d longitudinal environment assertions" % checks)
    quit(1 if failed else 0)
