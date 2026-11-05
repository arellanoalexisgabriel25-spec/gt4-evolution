extends SceneTree

const Driver = preload("res://tests/drag_test_driver.gd")
const Catalog = preload("res://scripts/car_catalog.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const Duel = preload("res://scripts/drag_duel.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var session = root.get_node("GameSession")
    for id in range(17,24):
        session.reset()
        session.controls.restore_defaults()
        session.game.buy(id)
        var car: Dictionary = session.game.find_car(id)
        for part in car.health: car.health[part]=100.0
        var balance: int = session.game.balance
        # Free heads-up is intentional: these factory cars span several time
        # classes, so an 18-second floor would classify faster passes as breakouts.
        check(session.start_drag(id,"duel","technical"),"The new owned car starts a two-car factory exhibition")
        change_scene_to_file("res://scenes/drag.tscn")
        await process_frame
        await process_frame
        var scene = current_scene
        check(scene.is_duel and scene.car.model_name==car.model and scene.opponent.model_name==car.model,"The selected new car creates two independent physical lane actors")
        check(scene.car.visual.imported_model and scene.car.visual.wheels.size()==4 and scene.car.visual.front_pivots.size()==2,"The actual race uses the supplied model with four animated wheels")
        check(scene.car.powertrain.config.drivetrain==("RWD" if id==17 else "FWD"),"The selected driven axle reaches the live powertrain")
        var collider: CollisionShape3D = scene.car.get_child(0)
        check(collider.shape.size.z==Catalog.definition(car.model).size.z,"The collision length belongs to the selected car rather than a generic placeholder")
        var driver = Driver.new()
        scene.input_provider=func() -> Dictionary: return driver.controls(scene.car.powertrain,scene.run.clock,1.0/60.0)
        for i in range(45): await physics_frame
        scene._arm()
        check(scene.duel.started and scene.run.phase=="countdown" and scene.opponent_run.phase=="countdown","Both new lane actors settle and arm on one common start tree")
        for i in range(8000):
            await physics_frame
            if scene.duel.finished: break
        var result: Dictionary = scene.duel_result
        var complete: bool = not result.is_empty() and scene.run.phase=="finished" and scene.opponent_run.phase=="finished"
        check(complete,"Both new physical cars cross the real finish and produce measured passes")
        if complete:
            var a: Dictionary = result.entries.player.ticket
            var b: Dictionary = result.entries.rival.ticket
            var difference := float(a.total)-float(b.total)
            var expected := "" if absf(difference)<=Duel.TIE_TOLERANCE else ("player" if difference<0 else "rival")
            check(result.winner==expected and result.outcome==("tie" if expected.is_empty() else "win"),"The new model's duel is decided by common-green arrival with the existing tie resolution")
            check(a.et>0.0 and b.et>0.0 and absf(float(a.total)-float(a.et)-float(a.reaction))<0.00001,"The two-car result retains separately measured ET and reaction")
            print("Physical national duel ",car.model,": ET ",a.et," / ",b.et,"; winner ",result.winner)
        check(-scene.car.position.z>=402.336 and -scene.opponent.position.z>=402.336,"Both actors physically cover the entire quarter-mile")
        check(scene.car.damage.impacts==0 and scene.opponent.damage.impacts==0,"A clean race does not fabricate collision damage on a new model")
        check(not session.career.stock_drag_records.best(id).is_empty() and session.career.drag_records.best(id).is_empty(),"The measured factory ticket is recorded only for the owned persistent unit")
        check(session.game.balance==balance and float(car.health.motor)<100.0,"The physical pass settles mechanical use without an entry fee or fabricated prize")
        var restored: Dictionary = SaveStore.decode(SaveStore.encode(session.game,session.career))
        check(restored.error.is_empty() and restored.game.find_car(id).owner=="player" and not restored.career.stock_drag_records.best(id).is_empty(),"The new owned vehicle and its measured factory record survive real save serialization")
        scene.input_provider=Callable()
        scene._back_to_garage()
        await process_frame
        await process_frame
        check(current_scene.name=="Main" and session.game.find_car(id).owner=="player" and session.game.balance==balance,"The new race returns to the same garage unit without a duplicate debit or award")
    if not failed: print("PASS: %d physical national duel assertions" % checks)
    quit(1 if failed else 0)
