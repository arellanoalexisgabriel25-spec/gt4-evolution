extends SceneTree

var failed := false
var checks := 0

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var session = root.get_node("GameSession")
    session.reset()
    session.game.buy(1)
    session.start_driving(1)
    change_scene_to_file("res://scenes/driving.tscn")
    await process_frame
    await process_frame
    var scene = current_scene
    scene.car.recover(Vector3(6.5, 0.75, 0), -PI * 0.5)
    scene.input_provider = func() -> Dictionary: return {"throttle":1.0,"steer":0.0,"brake":false}
    for i in range(120):
        await physics_frame
    check(scene.car.contact_count > 0, "Real character body collides with circuit barrier")
    check(scene.car.position.x < 8.5, "Barrier prevents driving through the edge")
    check(not scene.trial.valid, "Teleporting into collision test invalidates lap")
    var distance: float = scene.distance_m
    scene._reset_car()
    check(scene.car.position.distance_to(Vector3(0, 0.75, 58)) < 0.01, "Recovery restores starting position")
    check(scene.trial.valid and scene.trial.passed_gates == 0, "Recovery requires a fresh ordered lap")
    check(scene.distance_m == distance, "Recovery never counts teleport as mileage")
    scene._back_to_garage()
    await process_frame
    await process_frame
    if not failed:
        print("PASS: %d circuit collision assertions" % checks)
    quit(1 if failed else 0)
