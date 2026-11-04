extends SceneTree

const Driver = preload("res://tests/drag_test_driver.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Store = preload("res://scripts/save_store.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks+=1
    if not ok:
        failed=true
        push_error(message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var session = root.get_node("GameSession")
    session.reset()
    session.controls.restore_defaults()
    session.game.buy(13)
    var vehicle: Dictionary = session.game.find_car(13)
    for component in vehicle.health: vehicle.health[component]=100.0
    vehicle.upgrades=["ecu","tires"]
    vehicle.tire_compound="slick"
    var balance: int=session.game.balance
    check(not session.start_drag(13,"unknown") and session.selected_vehicle==0,"Malformed format cannot mutate garage selection")
    check(not session.start_drag(13,"duel","technical","L1") and not session.start_drag(13,"duel","technical","bogus") and session.selected_vehicle==0,"Unknown and restricted classes are rejected before garage selection")
    check(not session.start_drag(13,"practice","technical","1"),"Individual practice cannot masquerade as a class duel")
    change_scene_to_file("res://scenes/main.tscn")
    await process_frame
    await process_frame
    current_scene._change_tab("garaje")
    current_scene.duel_profile="conservative"
    var button: Button
    for node in current_scene.content.find_children("*","Button",true,false):
        if node.text=="DUELO ¼ DE MILLA / FÁBRICA":
            button=node
            break
    var found := button!=null
    if found: button.pressed.emit()
    await process_frame
    await process_frame
    var scene=current_scene
    check(found and scene.name=="QuarterMile" and scene.is_duel,"The real garage entry opens a two-car race")
    check(scene.class_data.get("id")=="1" and scene.class_data.get("minimum_et")==18.0,"Garage class selection carries the reference floor into the physical duel")
    check(scene.opponent!=null and scene.opponent.position.x>0 and scene.car.position.x<0,"Two separate physical cars stage in opposite lanes")
    check(scene.opponent_name=="Akira Sato" and scene.opponent_driver.profile=="conservative","The selected driver's identity and control policy reach the track")
    scene.camera.snap()
    var visible_area := root.get_visible_rect()
    check(visible_area.has_point(scene.camera.unproject_position(scene.car.global_position)) and visible_area.has_point(scene.camera.unproject_position(scene.opponent.global_position)),"The default duel camera frames both staged cars")
    check(scene.car.powertrain.get_script()==scene.opponent.powertrain.get_script(),"Both racers use the same physical drivetrain")
    var prepared=Config.from_vehicle(vehicle)
    check(scene.car.powertrain.config.peak_torque<prepared.peak_torque and scene.car.powertrain.config.tire_compound=="street","The series race excludes installed tuning and slicks")
    check(vehicle.upgrades==["ecu","tires"] and vehicle.tire_compound=="slick","Entering series preserves purchased equipment in the garage")
    var driver=Driver.new()
    scene.input_provider=func() -> Dictionary: return driver.controls(scene.car.powertrain,scene.run.clock,1.0/60.0)
    for i in range(45): await physics_frame
    scene.car.acceleration_clock=5.0
    scene.car.zero_to_hundred=2.0
    scene._arm()
    check(scene.car.acceleration_clock==0.0 and scene.car.zero_to_hundred<0,"Staging movement and waiting cannot contaminate the armed acceleration metric")
    check(scene.run.phase=="countdown" and scene.opponent_run.phase=="countdown" and scene.duel.started,"One start command arms both independent timing beams on the same tree")
    scene.paused=true
    var clock: float=scene.run.clock
    var rival_position: Vector3=scene.opponent.position
    for i in range(10): await physics_frame
    check(scene.run.clock==clock and scene.opponent_run.clock==clock and scene.opponent.position==rival_position,"Pause freezes both cars and both timing systems")
    scene.paused=false
    for i in range(8000):
        await physics_frame
        if scene.duel.finished: break
    var result: Dictionary=scene.duel_result
    check(not result.is_empty() and scene.run.phase=="finished" and scene.opponent_run.phase=="finished","Both physical cars reach the actual finish and produce a complete duel result")
    if not result.is_empty():
        check(result.rules_profile=="argentina_reference" and result.minimum_et==18.0,"The measured duel uses the selected Argentine reference rules")
        check(scene.hud.ticket_label.text.contains("PISO ET 18.00"),"The result exposes the ET floor separately from reaction")
        var a: float=result.entries.player.ticket.total
        var b: float=result.entries.rival.ticket.total
        check(result.winner==("player" if a<b else "rival"),"Winner follows the measured RT plus ET of the two lanes")
        print("Physical duel: player %.3f s / rival %.3f s; winner %s" % [a,b,result.winner])
    check(-scene.opponent.position.z>=402.336 and scene.opponent_driver.shifts_requested>1,"The opponent shifts its gearbox while physically covering the course")
    check(scene.car.zero_to_hundred>0 and scene.hud.power_label.text.contains("0–100"),"The HUD reports the player's measured acceleration metric")
    check(not session.career.stock_drag_records.best(13).is_empty() and session.career.drag_records.best(13).is_empty(),"Series records remain separate from prepared/legacy practice times")
    var decoded: Dictionary=Store.decode(Store.encode(session.game,session.career))
    check(decoded.error=="" and not decoded.career.stock_drag_records.best(13).is_empty(),"Series records survive real JSON serialization")
    var legacy: Dictionary=session.career.to_dict()
    legacy.erase("stock_drag_records")
    check(decoded.career.from_dict(legacy) and decoded.career.stock_drag_records.best(13).is_empty(),"Previous saves without series records remain valid")
    check(session.game.balance==balance and scene.hud.ticket_label.text.contains("TOTAL"),"A free exhibition reports both arrival times without inventing prizes")
    scene._recover()
    check(scene.duel_result.is_empty() and scene.opponent_run.phase=="preparation" and absf(scene.opponent.position.z)<0.01,"Retry resets both lanes and cannot reuse the previous result")
    driver.reaction_delay=-1.0
    driver.shift_hold=0.0
    driver.controls(scene.car.powertrain,0,1.0/60.0)
    scene._arm()
    for i in range(8000):
        await physics_frame
        if scene.duel.finished: break
    check(scene.run.reason=="LARGADA EN FALSO" and scene.duel_result.get("winner")=="rival","A real false start loses the duel while the other car completes its lane")
    check(scene.strip.lamps[4].emission_energy_multiplier>1.0 and scene.strip.opponent_lamps[3].emission_energy_multiplier>1.0,"A false start lights only the player's red while the rival receives its own green")
    check(scene.duel_result.entries.player.ticket.is_empty(),"Disqualification does not fabricate a finish ticket")
    scene.input_provider=Callable()
    scene._back_to_garage()
    await process_frame
    await process_frame
    check(current_scene.name=="Main" and session.game.balance==balance,"Returning settles wear without duplicating a result or charging entry")
    if not failed: print("PASS: %d physical drag duel assertions" % checks)
    quit(1 if failed else 0)
