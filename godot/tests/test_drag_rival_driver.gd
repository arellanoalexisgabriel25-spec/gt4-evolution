extends SceneTree

const Driver = preload("res://scripts/drag_rival_driver.gd")
const Model = preload("res://scripts/manual_powertrain.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Run = preload("res://scripts/drag_run.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func pass_with(driver) -> Dictionary:
    var model = Model.new()
    model.config = Config.new()
    var run = Run.new()
    var staged: Dictionary = driver.controls(model,0.0,1.0/60.0)
    check(model.gear==1 and staged.clutch==1.0 and staged.brake==1.0,"The actual driver stages first gear with clutch and brake held")
    run.arm(0,0)
    var distance := 0.0
    var max_input := 0.0
    for i in range(7200):
        var controls: Dictionary = driver.controls(model,run.clock,1.0/60.0)
        for key in ["throttle","clutch","brake"]:
            max_input = maxf(max_input,absf(float(controls[key])))
        model.step(1.0/60.0,controls.throttle,controls.clutch,controls.brake)
        distance += model.speed_mps/60.0
        run.advance(1.0/60.0,distance,model.speed_mps)
        if run.phase in ["finished","invalid"]:
            break
    return {"run":run,"model":model,"max_input":max_input,"distance":distance}

func _initialize() -> void:
    var baseline = Model.new()
    var driver = Driver.new()
    var invalid: Dictionary = driver.controls(baseline,NAN,1.0/60.0)
    check(invalid.throttle==0 and invalid.clutch==1 and invalid.brake==1 and baseline.gear==0,"Invalid time cannot change the gearbox or request propulsion")
    invalid = driver.controls(baseline,0.0,NAN)
    check(invalid.throttle==0 and baseline.gear==0,"Invalid delta is ignored without modifying the actual model")
    var defaults = Driver.new("unknown",{"reaction_delay":NAN,"shift_fraction":4.0,"shift_hold":-1.0})
    check(defaults.profile=="technical" and defaults.reaction_delay==0.16 and defaults.shift_fraction<=0.99 and defaults.shift_hold>=0.18,"Unknown profiles and invalid overrides resolve to bounded driver settings")
    var repeated := pass_with(driver)
    var same := pass_with(Driver.new())
    check(repeated.run.phase=="finished" and repeated.distance>=Run.DISTANCE,"The rival reaches a real integrated quarter-mile distance using the shared powertrain")
    check(repeated.run.report()==same.run.report() and repeated.model.wear==same.model.wear,"The same car and driver reproduce the same physical result and wear")
    check(repeated.model.shifts>2 and repeated.model.missed_shifts==0 and repeated.max_input<=1.0,"The driver completes accepted manual clutch shifts using bounded pedal inputs")
    driver.reset()
    var reset_pass := pass_with(driver)
    check(reset_pass.run.report()==same.run.report(),"Resetting restores the same launch and shifting policy without residual shift state")
    var conservative := pass_with(Driver.new("conservative"))
    var aggressive := pass_with(Driver.new("aggressive"))
    check(conservative.run.phase=="finished" and aggressive.run.phase=="finished","Both distinct styles can complete the measured distance with the same vehicle")
    check(conservative.run.reaction>repeated.run.reaction and repeated.run.reaction>aggressive.run.reaction,"Observed beam reaction reflects each driver's independently configured delay")
    check(absf(conservative.run.elapsed-aggressive.run.elapsed)>0.1,"Launch throttle and shift decisions produce different actual elapsed times")
    check(conservative.model.missed_shifts==0 and aggressive.model.missed_shifts==0,"Style variation does not bypass clutch requirements or spam rejected shifts")
    var stalled = Model.new()
    stalled.engine_running=false
    var held: Dictionary = Driver.new("aggressive").controls(stalled,10,1.0/60.0)
    check(held.throttle==0.0 and held.clutch==1.0 and not stalled.engine_running,"The policy cannot silently revive a stalled engine")
    print("Rival policy evidence: conservative ET %.3f RT %.3f / technical ET %.3f RT %.3f / aggressive ET %.3f RT %.3f" % [conservative.run.elapsed,conservative.run.reaction,repeated.run.elapsed,repeated.run.reaction,aggressive.run.elapsed,aggressive.run.reaction])
    if not failed:
        print("PASS: %d drag rival driver assertions" % checks)
    quit(1 if failed else 0)
