extends Camera3D

var target: Node3D
var response := 6.0

func snap() -> void:
    if not is_instance_valid(target):
        return
    global_position = target.global_position + target.global_basis.z * 9.0 + Vector3.UP * 4.5
    look_at(target.global_position + Vector3.UP, Vector3.UP)

func _process(delta: float) -> void:
    if not is_instance_valid(target):
        return
    var desired := target.global_position + target.global_basis.z * 9.0 + Vector3.UP * 4.5
    global_position = global_position.lerp(desired, 1.0 - exp(-response * delta))
    look_at(target.global_position + Vector3.UP - target.global_basis.z * 3.0, Vector3.UP)
