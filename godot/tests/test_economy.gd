extends SceneTree

const Economy = preload("res://scripts/economy.gd")
var checks := 0

func _initialize() -> void:
    var game: EvolutionEconomy = Economy.new()
    game.seed_demo()
    _check(game.cars.size() == 13, "ten legacy offers and three flagship cars")
    _check(game.balance == 12000, "starting capital")
    var car := game.find_car(1)
    var price := int(car["price"])
    _check(game.buy(1).begins_with("Compraste"), "purchase succeeds")
    _check(game.balance == 12000 - price, "purchase accounting")
    var after := game.balance
    _check(not game.buy(1).begins_with("Compraste"), "no duplicate purchase")
    _check(game.balance == after, "duplicate does not debit")
    var before_km := int(car["km"])
    car["health"]["frenos"] = 10.0
    _check(not game.eligible(car), "unsafe brakes rejected")
    _check(game.drive(1, 10).begins_with("Vehículo no apto"), "cannot drive unsafe car")
    car["health"]["frenos"] = 90.0
    car["health"]["neumaticos"] = 90.0
    _check(game.drive(1, 10).begins_with("Prueba"), "driving succeeds")
    _check(int(car["km"]) == before_km + 10, "mileage increases")
    var snapshot := game.to_dict()
    var restored: EvolutionEconomy = Economy.new()
    _check(restored.from_dict(snapshot), "load valid save")
    _check(restored.to_dict() == snapshot, "round-trip persistence")
    var invalid := snapshot.duplicate(true)
    invalid["balance"] = -100
    _check(not restored.from_dict(invalid), "invalid saves rejected")
    var old_balance := restored.balance
    var proceeds := restored.resale_quote(1)
    _check(restored.sell(1).begins_with("Vendiste"), "sale")
    _check(restored.balance == old_balance + proceeds, "sale accounting")
    _check(not restored.sell(1).begins_with("Vendiste"), "no double sale")
    print("PASS: %d assertions" % checks)
    quit(0)

func _check(ok: bool, name: String) -> void:
    if not ok:
        push_error("FAIL: " + name)
        quit(1)
        return
    checks += 1
