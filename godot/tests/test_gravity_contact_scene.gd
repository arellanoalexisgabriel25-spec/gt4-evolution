extends SceneTree

const DragActor = preload("res://scripts/drag_actor.gd")
const Actor = preload("res://scripts/vehicle_actor.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
var checks := 0
var failed := false
const DT := 1.0/60.0
const PEDALS := {"throttle":0.0,"clutch":1.0,"brake":0.0,"steer":0.0}

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func car_at(stage: Node3D, point: Vector3):
    var car = DragActor.new()
    car.model_name = "Fiat 147 Vivace"
    car.powertrain.config = Config.from_vehicle({"model":car.model_name,"health":{"motor":100,"frenos":100,"neumaticos":100,"transmision":100}},true)
    car.powertrain.engine_running = false
    car.powertrain.rpm = 0.0
    car.position = point
    stage.add_child(car)
    return car

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var stage := Node3D.new()
    root.add_child(stage)
    var manual = car_at(stage,Vector3(-5,20,0))
    var previous_mode = Actor.new()
    previous_mode.position = Vector3(5,20,0)
    stage.add_child(previous_mode)
    for step in range(60):
        await physics_frame
        manual.drive_manual(DT,PEDALS)
        previous_mode.drive(DT,PEDALS,true)
    check(absf(manual.velocity.y+9.81)<0.002 and absf(previous_mode.velocity.y+9.81)<0.002,"Both real collision actors fall with the same project gravity, not separate hardcoded accelerations")
    check(absf(manual.position.y-(20.0-9.81*0.5))<0.10,"Measured free-fall displacement agrees with semi-implicit gravity integration")
    check(manual.sample_ground().wheels_on_ground==0 and manual.powertrain.axles.normal_loads==Vector2.ZERO,"A falling car has no phantom tire support or normal load")
    stage.queue_free()
    await process_frame
    await physics_frame

    stage = Node3D.new()
    root.add_child(stage)
    var angle := deg_to_rad(10.0)
    var ground := StaticBody3D.new()
    ground.rotation.x = angle
    ground.position.y = -0.5/cos(angle)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(100,1,100)
    collision.shape = shape
    ground.add_child(collision)
    stage.add_child(ground)
    var car = car_at(stage,Vector3(0,0.9,0))
    var holding := PEDALS.duplicate()
    holding.brake = 1.0
    for step in range(120):
        await physics_frame
        car.drive_manual(DT,holding)
    check(car.is_on_floor() and car.sample_ground().wheels_on_ground==4,"The tilted real collider and all four wheel probes settle on an actual incline")
    check(absf(car.wheel_pitch-angle)<0.001 and absf(car.get_child(0).rotation.x-angle)<0.001,"Visual/probe/collider alignment uses the measured ground plane")
    check(absf(car.powertrain.normal_g-9.81*cos(angle))<0.001 and absf(car.powertrain.grade_acceleration+9.81*sin(angle))<0.001,"The real contact normal reaches the longitudinal gravity and load model")
    var before: Vector3 = car.position
    for step in range(60):
        await physics_frame
        car.drive_manual(DT,PEDALS)
    check(car.powertrain.speed_mps< -1.0 and car.position.z>before.z+0.5,"Releasing the actual car's brake rolls its collision body backward down the slope")
    check(car.position.y<before.y and car.is_on_floor(),"Rollback follows the sloped surface rather than moving horizontally through it")
    var stopped: Vector3 = car.position
    for step in range(120):
        await physics_frame
        car.drive_manual(DT,holding)
    check(absf(car.powertrain.speed_mps)<0.02 and car.position.distance_to(stopped)<2.0,"Physical brakes stop and hold the rolling collider on the incline")
    check(car.damage.impacts==0,"Gravity, normal braking and grade alignment do not fabricate crash damage")
    print("Scene gravity evidence: pitch=",car.wheel_pitch,"; contacts=",car.sample_ground().wheels_on_ground,"; hold speed=",car.powertrain.speed_mps)
    stage.queue_free()
    await process_frame
    if not failed: print("PASS: %d physical gravity and grade assertions" % checks)
    quit(1 if failed else 0)
