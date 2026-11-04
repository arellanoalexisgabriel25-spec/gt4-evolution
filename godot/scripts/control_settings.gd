extends RefCounted

const DEFAULT_KEYS := {"accelerate":KEY_W, "reverse":KEY_S, "left":KEY_A, "right":KEY_D, "brake":KEY_SPACE, "recover":KEY_R, "pause":KEY_P}
const ARROWS := {"accelerate":KEY_UP, "reverse":KEY_DOWN, "left":KEY_LEFT, "right":KEY_RIGHT}
const TITLES := {"accelerate":"Acelerar", "reverse":"Frenar / reversa", "left":"Girar a la izquierda", "right":"Girar a la derecha", "brake":"Freno", "recover":"Recuperar vehículo", "pause":"Pausar"}
const FILE_PATH := "user://controls_v1.json"
var keys: Dictionary = DEFAULT_KEYS.duplicate()
var deadzone := 0.18
var camera_mode := 0
var keyboard_steering := 0.8

static func action(name: String) -> String:
    return "evo_" + name

static func valid_key(code: int) -> bool:
    return (code >= KEY_A and code <= KEY_Z) or (code >= KEY_0 and code <= KEY_9) or code == KEY_SPACE

func bind(name: String, code: int) -> String:
    if not keys.has(name) or not valid_key(code):
        return "Elegí una letra, un número o Espacio. Esc cancela."
    for other in keys:
        if other != name and int(keys[other]) == code:
            return "Esa tecla ya se usa para %s." % str(TITLES[other]).to_lower()
    keys[name] = code
    apply()
    return ""

func restore_defaults() -> void:
    keys = DEFAULT_KEYS.duplicate()
    deadzone = 0.18
    camera_mode = 0
    keyboard_steering = 0.8
    apply()

func apply() -> void:
    for name in keys:
        var mapped := action(name)
        if not InputMap.has_action(mapped):
            InputMap.add_action(mapped)
        Input.action_release(mapped) # Remapping a held key must not leave throttle stuck.
        InputMap.action_erase_events(mapped)
        var event := InputEventKey.new()
        event.physical_keycode = keys[name]
        InputMap.action_add_event(mapped, event)
        if ARROWS.has(name):
            var arrow := InputEventKey.new()
            arrow.physical_keycode = ARROWS[name]
            InputMap.action_add_event(mapped, arrow)

static func axis(value: float, zone: float) -> float:
    var safe_zone := clampf(zone, 0.0, 0.95)
    if absf(value) <= safe_zone:
        return 0.0
    return signf(value) * clampf((absf(value) - safe_zone) / (1.0 - safe_zone), 0.0, 1.0)

static func pad_sample(steer: float, accelerator: float, brake: float, reverse: bool, zone: float) -> Dictionary:
    return {"throttle":clampf(maxf(0.0, axis(accelerator, zone)) - (1.0 if reverse else 0.0), -1.0, 1.0), "steer":axis(steer, zone), "brake":maxf(0.0, axis(brake, zone))}

func read_controls() -> Dictionary:
    var throttle := Input.get_action_strength(action("accelerate")) - Input.get_action_strength(action("reverse"))
    var steer := (Input.get_action_strength(action("right")) - Input.get_action_strength(action("left"))) * keyboard_steering
    var brake := Input.get_action_strength(action("brake"))
    var pads := Input.get_connected_joypads()
    if not pads.is_empty():
        var device := pads[0]
        var sample := pad_sample(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT), Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT), Input.is_joy_button_pressed(device, JOY_BUTTON_B), deadzone)
        throttle += float(sample["throttle"])
        steer += float(sample["steer"]) + (1.0 if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT) else 0.0) - (1.0 if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT) else 0.0)
        brake = maxf(brake, float(sample["brake"]))
    return {"throttle":clampf(throttle, -1.0, 1.0), "steer":clampf(steer, -1.0, 1.0), "brake":brake}

func key_label(name: String) -> String:
    return "Espacio" if keys[name] == KEY_SPACE else OS.get_keycode_string(keys[name])

func camera_look() -> Dictionary:
    var look := Vector2.ZERO
    var back := Input.is_physical_key_pressed(KEY_SHIFT)
    var pads := Input.get_connected_joypads()
    if not pads.is_empty():
        look = Vector2(axis(Input.get_joy_axis(pads[0],JOY_AXIS_RIGHT_X),deadzone),axis(Input.get_joy_axis(pads[0],JOY_AXIS_RIGHT_Y),deadzone))
        back = back or Input.is_joy_button_pressed(pads[0],JOY_BUTTON_Y)
    return {"axis":look,"back":back}

func help_text() -> String:
    return "%s/↑ acelerar · %s/↓ reversa · %s/%s girar\n%s freno · %s recuperar · %s pausa · Esc garaje\nMando: RT/LT acelerar/frenar · B reversa\nStick/cruceta girar · X recuperar · Inicio pausa" % [key_label("accelerate"),key_label("reverse"),key_label("left"),key_label("right"),key_label("brake"),key_label("recover"),key_label("pause")]

func to_dict() -> Dictionary:
    return {"version":1, "keys":keys.duplicate(), "deadzone":deadzone,"camera_mode":camera_mode,"keyboard_steering":keyboard_steering}

func from_dict(data: Dictionary) -> bool:
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
    keys = candidate
    deadzone = float(zone)
    camera_mode = int(camera)
    keyboard_steering = float(steering)
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
