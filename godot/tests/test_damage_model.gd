extends SceneTree

const Economy = preload("res://scripts/economy.gd")
const Damage = preload("res://scripts/damage_model.gd")
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
    check(Damage.points_for(2.0) == 0.0 and Damage.points_for(3.0) == 0.0, "Taps below the threshold cause no damage")
    check(Damage.points_for(NAN) == 0.0 and Damage.points_for(-5.0) == 0.0, "Invalid or negative changes cause no damage")
    check(Damage.points_for(10.0) > Damage.points_for(6.0) * 2.0, "Damage grows faster than impact speed")
    check(Damage.points_for(1000.0) == Damage.MAX_IMPACT_POINTS, "A single impact is capped")
    var forward := Vector2(0, -1)
    check(Damage.classify(Vector2(0, 8), forward) == "front", "Head-on impact is classified as front")
    check(Damage.classify(Vector2(0, -8), forward) == "rear", "Being hit from behind is classified as rear")
    check(Damage.classify(Vector2(8, 1), forward) == "side", "Lateral impact is classified as side")
    var model = Damage.new()
    var before := Vector2(0, -25)
    var applied: float = model.record(before, Vector2(0, -5), forward)
    check(applied > 40.0 and model.impacts == 1, "A 20 m/s frontal impact is severe")
    check(model.pending.has("chasis") and model.pending.has("motor") and not model.pending.has("transmision"), "Frontal damage hits chassis and engine, not the gearbox")
    check(is_equal_approx(model.total_pending(), applied), "Distributed damage equals impact points")
    check(model.record(before, Vector2(0, -5), forward) == 0.0 and model.impacts == 1, "Follow-up frames of the same crash are not counted twice")
    var first_total: float = model.total_pending()
    var extra: float = model.record(before, Vector2(0, 5), forward)
    check(extra > 0.0 and model.impacts == 1 and absf(model.total_pending() - Damage.MAX_IMPACT_POINTS) < 0.001 and absf(first_total + extra - Damage.MAX_IMPACT_POINTS) < 0.001, "A harder frame of the same crash adds only the increase")
    model.tick(0.6)
    check(model.record(before, Vector2(0, -23), forward) == 0.0, "A tap after the cooldown is still ignored")
    check(model.record(Vector2(0, -25), Vector2(0, -10), forward) > 0.0 and model.impacts == 2, "A new impact after the cooldown counts")
    check(Damage.new().record(Vector2(NAN, 0), Vector2.ZERO, forward) == 0.0 and Damage.new().record(before, Vector2.ZERO, Vector2.ZERO) == 0.0, "Invalid samples are ignored")

    var game = Economy.new()
    game.seed_demo()
    var unowned: Dictionary = model.settle(game, 1)
    check(unowned.is_empty() and model.total_pending() > 0.0, "Unowned car is not damaged and damage stays pending")
    game.buy(1)
    var car: Dictionary = game.find_car(1)
    car["health"]["chasis"] = 90.0
    car["health"]["motor"] = 90.0
    var health_before: Dictionary = car["health"].duplicate()
    var expected: float = model.total_pending()
    var settled: Dictionary = model.settle(game, 1)
    var lost := 0.0
    for component in Damage.COMPONENTS:
        lost += float(health_before[component]) - float(car["health"][component])
        check(float(car["health"][component]) >= 0.0 and float(car["health"][component]) <= 100.0, "Health stays within 0-100 for %s" % component)
    check(lost > 0.0 and lost <= expected + 0.0001 and not settled.is_empty(), "Settlement removes health up to the pending damage")
    check(model.pending.is_empty() and model.settle(game, 1).is_empty(), "Damage settles exactly once")
    var snapshot: Dictionary = game.to_dict()
    check(car["history"].back()["event"] == "danos", "Settlement is recorded in the car history")
    var restored = Economy.new()
    check(restored.from_dict(snapshot) and restored.to_dict() == snapshot, "Damaged car survives the existing save schema")
    var decoded: Dictionary = Store.decode(Store.encode(game, Career.new()))
    check(decoded.error.is_empty(), "Damaged car survives a JSON save")

    check(Damage.new().record(before,Vector2.ZERO,Vector2(NAN,1))==0.0,"A non-finite heading cannot be classified as a valid impact")
    var invalid = Damage.new()
    invalid.pending["motor"] = NAN
    var valid_state: Dictionary = game.to_dict()
    check(not invalid.valid_pending() and invalid.settle(game,1).is_empty() and game.to_dict()==valid_state,"Non-finite pending damage cannot corrupt saved mechanical health")
    var wreck = Damage.new()
    wreck.record(Vector2(0, -60), Vector2.ZERO, forward)
    var low: Dictionary = game.find_car(1)
    low["health"]["motor"] = 5.0
    wreck.settle(game, 1)
    check(low["health"]["motor"] >= 0.0 and not game.eligible(low), "Heavy damage cannot push health below zero and makes the car ineligible until repaired")
    var price: int = game.repair_quote(1, "motor")
    check(price > 0, "A damaged component has a repair quote")

    var healthy := Damage.handicaps({})
    var ruined := Damage.handicaps({"transmision": 0.0, "suspension": 0.0, "chasis": 0.0})
    var worn := Damage.handicaps({"transmision": 50.0, "suspension": 50.0, "chasis": 50.0})
    check(healthy["acceleration"] == 1.0 and healthy["grip"] == 1.0 and healthy["steering"] == 1.0, "Healthy cars have no handicap")
    check(ruined["acceleration"] < worn["acceleration"] and worn["acceleration"] < 1.0, "Transmission wear costs acceleration progressively")
    check(ruined["grip"] >= 0.79 and ruined["grip"] < worn["grip"] and ruined["steering"] >= 0.89, "Suspension and chassis handicaps are bounded")
    if failed:
        quit(1)
    else:
        print("PASS: %d damage model assertions" % checks)
        quit(0)
