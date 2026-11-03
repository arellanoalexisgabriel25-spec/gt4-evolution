extends SceneTree

const Driver = preload("res://scripts/rival_driver.gd")
var scene
var pilot = Driver.new()
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _controls() -> Dictionary:
    var traffic: Array = []
    for entry in scene.opponents:
        if not scene.race.is_finished(entry["id"]):
            traffic.append(entry["actor"].snapshot(entry["id"]))
    return pilot.controls(1.0 / 60.0, scene.car.position, scene.physics, scene.circuit, traffic)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var session = root.get_node("GameSession")
    session.reset()
    session.game.buy(1)
    var balance: int = session.game.balance
    check(session.start_driving(1, "race"), "Exhibition starts with owned safe car")
    change_scene_to_file("res://scenes/driving.tscn")
    await process_frame
    await process_frame
    scene = current_scene
    pilot.profile = {"skill":80.0,"aggression":0.5,"consistency":0.95}
    scene.input_provider = _controls
    check(scene.opponents.size() == 2, "Two physical rivals spawn")
    var start: Vector3 = scene.car.position
    for i in range(100):
        await physics_frame
    check(Vector2(scene.car.position.x, scene.car.position.z).distance_to(Vector2(start.x, start.z)) < 0.1, "Countdown prevents throttle launch")
    scene.paused = true
    var before: float = scene.race.countdown
    for i in range(30):
        await physics_frame
    check(scene.race.countdown == before, "Pause freezes countdown for every entrant")
    scene.paused = false
    var passing_seen := false
    for i in range(12000):
        await physics_frame
        for entry in scene.opponents:
            passing_seen = passing_seen or entry["driver"].overtaking
        if scene.race.phase == "finished":
            break
    var report: Dictionary = scene.race.report()
    print("Race navigation evidence: ", scene.race.standings())
    check(not report.is_empty(), "Full physical race finishes")
    check(scene.trial.completed_laps >= 2, "Player completes two validated laps")
    for entry in scene.opponents:
        var id: String = entry["id"]
        check(scene.race.entries[id]["trial"].completed_laps >= 2, "Rival %s completes two valid laps" % id)
        check(int(scene.race.entries[id]["recoveries"]) == 0, "Rival %s finishes without teleport recovery" % id)
    check(session.game.balance == balance, "Exhibition cannot generate credits")
    check(scene.car.distance_m > scene.circuit.length * 1.9, "Measured distance supports completed laps")
    check(passing_seen, "Physical rivals attempt passing slower traffic")
    check(scene.race.entries["claire"]["finish_time"] < scene.race.entries["nico"]["finish_time"], "Faster rival overtakes the driver who started ahead")
    scene._back_to_garage()
    await process_frame
    await process_frame
    check(current_scene.name == "Main", "Race returns to garage")
    check(session.game.balance == balance, "Race exit preserves credits")
    if not failed:
        print("PASS: %d physical race assertions" % checks)
    quit(1 if failed else 0)
