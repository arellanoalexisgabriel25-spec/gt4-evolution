extends SceneTree

const Trial = preload("res://scripts/time_trial.gd")
var checks := 0
var failed := false
var track := [Vector3(0, 0, 0), Vector3(0, 0, -20), Vector3(20, 0, -20), Vector3(20, 0, 0)]

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func walk(trial, end: Vector3) -> void:
    var start: Vector3 = trial.previous
    var steps := ceili(start.distance_to(end) / 2.0)
    for i in range(1, steps + 1):
        trial.advance(start.lerp(end, float(i) / steps), 0.1)

func _initialize() -> void:
    var trial = Trial.new()
    trial.reset(Vector3.ZERO, track)
    walk(trial, Vector3(0, 0, 4))
    walk(trial, Vector3.ZERO)
    check(trial.completed_laps == 0, "Start line alone cannot finish a lap")
    for target in [Vector3(0, 0, -22), Vector3(22, 0, -20), Vector3(20, 0, 2), Vector3(-2, 0, 0)]:
        walk(trial, target)
    check(trial.completed_laps == 1, "All ordered gates complete a lap")
    check(trial.best_time > 0.0 and trial.last_time == trial.best_time, "Completed lap records time")
    check(trial.passed_gates == 0 and trial.next_gate == 1, "Next lap starts at first gate")
    var record: float = trial.best_time
    trial.reset(Vector3.ZERO, track)
    check(trial.best_time == record and trial.completed_laps == 1, "Recovery preserves finished results")
    check(trial.elapsed == 0.0 and trial.next_gate == 1, "Recovery invalidates current lap")
    trial.advance(Vector3(0, 0, -24), 0.1)
    check(trial.next_gate == 1 and trial.passed_gates == 0, "Teleport cannot collect checkpoint")
    trial.reset(Vector3(0, 0, -24), track)
    walk(trial, Vector3(0, 0, -16))
    check(trial.next_gate == 1, "Reverse crossing cannot collect checkpoint")
    trial.reset(Vector3(12, 0, -16), track)
    walk(trial, Vector3(12, 0, -24))
    check(trial.next_gate == 1, "Passing outside gate width cannot collect checkpoint")
    var teleported = Trial.new()
    teleported.reset(Vector3.ZERO, track)
    teleported.advance(Vector3(0, 0, -24), 0.1)
    walk(teleported, Vector3(0, 0, -16))
    for target in [Vector3(0, 0, -22), Vector3(22, 0, -20), Vector3(20, 0, 2), Vector3(-2, 0, 0)]:
        walk(teleported, target)
    check(teleported.completed_laps == 0 and teleported.best_time == 0.0, "Teleport invalidates the entire lap, not just the next checkpoint")
    check(teleported.valid, "Crossing the finish starts a new valid attempt")
    for target in [Vector3(0, 0, -22), Vector3(22, 0, -20), Vector3(20, 0, 2), Vector3(-2, 0, 0)]:
        walk(teleported, target)
    check(teleported.completed_laps == 1, "A complete subsequent lap can count again")
    if not failed:
        print("PASS: %d time trial assertions" % checks)
    quit(1 if failed else 0)
