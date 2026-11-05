extends "res://scripts/vehicle_actor.gd"

const Manual = preload("res://scripts/manual_powertrain.gd")
const Surfaces = preload("res://scripts/track_surface.gd")
const Damage = preload("res://scripts/damage_model.gd")
const EnvironmentData = preload("res://scripts/driving_environment.gd")
var conditions = EnvironmentData.new()
var powertrain = Manual.new()
var damage = Damage.new()
var ground_state: Dictionary = Surfaces.combine([{},{},{},{}])
var measured_acceleration := 0.0
var zero_to_hundred := -1.0
var acceleration_clock := 0.0
var wheel_pitch := 0.0
var requested_speed_mps := 0.0

func _ready() -> void:
    super._ready()
    # Let the force solver decide acceleration; CharacterBody only resolves the
    # commanded path at that speed instead of adding its own slope response.
    floor_constant_speed = true
    visual.set_night_lighting()

# Four vertical suspension probes query real world collision, excluding vehicles.
# Ray reach is an explicit approximation; there is no full suspension solver yet.
func sample_ground() -> Dictionary:
    var profile: Dictionary = Catalog.definition(model_name)
    var width: float = profile.get("size",Vector3(1.8,1.4,3.9)).x
    var half_track := width*0.40
    var half_base: float = powertrain.config.wheelbase*0.5
    var samples: Array = []
    var space := get_world_3d().direct_space_state
    var wheel_frame := Basis(Vector3.RIGHT,wheel_pitch)
    for z in [-half_base,half_base]:
        for x in [-half_track,half_track]:
            var origin := to_global(wheel_frame*Vector3(x,0.15,z))
            var end := to_global(wheel_frame*Vector3(x,-0.66,z))
            var query := PhysicsRayQueryParameters3D.create(origin,end,1,[get_rid()])
            var hit := space.intersect_ray(query)
            var supported := not hit.is_empty() and Vector3(hit.normal).dot(Vector3.UP)>=0.65
            var sample := Surfaces.at(hit.position) if supported else {}
            if supported: sample["normal"] = hit.normal
            samples.append(sample)
    return Surfaces.combine(samples)

func drive_manual(delta: float, controls: Dictionary, _road: bool = true) -> void:
    if not is_finite(delta) or delta<=0.0 or delta>0.1:
        return
    # Reject malformed controls before touching transforms, wear or telemetry.
    for action in ["throttle","brake","clutch","steer","handbrake"]:
        var value = controls.get(action,0.0)
        if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)):
            return
    ground_state = sample_ground()
    var gravity := get_gravity()
    powertrain.config.gravity_mps2 = gravity.length()
    powertrain.config.air_density = conditions.density()
    var supported: bool = int(ground_state.get("wheels_on_ground",0))>0
    var frame := EnvironmentData.frame(-global_basis.z,ground_state.get("normal",Vector3.UP),gravity)
    if supported:
        wheel_pitch = asin(clampf(Vector3(frame.tangent).y,-1.0,1.0))
        # Rigid terrain alignment of the simple collider, not a suspension rig.
        get_child(0).rotation.x = wheel_pitch
    ground_state["normal_g"] = frame.normal_g
    ground_state["grade_acceleration"] = frame.grade_acceleration if supported else 0.0
    ground_state["wind_along"] = conditions.wind_velocity.dot(frame.tangent)
    var speed_before: float = powertrain.speed_mps
    damage.tick(delta)
    var pedal: float = float(controls.get("throttle",0.0))
    var brake: float = maxf(float(controls.get("brake",0.0)),-pedal)
    powertrain.step(delta,maxf(0,pedal),float(controls.get("clutch",0.0)),brake,true,ground_state,float(controls.get("handbrake",0.0)))
    requested_speed_mps = powertrain.speed_mps
    # Light directional assistance for the first longitudinal driving increment.
    # Lane violations still use the real collider position and invalidate a pass.
    var steer: float = float(controls.get("steer",0.0))*powertrain.config.steering_factor
    rotation.y = lerp_angle(rotation.y,-steer*0.09/(1.0+powertrain.speed_mps/50.0),1.0-exp(-5.0*delta))
    var previous := global_position
    var forward: Vector3 = frame.tangent if supported else -global_basis.z
    velocity.x = forward.x*powertrain.speed_mps
    velocity.z = forward.z*powertrain.speed_mps
    floor_stop_on_slope = supported and absf(powertrain.speed_mps)<0.00001
    if supported and is_on_floor():
        # Godot keeps the horizontal command's direction during floor sliding.
        # A normal-directed bias can invert that command at low speed on grades.
        velocity.y = -0.5
    else:
        velocity.y += gravity.y*delta
    var incoming := Vector2(velocity.x,velocity.z)
    move_and_slide()
    # Compare the requested velocity AFTER propulsion/braking with the resolved
    # collision velocity. Normal acceleration and recovery are never impacts.
    if is_on_wall() and damage.record(incoming,Vector2(velocity.x,velocity.z),Vector2(forward.x,forward.z),powertrain.config.engine_position)>0.0:
        powertrain.config.apply_damage(damage.latest_damage)
    # Grounded CharacterBody resets its reported vertical velocity after floor
    # contact. Reproject measured travel, not that incomplete velocity, onto the
    # slope; otherwise the normal contact bias becomes phantom propulsion.
    powertrain.speed_mps = (global_position-previous).dot(forward)/delta if supported else Vector3(velocity.x,0,velocity.z).dot(forward)
    if is_on_wall():
        # Travel before an impact is not the post-impact velocity. Using the
        # frame-average here would repeatedly propel an already stopped car.
        powertrain.speed_mps = Vector3(velocity.x,0,velocity.z).dot(Vector3(forward.x,0,forward.z).normalized())
    measured_acceleration = (powertrain.speed_mps-speed_before)/maxf(delta,0.000001)
    if acceleration_clock==0.0 and speed_before<=0.1 and powertrain.speed_mps>0.1:
        acceleration_clock = delta*(powertrain.speed_mps-0.1)/maxf(powertrain.speed_mps-speed_before,0.000001)
    elif acceleration_clock>0.0:
        acceleration_clock += delta
    if acceleration_clock>0.0:
        if zero_to_hundred<0 and speed_before<100.0/3.6 and powertrain.speed_mps>=100.0/3.6:
            zero_to_hundred = acceleration_clock-delta+delta*(100.0/3.6-speed_before)/maxf(powertrain.speed_mps-speed_before,0.000001)
    physics.velocity = Vector2(velocity.x,velocity.z)
    physics.heading = rotation.y
    physics.gear = powertrain.gear
    physics.rpm = powertrain.rpm
    var measured := (global_position-previous).slide(frame.normal).length() if supported else 0.0
    if measured < 10.0:
        distance_m += measured
    if is_on_wall():
        contact_count += 1
    visual.road_pitch = wheel_pitch
    visual.update_motion(delta,powertrain.speed_mps,steer,powertrain.axles.filtered_acceleration/maxf(powertrain.config.gravity_mps2,0.1),brake,powertrain.axles.omega*powertrain.config.wheel_radius)

func recover(location: Vector3, angle: float = 0.0) -> void:
    super.recover(location,angle)
    wheel_pitch = 0.0
    get_child(0).rotation.x = 0.0
    powertrain.reset()
    ground_state = Surfaces.combine([{},{},{},{}])
    reset_metrics()

func reset_metrics() -> void:
    measured_acceleration = 0.0
    zero_to_hundred = -1.0
    acceleration_clock = 0.0

# The manual drag gearbox has no reverse gear yet. The starter's pre-race
# alignment assist moves the collider only before either timing beam is armed.
# This is disclosed to the player; it never repairs, cools or resets session use.
func align_for_start(location: Vector3) -> void:
    global_position = location
    rotation = Vector3.ZERO
    velocity = Vector3.ZERO
    powertrain.speed_mps = 0.0
    powertrain.axles.omega = Vector2.ZERO
    powertrain.axles.forces = Vector2.ZERO
    powertrain.axles.slips = Vector2.ZERO
    powertrain.axles.filtered_acceleration = 0.0
    powertrain.acceleration = 0.0
    powertrain.wheelspin = 0.0
    physics.velocity = Vector2.ZERO
    reset_metrics()
