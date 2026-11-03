extends RefCounted

# Deterministic planar arcade model, independent of input, scenes and persistence.
# Lateral correction is limited by available tire acceleration; excess demand
# retains sideways velocity instead of immediately rotating the velocity vector.
const Config = preload("res://scripts/vehicle_config.gd")
const Transmission = preload("res://scripts/transmission.gd")
var transmission = Transmission.new()
var config = Config.new()
var velocity := Vector2.ZERO
var heading := 0.0
var throttle := 0.0
var steering := 0.0
var weight_transfer := 0.0
var slip := 0.0
var gear := 1
var rpm := 900.0

func reset(angle: float = 0.0) -> void:
    velocity = Vector2.ZERO
    heading = angle
    throttle = 0.0
    steering = 0.0
    weight_transfer = 0.0
    slip = 0.0
    gear = 1
    rpm = 900.0
    transmission.reset()

func forward() -> Vector2:
    return Vector2(-sin(heading), -cos(heading))

func signed_speed() -> float:
    return velocity.dot(forward())

func step(delta: float, requested_throttle: float, requested_steering: float, brake: bool, on_road: bool = true) -> void:
    if delta <= 0.0:
        return
    throttle = move_toward(throttle, clampf(requested_throttle, -1.0, 1.0), config.input_response * delta)
    steering = move_toward(steering, clampf(requested_steering, -1.0, 1.0), config.input_response * delta)
    var direction := forward()
    var right := Vector2(-direction.y, direction.x)
    var longitudinal := velocity.dot(direction)
    var lateral := velocity.dot(right)
    var before := longitudinal
    if brake:
        longitudinal = move_toward(longitudinal, 0.0, config.braking * delta)
    elif throttle > 0.01:
        if longitudinal < -0.5:
            longitudinal = move_toward(longitudinal, 0.0, config.braking * throttle * delta)
        else:
            longitudinal = move_toward(longitudinal, config.top_speed, config.acceleration * throttle * delta)
    elif throttle < -0.01:
        if longitudinal > 0.5:
            longitudinal = move_toward(longitudinal, 0.0, config.braking * -throttle * delta)
        else:
            longitudinal = move_toward(longitudinal, -config.reverse_speed, config.acceleration * -throttle * 0.6 * delta)
    else:
        longitudinal = move_toward(longitudinal, 0.0, (0.6 + absf(longitudinal) * 0.035) * delta)
    if not on_road:
        longitudinal = move_toward(longitudinal, clampf(longitudinal, -7.0, 11.0), 30.0 * delta)
    var acceleration := (longitudinal - before) / delta
    weight_transfer = lerpf(weight_transfer, clampf(acceleration / 9.81, -1.0, 1.0), 1.0 - exp(-5.0 * delta))
    var tire_limit: float = config.grip * 9.81 * (1.0 if on_road else 0.45)
    # Driven tires share lateral and longitudinal traction. FWD pushes wide;
    # RWD can break rear grip under power; AWD spreads the demand more evenly.
    var power_demand := clampf(absf(acceleration) / 20.0, 0.0, 0.8)
    var steer_scale := 1.0
    if config.drivetrain == "FWD":
        steer_scale -= power_demand * 0.35
        tire_limit *= 1.0 - power_demand * 0.15
    elif config.drivetrain == "RWD":
        tire_limit *= 1.0 - power_demand * 0.45
    else:
        tire_limit *= 1.0 - power_demand * 0.10
    var correction := clampf(-lateral * config.lateral_response, -tire_limit, tire_limit)
    lateral += correction * delta
    velocity = direction * longitudinal + right * lateral
    var wheel_angle: float = steering * config.steering_angle / (1.0 + absf(longitudinal) / 18.0)
    var yaw_rate: float = -longitudinal / maxf(config.wheelbase, 0.5) * tan(wheel_angle) * steer_scale
    heading = wrapf(heading + clampf(yaw_rate, -1.6, 1.6) * delta, -PI, PI)
    slip = absf(velocity.dot(Vector2(-forward().y, forward().x)))
    transmission.update(delta, signed_speed(), config)
    gear = transmission.gear
    rpm = transmission.rpm
