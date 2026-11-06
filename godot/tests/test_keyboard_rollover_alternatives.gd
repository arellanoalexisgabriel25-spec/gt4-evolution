extends SceneTree

# Injecting a key cannot validate electrical rollover on a physical keyboard.
# This verifies the independent alternate route, actual game dispatch and raw
# pedal diagnostics, so a driver can use keys outside the W/C/E letter matrix.
const Settings = preload("res://scripts/control_settings.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func key(code: int, pressed: bool, control: bool = false) -> InputEventKey:
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.pressed = pressed
    event.ctrl_pressed = control
    Input.parse_input_event(event)
    Input.flush_buffered_events()
    return event

func _initialize() -> void: call_deferred("run")

func run() -> void:
    var settings = Settings.new()
    settings.apply()
    check(settings.all_keys().size()==11,"Secondary hardware alternatives do not change existing action count or primary save schema")
    check(settings.binding_labels("clutch")=="C/Ctrl" and settings.binding_labels("shift_up")=="E/RePág" and settings.binding_labels("shift_down")=="Q/AvPág","All active physical alternatives have visible labels")
    key(KEY_W,true)
    key(KEY_CTRL,true,true)
    var lever := key(KEY_PAGEUP,true,true)
    var sample: Dictionary = settings.live_sample()
    check(sample.throttle==1.0 and sample.clutch==1.0 and sample.brake==0.0,"W+Ctrl+PageUp keeps independent full accelerator and clutch without pressing C or E")
    check(sample.keyboard.throttle==1.0 and sample.keyboard.clutch==1.0 and sample.controller.device==-1,"Raw diagnostics expose actual keyboard pedals and the absence of a controller")
    check(settings.key_event_pressed(lever,"shift_up"),"An alternate lever edge works while the physical clutch modifier is held")
    key(KEY_PAGEUP,false,true)
    key(KEY_CTRL,false)
    check(settings.live_sample().clutch==0.0 and settings.live_sample().throttle==1.0,"Releasing Ctrl disconnects only the clutch input and never lifts held W")
    key(KEY_W,false)
    check(settings.bind("accelerate",KEY_CTRL).is_empty(),"A player may choose Ctrl as a primary binding")
    key(KEY_CTRL,true,true)
    check(settings.live_sample().throttle==1.0 and settings.clutch_input()==0.0,"A primary Ctrl accelerator disables its clutch alias rather than operating two pedals")
    check(settings.binding_labels("clutch")=="C","The UI hides a secondary key consumed by another primary assignment")
    key(KEY_CTRL,false)
    check(settings.bind("clutch",KEY_PAGEUP).is_empty(),"PageUp can also become a primary remapped pedal")
    var primary := key(KEY_PAGEUP,true)
    check(settings.clutch_input()==1.0 and not settings.key_event_pressed(primary,"shift_up"),"A remapped clutch wins over the PageUp lever alias")
    key(KEY_PAGEUP,false)
    var saved: Dictionary = settings.to_dict()
    var restored = Settings.new()
    check(restored.from_dict(saved) and restored.to_dict()==saved and restored.secondary_keycodes("clutch").is_empty(),"Extended primary key choices round-trip without modifying legacy bindings or reactivating collisions")
    settings.restore_defaults()
    var axis := InputEventJoypadMotion.new()
    axis.device=0
    axis.axis=JOY_AXIS_TRIGGER_RIGHT
    axis.axis_value=0.8
    settings.controller.feed(axis)
    sample=settings.live_sample()
    check(sample.throttle>0.7 and sample.controller.throttle>0.7 and sample.keyboard.throttle==0.0,"Diagnostics distinguish genuine controller accelerator contribution from keyboard input")
    settings.controller.connection_changed(0,false)
    check(settings.live_sample().throttle==0.0,"Disconnecting a sampled controller releases the measured accelerator")
    var session = root.get_node("GameSession")
    session.reset()
    session.controls.restore_defaults()
    session.controls.controller.devices.clear()
    session.controls.controller.active_device=-1
    session.game.buy(11)
    for part in session.game.find_car(11).health: session.game.find_car(11).health[part]=100.0
    check(session.start_drag(11),"The owned vehicle enters the real drag scene for alternate key dispatch")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    var scene = current_scene
    key(KEY_W,true)
    key(KEY_CTRL,true,true)
    key(KEY_PAGEUP,true,true)
    key(KEY_PAGEUP,false,true)
    for i in range(30): await physics_frame
    check(scene.car.powertrain.gear==1 and scene.car.powertrain.missed_shifts==0,"Production W+Ctrl+PageUp selects first without a missed shift")
    check(scene._controls().throttle==1.0 and scene._controls().clutch==1.0,"The real scene retains accelerator and physical clutch simultaneously")
    key(KEY_E,true,true)
    key(KEY_E,false,true)
    for i in range(30): await physics_frame
    check(scene.car.powertrain.gear==2 and scene.car.powertrain.missed_shifts==0,"The original E lever also operates with the new Ctrl clutch and held W")
    key(KEY_PAGEDOWN,true,true)
    key(KEY_PAGEDOWN,false,true)
    for i in range(30): await physics_frame
    check(scene.car.powertrain.gear==1 and scene.car.powertrain.missed_shifts==0,"PageDown selects the lower gear through real production input")
    key(KEY_W,false,true)
    key(KEY_CTRL,false)
    scene._back_to_garage()
    await process_frame
    await process_frame
    session.menu_music.set_menu_active(false)
    for i in range(8): await process_frame
    if not failed: print("PASS: %d keyboard alternate input assertions" % checks)
    quit(1 if failed else 0)
