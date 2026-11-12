extends SceneTree
const Tuning = preload("res://scripts/tuning.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Profile = preload("res://scripts/engine_sound_profile.gd")
const Synth = preload("res://scripts/engine_sound_synth.gd")
const Driver = preload("res://tests/drag_test_driver.gd")
var checks:=0
var failed:=false
func check(ok: bool, why: String) -> void:
    checks+=1
    if not ok:
        failed=true
        push_error(why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var session=root.get_node("GameSession")
    session.reset()
    session.controls.restore_defaults()
    session.game.balance=100000
    check(session.game.buy(11).begins_with("Compraste"),"A factory Fiat can be purchased")
    var car: Dictionary=session.game.find_car(11)
    for part in car.health: car.health[part]=100.0
    var tuning=Tuning.new()
    var balance: int=session.game.balance
    check(tuning.install(session.game,11,"turbo").begins_with("Instalaste"),"The actual workshop installs the turbo")
    check(session.game.balance==balance-3200 and tuning.has_part(car,"turbo"),"Turbo purchase debits once and persists on the unit")
    balance=session.game.balance
    check(not tuning.install(session.game,11,"turbo").begins_with("Instalaste") and session.game.balance==balance,"A duplicate turbo cannot be charged")
    var stock=Config.from_vehicle(car,true)
    var prepared=Config.from_vehicle(car,false)
    check(stock.turbo_fraction==0.0 and prepared.turbo_fraction>0.0 and prepared.peak_torque>stock.peak_torque,"Stock racing excludes the kit and prepared racing gains boost")
    var restored=load("res://scripts/economy.gd").new()
    check(restored.from_dict(session.game.to_dict()) and tuning.has_part(restored.find_car(11),"turbo"),"The installed turbo survives save/load")
    var a=Synth.new()
    var b=Synth.new()
    a.configure(Profile.from_vehicle(stock,"Fiat 147 Vivace"),22050.0,19)
    b.configure(Profile.from_vehicle(prepared,"Fiat 147 Vivace"),22050.0,19)
    a.set_state(4000,0.9,true,false,0.65)
    b.set_state(4000,0.9,true,false,0.65)
    var raw: PackedVector2Array=a.render(11025)
    var boosted: PackedVector2Array=b.render(11025)
    var diff:=0.0
    var peak:=0.0
    for i in range(raw.size()):
        diff+=pow(raw[i].x-boosted[i].x,2.0)
        peak=maxf(peak,absf(boosted[i].x))
    check(sqrt(diff/raw.size())>0.005 and peak<1.0,"Boost produces a measurable distinct whistle without digital clipping")
    b.set_state(4000,0.0,true,false,0.55)
    check(b.relief_level>0.1,"Lifting the throttle under pressure triggers a relief sound")
    b.render(22050)
    check(b.relief_level<0.01,"The relief sound decays on the audio sample clock")
    check(not session.start_drag(11,"prepared_duel","technical","1"),"Prepared duels cannot claim the factory reference class")
    check(session.start_drag(11,"prepared_duel","technical","","Fiat 133"),"A prepared car can race a physical opponent")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    var scene=current_scene
    check(scene.is_duel and not scene.factory_duel and scene.car.powertrain.config.turbo_fraction>0.0,"The racing player actually carries the purchased turbo")
    check(scene.opponent.model_name=="Fiat 133" and scene.opponent.powertrain.config.turbo_fraction==0.0,"The rival remains a separate factory vehicle")
    check(scene.engine_audio.synth.profile.turbo>0.0,"The live emitter is configured with the fitted turbo")
    check(scene.garage.record_profile.contains("_prep_") and load("res://scripts/drag_records.gd").valid_profile(scene.garage.record_profile),"Prepared records use a valid separate setup profile")
    var driver=Driver.new()
    scene.input_provider=func(): return driver.controls(scene.car.powertrain,scene.run.clock,1.0/60.0)
    check(await Driver.await_automatic_start(scene),"The prepared duel reaches the real starting tree")
    var max_boost:=0.0
    for frame in range(10000):
        await physics_frame
        max_boost=maxf(max_boost,scene.car.powertrain.engine.boost)
        if scene.duel.finished: break
    check(max_boost>0.1,"Real loaded driving builds turbo pressure")
    check(scene.run.phase=="finished" and scene.opponent_run.phase=="finished","Both cars physically finish the prepared duel")
    check(session.career.stock_drag_records.best(11).is_empty() and not session.career.drag_records.best_for_profile(11,scene.garage.record_profile).is_empty(),"A prepared time never contaminates factory records")
    scene.input_provider=Callable()
    scene._back_to_garage()
    await process_frame
    session.menu_music.set_menu_active(false)
    if not failed: print("PASS: %d turbo audio and prepared duel assertions"%checks)
    quit(1 if failed else 0)
