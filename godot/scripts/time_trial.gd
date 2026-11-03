extends RefCounted

# Ordered checkpoint gates prevent finishing by crossing the start line repeatedly.
# Resets invalidate the current lap, while retaining completed laps and the best time.
var points: Array = []
var previous := Vector3.ZERO
var next_gate := 1
var passed_gates := 0
var completed_laps := 0
var elapsed := 0.0
var best_time := 0.0
var last_time := 0.0
var gate_directions: Array = []
var valid := true
var last_crossing_fraction := 1.0

func reset(position: Vector3, track: Array, directions: Array = []) -> void:
    points = track.duplicate()
    previous = position
    next_gate = 1
    passed_gates = 0
    elapsed = 0.0
    gate_directions = directions.duplicate()
    valid = true

func advance(position: Vector3, delta: float) -> bool:
    elapsed += maxf(delta, 0.0)
    var old := Vector2(previous.x, previous.z)
    var current := Vector2(position.x, position.z)
    previous = position
    if points.size() < 3 or old.distance_to(current) > 10.0:
        # Teleports must not count toward a timed lap.
        next_gate = 1
        passed_gates = 0
        elapsed = 0.0
        valid = false
        return false
    var target: Vector3 = points[next_gate]
    var before: Vector3 = points[(next_gate - 1 + points.size()) % points.size()]
    var center := Vector2(target.x, target.z)
    var direction := (center - Vector2(before.x, before.z)).normalized()
    if gate_directions.size() == points.size():
        var gate: Vector3 = gate_directions[next_gate]
        direction = Vector2(gate.x, gate.z).normalized()
    var old_side := (old - center).dot(direction)
    var new_side := (current - center).dot(direction)
    if old_side >= 0.0 or new_side < 0.0:
        return false
    last_crossing_fraction = -old_side / (new_side - old_side)
    var crossing := old.lerp(current, last_crossing_fraction)
    if crossing.distance_to(center) > 8.0:
        return false
    passed_gates += 1
    if next_gate == 0:
        var completed := valid
        if valid:
            last_time = elapsed - delta * (1.0 - last_crossing_fraction)
            if best_time == 0.0 or last_time < best_time:
                best_time = last_time
            completed_laps += 1
        valid = true
        elapsed = delta * (1.0 - last_crossing_fraction)
        passed_gates = 0
        next_gate = 1
        return completed
    next_gate = (next_gate + 1) % points.size()
    return false
