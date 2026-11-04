extends SceneTree

const Economy = preload("res://scripts/economy.gd")
const Career = preload("res://scripts/career.gd")
var checks := 0
var failed := false

func _initialize() -> void:
    var game: EvolutionEconomy = Economy.new()
    game.seed_demo()
    var career: EvolutionCareer = Career.new()
    _check(career.license == "R", "starts with rookie license")
    _check(career.reputation == 0, "starts without reputation")
    _check(career.can_enter(game, "debut", 1).contains("vehículo"), "requires own vehicle")
    _check(career.can_enter(game, "regional", 1).contains("Licencia"), "regional locked")
    _check(game.buy(1).begins_with("Compraste"), "initial vehicle acquired")
    var car := game.find_car(1)
    car["health"]["frenos"] = 9.0
    _check(career.can_enter(game, "debut", 1).contains("no está apto"), "unsafe car blocked")
    car["health"]["frenos"] = 85.0
    car["health"]["neumaticos"] = 85.0
    var before_balance := game.balance
    var before_mileage := int(car["km"])
    var first := career.simulate_event(game, "debut", 1)
    _check(first.contains("Copa de Debutantes"), "first competition simulated")
    _check(game.balance > before_balance, "net prize transfers credits")
    _check(int(car["km"]) == before_mileage + 12, "event adds mileage")
    _check(career.completed.has("debut"), "event recorded as completed")
    var awarded := game.balance
    _check(career.simulate_event(game, "debut", 1).contains("dos veces"), "no repeat reward")
    _check(game.balance == awarded, "duplicate event cannot mint credits")
    _check(career.simulate_event(game, "local", 1).contains("Sprint"), "second rookie event")
    _check(career.license == "B", "rookie achievements promote to B")
    _check(career.simulate_event(game, "regional", 1).contains("Regionales"), "regional unlocked")
    _check(career.simulate_event(game, "endurance", 1).contains("Resistencia"), "endurance unlocked")
    _check(career.license == "A", "B achievements promote to A")
    _check(career.can_enter(game, "national", 1).is_empty(), "national unlocked")
    var result := career.simulate_event(game, "national", 1)
    _check(result.contains("Nacional"), "national entry simulated")
    _check(career.results.size() == 5, "five unique event results")
    var saved := career.to_dict()
    var restored: EvolutionCareer = Career.new()
    _check(restored.from_dict(saved), "career save valid")
    _check(restored.to_dict() == saved, "career save round trip")
    var bad := saved.duplicate(true)
    bad["completed"].append("not_an_event")
    _check(not restored.from_dict(bad), "unknown event rejected")
    _check(restored.to_dict() == saved, "invalid career load atomic")
    var poor: EvolutionEconomy = Economy.new()
    poor.seed_demo()
    poor.buy(1)
    poor.balance = 0
    var new_career: EvolutionCareer = Career.new()
    _check(new_career.can_enter(poor, "debut", 1).contains("Saldo insuficiente"), "inscription costs funds")
    _check(new_career.simulate_event(poor, "debut", 1).contains("Saldo insuficiente"), "failed event no mutation")
    _check(new_career.completed.is_empty(), "failed entry cannot add result")
    if failed:
        quit(1)
    else:
        print("PASS: %d career assertions" % checks)
        quit(0)

func _check(ok: bool, message: String) -> void:
    if not ok:
        push_error("FAIL: " + message)
        failed = true
    else:
        checks += 1
