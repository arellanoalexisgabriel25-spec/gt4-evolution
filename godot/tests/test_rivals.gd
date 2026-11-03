extends SceneTree

const Economy = preload("res://scripts/economy.gd")
const Career = preload("res://scripts/career.gd")
const Rivals = preload("res://scripts/rivals.gd")
var checks := 0
var failed := false

func _initialize() -> void:
    var rivals: EvolutionRivals = Rivals.new()
    _check(Rivals.DRIVERS.size() == 4, "four simulated rivals")
    _check(rivals.field_for_event("debut").size() == 2, "two rivals per event")
    _check(rivals.field_for_event("national").size() == 2, "national rivals")
    _check(rivals.driver_by_id("akira")["name"] == "Akira Sato", "stable driver lookup")
    var same_a := rivals.classify(70.0, "debut")
    var same_b := rivals.classify(70.0, "debut")
    _check(same_a == same_b, "rival results deterministic")
    _check(rivals.classify(100.0, "debut")["position"] == 1, "high performer wins")
    _check(rivals.classify(0.0, "debut")["position"] == 3, "low performer finishes last")
    _check(rivals.classify(70.0, "unknown").is_empty(), "unknown event rejected")
    _check(rivals.score(rivals.driver_by_id("akira"), "endurance") > rivals.score(rivals.driver_by_id("akira"), "debut"), "event-specific rival performance")
    var game: EvolutionEconomy = Economy.new()
    game.seed_demo()
    var career: EvolutionCareer = Career.new()
    game.buy(1)
    var car := game.find_car(1)
    car["health"]["frenos"] = 85.0
    car["health"]["neumaticos"] = 85.0
    _check(career.simulate_event(game, "debut", 1).contains("Debutantes"), "simulated competition with rivals")
    _check(career.results.size() == 1, "result recorded")
    _check(career.results[0].has("opponents"), "rivals included in event result")
    _check(career.results[0]["opponents"].size() == 2, "two opponents recorded")
    _check(career.rivalries.has("nico"), "first rival history recorded")
    _check(int(career.rivalries["nico"]["encounters"]) == 1, "one encounter recorded")
    _check(int(career.rivalries["nico"]["victories"]) + int(career.rivalries["nico"]["defeats"]) == 1, "head-to-head counters consistent")
    var saved := career.to_dict()
    var restore: EvolutionCareer = Career.new()
    _check(restore.from_dict(saved), "rival history loads")
    _check(restore.to_dict() == saved, "rival history round trip")
    var tampered := saved.duplicate(true)
    tampered["rivalries"]["nico"]["encounters"] = -1
    _check(not restore.from_dict(tampered), "invalid rivalry counters rejected")
    _check(restore.to_dict() == saved, "invalid load atomic")
    var old_save := saved.duplicate(true)
    old_save.erase("rivalries")
    _check(restore.from_dict(old_save), "legacy career save loads without rivalries")
    _check(restore.rivalries.is_empty(), "legacy save initializes empty rival history")
    if failed:
        quit(1)
    else:
        print("PASS: %d rival assertions" % checks)
        quit(0)

func _check(ok: bool, message: String) -> void:
    if not ok:
        push_error("FAIL: " + message)
        failed = true
    else:
        checks += 1
