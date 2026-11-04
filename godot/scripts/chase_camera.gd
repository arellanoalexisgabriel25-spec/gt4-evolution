extends Camera3D

const MODES := ["SEGUIMIENTO", "CERCANA", "CAPÓ", "PARAGOLPES"]
var target: Node3D
var race_peer: Node3D
var mode := 0
var response := 9.0
var heading_response := 4.8
var base_distance := 6.5
var base_height := 2.5
var base_fov := 60.0
var max_fov := 72.0
var look_input := Vector2.ZERO
var look_back := false
var _heading := 0.0
var _orbit := 0.0
var _camera_offset := Vector3.ZERO
var _last_back := false

func _speed() -> float:
    if not is_instance_valid(target):
        return 0.0
    var model = target.get("physics")
    return model.speed() if model != null else 0.0

func cycle_mode() -> void:
    mode = (mode + 1) % MODES.size()
    snap()

func _offset(speed: float) -> Vector3:
    var distance := base_distance
    var height := base_height
    if mode == 1:
        distance = 4.5
        height = 1.7
    elif mode == 2:
        distance = -2.1 if look_back else -0.80
        height = 0.68
    elif mode == 3:
        distance = -2.1
        height = 0.12
    else:
        distance += clampf(speed,0.0,45.0) * 0.035
        height += clampf(speed,0.0,45.0) * 0.008
    var lateral := 0.0
    if mode==0 and is_instance_valid(race_peer):
        distance += 2.5+clampf(absf(race_peer.global_position.z-target.global_position.z),0,20)*0.85
        height += 0.6
        lateral = (race_peer.global_position.x-target.global_position.x)*0.5
    return Vector3(sin(_heading + _orbit),0,cos(_heading + _orbit)) * distance + Vector3.UP * (height + look_input.y * 0.7)+Vector3.RIGHT*lateral

func snap() -> void:
    if not is_instance_valid(target):
        return
    mode = clampi(mode,0,MODES.size()-1)
    _heading = target.global_rotation.y + (PI if look_back else 0.0)
    _orbit = 0.0
    _last_back = look_back
    _camera_offset = _offset(_speed())
    global_position = target.global_position + _camera_offset
    fov = base_fov + (8.0 if mode >= 2 else 0.0)
    near = 0.06 if mode >= 2 else 0.15
    var visual = target.get("visual")
    if visual != null:
        visual.visible = mode != 3
    _aim(_speed())

func _aim(speed: float) -> void:
    var back := Vector3(sin(_heading + _orbit),0,cos(_heading + _orbit))
    var height := 0.65 if mode >= 2 else 0.7
    var ahead := 20.0 if mode >= 2 else 2.5 + minf(speed,45.0) * 0.06
    var point := target.global_position
    if mode==0 and is_instance_valid(race_peer):
        point.x = (point.x+race_peer.global_position.x)*0.5
        point.z += clampf(race_peer.global_position.z-point.z,-20,20)*0.25
    look_at(point + Vector3.UP * height - back * ahead,Vector3.UP)

func _process(delta: float) -> void:
    if not is_instance_valid(target) or delta <= 0.0:
        return
    var speed := _speed()
    var wanted := target.global_rotation.y + (PI if look_back else 0.0)
    _orbit = move_toward(_orbit,look_input.x * 1.2,delta * 3.5)
    if mode >= 2 or _last_back != look_back:
        _heading = wanted
    else:
        _heading = lerp_angle(_heading,wanted,1.0-exp(-heading_response*delta))
    var desired := _offset(speed)
    if _last_back != look_back:
        _camera_offset = desired
    else:
        _camera_offset = _camera_offset.lerp(desired,1.0-exp(-response*delta))
    _last_back = look_back
    # Follow translation directly; smoothing the world position caused an extra
    # speed-dependent 5+ metre lag. Only the relative arm and heading are damped.
    var camera_position := target.global_position + _camera_offset
    if mode < 2 and target is CollisionObject3D:
        var query := PhysicsRayQueryParameters3D.create(target.global_position + Vector3.UP * 1.1,camera_position,1,[target.get_rid()])
        var hit := get_world_3d().direct_space_state.intersect_ray(query)
        if not hit.is_empty():
            camera_position = hit["position"] + hit["normal"] * 0.25
    global_position = camera_position
    var minimum_fov := base_fov + (8.0 if mode >= 2 else 0.0)
    var desired_fov := minimum_fov + clampf(speed/40.0,0.0,1.0) * (max_fov-minimum_fov)
    fov = lerpf(fov,desired_fov,1.0-exp(-3.0*delta))
    _aim(speed)
