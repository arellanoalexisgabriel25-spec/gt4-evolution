extends SceneTree

const Race = preload("res://scripts/race_session.gd")
const Layout = preload("res://scripts/circuit_layout.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    var race = Race.new()
    race.circuit = Layout.new()
    race.add_entry("player", "Player", race.circuit.points[0])
    race.add_entry("nico", "Nico", Vector3(-3, 0, 63))
    race.add_entry("claire", "Claire", Vector3(3, 0, 68))
    check(not race.can_drive("player") and race.report().is_empty(), "Countdown cannot generate driving or results")
    check(race.standings()[0]["id"] == "player", "Grid slots behind the start cannot appear a checkpoint ahead")
    race.tick(3.0)
    check(race.can_drive("player") and race.elapsed == 0.0, "Green flag starts race clock after countdown")
    var trial = race.entries["player"]["trial"]
    race.observe("player", Vector3(-8.5, 0, 58), 0.1)
    check(not trial.valid, "Leaving the asphalt invalidates a lap even without a teleport")
    trial.completed_laps = 1
    trial.passed_gates = 3
    race.recover("player", race.circuit.points[0])
    check(trial.completed_laps == 1 and trial.passed_gates == 0, "Recovery preserves completed lap but invalidates current progress")
    check(not race.can_drive("player") and race.entries["player"]["recoveries"] == 1, "Recovery imposes a timed hold")
    race.tick(2.0)
    check(not race.can_drive("player") and race.elapsed == 2.0, "Race clock runs during recovery penalty")
    race.tick(1.0)
    check(race.can_drive("player"), "Recovery hold expires")
    check(race.report().is_empty(), "Unfinished race cannot emit final report")
    race.time_limit = 3.5
    race.tick(1.0)
    check(race.phase == "finished", "Time limit terminates stalled race")
    check(race.report()["standings"].size() == 3 and race.entries["player"]["dnf"], "Time limit records DNFs rather than inventing finishes")
    var elapsed: float = race.elapsed
    race.tick(5.0)
    check(race.elapsed == elapsed, "Finalized clock cannot keep accruing time")
    if not failed:
        print("PASS: %d race session assertions" % checks)
    quit(1 if failed else 0)
