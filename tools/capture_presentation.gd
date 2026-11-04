extends SceneTree

const DragDriver = preload("res://tests/drag_test_driver.gd")
var output := "/workspace/artifacts/presentation-0.13"

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
    drag._arm()
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
    driver.reaction_delay = -1.0
    driver.shift_hold = 0.0
    driver.controls(drag.car.powertrain,0,1.0/60.0)
    drag._arm()
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
    Engine.time_scale = 1.0
    drag.input_provider = Callable()
    drag._back_to_garage()
    await process_frame
    await process_frame
    quit(0)
