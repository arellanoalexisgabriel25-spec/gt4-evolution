extends SceneTree

const Economy = preload("res://scripts/economy.gd")
const Career = preload("res://scripts/career.gd")
const Tuning = preload("res://scripts/tuning.gd")
var checks := 0
var failed := false

func _initialize() -> void:
    var game: EvolutionEconomy = Economy.new()
    game.seed_demo()
    var tuning: EvolutionTuning = Tuning.new()
    var car := game.find_car(1)
    _check(tuning.performance_bonus(car) == 0.0, "stock car has no bonus")
    _check(tuning.can_install(game, 1, "ecu").contains("pertenecer"), "only owned cars")
    _check(game.buy(1).begins_with("Compraste"), "vehicle bought")
    _check(tuning.part_by_id("ecu")["price"] == 1200, "ECU price fixed")
    var balance_before := game.balance
    _check(tuning.install(game, 1, "ecu").begins_with("Instalaste"), "ECU installed")
    _check(game.balance == balance_before - 1200, "tuning debited once")
    _check(tuning.has_part(car, "ecu"), "part is installed")
    _check(tuning.performance_bonus(car) == 5.0, "performance bonus applied")
    _check(tuning.install(game, 1, "ecu").contains("instalada"), "no duplicated upgrade")
    _check(game.balance == balance_before - 1200, "duplicate does not charge")
    _check(tuning.engine_wear_multiplier(car) > 1.0, "engine gains mechanical stress")
    var untouched: EvolutionEconomy = Economy.new()
    untouched.seed_demo()
    untouched.buy(1)
    var healthy_car := untouched.find_car(1)
    car["health"]["frenos"] = 85.0
    car["health"]["neumaticos"] = 85.0
    healthy_car["health"]["frenos"] = 85.0
    healthy_car["health"]["neumaticos"] = 85.0
    var initial := float(car["health"]["motor"])
    _check(game.drive(1, 100, 2.0).begins_with("Prueba"), "modified car drives")
    _check(untouched.drive(1, 100, 2.0).begins_with("Prueba"), "stock car drives")
    _check(float(car["health"]["motor"]) < float(healthy_car["health"]["motor"]), "tuned motor wears faster")
    _check(float(car["health"]["motor"]) < initial, "tuned motor wear nonzero")
    _check(tuning.performance_bonus(car) == 5.0, "bonus persists after driving")
    var saved := game.to_dict()
    var restored: EvolutionEconomy = Economy.new()
    _check(restored.from_dict(saved), "tuning save loads")
    _check(tuning.has_part(restored.find_car(1), "ecu"), "tuning is persistent")
    var tampered := saved.duplicate(true)
    tampered["cars"][0]["upgrades"].append("invalid")
    _check(not restored.from_dict(tampered), "reject unknown upgrade")
    _check(restored.to_dict() == saved, "failed load is atomic")
    var bad: EvolutionEconomy = Economy.new()
    bad.seed_demo()
    bad.buy(1)
    bad.balance = 0
    _check(tuning.install(bad, 1, "ecu").contains("Saldo insuficiente"), "cannot buy without funds")
    _check(not tuning.has_part(bad.find_car(1), "ecu"), "unaffordable part not installed")
    var career: EvolutionCareer = Career.new()
    var score := game.condition(car) + tuning.performance_bonus(car)
    _check(score > game.condition(car), "career performance modifier positive")
    if failed:
        quit(1)
    else:
        print("PASS: %d tuning assertions" % checks)
        quit(0)

func _check(ok: bool, message: String) -> void:
    if not ok:
        push_error("FAIL: " + message)
        failed = true
    else:
        checks += 1
