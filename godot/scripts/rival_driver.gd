extends RefCounted

# Deterministic pure-pursuit driver. It supplies the same normalized controls as
# the player; it never sets vehicle position, heading, velocity, or lap results.
var profile: Dictionary = {}
var elapsed := 0.0
var lane := 0.0
var preferred_side := 1.0
var overtaking := false
var target_speed := 0.0

func controls(delta: float, position: Vector3, physics, circuit, traffic: Array = []) -> Dictionary:
    elapsed += delta
    var projection: Dictionary = circuit.project(position)
    var along: float = projection["along"]
    var speed: float = physics.velocity.length()
    var skill := float(profile.get("skill", 60.0))
    var aggression := float(profile.get("aggression", 0.5))
    var consistency := float(profile.get("consistency", 0.8))
    var lookahead := clampf(6.0 + speed * 0.65, 7.0, 17.0)
    var forward := Vector3(physics.forward().x, 0, physics.forward().y)
    var right := Vector3(-forward.z, 0, forward.x)
    var desired_lane := 0.0
    target_speed = 13.0 + (skill - 50.0) * 0.15 + aggression
    overtaking = false
    for other in traffic:
        var difference: Vector3 = other["position"] - position
        var ahead := difference.dot(forward)
        var lateral := difference.dot(right)
        if ahead > 0.0 and ahead < 20.0 and absf(lateral) < 2.5:
            var passing_lane := preferred_side * (3.0 + aggression)
            var lane_clear := true
            for neighbor in traffic:
                var adjacent: Vector3 = neighbor["position"] - position
                if absf(adjacent.dot(right) - passing_lane) < 2.3 and absf(adjacent.dot(forward)) < 9.0:
                    lane_clear = false
            if lane_clear:
                desired_lane = passing_lane
                overtaking = true
            if ahead < 8.0 or not lane_clear:
                target_speed = minf(target_speed, maxf(0.0, float(other["speed"]) - (1.5 if ahead < 5.0 else 0.0)))
    lane = move_toward(lane, desired_lane, delta * (1.5 + aggression))
    # Deterministic small line errors and speed variation, never random teleports.
    var error := sin(elapsed * 0.7 + skill) * (1.0 - consistency) * 0.5
    target_speed *= 1.0 - (1.0 - consistency) * (0.5 + 0.5 * sin(elapsed * 0.4 + skill)) * 0.12
    for offset in [0.0, 8.0, 16.0, 24.0]:
        var first: Vector3 = circuit.tangent(along + offset)
        var second: Vector3 = circuit.tangent(along + offset + 8.0)
        var curvature := absf(first.signed_angle_to(second, Vector3.UP)) / 8.0
        if curvature > 0.005:
            var corner_speed := sqrt(5.0 * float(physics.config.grip) / curvature)
            target_speed = minf(target_speed, sqrt(corner_speed * corner_speed + 2.0 * 5.0 * offset))
    var tangent: Vector3 = circuit.tangent(along + lookahead)
    var target: Vector3 = circuit.sample(along + lookahead) + Vector3(-tangent.z, 0, tangent.x) * (lane + error)
    var direction := target - position
    var desired_heading := atan2(-direction.x, -direction.z)
    var heading_error := wrapf(desired_heading - physics.heading, -PI, PI)
    var desired_yaw := heading_error * 1.6
    var steer: float = -atan(desired_yaw * physics.config.wheelbase / maxf(speed, 3.0)) * (1.0 + speed / 18.0) / physics.config.steering_angle
    if absf(heading_error) > 0.7:
        target_speed = minf(target_speed, 5.0)
    var speed_error := target_speed - speed
    return {"throttle":clampf(speed_error * 0.6, 0.0, 1.0), "steer":clampf(steer, -1.0, 1.0), "brake":speed_error < -0.6}
