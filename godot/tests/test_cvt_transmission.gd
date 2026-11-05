extends SceneTree

const CVT = preload("res://scripts/cvt_transmission.gd")
const Model = preload("res://scripts/manual_powertrain.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Settings = preload("res://scripts/control_settings.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    var config = Config.from_vehicle({"model":"Toyota Corolla Cross","health":{"motor":100,"transmision":100,"frenos":100,"neumaticos":100}},true)
    var cvt = CVT.new()
    cvt.reset(config)
    check(config.transmission_type=="cvt" and config.gear_ratios.size()==1,"The Cross does not inherit a fictitious manual five-speed gearbox")
    for fraction in [0.0,0.1,0.3,0.6,0.85,1.0]:
        var pump_speed := 300.0
        var turbine_speed: float = pump_speed*fraction
        var result: Dictionary = cvt.converter(pump_speed,turbine_speed,1.0,config)
        check(result.turbine_torque>=result.pump_torque and result.turbine_torque*turbine_speed<=result.pump_torque*pump_speed+0.00001,"Converter multiplication respects pump/turbine power at each speed ratio")
        check(absf(result.loss_w-(result.pump_torque*pump_speed-result.turbine_torque*turbine_speed))<0.00001,"Converter loss is actual shaft-power difference")
    check(cvt.converter(300.0,0.0,0.0,config).pump_torque==0.0,"Neutral/disengaged converter transmits no torque")
    for step in range(300): cvt.advance(1.0/60.0,25.0,25.0/config.wheel_radius,1.0,config)
    var lower_speed: float = cvt.ratio
    for step in range(300): cvt.advance(1.0/60.0,45.0,45.0/config.wheel_radius,1.0,config)
    check(cvt.ratio<lower_speed and cvt.ratio>=config.cvt_min_ratio and cvt.ratio<=config.cvt_max_ratio,"The variable ratio continuously decreases as road speed rises under load")
    var model = Model.new()
    model.config = config
    model.reset(false)
    check(model.request_shift(1,0.0) and model.gear==1,"D is selected without a manual clutch pedal")
    for step in range(120): model.step(1.0/60.0,0.5,0.0,1.0)
    check(model.speed_mps==0.0 and model.clutch_engagement<0.25,"Holding the brake keeps the automatic staged while the engine runs")
    var accumulated := 0.0
    for step in range(2400):
        model.step(1.0/60.0,0.85,0.0,0.0)
        accumulated += model.speed_mps/60.0
        if accumulated>402.336: break
    check(accumulated>402.336 and model.speed_mps>25.0 and model.engine_running,"The real torque/axle model completes a CVT-powered quarter-mile without writing a target speed")
    check(model.shifts==1 and model.cvt.converter_heat_j>0.0,"One D selection produces continuous ratios and measured converter heat without fake manual shifts")
    var gear: int = model.gear
    check(not model.shift(-1,0.0) and model.gear==gear,"Drive/neutral selector changes are rejected while moving")
    var settings = Settings.new()
    settings.apply()
    settings.analog_clutch = true
    var axis := InputEventJoypadMotion.new()
    axis.device = 0
    axis.axis = JOY_AXIS_TRIGGER_LEFT
    axis.axis_value = 1.0
    settings.controller.feed(axis)
    check(settings.read_controls(true,true).brake>0.99 and settings.read_controls(true,false).brake==0.0,"A CVT always uses LT as a brake even when the player's manual-car preference enables analog clutch")
    model.limiter = true
    model.feedback_time = 0.0
    check(not model.shift_hint().contains("Subí"),"CVT feedback never asks the player for a nonexistent manual upshift")
    var reverse = Model.new()
    reverse.config = config
    reverse.reset(false)
    check(reverse.request_shift(-1,0.0) and reverse.gear==-1,"The automatic selector also supports reverse from neutral without a clutch pedal")
    for step in range(240): reverse.step(1.0/60.0,0.45,0.0,0.0)
    check(reverse.speed_mps< -1.0 and reverse.wheel_torque_nm<0.0 and reverse.cvt.converter_heat_j>0.0,"CVT reverse sends finite converter torque through a negative fixed ratio and moves backward")
    check(not reverse.request_shift(1,0.0),"A CVT selector rejects moving direction changes")
    print("CVT evidence: measured travel ",accumulated," m; speed ",model.speed_mps*3.6," km/h; heat ",model.cvt.converter_heat_j," J")
    if not failed: print("PASS: %d CVT power-flow assertions" % checks)
    quit(1 if failed else 0)
