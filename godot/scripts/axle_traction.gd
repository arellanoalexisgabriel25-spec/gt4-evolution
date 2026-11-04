extends RefCounted

# Two longitudinal axle states. Contact forces dissipate slip energy; front/rear
# torque split and load transfer never create extra normal force or engine power.
var omega := Vector2.ZERO
var forces := Vector2.ZERO
var normal_loads := Vector2.ZERO
var slips := Vector2.ZERO
var temperatures := Vector2(28,28)
var filtered_acceleration := 0.0
var slip_power := 0.0
var brake_power := 0.0
var abs_active := false

func reset(keep_heat: bool = true) -> void:
    omega = Vector2.ZERO
    forces = Vector2.ZERO
    slips = Vector2.ZERO
    filtered_acceleration = 0.0
    abs_active = false
    if not keep_heat:
        temperatures = Vector2(28,28)

static func front_share(config) -> float:
    if config.drivetrain == "FWD":
        return 1.0
    if config.drivetrain == "RWD":
        return 0.0
    return clampf(config.awd_front_split,0.05,0.95)

static func friction_curve(slip: float, peak_slip: float = 0.12) -> float:
    var magnitude := absf(slip)
    var value := sin(minf(magnitude/peak_slip,1.0)*PI*0.5)
    if magnitude > peak_slip:
        value = 0.82+0.18*exp(-(magnitude-peak_slip)*3.0)
    return signf(slip)*value

func driven_omega(config) -> float:
    var front := front_share(config)
    return omega.x*front+omega.y*(1.0-front)

func driven_slip(config) -> float:
    if config.drivetrain == "FWD":
        return absf(slips.x)
    if config.drivetrain == "RWD":
        return absf(slips.y)
    return maxf(absf(slips.x),absf(slips.y))

func drive_slip(config) -> float:
    if config.drivetrain == "FWD":
        return maxf(0,slips.x)
    if config.drivetrain == "RWD":
        return maxf(0,slips.y)
    return maxf(0,maxf(slips.x,slips.y))

func step(dt: float, speed: float, drive_torque: float, brake: float, config, tire_health: float, road: bool) -> float:
    var weight: float = config.mass*9.81
    var front_load := clampf(weight*config.front_weight_bias-config.mass*filtered_acceleration*config.cg_height/config.wheelbase,weight*0.08,weight*0.92)
    normal_loads = Vector2(front_load,weight-front_load)
    var split := front_share(config)
    var drive := Vector2(drive_torque*split,drive_torque*(1.0-split))
    var brake_total: float = brake*weight*config.wheel_radius*config.brake_capacity*(0.55+0.45*clampf(config.brake_health/100.0,0,1))
    var brakes := Vector2(brake_total*config.brake_front_bias,brake_total*(1.0-config.brake_front_bias))
    slip_power = 0.0
    brake_power = 0.0
    abs_active = false
    for index in range(2):
        slips[index] = (omega[index]*config.wheel_radius-speed)/maxf(speed,2.5)
        var temperature_grip := clampf(0.90+(temperatures[index]-28.0)*0.003,0.65,1.08)
        if temperatures[index]>90.0:
            temperature_grip = maxf(0.65,1.08-(temperatures[index]-90.0)*0.012)
        var load_sensitivity: float = pow(maxf(normal_loads[index]/(weight*0.5),0.1),-0.08)
        var mu: float = config.grip*(0.6+0.4*clampf(tire_health/100.0,0,1))*temperature_grip*load_sensitivity*(1.0 if road else 0.4)
        var target: float = normal_loads[index]*mu*friction_curve(slips[index],config.peak_slip)
        forces[index] = lerpf(forces[index],target,1.0-exp(-maxf(20,speed/0.25)*dt))
        # A relaxed force must not do positive work across a reversed slip.
        if forces[index]*slips[index]<0.0:
            forces[index] = 0.0
        var applied_brake := brakes[index]
        if config.abs_assist and speed>3.0 and slips[index]<-0.16:
            applied_brake *= clampf(1.0+(slips[index]+0.16)*4.0,0.08,1.0)
            abs_active = true
        var spin_before := omega[index]
        var torque: float = drive[index]-forces[index]*config.wheel_radius
        omega[index] = maxf(0,omega[index]+torque*dt/config.wheel_inertia)
        omega[index] = move_toward(omega[index],0,applied_brake*dt/config.wheel_inertia)
        var energy_rate := maxf(0,forces[index]*(spin_before*config.wheel_radius-speed))
        slip_power += energy_rate
        brake_power += applied_brake*minf(spin_before,omega[index])
        temperatures[index] += (energy_rate/16000.0-(temperatures[index]-28.0)*0.025)*dt
    return forces.x+forces.y

func observe_acceleration(value: float, dt: float) -> void:
    filtered_acceleration = lerpf(filtered_acceleration,clampf(value,-15,15),1.0-exp(-12.0*dt))
