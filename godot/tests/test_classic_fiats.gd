extends SceneTree

const Economy = preload("res://scripts/economy.gd")
const Catalog = preload("res://scripts/car_catalog.gd")
const Specs = preload("res://scripts/stock_vehicle_specs.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Handling = preload("res://scripts/handling.gd")
const TorqueUtils = preload("res://scripts/engine_torque.gd")
const Powertrain = preload("res://scripts/manual_powertrain.gd")
const Driver = preload("res://tests/drag_test_driver.gd")
const Run = preload("res://scripts/drag_run.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func healthy(car: Dictionary) -> Dictionary:
    var result := car.duplicate(true)
    for component in result.health: result.health[component]=100.0
    return result

# The policy writes actual clutch/throttle/shift inputs to the shared model;
# no target speed, ET or launch position is imposed to fit the reference data.
func measured_pass(config) -> Dictionary:
    var model = Powertrain.new()
    model.config = config
    var driver = Driver.new()
    var timer = Run.new()
    timer.arm(0,0)
    var distance := 0.0
    for i in range(7200):
        var controls: Dictionary = driver.controls(model,timer.clock,1.0/60.0)
        model.step(1.0/60.0,controls.throttle,controls.clutch,controls.brake)
        distance += model.speed_mps/60.0
        timer.advance(1.0/60.0,distance,model.speed_mps)
        if timer.phase in ["finished","invalid"]: break
    return timer.report()

func _initialize() -> void:
    var game = Economy.new()
    game.seed_demo()
    check(game.cars.size()==Economy.MODELS.size() and Catalog.FLAGSHIPS.size()==3 and Catalog.CLASSICS.size()==3,"The three classics extend the lineup while the original three remain flagships")
    check(game.find_car(11).model==Catalog.FLAGSHIPS[0] and game.find_car(13).model==Catalog.FLAGSHIPS[2],"Existing flagship IDs remain stable")
    check(game.find_car(14).model==Catalog.CLASSICS[0] and game.find_car(15).model==Catalog.CLASSICS[1] and game.find_car(16).model==Catalog.CLASSICS[2],"New offers append after all thirteen existing units")
    check(Catalog.has_definition(Catalog.CLASSICS[0]) and not Catalog.flagship(Catalog.CLASSICS[0]) and not Catalog.has_definition("Unknown"),"Supported models and flagship identity have separate meanings")
    var ordered := Catalog.market_order(game.cars)
    var ids := {}
    for car in ordered: ids[car.id]=true
    check(ordered.size()==Economy.MODELS.size() and ids.size()==Economy.MODELS.size() and ordered[0].id==11 and ordered[3].id==14 and ordered[4].id==15 and ordered[5].id==16,"Market order includes every unit exactly once and keeps flagships first")
    game.buy(12)
    game.find_car(12).health.motor=73.25
    game.find_car(12).history.append({"event":"preserved","points":1.25})
    var prior := game.to_dict()
    prior.cars=prior.cars.slice(0,13)
    var restored = Economy.new()
    check(restored.from_dict(prior),"A save containing only the prior thirteen offers remains valid")
    var before: Dictionary = restored.to_dict().duplicate(true)
    restored.ensure_flagship_offers()
    restored.ensure_flagship_offers()
    var after: Dictionary = restored.to_dict()
    check(restored.cars.size()==Economy.MODELS.size() and after.balance==before.balance and after.ledger==before.ledger,"Classic migration is idempotent and never charges or creates credits")
    check(after.cars.slice(0,13)==before.cars,"Migration preserves ownership, health, equipment, history and every old unit")
    var occupied: Dictionary = prior.duplicate(true)
    var custom: Dictionary = occupied.cars[0].duplicate(true)
    custom.id=14
    custom.model="Unidad preservada"
    occupied.cars.append(custom)
    check(restored.from_dict(occupied),"A pre-existing unit in the new ID range is still loadable")
    restored.ensure_flagship_offers()
    restored.ensure_flagship_offers()
    ids.clear()
    for car in restored.cars: ids[car.id]=true
    check(restored.cars.size()==Economy.MODELS.size()+1 and ids.size()==Economy.MODELS.size()+1 and restored.find_car(14).model=="Unidad preservada","Occupied IDs are retained and the new units receive free IDs without duplication")
    var configurations: Array = []
    var passes: Array = []
    for id in [14,15,16]:
        var car := healthy(game.find_car(id))
        var config = Config.from_vehicle(car,true)
        var circuit = Handling.configuration(car)
        check(game.eligible(car) and int(car.price)<Economy.START_BALANCE,"All classics are usable starter cars within the existing economy")
        check(config.gear_ratios.size()==(5 if id==14 else 4),"The classic layouts have independent gearbox configurations")
        check(config.drivetrain==("RWD" if id==15 else "FWD") and circuit.drivetrain==config.drivetrain,"Both driving modes preserve the correct driven axle for each classic")
        check(absf(config.front_weight_bias-(0.40 if id==15 else 0.62))<0.0001,"The rear-engined 133 is not assigned the front-heavy FWD weight distribution")
        var metric: Dictionary = config.metrics()
        check(absf(float(metric.calculated_peak_power_cv)-float({14:82.0,15:34.0,16:55.0}[id]))<0.0001,"Power uses the supplied Fiat report rather than a generic high-output profile")
        check(metric.status=="development_estimate" and not metric.manufacturer_verified and metric.sources[0].page==(1 if id==16 else 2),"Source-backed values remain distinct from estimated mass, gearing and curve interpolation")
        var profile: Dictionary = Specs.for_model(car.model)
        check(profile.estimated_fields.has("gear_ratios") and profile.estimated_fields.has("final_drive"),"Unknown transmission ratios stay explicitly labelled estimates")
        var pass_result := measured_pass(config)
        check(not pass_result.is_empty() and pass_result.distance==402.336 and pass_result.et>0,"Each classic completes a real integrated quarter-mile model pass")
        print("Classic development pass ",car.model," mass=",config.mass," kg · ",pass_result)
        passes.append(pass_result)
        configurations.append(config)
    check(absf(configurations[0].peak_torque*TorqueUtils.curve_factor(3000,configurations[0])-TorqueUtils.kgfm_to_nm(12.0))<0.0001,"The Super Europa curve also respects the supplied torque at 3000 RPM")
    check(configurations[0].metrics().calculated_peak_power_rpm==5600.0,"The Super Europa power maximum occurs at the supplied 5600 RPM")
    check(configurations[0].curb_mass==850.0 and configurations[1].curb_mass==680.0,"The 128 variants retain separate masses rather than sharing one generic profile")
    check(passes[0].et+0.5<passes[2].et and passes[2].et+0.5<passes[1].et,"Independent engine, mass and gearing produce a meaningful performance difference")
    if not failed: print("PASS: %d classic Fiat assertions" % checks)
    quit(1 if failed else 0)
