extends SceneTree

const Driver = preload("res://tests/drag_test_driver.gd")
const Catalog = preload("res://scripts/car_catalog.gd")
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
    for id in [24,25,26,27,28,29]:
        session.reset()
        session.controls.restore_defaults()
        session.game.buy(id)
        var vehicle: Dictionary = session.game.find_car(id)
        for component in vehicle.health: vehicle.health[component]=100.0
        var balance: int = session.game.balance
        check(session.start_drag(id,"duel","technical",""),"A purchased regional enters a physical indexed duel from its persistent unit")
        change_scene_to_file("res://scenes/drag.tscn")
        await process_frame
        await process_frame
        var scene = current_scene
        check(scene.is_duel and scene.car.model_name==vehicle.model and scene.opponent.model_name==vehicle.model,"The chosen regional creates two independent physical race cars")
        check(scene.car.powertrain.config.drivetrain==("RWD" if id in [25,26] else "FWD"),"Both pickups use rear drive and the hatch/sedan/SUV profiles use front drive")
        check(scene.car.visual.imported_model and scene.car.visual.wheels.size()==4,"The actual race loads the supplied regional model with animatable wheels")
        var body: CollisionShape3D = scene.car.get_child(0)
        check(body.shape.size.z==Catalog.DATA[vehicle.model].size.z,"Collision length follows the selected regional rather than a generic flagship")
        for frame in range(45): await physics_frame
        check(scene.car.sample_ground().wheels_on_ground==4,"All four real tire probes contact the original asphalt after settling")
        var driver = Driver.new()
        driver.launch_rpm = 2400.0 if id in [25,26] else 3400.0
        scene.input_provider=func() -> Dictionary: return driver.controls(scene.car.powertrain,scene.run.clock,1.0/60.0)
        check(await Driver.await_automatic_start(scene),"The starter automatically calls and starts the aligned physical cars")
        check(scene.duel.started and scene.run.phase=="countdown" and scene.opponent_run.phase=="countdown","Both regionals stage on the common tree")
        for i in range(8000):
            await physics_frame
            if scene.duel.finished: break
        var result: Dictionary = scene.duel_result
        var completed: bool = not result.is_empty() and scene.run.phase=="finished" and scene.opponent_run.phase=="finished"
        check(completed,"Both actual regional collision bodies cover the full quarter-mile and finish")
        if completed:
            var player: Dictionary = result.entries.player.ticket
            var rival: Dictionary = result.entries.rival.ticket
            var expected := "player" if float(player.total)<float(rival.total) else "rival"
            check(result.winner==expected,"Measured arrival from the common green decides the regional duel")
            print("Physical regional duel ",vehicle.model,": ET ",player.et," / ",rival.et,"; winner ",result.winner)
        check(-scene.car.position.z>=402.336 and -scene.opponent.position.z>=402.336,"The result is backed by both cars' measured world positions")
        check(scene.car.damage.impacts==0 and scene.opponent.damage.impacts==0,"A clean straight pass adds no fabricated collision damage")
        check(not session.career.stock_drag_records.best(id).is_empty() and session.career.drag_records.best(id).is_empty(),"Regional factory records attach to the owned car without polluting prepared practice")
        check(session.game.balance==balance and float(vehicle.health.motor)<100.0,"Regional races settle actual mechanical use without hidden fees or fabricated prizes")
        scene.input_provider=Callable()
        scene._back_to_garage()
        await process_frame
        await process_frame
        check(current_scene.name=="Main" and session.game.find_car(id).owner=="player" and session.game.balance==balance,"Each complete regional duel returns to the same unit and balance in the garage")
    if not failed: print("PASS: %d physical regional duel assertions" % checks)
    quit(1 if failed else 0)
