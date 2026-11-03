extends SceneTree

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

func pad(button: int, pressed: bool) -> void:
    var event := InputEventJoypadButton.new()
    event.button_index = button
    event.pressed = pressed
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var session = root.get_node("GameSession")
    session.controls.bind("accelerate", KEY_I)
    session.reset()
    check(session.controls.keys["accelerate"] == KEY_I, "New game preserves personal input preferences")
    session.game.buy(1)
    session.start_driving(1)
    change_scene_to_file("res://scenes/driving.tscn")
    await process_frame
    await process_frame
    var scene = current_scene
    var start: Vector3 = scene.car.position
    key(KEY_I, true)
    for i in range(60):
        await physics_frame
    key(KEY_I, false)
    check(scene.car.position.distance_to(start) > 2.0 and scene.speed_mps > 0.0, "Rebound key drives the actual garage vehicle")
    pad(JOY_BUTTON_B, true)
    await process_frame
    check(current_scene == scene and not scene.leaving, "Controller B cannot accidentally abandon the race through ui_cancel")
    pad(JOY_BUTTON_B, false)
    var buttons := scene.find_children("*", "Button", true, false)
    buttons[0].grab_focus()
    key(KEY_SPACE, true)
    await process_frame
    check(current_scene == scene and not scene.leaving, "Braking cannot activate a focused return-to-garage button")
    key(KEY_SPACE, false)
    pad(JOY_BUTTON_START, true)
    await process_frame
    check(scene.paused, "Controller Start pauses driving")
    var elapsed: float = scene.trial.elapsed
    for i in range(15):
        await physics_frame
    check(scene.trial.elapsed == elapsed, "Controller pause freezes lap clock")
    pad(JOY_BUTTON_START, false)
    pad(JOY_BUTTON_START, true)
    await process_frame
    check(not scene.paused, "Controller Start resumes driving")
    pad(JOY_BUTTON_START, false)
    pad(JOY_BUTTON_X, true)
    await process_frame
    check(scene.trial.passed_gates == 0 and scene.physics.velocity.length() < 0.1, "Controller X recovers the car with a fresh attempt")
    pad(JOY_BUTTON_X, false)
    key(KEY_ESCAPE, true)
    await process_frame
    await process_frame
    check(current_scene.name == "Main", "Escape remains a fixed return-to-garage action")
    key(KEY_ESCAPE, false)
    var menu = current_scene
    var path := "user://controls-ui-%d.json" % Time.get_ticks_usec()
    menu.controls_path = path
    menu._change_tab("ajustes")
    menu._request_binding("accelerate")
    key(KEY_K, true)
    key(KEY_K, false)
    check(session.controls.keys["accelerate"] == KEY_K and menu.pending_binding.is_empty(), "Settings UI captures a new key")
    check(FileAccess.file_exists(path), "Settings UI persists the new binding automatically")
    menu._request_binding("accelerate")
    key(KEY_ESCAPE, true)
    key(KEY_ESCAPE, false)
    check(menu.pending_binding.is_empty() and session.controls.keys["accelerate"] == KEY_K, "Escape cancels capture without changing the binding")
    menu._set_deadzone(0.3)
    check(session.controls.deadzone == 0.3 and menu.deadzone_label.text.contains("30%"), "Deadzone control updates saved preference and visible percentage")
    DirAccess.remove_absolute(path)
    if not failed:
        print("PASS: %d control integration assertions" % checks)
    quit(1 if failed else 0)
