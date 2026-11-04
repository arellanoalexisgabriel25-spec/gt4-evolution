extends RefCounted

# Consume the same normalized Godot/SDL events delivered by real controllers.
# Event state also lets automated scenarios exercise complete input paths without
# claiming that a simulated device is physical hardware.
var devices: Dictionary = {}
var active_device := -1

func feed(event: InputEvent) -> bool:
    if not (event is InputEventJoypadButton or event is InputEventJoypadMotion) or event.device<0:
        return false
    if event is InputEventJoypadMotion and not is_finite(event.axis_value):
        return false
    var id := event.device
    if not devices.has(id):
        devices[id] = {"buttons":{},"axes":{}}
    if active_device<0 or (event is InputEventJoypadButton and event.pressed) or (event is InputEventJoypadMotion and absf(event.axis_value)>0.25):
        active_device = id
    if event is InputEventJoypadMotion:
        devices[id]["axes"][event.axis] = clampf(event.axis_value,-1,1)
        return false
    var previous: bool = devices[id]["buttons"].get(event.button_index,false)
    devices[id]["buttons"][event.button_index] = event.pressed
    return event.pressed and not previous

func connection_changed(device: int, connected: bool) -> void:
    if connected:
        if not devices.has(device):
            devices[device] = {"buttons":{},"axes":{}}
    else:
        devices.erase(device)
        if active_device==device:
            active_device = -1

func selected() -> int:
    if active_device>=0 and devices.has(active_device):
        return active_device
    var connected := Input.get_connected_joypads()
    return connected[0] if not connected.is_empty() else -1

func axis_value(axis: int) -> float:
    var device := selected()
    if device<0:
        return 0.0
    if devices.has(device) and devices[device]["axes"].has(axis):
        return float(devices[device]["axes"][axis])
    return Input.get_joy_axis(device,axis) if Input.get_connected_joypads().has(device) else 0.0

func pressed(button: int) -> bool:
    var device := selected()
    if device<0:
        return false
    if devices.has(device) and devices[device]["buttons"].has(button):
        return bool(devices[device]["buttons"][button])
    return Input.is_joy_button_pressed(device,button) if Input.get_connected_joypads().has(device) else false

func description() -> String:
    var device := selected()
    if device<0:
        return "Sin mando conectado · teclado disponible"
    var name := Input.get_joy_name(device) if Input.get_connected_joypads().has(device) else ""
    return "Mando: " + (name if not name.is_empty() else "dispositivo %d" % (device+1))
