extends "res://scripts/vehicle_actor.gd"

const Manual = preload("res://scripts/manual_powertrain.gd")
var powertrain = Manual.new()

func drive_manual(delta: float, controls: Dictionary, road: bool) -> void:
    var pedal: float = float(controls.get("throttle",0.0))
    var brake: float = maxf(float(controls.get("brake",0.0)),-pedal)
    powertrain.step(delta,maxf(0,pedal),float(controls.get("clutch",0.0)),brake,road)
    # Light directional assistance for the first longitudinal driving increment.
    # Lane violations still use the real collider position and invalidate a pass.
    var steer: float = float(controls.get("steer",0.0))
    rotation.y = lerp_angle(rotation.y,-steer*0.09/(1.0+powertrain.speed_mps/50.0),1.0-exp(-5.0*delta))
    var previous := global_position
    var forward := -global_basis.z
    velocity.x = forward.x*powertrain.speed_mps
    velocity.z = forward.z*powertrain.speed_mps
    velocity.y = -1.0 if is_on_floor() else velocity.y-15.0*delta
    move_and_slide()
    powertrain.speed_mps = maxf(0,Vector3(velocity.x,0,velocity.z).dot(forward))
    physics.velocity = Vector2(velocity.x,velocity.z)
    physics.heading = rotation.y
    physics.gear = powertrain.gear
    physics.rpm = powertrain.rpm
    var measured := Vector2(global_position.x-previous.x,global_position.z-previous.z).length()
    if measured < 10.0:
        distance_m += measured
    if is_on_wall():
        contact_count += 1
    visual.update_motion(delta,powertrain.wheel_omega*powertrain.config.wheel_radius,steer,powertrain.acceleration/9.81,brake)

func recover(location: Vector3, angle: float = 0.0) -> void:
    super.recover(location,angle)
    powertrain.reset()
