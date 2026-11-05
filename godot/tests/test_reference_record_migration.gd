extends SceneTree
const Records = preload("res://scripts/drag_records.gd")
const Reference = preload("res://scripts/technical_reference_data.gd")
const Store = preload("res://scripts/save_store.gd")
const Career = preload("res://scripts/career.gd")
const Driver = preload("res://tests/drag_test_driver.gd")
var checks := 0
var failed := false
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)
func ticket(et: float) -> Dictionary:
    return {"distance":402.336,"et":et,"reaction":0.2,"total":et+0.2,"trap_kmh":110.0,"finish_kmh":111.0,"sixty_ft":3.0,"eighth":12.0}
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var profile: String = Reference.VIVACE_REVISION
    var records = Records.new()
    var old := ticket(18.0)
    check(records.from_dict({"11":old}),"Old unversioned records load without a migration prompt")
    check(records.best_for_profile(11,profile).is_empty() and records.previous_best(11,profile)==old,"Old times are preserved as history and cannot be the revised car's target")
    var malformed := ticket(20.0); malformed.et=NAN
    check(not records.consider_for_profile(11,malformed,profile) and records.best(11)==old and records.history_to_dict().is_empty(),"An invalid new run cannot archive or erase an old best")
    check(records.consider_for_profile(11,ticket(20.0),profile),"The first current-profile time is valid even when slower than an old curve's best")
    check(records.best_for_profile(11,profile).et==20.0 and records.previous_best(11,profile)==old,"Current and historical records remain distinct after a new finish")
    check(records.history_to_dict()["11"].legacy==old,"The original ticket survives the first revision transition")
    var snapshot: Dictionary = records.to_dict(); var archive: Dictionary = records.history_to_dict()
    check(not records.consider_for_profile(11,ticket(20.0),profile) and not records.consider_for_profile(11,ticket(21.0),profile) and records.to_dict()==snapshot and records.history_to_dict()==archive,"Duplicate/slower runs do not alter active or archived records")
    check(records.consider_for_profile(11,ticket(19.0),profile) and records.previous_best(11,profile)==old,"A faster current run improves its own series only")
    var exposed: Dictionary = records.previous_best(11,profile); exposed.et=1.0
    check(records.previous_best(11,profile).et==18.0,"Returned history is a defensive copy")
    check(records.consider_for_profile(11,ticket(22.0),"future_profile") and records.history_to_dict()["11"][profile].et==19.0,"A second future revision archives the completed earlier series")
    var tagged: Dictionary = records.best(11)
    check(not records.consider_for_profile(11,tagged,profile),"A previously tagged ticket cannot be relabelled as a different simulation")
    for bad in ["../bad","BAD","legacy","", "x".repeat(97)]:
        if bad.is_empty(): continue
        check(not records.consider_for_profile(11,ticket(17.0),bad),"Malformed profile names cannot poison record serialization")
    var preserved: Dictionary = records.history_to_dict()
    check(not records.history_from_dict({"11":{"other":ticket(18.0)}}) and records.history_to_dict()==preserved,"Invalid history loads reject mismatched profile tags atomically")
    check(not records.from_dict({"11":{"physics_profile":42}}),"Malformed active ticket metadata is rejected")
    var career = Career.new()
    career.drag_records=records
    var data := career.to_dict()
    var loaded = Career.new()
    check(loaded.from_dict(data) and loaded.drag_records.to_dict()==records.to_dict() and loaded.drag_records.history_to_dict()==records.history_to_dict(),"Career serialization retains active and historical profiles")
    var before := loaded.to_dict(); data.stock_drag_record_history=[]
    check(not loaded.from_dict(data) and loaded.to_dict()==before,"A malformed optional archive does not mutate a valid loaded career")
    var legacy := Career.new().to_dict(); legacy.erase("drag_record_history"); legacy.erase("stock_drag_record_history"); legacy.drag_records={"11":old}
    check(loaded.from_dict(legacy) and loaded.drag_records.best(11)==old,"Previous saves with no archive fields stay compatible")

    var session = root.get_node("GameSession")
    session.reset(); session.game.buy(11)
    var owned: Dictionary = session.game.find_car(11)
    for component in owned.health: owned.health[component]=100.0
    session.career.stock_drag_records.consider(11,old)
    var balance: int=session.game.balance
    var json_data: Dictionary=Store.decode(Store.encode(session.game,session.career))
    check(json_data.error=="" and json_data.career.stock_drag_records.best(11)==old,"A real old save round-trips before the new physical pass")
    check(session.start_drag(11,"duel","technical","","Fiat Uno Fire 3 puertas"),"The revised persistent car enters an actual mixed-car factory duel")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame; await process_frame
    var scene=current_scene
    check(scene.hud.best_label.text.contains("MEJOR —") and scene.garage.record_profile==profile,"The actual HUD starts a new comparable series instead of showing an old target")
    var driver=Driver.new()
    scene.input_provider=func() -> Dictionary: return driver.controls(scene.car.powertrain,scene.run.clock,1.0/60.0)
    check(await Driver.await_automatic_start(scene),"The revised car uses the normal automatic starter")
    for i in range(8000):
        await physics_frame
        if scene.duel.finished: break
    check(scene.run.phase=="finished" and scene.opponent_run.phase=="finished" and not scene.duel_result.is_empty(),"The PDF-configured 147 and its physical opponent both reach the real finish")
    var current: Dictionary=session.career.stock_drag_records.best_for_profile(11,profile)
    check(not current.is_empty() and is_equal_approx(current.et,scene.run.elapsed),"The new record stores its actually measured time and physical revision")
    check(session.career.stock_drag_records.previous_best(11,profile)==old and session.game.balance==balance,"The prior record and balance survive the real result settlement")
    scene.input_provider=Callable(); scene._back_to_garage()
    await process_frame; await process_frame
    var labels: Array= current_scene.content.find_children("*","Label",true,false)
    var has_history := false
    for label in labels: has_history=has_history or label.text.contains("Marca histórica / fábrica")
    check(has_history,"The real garage exposes preserved historical times with their prior-fiche label")
    json_data=Store.decode(Store.encode(session.game,session.career))
    check(json_data.error=="" and not json_data.career.stock_drag_records.best_for_profile(11,profile).is_empty() and is_equal_approx(json_data.career.stock_drag_records.best_for_profile(11,profile).et,current.et) and json_data.career.stock_drag_records.best_for_profile(11,profile).physics_profile==profile and json_data.career.stock_drag_records.previous_best(11,profile)==old,"Real JSON save/load preserves current and historical measured records")
    if not failed: print("PASS: %d reference record migration assertions" % checks)
    quit(1 if failed else 0)
