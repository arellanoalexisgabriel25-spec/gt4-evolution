extends SceneTree

const Physics = preload("res://scripts/vehicle_physics.gd")
const Settings = preload("res://scripts/control_settings.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    var slow = Physics.new()
    var fast = Physics.new()
    fast.velocity = Vector2(0,-40)
    slow.step(0.1,1,1,false)
    fast.step(0.1,1,1,false)
    check(slow.steering > 0.0 and slow.steering < 1.0,"Keyboard steering is progressive rather than an instant full-lock input")
    check(fast.steering < slow.steering,"High speed slows steering entry independently from throttle")
    check(is_equal_approx(fast.throttle,slow.throttle),"Steering speed filtering does not slow the accelerator")
    var previous: float = fast.steering
    fast.step(1.0/60.0,0,0,false)
    check(previous-fast.steering > fast.config.steering_response/(1.0+40.0/60.0)/60.0,"Releasing steering recentres faster than turn-in at high speed")
    for i in range(90):
        fast.step(1.0/60.0,0,0,false)
    check(fast.steering == 0.0 and is_finite(fast.heading),"Released steering returns to exactly neutral without unstable heading")
    var settings = Settings.new()
    settings.apply()
    Input.action_press("evo_right")
    check(is_equal_approx(settings.read_controls()["steer"],0.8),"Default keyboard steering uses the gentler configurable range")
    settings.keyboard_steering = 0.5
    check(is_equal_approx(settings.read_controls()["steer"],0.5),"Sensitivity changes the actual normalized keyboard command")
    Input.action_release("evo_right")
    var sample: Dictionary = Settings.pad_sample(1,0,0,false,0.18)
    check(sample["steer"] == 1.0,"Keyboard sensitivity does not reduce full analog steering range")
    if not failed:
        print("PASS: %d steering response assertions" % checks)
    quit(1 if failed else 0)
