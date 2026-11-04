extends SceneTree

const Driver = preload("res://tests/drag_test_driver.gd")
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

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var session = root.get_node("GameSession")
    session.reset()
    session.controls.restore_defaults()
    check(not session.start_drag(1),"Session rejects unowned quarter-mile entries")
    session.game.buy(1)
    var balance: int = session.game.balance
    change_scene_to_file("res://scenes/main.tscn")
    await process_frame
    await process_frame
    current_scene._change_tab("garaje")
    var found := false
    for button in current_scene.content.find_children("*","Button",true,false):
        if button.text == "¼ DE MILLA / MANUAL":
            found = true
            button.pressed.emit()
            break
    await process_frame
    await process_frame
    check(found and current_scene.name=="QuarterMile","The real garage button opens the selected vehicle in the new strip")
    var scene = current_scene
    check(scene.enabled and scene.car.model_name==session.game.find_car(1).model,"The mode uses the owned persistent unit, not a separate demo car")
    check(scene.car.powertrain.gear==0 and scene.hud.gear_label.text=="N" and scene.hud.speed_label.text=="0","The staged car starts visibly in neutral at zero speed")
    key(KEY_E,true)
    key(KEY_E,false)
    check(scene.car.powertrain.gear==0 and scene.car.powertrain.missed_shifts==1,"A real shift key without clutch is rejected and recorded")
    await physics_frame
    await physics_frame
    check(scene.hud.status_label.text.contains("EMBRAGUE") or scene.hud.status_label.text.contains("embrague"),"Rejected first-gear input explains the clutch requirement visibly during staging")
    key(KEY_C,true)
    for i in range(15):
        await physics_frame
    key(KEY_E,true)
    key(KEY_E,false)
    check(scene.car.powertrain.gear==1,"Clutch plus the physical shift key selects first gear")
    key(KEY_ENTER,true)
    key(KEY_ENTER,false)
    check(scene.run.phase=="countdown","Enter starts an armed tree with the real staged vehicle")
    var driver = Driver.new()
    scene.input_provider = func() -> Dictionary: return driver.controls(scene.car.powertrain,scene.run.clock,1.0/60.0)
    key(KEY_C,false)
    scene.paused = true
    var clock: float = scene.run.clock
    var rpm: float = scene.car.powertrain.rpm
    for i in range(15):
        await physics_frame
    check(scene.run.clock==clock and scene.car.powertrain.rpm==rpm,"Pause freezes the physical powertrain and the staging clock together")
    check(scene.hud.status_label.text.begins_with("PAUSA"),"The driver can see the paused state in the actual HUD")
    scene.paused = false
    for i in range(5000):
        await physics_frame
        if scene.run.phase in ["finished","invalid"]:
            break
    check(scene.run.phase=="finished","A reproducible clutch-driven pass reaches the actual physical finish")
    if scene.run.phase=="finished":
        var ticket: Dictionary = scene.run.report()
        check(-scene.car.position.z>=402.336 and ticket.et>10 and ticket.et<35,"Recorded time follows more than 402 metres of actual collision-body movement")
        check(session.career.drag_records.best(1)==ticket,"A valid arrival updates the selected garage unit's persistent record")
        check(scene.hud.ticket_panel.visible and scene.hud.ticket_label.text.contains("TICKET"),"Measured arrival shows a real timing ticket in the HUD")
        check(scene.hud.wear_label.text.contains("Caja 0.0") and scene.hud.wear_label.text.contains("DESGASTE"),"The ticket exposes actual stress from the pass, including the rejected change")
        check(ticket.reaction>=0 and ticket.sixty_ft<ticket.eighth and ticket.eighth<ticket.et,"Reaction and intermediate beams remain ordered in the complete 3D run")
        print("Physical quarter-mile evidence: ",ticket," mileage=",scene.car.distance_m," wear=",scene.car.powertrain.wear)
    for i in range(420):
        await physics_frame
    check(scene.car.powertrain.speed_mps<0.5,"Automatic finish braking stops safely within the physical runoff")
    check(session.game.balance==balance,"A completed free run cannot accidentally create a circuit prize or debit")
    scene._recover()
    check(scene.run.phase=="preparation" and scene.car.powertrain.gear==0,"Recovery creates a new staging attempt in neutral")
    var health: Dictionary = session.game.find_car(1).health.duplicate(true)
    var distance: float = scene.garage.settled_distance
    scene._recover()
    check(session.game.find_car(1).health==health and scene.garage.settled_distance==distance,"Repeated recovery cannot erase or duplicate already settled mechanical use")
    scene.input_provider = Callable()
    scene._back_to_garage()
    scene._back_to_garage()
    await process_frame
    await process_frame
    check(current_scene.name=="Main" and current_scene.current_tab=="garaje","Leaving returns to the actual garage without recreating ownership")
    check(session.selected_vehicle==0 and session.game.balance==balance,"Leaving twice clears selection without any second economy transaction")
    if not failed:
        print("PASS: %d drag integration assertions" % checks)
    quit(1 if failed else 0)
