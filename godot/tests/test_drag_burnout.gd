extends SceneTree

# Real engine -> clutch -> driven axle -> slip/contact heat. This suite never
# calls Tire.burnout(), changes a stock curve, or grants a preparation heat bonus.
const Manual = preload("res://scripts/manual_powertrain.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Axles = preload("res://scripts/axle_traction.gd")
const Actor = preload("res://scripts/drag_actor.gd")
const Torque = preload("res://scripts/engine_torque.gd")
const MODELS := ["Fiat 147 Vivace", "Fiat Uno Fire 3 puertas", "Fiat 500 Sport"]
var checks := 0
var failed := false
var fixture: Node3D

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func vehicle(name: String) -> Dictionary:
    return {"model":name,"upgrades":[],"health":{"motor":100.0,"transmision":100.0,"neumaticos":100.0,"frenos":100.0,"suspension":100.0,"chasis":100.0}}

func configuration(name: String):
    return Config.from_vehicle(vehicle(name),true)

func warmup(name: String, handbrake: float = 1.0, support: Vector2 = Vector2.ONE, rate: int = 60) -> Dictionary:
    var model = Manual.new()
    model.config = configuration(name)
    model.reset(false)
    model.shift(1,1.0)
    var dt := 1.0/float(rate)
    var contact := {"contact":support,"grip":Vector2.ONE,"rolling":1.0}
    for i in range(roundi(1.5*rate)):
        model.step(dt,0.75,1.0,0.0,true,contact,handbrake)
    var distance := 0.0
    var peak_slip := 0.0
    var peak_power := 0.0
    for i in range(5*rate):
        model.step(dt,1.0,0.0,0.0,true,contact,handbrake)
        distance += model.speed_mps*dt
        peak_slip = maxf(peak_slip,model.axles.drive_slip(model.config))
        peak_power = maxf(peak_power,model.engine_power_kw)
    return {"model":model,"distance":distance,"peak_slip":peak_slip,"peak_power_kw":peak_power}

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    for name in MODELS:
        var reference = configuration(name)
        var rated: Dictionary = Torque.maximum_power(reference)
        var result: Dictionary = warmup(name)
        var model = result.model
        check(model.config.factory_class and model.config.drivetrain=="FWD" and model.config.tire_compound=="street","The preparation uses an unmodified factory FWD car on street tires: "+name)
        check(model.config.peak_torque==reference.peak_torque and model.config.mass==reference.mass and model.config.gear_ratios==reference.gear_ratios,"Warming does not alter the stock torque, mass or gearbox: "+name)
        check(model.engine_running and model.gear==1 and result.peak_slip>0.5,"Throttle and a real clutch release spin the actual driven axle with handbrake held: "+name)
        check(model.axles.temperatures.x>40.0 and model.axles.temperatures.x>model.axles.temperatures.y+8.0,"The driven front tires warm from real slip more than the dragged rear tires: "+name)
        check(model.axles.tires[0].wear>0.0 and model.wear.neumaticos>0.0 and model.tire_heat_j>0.0,"The same contact dissipates heat and records tread wear rather than a free temperature award: "+name)
        check(model.engine_work_j>model.tire_heat_j and result.peak_power_kw<=float(rated.kw)*1.01,"Warming uses work supplied by the existing stock power curve: "+name)
        check(result.distance>5.0 and result.distance<25.0,"A five-second dry warmup creeps forward and is not falsely presented as stationary: "+name)
        var free: Dictionary = warmup(name,0.0)
        check(free.distance>result.distance+1.0 and free.model.speed_mps>model.speed_mps,"Rear handbrake measurably resists forward motion without braking the driven front axle directly: "+name)
        var airborne: Dictionary = warmup(name,1.0,Vector2.ZERO)
        check(airborne.model.axles.omega.x>0.0 and airborne.model.axles.omega.y==0.0,"A raised front drive axle may spin while the rear handbrake holds its axle: "+name)
        check(airborne.model.tire_heat_j==0.0 and airborne.model.wear.neumaticos==0.0 and airborne.model.axles.temperatures==Vector2.ONE*20.0,"Airborne wheelspin cannot produce contact heat, tread wear or warming: "+name)
        print("Dry manual warmup %s / 5 s: %.3f m, front %.2f C / rear %.2f C, tread %.6f / %.6f, peak %.2f kW" % [name,result.distance,model.axles.temperatures.x,model.axles.temperatures.y,model.axles.tires[0].wear,model.axles.tires[1].wear,result.peak_power_kw])

    var open_clutch = Manual.new()
    open_clutch.config = configuration(MODELS[0])
    open_clutch.reset(false)
    open_clutch.shift(1,1.0)
    for i in range(300): open_clutch.step(1.0/60.0,1.0,1.0,0.0,true,{},1.0)
    check(open_clutch.rpm>5000.0 and open_clutch.axles.omega==Vector2.ZERO and open_clutch.speed_mps==0.0,"Revving with clutch fully open cannot spin the wheels or move the car")
    check(open_clutch.tire_heat_j==0.0 and open_clutch.axles.temperatures==Vector2.ONE*20.0,"Revving without contact slip does not heat stationary tires")
    var coarse: Dictionary = warmup(MODELS[0],1.0,Vector2.ONE,60)
    var fine: Dictionary = warmup(MODELS[0],1.0,Vector2.ONE,120)
    check(coarse.model.axles.temperatures.distance_to(fine.model.axles.temperatures)<0.1 and absf(float(coarse.model.wear.neumaticos)-float(fine.model.wear.neumaticos))<0.001,"The physical preparation gives consistent heat and wear at 60 and 120 Hz")

    var parking_config = configuration("Fiat 500 Sport")
    var parking = Axles.new()
    parking.omega = Vector2(30.0,30.0)
    var front_before: float = parking.omega.x
    parking.step(0.1,0.0,0.0,0.0,parking_config,100.0,true,Vector2.ZERO,Vector2.ONE,1.0)
    check(parking.omega.x==front_before and parking.omega.y==0.0,"Mechanical handbrake removes rotational energy only from the rear axle")
    check(parking.brake_power>0.0 and parking.slip_power==0.0 and parking.temperatures==Vector2.ONE*20.0,"An airborne mechanical brake dissipates brake work without fabricating tire heat")
    var abs_parking = Axles.new()
    var abs_free = Axles.new()
    abs_parking.omega = Vector2(20.0/parking_config.wheel_radius,5.0)
    abs_free.omega = abs_parking.omega
    abs_parking.step(0.05,20.0,0.0,0.1,parking_config,100.0,true,Vector2.ONE,Vector2.ONE,1.0)
    abs_free.step(0.05,20.0,0.0,0.1,parking_config,100.0,true,Vector2.ONE,Vector2.ONE,0.0)
    check(parking_config.abs_assist and abs_parking.abs_active and abs_parking.omega.y==0.0 and abs_free.omega.y>0.0,"Hydraulic ABS modulation cannot release the independent rear parking brake")
    check(absf(abs_parking.omega.x-abs_free.omega.x)<0.000001,"Adding the mechanical parking brake does not alter front hydraulic brake modulation")

    fixture = Node3D.new()
    root.add_child(fixture)
    var ground := StaticBody3D.new()
    ground.collision_layer = 1
    ground.collision_mask = 0
    ground.position = Vector3(0,-0.05,-25)
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(20,0.1,100)
    collider.shape = shape
    ground.add_child(collider)
    fixture.add_child(ground)
    for name in MODELS:
        var actor = Actor.new()
        actor.model_name = name
        actor.powertrain.config = configuration(name)
        actor.powertrain.reset(false)
        actor.position = Vector3(-3.75,0.5,-5.0)
        actor.collision_layer = 2
        actor.collision_mask = 1
        fixture.add_child(actor)
        await physics_frame
        await physics_frame
        check(actor.sample_ground().wheels_on_ground==4,"The actual warming actor samples all four asphalt contacts: "+name)
        actor.powertrain.shift(1,1.0)
        for i in range(90):
            await physics_frame
            actor.drive_manual(1.0/60.0,{"throttle":0.75,"clutch":1.0,"brake":0.0,"handbrake":1.0})
        for i in range(300):
            await physics_frame
            actor.drive_manual(1.0/60.0,{"throttle":1.0,"clutch":0.0,"brake":0.0,"handbrake":1.0})
        var distance: float = -actor.position.z-5.0
        check(distance>5.0 and -actor.position.z<35.0 and absf(actor.position.x+3.75)<0.05,"A real five-second dry warmup remains forward of the start and within the bounded 35 m area: "+name)
        check(actor.powertrain.axles.temperatures.x>40.0 and actor.powertrain.wear.neumaticos>0.0 and actor.ground_state.wheels_on_ground==4,"Real actor handbrake controls propagate into axle slip, temperature and wear: "+name)
        print("Dry physical warmup %s / 5 s: %.3f m, track position %.3f m, front %.2f C / rear %.2f C" % [name,distance,-actor.position.z,actor.powertrain.axles.temperatures.x,actor.powertrain.axles.temperatures.y])
        actor.free()
        await physics_frame
    fixture.free()
    if not failed: print("PASS: %d physical drag burnout assertions" % checks)
    quit(1 if failed else 0)
