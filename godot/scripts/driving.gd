extends Node3D

# Deliberately simple arcade test track; NOT Gran Turismo 4 physics.
# No copyrighted assets, vehicle models, or circuits are used.
const MAX_FORWARD_MPS := 38.0
const MAX_REVERSE_MPS := 12.0
const ACCELERATION := 15.0
const BRAKE_POWER := 25.0
const DRAG := 7.0

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
    _box("Grass", Vector3(200.0, 1.0, 200.0), Vector3(0, -0.55, 0), Color("#537345"), true)
    _box("Straight road", Vector3(14.0, 0.08, 176.0), Vector3(0, -0.005, 0), Color("#303942"))
    for i in range(19):
        _box("Lane stripe %d" % i, Vector3(0.18, 0.012, 3.0), Vector3(0, 0.05, -81.0 + i * 9.0), Color("#e6e3c2"))
    for i in range(16):
        var z := -80.0 + 10.0 * float(i)
        _box("Left boundary %d" % i, Vector3(0.28, 0.42, 4.0), Vector3(-7.25, 0.18, z), Color("#e8e7e0"))
        _box("Right boundary %d" % i, Vector3(0.28, 0.42, 4.0), Vector3(7.25, 0.18, z), Color("#e8e7e0"))
    _build_car()
    _build_hud()
    enabled = GameSession.selected_vehicle > 0 and not GameSession.game.find_car(GameSession.selected_vehicle).is_empty()
    if not enabled:
        readout.text = "Elegí primero un vehículo en el garaje. Usá VOLVER."

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
    var body := MeshInstance3D.new()
    var body_mesh := BoxMesh.new()
    body_mesh.size = Vector3(1.8, 0.65, 3.9)
    body.mesh = body_mesh
    body.material_override = _paint(Color("#ba3737"))
    body.position = Vector3(0, 0.06, 0)
    car.add_child(body)
    var roof := MeshInstance3D.new()
    var roof_mesh := BoxMesh.new()
    roof_mesh.size = Vector3(1.4, 0.48, 1.9)
    roof.mesh = roof_mesh
    roof.material_override = _paint(Color("#e2d5c5"))
    roof.position = Vector3(0, 0.57, 0.25)
    car.add_child(roof)
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
            car.add_child(wheel)
    var camera := Camera3D.new()
    camera.position = Vector3(0, 4.2, 10.0)
    camera.rotation_degrees.x = -18.0
    camera.current = true
    car.add_child(camera)

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
    heading.text = "GT4 EVOLUTION · PRUEBA 3D"
    heading.add_theme_font_size_override("font_size", 20)
    layout.add_child(heading)
    readout = Label.new()
    layout.add_child(readout)
    var help := Label.new()
    help.text = "W / ↑ acelerar · S / ↓ frenar · A/D girar\nESC para volver al garaje."
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
    if forward and not reverse:
        speed_mps = move_toward(speed_mps, MAX_FORWARD_MPS, ACCELERATION * delta)
    elif reverse and not forward:
        speed_mps = move_toward(speed_mps, -MAX_REVERSE_MPS, BRAKE_POWER * delta)
    else:
        speed_mps = move_toward(speed_mps, 0.0, DRAG * delta)
    if absf(speed_mps) > 0.5:
        car.rotate_y(-steer * delta * 1.4 * clampf(absf(speed_mps) / 15.0, 0.0, 1.0) * signf(speed_mps))
    var previous := car.global_position
    car.velocity = -car.global_transform.basis.z * speed_mps
    car.velocity.y -= 15.0 * delta
    car.move_and_slide()
    var displacement := Vector2(car.global_position.x, car.global_position.z).distance_to(Vector2(previous.x, previous.z))
    if displacement < 10.0:
        distance_m += displacement
    readout.text = "Velocidad: %.0f km/h · Recorrido: %.0f m" % [absf(speed_mps) * 3.6, distance_m]

func _unhandled_input(event: InputEvent) -> void:
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
