extends RefCounted
const Tire = preload("res://scripts/tire_model.gd")

# Two longitudinal axle states. Contact forces dissipate slip energy; front/rear
# torque split and load transfer never create extra normal force or engine power.
var omega := Vector2.ZERO
var forces := Vector2.ZERO
var normal_loads := Vector2.ZERO
var slips := Vector2.ZERO
var tires: Array = [Tire.new(),Tire.new()]
var temperatures: Vector2:
    get: return Vector2(tires[0].temperature,tires[1].temperature)
    set(value):
        tires[0].temperature = value.x
        tires[1].temperature = value.y
var filtered_acceleration := 0.0
var slip_power := 0.0
var brake_power := 0.0
var brake_energy := Vector2.ZERO
var brake_torques := Vector2.ZERO
var capacities := Vector2.ZERO
var abs_active := false

func reset(keep_heat: bool = true) -> void:
    omega = Vector2.ZERO
    forces = Vector2.ZERO
    slips = Vector2.ZERO
    filtered_acceleration = 0.0
    abs_active = false
    normal_loads = Vector2.ZERO
    slip_power = 0.0
    brake_power = 0.0
    brake_energy = Vector2.ZERO
    if not keep_heat:
        for tire in tires:
            tire.reset()

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

# contact is the supported fraction of each axle; no missing load is invented on
# the other axle. surface_grip is additional per-axle grip (legacy road=false still
# applies its historical 0.4 multiplier). Bench callers retain full dry contact.
func step(dt: float, speed: float, drive_torque: float, brake: float, config, tire_health: float, road: bool, contact: Vector2 = Vector2.ONE, surface_grip: Vector2 = Vector2.ONE, handbrake: float = 0.0, normal_g: float = -1.0, grade_acceleration: float = 0.0, brake_factors: Vector2 = Vector2.ONE) -> float:
    if not is_finite(dt) or dt<=0.0 or not is_finite(speed) or not is_finite(drive_torque) or not is_finite(brake) or not is_finite(tire_health) or not is_finite(handbrake):
        return 0.0
    contact = Vector2(clampf(contact.x,0.0,1.0),clampf(contact.y,0.0,1.0)) if contact.is_finite() else Vector2.ZERO
    surface_grip = Vector2(clampf(surface_grip.x,0.0,2.0),clampf(surface_grip.y,0.0,2.0)) if surface_grip.is_finite() else Vector2.ZERO
    var gravity: float = config.gravity_mps2 if normal_g<0.0 else normal_g
    var weight: float = config.mass*gravity
    # The tire-supported acceleration excludes gravity along the grade. This
    # also gives the correct static axle transfer while held on an incline.
    var front_load := clampf(weight*config.front_weight_bias-config.mass*(filtered_acceleration-grade_acceleration)*config.cg_height/config.wheelbase,0.0,weight)
    normal_loads = Vector2(front_load,weight-front_load)*contact
    var split := front_share(config)
    var drive := Vector2(drive_torque*split,drive_torque*(1.0-split))
    # Hydraulic capacity belongs to the brake hardware, independent of slope
    # or whether a tire is touching the ground. Contact still limits road force.
    var hardware_weight: float = config.mass*config.gravity_mps2
    var brake_total: float = clampf(brake,0.0,1.0)*hardware_weight*config.wheel_radius*config.brake_capacity*(0.55+0.45*clampf(config.brake_health/100.0,0,1))
    var brakes := Vector2(brake_total*config.brake_front_bias,brake_total*(1.0-config.brake_front_bias))
    # Mechanical parking brake acts on the rear axle, independently of the
    # hydraulic pedal and ABS. It adds no engine torque or tire temperature.
    var rear_parking: float = clampf(handbrake,0.0,1.0)*hardware_weight*config.wheel_radius*0.65*(0.55+0.45*clampf(config.brake_health/100.0,0,1))
    slip_power = 0.0
    brake_power = 0.0
    brake_energy = Vector2.ZERO
    abs_active = false
    for index in range(2):
        var relative: float = omega[index]*config.wheel_radius-speed
        slips[index] = relative/maxf(absf(speed),2.5)
        tires[index].compound = config.tire_compound
        var temperature_grip: float = tires[index].thermal_grip()
        var load_sensitivity: float = pow(maxf(normal_loads[index]/maxf(hardware_weight*0.5,0.1),0.1),-0.08)
        var mu: float = config.grip*(0.6+0.4*clampf(tire_health/100.0,0,1))*temperature_grip*load_sensitivity*surface_grip[index]*(1.0 if road else 0.4)
        var capacity: float = normal_loads[index]*mu
        capacities[index] = capacity
        var target: float = capacity*friction_curve(slips[index],config.peak_slip)
        var raw_brake: float = maxf(brakes[index]*brake_factors[index],rear_parking if index==1 else 0.0)
        var holding_reserve: float = maxf(0.0,raw_brake-absf(drive[index]))
        var held: bool = absf(omega[index]*config.wheel_radius)<0.08 and holding_reserve>0.0
        if held and absf(speed)<2.5:
            # Low-speed slip regularization must not erase static/locked-tire
            # friction and let a braked car creep forever down an incline.
            target = -signf(speed)*minf(capacity,holding_reserve/config.wheel_radius)
        forces[index] = clampf(lerpf(forces[index],target,1.0-exp(-maxf(20,speed/0.25)*dt)),-capacity,capacity)
        # Force relaxation cannot retain more grip than the surface currently
        # supports. In the air capacity is zero, so contact force ends at once.
        # A relaxed force must not do positive work across a reversed slip.
        if forces[index]*slips[index]<0.0:
            forces[index] = 0.0
        # Bound the contact impulse by the effective wheel/body inertia. The
        # 2/m bound includes both simultaneous axle forces: friction alone may
        # dissipate energy, but cannot overshoot slip and create kinetic energy.
        var rotational_inverse: float = 0.0 if held else config.wheel_radius*config.wheel_radius/config.wheel_inertia
        var impulse_limit: float = absf(relative)/maxf(dt*(rotational_inverse+2.0/config.mass),0.00000001)
        forces[index] = clampf(forces[index],-impulse_limit,impulse_limit)
        var applied_brake: float = brakes[index]*brake_factors[index]
        var locking_slip := -slips[index]*signf(speed)
        if normal_loads[index]>0.0 and config.abs_assist and absf(speed)>3.0 and locking_slip>0.16:
            applied_brake *= clampf(1.0-(locking_slip-0.16)*4.0,0.08,1.0)
            abs_active = true
        if index==1:
            applied_brake = maxf(applied_brake,rear_parking)
        brake_torques[index] = applied_brake
        var spin_before := omega[index]
        var torque: float = drive[index]-forces[index]*config.wheel_radius
        omega[index] += torque*dt/config.wheel_inertia
        var pre_brake := omega[index]
        omega[index] = move_toward(pre_brake,0,applied_brake*dt/config.wheel_inertia)
        var energy_rate := maxf(0,forces[index]*(spin_before*config.wheel_radius-speed))
        slip_power += energy_rate
        # Exact energy removed by the brake operator, including a wheel that
        # stops within this step. Drive/contact work before braking stays separate.
        brake_energy[index] = 0.5*config.wheel_inertia*(pre_brake*pre_brake-omega[index]*omega[index])
        brake_power += brake_energy[index]/dt
        tires[index].step_contact(dt,energy_rate,normal_loads[index],forces[index],speed,road)
    return forces.x+forces.y

func holding_force(drive_torque: float, config) -> float:
    var result := 0.0
    var split := front_share(config)
    for axle in range(2):
        if absf(omega[axle]*config.wheel_radius)>0.08: continue
        var driven: float = absf(drive_torque*(split if axle==0 else 1.0-split))
        var hardware: float = maxf(0.0,brake_torques[axle]-driven)/config.wheel_radius
        var contact := maxf(0.0,capacities[axle]-absf(forces[axle]))
        result += minf(hardware,contact)
    return result

func observe_acceleration(value: float, dt: float) -> void:
    filtered_acceleration = lerpf(filtered_acceleration,clampf(value,-15,15),1.0-exp(-12.0*dt))

func tread_wear_points() -> float:
    return (float(tires[0].wear)+float(tires[1].wear))*25.0
