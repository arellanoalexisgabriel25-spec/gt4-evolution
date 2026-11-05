extends SceneTree

const Vehicle = preload("res://scripts/vehicle_actor.gd")
const Camera = preload("res://scripts/chase_camera.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var stage := Node3D.new()
    root.add_child(stage)
    var car = Vehicle.new()
    car.position.y = 0.55
    stage.add_child(car)
    var camera = Camera.new()
    camera.target = car
    stage.add_child(camera)
    camera.set_process(false)
    await physics_frame
    camera.snap()
    check(camera.global_position.z > 6.0 and car.visual.visible,"Chase view sits behind the visible garage vehicle")
    var far_distance: float = camera.global_position.distance_to(car.global_position)
    camera.cycle_mode()
    check(camera.mode == 1 and camera.global_position.distance_to(car.global_position) < far_distance,"Close chase uses a distinct shorter arm")
    camera.cycle_mode()
    check(camera.mode == 2 and camera.global_position.z < car.global_position.z and car.visual.visible,"Bonnet view is ahead of the cabin and retains the hood")
    check(camera.near < 0.1,"Bonnet view uses a close clipping plane")
    camera.cycle_mode()
    check(camera.mode == 3 and not car.visual.visible,"Bumper view hides only its own vehicle geometry")
    camera.cycle_mode()
    check(camera.mode == 0 and car.visual.visible,"Cycling wraps and restores the car model")
    car.physics.velocity = Vector2(0,-40)
    for i in range(120):
        car.position.z -= 40.0/60.0
        camera._process(1.0/60.0)
    var offset: Vector3 = camera.global_position - car.global_position
    check(offset.z > 7.5 and offset.z < 8.1,"At speed the chase arm extends without accumulating world-position lag")
    check(camera.fov > camera.base_fov and camera.fov <= camera.max_fov,"Field of view responds to ground speed within its bounds")
    camera.look_back = true
    camera._process(1.0/60.0)
    check(camera.global_position.z < car.global_position.z and (-camera.global_basis.z).z > 0.9,"Look-back switches sides immediately and faces rearward")
    camera.look_back = false
    camera._process(1.0/60.0)
    check(camera.global_position.z > car.global_position.z,"Releasing look-back restores forward chase without crossing the car")
    camera.look_input = Vector2(1,0)
    for i in range(60):
        camera._process(1.0/60.0)
    check(camera.global_position.x > car.global_position.x+3.0,"Camera look input orbits independently from vehicle heading")
    car.position = Vector3(0,0.55,0)
    car.physics.reset()
    camera.look_input = Vector2.ZERO
    camera.snap()
    var peer := Node3D.new()
    peer.position = Vector3(7.5,0.55,0)
    stage.add_child(peer)
    camera.race_peer = peer
    camera.snap()
    check(is_equal_approx(camera._peer_framing(),1.0) and root.get_visible_rect().has_point(camera.unproject_position(peer.global_position)),"Adjacent staging lanes remain visible together")
    peer.position.z = 7.0
    camera.snap()
    check(camera._peer_framing()>0.0 and camera._peer_framing()<1.0,"Two-car framing fades continuously as the physical gap opens")
    peer.position.z = 25.0
    camera.snap()
    check(camera._peer_framing()==0.0 and camera.global_position.distance_to(car.global_position)<8.0 and absf(camera.global_position.x-car.global_position.x)<0.01,"A distant trailing rival cannot pull the chase arm far behind the driven car")
    peer.position.z = -25.0
    camera.snap()
    check(camera._peer_framing()==0.0 and camera.global_position.distance_to(car.global_position)<8.0,"A distant leading rival cannot become the camera's target either")
    peer.position.z = 0.0
    camera.look_back = true
    camera.snap()
    check(camera._peer_framing()==0.0 and camera.global_position.z<car.global_position.z,"Rear look does not inherit the side-by-side staging offset")
    camera.look_back = false
    camera.race_peer = null
    camera.snap()
    check(camera._peer_framing()==0.0,"Single-car and old circuit cameras retain their own framing")
    var wall := StaticBody3D.new()
    wall.position = Vector3(0,2,3)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(6,4,0.4)
    collision.shape = shape
    wall.add_child(collision)
    stage.add_child(wall)
    await physics_frame
    await physics_frame
    camera._process(1.0/60.0)
    check(camera.global_position.z > 0.0 and camera.global_position.z < 2.8,"A real collision wall shortens the camera arm instead of occluding the player")
    stage.queue_free()
    await process_frame
    if not failed:
        print("PASS: %d camera mode assertions" % checks)
    quit(1 if failed else 0)
