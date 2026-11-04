extends SceneTree

var output := "/workspace/artifacts/presentation-0.12"

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
    quit(0)
