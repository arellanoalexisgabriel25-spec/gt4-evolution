extends SceneTree

var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func button(code: int, pressed: bool) -> void:
    var event := InputEventJoypadButton.new()
    event.device = 0
    event.button_index = code
    event.pressed = pressed
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func _initialize() -> void: call_deferred("run")

func run() -> void:
    var session = root.get_node("GameSession")
    session.reset()
    session.controls.restore_defaults()
    session.controls.controller.devices.clear()
    session.controls.controller.active_device = -1
    session.game.buy(11)
    for component in session.game.find_car(11).health: session.game.find_car(11).health[component] = 100.0
    check(session.start_drag(11,"duel","technical",""),"A real owned factory car enters the starting scene")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    var scene = current_scene
    for frame in range(20): await physics_frame
    var trigger := InputEventJoypadMotion.new()
    trigger.device = 0
    trigger.axis = JOY_AXIS_TRIGGER_RIGHT
    trigger.axis_value = 1.0
    Input.parse_input_event(trigger)
    Input.flush_buffered_events()
    button(JOY_BUTTON_LEFT_SHOULDER,true)
    Input.action_press("evo_brake")
    check(scene._controls().throttle>0.99 and scene._controls().clutch>0.99 and scene._controls().brake>0.99,"The fixture holds genuine input states before delivering a focus loss")
    var pose: Vector3 = scene.car.position
    var rival_pose: Vector3 = scene.opponent.position
    var rpm: float = scene.car.powertrain.rpm
    var rival_rpm: float = scene.opponent.powertrain.rpm
    var procedure_time: float = scene.procedure.elapsed
    root.focus_exited.emit()
    check(scene.paused and scene.message.contains("VENTANA INACTIVA"),"Window focus loss pauses and tells the driver how to continue")
    var released: Dictionary = scene._controls()
    check(released.throttle==0.0 and released.clutch==0.0 and released.brake==0.0,"Lost release events cannot leave cached clutch, brake or accelerator held")
    for frame in range(20): await physics_frame
    check(scene.car.position==pose and scene.opponent.position==rival_pose and scene.car.powertrain.rpm==rpm and scene.opponent.powertrain.rpm==rival_rpm and scene.procedure.elapsed==procedure_time,"Paused focus loss freezes the actual powertrain, preparation and both vehicle positions")
    root.focus_entered.emit()
    for frame in range(5): await physics_frame
    check(scene.paused,"Returning focus never resumes a vehicle or timer without a driver command")
    button(JOY_BUTTON_START,true)
    button(JOY_BUTTON_START,false)
    check(not scene.paused,"A new deliberate Start edge resumes after the cached old controls were cleared")
    for frame in range(10): await physics_frame
    check(scene.procedure.elapsed>procedure_time and scene._controls().throttle==0.0,"Resume advances the same preparation without replaying stale acceleration")
    scene._back_to_garage()
    await process_frame
    await process_frame
    await create_timer(0.12,true,false,true).timeout
    session.menu_music.set_menu_active(false)
    for frame in range(8): await physics_frame
    if not failed: print("PASS: %d window focus and released pedal assertions" % checks)
    quit(1 if failed else 0)
