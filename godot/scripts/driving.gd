extends Node3D

# Arcade driving and an original closed practice circuit; not GT4 physics.
# No copyrighted assets, vehicle models, or circuits are used.
const Physics = preload("res://scripts/vehicle_physics.gd")
const ChaseCamera = preload("res://scripts/chase_camera.gd")

const TimeTrial = preload("res://scripts/time_trial.gd")
const Handling = preload("res://scripts/handling.gd")
const TRACK := [Vector3(0, 0, 58), Vector3(0, 0, -60), Vector3(18, 0, -85), Vector3(65, 0, -85), Vector3(85, 0, -60), Vector3(85, 0, 60), Vector3(65, 0, 85), Vector3(18, 0, 85)]

var physics = Physics.new()
var camera
var visual: Node3D
var trial = TimeTrial.new()
var car: CharacterBody3D
var speed_mps: float = 0.0
var distance_m: float = 0.0
var readout: Label
var enabled: bool = false

func _paint(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.9
    return material

func _box(name: String, size: Vector3, pos: Vector3, color: Color, collidable: bool = false) -> Node3D:
    var node: Node3D
    if collidable:
        var body := StaticBody3D.new()
        node = body
        var collider := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collider.shape = shape
        body.add_child(collider)
    else:
        node = Node3D.new()
    node.name = name
    node.position = pos
    add_child(node)
    var mesh := MeshInstance3D.new()
    var cube := BoxMesh.new()
    cube.size = size
    mesh.mesh = cube
    mesh.material_override = _paint(color)
    node.add_child(mesh)
    return node

func _ready() -> void:
    var world := WorldEnvironment.new()
    world.environment = Environment.new()
    world.environment.background_mode = Environment.BG_COLOR
    world.environment.background_color = Color("#86abc9")
    world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    world.environment.ambient_light_color = Color("#f7fbff")
    world.environment.ambient_light_energy = 0.9
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55.0, -30.0, 0.0)
    sun.light_energy = 1.2
    add_child(sun)
    _box("Grass", Vector3(340.0, 1.0, 340.0), Vector3(40, -0.55, 0), Color("#537345"), true)
    _build_track()
    _build_car()
    _build_hud()
    enabled = GameSession.choose_vehicle(GameSession.selected_vehicle)
    if enabled:
        physics.config = Handling.configuration(GameSession.game.find_car(GameSession.selected_vehicle))
    trial.reset(car.position, TRACK)
    if not enabled:
        readout.text = "Elegí primero un vehículo en el garaje. Usá VOLVER."

func _build_track() -> void:
    for i in range(TRACK.size()):
        var start: Vector3 = TRACK[i]
        var end: Vector3 = TRACK[(i + 1) % TRACK.size()]
        var direction := (end - start).normalized()
        var center := (start + end) * 0.5
        var length := start.distance_to(end)
        var angle := atan2(-direction.x, -direction.z)
        var road := _box("Road %d" % i, Vector3(16, 0.08, length + 10), center, Color("#303942"))
        road.rotation.y = angle
        var side := Vector3(-direction.z, 0, direction.x)
        for edge in [-1, 1]:
            var barrier := _box("Barrier %d %d" % [i, edge], Vector3(0.4, 0.8, length), center + side * float(edge) * 10.5 + Vector3(0, 0.4, 0), Color("#e8e7e0"), true)
            barrier.rotation.y = angle
        for mark in range(int(length / 9.0)):
            var stripe := _box("Stripe", Vector3(0.18, 0.02, 3), start + direction * (float(mark) * 9.0 + 4.0) + Vector3(0, 0.06, 0), Color("#e6e3c2"))
            stripe.rotation.y = angle
        var gate := _box("Checkpoint %d" % i, Vector3(15, 0.025, 1.0), start + Vector3(0, 0.065, 0), Color("#f3c969") if i else Color.WHITE)
        gate.rotation.y = angle
        for edge in [-1, 1]:
            _box("Gate post", Vector3(0.3, 3, 0.3), start + side * float(edge) * 8 + Vector3(0, 1.5, 0), Color("#eeaa33"))

func _reset_car() -> void:
    car.position = TRACK[0] + Vector3(0, 0.75, 0)
    car.rotation = Vector3.ZERO
    car.velocity = Vector3.ZERO
    speed_mps = 0.0
    physics.reset()
    camera.snap()
    trial.reset(car.position, TRACK)

func _build_car() -> void:
    car = CharacterBody3D.new()
    car.name = "PracticeCar"
    car.position = Vector3(0, 0.75, 58)
    car.floor_snap_length = 0.15
    add_child(car)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(1.8, 1.0, 3.9)
    collision.shape = shape
    car.add_child(collision)
    visual = Node3D.new()
    car.add_child(visual)
    var body := MeshInstance3D.new()
    var body_mesh := BoxMesh.new()
    body_mesh.size = Vector3(1.8, 0.65, 3.9)
    body.mesh = body_mesh
    body.material_override = _paint(Color("#ba3737"))
    body.position = Vector3(0, 0.06, 0)
    visual.add_child(body)
    var roof := MeshInstance3D.new()
    var roof_mesh := BoxMesh.new()
    roof_mesh.size = Vector3(1.4, 0.48, 1.9)
    roof.mesh = roof_mesh
    roof.material_override = _paint(Color("#e2d5c5"))
    roof.position = Vector3(0, 0.57, 0.25)
    visual.add_child(roof)
    for x in [-0.95, 0.95]:
        for z in [-1.2, 1.2]:
            var wheel := MeshInstance3D.new()
            var tire := CylinderMesh.new()
            tire.top_radius = 0.38
            tire.bottom_radius = 0.38
            tire.height = 0.22
            wheel.mesh = tire
            wheel.material_override = _paint(Color("#171717"))
            wheel.position = Vector3(x, -0.22, z)
            wheel.rotation_degrees.z = 90
            visual.add_child(wheel)
    camera = ChaseCamera.new()
    add_child(camera)
    camera.target = car
    camera.current = true
    camera.snap()

func _build_hud() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)
    var info := PanelContainer.new()
    info.position = Vector2(22, 20)
    info.custom_minimum_size = Vector2(330, 0)
    canvas.add_child(info)
    var layout := VBoxContainer.new()
    info.add_child(layout)
    var heading := Label.new()
    heading.text = "GT4 EVOLUTION · CONTRARRELOJ"
    heading.add_theme_font_size_override("font_size", 20)
    layout.add_child(heading)
    readout = Label.new()
    layout.add_child(readout)
    var help := Label.new()
    help.text = "W / ↑ acelerar · S / ↓ frenar · A/D girar\nESPACIO freno · R reinicia · ESC garaje\nPasá por las puertas amarillas en orden."
    layout.add_child(help)
    var back := Button.new()
    back.text = "VOLVER AL GARAJE"
    back.pressed.connect(_back_to_garage)
    layout.add_child(back)

func _physics_process(delta: float) -> void:
    if not enabled:
        return
    var forward := Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up")
    var reverse := Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down")
    var steer := 0.0
    if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
        steer -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
        steer += 1.0
    var requested_throttle := (1.0 if forward else 0.0) - (1.0 if reverse else 0.0)
    physics.step(delta, requested_throttle, steer, Input.is_physical_key_pressed(KEY_SPACE), _on_road(car.global_position))
    car.rotation.y = physics.heading
    var previous := car.global_position
    car.velocity.x = physics.velocity.x
    car.velocity.z = physics.velocity.y
    car.velocity.y = -1.0 if car.is_on_floor() else car.velocity.y - 15.0 * delta
    car.move_and_slide()
    physics.velocity = Vector2(car.velocity.x, car.velocity.z)
    speed_mps = physics.signed_speed()
    visual.rotation.x = lerp_angle(visual.rotation.x, -physics.weight_transfer * 0.06, 1.0 - exp(-6.0 * delta))
    visual.rotation.z = lerp_angle(visual.rotation.z, -physics.steering * speed_mps * 0.002, 1.0 - exp(-6.0 * delta))
    var displacement := Vector2(car.global_position.x, car.global_position.z).distance_to(Vector2(previous.x, previous.z))
    if displacement < 10.0:
        distance_m += displacement
    trial.advance(car.global_position, delta)
    if car.global_position.y < -5.0:
        _reset_car()
    readout.text = "%.0f km/h · %.0f m · Marcha %s · %.0f RPM\nVuelta %d · Control %d/%d\nTiempo %.2f s · Mejor %s" % [physics.velocity.length() * 3.6, distance_m, "R" if physics.gear == -1 else str(physics.gear), physics.rpm, trial.completed_laps + 1, trial.passed_gates, TRACK.size(), trial.elapsed, "%.2f s" % trial.best_time if trial.best_time > 0.0 else "—"]

func _on_road(position: Vector3) -> bool:
    var point := Vector2(position.x, position.z)
    for i in range(TRACK.size()):
        var start: Vector3 = TRACK[i]
        var end: Vector3 = TRACK[(i + 1) % TRACK.size()]
        var closest := Geometry2D.get_closest_point_to_segment(point, Vector2(start.x, start.z), Vector2(end.x, end.z))
        if point.distance_to(closest) <= 8.0:
            return true
    return false

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R and enabled:
        _reset_car()
    if event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        _back_to_garage()

func _back_to_garage() -> void:
    if enabled:
        var km := floori(distance_m / 1000.0)
        if km > 0:
            GameSession.game.drive(GameSession.selected_vehicle, km, 1.0)
    GameSession.selected_vehicle = 0
    get_tree().change_scene_to_file("res://scenes/main.tscn")
