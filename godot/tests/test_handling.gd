extends SceneTree

const Handling = preload("res://scripts/handling.gd")

func _initialize() -> void:
    var stock := {"health": {"motor": 90.0, "frenos": 90.0, "neumaticos": 90.0}, "upgrades": []}
    var worn := {"health": {"motor": 40.0, "frenos": 40.0, "neumaticos": 40.0}, "upgrades": []}
    var tuned := stock.duplicate(true)
    tuned["upgrades"] = ["ecu", "escape", "brakes", "tires", "suspension"]
    var a := Handling.parameters(stock)
    var b := Handling.parameters(worn)
    var c := Handling.parameters(tuned)
    var checks := 0
    for parameter in ["acceleration", "top_speed", "braking", "grip"]:
        if not (float(b[parameter]) > 0.0 and float(b[parameter]) < float(a[parameter]) and float(a[parameter]) < float(c[parameter])):
            push_error("Wear and upgrades must affect " + parameter)
            quit(1)
            return
        checks += 1
    if stock["upgrades"] != [] or stock["health"]["motor"] != 90.0:
        quit(1)
        return
    print("PASS: %d handling assertions" % (checks + 1))
    quit(0)
