extends SceneTree

# Load after autoloads exist: standalone --check-only cannot resolve GameSession.
func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var count := 0
    for filename in DirAccess.get_files_at("res://scripts"):
        if not filename.ends_with(".gd"):
            continue
        var script = load("res://scripts/" + filename)
        if script == null or not script.can_instantiate():
            push_error("Game script cannot compile: " + filename)
            quit(1)
            return
        count += 1
    print("Validated %d game scripts" % count)
    quit(0)
