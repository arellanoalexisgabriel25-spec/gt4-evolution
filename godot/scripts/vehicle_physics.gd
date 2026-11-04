extends RefCounted

# Deterministic planar arcade model, independent of input, scenes and persistence.
# Lateral correction is limited by available tire acceleration; excess demand
# retains sideways velocity instead of immediately rotating the velocity vector.
# 0.11: axle loads follow weight transfer (understeer on power, lift-off
# rotation under braking), engine torque follows RPM, and braking is grip-limited.
const LOAD_SHIFT := 0.06
const LOAD_SENSITIVITY := 0.35
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

# Tire load sensitivity: extra load adds less grip than lost load removes.
static func load_grip(factor: float) -> float:
    return maxf(factor * (1.0 - LOAD_SENSITIVITY * (factor - 1.0)), 0.2)

# Relative grip of the (front, rear) axles for the current weight transfer.
func axle_grip() -> Vector2:
    var front_static := clampf(config.front_weight_bias, 0.3, 0.7)
    var rear_static := 1.0 - front_static
    var shift := LOAD_SHIFT * weight_transfer
    return Vector2(load_grip((front_static - shift) / front_static), load_grip((rear_static + shift) / rear_static))

# Normalized engine torque at the current RPM.
func torque_factor() -> float:
    var curve: PackedFloat32Array = config.torque_curve
    if curve.size() == 0:
        return 1.0
    if curve.size() == 1:
        return curve[0]
    var span := maxf(config.redline_rpm - config.idle_rpm, 1.0)
    var position := clampf((rpm - config.idle_rpm) / span, 0.0, 1.0) * float(curve.size() - 1)
    var index := mini(int(position), curve.size() - 2)
    return lerpf(curve[index], curve[index + 1], position - float(index))

func forward() -> Vector2:
    return Vector2(-sin(heading), -cos(heading))

func signed_speed() -> float:
    return velocity.dot(forward())

func speed() -> float:
    return velocity.length()

func step(delta: float, requested_throttle: float, requested_steering: float, brake: bool, on_road: bool = true, brake_strength: float = 1.0) -> void:
    if delta <= 0.0:
        return
    throttle = move_toward(throttle, clampf(requested_throttle, -1.0, 1.0), config.input_response * delta)
    var steering_goal := clampf(requested_steering,-1.0,1.0)
    var steering_rate: float = config.centering_response if absf(steering_goal) < 0.01 else config.steering_response / (1.0 + speed()/60.0)
    steering = move_toward(steering,steering_goal,steering_rate*delta)
    var direction := forward()
    var right := Vector2(-direction.y, direction.x)
    var longitudinal := velocity.dot(direction)
    var lateral := velocity.dot(right)
    var before := longitudinal
    var surface := 1.0 if on_road else 0.45
    var brake_limit: float = config.grip * 9.81 * surface * config.brake_grip_factor
    var applying_drive := false
    if brake:
        var deceleration := minf(config.braking * clampf(brake_strength, 0.0, 1.0), brake_limit)
        longitudinal = move_toward(longitudinal, 0.0, deceleration * delta)
    elif throttle > 0.01:
        if longitudinal < -0.5:
            longitudinal = move_toward(longitudinal, 0.0, minf(config.braking * throttle, brake_limit) * delta)
        else:
            applying_drive = true
            var ratio := clampf(absf(longitudinal) / maxf(config.top_speed, 1.0), 0.0, 1.0)
            var drive: float = config.acceleration * throttle * torque_factor() * (1.0 - config.drag_taper * ratio * ratio)
            longitudinal = move_toward(longitudinal, config.top_speed, drive * delta)
    elif throttle < -0.01:
        if longitudinal > 0.5:
            longitudinal = move_toward(longitudinal, 0.0, minf(config.braking * -throttle, brake_limit) * delta)
        else:
            applying_drive = true
            longitudinal = move_toward(longitudinal, -config.reverse_speed, config.acceleration * -throttle * 0.6 * delta)
    else:
        longitudinal = move_toward(longitudinal, 0.0, (0.6 + absf(longitudinal) * 0.035) * delta)
    if not on_road:
        longitudinal = move_toward(longitudinal, clampf(longitudinal, -7.0, 11.0), 30.0 * delta)
    var acceleration := (longitudinal - before) / delta
    weight_transfer = lerpf(weight_transfer, clampf(acceleration / 9.81, -1.0, 1.0), 1.0 - exp(-5.0 * delta))
    var axles := axle_grip()
    var tire_limit: float = config.grip * 9.81 * surface * minf(axles.x, axles.y)
    # Driven tires share lateral and longitudinal traction. FWD pushes wide;
    # RWD can break rear grip under power; AWD spreads the demand more evenly.
    # Only applied drive power loads the driven axle; braking is shared by all tires.
    var power_demand := 0.0
    if applying_drive and acceleration * signf(throttle) > 0.0:
        power_demand = clampf(absf(acceleration) / 20.0, 0.0, 0.8)
    # Front-heavy load transfer (braking) sharpens turn-in; rear-heavy (power) pushes wide.
    var steer_scale := clampf(axles.x / axles.y, 0.8, 1.2)
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
    # Yaw saturates near the lateral grip limit, so full lock at speed pushes wide
    # instead of spinning the heading far ahead of the velocity vector.
    var base_limit: float = config.grip * 9.81 * surface * minf(axles.x, axles.y)
    var yaw_cap: float = base_limit * (1.0 + config.yaw_grip_overdrive) / maxf(absf(longitudinal), 4.0) * lerpf(1.0, clampf(steer_scale, 0.5, 1.2), 0.5)
    yaw_cap = minf(yaw_cap, 1.6)
    heading = wrapf(heading + clampf(yaw_rate, -yaw_cap, yaw_cap) * delta, -PI, PI)
    slip = absf(velocity.dot(Vector2(-forward().y, forward().x)))
    transmission.update(delta, signed_speed(), config)
    gear = transmission.gear
    rpm = transmission.rpm
