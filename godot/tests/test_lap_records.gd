extends SceneTree

const Records = preload("res://scripts/lap_records.gd")
const Career = preload("res://scripts/career.gd")
const Economy = preload("res://scripts/economy.gd")
const Store = preload("res://scripts/save_store.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    var records = Records.new()
    check(records.get_best(1) == 0.0, "No invented initial record")
    check(records.consider(1, 36.5), "First valid lap creates a record")
    check(not records.consider(1, 37.0) and records.get_best(1) == 36.5, "Slower lap does not replace best")
    check(records.consider(1, 35.5) and records.get_best(1) == 35.5, "Faster lap updates best")
    check(records.consider(2, 40.0) and records.get_best(1) == 35.5, "Records are separate per persistent car")
    check(not records.consider(1, NAN) and not records.consider(1, 0.0), "Invalid lap times rejected")
    var before := records.to_dict()
    check(not records.from_dict({"club_oval:1":-1.0}) and records.to_dict() == before, "Invalid record load preserves prior data")
    check(not records.from_dict({"unknown:1":50.0}), "Unknown circuit records rejected")
    var career = Career.new()
    career.lap_records = records
    var game = Economy.new()
    game.seed_demo()
    var restored := Store.decode(Store.encode(game, career))
    check(restored.error.is_empty() and restored.career.lap_records.get_best(1) == 35.5, "JSON save preserves personal best")
    var legacy := career.to_dict()
    legacy.erase("lap_records")
    check(career.from_dict(legacy) and career.lap_records.get_best(1) == 0.0, "Old career saves initialize empty records")
    if not failed:
        print("PASS: %d lap record assertions" % checks)
    quit(1 if failed else 0)
