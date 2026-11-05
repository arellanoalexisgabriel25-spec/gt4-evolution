extends SceneTree

# Executed outside the exported PCK by the matching editor binary. Every game
# script, resource, scene and autoload below is loaded from that exact pack.
const Catalog = preload("res://scripts/car_catalog.gd")
const Visual = preload("res://scripts/car_visual.gd")
const Driver = preload("res://scripts/drag_rival_driver.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    call_deferred("run")

# Tests are deliberately excluded from shipping PCKs. This external fixture
# observes the packaged procedure directly instead of importing test helpers.
func await_automatic_start(scene) -> bool:
    if scene.run.phase != "preparation" or scene.paused or not scene.enabled:
        return false
    if not scene.procedure.configure(0.05,5.0,0.05):
        return false
    for frame in range(600):
        await physics_frame
        if scene.run.phase == "countdown":
            return true
        if scene.run.phase == "invalid" or scene.procedure.phase == "expired":
            return false
    return false

func run() -> void:
    var session = root.get_node("GameSession")
    check(session.VERSION=="0.20","The exported PCK carries the current game version")
    check(Catalog.DATA.size()==13,"The export contains all thirteen supplied car models")
    for name in Catalog.DATA:
        var profile: Dictionary = Catalog.DATA[name]
        check(ResourceLoader.exists(str(profile.asset)),"The exported model resolves through its imported resource: "+name)
        var visual = Visual.new()
        visual.model_name = name
        root.add_child(visual)
        await process_frame
        check(visual.imported_model and visual.wheels.size()==4 and visual.front_pivots.size()==2,"The exported car has a body and four animatable wheels: "+name)
        visual.queue_free()
        await process_frame
    session.reset()
    var car_id := 0
    for car in session.game.cars:
        if car.model=="Fiat 133": car_id=int(car.id)
    check(car_id>0,"The exported market contains the Fiat 133")
    if car_id<=0:
        quit(1)
        return
    session.game.buy(car_id)
    var owned: Dictionary = session.game.find_car(car_id)
    for component in owned.health: owned.health[component]=100.0
    check(session.start_drag(car_id,"duel","technical","1"),"The exported car enters a real two-lane class duel")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    var scene = current_scene
    check(scene.is_duel and scene.car.powertrain.config.drivetrain=="RWD","The exported Fiat 133 retains rear-wheel drive")
    var driver = Driver.new("technical")
    scene.input_provider=func() -> Dictionary: return driver.controls(scene.car.powertrain,scene.run.clock,1.0/60.0)
    check(await await_automatic_start(scene),"The exported starter progresses through preparation and alignment without a driver signal")
    check(scene.duel.started,"Both exported lane timers arm on the common tree")
    for i in range(9000):
        await physics_frame
        if scene.duel.finished: break
    check(scene.run.phase=="finished" and scene.opponent_run.phase=="finished","Both exported physical cars complete the actual course")
    check(-scene.car.position.z>=402.336 and -scene.opponent.position.z>=402.336,"The export measures actual 402.336 metre travel in both lanes")
    check(not scene.duel_result.is_empty() and scene.duel_result.entries.player.ticket.et>0.0 and scene.duel_result.entries.rival.ticket.et>0.0,"The exported duel generates two independently measured ET tickets")
    if not scene.duel_result.is_empty():
        print("Export PCK physical duel: ",scene.duel_result)
    scene.input_provider=Callable()
    scene._back_to_garage()
    await process_frame
    await process_frame
    check(current_scene.name=="Main" and session.game.find_car(car_id).owner=="player","The exported duel returns to the same owned unit")
    if not failed: print("PASS: %d exported PCK assertions" % checks)
    quit(1 if failed else 0)
