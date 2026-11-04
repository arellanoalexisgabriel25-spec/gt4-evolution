extends SceneTree

const Economy = preload("res://scripts/economy.gd")
var checks := 0

func _initialize() -> void:
    var game: EvolutionEconomy = Economy.new()
    game.seed_demo()
    var car := game.find_car(1)
    _check(not bool(car.get("inspected", false)), "new offer not inspected")
    var original_balance := game.balance
    var original_condition := game.condition(car)
    var result := game.inspect(1)
    _check(result.begins_with("Inspección completada"), "inspection succeeds")
    _check(game.balance == original_balance - 200, "inspection costs 200 credits")
    _check(bool(car["inspected"]), "inspection revealed")
    _check(game.condition(car) == original_condition, "inspection does not repair car")
    _check(not game.inspect(1).begins_with("Inspección completada"), "reinspection blocked")
    _check(game.balance == original_balance - 200, "no double charge")
    var restored: EvolutionEconomy = Economy.new()
    _check(restored.from_dict(game.to_dict()), "save containing inspection loads")
    _check(bool(restored.find_car(1).get("inspected", false)), "inspection state preserved")
    restored.balance = 0
    _check(restored.inspect(2).begins_with("Saldo insuficiente"), "cannot inspect without funds")
    _check(not bool(restored.find_car(2).get("inspected", false)), "failed inspection unchanged")
    _check(restored.buy(1).begins_with("Saldo insuficiente"), "cannot buy with zero credits")
    print("PASS: %d inspection assertions" % checks)
    quit(0)

func _check(ok: bool, name: String) -> void:
    if not ok:
        push_error("FAIL: " + name)
        quit(1)
        return
    checks += 1
