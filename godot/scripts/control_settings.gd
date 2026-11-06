extends RefCounted

const DEFAULT_KEYS := {"accelerate":KEY_W, "reverse":KEY_S, "left":KEY_A, "right":KEY_D, "brake":KEY_SPACE, "recover":KEY_R, "pause":KEY_P}
const DRAG_KEYS := {"shift_up":KEY_E,"shift_down":KEY_Q,"clutch":KEY_C,"handbrake":KEY_H}
# Modifier keys are normally wired outside a low-cost keyboard's letter matrix.
# These second bindings give the driver another physical chord when W+C+E is
# blocked by the keyboard hardware. They do not operate the clutch automatically.
const DRAG_ALIASES := {"clutch":[KEY_CTRL],"shift_up":[KEY_PAGEUP],"shift_down":[KEY_PAGEDOWN]}
const ARROWS := {"accelerate":KEY_UP, "reverse":KEY_DOWN, "left":KEY_LEFT, "right":KEY_RIGHT}
const TITLES := {"accelerate":"Acelerar", "reverse":"Frenar / reversa", "left":"Girar a la izquierda", "right":"Girar a la derecha", "brake":"Freno", "recover":"Recuperar vehículo", "pause":"Pausar","shift_up":"Subir marcha (¼ milla)","shift_down":"Bajar marcha (¼ milla)","clutch":"Embrague (¼ milla)","handbrake":"Freno de mano (¼ milla)"}
const FILE_PATH := "user://controls_v1.json"
const Controller = preload("res://scripts/controller_state.gd")
const Playlist = preload("res://scripts/menu_playlist.gd")
const SHIFT_MODES := ["manual","auto_clutch","semi_auto"]
const VISUAL_QUALITIES := ["performance","balanced","high"]
var controller = Controller.new()
var keys: Dictionary = DEFAULT_KEYS.duplicate()
var drag_keys: Dictionary = DRAG_KEYS.duplicate()
var deadzone := 0.18
var camera_mode := 0
var keyboard_steering := 0.8
var trigger_deadzone := 0.04
var analog_clutch := false
var traction_control := false
var abs_assist := true
var music_volume := 0.35
var music_track_id := "perra"
var music_shuffle := false
var shift_mode := "manual"
var auto_rev_match := false
var visual_quality := "balanced"

static func action(name: String) -> String:
    return "evo_" + name

static func valid_key(code: int) -> bool:
    return (code >= KEY_A and code <= KEY_Z) or (code >= KEY_0 and code <= KEY_9) or code in [KEY_SPACE,KEY_CTRL,KEY_PAGEUP,KEY_PAGEDOWN]

func bind(name: String, code: int) -> String:
    if (not keys.has(name) and not drag_keys.has(name)) or not valid_key(code):
        return "Elegí una letra, un número, Espacio, Ctrl, RePág o AvPág. Esc cancela."
    var bindings := all_keys()
    for other in bindings:
        if other != name and int(bindings[other]) == code:
            return "Esa tecla ya se usa para %s." % str(TITLES[other]).to_lower()
    if keys.has(name):
        keys[name] = code
    else:
        drag_keys[name] = code
    apply()
    return ""

func restore_defaults() -> void:
    keys = DEFAULT_KEYS.duplicate()
    drag_keys = DRAG_KEYS.duplicate()
    deadzone = 0.18
    camera_mode = 0
    keyboard_steering = 0.8
    trigger_deadzone = 0.04
    analog_clutch = false
    traction_control = false
    abs_assist = true
    music_volume = 0.35
    music_track_id = "perra"
    music_shuffle = false
    shift_mode = "manual"
    auto_rev_match = false
    visual_quality = "balanced"
    apply()

func msaa_level() -> int:
    return {"performance":Viewport.MSAA_DISABLED,"balanced":Viewport.MSAA_2X,"high":Viewport.MSAA_4X}.get(visual_quality,Viewport.MSAA_2X)

func apply() -> void:
    var bindings := all_keys()
    for name in bindings:
        var mapped := action(name)
        if not InputMap.has_action(mapped):
            InputMap.add_action(mapped)
        Input.action_release(mapped) # Remapping a held key must not leave throttle stuck.
        InputMap.action_erase_events(mapped)
        var event := InputEventKey.new()
        event.physical_keycode = bindings[name]
        InputMap.action_add_event(mapped, event)
        if ARROWS.has(name):
            var arrow := InputEventKey.new()
            arrow.physical_keycode = ARROWS[name]
            InputMap.action_add_event(mapped, arrow)
        for code in secondary_keycodes(name):
            var alternate := InputEventKey.new()
            alternate.physical_keycode = code
            InputMap.action_add_event(mapped,alternate)

static func axis(value: float, zone: float) -> float:
    var safe_zone := clampf(zone, 0.0, 0.95)
    if absf(value) <= safe_zone:
        return 0.0
    return signf(value) * clampf((absf(value) - safe_zone) / (1.0 - safe_zone), 0.0, 1.0)

static func pad_sample(steer: float, accelerator: float, brake: float, reverse: bool, zone: float) -> Dictionary:
    return {"throttle":clampf(maxf(0.0, axis(accelerator, zone)) - (1.0 if reverse else 0.0), -1.0, 1.0), "steer":axis(steer, zone), "brake":maxf(0.0, axis(brake, zone))}

func read_controls(manual_mode: bool = false, automatic: bool = false) -> Dictionary:
    var throttle := key_strength("accelerate") - key_strength("reverse")
    var steer := (key_strength("right") - key_strength("left")) * keyboard_steering
    var brake := key_strength("brake")
    if manual_mode:
        # Drag direction is selected by the gearbox. S/Down is a separate brake
        # pedal, so a W+S throttle blip is possible while braking (heel-toe).
        throttle = key_strength("accelerate")
        brake = maxf(brake,key_strength("reverse"))
    var handbrake := key_strength("handbrake") if manual_mode else 0.0
    if controller.selected()>=0:
        throttle += maxf(0,axis(controller.axis_value(JOY_AXIS_TRIGGER_RIGHT),trigger_deadzone))-(1.0 if controller.pressed(JOY_BUTTON_B) and not manual_mode else 0.0)
        steer += axis(controller.axis_value(JOY_AXIS_LEFT_X),deadzone)+(1.0 if controller.pressed(JOY_BUTTON_DPAD_RIGHT) else 0.0)-(1.0 if controller.pressed(JOY_BUTTON_DPAD_LEFT) else 0.0)
        if not analog_clutch or not manual_mode or automatic:
            brake = maxf(brake,maxf(0,axis(controller.axis_value(JOY_AXIS_TRIGGER_LEFT),trigger_deadzone)))
        if manual_mode and controller.pressed(JOY_BUTTON_B):
            brake = 1.0
        if manual_mode and controller.pressed(JOY_BUTTON_LEFT_STICK):
            handbrake = 1.0
    return {"throttle":clampf(throttle, -1.0, 1.0), "steer":clampf(steer, -1.0, 1.0), "brake":brake,"handbrake":handbrake}

# Poll physical pedals as well as their InputMap actions. The lever event can
# arrive before an action state is updated or after a focused Control handled
# the event. This reads simultaneous keys without consuming or latching them.
# Window focus loss is still handled by Godot, unlike a custom held-key cache.
func key_strength(name: String) -> float:
    var value := Input.get_action_strength(action(name))
    var code: int = all_keys().get(name,0)
    if code>0 and Input.is_physical_key_pressed(code): value=1.0
    if ARROWS.has(name) and Input.is_physical_key_pressed(int(ARROWS[name])): value=1.0
    for alternate in secondary_keycodes(name):
        if Input.is_physical_key_pressed(alternate): value=1.0
    return value

func key_event_pressed(event: InputEvent, name: String) -> bool:
    if not event is InputEventKey or not event.pressed or event.echo: return false
    var code: int = event.physical_keycode if event.physical_keycode>0 else event.keycode
    return code==int(all_keys().get(name,0)) or secondary_keycodes(name).has(code)

func secondary_keycodes(name: String) -> Array[int]:
    var result: Array[int] = []
    var bindings := all_keys()
    for code in DRAG_ALIASES.get(name,[]):
        # A user's primary assignment always wins over a convenience alias.
        # This also prevents two actions when loading a customized old file.
        if not bindings.values().has(code): result.append(int(code))
    return result

func all_keys() -> Dictionary:
    var bindings := keys.duplicate()
    bindings.merge(drag_keys)
    return bindings

func key_label(name: String) -> String:
    var code: int = all_keys().get(name,0)
    return _key_title(code)

static func _key_title(code: int) -> String:
    return {KEY_SPACE:"Espacio",KEY_CTRL:"Ctrl",KEY_PAGEUP:"RePág",KEY_PAGEDOWN:"AvPág"}.get(code,OS.get_keycode_string(code))

func binding_labels(name: String) -> String:
    var labels: PackedStringArray = [key_label(name)]
    for code in secondary_keycodes(name): labels.append(_key_title(code))
    return "/".join(labels)

func clutch_input() -> float:
    var value := key_strength("clutch")
    if analog_clutch:
        value = maxf(value,maxf(0,axis(controller.axis_value(JOY_AXIS_TRIGGER_LEFT),trigger_deadzone)))
    if controller.pressed(JOY_BUTTON_LEFT_SHOULDER):
        value = 1.0
    return value

# Raw driver samples for a diagnostic HUD. This exposes no assisted pedal and
# never infers an unreported key: missing hardware events remain visible.
func live_sample(manual_mode: bool = true, automatic: bool = false) -> Dictionary:
    var sample := read_controls(manual_mode,automatic)
    sample["clutch"] = clutch_input()
    var keyboard_throttle := key_strength("accelerate")
    var keyboard_brake := key_strength("brake")
    if manual_mode:
        keyboard_brake = maxf(keyboard_brake,key_strength("reverse"))
    else:
        keyboard_throttle -= key_strength("reverse")
    sample["keyboard"] = {"throttle":keyboard_throttle,"clutch":key_strength("clutch"),"brake":keyboard_brake,"handbrake":key_strength("handbrake") if manual_mode else 0.0}
    var selected := controller.selected()
    var pad_throttle := maxf(0.0,axis(controller.axis_value(JOY_AXIS_TRIGGER_RIGHT),trigger_deadzone))
    var pad_clutch := maxf(0.0,axis(controller.axis_value(JOY_AXIS_TRIGGER_LEFT),trigger_deadzone)) if analog_clutch else 0.0
    if controller.pressed(JOY_BUTTON_LEFT_SHOULDER): pad_clutch=1.0
    var pad_brake := maxf(0.0,axis(controller.axis_value(JOY_AXIS_TRIGGER_LEFT),trigger_deadzone)) if not analog_clutch or not manual_mode or automatic else 0.0
    if manual_mode and controller.pressed(JOY_BUTTON_B): pad_brake=1.0
    sample["controller"] = {"device":selected,"throttle":pad_throttle,"clutch":pad_clutch,"brake":pad_brake,"handbrake":1.0 if manual_mode and controller.pressed(JOY_BUTTON_LEFT_STICK) else 0.0}
    return sample

func camera_look() -> Dictionary:
    var look := Vector2.ZERO
    var back := Input.is_physical_key_pressed(KEY_SHIFT)
    if controller.selected()>=0:
        look = Vector2(axis(controller.axis_value(JOY_AXIS_RIGHT_X),deadzone),axis(controller.axis_value(JOY_AXIS_RIGHT_Y),deadzone))
        back = back or controller.pressed(JOY_BUTTON_Y)
    return {"axis":look,"back":back}

func help_text() -> String:
    return "%s/↑ acelerar · %s/↓ reversa · %s/%s girar\n%s freno · %s recuperar · %s pausa · Esc garaje\nMando: RT/LT acelerar/frenar · B reversa\nStick/cruceta girar · X recuperar · Inicio pausa" % [key_label("accelerate"),key_label("reverse"),key_label("left"),key_label("right"),key_label("brake"),key_label("recover"),key_label("pause")]

func to_dict() -> Dictionary:
    return {"version":1, "keys":keys.duplicate(), "drag_keys":drag_keys.duplicate(),"deadzone":deadzone,"camera_mode":camera_mode,"keyboard_steering":keyboard_steering,"trigger_deadzone":trigger_deadzone,"analog_clutch":analog_clutch,"traction_control":traction_control,"abs_assist":abs_assist,"music_volume":music_volume,"music_track_id":music_track_id,"music_shuffle":music_shuffle,"shift_mode":shift_mode,"auto_rev_match":auto_rev_match,"visual_quality":visual_quality}

func from_dict(data: Dictionary) -> bool:
    var mode = data.get("shift_mode","manual")
    var matching = data.get("auto_rev_match",false)
    var quality = data.get("visual_quality","balanced")
    if typeof(quality)!=TYPE_STRING or not VISUAL_QUALITIES.has(quality):
        return false
    if typeof(mode)!=TYPE_STRING or not SHIFT_MODES.has(mode) or typeof(matching)!=TYPE_BOOL:
        return false
    var song = data.get("music_track_id","perra")
    var shuffled = data.get("music_shuffle",false)
    if typeof(song)!=TYPE_STRING or Playlist.index_of(song)<0 or typeof(shuffled)!=TYPE_BOOL:
        return false
    var triggers = data.get("trigger_deadzone",0.04)
    var music = data.get("music_volume",0.35)
    if typeof(triggers) not in [TYPE_FLOAT,TYPE_INT] or not is_finite(float(triggers)) or float(triggers)<0.0 or float(triggers)>0.2:
        return false
    if typeof(music) not in [TYPE_FLOAT,TYPE_INT] or not is_finite(float(music)) or float(music)<0.0 or float(music)>1.0:
        return false
    for flag in ["analog_clutch","traction_control","abs_assist"]:
        if data.has(flag) and typeof(data[flag])!=TYPE_BOOL:
            return false
    if data.get("version") != 1 or typeof(data.get("keys")) != TYPE_DICTIONARY or data["keys"].size() != DEFAULT_KEYS.size():
        return false
    var zone = data.get("deadzone")
    if typeof(zone) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(zone)) or float(zone) < 0.1 or float(zone) > 0.4:
        return false
    var candidate := {}
    var camera = data.get("camera_mode",0)
    var steering = data.get("keyboard_steering",0.8)
    if typeof(camera) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(camera)) or float(camera)!=floorf(float(camera)) or int(camera)<0 or int(camera)>3:
        return false
    if typeof(steering) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(steering)) or float(steering)<0.4 or float(steering)>1.0:
        return false
    var seen := {}
    for name in DEFAULT_KEYS:
        var code = data["keys"].get(name)
        if typeof(code) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(code)) or float(code) != floorf(float(code)) or not valid_key(int(code)) or seen.has(int(code)):
            return false
        candidate[name] = int(code)
        seen[int(code)] = true
    var drag := {}
    if data.has("drag_keys"):
        if typeof(data["drag_keys"]) != TYPE_DICTIONARY or data["drag_keys"].size() not in [3,DRAG_KEYS.size()]:
            return false
        for name in data["drag_keys"]:
            if not DRAG_KEYS.has(name):
                return false
        for name in DRAG_KEYS:
            if name=="handbrake" and not data["drag_keys"].has(name):
                continue
            var code = data["drag_keys"].get(name)
            if typeof(code) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(code)) or float(code)!=floorf(float(code)) or not valid_key(int(code)) or seen.has(int(code)):
                return false
            drag[name] = int(code)
            seen[int(code)] = true
    else:
        # Preserve existing custom bindings, even if E/Q/C were used before 0.13.
        for name in DRAG_KEYS:
            var choices := [DRAG_KEYS[name],KEY_F,KEY_G,KEY_H,KEY_J,KEY_K,KEY_L,KEY_Z,KEY_V,KEY_B,KEY_N,KEY_M]
            for code in choices:
                if not seen.has(code):
                    drag[name] = code
                    seen[code] = true
                    break
    if not drag.has("handbrake"):
        # Existing v1 files contain three manual actions. Add only the optional
        # handbrake, retaining every old key even when H was already assigned.
        for code in [KEY_H,KEY_F,KEY_G,KEY_J,KEY_K,KEY_L,KEY_Z,KEY_V,KEY_B,KEY_N,KEY_M]:
            if not seen.has(code):
                drag["handbrake"] = code
                break
    keys = candidate
    drag_keys = drag
    deadzone = float(zone)
    camera_mode = int(camera)
    keyboard_steering = float(steering)
    trigger_deadzone = float(triggers)
    music_volume = float(music)
    music_track_id = song
    music_shuffle = shuffled
    shift_mode = mode
    auto_rev_match = matching
    visual_quality = quality
    analog_clutch = data.get("analog_clutch",false)
    traction_control = data.get("traction_control",false)
    abs_assist = data.get("abs_assist",true)
    return true

func save_file(path: String = FILE_PATH) -> Error:
    var candidate = get_script().new()
    if not candidate.from_dict(to_dict()):
        return ERR_INVALID_DATA
    var temporary := path + ".tmp"
    var file := FileAccess.open(temporary, FileAccess.WRITE)
    if file == null:
        return FileAccess.get_open_error()
    file.store_string(JSON.stringify(to_dict(), "", true, true))
    file.flush()
    var error := file.get_error()
    file.close()
    if error == OK:
        error = DirAccess.rename_absolute(temporary, path)
    if error != OK:
        DirAccess.remove_absolute(temporary)
    return error

func load_file(path: String = FILE_PATH) -> bool:
    if not FileAccess.file_exists(path):
        apply()
        return true
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return false
    var parser := JSON.new()
    var error := parser.parse(file.get_as_text())
    file.close()
    if error != OK or typeof(parser.data) != TYPE_DICTIONARY or not from_dict(parser.data):
        return false
    apply()
    return true
