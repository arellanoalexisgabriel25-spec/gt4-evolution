extends SceneTree

const Economy = preload("res://scripts/economy.gd")
const Catalog = preload("res://scripts/car_catalog.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Torque = preload("res://scripts/engine_torque.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    var game = Economy.new()
    game.seed_demo()
    check(game.cars.size()==36 and Catalog.REGIONALS.size()==6,"Six regional offers extend the prior twenty-three stable units")
    game.buy(12)
    game.find_car(12).history.append({"event":"previous career"})
    var old: Dictionary = game.to_dict().duplicate(true)
    old.cars = old.cars.slice(0,23)
    var restored = Economy.new()
    check(restored.from_dict(old),"A real pre-0.22 economy snapshot remains loadable")
    var previous: Dictionary = restored.to_dict().duplicate(true)
    restored.ensure_flagship_offers()
    restored.ensure_flagship_offers()
    check(restored.cars.size()==36 and restored.to_dict().cars.slice(0,23)==previous.cars,"Idempotent migration preserves every previous ID, owner, history, condition and listing")
    check(restored.balance==previous.balance and restored.ledger==previous.ledger,"Adding market offers neither spends nor generates credits")
    var models := {}
    var ids := {}
    for car in Catalog.market_order(restored.cars):
        ids[car.id] = true
        models[car.model] = true
    check(ids.size()==36 and models.size()==36,"All legacy and imported cars remain reachable exactly once in the market")
    var powers := [92.0,140.0,163.0,99.0,110.0,72.0]
    for index in range(6):
        var vehicle: Dictionary = game.find_car(24+index).duplicate(true)
        for part in vehicle.health: vehicle.health[part]=100.0
        var config = Config.from_vehicle(vehicle,true)
        var metrics: Dictionary = config.metrics()
        check(vehicle.model==Catalog.REGIONALS[index] and ResourceLoader.exists(Catalog.definition(vehicle.model).asset),"Stable appended IDs select the actual supplied mesh")
        check(absf(metrics.calculated_peak_power_cv-powers[index])<0.002,"The physical torque curve reproduces its declared provisional power without an intermediate power spike")
        check(config.mass==config.curb_mass+75.0 and config.gear_ratios.size()==(6 if index==1 else 5),"Kerb mass, standard test driver and manual gearbox remain separate")
        check(config.drivetrain==("RWD" if index in [1,2] else "FWD"),"Pickups and passenger vehicles use their configured driven axle")
        check(not config.record_revision.is_empty() and config.record_revision.begins_with(Catalog.definition(vehicle.model).key),"The new baseline has its own record revision for later factory calibration")
        check(not metrics.manufacturer_verified and config.estimated_fields.has("variant_mapping") and config.estimated_fields.has("gear_ratios"),"The provisional body/engine association and unknown ratios are explicitly disclosed")
        if index==5:
            check(metrics.sources.is_empty() and metrics.reference_targets.is_empty(),"The Palio hatch does not inherit the PDF's incompatible Weekend specification")
        else:
            check(metrics.sources[0].document=="Informe Técnico Automotriz Completo.pdf" and not metrics.sources[0].primary_document_verified,"Referenced figures identify the user's secondary compilation without claiming a verified factory sheet")
        if index in [1,2]:
            check(config.cg_height>0.7 and config.wheel_inertia>6.0 and config.engine_inertia>0.35,"The pickup's geometry and rotational masses differ from a small hatch")
            var turbo = Torque.new()
            var initial: float = turbo.boost_factor(0.01,1750.0,1.0,true,config)
            for step in range(600): turbo.boost_factor(0.01,1750.0,1.0,true,config)
            var loaded: float = turbo.boost_factor(0.01,1750.0,1.0,true,config)
            check(loaded>0.999 and initial<0.7,"A loaded diesel builds full boost around its low-speed torque peak rather than using the petrol turbo's spool range")
        var modified := vehicle.duplicate(true)
        modified.upgrades = ["ecu","escape","suspension","brakes"]
        var baseline = Config.from_vehicle(modified,true)
        check(baseline.peak_torque==config.peak_torque and baseline.cg_height==config.cg_height and baseline.tire_compound=="street","Factory duels exclude prepared-engine, lowered-suspension and tire bonuses")
    if not failed: print("PASS: %d regional fleet assertions" % checks)
    quit(1 if failed else 0)
