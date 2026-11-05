extends SceneTree

const Manual = preload("res://scripts/manual_powertrain.gd")
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

func button(code: int, pressed: bool) -> void:
    var event := InputEventJoypadButton.new()
    event.device = 0
    event.button_index = code
    event.pressed = pressed
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func axis(code: int, value: float) -> void:
    var event := InputEventJoypadMotion.new()
    event.device = 0
    event.axis = code
    event.axis_value = value
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var model = Manual.new()
    model.step(0.1,1.0,0.0,0.0)
    check(model.request_shift(1,1.0) and model.gear==1 and model.throttle>0.4,"Full throttle does not inhibit a clutch-assisted first-gear change")
    for i in range(60): model.step(1.0/60.0,1.0,1.0,0.0)
    var held_rpm: float = model.rpm
    check(model.request_shift(1,1.0) and model.gear==2 and model.missed_shifts==0,"The driver can upshift without lifting the accelerator")
    for i in range(20): model.step(1.0/60.0,1.0,1.0,0.0)
    check(model.throttle>0.99 and model.rpm>model.config.idle_rpm*2.0 and model.rpm<=model.config.redline_rpm*1.1,"An open clutch at full throttle freely revs into the limiter; the change does not secretly cut throttle")
    check(held_rpm>model.config.idle_rpm*2.0 and model.speed_mps<0.01,"Clutch travel disconnects propulsion rather than inhibiting engine acceleration")
    check(model.request_shift(-1,1.0) and model.gear==1,"A clutch-assisted downshift also accepts held throttle")
    model.reset()
    check(model.request_shift(1,0.0) and model.gear==0,"A shift lever just before the clutch queues without inventing a gear")
    model.step(0.05,1.0,1.0,0.0)
    check(model.gear==1 and model.missed_shifts==0 and model.pending_shift_direction==0,"The short pedal window accepts a following clutch press exactly once")
    model.reset()
    var before_wear: float = model.wear.transmision
    model.request_shift(1,0.0)
    for i in range(12): model.step(1.0/60.0,1.0,0.0,0.0)
    check(model.gear==0 and model.missed_shifts==1 and model.wear.transmision>before_wear,"Never pressing the clutch still rejects and wears the transmission once after the input window")
    for i in range(30): model.step(1.0/60.0,1.0,1.0,0.0)
    check(model.gear==0 and model.missed_shifts==1,"A clutch pressed after expiration cannot execute a stale shift request")
    model.reset()
    model.request_shift(1,0.0)
    check(not model.request_shift(1,0.0),"Repeated held-button events cannot queue multiple changes")
    model.reset()
    model.step(0.1,1.0,1.0,0.0)
    check(model.gear==0 and model.pending_shift_direction==0,"Recovery discards a pending gear request")
    for value in [NAN,INF,-INF,-0.1,1.1]:
        check(not model.request_shift(1,value) and model.pending_shift_direction==0,"Malformed pedal input cannot queue a change")
    var before_rpm: float = model.rpm
    model.step(0.1,1.0,0.0,0.0,true,{},NAN)
    check(model.rpm==before_rpm,"A non-finite handbrake is rejected before mutating the powertrain")

    var session = root.get_node("GameSession")
    session.reset()
    session.controls.restore_defaults()
    session.controls.controller.devices.clear()
    session.controls.controller.active_device = -1
    session.game.buy(1)
    check(session.start_drag(1),"The real owned car enters manual practice for chord integration")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    var scene = current_scene
    scene.set_physics_process(false)
    key(KEY_W,true)
    key(KEY_C,true)
    key(KEY_E,true)
    key(KEY_E,false)
    check(scene.car.powertrain.gear==1 and scene._controls().throttle==1.0 and scene._controls().clutch==1.0,"Actual W+C+E input events select first with accelerator and clutch held together")
    scene.car.powertrain.reset()
    key(KEY_C,false)
    key(KEY_E,true)
    key(KEY_E,false)
    key(KEY_C,true)
    scene.car.powertrain.step(1.0/60.0,scene._controls().throttle,scene._controls().clutch,0.0)
    check(scene.car.powertrain.gear==1 and scene.car.powertrain.missed_shifts==0,"Actual W+E+C events in the same batch produce the same result despite event ordering")
    key(KEY_W,false)
    key(KEY_C,false)
    scene.car.powertrain.reset()
    axis(JOY_AXIS_TRIGGER_RIGHT,1.0)
    button(JOY_BUTTON_A,true)
    button(JOY_BUTTON_A,false)
    button(JOY_BUTTON_LEFT_SHOULDER,true)
    scene.car.powertrain.step(1.0/60.0,scene._controls().throttle,scene._controls().clutch,0.0)
    check(scene.car.powertrain.gear==1 and scene._controls().throttle==1.0 and scene.car.powertrain.missed_shifts==0,"Actual RT+A+LB events tolerate simultaneous controller gear/clutch ordering")
    button(JOY_BUTTON_LEFT_SHOULDER,false)
    axis(JOY_AXIS_TRIGGER_RIGHT,0.0)
    if not failed: print("PASS: %d simultaneous shift assertions" % checks)
    quit(1 if failed else 0)
