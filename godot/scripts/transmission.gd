extends RefCounted

# Original Godot implementation. Research pointers and limits: REFERENCES.md.
# Angular speed -> RPM and one-step gear transitions are also observable in
# gt4-decomp func_00363868 / func_00351DC8; no recovered C++ is copied here.
var gear := 1
var rpm := 900.0
var shift_cooldown := 0.0

func reset() -> void:
    gear = 1
    rpm = 900.0
    shift_cooldown = 0.0

func coupled_rpm(speed_mps: float, ratio: float, config) -> float:
    var wheel_angular_speed := absf(speed_mps) / maxf(config.wheel_radius, 0.05)
    return wheel_angular_speed * absf(ratio * config.final_drive) * 60.0 / TAU

func update(delta: float, speed_mps: float, config) -> void:
    shift_cooldown = maxf(0.0, shift_cooldown - maxf(delta, 0.0))
    if speed_mps < -0.5:
        gear = -1
        rpm = clampf(coupled_rpm(speed_mps, config.reverse_ratio, config), config.idle_rpm, config.redline_rpm)
        return
    var count: int = config.gear_ratios.size()
    if count == 0:
        gear = 1
        rpm = config.idle_rpm
        return
    gear = clampi(gear, 1, count)
    var raw := coupled_rpm(speed_mps, config.gear_ratios[gear - 1], config)
    if shift_cooldown == 0.0:
        if raw >= config.upshift_rpm and gear < count:
            gear += 1
            shift_cooldown = config.shift_interval
        elif raw <= config.downshift_rpm and gear > 1:
            # Reject a downshift that would immediately require shifting up.
            var lower := coupled_rpm(speed_mps, config.gear_ratios[gear - 2], config)
            if lower < config.upshift_rpm:
                gear -= 1
                shift_cooldown = config.shift_interval
    rpm = clampf(coupled_rpm(speed_mps, config.gear_ratios[gear - 1], config), config.idle_rpm, config.redline_rpm)
