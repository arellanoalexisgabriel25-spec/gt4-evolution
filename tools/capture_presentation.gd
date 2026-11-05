extends SceneTree

const DragDriver = preload("res://tests/drag_test_driver.gd")
var output := "/workspace/artifacts/presentation-0.22"
var capture_heat_done := false

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if not args.is_empty():
        output = args[0]
    DirAccess.make_dir_recursive_absolute(output)
    call_deferred("run")

func picture(name: String) -> void:
    for i in range(6):
        await process_frame
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    var error := image.save_png(output.path_join(name+".png"))
    if error != OK:
        push_error("Failed screenshot: " + name)
        quit(1)
    print("Captured ",name," ",image.get_size())

func settle_drag(drag) -> void:
    var active: bool = drag.is_physics_processing()
    drag.set_physics_process(true)
    for i in range(45): await physics_frame
    drag.set_physics_process(active)

func arm_drag(drag) -> bool:
    var armed: bool = await DragDriver.await_automatic_start(drag)
    if not armed or drag.run.phase!="countdown":
        print("Capture start failure: run=",drag.run.phase," / procedure=",drag.procedure.phase," / clock=",drag.run.clock)
        push_error("Cannot capture an unstaged race: "+str(drag.message))
        quit(1)
        return false
    return true

func burnout_controls(drag) -> Dictionary:
    var model = drag.car.powertrain
    if drag.procedure.phase != "burnout" or capture_heat_done:
        return {"throttle":0.0,"clutch":1.0,"brake":1.0,"handbrake":0.0,"steer":0.0}
    if model.gear == 0 and model.shift_timer <= 0.0:
        model.shift(1,1.0)
    var preloading: bool = drag.procedure.phase_elapsed<1.5
    return {"throttle":0.75 if preloading else 1.0,"clutch":1.0 if preloading else 0.0,"brake":0.0,"handbrake":1.0,"steer":0.0}

func run() -> void:
    if DisplayServer.get_name() == "headless":
        push_error("Presentation capture requires a rendered display, not --headless.")
        quit(1)
        return
    var session = root.get_node("GameSession")
    session.reset()
    change_scene_to_file("res://scenes/main.tscn")
    await process_frame
    await process_frame
    await picture("01-home")
    if not session.menu_music.player.playing or session.menu_music.player.stream.loop:
        push_error("Menu playlist did not start its real playback.")
        quit(1)
        return
    current_scene._change_tab("mercado")
    await picture("02-dealer")
    session.game.buy(1)
    current_scene._change_tab("garaje")
    await picture("03-garage")
    current_scene._change_tab("ajustes")
    await picture("04-settings")
    session.start_driving(1)
    change_scene_to_file("res://scenes/driving.tscn")
    await process_frame
    await process_frame
    Input.action_press("evo_accelerate")
    for i in range(150):
        await physics_frame
    Input.action_release("evo_accelerate")
    if session.menu_music.player.playing or session.menu_music.gain>0.001:
        push_error("Menu music did not fade to silence in the driving scene.")
        quit(1)
        return
    # Freeze a real driven instant so the camera comparisons share a location.
    current_scene.set_physics_process(false)
    for mode in range(4):
        current_scene.camera.mode = mode
        current_scene.camera.snap()
        current_scene._refresh_hud()
        await picture("0%d-camera-%d" % [mode+5,mode])
    current_scene.camera.mode = 0
    current_scene.camera.snap()
    current_scene.camera.look_back = true
    current_scene.camera.snap()
    current_scene._refresh_hud()
    await picture("09-look-back")
    current_scene._back_to_garage()
    await process_frame
    await process_frame
    session.start_driving(1,"race")
    change_scene_to_file("res://scenes/driving.tscn")
    await process_frame
    await process_frame
    await picture("10-race-grid")
    current_scene._back_to_garage()
    await process_frame
    await process_frame
    session.start_drag(1)
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    await settle_drag(current_scene)
    await picture("11-drag-staging")
    var drag = current_scene
    drag.paused = true
    await physics_frame
    await physics_frame
    if not drag.engine_audio.stream_paused:
        push_error("Rendered audio playback did not pause with the powertrain.")
        quit(1)
        return
    drag.paused = false
    var driver = DragDriver.new()
    drag.input_provider = func() -> Dictionary: return driver.controls(drag.car.powertrain,drag.run.clock,drag.get_physics_process_delta_time())
    driver.controls(drag.car.powertrain,0,1.0/60.0)
    if not await arm_drag(drag): return
    Engine.time_scale = 3.0
    while drag.run.clock < 1.0:
        await physics_frame
    drag.set_physics_process(false)
    drag._refresh_hud()
    await picture("12-drag-tree")
    drag.set_physics_process(true)
    while -drag.car.position.z < 140 and drag.run.phase not in ["finished","invalid"]:
        await physics_frame
    drag.set_physics_process(false)
    drag.camera.snap()
    drag._refresh_hud()
    await picture("13-drag-driving")
    drag.camera.mode = 1
    drag.camera.snap()
    await picture("14-drag-close")
    drag.set_physics_process(true)
    while drag.run.phase not in ["finished","invalid"]:
        await physics_frame
    if drag.run.phase != "finished":
        push_error("The rendered manual quarter-mile pass did not finish: "+drag.run.reason)
        quit(1)
        return
    drag.set_physics_process(false)
    drag._refresh_hud()
    await picture("15-drag-ticket")
    drag._recover()
    # The procedure starts itself; do not advance an already-ready retry before
    # configuring the short fixture window and observing its common tree.
    driver.reaction_delay = 0.12
    driver.shift_hold = 0.0
    if not await arm_drag(drag): return
    driver.reaction_delay = -1.0
    drag.set_physics_process(true)
    while drag.run.phase not in ["finished","invalid"]:
        await physics_frame
    if drag.run.reason != "LARGADA EN FALSO":
        push_error("The rendered early launch did not trigger the false-start rule.")
        quit(1)
        return
    drag.set_physics_process(false)
    drag._refresh_hud()
    await picture("16-drag-red-light")
    var pause_button := InputEventJoypadButton.new()
    pause_button.button_index = JOY_BUTTON_BACK
    pause_button.device = 0
    pause_button.pressed = true
    Input.parse_input_event(pause_button)
    Input.flush_buffered_events()
    await process_frame
    await process_frame
    if not drag.paused or not drag.pause_menu.visible:
        push_error("Controller pause did not open its navigable overlay.")
        quit(1)
        return
    await picture("17-controller-pause")
    pause_button.pressed = false
    Input.parse_input_event(pause_button)
    Input.flush_buffered_events()
    Engine.time_scale = 1.0
    drag.input_provider = Callable()
    drag._back_to_garage()
    await process_frame
    await process_frame
    current_scene._change_tab("inicio")
    for entry in [["Fiat 147 Vivace","18-147-showroom"],["Fiat Uno Fire 3 puertas","19-uno-showroom"],["Volkswagen Gol Power 3 puertas","20-gol-showroom"],["Fiat 128 Súper Europa 1.5","28-128-super-showroom"],["Fiat 133","29-133-showroom"],["Fiat 128 estándar","30-128-standard-showroom"],["Fiat 125","34-125-showroom"],["Fiat Duna","35-duna-showroom"],["Fiat Cronos","36-cronos-showroom"],["Fiat Siena","37-siena-showroom"],["Fiat Punto","38-punto-showroom"],["Fiat Regatta","39-regatta-showroom"],["Fiat 500 Sport","40-500-showroom"],["Chevrolet Corsa 5 puertas","51-corsa-showroom"],["Volkswagen Amarok","52-amarok-showroom"],["Ford Ranger cabina simple","53-ranger-showroom"],["Ford EcoSport","54-ecosport-showroom"],["Toyota Corolla","55-corolla-showroom"],["Fiat Palio 5 puertas","56-palio-showroom"]]:
        current_scene._feature(entry[0])
        await picture(entry[1])
    current_scene._change_tab("taller")
    await picture("21-tire-workshop")
    session.game.buy(13)
    if not session.start_drag(13):
        push_error("Could not enter the supplied Gol from the actual garage.")
        quit(1)
        return
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    drag = current_scene
    await settle_drag(drag)
    drag.set_physics_process(false)
    drag.camera.mode = 1
    drag.camera.snap()
    await picture("22-gol-staging")
    var gol_driver := DragDriver.new()
    drag.input_provider = func() -> Dictionary: return gol_driver.controls(drag.car.powertrain,drag.run.clock,drag.get_physics_process_delta_time())
    gol_driver.controls(drag.car.powertrain,0,1.0/60.0)
    if not await arm_drag(drag): return
    drag.set_physics_process(true)
    Engine.time_scale = 3.0
    while -drag.car.position.z<140 and drag.run.phase not in ["finished","invalid"]:
        await physics_frame
    if drag.run.phase!="running":
        push_error("The supplied Gol failed its rendered manual launch.")
        quit(1)
        return
    drag.set_physics_process(false)
    drag.camera.look_input = Vector2(0.8,0)
    drag.camera.snap()
    drag._refresh_hud()
    await picture("24-gol-driving")
    Engine.time_scale = 1.0
    drag.input_provider = Callable()
    drag.car.recover(Vector3(-3.5,0.55,-704))
    drag.car.powertrain.speed_mps = 25
    drag.car.powertrain.wheel_omega = 25/drag.car.powertrain.config.wheel_radius
    for i in range(30):
        drag.car.drive_manual(1.0/60.0,{"throttle":0.0,"clutch":1.0,"brake":0.0},true)
        if drag.car.damage.impacts>0:
            break
    if drag.car.damage.impacts==0:
        push_error("The rendered Gol did not collide with the existing end barrier.")
        quit(1)
        return
    drag.run.invalidate("IMPACTO EN LA ESCAPATORIA")
    drag.camera.look_input = Vector2.ZERO
    drag.camera.snap()
    drag._refresh_hud()
    await picture("23-impact-damage")
    drag._back_to_garage()
    await process_frame
    await process_frame
    session.reset()
    session.game.buy(13)
    for component in session.game.find_car(13)["health"]:
        session.game.find_car(13)["health"][component] = 100.0
    session.start_drag(13,"duel","technical","1")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    drag = current_scene
    await settle_drag(drag)
    await picture("25-duel-staging")
    var duel_driver := DragDriver.new()
    drag.input_provider = func() -> Dictionary: return duel_driver.controls(drag.car.powertrain,drag.run.clock,drag.get_physics_process_delta_time())
    duel_driver.controls(drag.car.powertrain,0,1.0/60.0)
    if not await arm_drag(drag): return
    Engine.time_scale = 3.0
    while -drag.car.position.z<140 and not drag.duel.finished:
        await physics_frame
    drag.set_physics_process(false)
    drag.camera.snap()
    drag._refresh_hud()
    await picture("26-duel-driving")
    drag.set_physics_process(true)
    while not drag.duel.finished:
        await physics_frame
    drag.set_physics_process(false)
    if drag.run.phase!="finished" or drag.opponent_run.phase!="finished":
        push_error("The rendered two-car race did not produce two physical arrivals.")
        quit(1)
        return
    drag._refresh_hud()
    await picture("27-duel-result")
    Engine.time_scale = 1.0
    drag.input_provider = Callable()
    drag._back_to_garage()
    await process_frame
    await process_frame
    session.reset()
    session.game.buy(15)
    for component in session.game.find_car(15)["health"]:
        session.game.find_car(15)["health"][component] = 100.0
    session.start_drag(15,"duel","technical","1")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    drag = current_scene
    var classic_driver := DragDriver.new()
    drag.input_provider = func() -> Dictionary: return classic_driver.controls(drag.car.powertrain,drag.run.clock,drag.get_physics_process_delta_time())
    await settle_drag(drag)
    await picture("31-133-duel-staging")
    if not await arm_drag(drag): return
    Engine.time_scale = 3.0
    while -drag.car.position.z<100 and not drag.duel.finished:
        await physics_frame
    drag.set_physics_process(false)
    drag.camera.snap()
    drag._refresh_hud()
    await picture("32-133-duel-driving")
    drag.set_physics_process(true)
    while not drag.duel.finished:
        await physics_frame
    drag.set_physics_process(false)
    if drag.run.phase!="finished" or drag.opponent_run.phase!="finished" or drag.car.powertrain.config.drivetrain!="RWD":
        push_error("The supplied rear-drive 133 did not complete a two-car physical race.")
        quit(1)
        return
    drag._refresh_hud()
    await picture("33-133-duel-result")
    Engine.time_scale = 1.0
    drag.input_provider = Callable()
    drag._back_to_garage()
    await process_frame
    await process_frame
    session.reset()
    session.game.buy(23)
    for component in session.game.find_car(23)["health"]:
        session.game.find_car(23)["health"][component] = 100.0
    session.start_drag(23,"duel","technical","","Fiat 133")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    drag = current_scene
    var mixed_driver := DragDriver.new()
    drag.input_provider = func() -> Dictionary: return mixed_driver.controls(drag.car.powertrain,drag.run.clock,drag.get_physics_process_delta_time())
    await settle_drag(drag)
    await picture("41-mixed-duel-staging")
    if not await arm_drag(drag): return
    Engine.time_scale = 3.0
    while -drag.car.position.z<60 and not drag.duel.finished:
        await physics_frame
    drag.set_physics_process(false)
    drag.camera.snap()
    drag._refresh_hud()
    await picture("42-mixed-duel-driving")
    drag.set_physics_process(true)
    while not drag.duel.finished:
        await physics_frame
    drag.set_physics_process(false)
    if drag.run.phase!="finished" or drag.opponent_run.phase!="finished" or drag.opponent.model_name!="Fiat 133":
        push_error("The mixed-model exported demonstration did not produce two real arrivals.")
        quit(1)
        return
    drag._refresh_hud()
    await picture("43-mixed-duel-result")
    Engine.time_scale = 1.0
    drag.input_provider = Callable()
    drag._back_to_garage()
    await process_frame
    await process_frame
    # Capture actual preparation contact heat and the marshal's subsequent
    # blue-light call. No tire-temperature helper or fake timing ticket is used.
    session.reset()
    session.game.buy(23)
    for component in session.game.find_car(23)["health"]:
        session.game.find_car(23)["health"][component] = 100.0
    session.start_drag(23,"duel","technical","","Fiat 133")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    drag = current_scene
    drag.input_provider = func() -> Dictionary: return burnout_controls(drag)
    Engine.time_scale = 3.0
    var cold_front: float = drag.car.powertrain.axles.temperatures.x
    var heated := false
    for frame in range(500):
        await physics_frame
        if drag.procedure.phase != "burnout" or drag.procedure.phase_elapsed>6.6: break
        if drag.car.powertrain.axles.temperatures.x>cold_front+15.0 and drag.car.powertrain.axles.slip_power>1000.0:
            heated = true
            break
    if not heated or drag.run.clock != 0.0:
        print("Burnout capture evidence: ",{"phase":drag.procedure.phase,"elapsed":drag.procedure.phase_elapsed,"temperatures":drag.car.powertrain.axles.temperatures,"slip_power":drag.car.powertrain.axles.slip_power,"distance":-drag.car.position.z,"speed":drag.car.powertrain.speed_mps,"rpm":drag.car.powertrain.rpm,"gear":drag.car.powertrain.gear,"clock":drag.run.clock})
        push_error("The rendered burnout did not create actual tire contact heat before timing.")
        quit(1)
        return
    drag.set_physics_process(false)
    drag.camera.mode = 1
    drag.camera.look_input = Vector2(0.7,0.0)
    drag.camera.snap()
    drag._refresh_hud()
    print("Rendered burnout temperature: ",cold_front," -> ",drag.car.powertrain.axles.temperatures.x,"; slip power ",drag.car.powertrain.axles.slip_power)
    await picture("44-burnout-preparation")
    capture_heat_done = true
    drag.set_physics_process(true)
    for frame in range(800):
        await physics_frame
        if drag.procedure.phase != "burnout": break
    if drag.procedure.phase != "staging" or drag.run.phase != "preparation":
        push_error("The starter did not issue a blue-light alignment call before timing.")
        quit(1)
        return
    drag.set_physics_process(false)
    drag.camera.look_input = Vector2.ZERO
    drag.camera.snap()
    drag._refresh_hud()
    await picture("45-starter-call")
    drag.paused = true
    drag._refresh_hud()
    await picture("46-paused-telemetry")
    Engine.time_scale = 1.0
    drag.input_provider = Callable()
    drag._back_to_garage()
    await process_frame
    await process_frame
    session.reset()
    session.game.buy(11)
    session.menu_tab = "garaje"
    change_scene_to_file("res://scenes/main.tscn")
    await process_frame
    await process_frame
    await process_frame
    # Scroll the actual owned-car card into view, as the player can do.
    var garage_scroll: ScrollContainer = current_scene.content.get_parent()
    for label in current_scene.content.find_children("*","Label",true,false):
        if label.text.begins_with("FICHA PROVISIONAL"):
            garage_scroll.scroll_vertical += maxi(0,int(label.global_position.y-garage_scroll.global_position.y-85.0))
            break
    await picture("47-reference-147-garage")
    current_scene._change_tab("tuning")
    await picture("48-tuning-system")
    current_scene._change_tab("carrera")
    await picture("49-career-system")
    current_scene._change_tab("historial")
    await picture("50-transactions-system")
    session.menu_music.select_track("butakera")
    current_scene._change_tab("ajustes")
    await picture("57-playlist-settings")
    if not session.menu_music.player.playing or session.menu_music.track_id()!="butakera":
        push_error("The new Ogg playlist track did not play in the actual menu.")
        quit(1)
        return
    session.reset()
    session.game.buy(25)
    for component in session.game.find_car(25).health:
        session.game.find_car(25).health[component]=100.0
    session.start_drag(25,"duel","technical","","Chevrolet Corsa 5 puertas")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    drag = current_scene
    drag.set_physics_process(false)
    await settle_drag(drag)
    drag._refresh_hud()
    drag.camera.snap()
    await picture("58-night-pickup-staging")
    driver = DragDriver.new()
    driver.launch_rpm = 2400.0
    drag.input_provider=func() -> Dictionary: return driver.controls(drag.car.powertrain,drag.run.clock,1.0/60.0)
    if not await arm_drag(drag): return
    drag.set_physics_process(true)
    Engine.time_scale = 6.0
    for frame in range(5000):
        await physics_frame
        if drag.run.elapsed>6.0: break
    drag.set_physics_process(false)
    drag.camera.snap()
    drag._refresh_hud()
    await picture("59-night-pickup-driving")
    drag.set_physics_process(true)
    for frame in range(7000):
        await physics_frame
        if drag.duel.finished: break
    if drag.run.phase!="finished" or drag.opponent_run.phase!="finished":
        push_error("The new pickup and Corsa did not complete the measured night duel.")
        quit(1)
        return
    drag.set_physics_process(false)
    drag._refresh_hud()
    await picture("60-night-pickup-result")
    Engine.time_scale = 1.0
    drag.input_provider=Callable()
    drag._back_to_garage()
    await process_frame
    await process_frame
    session.menu_music.set_menu_active(false)
    for i in range(20):
        await process_frame
    quit(0)
