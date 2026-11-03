extends SceneTree

const Layout = preload("res://scripts/circuit_layout.gd")
const Driver = preload("res://scripts/rival_driver.gd")
const Physics = preload("res://scripts/vehicle_physics.gd")
const Rivals = preload("res://scripts/rivals.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    var circuit = Layout.new()
    var model = Physics.new()
    model.velocity = Vector2(0, -10)
    var location: Vector3 = circuit.sample(30.0)
    var clear = Driver.new()
    var request: Dictionary = clear.controls(0.1, location, model, circuit)
    check(request["throttle"] > 0.0 and not request["brake"], "Clear straight requests acceleration")
    var pass_driver = Driver.new()
    var lead := {"id":"lead","position":location + Vector3(0, 0, -12),"speed":6.0}
    pass_driver.controls(0.1, location, model, circuit, [lead])
    check(pass_driver.overtaking and pass_driver.lane > 0.0, "Slower lead car requests a passing lane")
    var blocked = Driver.new()
    var beside := {"id":"beside","position":location + Vector3(3.5, 0, -3),"speed":6.0}
    blocked.controls(0.1, location, model, circuit, [lead, beside])
    check(not blocked.overtaking and blocked.target_speed <= lead.speed, "Occupied adjacent lane prevents unsafe pass")
    var emergency = Driver.new()
    var controls: Dictionary = emergency.controls(0.1, location, model, circuit, [{"id":"stopped","position":location + Vector3(0, 0, -3),"speed":0.0}])
    check(controls["brake"] and controls["throttle"] == 0.0, "Stopped close traffic triggers braking")
    var nico = Driver.new()
    var claire = Driver.new()
    nico.profile = Rivals.new().driver_by_id("nico")
    claire.profile = Rivals.new().driver_by_id("claire")
    nico.controls(0.1, location, model, circuit)
    claire.controls(0.1, location, model, circuit)
    check(claire.target_speed > nico.target_speed, "Driver profiles produce different pace")
    var first = Driver.new()
    var repeat = Driver.new()
    var deterministic := true
    for i in range(100):
        if first.controls(1.0 / 60.0, location, model, circuit, [lead]) != repeat.controls(1.0 / 60.0, location, model, circuit, [lead]):
            deterministic = false
    check(deterministic, "Identical profiles, traffic and elapsed time produce identical controls")
    var corner = Driver.new()
    corner.controls(0.1, circuit.sample(120.0), model, circuit)
    check(corner.target_speed < clear.target_speed, "Curve anticipation reduces target speed")
    if not failed:
        print("PASS: %d rival driver assertions" % checks)
    quit(1 if failed else 0)
