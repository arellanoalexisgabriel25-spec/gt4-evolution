extends SceneTree
const Model = preload("res://scripts/manual_powertrain.gd")
var checks := 0
var failed := false
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed=true
        push_error(message)
func snapshot(model) -> Dictionary:
    return {"gear":model.gear,"shifts":model.shifts,"missed":model.missed_shifts,"wear":model.wear.duplicate(true),"timer":model.shift_timer,"feedback":model.feedback,"feedback_time":model.feedback_time}
func _initialize() -> void:
    var model=Model.new()
    var before:=snapshot(model)
    for pedal in [NAN,INF,-INF,-0.1,1.1]:
        check(not model.shift(1,pedal),"A malformed clutch cannot select a gear")
        check(snapshot(model)==before,"Rejected malformed input preserves gearbox, feedback and mechanical health")
    check(not model.shift(1,0.0) and model.missed_shifts==1 and float(model.wear.transmision)>0,"A real shift without clutch still incurs the normal failed-shift consequence")
    model.shift_timer=0.0
    check(model.shift(1,1.0) and model.gear==1,"A valid fully depressed clutch still permits first gear")
    var frozen:=snapshot(model)
    check(not model.shift(1,NAN) and snapshot(model)==frozen,"Malformed input cannot replace an in-progress valid gear selection")
    if not failed: print("PASS: %d shift input assertions" % checks)
    quit(1 if failed else 0)
