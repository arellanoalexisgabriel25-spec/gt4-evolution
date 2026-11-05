extends SceneTree

const Config = preload("res://scripts/drag_vehicle_config.gd")
const Specs = preload("res://scripts/stock_vehicle_specs.gd")
const EngineTorque = preload("res://scripts/engine_torque.gd")
const Model = preload("res://scripts/manual_powertrain.gd")
const Economy = preload("res://scripts/economy.gd")
const Driver = preload("res://tests/drag_test_driver.gd")
const Run = preload("res://scripts/drag_run.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func benchmark(config) -> Dictionary:
    var model = Model.new()
    model.config = config
    var driver = Driver.new()
    var run = Run.new()
    run.arm(0,0)
    var distance := 0.0
    var first_motion := -1.0
    var zero_to_hundred := -1.0
    for i in range(7200):
        var controls: Dictionary = driver.controls(model,run.clock,1.0/60.0)
        var before_speed: float = model.speed_mps
        model.step(1.0/60.0,controls.throttle,controls.clutch,controls.brake)
        if first_motion<0 and model.speed_mps>0.1:
            first_motion=run.clock
        if zero_to_hundred<0 and before_speed<100.0/3.6 and model.speed_mps>=100.0/3.6:
            zero_to_hundred=run.clock+(100.0/3.6-before_speed)/(model.speed_mps-before_speed)/60.0-first_motion
        distance += model.speed_mps/60.0
        run.advance(1.0/60.0,distance,model.speed_mps)
        if run.phase in ["finished","invalid"]: break
    return {"et":run.elapsed if run.phase=="finished" else -1.0,"zero_to_hundred":zero_to_hundred,"trap_kmh":run.trap_speed}

func _initialize() -> void:
    check(is_equal_approx(EngineTorque.kgfm_to_nm(11.3),110.815145),"Kilogram-force metre converts to Newton metre without treating kgm as Nm")
    check(EngineTorque.torque_for_cv_at_rpm(68,NAN)==0.0,"Malformed power anchors cannot poison a curve")
    check(is_equal_approx(EngineTorque.power_kw(100.0,6000),62.8318530717959),"Torque times angular speed gives crank power in kW")
    check(is_equal_approx(EngineTorque.kw_to_cv(73.549875),100.0),"Metric CV uses 735.49875 W per CV")
    check(EngineTorque.kw_to_hp(73.549875)<100.0,"Mechanical hp and metric CV are not silently interchanged")
    check(is_equal_approx(Specs.unloaded_tire_radius_m(185,60,14),0.2888),"Tire sidewall and rim dimensions convert millimetres and inches to metres")
    check(Specs.unloaded_tire_radius_m(NAN,60,14)==0.0,"Invalid tire dimensions cannot create a NaN radius")
    var custom = Config.new()
    custom.idle_rpm=2000
    custom.redline_rpm=6000
    custom.torque_rpm=PackedFloat32Array([2000,6000])
    custom.torque_curve=PackedFloat32Array([1.0,0.5])
    var interior: Dictionary = EngineTorque.maximum_power(custom)
    check(is_equal_approx(float(interior.rpm),5000.0),"Power maximum is solved inside a descending torque segment rather than guessed from knots")
    var game = Economy.new()
    game.seed_demo()
    var times: Array = []
    for id in [11,12,13]:
        var car: Dictionary = game.find_car(id).duplicate(true)
        for component in car.health: car.health[component]=100.0
        var standard = Config.from_vehicle(car,true)
        var report: Dictionary = standard.metrics()
        check(is_equal_approx(standard.mass,standard.curb_mass+75.0),"The test mass explicitly includes a 75 kg driver")
        check(report.status=="development_estimate" and not report.manufacturer_verified and (not report.sources.is_empty() if id in [11,12] else report.sources.is_empty()),"Unsupported model estimates are never labelled verified factory specifications")
        check(standard.factory_class and not standard.abs_assist and standard.tire_compound=="street","The baseline protocol excludes gameplay assists and non-stock tire compounds")
        check(is_equal_approx(standard.cg_height,0.48),"An unmodified flagship retains its configured centre of gravity")
        var sampled := 0.0
        for rpm in range(900,int(standard.redline_rpm)+1):
            sampled=maxf(sampled,EngineTorque.power_kw(standard.peak_torque*EngineTorque.curve_factor(rpm,standard),rpm))
        check(absf(sampled-float(report.calculated_peak_power_kw))<0.001,"Dense torque-curve sampling agrees with the reported analytical power maximum")
        if id==12:
            check(absf(standard.peak_torque*EngineTorque.curve_factor(2250,standard)-110.815145)<0.0001,"The identified Uno anchors torque at 11.3 kgf m and 2250 RPM")
            check(absf(float(report.calculated_peak_power_cv)-68.0)<0.0001 and absf(float(report.calculated_peak_power_rpm)-5250.0)<0.01,"The Uno power curve peaks at the supplied 68 CV / 5250 RPM")
            check(report.reference_targets.zero_to_hundred_s==13.2 and report.reference_targets.top_speed_kmh==158.0 and not report.reference_targets.manufacturer_verified,"Reference acceleration and speed remain targets rather than fabricated test results")
            check(not bool(report.sources[0].primary_document_verified),"A supplied description is not silently promoted to an inspected factory document")
        var modified: Dictionary = car.duplicate(true)
        modified.upgrades=["ecu","escape","suspension","brakes","tires"]
        modified.tire_compound="slick"
        var stock_again = Config.from_vehicle(modified,true)
        var upgraded = Config.from_vehicle(modified)
        check(stock_again.peak_torque==standard.peak_torque and stock_again.grip==standard.grip and stock_again.tire_compound=="street","Factory mode ignores saved upgrades without changing the owned unit")
        check(modified.upgrades.size()==5 and modified.tire_compound=="slick" and upgraded.peak_torque>standard.peak_torque,"Legacy tuning data is preserved and still applies in the upgrade-enabled mode")
        var worn: Dictionary = modified.duplicate(true)
        worn.health.motor=30.0
        var worn_config = Config.from_vehicle(worn,true)
        check(worn_config.engine_health==30.0,"Factory hardware selection does not repair persistent mechanical wear for free")
        var run: Dictionary = benchmark(standard)
        check(run.et>0 and run.zero_to_hundred>0 and run.trap_kmh>100,"The stock protocol produces complete measured manual passes and acceleration metrics")
        print("Stock development benchmark ",car.model," mass=",standard.mass," kg · net power=",report.calculated_peak_power_kw," kW / ",report.calculated_peak_power_cv," CV @ ",report.calculated_peak_power_rpm," rpm · ",run)
        times.append(run.et)
    var light = Config.from_vehicle(game.find_car(11),true)
    light.engine_health=100
    light.transmission_health=100
    light.tire_health=100
    light.driver_mass=0
    var loaded = light.duplicate()
    loaded.driver_mass=75
    check(benchmark(loaded).et>benchmark(light).et+0.1,"Adding test-driver mass worsens elapsed time without changing engine data")
    check(loaded.peak_torque==light.peak_torque and loaded.metrics().calculated_peak_power_kw==light.metrics().calculated_peak_power_kw,"Test payload changes inertia rather than inventing engine power")
    var full_load = Model.new()
    full_load.rpm=4000
    full_load.throttle=1.0
    full_load.clutch_engagement=0
    var expected: float = full_load.torque_at(full_load.rpm)
    full_load.step(1.0/480.0,1,1,0)
    check(is_equal_approx(full_load.engine_torque_nm,expected),"Net catalog torque is not reduced by a second full-load engine-friction deduction")
    check(full_load.shaft_power_kw==0.0 and full_load.contact_power_kw==0.0,"An open clutch transmits neither axle power nor road-contact power")
    var delivered := Model.transmitted_torque(100,10,0.8)*10
    var absorbed := -Model.transmitted_torque(-100,10,0.8)*10
    check(is_equal_approx(delivered,8000.0) and is_equal_approx(absorbed,12500.0),"Driveline losses dissipate energy in both propulsion and backdrive directions")
    var drag = Model.new()
    drag.gear=5
    drag.speed_mps=25
    drag.wheel_omega=25/drag.config.wheel_radius
    drag.rpm=1000
    drag.clutch_engagement=1
    drag.engine_running=false
    drag.config.drag_area=0
    drag.config.rolling_resistance=0
    var before: float = drag.kinetic_energy_j()
    for i in range(240): drag.step(1.0/120.0,0,0,0)
    check(drag.kinetic_energy_j()<before and drag.driveline_heat_j>0 and drag.clutch_heat_j>0,"Fuel-cut backdrive loses total kinetic energy while recording coupling losses")
    var slip = Model.new()
    slip.gear=2
    slip.speed_mps=15
    slip.wheel_omega=60
    slip.rpm=6500
    slip.throttle=1
    slip.clutch_engagement=1
    slip.step(1.0/480.0,1,0,0)
    check(slip.shaft_power_kw>slip.contact_power_kw and slip.shaft_power_kw>0 and slip.tire_heat_j>0,"During slip axle power and useful contact power differ, with tire dissipation recorded")
    check(is_equal_approx(slip.wheel_power_kw,slip.shaft_power_kw),"The wheel-power telemetry now reports power at the driven axle")
    var load_model = Model.new()
    var rolling: float = load_model.config.rolling_resistance*load_model.config.mass*9.81
    check(is_equal_approx(load_model.road_load_force(0),rolling),"Rolling resistance depends on actual loaded mass")
    check(is_equal_approx(load_model.road_load_force(40)-rolling,4.0*(load_model.road_load_force(20)-rolling)),"Aerodynamic road load grows with speed squared at the configured air density")
    if not failed: print("PASS: %d stock metric assertions" % checks)
    quit(1 if failed else 0)
