extends CharacterBody3D

const Physics = preload("res://scripts/vehicle_physics.gd")
var physics = Physics.new()
var visual: Node3D
var color := Color("b93a40")
var driver_name := ""
var distance_m := 0.0
var contact_count := 0

func _ready() -> void:
    floor_snap_length = 0.3
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(1.8, 1.0, 3.9)
    collision.shape = shape
    add_child(collision)
    visual = Node3D.new()
    add_child(visual)
    _mesh(Vector3(1.8, 0.6, 3.9), Vector3(0, 0.05, 0), color)
    _mesh(Vector3(1.4, 0.5, 1.7), Vector3(0, 0.55, 0.25), Color("233647"))
    _mesh(Vector3(1.42, 0.08, 1.72), Vector3(0, 0.84, 0.25), color)
    for x in [-0.62, 0.62]:
        _mesh(Vector3(0.4, 0.16, 0.05), Vector3(x, 0.15, -1.96), Color("f9e7ad"))
        _mesh(Vector3(0.4, 0.16, 0.05), Vector3(x, 0.15, 1.96), Color("db2828"))
    for x in [-0.95, 0.95]:
        for z in [-1.2, 1.2]:
            var wheel := MeshInstance3D.new()
            var tire := CylinderMesh.new()
            tire.top_radius = 0.38
            tire.bottom_radius = 0.38
            tire.height = 0.22
            wheel.mesh = tire
            wheel.material_override = paint(Color("171b22"))
            wheel.position = Vector3(x, -0.22, z)
            wheel.rotation_degrees.z = 90
            visual.add_child(wheel)
    if not driver_name.is_empty():
        var label := Label3D.new()
        label.text = driver_name
        label.position.y = 2.2
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        label.font_size = 36
        label.outline_size = 8
        add_child(label)

static func paint(value: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = value
    material.roughness = 0.8
    return material

func _mesh(size: Vector3, location: Vector3, value: Color) -> void:
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.material_override = paint(value)
    mesh.position = location
    visual.add_child(mesh)

func drive(delta: float, controls: Dictionary, road: bool) -> void:
    var brake := clampf(float(controls.get("brake", 0.0)), 0.0, 1.0)
    physics.step(delta, float(controls.get("throttle", 0.0)), float(controls.get("steer", 0.0)), brake > 0.0, road, brake)
    rotation.y = physics.heading
    var previous := global_position
    velocity.x = physics.velocity.x
    velocity.z = physics.velocity.y
    velocity.y = -1.0 if is_on_floor() else velocity.y - 15.0 * delta
    move_and_slide()
    physics.velocity = Vector2(velocity.x, velocity.z)
    if is_on_wall():
        contact_count += 1
    var displacement := Vector2(global_position.x - previous.x, global_position.z - previous.z).length()
    if displacement < 10.0:
        distance_m += displacement
    visual.rotation.x = lerp_angle(visual.rotation.x, -physics.weight_transfer * 0.06, 1.0 - exp(-6.0 * delta))
    visual.rotation.z = lerp_angle(visual.rotation.z, -physics.steering * physics.signed_speed() * 0.002, 1.0 - exp(-6.0 * delta))

func recover(location: Vector3, angle: float = 0.0) -> void:
    position = location
    rotation = Vector3(0, angle, 0)
    velocity = Vector3.ZERO
    physics.reset(angle)

func snapshot(id: String) -> Dictionary:
    return {"id":id, "position":global_position, "speed":physics.velocity.length()}
