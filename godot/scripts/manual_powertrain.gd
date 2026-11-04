extends RefCounted

# Longitudinal model with separate engine/wheel inertia and finite clutch torque.
# Scene collision and beam timing use measured actor movement, not this model's
# integration. Substeps keep clutch and tire coupling stable at normal frame rates.
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Axles = preload("res://scripts/axle_traction.gd")
const EngineTorque = preload("res://scripts/engine_torque.gd")
var config = Config.new()
var axles = Axles.new()
var engine = EngineTorque.new()
var gear := 0
var rpm := 900.0
var speed_mps := 0.0
var wheel_omega: float:
    get: return axles.driven_omega(config)
    set(value): axles.omega = Vector2(value,value)
var clutch_engagement := 0.0
var throttle := 0.0
var engine_running := true
var shift_timer := 0.0
var missed_shifts := 0
var shifts := 0
var wheelspin := 0.0
var acceleration := 0.0
var tire_temperature: float:
    get:
        return axles.temperatures.x if config.drivetrain=="FWD" else (axles.temperatures.y if config.drivetrain=="RWD" else (axles.temperatures.x+axles.temperatures.y)*0.5)
    set(value): axles.temperatures = Vector2(value,value)
var engine_temperature := 88.0
var wear := {"motor":0.0,"transmision":0.0,"neumaticos":0.0,"frenos":0.0}
var feedback := "Punto muerto · C + subir marcha para engranar primera"
var feedback_time := 0.0
var limiter := false
var wheel_power_kw := 0.0
var clutch_loss_kw := 0.0
var engine_torque_nm := 0.0
var wheel_torque_nm := 0.0
var driveline_loss_kw := 0.0
var traction_control := false
var tcs_cut := 1.0

func reset(keep_heat: bool = true) -> void:
    axles.reset(keep_heat)
    engine.boost = 0.0
    tcs_cut = 1.0
    gear = 0
    rpm = config.idle_rpm
    speed_mps = 0.0
    wheel_omega = 0.0
    clutch_engagement = 0.0
    throttle = 0.0
    shift_timer = 0.0
    engine_running = true
    limiter = false
    acceleration = 0.0
    wheelspin = 0.0
    wheel_power_kw = 0.0
    clutch_loss_kw = 0.0
    engine_torque_nm = 0.0
    wheel_torque_nm = 0.0
    driveline_loss_kw = 0.0
    feedback = "Punto muerto · Embrague + subir marcha para engranar primera"
    if not keep_heat:
        engine_temperature = 88.0

func torque_at(engine_rpm: float) -> float:
    var factor := EngineTorque.curve_factor(engine_rpm,config)
    var health := clampf((config.engine_health-float(wear["motor"]))/100.0,0,1)
    var thermal := clampf(1.0-maxf(0,engine_temperature-105.0)*0.015,0.55,1.0)
    return config.peak_torque*factor*(0.65+0.35*health)*thermal

func shift(direction: int, clutch: float) -> bool:
    if direction not in [-1,1] or shift_timer > 0.0:
        return false
    var next := clampi(gear+direction,0,config.gear_ratios.size())
    if next == gear:
        return false
    if clutch < 0.7:
        missed_shifts += 1
        wear["transmision"] += 0.035
        shift_timer = 0.18
        feedback = "CAMBIO RECHAZADO · Pisá el embrague"
        feedback_time = 2.0
        return false
    feedback = "CAMBIO TEMPRANO · Caída de RPM" if gear > 0 and rpm < config.redline_rpm*0.7 else "CAMBIO EN BANDA"
    if rpm > config.redline_rpm*0.98:
        feedback = "CAMBIO TARDÍO · Cerca del corte"
    if next == 0:
        feedback = "PUNTO MUERTO"
    elif gear == 0:
        feedback = "PRIMERA ENGRANADA · Mantené el embrague"
    gear = next
    shifts += 1
    shift_timer = 0.18
    feedback_time = 1.6
    return true

func step(delta: float, accelerator: float, clutch: float, brake: float, on_road: bool = true) -> void:
    if not is_finite(delta) or delta <= 0.0 or not is_finite(accelerator) or not is_finite(clutch) or not is_finite(brake):
        return
    var duration := minf(delta,0.1)
    var count := maxi(1,ceili(duration*480.0))
    var dt := duration/float(count)
    feedback_time = maxf(0,feedback_time-duration)
    for i in range(count):
        _integrate(dt,clampf(accelerator,0,1),clampf(clutch,0,1),clampf(brake,0,1),on_road)

func _integrate(dt: float, accelerator: float, clutch: float, brake: float, on_road: bool) -> void:
    shift_timer = maxf(0,shift_timer-dt)
    throttle = move_toward(throttle,accelerator,dt*5.0)
    clutch_engagement = move_toward(clutch_engagement,1.0-clutch,dt*(10.0 if clutch > 0.5 else 5.0))
    var ratio: float = config.gear_ratios[gear-1]*config.final_drive if gear > 0 else 0.0
    var engine_omega := rpm*TAU/60.0
    var difference := engine_omega-wheel_omega*ratio
    var clutch_health := clampf((config.transmission_health-float(wear["transmision"]))/100.0,0,1)
    var capacity: float = config.clutch_capacity*(0.6+0.4*clutch_health)*clutch_engagement
    var clutch_torque := clampf(difference*5.0,-capacity,capacity) if ratio > 0.0 and shift_timer == 0.0 else 0.0
    if rpm >= config.redline_rpm:
        limiter = true
    elif rpm < config.redline_rpm-220.0:
        limiter = false
    var idle := clampf((config.idle_rpm-rpm)*0.18,0,90)
    var pressure_factor: float = engine.boost_factor(dt,rpm,throttle,gear>0 and clutch_engagement>0.2,config)
    var slip: float = axles.drive_slip(config)
    var wanted_cut := clampf(0.18/maxf(slip,0.18),0.15,1.0) if traction_control and speed_mps>2.0 and accelerator>0.05 else 1.0
    tcs_cut = lerpf(tcs_cut,wanted_cut,1.0-exp(-14.0*dt))
    var combustion := torque_at(rpm)*throttle*pressure_factor*tcs_cut if engine_running and not limiter else 0.0
    engine_torque_nm = combustion
    if engine_running:
        combustion += idle
    var friction := 7.0+engine_omega*0.025
    engine_omega = maxf(0,engine_omega+(combustion-clutch_torque-friction)*dt/config.engine_inertia)
    rpm = engine_omega*60.0/TAU
    if engine_running and rpm < 420.0:
        engine_running = false
        feedback = "MOTOR CALADO · R recupera y vuelve a arrancar"
        feedback_time = 5.0
    wheel_torque_nm = clutch_torque*ratio*config.drivetrain_efficiency
    var tread_before: float = axles.tread_wear_points()
    var tire_force: float = axles.step(dt,speed_mps,wheel_torque_nm,brake,config,config.tire_health-float(wear["neumaticos"]),on_road)
    wheelspin = axles.driven_slip(config)
    var resistance: float = 0.5*1.225*config.drag_area*speed_mps*speed_mps+config.rolling_resistance*config.mass*9.81
    var previous := speed_mps
    speed_mps = maxf(0,speed_mps+(tire_force-resistance)*dt/config.mass)
    if speed_mps<0.15 and brake>0.5:
        speed_mps = 0.0
    acceleration = (speed_mps-previous)/dt
    axles.observe_acceleration(acceleration,dt)
    wheel_power_kw = maxf(0,tire_force*speed_mps/1000.0)
    clutch_loss_kw = absf(clutch_torque*difference)/1000.0
    driveline_loss_kw = absf(clutch_torque*ratio*wheel_omega)*(1.0-config.drivetrain_efficiency)/1000.0
    engine_temperature += (throttle*0.22-(engine_temperature-85.0)*0.015-speed_mps*0.001)*dt
    wear["neumaticos"] += maxf(0,axles.tread_wear_points()-tread_before)
    wear["transmision"] += absf(clutch_torque*difference)*dt*0.00000004
    wear["motor"] += (0.001*throttle+0.04*maxf(0,rpm/config.redline_rpm-1.0))*dt*config.engine_wear_factor
    wear["frenos"] += axles.brake_power*dt*0.000000005
    if rpm > config.redline_rpm*1.10:
        feedback = "SOBRERRÉGIMEN · La reducción fuerza el motor"
        feedback_time = 2.0
    rpm = minf(rpm,config.redline_rpm*1.8)

func shift_hint() -> String:
    if not engine_running:
        return "MOTOR CALADO · R PARA RECUPERAR"
    if feedback_time > 0.0:
        return feedback
    if limiter:
        return "CORTE · Subí una marcha"
    if gear == 0:
        return "NEUTRO · Embrague + subir marcha"
    if gear < config.gear_ratios.size() and rpm >= config.redline_rpm*0.90:
        return "CAMBIAR · Embrague, subir y volver a acelerar"
    return "EN BANDA" if rpm >= config.redline_rpm*0.55 else "BAJAS RPM"
