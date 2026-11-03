extends SceneTree

const Transmission = preload("res://scripts/transmission.gd")
const Config = preload("res://scripts/vehicle_config.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    var config = Config.new()
    var box = Transmission.new()
    box.update(0.1, 0.0, config)
    check(box.gear == 1 and box.rpm == config.idle_rpm, "Rest uses first gear and idle RPM")
    config.wheel_radius = 0.5
    config.final_drive = 2.0
    check(is_equal_approx(box.coupled_rpm(PI, 1.0, config), 120.0), "One wheel revolution per second gives 120 engine RPM with 2:1 final drive")
    check(is_equal_approx(box.coupled_rpm(PI, 2.0, config), 240.0), "Doubling gear ratio doubles engine speed")
    config = Config.new()
    box.update(0.1, 16.0, config)
    check(box.gear == 2, "Automatic box upshifts at engine threshold")
    check(box.rpm < config.upshift_rpm, "Upshift reduces RPM at constant road speed")
    var gear: int = box.gear
    for i in range(30):
        box.update(1.0 / 60.0, 16.0, config)
    check(box.gear == gear, "Hysteresis prevents repeated shifts at constant speed")
    box.reset()
    box.update(0.1, 100.0, config)
    check(box.gear == 2, "High speed requests only one gear change per update")
    box.update(0.01, 100.0, config)
    check(box.gear == 2, "Shift interval blocks immediate next shift")
    box.update(0.4, 100.0, config)
    check(box.gear == 3, "Next shift occurs after cooldown")
    check(box.rpm <= config.redline_rpm, "Tachometer is bounded by redline")
    box.update(0.4, 0.0, config)
    check(box.gear == 2, "Braking downshifts one gear at a time")
    box.update(0.4, 0.0, config)
    check(box.gear == 1, "Continued stop returns to first gear")
    box.update(0.1, -4.0, config)
    check(box.gear == -1 and box.rpm > config.idle_rpm, "Reverse uses its own ratio")
    box.update(0.1, 0.0, config)
    check(box.gear == 1, "Leaving reverse restores a forward gear")
    box.reset()
    check(box.gear == 1 and box.shift_cooldown == 0.0, "Reset clears transmission state")
    if not failed:
        print("PASS: %d transmission assertions" % checks)
    quit(1 if failed else 0)
