extends SceneTree

const Settings = preload("res://scripts/control_settings.gd")
var checks := 0
var failed := false
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed=true
        push_error(message)
func key(code: int, pressed: bool) -> void:
    var event := InputEventKey.new()
    event.physical_keycode=code
    event.pressed=pressed
    Input.parse_input_event(event)
    Input.flush_buffered_events()
func _initialize() -> void:
    var settings=Settings.new()
    settings.apply()
    check(settings.drag_keys.handbrake==KEY_H,"New settings default to a separate H handbrake")
    key(KEY_W,true)
    key(KEY_H,true)
    var controls: Dictionary=settings.read_controls(true)
    check(controls.throttle==1.0 and controls.handbrake==1.0 and controls.brake==0.0,"Keyboard handbrake and accelerator are independent from the service brake")
    check(settings.read_controls(false).handbrake==0.0,"The optional manual handbrake leaves older circuit controls unchanged")
    key(KEY_W,false)
    key(KEY_H,false)
    check(settings.bind("handbrake",KEY_J).is_empty(),"The handbrake can be rebound through the shared settings API")
    key(KEY_J,true)
    check(settings.read_controls(true).handbrake==1.0,"The newly rebound physical key applies the handbrake")
    key(KEY_J,false)
    var legacy: Dictionary=settings.to_dict()
    legacy.drag_keys.erase("handbrake")
    legacy.keys.accelerate=KEY_H
    var loaded=Settings.new()
    check(loaded.from_dict(legacy),"A real v1 file with only three manual actions migrates")
    check(loaded.keys.accelerate==KEY_H and loaded.drag_keys.clutch==KEY_C and loaded.drag_keys.shift_up==KEY_E and loaded.drag_keys.shift_down==KEY_Q,"Migration preserves every existing binding including an occupied H")
    check(loaded.drag_keys.handbrake!=KEY_H and not legacy.keys.values().has(loaded.drag_keys.handbrake) and not legacy.drag_keys.values().has(loaded.drag_keys.handbrake),"Migration allocates an unused handbrake key without stealing controls")
    var path:="user://handbrake-settings-%d.json" % Time.get_ticks_usec()
    check(loaded.save_file(path)==OK,"The migrated handbrake persists in a real settings file")
    var restored=Settings.new()
    check(restored.load_file(path) and restored.to_dict()==loaded.to_dict(),"All migrated controls survive file round-trip")
    DirAccess.remove_absolute(path)
    var before: Dictionary=restored.to_dict()
    var malformed: Dictionary=before.duplicate(true)
    malformed.drag_keys.erase("clutch")
    check(not restored.from_dict(malformed) and restored.to_dict()==before,"Missing required legacy actions are rejected atomically")
    malformed=before.duplicate(true)
    malformed.drag_keys.erase("handbrake")
    malformed.drag_keys["unknown"]=KEY_T
    check(not restored.from_dict(malformed) and restored.to_dict()==before,"Unknown manual actions cannot replace the optional handbrake")
    var pad:=InputEventJoypadButton.new()
    pad.device=0
    pad.button_index=JOY_BUTTON_LEFT_STICK
    pad.pressed=true
    restored.controller.feed(pad)
    check(restored.read_controls(true).handbrake==1.0 and restored.read_controls(true).brake==0.0,"Controller L3 applies only the rear handbrake input")
    pad.pressed=false
    restored.controller.feed(pad)
    check(restored.read_controls(true).handbrake==0.0,"Releasing L3 releases the handbrake")
    if not failed: print("PASS: %d handbrake settings assertions" % checks)
    quit(1 if failed else 0)
