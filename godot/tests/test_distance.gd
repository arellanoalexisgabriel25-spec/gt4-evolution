extends SceneTree

const Economy = preload("res://scripts/economy.gd")
const Store = preload("res://scripts/save_store.gd")
const Career = preload("res://scripts/career.gd")
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
    var old := game.to_dict()
    check(not game.record_distance(1, 500.0), "Unowned car cannot record a player trip")
    check(game.to_dict() == old, "Rejected trip has no mutation")
    game.buy(1)
    var car: Dictionary = game.find_car(1)
    var km: int = car["km"]
    var health: float = car["health"]["neumaticos"]
    check(game.record_distance(1, 456.75), "Sub-kilometre trip records")
    check(car["km"] == km and is_equal_approx(car["distance_remainder_m"], 456.75), "Fractional distance is retained")
    check(car["health"]["neumaticos"] < health, "Short trips cause wear")
    var restored: Dictionary = Store.decode(Store.encode(game, Career.new()))
    check(restored.error.is_empty(), "Fractional distance survives a JSON save")
    game = restored.game
    car = game.find_car(1)
    check(game.record_distance(1, 600.5), "Next trip accumulates")
    check(car["km"] == km + 1 and is_equal_approx(car["distance_remainder_m"], 57.25), "Trips carry whole kilometres without losing remainder")
    old = game.to_dict()
    check(not game.record_distance(1, NAN) and not game.record_distance(1, -1.0), "Invalid distances rejected")
    check(game.to_dict() == old, "Invalid distance cannot corrupt persistent state")
    var legacy := old.duplicate(true)
    for vehicle in legacy["cars"]:
        vehicle.erase("distance_remainder_m")
    check(Economy.new().from_dict(legacy), "Legacy cars without remainder still load")
    var bad := old.duplicate(true)
    bad["cars"][0]["distance_remainder_m"] = 1000.0
    check(not game.from_dict(bad), "Invalid remainder rejected atomically")
    check(game.to_dict() == old, "Invalid remainder preserves current state")
    if not failed:
        print("PASS: %d distance assertions" % checks)
    quit(1 if failed else 0)
