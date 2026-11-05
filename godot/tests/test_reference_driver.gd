extends SceneTree

const Driver = preload("res://tests/drag_test_driver.gd")
const Model = preload("res://scripts/manual_powertrain.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    var driver = Driver.new()
    var model = Model.new()
    model.gear = 2
    model.rpm = 6600.0
    model.speed_mps = 15.0
    model.wheel_omega = model.speed_mps/model.config.wheel_radius
    model.clutch_engagement = 1.0
    driver.controls(model,10.0,1.0/60.0)
    check(model.gear==2,"A free-revving unsynchronized engine after a shift cannot trigger another reference-driver upshift")
    model.wheel_omega = model.rpm*TAU/60.0/(model.config.gear_ratios[1]*model.config.final_drive)
    var pedals: Dictionary = driver.controls(model,10.1,1.0/60.0)
    check(model.gear==3 and pedals.clutch==1.0,"The synchronized rising shift point performs one deliberate clutch change")
    for frame in range(10): driver.controls(model,10.2+frame/60.0,1.0/60.0)
    check(model.gear==3,"The reference lever hold cannot skip through multiple gears")
    if not failed: print("PASS: %d reference driver synchronization assertions" % checks)
    quit(1 if failed else 0)
