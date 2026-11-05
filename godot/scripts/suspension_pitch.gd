extends RefCounted

# Reduced sprung-body pitch response, not a four-wheel suspension solver.
# The forcing moment comes from longitudinal acceleration. Exact integration of
# the linear spring/damper avoids timestep-dependent damping. Grade transfer is
# handled separately in the axle model so a held incline is static immediately.
var angle_rad := 0.0
var angular_velocity := 0.0
var restoring_moment_nm := 0.0

func reset() -> void:
    angle_rad = 0.0
    angular_velocity = 0.0
    restoring_moment_nm = 0.0

func energy_j(config) -> float:
    return 0.5*config.suspension_pitch_inertia_kg_m2*angular_velocity*angular_velocity+0.5*config.suspension_pitch_stiffness_nm_rad*angle_rad*angle_rad

func step(dt: float, moment_nm: float, config) -> float:
    if not is_finite(dt) or dt<=0.0 or not is_finite(moment_nm): return restoring_moment_nm
    var stiffness: float = maxf(config.suspension_pitch_stiffness_nm_rad,1.0)
    var health: float = clampf(config.suspension_health/100.0,0.0,1.0)
    var damping: float = maxf(config.suspension_pitch_damping_nms_rad,0.0)*(0.25+0.75*health)
    var inertia: float = maxf(config.suspension_pitch_inertia_kg_m2,1.0)
    var target := moment_nm/stiffness
    var position := angle_rad-target
    var velocity := angular_velocity
    var alpha := damping/(2.0*inertia)
    var frequency_squared := stiffness/inertia
    var discriminant := alpha*alpha-frequency_squared
    var next_position := 0.0
    var next_velocity := 0.0
    if absf(discriminant)<0.000001:
        var decay := exp(-alpha*dt)
        var coefficient := velocity+alpha*position
        next_position = decay*(position+coefficient*dt)
        next_velocity = decay*(velocity-alpha*coefficient*dt)
    elif discriminant<0.0:
        var frequency := sqrt(-discriminant)
        var decay := exp(-alpha*dt)
        var cosine := cos(frequency*dt)
        var sine := sin(frequency*dt)
        next_position = decay*(position*cosine+(velocity+alpha*position)*sine/frequency)
        next_velocity = decay*(velocity*cosine-(alpha*velocity+frequency_squared*position)*sine/frequency)
    else:
        var root := sqrt(discriminant)
        var first := -alpha+root
        var second := -alpha-root
        var coefficient := (velocity-second*position)/(first-second)
        var remainder := position-coefficient
        var first_decay := exp(first*dt)
        var second_decay := exp(second*dt)
        next_position = coefficient*first_decay+remainder*second_decay
        next_velocity = first*coefficient*first_decay+second*remainder*second_decay
    angle_rad = target+next_position
    angular_velocity = next_velocity
    restoring_moment_nm = stiffness*angle_rad+damping*angular_velocity
    return restoring_moment_nm
