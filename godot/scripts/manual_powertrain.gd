extends RefCounted

# Longitudinal model with separate engine/wheel inertia and finite clutch torque.
# Scene collision and beam timing use measured actor movement, not this model's
# integration. Substeps keep clutch and tire coupling stable at normal frame rates.
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Axles = preload("res://scripts/axle_traction.gd")
const EngineTorque = preload("res://scripts/engine_torque.gd")
const EnvironmentData = preload("res://scripts/driving_environment.gd")
const BrakeThermal = preload("res://scripts/brake_thermal.gd")
const Gearbox = preload("res://scripts/manual_gearbox.gd")
const Clutch = preload("res://scripts/manual_clutch.gd")
const CVT = preload("res://scripts/cvt_transmission.gd")
# A brief lever-input window tolerates pedal/button delivery order. It never
# opens the clutch, releases the accelerator or executes an unclutched change.
const SHIFT_INPUT_WINDOW := 0.10
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
var pending_shift_direction := 0
var pending_shift_time := 0.0
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
var engine_power_kw := 0.0
var shaft_power_kw := 0.0
var contact_power_kw := 0.0
var road_load_n := 0.0
var contact_loads := Vector2.ONE
var surface_grip := Vector2.ONE
var rolling_scale := 1.0
var engine_work_j := 0.0
var clutch_heat_j := 0.0
var driveline_heat_j := 0.0
var tire_heat_j := 0.0
var brake_heat_j := 0.0
var road_work_j := 0.0
var traction_control := false
var tcs_cut := 1.0
var brakes = BrakeThermal.new()
var normal_g := EnvironmentData.STANDARD_GRAVITY
var grade_acceleration := 0.0
var wind_along := 0.0
var rolling_axles := Vector2.ONE
var aerodynamic_force_n := 0.0
var rolling_force_n := 0.0
var grade_force_n := 0.0
var gravity_work_j := 0.0
var cvt = CVT.new()

var gearbox = Gearbox.new()
var clutch_pack = Clutch.new()
var shift_mode := "manual"
var auto_rev_match := false
var effective_clutch_pedal := 1.0
var shift_quality := "none"
var shift_event_serial := 0
var pending_engagement := false
var engagement_is_shift := false
var assisted_shift_hold := 0.0
var overrev_dose := 0.0
var wheel_surfaces: Array = []
var clutch_temperature: float:
    get: return clutch_pack.temperature
var clutch_health: float:
    get: return clampf(config.transmission_health-float(wear.transmision),0.0,100.0)

func target_rpm(gear_selection: int = gear) -> float:
    return wheel_omega*Gearbox.ratio(gear_selection,config)*60.0/TAU

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
    pending_shift_direction = 0
    pending_shift_time = 0.0
    engine_running = config.engine_health-float(wear.motor)>=20.0
    gearbox.phase = "neutral"
    gearbox.remaining = 0.0
    gearbox.elapsed = 0.0
    gearbox.input_omega = 0.0
    pending_engagement = false
    assisted_shift_hold = 0.0
    limiter = false
    acceleration = 0.0
    wheelspin = 0.0
    wheel_power_kw = 0.0
    clutch_loss_kw = 0.0
    engine_torque_nm = 0.0
    wheel_torque_nm = 0.0
    driveline_loss_kw = 0.0
    engine_power_kw = 0.0
    shaft_power_kw = 0.0
    contact_power_kw = 0.0
    road_load_n = 0.0
    contact_loads = Vector2.ONE
    surface_grip = Vector2.ONE
    rolling_scale = 1.0
    feedback = "Punto muerto · Embrague + subir marcha para engranar primera"
    if not keep_heat:
        engine_temperature = 88.0
        brakes.reset(config.brake_ambient_c)
        clutch_pack.temperature = 20.0
    cvt.reset(config,keep_heat)

func torque_at(engine_rpm: float) -> float:
    var factor := EngineTorque.curve_factor(engine_rpm,config)
    var health := clampf((config.engine_health-float(wear["motor"]))/100.0,0,1)
    var thermal := clampf(1.0-maxf(0,engine_temperature-105.0)*0.015,0.55,1.0)
    return config.peak_torque*factor*(0.65+0.35*health)*thermal

static func transmitted_torque(clutch_torque: float, ratio: float, efficiency: float, input_speed: float = 1.0) -> float:
    var eta := clampf(efficiency,0.05,1.0)
    # Positive torque flows engine -> axle. Negative torque flows axle -> engine;
    # the wheels must lose MORE power than the crankshaft receives, not less.
    return clutch_torque*ratio*(eta if clutch_torque*input_speed>=0.0 else 1.0/eta)

func road_load_force(speed: float) -> float:
    return EnvironmentData.aerodynamic_force(speed,wind_along,config.air_density,config.drag_area)+config.rolling_resistance*config.mass*normal_g*rolling_scale

func kinetic_energy_j() -> float:
    var engine_omega := rpm*TAU/60.0
    return 0.5*config.mass*speed_mps*speed_mps+0.5*config.engine_inertia*engine_omega*engine_omega+0.5*config.wheel_inertia*axles.omega.length_squared()

func shift(direction: int, clutch: float) -> bool:
    if not is_finite(clutch) or clutch<0.0 or clutch>1.0:
        return false
    if direction not in [-1,1] or shift_timer > 0.0:
        return false
    if config.transmission_type=="cvt":
        # E/Q select R/N/D at rest; the reverse idler uses a fixed ratio,
        # while only D is controlled by the variator.
        var selection := clampi(gear+direction,-1,1)
        if absf(speed_mps)>0.5 or selection==gear: return false
        gear = selection
        shifts += 1
        shift_timer = 0.18
        feedback = "D · AUTOMÁTICA CVT" if gear==1 else ("R · REVERSA CVT" if gear<0 else "PUNTO MUERTO")
        feedback_time = 1.6
        return true
    var next := clampi(gear+direction,-1,config.gear_ratios.size())
    if next == gear:
        return false
    if (next<0 and speed_mps>0.5) or (next>0 and speed_mps< -0.5) or (next<0 and gear>=0 and absf(speed_mps)>0.5):
        feedback = "REVERSA RECHAZADA · Detené el auto"
        feedback_time = 2.0
        shift_quality = "rejected"
        shift_event_serial += 1
        missed_shifts += 1
        wear.transmision += 0.08
        return false
    pending_shift_direction = 0
    pending_shift_time = 0.0
    var matched: bool = gear>0 and next>0 and absf(rpm-target_rpm(next))<120.0 and throttle<0.08
    if clutch < config.clutch_release_pedal and not matched:
        shift_quality = "rejected"
        shift_event_serial += 1
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
    if next<0: feedback = "REVERSA · Soltá el embrague con control"
    engagement_is_shift = gear>0 and next>0
    shift_timer = gearbox.select(gear,next,wheel_omega,config)
    gear = next
    pending_engagement = next!=0
    shift_quality = "acceptable" if clutch>=config.clutch_release_pedal else "perfect"
    shift_event_serial += 1
    shifts += 1
    feedback_time = 1.6
    return true

# Input-facing API. Simultaneously pressed clutch/shift buttons can arrive in
# either order within a frame. Queue only this short pedal transition; a driver
# who never depresses the clutch still incurs the normal missed-shift damage.
# Scripted drivers retain shift(), whose strict immediate contract is unchanged.
func request_shift(direction: int, clutch: float) -> bool:
    if not is_finite(clutch) or clutch<0.0 or clutch>1.0 or direction not in [-1,1]:
        return false
    if config.transmission_type=="cvt": return shift(direction,clutch)
    if shift_timer>0.0 or pending_shift_direction!=0:
        feedback = "SINCRONIZANDO · Esperá el enganche antes de otro cambio"
        feedback_time = 1.0
        return false
    if clampi(gear+direction,-1,config.gear_ratios.size())==gear:
        return false
    if shift_mode in ["auto_clutch","semi_auto"]:
        assisted_shift_hold = config.shift_time+0.1
        return shift(direction,1.0)
    if clutch>=config.clutch_release_pedal:
        return shift(direction,clutch)
    pending_shift_direction = direction
    pending_shift_time = SHIFT_INPUT_WINDOW
    feedback = "CAMBIO SOLICITADO · Pisá el embrague"
    feedback_time = SHIFT_INPUT_WINDOW
    return true

func _advance_shift_request(delta: float, clutch: float) -> void:
    if pending_shift_direction==0:
        return
    pending_shift_time = maxf(0.0,pending_shift_time-delta)
    if clutch>=config.clutch_release_pedal or pending_shift_time<=0.0:
        var direction := pending_shift_direction
        pending_shift_direction = 0
        pending_shift_time = 0.0
        shift(direction,clutch)

func step(delta: float, accelerator: float, clutch: float, brake: float, on_road: bool = true, contact_state: Dictionary = {}, handbrake: float = 0.0) -> void:
    if not is_finite(delta) or delta <= 0.0 or not is_finite(accelerator) or not is_finite(clutch) or not is_finite(brake) or not is_finite(handbrake):
        return
    var support = contact_state.get("contact",Vector2.ONE)
    var friction = contact_state.get("grip",Vector2.ONE)
    var rolling = contact_state.get("rolling",1.0)
    var sampled_normal = contact_state.get("normal_g",config.gravity_mps2)
    var sampled_grade = contact_state.get("grade_acceleration",0.0)
    var sampled_wind = contact_state.get("wind_along",0.0)
    var axle_rolling = contact_state.get("rolling_axles",Vector2.ONE*float(rolling) if typeof(rolling) in [TYPE_INT,TYPE_FLOAT] else Vector2.ZERO)
    if typeof(support)!=TYPE_VECTOR2 or not support.is_finite() or typeof(friction)!=TYPE_VECTOR2 or not friction.is_finite():
        return
    if typeof(rolling) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(rolling)) or float(rolling)<0.0:
        return
    for value in [sampled_normal,sampled_grade,sampled_wind]:
        if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)): return
    if float(sampled_normal)<0.0 or float(sampled_normal)>config.gravity_mps2+0.001 or absf(float(sampled_grade))>config.gravity_mps2+0.001 or typeof(axle_rolling)!=TYPE_VECTOR2 or not axle_rolling.is_finite(): return
    normal_g = float(sampled_normal)
    grade_acceleration = float(sampled_grade)
    wind_along = float(sampled_wind)
    wheel_surfaces = contact_state.get("wheel_surfaces",[])
    rolling_axles = axle_rolling.clamp(Vector2.ZERO,Vector2.ONE*8.0)
    contact_loads = support.clamp(Vector2.ZERO,Vector2.ONE)
    surface_grip = friction.clamp(Vector2.ZERO,Vector2.ONE*2.0)
    # A tire must be supported to create rolling resistance. Air drag remains.
    rolling_scale = minf(float(rolling),8.0) if contact_loads.length_squared()>0.0 else 0.0
    var duration := minf(delta,0.1)
    var count := maxi(1,ceili(duration*480.0))
    var dt := duration/float(count)
    feedback_time = maxf(0,feedback_time-duration)
    _advance_shift_request(duration,clampf(clutch,0,1))
    for i in range(count):
        _integrate(dt,clampf(accelerator,0,1),clampf(clutch,0,1),clampf(brake,0,1),on_road,clampf(handbrake,0,1))

func _integrate(dt: float, accelerator: float, clutch: float, brake: float, on_road: bool, handbrake: float) -> void:
    gearbox.advance(dt,gear,wheel_omega,rpm*TAU/60.0,clutch_engagement,config)
    shift_timer = maxf(0,shift_timer-dt)
    if gearbox.phase=="shifting": shift_timer = maxf(shift_timer,gearbox.remaining)
    if gearbox.phase=="rejected":
        # A timed-out synchronizer never snaps either shaft into agreement.
        # The lever falls to neutral; retrying requires a new driver command.
        gear = 0
        shift_timer = 0.0
        pending_shift_direction = 0
        pending_shift_time = 0.0
        pending_engagement = false
        engagement_is_shift = false
        assisted_shift_hold = 0.0
        gearbox.phase = "neutral"
        shift_quality = "rejected"
        shift_event_serial += 1
        missed_shifts += 1
        wear.transmision += 0.08
        feedback = "SINCRONIZACIÓN RECHAZADA · Quedó en punto muerto"
        feedback_time = 2.0
    if shift_mode=="semi_auto" and shift_timer>0.0: accelerator = 0.0
    throttle = move_toward(throttle,accelerator,dt*5.0)
    var automatic: bool = config.transmission_type=="cvt"
    if automatic:
        clutch = 1.0 if gear==0 or (brake>0.5 and absf(speed_mps)<1.0) else 0.0
    elif shift_mode in ["auto_clutch","semi_auto"]:
        assisted_shift_hold = maxf(0.0,assisted_shift_hold-dt)
        var launch_open: bool = absf(speed_mps)<0.15 and (accelerator<0.1 or brake>0.5)
        clutch = maxf(clutch,1.0 if shift_timer>0.0 or assisted_shift_hold>0.0 or gear==0 or launch_open else 0.0)
    effective_clutch_pedal = clutch
    var pressure: float = Clutch.pressure(clutch,config)
    var travel_time: float = config.clutch_disengage_time if pressure<clutch_engagement else config.clutch_engage_time
    clutch_engagement = move_toward(clutch_engagement,pressure,dt/maxf(travel_time,0.01))
    if pending_engagement and clutch_engagement>0.05 and shift_timer<=0.0:
        var mismatch := absf(rpm-target_rpm())
        shift_quality = ("perfect" if mismatch<180.0 else ("acceptable" if mismatch<900.0 else "poor")) if engagement_is_shift else "acceptable"
        shift_event_serial += 1
        feedback = {"perfect":"CAMBIO PERFECTO · RPM sincronizadas","acceptable":"CAMBIO ACEPTABLE · Acople progresivo","poor":"ACOPLE BRUSCO · Diferencia de RPM"}[shift_quality]
        feedback_time = 1.6
        pending_engagement = false
    var ratio: float = Gearbox.ratio(gear,config)
    if automatic and gear>0:
        ratio = cvt.advance(dt,speed_mps,wheel_omega,throttle,config)*config.final_drive
    var engine_omega := rpm*TAU/60.0
    var difference := engine_omega-wheel_omega*ratio
    var clutch_health := clampf((config.transmission_health-float(wear["transmision"]))/100.0,0,1)
    # Estimated friction condition curve: a fully worn manual plate cannot
    # transmit torque. The CVT converter/lock-up retains its separate model.
    var condition_factor: float = (0.6+0.4*clutch_health) if automatic else pow(clutch_health,0.7)
    var capacity: float = config.clutch_capacity*condition_factor*clutch_engagement*clutch_pack.capacity_factor(config)
    var clutch_torque := clampf(difference*5.0,-capacity,capacity) if ratio != 0.0 and shift_timer == 0.0 else 0.0
    var split := Axles.front_share(config)
    var inverse_wheel_inertia: float = (split*split+(1.0-split)*(1.0-split))/config.wheel_inertia
    var eta: float = config.drivetrain_efficiency if difference*wheel_omega*ratio>=0.0 else 1.0/config.drivetrain_efficiency
    var coupling_limit: float = absf(difference)/maxf(dt*(1.0/config.engine_inertia+ratio*ratio*inverse_wheel_inertia*eta),0.00000001)
    clutch_torque = clampf(clutch_torque,-coupling_limit,coupling_limit)
    var fluid: bool = automatic and gear!=0 and shift_timer==0.0 and (difference>0.0 and (wheel_omega*ratio/maxf(engine_omega,0.001)<0.88 or absf(speed_mps)<10.0))
    cvt.locked = automatic and gear!=0 and not fluid and clutch_engagement>0.9
    var converter := {"pump_torque":0.0,"turbine_torque":0.0,"loss_w":0.0}
    if fluid:
        converter = cvt.converter(engine_omega,wheel_omega*ratio,clutch_engagement,config)
        clutch_torque = minf(float(converter.pump_torque),engine_omega*config.engine_inertia/dt)
    if rpm >= config.redline_rpm:
        limiter = true
    elif rpm < config.redline_rpm-220.0:
        limiter = false
    if auto_rev_match and gear>0 and clutch>0.5 and pending_engagement:
        # Assistance adds real throttle only. It never assigns crankshaft RPM.
        var blip: float = clampf((target_rpm()-rpm)/1200.0,0.0,1.0)
        throttle = maxf(throttle,blip)
    var idle := clampf((config.idle_rpm-rpm)*0.18,0,90)
    var pressure_factor: float = engine.boost_factor(dt,rpm,throttle,gear!=0 and clutch_engagement>0.2,config)
    var slip: float = axles.drive_slip(config)
    var wanted_cut := clampf(0.18/maxf(slip,0.18),0.15,1.0) if traction_control and speed_mps>2.0 and accelerator>0.05 else 1.0
    tcs_cut = lerpf(tcs_cut,wanted_cut,1.0-exp(-14.0*dt))
    var friction := 7.0+engine_omega*0.025
    var rated_net := torque_at(rpm)*throttle*pressure_factor*tcs_cut if engine_running and not limiter else 0.0
    # Catalog/full-load torque is already net at the crankshaft. Subtracting
    # internal drag again at WOT understated all stock engines. Retain drag on
    # lift/fuel cut for genuine engine braking; idle control supplies only idle.
    var pumping_loss := friction*(1.0-throttle) if engine_running and not limiter else friction
    var engine_net := rated_net-pumping_loss+(idle if engine_running else 0.0)
    engine_torque_nm = engine_net
    engine_power_kw = EngineTorque.power_kw(engine_net,rpm)
    engine_work_j += engine_net*engine_omega*dt
    engine_omega = maxf(0,engine_omega+(engine_net-clutch_torque)*dt/config.engine_inertia)
    rpm = engine_omega*60.0/TAU
    if engine_running and rpm < 420.0:
        engine_running = false
        feedback = "MOTOR CALADO · R recupera y vuelve a arrancar"
        feedback_time = 5.0
    wheel_torque_nm = transmitted_torque(clutch_torque,ratio,config.drivetrain_efficiency,wheel_omega*ratio)
    if fluid:
        wheel_torque_nm = float(converter.turbine_torque)*ratio*config.drivetrain_efficiency
    shaft_power_kw = wheel_torque_nm*wheel_omega/1000.0
    wheel_power_kw = maxf(0,shaft_power_kw)
    var turbine_torque: float = float(converter.turbine_torque) if fluid else clutch_torque
    driveline_loss_kw = maxf(0,(turbine_torque*ratio-wheel_torque_nm)*wheel_omega/1000.0)
    var tread_before: float = axles.tread_wear_points()
    var tire_force: float = axles.step(dt,speed_mps,wheel_torque_nm,brake,config,config.tire_health-float(wear["neumaticos"]),on_road,contact_loads,surface_grip,handbrake,normal_g,grade_acceleration,brakes.factors(config),wheel_surfaces)
    wheelspin = axles.driven_slip(config)
    var previous := speed_mps
    aerodynamic_force_n = EnvironmentData.aerodynamic_force(speed_mps,wind_along,config.air_density,config.drag_area)
    rolling_force_n = config.rolling_resistance*axles.normal_loads.dot(rolling_axles)
    grade_force_n = config.mass*grade_acceleration
    var external: float = tire_force+grade_force_n-aerodynamic_force_n
    var unresisted: float = speed_mps+external*dt/config.mass
    speed_mps = move_toward(unresisted,0.0,rolling_force_n*dt/config.mass)
    # A stopped braked axle can hold only within its actual remaining brake
    # torque and tire friction cone. No fixed-speed snapping or infinite grip.
    if absf(speed_mps)*config.mass/dt<=axles.holding_force(wheel_torque_nm,config):
        speed_mps = 0.0
    road_load_n = aerodynamic_force_n+rolling_force_n*signf(unresisted)
    var mean_speed := (previous+speed_mps)*0.5
    road_work_j += aerodynamic_force_n*mean_speed*dt+rolling_force_n*absf(mean_speed)*dt
    gravity_work_j += grade_force_n*mean_speed*dt
    acceleration = (speed_mps-previous)/dt
    axles.observe_acceleration(acceleration,dt)
    contact_power_kw = tire_force*speed_mps/1000.0
    clutch_loss_kw = absf(clutch_torque*difference)/1000.0
    if fluid:
        clutch_loss_kw = float(converter.loss_w)/1000.0
        cvt.converter_heat_j += float(converter.loss_w)*dt
    clutch_heat_j += clutch_loss_kw*1000.0*dt
    driveline_heat_j += driveline_loss_kw*1000.0*dt
    tire_heat_j += axles.slip_power*dt
    brake_heat_j += axles.brake_power*dt
    brakes.step(dt,axles.brake_energy,speed_mps,config)
    engine_temperature += (throttle*0.22-(engine_temperature-85.0)*0.015-speed_mps*0.001)*dt
    wear["neumaticos"] += maxf(0,axles.tread_wear_points()-tread_before)
    wear["transmision"] += clutch_pack.step(dt,0.0 if automatic else clutch_loss_kw*1000.0*dt,speed_mps,config)
    wear["motor"] += ((0.001*throttle if engine_running else 0.0)+config.overrev_wear_per_second*pow(maxf(0,rpm/config.redline_rpm-1.0),2.0))*dt*config.engine_wear_factor
    wear["frenos"] += axles.brake_power*dt*0.000000005
    if rpm > config.redline_rpm*1.10:
        feedback = "SOBRERRÉGIMEN · La reducción fuerza el motor"
        feedback_time = 2.0
    overrev_dose += pow(maxf(0.0,rpm/config.redline_rpm-1.35),2.0)*dt
    if overrev_dose>0.04 and engine_running:
        wear.motor += maxf(0.0,config.engine_health-float(wear.motor)-15.0)
        engine_running = false
        feedback = "FALLA MECÁNICA · Sobrerégimen; requiere taller"
        feedback_time = 6.0

func shift_hint() -> String:
    if not engine_running:
        if config.engine_health-float(wear.motor)<20.0: return "FALLA MECÁNICA · REQUIERE TALLER"
        return "MOTOR CALADO · R PARA RECUPERAR"
    if feedback_time > 0.0:
        return feedback
    if config.transmission_type=="cvt":
        return "N · SUBIR: D / BAJAR: R" if gear==0 else ("R · REVERSA CVT" if gear<0 else ("CVT · CORTE DE INYECCIÓN" if limiter else ("CVT · ACOPLE DIRECTO" if cvt.locked else "CVT · CONVERTIDOR")))
    if gear<0:
        return "REVERSA · CONTROLÁ EL ACELERADOR"
    if limiter:
        return "CORTE · Subí una marcha"
    if gear == 0:
        return "NEUTRO · Embrague + subir marcha"
    if gear < config.gear_ratios.size() and rpm >= config.redline_rpm*0.90:
        return "CAMBIAR · Embrague y subir marcha"
    return "EN BANDA" if rpm >= config.redline_rpm*0.55 else "BAJAS RPM"
