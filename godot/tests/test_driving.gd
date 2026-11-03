extends SceneTree

var checks := 0
var failed := false

func _initialize() -> void:
    call_deferred("_run_test")

func _run_test() -> void:
    var session = root.get_node_or_null("GameSession")
    if session == null:
        push_error("Autoload GameSession missing")
        quit(1)
        return
    session.reset()
    var game = session.game
    _check(game.buy(1).begins_with("Compraste"), "buy starter vehicle")
    var previous_balance: int = game.balance
    _check(session.choose_vehicle(1), "select owned roadworthy car")
    var open_error: Error = change_scene_to_file("res://scenes/driving.tscn")
    _check(open_error == OK, "driving scene change requested")
    await process_frame
    await process_frame
    var scene = current_scene
    if scene == null:
        push_error("Driving scene did not load")
        quit(1)
        return
    _check(scene.name == "Driving", "driving scene active")
    var start: Vector3 = scene.car.global_position
    Input.action_press("ui_up")
    for i in range(90):
        await physics_frame
    Input.action_release("ui_up")
    _check(scene.speed_mps > 0.0, "acceleration changes speed")
    _check(scene.car.global_position.distance_to(start) > 1.0, "car moves under throttle")
    _check(scene.distance_m > 1.0, "odometer measures distance")
    _check(scene.camera.target == scene.car and scene.camera.get_parent() == scene, "chase camera follows independently of car rotation")
    _check(scene.camera.global_position.distance_to(scene.car.global_position) < 20.0, "chase camera stays near moving car")
    _check(scene._on_road(Vector3(0, 0, 0)), "straight belongs to circuit")
    _check(not scene._on_road(Vector3(42, 0, 0)), "infield is off road")
    _check(scene.trial.elapsed > 0.0, "time trial clock advances during driving")
    var driven: float = scene.distance_m
    scene._reset_car()
    _check(scene.speed_mps == 0.0, "recovery stops car")
    _check(scene.trial.elapsed == 0.0 and scene.trial.next_gate == 1, "recovery restarts timed lap")
    _check(scene.distance_m == driven, "recovery preserves actual driven distance")
    scene._back_to_garage()
    await process_frame
    await process_frame
    _check(current_scene != null and current_scene.name == "Main", "return to garage")
    _check(session.game.balance == previous_balance, "session credits preserved")
    _check(session.game.find_car(1)["owner"] == "player", "ownership preserved")
    _check(session.selected_vehicle == 0, "selection cleared")
    if failed:
        quit(1)
    else:
        print("PASS: %d driving integration assertions" % checks)
        quit(0)

func _check(ok: bool, message: String) -> void:
    if not ok:
        failed = true
        push_error("FAIL: " + message)
    else:
        checks += 1
