extends SceneTree

const Preparation = preload("res://tests/drag_test_driver.gd")

var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func button(code: int, pressed: bool) -> void:
    var event := InputEventJoypadButton.new()
    event.device = 0
    event.button_index = code
    event.pressed = pressed
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func axis(code: int, value: float) -> void:
    var event := InputEventJoypadMotion.new()
    event.device = 0
    event.axis = code
    event.axis_value = value
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func frames() -> void:
    await process_frame
    await process_frame

func tap(code: int) -> void:
    button(code,true)
    await frames()
    button(code,false)
    await frames()

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var session = root.get_node("GameSession")
    session.reset()
    session.controls.restore_defaults()
    session.controls.controller.devices.clear()
    session.controls.controller.active_device = -1
    change_scene_to_file("res://scenes/main.tscn")
    await frames()
    var menu = current_scene
    var settings_path := "user://controller-ui-%d.json" % Time.get_ticks_usec()
    menu.controls_path = settings_path
    await tap(JOY_BUTTON_RIGHT_SHOULDER)
    check(menu.current_tab=="garaje","Controller RB changes the actual main navigation tab")
    await tap(JOY_BUTTON_RIGHT_SHOULDER)
    check(menu.current_tab=="mercado" and menu.nav_buttons["mercado"].has_focus(),"Tab changes retain visible, predictable controller focus")
    await tap(JOY_BUTTON_DPAD_RIGHT)
    var focused := root.gui_get_focus_owner()
    check(focused!=null and menu.content.is_ancestor_of(focused),"D-pad moves from the sidebar into the real dealership controls")
    var inspection: Button
    for node in menu.content.find_children("*","Button",true,false):
        if node.text.begins_with("INSPECCIÓN") and node.get_parent().get_parent().get_parent().get_meta("vehicle_id",0)==1:
            inspection = node
            break
    var before: int = session.game.balance
    inspection.grab_focus()
    button(JOY_BUTTON_A,true)
    await frames()
    button(JOY_BUTTON_A,true)
    await frames()
    check(session.game.balance==before-200 and session.game.find_car(1).inspected,"A confirms the inspection once; duplicate held events cannot double-debit")
    button(JOY_BUTTON_A,false)
    await frames()
    var buy: Button
    for node in menu.content.find_children("*","Button",true,false):
        if node.text=="COMPRAR" and node.get_parent().get_parent().get_parent().get_meta("vehicle_id",0)==1:
            buy = node
            break
    buy.grab_focus()
    await tap(JOY_BUTTON_A)
    check(session.game.find_car(1).owner=="player","Controller confirmation buys the actual persistent car")
    menu._change_tab("ajustes")
    await frames()
    var volume = menu.content.find_children("*","HSlider",true,false)[0]
    volume.grab_focus()
    var old_volume: float = session.controls.music_volume
    await tap(JOY_BUTTON_DPAD_RIGHT)
    check(session.controls.music_volume>old_volume,"D-pad adjusts and persists the real menu music slider")
    var choice = menu.content.find_children("*","OptionButton",true,false)[0]
    choice.grab_focus()
    await tap(JOY_BUTTON_A)
    check(session.controls.analog_clutch,"The controller can choose analog clutch directly from Settings")
    var tcs = menu.content.find_children("*","CheckButton",true,false)[0]
    tcs.grab_focus()
    await tap(JOY_BUTTON_A)
    check(session.controls.traction_control,"Controller confirmation can toggle the actual traction assistance setting")
    await tap(JOY_BUTTON_B)
    check(menu.current_tab=="inicio","Controller B returns from settings to the home")
    menu._change_tab("garaje")
    for node in menu.content.find_children("*","Button",true,false):
        if node.text=="¼ DE MILLA / MANUAL":
            node.grab_focus()
            break
    await tap(JOY_BUTTON_A)
    check(current_scene.name=="QuarterMile" and current_scene.car.powertrain.gear==0,"A enters the quarter mile without leaking its menu press into a first-gear change")
    var scene = current_scene
    check(scene.car.powertrain.traction_control,"The chosen TCS preference reaches the real manual powertrain")
    axis(JOY_AXIS_TRIGGER_LEFT,1)
    await tap(JOY_BUTTON_A)
    check(scene.car.powertrain.gear==1,"Analog clutch plus controller A selects first gear")
    axis(JOY_AXIS_TRIGGER_RIGHT,0.65)
    for i in range(25):
        await physics_frame
    var controls: Dictionary = session.controls.read_controls(true)
    check(controls.throttle>0.5 and controls.brake==0 and session.controls.clutch_input()>0.99,"RT and analog LT provide independent accelerator and clutch without phantom braking")
    check(session.controls.read_controls(false).brake>0.99,"The same LT still brakes in the older automatic circuit mode")
    await tap(JOY_BUTTON_START)
    check(scene.paused and scene.pause_menu.visible and scene.run.phase=="preparation" and scene.procedure.phase=="burnout","Controller Start pauses preparation instead of overriding the starter")
    var preparation_clock: float = scene.procedure.elapsed
    for i in range(10): await physics_frame
    check(scene.procedure.elapsed==preparation_clock,"Controller pause also freezes the preparation deadline")
    await tap(JOY_BUTTON_B)
    check(not scene.paused and not scene.pause_menu.visible,"Controller B resumes the authorized preparation")
    check(await Preparation.await_automatic_start(scene),"The starter automatically arms after the real controller gear and clutch remain ready")
    check(scene.run.phase=="countdown","Held controller accelerator and clutch do not require a manual tree command")
    await tap(JOY_BUTTON_BACK)
    check(scene.paused and scene.pause_menu.visible,"Controller Select opens the full pause menu")
    var clock: float = scene.run.clock
    for i in range(10):
        await physics_frame
    check(scene.run.clock==clock,"Controller pause freezes timing and vehicle dynamics")
    await tap(JOY_BUTTON_B)
    check(not scene.paused and not scene.pause_menu.visible,"Controller B immediately resumes without swallowing the next input")
    Input.joy_connection_changed.emit(0,false)
    await frames()
    check(scene.paused and scene.controller_lost and scene.pause_menu.heading.text.contains("DESCONECTADO"),"Disconnecting the active device automatically pauses and explains the reason")
    check(session.controls.controller.selected()<0 and session.controls.read_controls(true).throttle==0,"Disconnect clears held trigger state instead of retaining acceleration")
    scene.pause_menu._resume()
    await tap(JOY_BUTTON_BACK)
    var leave_button: Button
    for node in scene.pause_menu.find_children("*","Button",true,false):
        if node.text=="VOLVER AL GARAJE":
            leave_button = node
    leave_button.grab_focus()
    await tap(JOY_BUTTON_A)
    check(current_scene.name=="Main" and current_scene.current_tab=="garaje","The whole drive/garage loop can be completed with a controller")
    check(session.game.find_car(1).owner=="player" and session.menu_music.active,"Returning preserves ownership and reactivates menu music")
    DirAccess.remove_absolute(settings_path)
    if not failed:
        print("PASS: %d controller navigation assertions" % checks)
    quit(1 if failed else 0)
