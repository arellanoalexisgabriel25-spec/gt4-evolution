extends SceneTree
const Driver = preload("res://scripts/drag_rival_driver.gd")
const Preparation = preload("res://tests/drag_test_driver.gd")
var checks := 0
var failed := false
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed=true
        push_error(message)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var session=root.get_node("GameSession")
    session.reset()
    session.game.buy(23)
    for part in session.game.find_car(23).health: session.game.find_car(23).health[part]=100.0
    var original_133: Dictionary=session.game.find_car(15).duplicate(true)
    var balance: int=session.game.balance
    check(not session.start_drag(23,"duel","technical","","Unknown") and session.selected_vehicle==0,"An unknown opponent cannot change player selection")
    check(not session.start_drag(23,"practice","technical","","Fiat 133"),"Individual practice cannot silently create a rival")
    check(session.start_drag(23,"duel","technical","","Fiat 133"),"The factory duel accepts a different supported opponent model")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    var scene=current_scene
    check(scene.car.model_name=="Fiat 500 Sport" and scene.opponent.model_name=="Fiat 133","The two physical actors use different selected cars")
    check(scene.car.powertrain.config.mass>scene.opponent.powertrain.config.mass and scene.car.powertrain.config.drivetrain=="FWD" and scene.opponent.powertrain.config.drivetrain=="RWD","Each rival retains its own mass, drivetrain and gearing")
    check(scene.car.powertrain.config.abs_assist and not scene.opponent.powertrain.config.abs_assist,"The rival does not inherit incompatible ABS equipment from the player's car")
    check(scene.car.visual.imported_model and scene.opponent.visual.imported_model,"Both chosen supplied models are imported into the live race")
    var driver=Driver.new("technical")
    scene.input_provider=func() -> Dictionary: return driver.controls(scene.car.powertrain,scene.run.clock,1.0/60.0)
    check(await Preparation.await_automatic_start(scene),"The starter calls both different physical models without a manual signal")
    check(scene.duel.started,"Different factory models arm on the same tree")
    for i in range(8000):
        await physics_frame
        if scene.duel.finished: break
    var result: Dictionary=scene.duel_result
    check(scene.run.phase=="finished" and scene.opponent_run.phase=="finished" and not result.is_empty(),"Both different physical cars complete the actual measured quarter-mile")
    if not result.is_empty():
        check(result.winner=="player" and result.entries.player.ticket.total<result.entries.rival.ticket.total,"The actual faster arrival wins the free mixed-car exhibition")
        print("Mixed-model physical duel: ",result.entries.player.ticket," / ",result.entries.rival.ticket)
    check(scene.hud.opponent_label.text.contains("Fiat 133"),"The HUD identifies the actual rival model")
    check(session.game.find_car(15)==original_133 and session.game.balance==balance,"The AI replica cannot mutate or grant ownership of the seller's car")
    scene.input_provider=Callable()
    scene._back_to_garage()
    await process_frame
    await process_frame
    check(current_scene.duel_opponent_model=="Fiat 133" and current_scene.duel_class.is_empty(),"The garage preserves the chosen opponent and free format during the session")
    check(session.game.balance==balance and session.game.find_car(23).owner=="player","Returning preserves the player's original unit and credits")
    if not failed: print("PASS: %d mixed-model drag duel assertions" % checks)
    quit(1 if failed else 0)
