extends SceneTree

const Settings = preload("res://scripts/control_settings.gd")
const Physics = preload("res://scripts/vehicle_physics.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func key(code: int, pressed: bool) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.pressed = pressed
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func _initialize() -> void:
    var settings = Settings.new()
    settings.apply()
    check(settings.keys["accelerate"] == KEY_W, "Default controls preserve W acceleration")
    key(KEY_W, true)
    check(settings.read_controls()["throttle"] == 1.0, "Physical key event supplies acceleration")
    check(settings.bind("accelerate", KEY_I).is_empty(), "Acceleration can be rebound")
    check(settings.read_controls()["throttle"] == 0.0, "Remapping a held key releases its old action")
    key(KEY_W, false)
    key(KEY_I, true)
    check(settings.read_controls()["throttle"] == 1.0, "New binding controls acceleration")
    key(KEY_I, false)
    key(KEY_UP, true)
    check(settings.read_controls()["throttle"] == 1.0, "Arrow fallback remains usable after remapping")
    key(KEY_UP, false)
    var old: Dictionary = settings.to_dict()
    check(not settings.bind("accelerate", KEY_P).is_empty() and settings.to_dict() == old, "Duplicate binding cannot steal pause")
    check(not settings.bind("pause", KEY_ESCAPE).is_empty(), "Escape remains a fixed exit/cancel key")
    check(Settings.axis(0.1, 0.18) == 0.0 and Settings.axis(-0.1, 0.18) == 0.0, "Stick drift is suppressed inside deadzone")
    check(is_equal_approx(Settings.axis(0.59, 0.18), 0.5), "Stick range is rescaled smoothly after deadzone")
    check(Settings.axis(1.0, 0.18) == 1.0 and Settings.axis(-1.0, 0.18) == -1.0, "Full steering range is retained")
    var sample := Settings.pad_sample(0.0, 1.0, 0.0, false, 0.18)
    check(sample["throttle"] == 1.0 and sample["brake"] == 0.0, "Right trigger accelerates")
    sample = Settings.pad_sample(0.0, 0.0, 0.59, true, 0.18)
    check(sample["throttle"] == -1.0 and is_equal_approx(sample["brake"], 0.5), "Controller reverse and proportional brake are separate")
    var light = Physics.new()
    var strong = Physics.new()
    light.velocity = Vector2(0, -20)
    strong.velocity = Vector2(0, -20)
    light.step(0.1, 0.0, 0.0, true, true, 0.25)
    strong.step(0.1, 0.0, 0.0, true, true, 1.0)
    check(strong.signed_speed() < light.signed_speed() and light.signed_speed() < 20.0, "Trigger pressure changes actual braking force")
    var path := "user://controls-test-%d.json" % Time.get_ticks_usec()
    settings.deadzone = 0.25
    check(settings.save_file(path) == OK, "Custom controls write to a real settings file")
    var restored = Settings.new()
    check(restored.load_file(path) and restored.keys["accelerate"] == KEY_I and restored.deadzone == 0.25, "Settings reload independently from a game save")
    var valid_file := FileAccess.get_file_as_string(path)
    settings.deadzone = NAN
    check(settings.save_file(path) != OK and FileAccess.get_file_as_string(path) == valid_file, "Invalid settings cannot overwrite the previous file")
    old = restored.to_dict()
    var invalid := old.duplicate(true)
    invalid["keys"]["pause"] = invalid["keys"]["accelerate"]
    check(not restored.from_dict(invalid) and restored.to_dict() == old, "Invalid load preserves valid settings")
    restored.restore_defaults()
    check(restored.keys == Settings.DEFAULT_KEYS and restored.deadzone == 0.18, "Restore defaults resets keyboard and deadzone")
    DirAccess.remove_absolute(path)
    if not failed:
        print("PASS: %d control setting assertions" % checks)
    quit(1 if failed else 0)
