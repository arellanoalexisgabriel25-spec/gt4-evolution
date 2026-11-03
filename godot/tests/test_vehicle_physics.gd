extends SceneTree

const Physics = preload("res://scripts/vehicle_physics.gd")
const Handling = preload("res://scripts/handling.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func run_for(model, seconds: float, throttle: float, steer: float = 0.0, brake: bool = false, road: bool = true, hz: int = 60) -> void:
    for i in range(roundi(seconds * hz)):
        model.step(1.0 / hz, throttle, steer, brake, road)

func _initialize() -> void:
    var car = Physics.new()
    car.step(1.0 / 60.0, 1.0, 1.0, false)
    check(car.throttle > 0.0 and car.throttle < 1.0, "Throttle builds progressively")
    check(car.steering > 0.0 and car.steering < 1.0, "Steering builds progressively")
    car.reset()
    run_for(car, 5.0, 1.0)
    check(car.signed_speed() > 30.0 and car.signed_speed() <= car.config.top_speed + 0.01, "Car accelerates within speed cap")
    check(car.weight_transfer > 0.0, "Acceleration shifts load rearward")
    check(car.gear > 1 and car.rpm >= 900.0 and car.rpm <= 7000.0, "Automatic gears and RPM update")
    var speed: float = car.signed_speed()
    run_for(car, 0.5, 0.0, 0.0, true)
    check(car.signed_speed() < speed and car.weight_transfer < 0.0, "Braking reduces speed and shifts load forward")
    run_for(car, 3.0, 0.0, 0.0, true)
    check(absf(car.signed_speed()) < 0.01, "Brake stops without reversing")
    run_for(car, 3.0, -1.0)
    check(car.signed_speed() < -1.0 and car.gear == -1, "Reverse engages from rest")
    check(car.signed_speed() >= -car.config.reverse_speed - 0.01, "Reverse speed is limited")
    car.reset()
    run_for(car, 3.0, 1.0)
    run_for(car, 1.0, 1.0, 1.0)
    check(car.slip > 0.5, "Hard cornering retains lateral slip")
    var corner_slip: float = car.slip
    run_for(car, 3.0, 0.0)
    check(car.slip < corner_slip, "Straightening recovers grip")
    car.reset()
    check(car.velocity == Vector2.ZERO and car.slip == 0.0, "Reset removes momentum and slip")
    var dry = Physics.new()
    var grass = Physics.new()
    run_for(dry, 5.0, 1.0)
    run_for(grass, 5.0, 1.0, 0.0, false, false)
    check(grass.signed_speed() < dry.signed_speed() * 0.6, "Grass slows the car")
    var front = Physics.new()
    var rear = Physics.new()
    front.config.drivetrain = "FWD"
    rear.config.drivetrain = "RWD"
    run_for(front, 2.0, 1.0, 0.7)
    run_for(rear, 2.0, 1.0, 0.7)
    check(front.velocity.distance_to(rear.velocity) > 0.2, "Driven axle changes cornering trajectory")
    var vehicle := {"model": "Mazda MX-5 NA", "health": {"motor": 80.0, "frenos": 80.0, "neumaticos": 80.0}}
    var civic := vehicle.duplicate(true)
    civic["model"] = "Honda Civic EK"
    check(Handling.configuration(vehicle).drivetrain == "RWD" and Handling.configuration(civic).drivetrain == "FWD", "Garage selects distinct vehicle configurations")
    check(Handling.configuration(vehicle).acceleration > Handling.configuration(civic).acceleration, "Two presets have different acceleration")
    var sixty = Physics.new()
    var fast = Physics.new()
    run_for(sixty, 4.0, 1.0)
    run_for(fast, 4.0, 1.0, 0.0, false, true, 120)
    check(sixty.velocity.distance_to(fast.velocity) < 0.25, "Straight acceleration is stable across tick rates")
    var repeat = Physics.new()
    run_for(repeat, 4.0, 1.0)
    check(sixty.velocity == repeat.velocity, "Same inputs produce identical results")
    if not failed:
        print("PASS: %d vehicle physics assertions" % checks)
    quit(1 if failed else 0)
