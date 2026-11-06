extends SceneTree

# Production InputEventKey path and real CharacterBody movement. This cannot
# measure a particular keyboard's electrical rollover; key bindings are remappable.
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func key(code: int, pressed: bool) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.pressed = pressed
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func release_keys() -> void:
    for code in [KEY_W,KEY_S,KEY_C,KEY_E,KEY_Q,KEY_SPACE]: key(code,false)

func ticks(count: int) -> void:
    for i in range(count): await physics_frame

func _initialize() -> void:
    call_deferred("run")

func open_strip(mode: String):
    var session = root.get_node("GameSession")
    session.reset()
    session.controls.restore_defaults()
    session.controls.shift_mode = mode
    session.controls.controller.devices.clear()
    session.controls.controller.active_device = -1
    session.game.buy(11)
    for part in session.game.find_car(11).health: session.game.find_car(11).health[part]=100.0
    check(session.start_drag(11,"duel","technical",""),"An owned stock car can enter the real head-to-head strip")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    return current_scene

func leave_strip(scene) -> void:
    release_keys()
    scene._back_to_garage()
    await process_frame
    await process_frame
    await create_timer(0.12,true,false,true).timeout

func await_green(scene) -> bool:
    var countdown := false
    for i in range(3000):
        await physics_frame
        if scene.run.phase=="countdown": countdown=true
        if scene.run.phase=="running":
            check(countdown,"The actual starter completes an amber countdown before green")
            return true
        if scene.run.phase=="invalid" or scene.procedure.phase=="expired": break
    check(false,"The real preparation/alignment path reaches green: %s / %s / %s" % [scene.procedure.phase,scene.run.phase,scene.procedure.reason])
    return false

func run() -> void:
    var scene = await open_strip("manual")
    await ticks(20)
    key(KEY_C,true)
    key(KEY_Q,true)
    key(KEY_Q,false)
    await ticks(30)
    check(scene.car.powertrain.gear==-1,"C + Q selects reverse from neutral through real keyboard events")
    var reverse_start: float = scene.car.position.z
    key(KEY_W,true)
    key(KEY_C,false)
    await ticks(50)
    check(scene.car.powertrain.speed_mps< -0.1 and scene.car.position.z>reverse_start+0.1,"Reverse creates negative longitudinal speed and actual backwards collision-body movement")
    release_keys()
    scene._recover()
    await ticks(15)
    key(KEY_W,true)
    key(KEY_E,true)
    key(KEY_E,false)
    # Event delivery order must not lose a pedal arriving within the same frame.
    key(KEY_C,true)
    await ticks(30)
    check(scene.car.powertrain.gear==1 and scene.car.powertrain.missed_shifts==0,"W held with E then C in the same frame selects first without a spurious rejection")
    check(scene._controls().throttle==1.0 and scene._controls().clutch==1.0,"Actual accelerator and clutch remain simultaneously held during selection")
    check(scene.procedure._warmup_seconds==25.0 and scene.procedure._staging_seconds==30.0,"Native keyboard launch retains the full shipped warming and presentation periods")
    var green: bool = await await_green(scene)
    if green:
        check(scene.car.powertrain.gear==1 and scene.car.powertrain.engine_running,"First gear and a running engine survive physical staging and the countdown")
        check(scene.car.powertrain.clutch_engagement<0.05,"Full-manual clutch remains open while the actual pedal is held at green")
        check(scene.hud.status_label.text.contains("EMBRAGUE"),"A held clutch at green gives a visible release instruction")
        var start_z: float = scene.car.position.z
        key(KEY_C,false)
        await ticks(120)
        check(scene.run.phase=="running" and scene.car.position.z<start_z-1.0 and scene.car.powertrain.speed_mps>1.0,"Releasing only the clutch after green launches the real car with W continuously held")
        check(scene.run.launch_time>=0.0 and scene.run.reaction>=0.0,"Actual beam departure records a nonnegative measured reaction")
        var misses: int = scene.car.powertrain.missed_shifts
        key(KEY_C,true)
        key(KEY_E,true)
        key(KEY_E,false)
        await ticks(35)
        check(scene.car.powertrain.gear==2 and scene.car.powertrain.missed_shifts==misses,"W + C + E upshifts a moving car without requiring accelerator release")
        check(scene._controls().throttle==1.0,"The input pipeline never lifts the driver's accelerator for a raw manual shift")
        key(KEY_C,false)
        await ticks(18)
        key(KEY_C,true)
        key(KEY_Q,true)
        key(KEY_Q,false)
        await ticks(35)
        check(scene.car.powertrain.gear==1 and scene.car.powertrain.missed_shifts==misses,"W + C + Q also downshifts through the production lever path")
    await leave_strip(scene)
    scene = await open_strip("auto_clutch")
    check(scene.procedure._warmup_seconds==25.0,"Assisted native keyboard launch also retains the full 25-second warming period")
    key(KEY_E,true)
    key(KEY_E,false)
    key(KEY_W,true)
    key(KEY_S,true)
    green = await await_green(scene)
    if green:
        check(scene.car.powertrain.shift_mode=="auto_clutch" and scene._controls().clutch==0.0,"The optional auto-clutch mode reaches green without a physical clutch pedal")
        var start_z: float = scene.car.position.z
        key(KEY_S,false)
        await ticks(120)
        check(scene.run.phase=="running" and scene.car.position.z<start_z-1.0 and scene.car.powertrain.speed_mps>1.0,"The disclosed auto-clutch staging hold releases after the actual green and launches the car")
    await leave_strip(scene)
    root.get_node("GameSession").menu_music.set_menu_active(false)
    await ticks(8)
    if not failed: print("PASS: %d keyboard launch and reverse assertions" % checks)
    quit(1 if failed else 0)
