extends SceneTree

# Reproducible numerical bench, not a factory test or a scene replay. It uses the
# same manual engine/axles and a documented driver with healthy stock hardware.
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Model = preload("res://scripts/manual_powertrain.gd")
const Catalog = preload("res://scripts/car_catalog.gd")
const Driver = preload("res://tests/drag_test_driver.gd")
const Run = preload("res://scripts/drag_run.gd")
const DT := 1.0/60.0
const DURATION := 90.0
func measure(name: String) -> Dictionary:
    var vehicle := {"model":name,"upgrades":[],"health":{"motor":100.0,"transmision":100.0,"neumaticos":100.0,"frenos":100.0,"suspension":100.0,"chasis":100.0}}
    var model=Model.new()
    model.config=Config.from_vehicle(vehicle,true)
    model.reset(false)
    var driver=Driver.new()
    driver.launch_rpm = 2400.0 if model.config.redline_rpm<5000.0 and model.config.turbo_fraction>0.0 else 3400.0
    var timer=Run.new()
    timer.arm(0.0,0.0)
    var distance := 0.0
    var motion_time := -1.0
    var hundred_time := -1.0
    var measured_ticket: Dictionary = {}
    for frame in range(int(DURATION/DT)):
        var clock := frame*DT
        var controls: Dictionary=driver.controls(model,clock,DT)
        var before: float=model.speed_mps
        model.step(DT,controls.throttle,controls.clutch,controls.brake)
        if motion_time<0.0 and before<=0.1 and model.speed_mps>0.1:
            motion_time=clock+DT*(0.1-before)/(model.speed_mps-before)
        if hundred_time<0.0 and before<100.0/3.6 and model.speed_mps>=100.0/3.6:
            hundred_time=clock+DT*(100.0/3.6-before)/(model.speed_mps-before)-motion_time
        distance+=model.speed_mps*DT
        timer.advance(DT,distance,model.speed_mps)
        if measured_ticket.is_empty() and timer.phase=="finished": measured_ticket=timer.report()
    return {"model":name,"physical_scene":false,"launch_rpm_target":driver.launch_rpm,"profile":model.config.metrics(),"ticket":measured_ticket,"zero_to_hundred_s":hundred_time if hundred_time>0 else null,"speed_at_90_s_kmh":model.speed_mps*3.6,"driver_shifts":model.shifts,"temperature_front_c":model.axles.temperatures.x,"temperature_rear_c":model.axles.temperatures.y}
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var reports: Array=[]
    for name in Catalog.FLAGSHIPS+Catalog.CLASSICS+Catalog.NATIONALS+Catalog.REGIONALS:
        var result:=measure(name)
        if result.ticket.is_empty():
            push_error("No completed numerical pass: "+name)
            quit(1)
            return
        reports.append(result)
        print("BENCH ",name," · ET ",result.ticket.et," · 0-100 ",result.zero_to_hundred_s," · speed@90s ",result.speed_at_90_s_kmh)
    var data := {"game_version":root.get_node("GameSession").VERSION,"protocol":{"engine":"Godot 4.6.3","kind":"numerical_manual_powertrain_not_scene_or_factory_test","dt_s":DT,"duration_s":DURATION,"driver_kg":75.0,"initial_tires_c":20.0,"hardware":"healthy_factory_street_tires","tcs":false,"abs":"configured_factory_equipment","road":"flat_dry_asphalt_full_contact","air_density_kg_m3":1.225,"clutch":"manual_driver_0.22s_shift_hold","shift_fraction_redline":0.92,"launch_rpm_target":3400.0,"zero_to_hundred_origin_mps":0.1,"distance_integration":"end_step_speed_like_actor","speed_at_90_s_is_not_verified_terminal_speed":true},"vehicles":reports}
    var args:=OS.get_cmdline_user_args()
    if args.size()!=1:
        push_error("Pass one output JSON path after --")
        quit(1)
        return
    var file:=FileAccess.open(args[0],FileAccess.WRITE)
    if file==null:
        push_error("Could not write benchmark JSON")
        quit(1)
        return
    file.store_string(JSON.stringify(data,"  "))
    file.close()
    print("PASS: %d stock numerical benchmarks written" % reports.size())
    quit(0)
