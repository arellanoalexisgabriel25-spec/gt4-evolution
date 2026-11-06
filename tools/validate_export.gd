extends SceneTree

# Executed outside the exported PCK by the matching editor binary. Every game
# script, resource, scene and autoload below is loaded from that exact pack.
const Catalog = preload("res://scripts/car_catalog.gd")
const Visual = preload("res://scripts/car_visual.gd")
const Style = preload("res://scripts/racing_theme.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Reference = preload("res://scripts/technical_reference_data.gd")
const Store = preload("res://scripts/save_store.gd")
const Driver = preload("res://scripts/drag_rival_driver.gd")
const Model = preload("res://scripts/manual_powertrain.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    call_deferred("run")

# Tests are deliberately excluded from shipping PCKs. This external fixture
# observes the packaged procedure directly instead of importing test helpers.
func await_automatic_start(scene) -> bool:
    if scene.run.phase != "preparation" or scene.paused or not scene.enabled:
        return false
    if not scene.procedure.configure(0.05,5.0,0.05):
        return false
    for frame in range(600):
        await physics_frame
        if scene.run.phase == "countdown":
            return true
        if scene.run.phase == "invalid" or scene.procedure.phase == "expired":
            return false
    return false

func run() -> void:
    var session = root.get_node("GameSession")
    check(session.VERSION=="0.25","The exported PCK carries the current game version")
    check(session.controls.shift_mode=="manual" and not session.controls.auto_rev_match,"The shipping defaults disclose manual control without rev-matching assistance")
    check(session.controls.secondary_keycodes("clutch").has(KEY_CTRL) and session.controls.secondary_keycodes("shift_up").has(KEY_PAGEUP),"The shipping controls retain hardware-friendly alternative manual chords")
    check(session.controls.msaa_level()==Viewport.MSAA_2X,"The packaged default applies the explicit balanced graphics preference")
    check(Catalog.SHOWROOM_ONLY==["Volkswagen Taos"] and not Catalog.has_definition("Volkswagen Taos"),"The Taos exhibition cannot masquerade as an unimplemented factory transmission")
    var exhibit=Visual.new()
    exhibit.model_name="Volkswagen Taos"
    root.add_child(exhibit)
    await process_frame
    check(exhibit.imported_model and exhibit.wheels.size()==4,"The shipping Taos resolves its optimized mesh, texture and four wheel rig")
    exhibit.queue_free()
    await process_frame
    var sound_profile=load("res://scripts/engine_sound_profile.gd").from_vehicle(Config.new(),"Fiat 147 Vivace")
    var sound=load("res://scripts/engine_sound_synth.gd").new()
    sound.configure(sound_profile,44100.0)
    sound.set_state(3500.0,0.9,true,false,0.0,0.0)
    var waveform: PackedVector2Array=sound.render(2048)
    var audio_energy:=0.0
    var bounded:=true
    for sample in waveform:
        bounded=bounded and sample.is_finite() and absf(sample.x)<=1.0 and absf(sample.y)<=1.0
        audio_energy+=sample.length_squared()
    check(waveform.size()==2048 and bounded and audio_energy>0.01,"The packaged engine synthesizer produces finite audible samples without clipped peaks")
    var gearbox_car = Model.new()
    gearbox_car.rpm = 6000.0
    gearbox_car.throttle = 1.0
    check(gearbox_car.request_shift(1,1.0),"The packaged manual gearbox accepts clutch plus full throttle")
    for tick in range(40): gearbox_car.step(1.0/120.0,1.0,1.0,0.0)
    check(gearbox_car.gear==1 and gearbox_car.rpm>5000.0 and gearbox_car.speed_mps==0.0,"Selection preserves a free-revving motor and transmits no torque through an open clutch")
    check(gearbox_car.request_shift(1,1.0),"The packaged synchronized gearbox accepts a consecutive WOT upshift")
    var reverse = Model.new()
    check(reverse.request_shift(-1,1.0),"The packaged manual gearbox selects real reverse from neutral")
    for tick in range(40): reverse.step(1.0/120.0,0.5,1.0,0.0)
    for tick in range(240): reverse.step(1.0/120.0,0.5,0.0,0.0)
    check(reverse.speed_mps< -1.0 and reverse.wheel_torque_nm<0.0,"Reverse applies signed axle torque and moves backward in the packaged physics")
    check(reverse.clutch_temperature>20.0 and reverse.wear.transmision>0.0,"The packaged launch dissipates clutch energy into temperature and persistent wear")
    check(reverse.axles.suspension!=null and reverse.config.differential_type=="open","The packaged chassis uses the configurable reduced suspension and factory open differential baseline")
    check(Catalog.DATA.size()==26,"The export contains all twenty-six supplied car models")
    for song in session.menu_music.Playlist.SONGS:
        check(session.menu_music.select_track(song.id),"The exported playlist loads the shipped stream: "+song.id)
        check(session.menu_music.track.get_length()>85.0 and not session.menu_music.player.stream.loop,"The packaged song decodes completely and advances at its end")
    session.menu_music.select_track("perra")
    for name in Catalog.DATA:
        var profile: Dictionary = Catalog.DATA[name]
        check(ResourceLoader.exists(str(profile.asset)),"The exported model resolves through its imported resource: "+name)
        var visual = Visual.new()
        visual.model_name = name
        root.add_child(visual)
        await process_frame
        check(visual.imported_model and visual.wheels.size()==4 and visual.front_pivots.size()==2,"The exported car has a body and four animatable wheels: "+name)
        visual.queue_free()
        await process_frame
    check(Style.build().get_stylebox("panel","PanelContainer").bg_color==Color("1a2129"),"The exported UI carries the supplied dark visual palette")
    check(is_equal_approx(Style.MONO.get_string_size("1111").x,Style.MONO.get_string_size("8888").x),"The exported numeric font is loaded with tabular widths")
    session.reset()
    var car_id := 0
    for car in session.game.cars:
        if car.model=="Fiat 133": car_id=int(car.id)
    check(car_id>0,"The exported market contains the Fiat 133")
    if car_id<=0:
        quit(1)
        return
    session.game.buy(car_id)
    var owned: Dictionary = session.game.find_car(car_id)
    for component in owned.health: owned.health[component]=100.0
    check(session.start_drag(car_id,"duel","technical","1"),"The exported car enters a real two-lane class duel")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    var scene = current_scene
    check(scene.is_duel and scene.car.powertrain.config.drivetrain=="RWD","The exported Fiat 133 retains rear-wheel drive")
    var driver = Driver.new("technical")
    scene.input_provider=func() -> Dictionary: return driver.controls(scene.car.powertrain,scene.run.clock,1.0/60.0)
    check(await await_automatic_start(scene),"The exported starter progresses through preparation and alignment without a driver signal")
    check(scene.duel.started,"Both exported lane timers arm on the common tree")
    for i in range(9000):
        await physics_frame
        if scene.duel.finished: break
    check(scene.run.phase=="finished" and scene.opponent_run.phase=="finished","Both exported physical cars complete the actual course")
    check(-scene.car.position.z>=402.336 and -scene.opponent.position.z>=402.336,"The export measures actual 402.336 metre travel in both lanes")
    check(not scene.duel_result.is_empty() and scene.duel_result.entries.player.ticket.et>0.0 and scene.duel_result.entries.rival.ticket.et>0.0,"The exported duel generates two independently measured ET tickets")
    if not scene.duel_result.is_empty():
        print("Export PCK physical duel: ",scene.duel_result)
    scene.input_provider=Callable()
    scene._back_to_garage()
    await process_frame
    await process_frame
    check(current_scene.name=="Main" and session.game.find_car(car_id).owner=="player","The exported duel returns to the same owned unit")
    session.game.buy(11)
    var revised: Dictionary = session.game.find_car(11)
    for component in revised.health: revised.health[component]=100.0
    var balance: int = session.game.balance
    check(session.start_drag(11,"duel","technical","1","Fiat 500 Sport"),"The exported revised 147 enters a mixed physical factory race")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    scene = current_scene
    var metrics: Dictionary = scene.car.powertrain.config.metrics()
    check(metrics.curb_mass_kg==807.0 and absf(metrics.peak_torque_nm-101.98916)<0.0001 and absf(metrics.calculated_peak_power_cv-63.0)<0.0001,"The shipped physics actually uses the new 147 PDF anchors")
    check(metrics.sources[0].sha256==Reference.DOCUMENT_SHA256 and metrics.estimated_fields.has("power_rpm"),"The exported fiche keeps its source and estimated power RPM distinct")
    driver = Driver.new("technical")
    scene.input_provider=func() -> Dictionary: return driver.controls(scene.car.powertrain,scene.run.clock,1.0/60.0)
    check(await await_automatic_start(scene),"The revised exported car passes through the same automatic starter")
    for frame in range(9000):
        await physics_frame
        if scene.duel.finished: break
    check(scene.run.phase=="finished" and scene.opponent_run.phase=="finished","Both revised factory cars cover the actual measured course")
    var current: Dictionary = session.career.stock_drag_records.best_for_profile(11,preload("res://scripts/stock_vehicle_specs.gd").record_revision("Fiat 147 Vivace"))
    check(not current.is_empty() and is_equal_approx(current.et,scene.run.elapsed),"The exported result stores a measured profile-specific personal best")
    var decoded: Dictionary = Store.decode(Store.encode(session.game,session.career))
    check(decoded.error=="" and decoded.career.stock_drag_records.best_for_profile(11,preload("res://scripts/stock_vehicle_specs.gd").record_revision("Fiat 147 Vivace")).physics_profile==preload("res://scripts/stock_vehicle_specs.gd").record_revision("Fiat 147 Vivace"),"The exported game can save and load the physical revision metadata")
    check(session.game.balance==balance,"The new physical reference cannot generate or lose credits on finish")
    scene.input_provider=Callable()
    scene._back_to_garage()
    await process_frame
    await process_frame
    session.reset()
    session.game.buy(25)
    for part in session.game.find_car(25).health: session.game.find_car(25).health[part]=100.0
    check(session.start_drag(25,"duel","technical","","Chevrolet Corsa 5 puertas"),"The exported pickup enters a mixed free night duel")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    scene = current_scene
    check(scene.strip.get_node_or_null("NightPresentation")!=null,"The shipping track instantiates its night environment")
    check(scene.car.visual.night_lights.beam!=null and not scene.car.visual.night_lights.draw_housings,"The imported pickup uses its own housings with functional projected headlights")
    check(scene.car.powertrain.config.cg_height>0.7 and scene.car.powertrain.config.gear_ratios.size()==6,"The packaged pickup retains its own geometry and six-speed drivetrain")
    driver = Driver.new("technical")
    scene.input_provider=func() -> Dictionary: return driver.controls(scene.car.powertrain,scene.run.clock,1.0/60.0)
    check(await await_automatic_start(scene),"The packaged night duel still uses automatic preparation and starter")
    for frame in range(9000):
        await physics_frame
        if scene.duel.finished: break
    check(scene.run.phase=="finished" and scene.opponent_run.phase=="finished","Both new packaged models physically finish the 402.336 metre night race")
    check(scene.hud.instruments!=null and scene.hud.instruments.rpm>0.0,"The exported analog instruments receive live engine readings")
    scene.input_provider=Callable()
    scene._back_to_garage()
    await process_frame
    await process_frame
    session.reset()
    session.game.buy(36)
    for part in session.game.find_car(36).health: session.game.find_car(36).health[part]=100.0
    check(session.start_drag(36,"duel","technical","","Volkswagen Virtus"),"The packaged CVT Cross can race a different manual car")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    scene = current_scene
    driver = Driver.new("technical")
    scene.input_provider=func() -> Dictionary: return driver.controls(scene.car.powertrain,scene.run.clock,1.0/60.0)
    check(scene.car.powertrain.config.transmission_type=="cvt" and scene.car.powertrain.config.gear_ratios.size()==1,"The shipped Cross has the continuous gearbox and launch coupling")
    check(await await_automatic_start(scene),"The automatic car stages using the brake and actual starter")
    for frame in range(9000):
        await physics_frame
        if scene.duel.finished: break
    check(scene.run.phase=="finished" and scene.opponent_run.phase=="finished" and scene.hud.gear_label.text=="D","Both different gearbox types finish a measured physical race with the correct dashboard")
    check(scene.car.powertrain.cvt.converter_heat_j>0.0 and scene.car.powertrain.brakes.temperatures.x>=20.0,"Exported power flow reaches converter and brake thermal states")
    scene.input_provider=Callable()
    scene._back_to_garage()
    await process_frame
    await process_frame
    if not failed: print("PASS: %d exported PCK assertions" % checks)
    quit(1 if failed else 0)
