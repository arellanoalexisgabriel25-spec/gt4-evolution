extends SceneTree

const Surface = preload("res://scripts/track_surface.gd")
const Strip = preload("res://scripts/drag_strip.gd")
const Actor = preload("res://scripts/drag_actor.gd")
const Manual = preload("res://scripts/manual_powertrain.gd")
var checks := 0
var failed := false
var fixture: Node3D

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    call_deferred("run")

func new_fixture() -> void:
    fixture = Node3D.new()
    root.add_child(fixture)

func clear_fixture() -> void:
    fixture.free()
    await physics_frame
    await physics_frame

func ground_box(size: Vector3, location: Vector3, layer: int = 1, angle: float = 0.0) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.collision_layer = layer
    body.collision_mask = 0
    body.position = location
    body.rotation.z = angle
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    fixture.add_child(body)
    return body

func actor_at(location: Vector3):
    var actor = Actor.new()
    actor.position = location
    actor.collision_layer = 2
    actor.collision_mask = 1
    fixture.add_child(actor)
    return actor

func sync_physics() -> void:
    await physics_frame
    await physics_frame

func model_state(model) -> Dictionary:
    return {
        "rpm":model.rpm,"speed":model.speed_mps,"omega":model.axles.omega,
        "forces":model.axles.forces,"normal_loads":model.axles.normal_loads,
        "wear":model.wear.duplicate(true),"work":model.engine_work_j,
        "contact":model.contact_loads,"grip":model.surface_grip,"rolling":model.rolling_scale,
        "gear":model.gear,"throttle":model.throttle,"clutch":model.clutch_engagement,
        "shift_timer":model.shift_timer,"engine_running":model.engine_running,
        "engine_temperature":model.engine_temperature,"tire_temperatures":model.axles.temperatures,
        "clutch_heat":model.clutch_heat_j,"driveline_heat":model.driveline_heat_j,
        "tire_heat":model.tire_heat_j,"brake_heat":model.brake_heat_j,
        "road_work":model.road_work_j,"feedback_time":model.feedback_time,
    }

func actor_state(actor) -> Dictionary:
    return {
        "model":model_state(actor.powertrain),"position":actor.position,
        "rotation":actor.rotation,"velocity":actor.velocity,"distance":actor.distance_m,
        "ground":actor.ground_state.duplicate(true),"contacts":actor.contact_count,
        "acceleration_clock":actor.acceleration_clock,"zero_to_hundred":actor.zero_to_hundred,
        "measured_acceleration":actor.measured_acceleration,"damage_cooldown":actor.damage.cooldown,
        "damage_pending":actor.damage.pending.duplicate(true),
    }

func run() -> void:
    var asphalt: Dictionary = Surface.at(Vector3.ZERO)
    var apron: Dictionary = Surface.at(Vector3(Surface.ROAD_HALF_WIDTH+0.1,0.0,0.0))
    var gravel: Dictionary = Surface.at(Vector3(Surface.APRON_HALF_WIDTH+0.1,0.0,0.0))
    var grass: Dictionary = Surface.at(Vector3(Surface.GRAVEL_HALF_WIDTH+0.1,0.0,0.0))
    check(asphalt.id=="asphalt" and apron.id=="apron" and gravel.id=="gravel" and grass.id=="grass","The strip exposes separate paved lane, apron, dirt and grass profiles")
    check(Surface.at(Vector3(0,0,Surface.START_Z)).id=="asphalt" and Surface.at(Vector3(0,0,Surface.END_Z)).id=="asphalt","Surface classification includes the exact visible asphalt endpoints")
    check(Surface.at(Vector3(0,0,Surface.START_Z+0.01)).id=="grass" and Surface.at(Vector3(0,0,Surface.END_Z-0.01)).id=="grass","Asphalt grip ends at both finite ends of the visible strip")
    check(Surface.at(Vector3(NAN,0,0)).is_empty(),"Non-finite sample positions cannot select a surface")
    new_fixture()
    var strip = Strip.new()
    fixture.add_child(strip)
    var found := 0
    for half_width in [Surface.ROAD_HALF_WIDTH,Surface.APRON_HALF_WIDTH,Surface.GRAVEL_HALF_WIDTH]:
        for mesh in strip.find_children("*","MeshInstance3D",true,false):
            if not mesh.mesh is BoxMesh: continue
            var size: Vector3 = mesh.mesh.size
            if absf(size.x-float(half_width)*2.0)<0.001 and absf(size.z-Surface.LENGTH)<0.001:
                var bounds: AABB = mesh.global_transform*mesh.mesh.get_aabb()
                check(absf(bounds.position.x+float(half_width))<0.001 and absf(bounds.end.x-float(half_width))<0.001 and absf(bounds.position.z-Surface.END_Z)<0.001 and absf(bounds.end.z-Surface.START_Z)<0.001,"Visible surface bounds match the classifier's width and longitudinal limits")
                found += 1
                break
    check(found==3,"All three finite surface bands are represented by visible geometry")
    await clear_fixture()

    var all: Dictionary = Surface.combine([asphalt,asphalt,asphalt,asphalt])
    var front: Dictionary = Surface.combine([asphalt,asphalt,{},{}])
    var diagonal: Dictionary = Surface.combine([asphalt,{},{},asphalt])
    var none: Dictionary = Surface.combine([{},{},{},{}])
    check(all.contact==Vector2.ONE and all.grip==Vector2.ONE and all.rolling==1.0 and all.wheels_on_ground==4,"Four dry supported tires retain full axle contact and rolling resistance")
    check(front.contact==Vector2(1,0) and front.grip==Vector2(1,0) and front.rolling==0.5,"Two front supports retain only front loading and half the dry rolling contribution")
    check(diagonal.contact==Vector2(0.5,0.5) and diagonal.rolling==0.5,"Diagonal support halves each axle's own support without redistributing weight")
    check(none.contact==Vector2.ZERO and none.grip==Vector2.ZERO and none.rolling==0.0 and none.wheels_on_ground==0,"No supports yield no tire capacity or rolling resistance")
    var mixed: Dictionary = Surface.combine([asphalt,apron,gravel,grass])
    check(mixed.contact==Vector2.ONE and mixed.grip.is_equal_approx(Vector2(0.925,0.45)) and absf(float(mixed.rolling)-2.2875)<0.00001,"Mixed surfaces average supported tire coefficients independently per axle")
    check(Surface.combine([asphalt]).is_empty() and Surface.combine([asphalt,asphalt,asphalt,{"id":"unknown"}]).is_empty(),"Malformed or unknown four-wheel samples are rejected")
    var forged: Dictionary = asphalt.duplicate(true)
    forged.grip = 1000.0
    forged.rolling = 1000.0
    check(Surface.combine([forged,forged,forged,forged]).grip==Vector2.ONE,"Authoritative profile identifiers prevent arbitrary grip injected in a sample")
    for support in [all,front,diagonal,none]:
        var model = Manual.new()
        model.config.front_weight_bias = 0.5
        model.step(1.0/60.0,0,1,0,true,support)
        var weight: float = model.config.mass*9.81
        check(model.axles.normal_loads.is_equal_approx(Vector2.ONE*weight*0.5*support.contact),"The manual model applies actual per-axle support to normal loads")
        check(absf(model.road_load_force(0)-model.config.rolling_resistance*weight*float(support.rolling))<0.0001,"Rolling resistance follows the surface's supported-tire contribution")

    new_fixture()
    ground_box(Vector3(40,0.1,20),Vector3(0,-0.05,0))
    var actor = actor_at(Vector3(0,0.5,0))
    await sync_physics()
    var sampled: Dictionary = actor.sample_ground()
    check(sampled.contact==Vector2.ONE and sampled.wheels_on_ground==4 and sampled.label=="ASFALTO","Four suspension rays detect a real horizontal collider under all wheels")
    actor.position.x = Surface.ROAD_HALF_WIDTH
    await sync_physics()
    sampled = actor.sample_ground()
    check(sampled.contact==Vector2.ONE and sampled.grip.is_equal_approx(Vector2(0.925,0.925)) and absf(float(sampled.rolling)-1.075)<0.0001,"An actor straddling the physical asphalt edge samples different surfaces at left and right tires")
    await clear_fixture()

    for front_only in [true,false]:
        new_fixture()
        ground_box(Vector3(10,0.1,4),Vector3(0,-0.05,-2.0 if front_only else 2.0))
        actor = actor_at(Vector3(0,0.5,0))
        await sync_physics()
        sampled = actor.sample_ground()
        check(sampled.contact==(Vector2(1,0) if front_only else Vector2(0,1)) and sampled.wheels_on_ground==2,"The ray order distinguishes front-only and rear-only physical platforms")
        await clear_fixture()

    new_fixture()
    ground_box(Vector3(40,0.1,200),Vector3(0,-0.05,0))
    actor = actor_at(Vector3(0,0.5,Surface.START_Z))
    await sync_physics()
    sampled = actor.sample_ground()
    check(sampled.contact==Vector2.ONE and sampled.grip.is_equal_approx(Vector2(1.0,0.38)),"Front and rear wheel positions independently cross the finite paved start boundary")
    await clear_fixture()

    new_fixture()
    actor = actor_at(Vector3(0,0.5,0))
    # Thin walls lean five degrees so a vertical ray actually hits a side face;
    # the normals remain almost horizontal and cannot count as wheel support.
    for x in [-0.72,0.72]:
        ground_box(Vector3(0.04,4,8),Vector3(x,0.05,0),1,deg_to_rad(5.0))
    await sync_physics()
    var query := PhysicsRayQueryParameters3D.create(Vector3(0.72,0.65,-actor.powertrain.config.wheelbase*0.5),Vector3(0.72,-0.16,-actor.powertrain.config.wheelbase*0.5),1,[actor.get_rid()])
    var wall_hit: Dictionary = actor.get_world_3d().direct_space_state.intersect_ray(query)
    check(not wall_hit.is_empty() and absf(Vector3(wall_hit.normal).dot(Vector3.UP))<0.65,"The wall fixture produces a real side-face hit for the suspension ray")
    check(actor.sample_ground().wheels_on_ground==0,"Near-vertical collision faces cannot count as supporting road")
    await clear_fixture()

    new_fixture()
    actor = actor_at(Vector3(0,0.5,0))
    var rival = actor_at(Vector3(0,-0.5,0))
    rival.collision_layer = 2
    rival.collision_mask = 0
    await sync_physics()
    query = PhysicsRayQueryParameters3D.create(Vector3(0.72,0.65,0),Vector3(0.72,-0.16,0),2,[actor.get_rid()])
    var rival_hit: Dictionary = actor.get_world_3d().direct_space_state.intersect_ray(query)
    check(not rival_hit.is_empty() and rival_hit.collider==rival,"The rival's roof physically occupies the queried space on vehicle layer two")
    check(actor.sample_ground().wheels_on_ground==0,"Suspension rays exclude another vehicle instead of treating its roof as asphalt")
    await clear_fixture()

    new_fixture()
    actor = actor_at(Vector3(0,100,0))
    actor.powertrain.config.drivetrain = "FWD"
    actor.powertrain.gear = 2
    actor.powertrain.rpm = 4000.0
    actor.powertrain.throttle = 1.0
    actor.powertrain.clutch_engagement = 1.0
    actor.powertrain.speed_mps = 10.0
    actor.powertrain.wheel_omega = 10.0/actor.powertrain.config.wheel_radius
    actor.powertrain.config.air_density = 0.0
    actor.powertrain.axles.temperatures = Vector2(80,80)
    var spin_before: float = actor.powertrain.axles.omega.x
    await sync_physics()
    for i in range(60):
        await physics_frame
        actor.drive_manual(1.0/60.0,{"throttle":1.0,"clutch":0.0,"brake":0.0})
    check(not actor.is_on_floor() and actor.ground_state.wheels_on_ground==0 and actor.powertrain.axles.normal_loads==Vector2.ZERO,"An actual falling actor carries no wheel contact or normal load")
    check(absf(actor.powertrain.speed_mps-10.0)<0.0001 and actor.powertrain.axles.forces==Vector2.ZERO,"A falling car cannot accelerate its chassis from airborne engine torque")
    check(actor.powertrain.axles.omega.x>spin_before and actor.powertrain.engine_work_j>0.0,"Engine work can spin airborne drive wheels without becoming road propulsion")
    check(actor.powertrain.tire_heat_j==0.0 and actor.powertrain.wear.neumaticos==0.0 and actor.powertrain.axles.temperatures.x<80.0,"Unsupported tires cool while contact heat and contact tread wear remain zero")
    check(actor.powertrain.rolling_scale==0.0 and actor.powertrain.road_load_force(10.0)==0.0,"Airborne wheel contact cannot retain rolling resistance")
    check(absf(actor.velocity.y+9.81)<0.0001,"The drag actor falls under 9.81 m/s² for one second")
    var before := actor_state(actor)
    for delta in [NAN,INF,-0.01,0.0]:
        actor.drive_manual(delta,{"throttle":1.0})
    check(actor_state(actor)==before,"Invalid actor durations cannot mutate movement, timing metrics or contact state")
    for action in ["throttle","brake","clutch","steer"]:
        for bad_value in [NAN,INF,"invalid"]:
            var bad_controls := {"throttle":1.0,"brake":0.0,"clutch":0.0,"steer":0.1}
            bad_controls[action] = bad_value
            actor.drive_manual(1.0/60.0,bad_controls)
            check(actor_state(actor)==before,"Malformed %s input is rejected before transforms, powertrain, wear and telemetry change" % action)
    await clear_fixture()

    var validating = Manual.new()
    var initial := model_state(validating)
    for bad in [{"contact":Vector2(NAN,1)},{"contact":"asphalt"},{"grip":Vector2(1,INF)},{"grip":100},{"rolling":-1.0},{"rolling":NAN},{"rolling":"grass"}]:
        validating.step(1.0/60.0,1,0,0,true,bad)
        check(model_state(validating)==initial,"Malformed surface state is rejected before any drivetrain or contact state changes")
    validating.step(NAN,1,0,0,true,all)
    check(model_state(validating)==initial,"Non-finite manual-model durations preserve the previous state")
    if not failed: print("PASS: %d physical track-contact assertions" % checks)
    quit(1 if failed else 0)
