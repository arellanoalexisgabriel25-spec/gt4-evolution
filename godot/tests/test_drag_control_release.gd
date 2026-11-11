extends SceneTree

var checks := 0
var failed := false

func check(ok: bool, why: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(why)

func ticks(count: int) -> void:
    for i in range(count): await physics_frame

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var session = root.get_node("GameSession")
    session.reset()
    session.controls.restore_defaults()
    session.controls.shift_mode = "auto_clutch"
    session.game.buy(11)
    for part in session.game.find_car(11).health: session.game.find_car(11).health[part] = 100.0
    check(session.start_drag(11,"duel","technical",""),"Owned vehicle enters physical drag scene")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    var scene = current_scene
    var model = scene.car.powertrain
    var pedals := {"throttle":0.0,"clutch":0.0,"brake":1.0,"handbrake":0.0,"steer":0.0}
    scene.input_provider = func() -> Dictionary: return pedals
    scene.procedure.configure(0.2,30.0,1.5)
    for frame in range(40):
        await physics_frame
        if scene.alignment_pending: break
    check(scene.alignment_pending and scene.procedure.phase=="staging","Blue call requests placement after warmup")
    pedals.brake = 0.0
    pedals.throttle = 0.35
    await ticks(1)
    check(is_equal_approx(scene._applied_controls.throttle,0.35) and scene._applied_controls.brake==0.0,"Automatic placement never replaces the accelerator or brake")
    pedals.throttle = 0.0
    pedals.brake = 1.0
    await ticks(80)
    check(scene.procedure.phase=="staging" and not scene.alignment_pending,"Blue call completes alignment")
    check(model.request_shift(-1,0.0),"Assisted mode accepts reverse selection")
    await ticks(40)
    var origin: float = scene.car.position.z
    pedals.brake = 0.0
    pedals.throttle = 0.45
    await ticks(120)
    check(scene._applied_controls.brake==0.0 and scene._applied_controls.clutch==0.0,"Assisted staging preserves the driver's pedals")
    check(model.gear==-1 and model.speed_mps< -0.2 and scene.car.position.z>origin+0.2,"Reverse physically moves after the blue call in assisted mode")
    pedals.brake=1.0
    pedals.throttle=0.0
    await ticks(160)
    check(model.engine_running and model.rpm>420.0,"Assisted braking while reversing disengages in time to prevent a stall")
    check(model.request_shift(1,0.0),"Reverse can shift to neutral after stopping")
    await ticks(45)
    check(model.request_shift(1,0.0),"First gear can be selected")
    await ticks(45)
    scene.run.invalidate("TEST FALSE START")
    origin = scene.car.position.z
    pedals.brake=0.0
    pedals.throttle=0.45
    await ticks(150)
    check(scene._applied_controls.brake==0.0 and scene._applied_controls.throttle==0.45,"A canceled duel does not override the driver's pedals")
    print("Invalid-run state: speed=",model.speed_mps," displacement=",scene.car.position.z-origin," gear=",model.gear," rpm=",model.rpm," engine=",model.engine_running," phase=",scene.procedure.phase," clutch=",model.clutch_engagement)
    check(model.speed_mps>0.2 and scene.car.position.z<origin-0.2,"The player can still drive after a false start")
    check(scene.run.phase=="invalid" and scene.run.report().is_empty(),"Driving away never turns a false start into a valid result")
    scene.input_provider=Callable()
    scene._back_to_garage()
    await process_frame
    session.menu_music.set_menu_active(false)
    if not failed: print("PASS: %d assisted reverse and invalid-run control assertions" % checks)
    quit(1 if failed else 0)
