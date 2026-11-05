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
    var tickets: Array = []
    for index in range(3):
        session.reset()
        var id := 11+index
        session.game.buy(id)
        var car: Dictionary = session.game.find_car(id)
        for component in car.health: car.health[component]=100.0
        var balance: int = session.game.balance
        check(session.start_drag(id),"The owned flagship can enter the real quarter-mile scene")
        change_scene_to_file("res://scenes/drag.tscn")
        await process_frame
        await process_frame
        var scene = current_scene
        check(scene.car.model_name==Catalog.FLAGSHIPS[index] and scene.car.powertrain.config.drivetrain=="FWD","The scene binds the actual selected flagship and its front-drive configuration")
        var collision: CollisionShape3D = scene.car.get_child(0)
        check(is_equal_approx(collision.shape.size.z,float(Catalog.DATA[car.model].size.z)),"The physical body uses the selected car's length")
        var driver = Driver.new()
        scene.input_provider = func() -> Dictionary: return driver.controls(scene.car.powertrain,scene.run.clock,1.0/60.0)
        check(await Driver.await_automatic_start(scene),"The starter automatically calls and starts the aligned physical cars")
        check(scene.run.phase=="countdown","The flagship stages through the real clutch and start tree")
        for i in range(5000):
            await physics_frame
            if scene.run.phase in ["finished","invalid"]: break
        check(scene.run.phase=="finished" and -scene.car.position.z>=402.336,"The actual flagship collision body completes the full measured distance")
        check(not session.career.drag_records.best(id).is_empty() and session.career.drag_records.best(1).is_empty(),"The real arrival records a ticket only for the selected persistent car")
        tickets.append(scene.run.elapsed)
        check(scene.car.damage.impacts==0,"A clean full-throttle pass does not fabricate collision damage")
        for i in range(420): await physics_frame
        check(scene.car.powertrain.speed_mps<0.5 and session.game.balance==balance,"The flagship brakes safely without a hidden fee or free prize")
        scene.input_provider = Callable()
        scene._back_to_garage()
        await process_frame
        await process_frame
        check(current_scene.name=="Main" and session.game.find_car(id).owner=="player","The complete pass returns to the original owned unit in the garage")
    print("Physical flagship passes: ",tickets)
    if not failed: print("PASS: %d physical flagship assertions" % checks)
    quit(1 if failed else 0)
