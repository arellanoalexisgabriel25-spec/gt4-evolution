extends SceneTree

const Driver = preload("res://scripts/rival_driver.gd")
const Store = preload("res://scripts/save_store.gd")
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
    var starting_km: int = session.game.find_car(1)["km"]
    var tires: float = session.game.find_car(1)["health"]["neumaticos"]
    change_scene_to_file("res://scenes/main.tscn")
    await process_frame
    await process_frame
    current_scene._race("debut", 1)
    check(session.game.balance == balance - 120, "Career UI charges one admission before scene transition")
    await process_frame
    await process_frame
    scene = current_scene
    check(scene.career_event and scene.race != null, "Career UI opens physical debut race")
    pilot.profile = {"skill":80.0,"aggression":0.5,"consistency":0.95}
    scene.input_provider = _controls
    for i in range(12000):
        await physics_frame
        if scene.race.phase == "finished":
            break
    check(scene.race.phase == "finished" and scene.trial.completed_laps == 2, "Paid race completes real ordered laps")
    check(session.career.completed.has("debut"), "Physical finish records career achievement")
    if session.career.results.is_empty():
        quit(1)
        return
    var result: Dictionary = session.career.results[0]
    var position := 0
    for row in scene.race.standings():
        if row["id"] == "player":
            position = row["position"]
    var reward: int = session.career.event_by_id("debut")["rewards"][position - 1]
    check(result["source"] == "track" and result["position"] == position, "Career placement comes from physical finish order")
    check(session.game.balance == balance - 120 + reward, "Actual finish pays the correct unique reward")
    check(session.entry_ticket.is_empty() and not session.career.has_pending_track_entry(), "Settlement closes paid admission")
    var paid: int = session.game.balance
    session.finish_track_event(scene.race)
    check(session.game.balance == paid and session.career.results.size() == 1, "Repeated callback cannot pay twice")
    var meters: float = scene.distance_m
    var completed_race = scene.race
    scene._back_to_garage()
    await process_frame
    await process_frame
    check(current_scene.name == "Main", "Finished career race returns to garage")
    var car: Dictionary = session.game.find_car(1)
    check(car["km"] == starting_km + floori(meters / 1000.0), "Career uses measured metres rather than the old simulated 12 km")
    check(is_equal_approx(car["distance_remainder_m"], fmod(meters, 1000.0)), "Unrounded race distance is retained")
    check(car["health"]["neumaticos"] < tires, "Physical career race causes mechanical wear")
    check(session.career.rivalries["nico"]["encounters"] == 1 and session.career.rivalries["claire"]["encounters"] == 1, "Real race updates rivalry memory once")
    check(session.career.lap_records.get_best(1) > 0.0, "Valid physical lap creates personal best")
    var path := "user://track-career-%d.json" % Time.get_ticks_usec()
    check(Store.save_file(path, session.game, session.career) == OK, "Completed real result can be saved")
    var loaded: Dictionary = Store.load_file(path)
    check(loaded.error.is_empty() and loaded.career.results[0]["source"] == "track" and loaded.game.balance == paid, "JSON file restores real result and credits")
    check(loaded.career.lap_records.get_best(1) > 0.0, "Physical lap record persists in saved game")
    DirAccess.remove_absolute(path)
    current_scene._race("debut", 1)
    check(session.game.balance == paid and session.entry_ticket.is_empty(), "Completed career UI cannot recharge entry")
    current_scene._reset()
    session.game.buy(1)
    var before_abandon: int = session.game.balance
    current_scene._race("debut", 1)
    await process_frame
    await process_frame
    scene = current_scene
    var newly_paid: int = session.game.balance
    session.finish_track_event(completed_race)
    check(session.game.balance == newly_paid and not session.entry_ticket.is_empty(), "Stale result cannot settle a newly paid race")
    scene._back_to_garage()
    scene._back_to_garage()
    await process_frame
    await process_frame
    check(session.game.balance == before_abandon - 120, "Abandoning scene consumes admission exactly once")
    check(session.career.completed.is_empty() and session.entry_ticket.is_empty(), "Abandonment awards no progress and clears admission")
    if not failed:
        print("PASS: %d track career integration assertions" % checks)
    quit(1 if failed else 0)
