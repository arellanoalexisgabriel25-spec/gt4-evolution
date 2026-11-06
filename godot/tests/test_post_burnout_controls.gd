extends SceneTree

# Use the shipped 25/30/1.5 second procedure, a real contact burnout, and
# controlled pedals. No actor speed, position, timer or heat is assigned.
var checks := 0
var failed := false
var pedals := {"throttle":0.0,"clutch":1.0,"brake":1.0,"handbrake":0.0,"steer":0.0}

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func ticks(count: int) -> void:
    for tick in range(count): await physics_frame

func _initialize() -> void: call_deferred("run")

func run() -> void:
    var session = root.get_node("GameSession")
    session.reset()
    session.controls.restore_defaults()
    session.controls.controller.devices.clear()
    session.controls.controller.active_device = -1
    session.game.buy(11)
    var unit: Dictionary = session.game.find_car(11)
    for component in unit.health: unit.health[component] = 100.0
    check(session.start_drag(11,"duel","technical",""),"An owned healthy factory147 enters the actual two-lane procedure")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    var scene = current_scene
    scene.input_provider = func() -> Dictionary: return pedals
    await ticks(20)
    var model = scene.car.powertrain
    check(scene.procedure.remaining>24.0,"The regression keeps the production 25second warmup instead of configuring a short fixture")
    check(model.request_shift(1,1.0),"First is selected through the same gearbox while the clutch is held")
    pedals.throttle = 0.8
    pedals.brake = 0.0
    await ticks(50)
    var cold: float = model.axles.temperatures.x
    pedals.clutch = 0.0
    pedals.handbrake = 1.0
    await ticks(100)
    check(model.axles.temperatures.x>cold+0.1 and model.wear.neumaticos>0.0,"A genuine contact burnout heats and wears the driven tyres before the default call")
    pedals.throttle = 0.0
    pedals.clutch = 1.0
    pedals.brake = 1.0
    pedals.handbrake = 0.0
    await ticks(120)
    check(model.engine_running and absf(model.speed_mps)<0.1,"Normal braking and an open clutch stop the warmed car without stalling or repairs")
    # Select N then R while stationary. Holding the clutch leaves the car still
    # until the blue call; reverse explicitly elects a manual return to the beam.
    check(model.request_shift(-1,1.0),"A warmed car can deliberately select neutral")
    await ticks(45)
    check(model.request_shift(-1,1.0) and model.gear==-1,"Reverse is selected before the blue call with the car physically stopped")
    await ticks(45)
    var position_before_call: Vector3 = scene.car.position
    var retained_heat: Vector2 = model.axles.temperatures
    for frame in range(1800):
        await physics_frame
        if scene.procedure.phase!="burnout": break
    check(scene.procedure.phase=="staging" and scene.procedure.elapsed>=25.0,"Only the complete default warming interval issues the real blue alignment call")
    await ticks(5)
    check(not scene.alignment_pending and scene.car.position.distance_to(position_before_call)<0.1,"Selecting reverse elects manual return and prevents an automatic staging teleport")
    check(model.axles.temperatures.x>20.0 and model.wear.neumaticos>0.0 and retained_heat.x>20.0,"Calling the warmed car never resets actual tyre heat or wear")
    var reverse_origin: Vector3 = scene.car.position
    pedals.throttle = 0.35
    pedals.clutch = 0.55
    pedals.brake = 0.0
    await ticks(60)
    check(model.gear==-1 and model.speed_mps< -0.2 and scene.car.position.z>reverse_origin.z+0.2,"After warmup reverse delivers actual negative speed and backwards CharacterBody movement; no hidden clutch or brake holds it")
    # Reverse towards the beam using only real brake/clutch/throttle commands.
    # The speed target shrinks near the line. No transform or timer is patched.
    var arrived := false
    for frame in range(900):
        var distance: float = -scene.car.position.z
        var target: float = -clampf((distance-0.015)*0.7,0.03,1.5)
        if distance<=0.04:
            pedals.clutch = 1.0
            pedals.brake = 1.0
        elif model.speed_mps<target:
            pedals.clutch = 1.0
            pedals.brake = 0.65
        else:
            pedals.clutch = 0.55
            pedals.brake = 0.0
        await physics_frame
        if absf(scene.car.position.z)<0.09 and absf(model.speed_mps)<0.09:
            arrived = true
            break
        if scene.procedure.phase=="expired": break
    check(arrived and scene.procedure.phase=="staging","The driver can return physically to the staging beam in reverse inside the unmodified presentation window")
    var reverse_travel: float = scene.car.position.z-reverse_origin.z
    pedals.throttle = 0.45
    pedals.clutch = 1.0
    pedals.brake = 1.0
    await ticks(30)
    check(model.request_shift(1,1.0) and model.gear==0,"Reverse disengages into neutral at the real beam")
    await ticks(45)
    check(model.request_shift(1,1.0) and model.gear==1,"The same warmed unit selects first without lifting the held accelerator")
    await ticks(45)
    var saw_countdown := false
    for frame in range(600):
        await physics_frame
        if scene.run.phase=="countdown": saw_countdown = true
        if scene.run.phase in ["running","invalid"] or scene.procedure.phase=="expired": break
    check(saw_countdown and scene.run.phase=="running" and scene.duel.started,"Both actually aligned cars complete the starter countdown and reach green without Enter or a driver start command")
    var launch_z: float = scene.car.position.z
    pedals.throttle = 0.8
    pedals.clutch = 0.0
    pedals.brake = 0.0
    await ticks(150)
    check(scene.run.phase=="running" and model.engine_running and model.speed_mps>2.0 and scene.car.position.z<launch_z-2.0,"Releasing real clutch/brakes after the default full warmup and green actually launches the warmed car")
    check(scene.run.launch_time>=0.0 and scene.run.reaction>=0.0,"Physical beam departure after manual return records a real legal reaction")
    print("Full preparation evidence: armed after ",scene.procedure.elapsed," s; reverse return ",reverse_travel," m; launch speed ",model.speed_mps," m/s; front tyre ",model.axles.temperatures.x," C")
    scene.input_provider = Callable()
    scene._back_to_garage()
    await process_frame
    await process_frame
    await create_timer(0.12,true,false,true).timeout
    # Also cover the common route: let the initial line assistance complete in
    # neutral, then choose R after the call. It used to remain clamped forever.
    session.reset()
    session.game.buy(11)
    for component in session.game.find_car(11).health: session.game.find_car(11).health[component] = 100.0
    check(session.start_drag(11,"duel","technical",""),"A second healthy unit enters the same production procedure")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    scene = current_scene
    model = scene.car.powertrain
    pedals.throttle = 0.0
    pedals.clutch = 1.0
    pedals.brake = 1.0
    scene.input_provider = func() -> Dictionary: return pedals
    for frame in range(1800):
        await physics_frame
        if scene.procedure.phase=="staging" and not scene.alignment_pending: break
    check(scene.procedure.elapsed>=25.0 and scene.procedure.phase=="staging" and scene._staged(),"Default automatic line placement still completes for a stopped neutral car after all25seconds")
    check(model.request_shift(-1,1.0),"The driver can select reverse after initial alignment rather than only before the call")
    await ticks(45)
    var aligned_reverse_origin: float = scene.car.position.z
    pedals.throttle = 0.35
    pedals.clutch = 0.55
    pedals.brake = 0.0
    await ticks(60)
    check(model.speed_mps< -0.2 and scene.car.position.z>aligned_reverse_origin+0.2,"Reverse remains powered after assisted alignment; selecting it never leaves an invisible brake applied")
    check(scene._applied_controls.clutch==pedals.clutch and scene._applied_controls.brake==0.0,"Manual staging passes the driver's actual clutch and brake to the physics")
    scene.input_provider = Callable()
    scene._back_to_garage()
    await process_frame
    await process_frame
    await create_timer(0.12,true,false,true).timeout
    session.menu_music.set_menu_active(false)
    await ticks(8)
    if not failed: print("PASS: %d full warmup and manual return assertions" % checks)
    quit(1 if failed else 0)
