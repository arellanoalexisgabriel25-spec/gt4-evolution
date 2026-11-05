extends SceneTree

const Economy = preload("res://scripts/economy.gd")
const Career = preload("res://scripts/career.gd")
const Catalog = preload("res://scripts/car_catalog.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Garage = preload("res://scripts/drag_garage_session.gd")
const Store = preload("res://scripts/save_store.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func ticket(et: float) -> Dictionary:
    return {"distance":402.336,"et":et,"reaction":0.2,"total":et+0.2,"trap_kmh":110.0,"finish_kmh":111.0,"sixty_ft":3.0,"eighth":12.0}

func _initialize() -> void:
    var game = Economy.new()
    game.seed_demo()
    var old := game.to_dict().duplicate(true)
    old.cars = old.cars.slice(0,29)
    var restored = Economy.new()
    check(restored.from_dict(old),"A real version 0.22 inventory remains loadable")
    restored.ensure_flagship_offers()
    restored.ensure_flagship_offers()
    check(restored.cars.size()==36 and restored.cars.slice(0,29)==old.cars,"Seven offers append idempotently without replacing previous vehicles")
    check(restored.balance==old.balance and restored.ledger==old.ledger,"Catalog migration creates no credits or charges")
    var powers := [106.0,60.0,115.0,100.0,110.0,98.0,170.0]
    for index in range(7):
        var car: Dictionary = game.find_car(30+index).duplicate(true)
        for part in car.health: car.health[part]=100.0
        var config = Config.from_vehicle(car,true)
        var metrics: Dictionary = config.metrics()
        check(car.model==Catalog.EXPANDED[index] and ResourceLoader.exists(Catalog.definition(car.model).asset),"Appended stable IDs select the corresponding supplied model")
        check(absf(metrics.calculated_peak_power_cv-powers[index])<0.003,"The actual crankshaft curve reproduces its declared development power")
        check(config.transmission_type==("cvt" if index==6 else "manual"),"The Cross CVT remains distinct from the six manual drivetrains")
        check(not metrics.manufacturer_verified and config.estimated_fields.has("variant_mapping"),"A body scan is never presented as a verified engine/year identification")
        check(config.record_revision.ends_with("__longitudinal_023") and metrics.test_mass_kg==config.curb_mass+75.0,"Each new record series identifies dynamics separately from the mass and factory sheet")
        if index in [0,1,3,5]:
            check(metrics.sources.is_empty() and config.estimated_fields.has("power_cv"),"Old Yaris/Ka/Polo/Onix bodies do not silently inherit unrelated modern PDF variants")
        else:
            check(not metrics.sources.is_empty() and not metrics.sources[0].primary_document_verified,"The supplied compendium remains a secondary reference")
    game.buy(24)
    var career = Career.new()
    var before := ticket(18.5)
    career.stock_drag_records.consider(24,before)
    var garage = Garage.new()
    check(garage.begin(game,career,24),"An owned 0.22 regional vehicle starts the revised garage session")
    check(garage.record_profile==Config.from_vehicle(game.find_car(24),true).record_revision,"The regional config, live garage and UI record lookup share the same revision")
    check(career.stock_drag_records.best_for_profile(24,garage.record_profile).is_empty() and career.stock_drag_records.previous_best(24,garage.record_profile)==before,"The former untagged regional record remains historical instead of contaminating the new series")
    check(career.stock_drag_records.consider_for_profile(24,ticket(19.5),garage.record_profile),"A first valid new-series run is accepted even when slower than its old-physics best")
    var decoded: Dictionary = Store.decode(Store.encode(game,career))
    check(decoded.error=="" and decoded.career.stock_drag_records.previous_best(24,garage.record_profile)==before and decoded.career.stock_drag_records.best_for_profile(24,garage.record_profile).et==19.5,"Both tickets survive actual JSON serialization with their own provenance")
    if not failed: print("PASS: %d expanded fleet and record compatibility assertions" % checks)
    quit(1 if failed else 0)
