extends CharacterBody3D

const Visual = preload("res://scripts/car_visual.gd")
const Physics = preload("res://scripts/vehicle_physics.gd")
const Catalog = preload("res://scripts/car_catalog.gd")
var physics = Physics.new()
var visual
var color := Color("b93a40")
var driver_name := ""
var model_name := ""
var distance_m := 0.0
var contact_count := 0

func _ready() -> void:
    floor_snap_length = 0.3
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(1.8, 1.0, 3.9)
    var profile: Dictionary = Catalog.definition(model_name)
    if not profile.is_empty():
        var dimensions: Vector3 = profile["size"]
        shape.size = Vector3(dimensions.x,1.0,dimensions.z)
    collision.shape = shape
    add_child(collision)
    visual = Visual.new()
    visual.paint_color = color
    visual.model_name = model_name
    add_child(visual)
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

func drive(delta: float, controls: Dictionary, road: bool) -> void:
    var brake := clampf(float(controls.get("brake", 0.0)), 0.0, 1.0)
    var throttle := clampf(float(controls.get("throttle",0.0)),-1.0,1.0)
    var slowing := brake > 0.05 or throttle*physics.signed_speed() < -0.5
    physics.step(delta, throttle, float(controls.get("steer", 0.0)), brake > 0.0, road, brake)
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
    visual.update_motion(delta, physics.signed_speed(), physics.steering, physics.weight_transfer, 1.0 if slowing else 0.0)

func recover(location: Vector3, angle: float = 0.0) -> void:
    position = location
    rotation = Vector3(0, angle, 0)
    velocity = Vector3.ZERO
    physics.reset(angle)

func snapshot(id: String) -> Dictionary:
    return {"id":id, "position":global_position, "speed":physics.velocity.length()}
