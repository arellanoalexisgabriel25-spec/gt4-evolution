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
    check(session.VERSION=="0.22","The exported PCK carries the current game version")
    check(Catalog.DATA.size()==19,"The export contains all nineteen supplied car models")
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
    var current: Dictionary = session.career.stock_drag_records.best_for_profile(11,Reference.VIVACE_REVISION)
    check(not current.is_empty() and is_equal_approx(current.et,scene.run.elapsed),"The exported result stores a measured profile-specific personal best")
    var decoded: Dictionary = Store.decode(Store.encode(session.game,session.career))
    check(decoded.error=="" and decoded.career.stock_drag_records.best_for_profile(11,Reference.VIVACE_REVISION).physics_profile==Reference.VIVACE_REVISION,"The exported game can save and load the physical revision metadata")
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
    if not failed: print("PASS: %d exported PCK assertions" % checks)
    quit(1 if failed else 0)
