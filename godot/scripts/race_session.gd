extends RefCounted

const Trial = preload("res://scripts/time_trial.gd")
var circuit
var entries: Dictionary = {}
var phase := "countdown"
var countdown := 3.0
var elapsed := 0.0
var laps := 2
var time_limit := 600.0
var player_finish_time := -1.0

func add_entry(id: String, name: String, position: Vector3) -> void:
    var trial = Trial.new()
    trial.reset(position, circuit.gates, circuit.gate_directions)
    entries[id] = {"name":name, "trial":trial, "along":circuit.project(position)["along"], "finish_time":-1.0, "dnf":false, "hold":0.0, "recoveries":0}

func tick(delta: float) -> void:
    if phase == "countdown":
        countdown = maxf(0.0, countdown - delta)
        if countdown == 0.0:
            phase = "running"
        return
    if phase != "running":
        return
    elapsed += delta
    for id in entries:
        entries[id]["hold"] = maxf(0.0, float(entries[id]["hold"]) - delta)
    if elapsed >= time_limit or (player_finish_time >= 0.0 and elapsed - player_finish_time >= 30.0):
        for id in entries:
            if float(entries[id]["finish_time"]) < 0.0:
                entries[id]["dnf"] = true
        phase = "finished"

func is_finished(id: String) -> bool:
    return float(entries[id]["finish_time"]) >= 0.0 or bool(entries[id]["dnf"])

func can_drive(id: String) -> bool:
    return phase == "running" and not is_finished(id) and float(entries[id]["hold"]) == 0.0

func observe(id: String, position: Vector3, delta: float) -> void:
    if not can_drive(id):
        return
    var entry: Dictionary = entries[id]
    var trial = entry["trial"]
    entry["along"] = circuit.project(position)["along"]
    if not circuit.on_road(position):
        trial.valid = false
    trial.advance(position, delta)
    if trial.completed_laps >= laps:
        entry["finish_time"] = elapsed - delta * (1.0 - trial.last_crossing_fraction)
        if id == "player":
            player_finish_time = entry["finish_time"]

func finish_tick() -> void:
    if phase != "running":
        return
    for id in entries:
        if not is_finished(id):
            return
    phase = "finished"

func recover(id: String, position: Vector3) -> void:
    if phase != "running" or is_finished(id):
        return
    var entry: Dictionary = entries[id]
    entry["trial"].reset(position, circuit.gates, circuit.gate_directions)
    entry["along"] = 0.0
    entry["hold"] = 3.0
    entry["recoveries"] = int(entry["recoveries"]) + 1

func standings() -> Array[Dictionary]:
    var table: Array[Dictionary] = []
    for id in entries:
        var entry: Dictionary = entries[id]
        var trial = entry["trial"]
        # Ordered gates bound projected progress so cutting the infield cannot
        # place an entrant a whole lap ahead in the live display.
        var lower: float = float(trial.passed_gates) * circuit.length / 8.0 if trial.passed_gates > 0 else -20.0
        var upper: float = float(trial.passed_gates + 1) * circuit.length / 8.0
        var projected: float = entry["along"]
        if trial.passed_gates == 0 and projected > circuit.length * 0.75:
            projected -= circuit.length # Grid slots behind the start line.
        var along := clampf(projected, lower, upper)
        table.append({"id":id, "name":entry["name"], "laps":trial.completed_laps, "time":entry["finish_time"], "dnf":entry["dnf"], "progress":trial.completed_laps * circuit.length + along, "recoveries":entry["recoveries"], "hold":entry["hold"]})
    table.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        if (a["time"] >= 0.0) != (b["time"] >= 0.0):
            return a["time"] >= 0.0
        if a["time"] >= 0.0 and a["time"] != b["time"]:
            return a["time"] < b["time"]
        if a["dnf"] != b["dnf"]:
            return not a["dnf"]
        if a["progress"] != b["progress"]:
            return a["progress"] > b["progress"]
        return str(a["id"]) < str(b["id"])
    )
    for i in range(table.size()):
        table[i]["position"] = i + 1
    return table

func report() -> Dictionary:
    if phase != "finished":
        return {}
    return {"laps":laps, "elapsed":elapsed, "standings":standings()}
