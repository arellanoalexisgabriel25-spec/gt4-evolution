extends SceneTree

const Economy = preload("res://scripts/economy.gd")
const Catalog = preload("res://scripts/car_catalog.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Handling = preload("res://scripts/handling.gd")
const Model = preload("res://scripts/manual_powertrain.gd")
const Driver = preload("res://tests/drag_test_driver.gd")
const Run = preload("res://scripts/drag_run.gd")
const Visual = preload("res://scripts/car_visual.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func pass_with(config) -> float:
    var model = Model.new()
    model.config = config
    var driver = Driver.new()
    var run = Run.new()
    run.arm(0,0)
    var distance := 0.0
    for i in range(7200):
        var controls: Dictionary = driver.controls(model,run.clock,1.0/60.0)
        model.step(1.0/60.0,controls.throttle,controls.clutch,controls.brake)
        distance += model.speed_mps/60.0
        run.advance(1.0/60.0,distance,model.speed_mps)
        if run.phase in ["finished","invalid"]:
            break
    return run.elapsed if run.phase=="finished" else -1.0

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var game = Economy.new()
    game.seed_demo()
    check(game.cars.size()==13 and game.find_car(1).model=="Mazda MX-5 NA" and game.find_car(10).model=="Nissan Skyline R32","New flagship offers preserve every legacy vehicle ID")
    check(game.find_car(1).price==4100,"Adding national cars does not re-roll the existing used market")
    var ordered: Array = Catalog.market_order(game.cars)
    var times: Array[float] = []
    for index in range(3):
        var car: Dictionary = game.find_car(11+index)
        check(car.model==Catalog.FLAGSHIPS[index] and ordered[index].id==car.id,"The flagship lineup is displayed first without changing persistent IDs")
        check(game.eligible(car) and int(car.price)<Economy.START_BALANCE,"Each flagship is a viable starter with a repair budget left over")
        var healthy: Dictionary = car.duplicate(true)
        for component in healthy.health: healthy.health[component]=100.0
        var config = Config.from_vehicle(healthy)
        check(config.drivetrain=="FWD" and Handling.configuration(healthy).drivetrain=="FWD","Both real driving modes use front-wheel drive for the flagship")
        times.append(pass_with(config))
    check(times.min()>0 and absf(times[0]-times[1])>0.1 and absf(times[1]-times[2])>0.1,"Mass, torque and gearing produce distinct complete quarter-mile times")
    print("Flagship benchmark: 147 %.3f s / Uno %.3f s / Gol %.3f s" % times)
    var old: Dictionary = game.to_dict()
    old.cars = old.cars.slice(0,10)
    var restored = Economy.new()
    check(restored.from_dict(old),"A previous ten-car save remains valid")
    var balance: int = restored.balance
    var first: Dictionary = restored.find_car(1).duplicate(true)
    restored.ensure_flagship_offers()
    restored.ensure_flagship_offers()
    check(restored.cars.size()==13 and restored.balance==balance and restored.find_car(1)==first,"Flagship migration is idempotent and preserves finances and old vehicles")
    var occupied: Dictionary = old.duplicate(true)
    var custom: Dictionary = occupied.cars[0].duplicate(true)
    custom.id=11
    custom.model="Unidad conservada"
    occupied.cars.append(custom)
    check(restored.from_dict(occupied),"An existing nonstandard ID remains loadable")
    restored.ensure_flagship_offers()
    var ids: Dictionary = {}
    for car in restored.cars: ids[car.id]=true
    check(restored.find_car(11).model=="Unidad conservada" and ids.size()==14,"Migration allocates new IDs rather than overwriting an occupied ID")
    var visual = Visual.new()
    visual.model_name = Catalog.FLAGSHIPS[2]
    root.add_child(visual)
    await process_frame
    check(visual.imported_model and visual.wheels.size()==4 and visual.front_pivots.size()==2,"The supplied Gol GLB renders with four independently animatable wheels")
    var triangles := 0
    for count in visual.triangle_counts: triangles += int(count)
    check(triangles==40000 and visual.triangle_counts.min()>0,"Wheel partitioning preserves all 40,000 supplied triangles across body and wheels")
    var box: AABB
    var first_mesh := true
    for mesh in visual.find_children("*","MeshInstance3D",true,false):
        var transformed: AABB = mesh.global_transform*mesh.mesh.get_aabb()
        box = transformed if first_mesh else box.merge(transformed)
        first_mesh = false
    check(box.size.is_equal_approx(Catalog.DATA[Catalog.FLAGSHIPS[2]].size),"The imported visual is normalized to the configured car dimensions")
    visual.update_motion(0.1,15,0.5,0,0,Vector2(30,10))
    check(absf(visual.wheels[0].rotation.x)>absf(visual.wheels[1].rotation.x)*2.9 and absf(visual.front_pivots[0].rotation.y)>0,"Imported wheels display driven-axle slip and steering")
    visual.queue_free()
    await process_frame
    if not failed: print("PASS: %d flagship car assertions" % checks)
    quit(1 if failed else 0)
