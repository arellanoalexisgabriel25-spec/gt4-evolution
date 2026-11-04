extends SceneTree

const Economy = preload("res://scripts/economy.gd")
var checks := 0
var failed := false

func _initialize() -> void:
    var game: EvolutionEconomy = Economy.new()
    game.seed_demo()
    var car := game.find_car(3)
    _check(car.has("faults") and not car["faults"].is_empty(), "demo vehicle has concealed defect")
    _check(not game.eligible(car), "fault makes car unsafe")
    _check(game.inspection_summary(car) == "Estado mecánico no verificado.", "defect not advertised")
    var balance_before := game.balance
    _check(game.inspect(3).begins_with("Inspección completada"), "mechanic inspection succeeds")
    _check(game.balance == balance_before - 200, "inspection debit correct")
    _check(game.inspection_summary(car).contains("motor"), "inspection identifies defect")
    var price := int(car["price"])
    _check(game.buy(3).begins_with("Compraste"), "defective car can be purchased")
    _check(game.balance == balance_before - 200 - price, "purchase debit correct")
    var defect_quote := game.repair_quote(3, "motor")
    _check(defect_quote >= 900, "fault repair surcharge")
    var before_failed := game.balance
    game.balance = 0
    var condition_before := game.condition(car)
    _check(game.repair(3, "motor").begins_with("Saldo insuficiente"), "cannot repair without money")
    _check(game.condition(car) == condition_before, "failed repair keeps health")
    _check(bool(car["faults"].get("motor", false)), "failed repair keeps hidden defect")
    game.balance = before_failed + defect_quote
    var paid_balance := game.balance
    _check(game.repair(3, "motor").begins_with("Reparación"), "repair completes")
    _check(game.balance == paid_balance - defect_quote, "repair charges exactly quoted amount")
    _check(not car["faults"].has("motor"), "repair removes defect")
    _check(game.eligible(car), "repaired car is eligible")
    var saved := game.to_dict()
    var recovered: EvolutionEconomy = Economy.new()
    _check(recovered.from_dict(saved), "restored save loads")
    _check(not recovered.find_car(3)["faults"].has("motor"), "repair persists")
    var pristine: EvolutionEconomy = Economy.new()
    pristine.seed_demo()
    _check(pristine.find_car(3)["price"] == price, "market deterministic")
    var before_value := game.resale_quote(3)
    car["health"]["motor"] = 20.0
    _check(game.resale_quote(3) < before_value, "damaged car resells for less")
    var sample := game.calculate_market_price(2, 50000, car["health"], {})
    var worn := game.calculate_market_price(2, 260000, car["health"], {})
    _check(sample > worn, "high mileage reduces market price")
    var broken := game.calculate_market_price(2, 50000, car["health"], {"motor": true})
    _check(broken < sample, "concealed defects reduce market price")
    var invalid := saved.duplicate(true)
    invalid["cars"][0]["faults"] = {"fake_part": true}
    _check(not recovered.from_dict(invalid), "unknown components rejected on load")
    _check(recovered.to_dict() == saved, "invalid load leaves previous state")
    if failed:
        quit(1)
    else:
        print("PASS: %d market/restoration assertions" % checks)
        quit(0)

func _check(ok: bool, message: String) -> void:
    if not ok:
        push_error("FAIL: " + message)
        failed = true
    else:
        checks += 1
