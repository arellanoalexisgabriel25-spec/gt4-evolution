extends SceneTree

const Economy = preload("res://scripts/economy.gd")
const Career = preload("res://scripts/career.gd")
const Store = preload("res://scripts/save_store.gd")
const Tire = preload("res://scripts/tire_model.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Model = preload("res://scripts/manual_powertrain.gd")
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
    var before: Dictionary = game.to_dict()
    check(game.tire_quote(11,"slick")==-1 and not game.replace_tires(11,"slick").contains("instalado"),"The workshop cannot modify a seller's car")
    check(game.to_dict()==before,"Rejected tire work cannot change money or inventory")
    game.buy(11)
    var car: Dictionary = game.find_car(11)
    var balance: int = game.balance
    var quote: int = game.tire_quote(11,"sport")
    check(game.replace_tires(11,"sport").contains("ARS") and game.balance==balance-quote,"A compound replacement charges its exact ARS quote once")
    check(car.health.neumaticos==100.0 and Config.from_vehicle(car).tire_compound=="sport","New tires restore tread health and reach the real powertrain")
    var installed: Dictionary = game.to_dict()
    check(game.tire_quote(11,"sport")==0 and not game.replace_tires(11,"sport").contains("instalado") and game.to_dict()==installed,"Duplicate confirmation cannot buy the same fresh set twice")
    check(game.tire_quote(11,"unknown")==-1 and not game.replace_tires(11,"unknown").contains("instalado") and game.to_dict()==installed,"Invalid compounds are rejected without partial mutation")
    car.health.neumaticos = 50.0
    game.balance = 0
    before = game.to_dict()
    check(game.replace_tires(11,"slick").contains("Saldo insuficiente") and game.to_dict()==before,"Insufficient funds cannot install free tires or reset wear")
    game.balance = balance
    check(game.replace_tires(11,"slick").contains("instalado") and car.health.neumaticos==100.0,"Slicks are an explicit paid alternative in the same workshop")
    var decoded: Dictionary = Store.decode(Store.encode(game,Career.new()))
    check(decoded.error.is_empty() and decoded.game.find_car(11).tire_compound=="slick","Compound selection survives actual JSON encoding and loading")
    before = game.to_dict()
    var corrupt: Dictionary = before.duplicate(true)
    corrupt.cars[10].tire_compound = "unknown"
    check(not game.from_dict(corrupt) and game.to_dict()==before,"Malformed compound saves are rejected atomically")
    var street = Tire.new("street")
    var slick = Tire.new("slick")
    check(street.thermal_grip()>slick.thermal_grip(),"Street tires beat cold slicks at ambient temperature")
    street.temperature = 45.0
    slick.temperature = 75.0
    check(slick.thermal_grip()>street.thermal_grip()*1.2,"Prepared slicks provide a measurable warm-grip advantage")
    var hot = Tire.new()
    var rolling = Tire.new()
    for i in range(360):
        hot.step_contact(1.0/120.0,40000,4500,3500,5)
        rolling.step_contact(1.0/120.0,0,4500,0,5)
    check(hot.temperature>rolling.temperature+25 and hot.wear>rolling.wear*3,"Real dissipated slip power heats and wears contact patches")
    var model = Model.new()
    model.config.drivetrain="FWD"
    model.axles.omega=Vector2(100,10)
    model.speed_mps=3
    model.step(0.1,0,1,0)
    check(model.axles.temperatures.x>model.axles.temperatures.y and float(model.wear.neumaticos)>0,"Independent front-wheel slip drives the actual tire temperatures and wear counter")
    var wear: float = model.wear.neumaticos
    var heat: Vector2 = model.axles.temperatures
    model.reset(true)
    check(model.axles.temperatures==heat and float(model.wear.neumaticos)==wear,"Retrying preserves session heat and cumulative tread loss")
    model.reset(false)
    model.step(0.1,0,1,0)
    check(float(model.wear.neumaticos)>=wear,"A thermal reset cannot rewind the monotonic wear counter")
    if not failed: print("PASS: %d tire workshop assertions" % checks)
    quit(1 if failed else 0)
