extends SceneTree

const Store = preload("res://scripts/save_store.gd")
const Economy = preload("res://scripts/economy.gd")
const Career = preload("res://scripts/career.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func equivalent(a, b) -> bool:
    if typeof(a) in [TYPE_FLOAT, TYPE_INT] and typeof(b) in [TYPE_FLOAT, TYPE_INT]:
        return absf(float(a) - float(b)) < 0.000000001
    if typeof(a) == TYPE_DICTIONARY and typeof(b) == TYPE_DICTIONARY:
        if a.size() != b.size():
            return false
        for key in a:
            if not b.has(key) or not equivalent(a[key], b[key]):
                return false
        return true
    if typeof(a) == TYPE_ARRAY and typeof(b) == TYPE_ARRAY:
        if a.size() != b.size():
            return false
        for i in range(a.size()):
            if not equivalent(a[i], b[i]):
                return false
        return true
    return a == b

func _initialize() -> void:
    var game = Economy.new()
    game.seed_demo()
    game.buy(1)
    var career = Career.new()
    career.simulate_event(game, "debut", 1)
    var encoded := Store.encode(game, career)
    var loaded := Store.decode(encoded)
    check(loaded.error.is_empty(), "JSON encoded by the game can be decoded")
    if loaded.error.is_empty():
        check(equivalent(loaded.game.to_dict(), game.to_dict()), "JSON round-trip preserves economy and history within numeric precision")
        check(loaded.career.to_dict() == career.to_dict(), "JSON round-trip preserves career and rivalries")
    check(Store.decode(JSON.stringify(game.to_dict())).error.is_empty(), "Legacy economy-only JSON loads")
    check(not Store.decode('{"save_version":99}').error.is_empty(), "Unsupported save version rejected")
    check(not Store.decode('{"economy":"bad"}').error.is_empty(), "Malformed nested state rejected safely")
    check(not Store.decode("{broken").error.is_empty(), "Corrupt JSON rejected")
    var bad := game.to_dict()
    bad["balance"] = 1.5
    check(not Store.decode(JSON.stringify(bad)).error.is_empty(), "Fractional credits are not rounded into valid credits")
    var path := "user://test-save-%d.json" % Time.get_ticks_usec()
    check(Store.save_file(path, game, career) == OK, "Save writes a real JSON file")
    var original := FileAccess.get_file_as_string(path)
    game.balance += 10
    check(Store.save_file(path, game, career) == OK, "Atomic replacement updates an existing save")
    check(FileAccess.get_file_as_string(path) != original, "Existing save contains the new state")
    loaded = Store.load_file(path)
    check(loaded.error.is_empty() and loaded.game.balance == game.balance, "File load restores actual saved credits")
    original = FileAccess.get_file_as_string(path)
    game.balance = -1
    check(Store.save_file(path, game, career) != OK, "Invalid state cannot be saved")
    check(FileAccess.get_file_as_string(path) == original, "Failed save preserves previous file")
    check(not FileAccess.file_exists(path + ".tmp"), "Successful replacement leaves no temporary file")
    DirAccess.remove_absolute(path)
    if not failed:
        print("PASS: %d save store assertions" % checks)
    quit(1 if failed else 0)
