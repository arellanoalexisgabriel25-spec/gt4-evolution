extends SceneTree

const Layout = preload("res://scripts/circuit_layout.gd")
const Physics = preload("res://scripts/vehicle_physics.gd")
const Driver = preload("res://scripts/rival_driver.gd")
const Trial = preload("res://scripts/time_trial.gd")

func _initialize() -> void:
    var circuit = Layout.new()
    var model = Physics.new()
    var driver = Driver.new()
    var trial = Trial.new()
    var position: Vector3 = circuit.points[0]
    trial.reset(position, circuit.gates, circuit.gate_directions)
    var max_offset := 0.0
    for i in range(12000):
        var controls: Dictionary = driver.controls(1.0 / 60.0, position, model, circuit)
        model.step(1.0 / 60.0, controls.throttle, controls.steer, controls.brake, circuit.on_road(position))
        position += Vector3(model.velocity.x, 0, model.velocity.y) / 60.0
        trial.advance(position, 1.0 / 60.0)
        max_offset = maxf(max_offset, float(circuit.project(position).distance))
        if trial.completed_laps >= 2:
            break
    if trial.completed_laps < 2 or max_offset > 7.5:
        push_error("Navigation failed: laps=%d position=%s offset=%.2f next=%d" % [trial.completed_laps, position, max_offset, trial.next_gate])
        quit(1)
        return
    print("PASS: 2 navigation assertions · two physical-model laps, max offset %.2f m" % max_offset)
    quit(0)
