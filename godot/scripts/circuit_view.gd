extends Node3D

const Layout = preload("res://scripts/circuit_layout.gd")
const Vehicle = preload("res://scripts/vehicle_actor.gd")
var layout = Layout.new()

func _box(size: Vector3, location: Vector3, color: Color, angle: float = 0.0, solid: bool = false) -> void:
    var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
    node.position = location
    node.rotation.y = angle
    add_child(node)
    if solid:
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        node.add_child(collision)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.material_override = Vehicle.paint(color)
    node.add_child(mesh)

func _ready() -> void:
    var world := WorldEnvironment.new()
    world.environment = Environment.new()
    world.environment.background_mode = Environment.BG_COLOR
    world.environment.background_color = Color("86abc9")
    world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    world.environment.ambient_light_color = Color("f7fbff")
    world.environment.ambient_light_energy = 0.8
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -30, 0)
    sun.light_energy = 1.2
    add_child(sun)
    _box(Vector3(340, 1, 340), Vector3(40, -0.55, 0), Color("537345"), 0.0, true)
    for i in range(layout.points.size()):
        var start: Vector3 = layout.points[i]
        var end: Vector3 = layout.points[(i + 1) % layout.points.size()]
        var direction := (end - start).normalized()
        var side := Vector3(-direction.z, 0, direction.x)
        var center := (start + end) * 0.5
        var segment_length := start.distance_to(end)
        var angle := atan2(-direction.x, -direction.z)
        _box(Vector3(16, 0.08, segment_length + 0.3), center, Color("303942"), angle)
        for edge in [-1, 1]:
            _box(Vector3(1, 0.04, segment_length + 0.2), center + side * float(edge) * 7.5 + Vector3.UP * 0.07, Color("e8e7e0") if i % 2 == 0 else Color("bb4242"), angle)
            _box(Vector3(0.4, 0.9, segment_length + 0.15), center + side * float(edge) * Layout.BARRIER_OFFSET + Vector3.UP * 0.4, Color("dce4e6"), angle, true)
    for i in range(8):
        var location: Vector3 = layout.gates[i]
        var direction: Vector3 = layout.gate_directions[i]
        var angle := atan2(-direction.x, -direction.z)
        _box(Vector3(15, 0.025, 0.6), location + Vector3.UP * 0.07, Color("f3c969") if i > 0 else Color.WHITE, angle)
        for edge in [-1, 1]:
            _box(Vector3(0.3, 2.5, 0.3), location + Vector3(-direction.z, 0, direction.x) * edge * 8.5 + Vector3.UP * 1.2, Color("edaa33"))
        var label := Label3D.new()
        label.text = "META" if i == 0 else "CONTROL %d" % i
        label.position = location + Vector3.UP * 4
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        label.font_size = 48
        add_child(label)
