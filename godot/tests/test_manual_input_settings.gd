extends SceneTree

const Settings = preload("res://scripts/control_settings.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func key(code: int, pressed: bool, shift: bool = false) -> InputEventKey:
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.pressed = pressed
    event.shift_pressed = shift
    Input.parse_input_event(event)
    Input.flush_buffered_events()
    return event

func _initialize() -> void:
    var settings = Settings.new()
    settings.apply()
    check(settings.shift_mode=="manual" and not settings.auto_rev_match,"New games default to full manual with no rev-matching assistance")
    var legacy: Dictionary = settings.to_dict()
    legacy.erase("shift_mode")
    legacy.erase("auto_rev_match")
    check(settings.from_dict(legacy) and settings.shift_mode=="manual" and not settings.auto_rev_match,"Existing controls_v1 files add explicit manual defaults without changing key bindings")
    var path := "user://manual-assists-settings.json"
    for mode in Settings.SHIFT_MODES:
        settings.shift_mode = mode
        settings.auto_rev_match = mode!="manual"
        check(settings.save_file(path)==OK,"Every transmission assistance mode can be persisted")
        var loaded = Settings.new()
        check(loaded.load_file(path) and loaded.to_dict()==settings.to_dict(),"Assistance choice survives actual JSON serialization alongside all previous preferences")
    var before: Dictionary = settings.to_dict().duplicate(true)
    for bad in [{"shift_mode":"auto_everything"},{"shift_mode":1},{"auto_rev_match":"true"}]:
        var corrupt := before.duplicate(true)
        corrupt.merge(bad,true)
        check(not settings.from_dict(corrupt) and settings.to_dict()==before,"Invalid assistance data cannot partially mutate existing valid controls")
    settings.restore_defaults()
    key(KEY_W,true)
    key(KEY_C,true)
    var lever := key(KEY_E,true,true)
    check(settings.read_controls(true).throttle==1.0 and settings.clutch_input()==1.0,"Actual accelerator and clutch states coexist while the lever is pressed")
    check(settings.key_event_pressed(lever,"shift_up"),"The physical lever edge is recognized even with an unrelated modifier")
    Input.action_release(Settings.action("accelerate"))
    Input.action_release(Settings.action("clutch"))
    check(settings.read_controls(true).throttle==1.0 and settings.clutch_input()==1.0,"Physical pedal polling survives an independently released InputMap action without inventing a held-key latch")
    key(KEY_W,false)
    key(KEY_C,false)
    key(KEY_E,false)
    check(settings.read_controls(true).throttle==0.0 and settings.clutch_input()==0.0,"Releasing the real keys releases both pedals immediately")
    check(settings.bind("clutch",KEY_J).is_empty(),"Manual clutch remains remappable")
    key(KEY_J,true)
    check(settings.clutch_input()==1.0,"Physical fallback follows the current binding rather than hardcoding C")
    key(KEY_J,false)
    key(KEY_W,true)
    key(KEY_S,true)
    check(settings.read_controls(true).throttle==1.0 and settings.read_controls(true).brake==1.0,"W and S are independent accelerator/brake pedals for heel-toe in a manual drag car")
    check(settings.read_controls(false).throttle==0.0,"The previous automatic circuit retains its opposing forward/reverse axis")
    key(KEY_W,false)
    key(KEY_S,false)
    var echo := InputEventKey.new()
    echo.physical_keycode=KEY_E
    echo.pressed=true
    echo.echo=true
    check(not settings.key_event_pressed(echo,"shift_up"),"Key repeat does not manufacture additional lever strokes")
    DirAccess.remove_absolute(path)
    if not failed: print("PASS: %d manual input and assistance settings assertions" % checks)
    quit(1 if failed else 0)
