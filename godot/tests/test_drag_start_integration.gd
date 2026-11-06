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

func button(code: int, pressed: bool) -> void:
    var event := InputEventJoypadButton.new()
    event.device = 0
    event.button_index = code
    event.pressed = pressed
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func motion_state(actor) -> Dictionary:
    return {"position":actor.position,"velocity":actor.velocity,"rpm":actor.powertrain.rpm,"heat":actor.powertrain.axles.temperatures,"engine_heat":actor.powertrain.engine_temperature,"wear":actor.powertrain.wear.duplicate(true)}

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var session = root.get_node("GameSession")
    session.reset()
    session.controls.restore_defaults()
    session.controls.controller.devices.clear()
    session.controls.controller.active_device = -1
    session.game.buy(11)
    var owned: Dictionary = session.game.find_car(11)
    for part in owned.health: owned.health[part] = 100.0
    var balance: int = session.game.balance
    var reputation: int = session.career.reputation
    check(session.start_drag(11,"duel","technical"),"An owned factory Fiat 147 enters the real two-car preparation")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    var scene = current_scene
    check(scene.procedure.phase=="burnout" and scene.procedure.remaining>24.9 and scene.procedure.remaining<=25.0,"The playable default provides 25 seconds of authorized warming")
    check(is_equal_approx(-scene.car.position.z,5.0) and is_equal_approx(-scene.opponent.position.z,5.0),"Both physical cars spawn five metres ahead of the line in the authorized area")
    check(scene.run.clock==0.0 and scene.opponent_run.clock==0.0 and not scene.duel.started,"Neither race timer nor the duel starts during preparation")
    key(KEY_ENTER,true)
    key(KEY_ENTER,false)
    check(scene.procedure.phase=="burnout" and scene.run.phase=="preparation" and not scene.duel.started,"Enter cannot request the tree or skip the warming period")
    button(JOY_BUTTON_START,true)
    button(JOY_BUTTON_START,false)
    check(scene.paused and scene.procedure.phase=="burnout" and not scene.duel.started,"Controller Start pauses preparation instead of commanding the starter")
    var pause_procedure: Dictionary = scene.procedure.snapshot()
    var pause_car: Dictionary = motion_state(scene.car)
    var pause_rival: Dictionary = motion_state(scene.opponent)
    for i in range(15): await physics_frame
    check(scene.procedure.snapshot()==pause_procedure and motion_state(scene.car)==pause_car and motion_state(scene.opponent)==pause_rival and scene.run.clock==0.0 and scene.opponent_run.clock==0.0,"Pause freezes preparation, both physical cars, tyre/engine heat, wear and timing together")
    button(JOY_BUTTON_START,true)
    button(JOY_BUTTON_START,false)
    check(not scene.paused,"Controller Start resumes the same preparation")

    # Exercise real clutch/torque/contact heating in the authorized area. The
    # fixture supplies only driver pedals; it never assigns temperature or speed.
    var pedals := {"throttle":1.0,"clutch":1.0,"brake":0.0,"handbrake":1.0,"steer":0.0}
    scene.input_provider = func() -> Dictionary: return pedals
    scene.car.powertrain.shift(1,1.0)
    for i in range(60): await physics_frame
    var cold_front: float = scene.car.powertrain.axles.temperatures.x
    pedals.clutch = 0.0
    for i in range(90): await physics_frame
    check(scene.procedure.phase=="burnout" and scene.car.powertrain.axles.temperatures.x>cold_front+0.1,"Driven front tyres gain actual contact heat during a permitted FWD burnout")
    check(scene.car.powertrain.axles.tires[0].wear>0.0 and scene.car.powertrain.wear.neumaticos>0.0,"Warming consumes physical tyre tread and session mechanical health")
    check(scene.run.clock==0.0 and scene.opponent_run.clock==0.0 and scene.run.report().is_empty() and scene.opponent_run.report().is_empty(),"Real warming movement produces no timed run or invented finish ticket")
    # Stop by real brakes before using a short test presentation window.
    pedals.throttle = 0.0
    pedals.clutch = 1.0
    pedals.brake = 1.0
    pedals.handbrake = 0.0
    for i in range(150): await physics_frame
    check(scene.car.powertrain.speed_mps<0.15 and scene.procedure.phase=="burnout","The warmed car physically stops in its authorized area before alignment")
    var warm_heat: Vector2 = scene.car.powertrain.axles.temperatures
    var warm_wear: Dictionary = scene.car.powertrain.wear.duplicate(true)
    var measured_distance: float = scene.car.distance_m
    var driver = Driver.new()
    scene.input_provider = func() -> Dictionary: return driver.controls(scene.car.powertrain,scene.run.clock,1.0/60.0)
    check(scene.procedure.configure(0.1,1.0,0.05),"The integration fixture uses short positive timings without issuing a start command")
    for i in range(120):
        await physics_frame
        if scene.run.phase=="countdown" or scene.procedure.phase=="expired": break
    check(scene.procedure.phase=="countdown" and scene.run.phase=="countdown" and scene.opponent_run.phase=="countdown" and scene.duel.started,"The starter automatically aligns and arms both real lanes after continuous first-gear/clutch readiness")
    check(absf(scene.car.position.z)<=0.1 and absf(scene.opponent.position.z)<=0.1 and absf(scene.run.clock-scene.opponent_run.clock)<0.000001,"Both timing beams start at the same physical line and common tree clock")
    check(scene.car.powertrain.axles.temperatures.x>=warm_heat.x-1.0 and scene.car.powertrain.axles.temperatures.y>=warm_heat.y-1.0,"Alignment preserves warmed tyres, allowing only actual elapsed cooling")
    var wear_preserved := true
    for component in warm_wear: wear_preserved = wear_preserved and float(scene.car.powertrain.wear[component])>=float(warm_wear[component])
    check(wear_preserved and scene.car.distance_m>=measured_distance and scene.car.distance_m<measured_distance+0.5,"Alignment preserves cumulative wear and does not count its assistance as driven mileage")
    check(session.game.balance==balance and session.career.reputation==reputation and session.career.stock_drag_records.best(11).is_empty(),"Pre-race alignment and arming never award a prize, reputation or result record")

    var heat_before_retry: Vector2 = scene.car.powertrain.axles.temperatures
    var wear_before_retry: Dictionary = scene.car.powertrain.wear.duplicate(true)
    key(KEY_R,true)
    key(KEY_R,false)
    check(scene.procedure.phase=="burnout" and scene.procedure.remaining==0.1 and scene.run.phase=="preparation" and scene.opponent_run.phase=="preparation" and not scene.duel.started,"R creates a fresh complete procedure and clears both old timing lanes")
    check(scene.car.powertrain.axles.temperatures==heat_before_retry and scene.car.powertrain.wear==wear_before_retry and scene.car.powertrain.gear==0,"R preserves accumulated heat and mechanical use while selecting neutral")
    check(is_equal_approx(-scene.car.position.z,5.0) and is_equal_approx(-scene.opponent.position.z,5.0),"Retry returns both cars to their authorized warming positions")
    var settled_health: Dictionary = owned.health.duplicate(true)
    key(KEY_R,true)
    key(KEY_R,false)
    check(owned.health==settled_health and session.game.balance==balance,"Repeated retry cannot double-apply settled wear or charge money")

    scene.input_provider = func() -> Dictionary: return {"throttle":0.0,"clutch":1.0,"brake":1.0,"steer":0.0}
    scene.procedure.configure(0.1,1.0,0.05)
    for i in range(120):
        await physics_frame
        if scene.procedure.phase=="expired": break
    check(scene.procedure.phase=="expired" and scene.procedure.reason.contains("PILOTO") and scene.car.powertrain.gear==0,"A driver left in neutral misses the presentation deadline instead of starting")
    check(scene.run.clock==0.0 and scene.opponent_run.clock==0.0 and scene.run.report().is_empty() and scene.opponent_run.report().is_empty() and scene.duel_result.is_empty() and not scene.duel.started,"Expired preparation produces no race clock, ticket, duel winner or result")
    check(session.game.balance==balance and session.career.reputation==reputation and session.career.stock_drag_records.best(11).is_empty(),"A presentation timeout cannot create credits or progression")

    key(KEY_R,true)
    key(KEY_R,false)
    scene.procedure.configure(25.0,30.0,1.5)
    # Deliberately place the collider outside the authorized area as a boundary
    # fixture. The assertion checks cancellation, never a timed teleport repair.
    scene.car.position.z = -36.0
    for i in range(3): await physics_frame
    check(scene.procedure.phase=="expired" and scene.procedure.reason.contains("ZONA DE CALENTAMIENTO") and not scene.alignment_pending,"Leaving the 35-metre warming zone cancels authorization explicitly")
    check(scene.car.position.z<=-35.5 and scene.run.phase=="preparation" and scene.run.clock==0.0 and not scene.duel.started,"Out-of-zone cancellation never teleports the car to a ready beam or starts a race")
    var cancelled_pedals := {"throttle":0.35,"clutch":1.0,"brake":1.0,"handbrake":0.0,"steer":0.0}
    scene.input_provider=func() -> Dictionary: return cancelled_pedals
    check(scene.car.powertrain.request_shift(-1,1.0),"A cancelled preparation still allows the driver to select reverse deliberately")
    for i in range(30): await physics_frame
    var cancelled_origin: float=scene.car.position.z
    cancelled_pedals.clutch=0.55
    cancelled_pedals.brake=0.0
    for i in range(90): await physics_frame
    check(scene.car.powertrain.speed_mps< -0.2 and scene.car.position.z>cancelled_origin+0.2,"Expiry cannot create a hidden clutch/brake lock that makes reverse immobile")
    check(scene.procedure.phase=="expired" and not scene.duel.started and scene.run.clock==0.0 and scene.duel_result.is_empty(),"Returning after a cancelled call cannot reopen the race or create a result")
    check(session.game.balance==balance and session.career.reputation==reputation,"Free physical control after expiry creates no credits or sporting progress")
    if not failed: print("PASS: %d automatic drag start integration assertions" % checks)
    quit(1 if failed else 0)
