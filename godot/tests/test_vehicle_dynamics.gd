extends SceneTree

const Physics = preload("res://scripts/vehicle_physics.gd")
const Config = preload("res://scripts/vehicle_config.gd")
const Handling = preload("res://scripts/handling.gd")
const Actor = preload("res://scripts/vehicle_actor.gd")
const ChaseCamera = preload("res://scripts/chase_camera.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func model(drivetrain: String, front_bias: float):
    var car = Physics.new()
    car.config = Config.new()
    car.config.drivetrain = drivetrain
    car.config.front_weight_bias = front_bias
    return car

# Heading change and final slip for a fixed steering input at 20 m/s.
func corner(drivetrain: String, front_bias: float, throttle: float, brake: bool) -> Dictionary:
    var car = model(drivetrain, front_bias)
    car.velocity = Vector2(0, -20)
    car.transmission.gear = 3
    car.throttle = maxf(throttle, 0.0)
    var start: float = car.heading
    for i in range(48):
        car.step(1.0 / 60.0, throttle, 0.5, brake)
    return {"turn": absf(car.heading - start), "slip": car.slip}

func stopping_distance(car, speed: float) -> float:
    car.velocity = Vector2(0, -speed)
    var distance := 0.0
    for i in range(900):
        car.step(1.0 / 60.0, 0.0, 0.0, true)
        distance += car.signed_speed() / 60.0
        if car.signed_speed() < 0.01:
            break
    return distance

func speed_gain(start_speed: float) -> float:
    var car = Physics.new()
    car.velocity = Vector2(0, -start_speed)
    car.throttle = 1.0
    car.step(1.0 / 60.0, 1.0, 0.0, false)
    var before: float = car.signed_speed()
    for i in range(30):
        car.step(1.0 / 60.0, 1.0, 0.0, false)
    return car.signed_speed() - before

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    # Engine torque follows RPM.
    var engine = Physics.new()
    engine.rpm = 900.0
    var idle_torque: float = engine.torque_factor()
    engine.rpm = 4000.0
    var mid_torque: float = engine.torque_factor()
    engine.rpm = 7000.0
    var redline_torque: float = engine.torque_factor()
    check(is_equal_approx(idle_torque, 0.78) and mid_torque > 0.95 and redline_torque < 0.75, "Torque curve rises from idle, peaks mid-range and falls toward redline")
    engine.config.torque_curve = PackedFloat32Array()
    check(engine.torque_factor() == 1.0, "Empty torque curve means flat torque")
    check(speed_gain(5.0) > speed_gain(35.0) * 1.5, "Drive thrust falls off toward top speed")

    # Axle loads.
    var axle = model("FWD", 0.62)
    axle.weight_transfer = 0.0
    check(is_equal_approx(axle.axle_grip().x, 1.0) and is_equal_approx(axle.axle_grip().y, 1.0), "Static axle grip is neutral")
    axle.weight_transfer = 1.0
    check(axle.axle_grip().x < axle.axle_grip().y, "Acceleration unloads the front axle")
    axle.weight_transfer = -1.0
    check(axle.axle_grip().y < axle.axle_grip().x, "Braking unloads the rear axle")

    # Braking is limited by tires and by brake strength.
    var fresh = Physics.new()
    var worn = Physics.new()
    worn.config.grip = 0.72
    check(stopping_distance(worn, 30.0) > stopping_distance(fresh, 30.0) * 1.2, "Worn tires lengthen braking distance")
    var weak = Physics.new()
    weak.config.braking = 16.0
    var strong = Physics.new()
    check(stopping_distance(weak, 30.0) > stopping_distance(strong, 30.0) * 1.15, "Weak brakes lengthen braking distance")
    var pedal = Physics.new()
    var reverse_pedal = Physics.new()
    pedal.config.grip = 0.5
    reverse_pedal.config.grip = 0.5
    pedal.velocity = Vector2(0, -20)
    reverse_pedal.velocity = Vector2(0, -20)
    reverse_pedal.throttle = -1.0
    pedal.step(0.1, 0.0, 0.0, true)
    reverse_pedal.step(0.1, -1.0, 0.0, false)
    check(is_equal_approx(pedal.signed_speed(), reverse_pedal.signed_speed()), "Reverse pedal cannot bypass tire-limited braking while moving forward")
    pedal.reset()
    reverse_pedal.reset()
    pedal.velocity = Vector2(0, 10)
    reverse_pedal.velocity = Vector2(0, 10)
    reverse_pedal.throttle = 1.0
    pedal.step(0.1, 0.0, 0.0, true)
    reverse_pedal.step(0.1, 1.0, 0.0, false)
    check(is_equal_approx(pedal.signed_speed(), reverse_pedal.signed_speed()), "Forward pedal also respects tire braking limits while reversing")
    var brake_front = model("FWD", 0.5)
    var brake_rear = model("RWD", 0.5)
    for car in [brake_front, brake_rear]:
        car.velocity = Vector2(0, -20)
        car.throttle = -1.0
        car.step(0.1, -1.0, 0.5, false)
    check(is_equal_approx(brake_front.heading, brake_rear.heading) and is_equal_approx(brake_front.slip, brake_rear.slip), "Pedal braking does not load driven axles as propulsion")

    # Handling character at the same speed and steering.
    var results := {}
    for entry in [["FWD", 0.62], ["RWD", 0.50], ["AWD", 0.55]]:
        var kind: String = entry[0]
        var bias: float = entry[1]
        results[kind] = {
            "power": corner(kind, bias, 1.0, false),
            "coast": corner(kind, bias, 0.0, false),
            "brake": corner(kind, bias, 0.0, true)}
    for kind in results:
        var data: Dictionary = results[kind]
        check(data["power"]["turn"] < data["coast"]["turn"], "%s rotates less under power than when coasting" % kind)
        check(data["brake"]["turn"] > data["power"]["turn"] * 1.3, "%s turns in better under braking than under power" % kind)
    var fwd_ratio: float = results["FWD"]["power"]["turn"] / results["FWD"]["coast"]["turn"]
    var rwd_ratio: float = results["RWD"]["power"]["turn"] / results["RWD"]["coast"]["turn"]
    check(fwd_ratio < rwd_ratio, "Front-drive pushes wide under power more than rear-drive")
    check(results["RWD"]["power"]["slip"] > results["FWD"]["power"]["slip"] * 1.3, "Rear-drive slides more than front-drive under power")

    # Yaw saturates at the grip limit: full lock at top speed does not spin the heading ahead of velocity.
    var fast = Physics.new()
    for i in range(300):
        fast.step(1.0 / 60.0, 1.0, 0.0, false)
    for i in range(60):
        fast.step(1.0 / 60.0, 1.0, 1.0, false)
    check(fast.speed() > 30.0 and fast.slip < fast.speed() * 0.35, "Full lock at speed saturates instead of spinning")
    fast.velocity = Vector2(3, 4)
    check(fast.speed() == 5.0, "Ground speed includes lateral sliding")

    # Preset differences.
    var civic = Handling.configuration({"model": "Honda Civic EK"})
    var miata = Handling.configuration({"model": "Mazda MX-5 NA"})
    var subaru = Handling.configuration({"model": "Subaru Impreza"})
    check(civic.front_weight_bias > miata.front_weight_bias and subaru.drivetrain == "AWD", "Presets carry different weight distribution")
    check(civic.torque_curve != miata.torque_curve, "Presets carry different torque curves")

    # Chase camera widens and pulls back with speed and trails heading changes.
    var actor = Actor.new()
    root.add_child(actor)
    var camera = ChaseCamera.new()
    root.add_child(camera)
    camera.target = actor
    camera.current = true
    camera.snap()
    var resting: float = camera.global_position.distance_to(actor.global_position)
    actor.physics.velocity = Vector2(0, -35)
    camera.snap()
    var moving: float = camera.global_position.distance_to(actor.global_position)
    check(moving > resting and moving < 20.0, "Camera pulls back with speed and stays near the car")
    for i in range(60):
        camera._process(0.1)
    check(camera.fov > camera.base_fov + 5.0, "Field of view widens with speed")
    actor.physics.velocity = Vector2(35, 0)
    check(is_equal_approx(camera._speed(), 35.0), "Camera keeps speed response during a sideways slide")
    actor.rotation.y = 1.0
    camera._process(1.0 / 60.0)
    check(camera._heading > 0.0 and camera._heading < 1.0, "Camera heading trails a rapid turn")
    camera.snap()
    check(is_equal_approx(camera._heading, 1.0), "Snap realigns the camera instantly")

    if failed:
        quit(1)
    else:
        print("PASS: %d vehicle dynamics assertions" % checks)
        quit(0)
