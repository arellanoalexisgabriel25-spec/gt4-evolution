extends Camera3D

# Smoothed chase camera. It trails the car's heading slightly so slides are
# visible, pulls back and widens the field of view with speed, and looks ahead.
var target: Node3D
var response := 6.0
var heading_response := 3.5
var base_distance := 8.5
var base_height := 4.2
var base_fov := 68.0
var max_fov := 82.0
var _heading := 0.0

func _speed() -> float:
    if not is_instance_valid(target):
        return 0.0
    var model = target.get("physics")
    if model == null:
        return 0.0
    return model.speed()

func _offset(speed: float) -> Vector3:
    var back := Vector3(sin(_heading), 0.0, cos(_heading))
    return back * (base_distance + clampf(speed, 0.0, 45.0) * 0.07) + Vector3.UP * (base_height + clampf(speed, 0.0, 45.0) * 0.015)

func snap() -> void:
    if not is_instance_valid(target):
        return
    _heading = target.global_rotation.y
    var speed := _speed()
    global_position = target.global_position + _offset(speed)
    fov = base_fov
    _aim(speed)

func _aim(speed: float) -> void:
    var back := Vector3(sin(_heading), 0.0, cos(_heading))
    look_at(target.global_position + Vector3.UP - back * (3.0 + speed * 0.1), Vector3.UP)

func _process(delta: float) -> void:
    if not is_instance_valid(target):
        return
    var speed := _speed()
    _heading = lerp_angle(_heading, target.global_rotation.y, 1.0 - exp(-heading_response * delta))
    var desired := target.global_position + _offset(speed)
    global_position = global_position.lerp(desired, 1.0 - exp(-response * delta))
    fov = lerpf(fov, base_fov + clampf(speed / 40.0, 0.0, 1.0) * (max_fov - base_fov), 1.0 - exp(-3.0 * delta))
    _aim(speed)
