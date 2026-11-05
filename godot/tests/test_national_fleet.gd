extends SceneTree

const Economy = preload("res://scripts/economy.gd")
const Catalog = preload("res://scripts/car_catalog.gd")
const Specs = preload("res://scripts/stock_vehicle_specs.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Handling = preload("res://scripts/handling.gd")
const Torque = preload("res://scripts/engine_torque.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func healthy(car: Dictionary) -> Dictionary:
    var copy := car.duplicate(true)
    for part in copy.health: copy.health[part]=100.0
    return copy

func _initialize() -> void:
    var game = Economy.new()
    game.seed_demo()
    var expected := ["Fiat 125","Fiat Duna","Fiat Cronos","Fiat Siena","Fiat Punto","Fiat Regatta","Fiat 500 Sport"]
    var expected_power := [90.0,72.0,130.0,103.0,87.0,100.0,100.0]
    check(game.cars.size()==36 and Catalog.NATIONALS==expected,"Seven additional offers append after the previous sixteen stable units")
    check(Catalog.FLAGSHIPS.size()==3 and Catalog.CLASSICS.size()==3 and Catalog.DATA.size()==26,"Supported models grow without redefining the three flagships or three classics")
    check(game.find_car(1).model=="Mazda MX-5 NA" and game.find_car(1).price==4100 and game.find_car(16).model=="Fiat 128 estándar","The legacy market sequence and asking prices are preserved")
    var ordered := Catalog.market_order(game.cars)
    var ids := {}
    for item in ordered: ids[int(item.id)]=true
    check(ordered.size()==36 and ids.size()==36 and ordered[0].id==11 and ordered[5].id==16 and ordered[6].id==17,"The complete market contains every unit once, keeping flagships and classics first")

    game.buy(12)
    var owned: Dictionary = game.find_car(12)
    owned.health.motor=71.25
    owned.upgrades=["ecu"]
    owned.history.append({"event":"preserved","points":2.5})
    var old := game.to_dict().duplicate(true)
    old.cars=old.cars.slice(0,16)
    var restored = Economy.new()
    check(restored.from_dict(old),"A version 0.18 save with sixteen offers remains valid")
    var before: Dictionary = restored.to_dict().duplicate(true)
    restored.ensure_flagship_offers()
    restored.ensure_flagship_offers()
    var after: Dictionary = restored.to_dict()
    check(restored.cars.size()==36 and after.balance==before.balance and after.ledger==before.ledger,"Offer migration is idempotent and creates neither credits nor charges")
    check(after.cars.slice(0,16)==before.cars,"Migration retains all previous IDs, ownership, health, upgrades, history and listings")
    check(restored.find_car(12).owner=="player" and restored.find_car(12).health.motor==71.25,"The existing owned unit is not replaced by a freshly seeded offer")
    var occupied := old.duplicate(true)
    for id in [17,19,23]:
        var custom: Dictionary = occupied.cars[0].duplicate(true)
        custom.id=id
        custom.model="Unidad preservada %d" % id
        occupied.cars.append(custom)
    check(restored.from_dict(occupied),"Pre-existing custom units in the new ID range remain loadable")
    restored.ensure_flagship_offers()
    restored.ensure_flagship_offers()
    ids.clear()
    for item in restored.cars: ids[int(item.id)]=true
    check(restored.cars.size()==39 and ids.size()==39,"Colliding offer IDs are allocated free IDs without duplicate cars")
    check(restored.find_car(17).model=="Unidad preservada 17" and restored.find_car(19).model=="Unidad preservada 19" and restored.find_car(23).model=="Unidad preservada 23","Migration never overwrites existing colliding IDs")

    for index in range(expected.size()):
        var id := 17+index
        var car: Dictionary = game.find_car(id)
        check(car.model==expected[index] and Catalog.has_definition(car.model) and not Catalog.flagship(car.model),"The new model name, offer ID and supported-model category agree")
        check(ResourceLoader.exists(str(Catalog.definition(car.model).asset)),"Every new offer resolves to its supplied imported model")
        var baseline = Config.from_vehicle(healthy(car),true)
        var circuit = Handling.configuration(healthy(car))
        var correct_drive := "RWD" if id==17 else "FWD"
        check(baseline.drivetrain==correct_drive and circuit.drivetrain==correct_drive,"Both driving modes preserve the new car's driven axle")
        check(baseline.engine_position=="front","These seven added profiles retain a front engine independently of their driven axle")
        var report: Dictionary = baseline.metrics()
        check(absf(float(report.calculated_peak_power_cv)-float(expected_power[index]))<0.0002,"The full-load curve respects the independently specified development power anchor")
        check(not report.manufacturer_verified and report.status=="development_estimate","Incomplete profiles do not become verified manufacturer simulations")
        var description: Dictionary = Specs.for_model(car.model)
        check(description.estimated_fields.has("gear_ratios") and description.estimated_fields.has("final_drive"),"Unknown transmission parameters remain identified as estimates")
        if id==21:
            check(report.sources.is_empty() and report.reference_targets.is_empty(),"The estimated regional Punto never inherits the incompatible PDF's European 2002 power claim")
        else:
            check(not report.sources.is_empty() and report.reference_targets.has("power_cv"),"A supplied power reference retains its provenance beside the estimated parameters")
        var altered := healthy(car)
        altered.upgrades=["ecu","escape","tires"]
        altered.tire_compound="slick"
        altered.health.motor=63.5
        var stock = Config.from_vehicle(altered,true)
        var prepared = Config.from_vehicle(altered,false)
        check(stock.peak_torque==baseline.peak_torque and stock.tire_compound=="street" and stock.engine_health==63.5,"Factory selection excludes upgrades without repairing the owned car")
        check(prepared.peak_torque>stock.peak_torque and altered.upgrades.size()==3 and altered.tire_compound=="slick","The same stored equipment remains usable in prepared practice without being deleted")
        var buyer = Economy.new()
        buyer.seed_demo()
        var balance: int = buyer.balance
        var price: int = buyer.find_car(id).price
        var message: String = buyer.buy(id)
        check(message.begins_with("Compraste") and buyer.balance==balance-price and buyer.find_car(id).owner=="player","Each added offer can be purchased with exactly one quoted debit")
        balance=buyer.balance
        buyer.buy(id)
        check(buyer.balance==balance,"Duplicate purchases cannot charge for the same new car twice")

    var front_engine_rwd = Config.from_vehicle(healthy(game.find_car(17)),true)
    var rear_engine_rwd = Config.from_vehicle(healthy(game.find_car(15)),true)
    check(front_engine_rwd.drivetrain==rear_engine_rwd.drivetrain and front_engine_rwd.engine_position=="front" and rear_engine_rwd.engine_position=="rear","The front-engine 125 and rear-engine 133 do not collapse into a single RWD layout")
    check(front_engine_rwd.front_weight_bias>rear_engine_rwd.front_weight_bias,"The 125 and 133 retain distinct front/rear weight distributions")
    var sport = Config.from_vehicle(healthy(game.find_car(23)),true)
    check(sport.gear_ratios.size()==6 and sport.turbo_fraction==0.0,"The Abarth-shaped supplied model uses the requested naturally aspirated Sport six-speed profile")
    check(absf(sport.peak_torque*Torque.curve_factor(4250,sport)-Torque.kgfm_to_nm(13.1))<0.0002 and absf(float(sport.metrics().calculated_peak_power_rpm)-6000.0)<0.001,"The Sport anchors both torque at 4250 RPM and its 100 CV power peak at 6000 RPM")
    check(sport.abs_assist and Config.from_vehicle(healthy(game.find_car(19)),true).abs_assist and not front_engine_rwd.abs_assist,"Factory ABS follows configured equipment instead of being assigned to all added vehicles")
    for model in Catalog.DATA:
        var car: Dictionary = {}
        for item in game.cars:
            if item.model==model: car=item
        var config = Config.from_vehicle(healthy(car),true)
        var report: Dictionary = config.metrics()
        check(config.mass>75.0 and is_finite(float(report.calculated_peak_power_kw)) and report.calculated_peak_power_kw>0.0,"All thirteen supported stock profiles have finite positive loaded mass and power")
        var increasing: bool = config.torque_rpm.size()==config.torque_curve.size()
        for index in range(config.torque_rpm.size()-1):
            increasing = increasing and config.torque_rpm[index+1]>config.torque_rpm[index]
        check(increasing,"All thirteen torque curves use strictly increasing RPM knots")
    if not failed: print("PASS: %d national fleet assertions" % checks)
    quit(1 if failed else 0)
