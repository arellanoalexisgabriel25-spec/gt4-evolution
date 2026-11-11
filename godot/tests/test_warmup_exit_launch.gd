extends SceneTree

var checks := 0
var failed := false
func check(ok: bool, detail: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(detail)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    await run_case("manual")
    await run_case("auto_clutch")
    var session = root.get_node("GameSession")
    session.menu_music.set_menu_active(false)
    if not failed: print("PASS: %d moving warmup and real launch assertions" % checks)
    quit(1 if failed else 0)

func run_case(mode: String) -> void:
    var session = root.get_node("GameSession")
    session.reset()
    session.controls.restore_defaults()
    session.controls.shift_mode = mode
    session.game.buy(11)
    for part in session.game.find_car(11).health: session.game.find_car(11).health[part]=100.0
    check(session.start_drag(11,"duel","technical",""),"A healthy owned unit enters the real drag scene")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    var scene = current_scene
    var model = scene.car.powertrain
    var pedals := {"throttle":0.0,"clutch":1.0 if mode=="manual" else 0.0,"brake":1.0,"handbrake":0.0,"steer":0.0}
    scene.input_provider = func() -> Dictionary: return pedals
    check(model.request_shift(1,float(pedals.clutch)),"The driver selects first with the chosen clutch mode")
    for i in range(45): await physics_frame
    pedals.brake=0.0
    pedals.clutch=0.0
    pedals.throttle=0.65
    for frame in range(1500):
        await physics_frame
        if scene.procedure.phase != "burnout": break
    var distance: float = -scene.car.position.z
    check(distance>=35.0 and scene.procedure.phase=="staging","Driving beyond the marked warmup zone physically ends warming and calls staging")
    check(scene.run.phase=="preparation" and scene.run.clock==0.0 and scene.duel_result.is_empty(),"Crossing the warmup boundary does not cancel or start a race")
    check(scene._applied_controls.throttle==pedals.throttle and scene._applied_controls.brake==0.0,"The driver retains the pedals while the moving car is called")
    pedals.throttle=0.0
    pedals.brake=1.0
    pedals.clutch=1.0 if mode=="manual" else 0.0
    for frame in range(1100):
        await physics_frame
        if scene._staged() and not scene.alignment_pending: break
    check(scene._staged() and scene.procedure.phase=="staging","Real braking lets the car stop and the starter align it")
    check(model.engine_running,"Assisted braking leaves the engine running after the moving warmup")
    pedals.throttle=0.65
    for frame in range(900):
        await physics_frame
        if scene.run.phase in ["running","invalid"] or scene.procedure.phase=="expired": break
    check(scene.run.phase=="running" and scene.duel.started,"Both vehicles reach the actual green light")
    var launch_z: float=scene.car.position.z
    pedals.brake=0.0
    pedals.clutch=0.0
    for frame in range(150): await physics_frame
    check(model.speed_mps>1.0 and scene.car.position.z<launch_z-1.0,"Releasing the brake launches the same car after moving in warmup")
    check(scene.run.launch_time>=0.0 and scene.run.reaction>=0.0,"The resulting launch has a measured legal reaction")
    scene.input_provider=Callable()
    scene._back_to_garage()
    await process_frame
    await process_frame
