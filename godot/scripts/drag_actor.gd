extends "res://scripts/vehicle_actor.gd"

const Manual = preload("res://scripts/manual_powertrain.gd")
const Damage = preload("res://scripts/damage_model.gd")
var powertrain = Manual.new()
var damage = Damage.new()
var measured_acceleration := 0.0
var zero_to_hundred := -1.0
var acceleration_clock := 0.0

func drive_manual(delta: float, controls: Dictionary, road: bool) -> void:
    var speed_before: float = powertrain.speed_mps
    damage.tick(delta)
    var pedal: float = float(controls.get("throttle",0.0))
    var brake: float = maxf(float(controls.get("brake",0.0)),-pedal)
    powertrain.step(delta,maxf(0,pedal),float(controls.get("clutch",0.0)),brake,road)
    # Light directional assistance for the first longitudinal driving increment.
    # Lane violations still use the real collider position and invalidate a pass.
    var steer: float = float(controls.get("steer",0.0))*powertrain.config.steering_factor
    rotation.y = lerp_angle(rotation.y,-steer*0.09/(1.0+powertrain.speed_mps/50.0),1.0-exp(-5.0*delta))
    var previous := global_position
    var forward := -global_basis.z
    velocity.x = forward.x*powertrain.speed_mps
    velocity.z = forward.z*powertrain.speed_mps
    velocity.y = -1.0 if is_on_floor() else velocity.y-15.0*delta
    var incoming := Vector2(velocity.x,velocity.z)
    move_and_slide()
    # Compare the requested velocity AFTER propulsion/braking with the resolved
    # collision velocity. Normal acceleration and recovery are never impacts.
    if is_on_wall() and damage.record(incoming,Vector2(velocity.x,velocity.z),Vector2(forward.x,forward.z))>0.0:
        powertrain.config.apply_damage(damage.latest_damage)
    powertrain.speed_mps = maxf(0,Vector3(velocity.x,0,velocity.z).dot(forward))
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
    var measured := Vector2(global_position.x-previous.x,global_position.z-previous.z).length()
    if measured < 10.0:
        distance_m += measured
    if is_on_wall():
        contact_count += 1
    visual.update_motion(delta,powertrain.speed_mps,steer,powertrain.axles.filtered_acceleration/9.81,brake,powertrain.axles.omega*powertrain.config.wheel_radius)

func recover(location: Vector3, angle: float = 0.0) -> void:
    super.recover(location,angle)
    powertrain.reset()
    reset_metrics()

func reset_metrics() -> void:
    measured_acceleration = 0.0
    zero_to_hundred = -1.0
    acceleration_clock = 0.0
