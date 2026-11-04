extends SceneTree

const Model = preload("res://scripts/manual_powertrain.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Driver = preload("res://tests/drag_test_driver.gd")
const Run = preload("res://scripts/drag_run.gd")
const Economy = preload("res://scripts/economy.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func pass_with(config, fraction: float = 0.92) -> Dictionary:
    var model = Model.new()
    model.config = config
    var driver = Driver.new()
    driver.shift_fraction = fraction
    var run = Run.new()
    run.arm(0,0)
    var distance := 0.0
    for i in range(7200):
        var controls: Dictionary = driver.controls(model,run.clock,1.0/60.0)
        model.step(1.0/60.0,controls.throttle,controls.clutch,controls.brake)
        distance += model.speed_mps/60.0
        run.advance(1.0/60.0,distance,model.speed_mps)
        if run.phase in ["finished","invalid"]:
            break
    return {"run":run,"model":model}

func _initialize() -> void:
    var neutral = Model.new()
    for i in range(240):
        neutral.step(1.0/60.0,1,0,0)
    check(neutral.rpm>6500 and neutral.rpm<7100,"Free revving reaches a real fuel-cut limiter without runaway RPM")
    check(neutral.speed_mps==0.0 and neutral.gear==0,"Neutral cannot transmit engine power to the car")
    check(not neutral.shift(1,0) and neutral.gear==0 and neutral.missed_shifts==1,"A change without clutch is rejected rather than silently becoming automatic")
    check(float(neutral.wear["transmision"])>0.0,"A rejected under-clutch change records gearbox wear")
    for i in range(15):
        neutral.step(1.0/60.0,0,1,0)
    check(neutral.shift(1,1),"Depressed clutch permits a deliberate first gear selection")
    for i in range(120):
        neutral.step(1.0/60.0,0.5,1,0)
    check(neutral.speed_mps==0.0,"An open clutch prevents drive even with first gear and throttle")
    check(neutral.wheel_power_kw==0.0 and neutral.clutch_loss_kw==0.0,"The telemetry cannot claim wheel power or clutch loss across a fully open coupling")
    var stall = Model.new()
    stall.shift(1,1)
    for i in range(120):
        stall.step(1.0/60.0,0,0,1)
    check(not stall.engine_running and stall.rpm<500,"Dropping the clutch against the brake at idle can stall the engine: running=%s RPM=%.0f" % [stall.engine_running,stall.rpm])
    stall.reset()
    check(stall.engine_running and stall.gear==0 and stall.speed_mps==0.0,"Recovery restarts in neutral without leaving a progression lock")
    var good := pass_with(Config.new())
    var early := pass_with(Config.new(),0.55)
    var no_shift := pass_with(Config.new(),2.0)
    check(good.run.phase=="finished" and early.run.phase=="finished" and no_shift.run.phase=="finished","Actual manual-model runs can complete the full measured quarter mile")
    check(good.run.elapsed+1.0<early.run.elapsed,"Premature shifts lose power and measurably worsen the real elapsed time")
    check(good.run.elapsed+5.0<no_shift.run.elapsed,"Staying on the first-gear limiter cannot match correctly timed changes")
    check(good.model.shifts>2 and good.model.missed_shifts==0,"The reference run performs multiple accepted clutch changes")
    check(good.run.trap_speed>100 and good.run.trap_speed<170,"Reference speed is produced by torque, gearing, mass, drag and traction")
    var worn = Config.new()
    worn.engine_health = 25
    worn.tire_health = 40
    worn.transmission_health = 40
    var worn_pass := pass_with(worn)
    check(worn_pass.run.phase=="finished" and worn_pass.run.elapsed>good.run.elapsed,"Actual worn engine and tire conditions slow an otherwise identical pass")
    var game = Economy.new()
    game.seed_demo()
    var stock = Config.from_vehicle(game.find_car(1))
    var upgraded: Dictionary = game.find_car(1).duplicate(true)
    upgraded["upgrades"] = ["ecu","escape","tires"]
    var tuned = Config.from_vehicle(upgraded)
    check(tuned.peak_torque>stock.peak_torque and tuned.tire_compound=="sport" and is_equal_approx(tuned.grip,stock.grip),"Garage upgrades add torque and select sport tires without applying their grip bonus twice")
    var civic = Config.from_vehicle(game.find_car(2))
    var skyline = Config.from_vehicle(game.find_car(10))
    check(stock.drivetrain=="RWD" and civic.drivetrain=="FWD" and skyline.drivetrain=="AWD","Garage models retain the correct driven-axle configurations")
    check(civic.mass!=stock.mass and skyline.peak_torque>stock.peak_torque,"Distinct provisional vehicle presets produce physically different inputs")
    var starter_pass := pass_with(stock)
    var awd_pass := pass_with(skyline)
    check(starter_pass.run.phase=="finished" and awd_pass.run.phase=="finished" and awd_pass.run.elapsed+1.0<starter_pass.run.elapsed,"Two actual garage-model configurations produce distinct complete quarter-mile results")
    var cut = Model.new()
    cut.gear = 1
    cut.speed_mps = 33
    cut.wheel_omega = 33/cut.config.wheel_radius
    cut.rpm = 6500
    var safe = Model.new()
    safe.gear = 3
    safe.speed_mps = 33
    safe.wheel_omega = 33/safe.config.wheel_radius
    safe.rpm = 6500
    var peak: float = cut.rpm
    for i in range(90):
        cut.step(1.0/60.0,0,0,0)
        safe.step(1.0/60.0,0,0,0)
        peak = maxf(peak,cut.rpm)
    check(peak>cut.config.redline_rpm*1.1 and float(cut.wear["motor"])>float(safe.wear["motor"])+0.005,"An excessively low gear mechanically overrevs and wears the engine more than the correct gear at the same speed/duration")
    var before: float = neutral.rpm
    neutral.step(0,1,0,0)
    check(neutral.rpm==before,"Zero-duration updates cannot create RPM or wear")
    print("Manual benchmark: in-band %.3f s, early %.3f s, no upshift %.3f s, worn %.3f s" % [good.run.elapsed,early.run.elapsed,no_shift.run.elapsed,worn_pass.run.elapsed])
    if not failed:
        print("PASS: %d drag powertrain assertions" % checks)
    quit(1 if failed else 0)
