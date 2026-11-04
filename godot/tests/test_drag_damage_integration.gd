extends SceneTree

const Strip = preload("res://scripts/drag_strip.gd")
const Store = preload("res://scripts/save_store.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var session = root.get_node("GameSession")
    session.reset()
    session.game.buy(1)
    var vehicle: Dictionary = session.game.find_car(1)
    for component in vehicle.health: vehicle.health[component]=100.0
    session.start_drag(1)
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    var scene = current_scene
    scene.set_physics_process(false)
    var car = scene.car
    var wall := StaticBody3D.new()
    wall.position = Vector3(Strip.LANE_X,1,-7)
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(8,3,0.25)
    collider.shape = shape
    wall.add_child(collider)
    scene.add_child(wall)
    await physics_frame
    car.recover(Vector3(Strip.LANE_X,0.55,0))
    check(car.damage.impacts==0 and car.damage.total_pending()==0,"Recovery and scene placement do not fabricate crash damage")
    car.powertrain.speed_mps = 25
    car.powertrain.wheel_omega = 25/car.powertrain.config.wheel_radius
    var torque_before: float = car.powertrain.torque_at(4000)
    var balance: int = session.game.balance
    for i in range(30):
        car.drive_manual(1.0/60.0,{"throttle":0.0,"clutch":1.0,"brake":0.0},true)
        if car.damage.impacts>0: break
    check(car.damage.impacts==1 and car.damage.total_pending()>0 and car.is_on_wall(),"An actual CharacterBody collision records measured impact damage")
    check(car.damage.pending.has("motor") and car.damage.pending.has("chasis") and not car.damage.pending.has("transmision"),"Frontal collision selects the expected affected components")
    check(car.powertrain.torque_at(4000)<torque_before,"Impact damage reduces engine output immediately before garage settlement")
    scene._refresh_hud()
    check(scene.hud.damage_label.text.contains("DAÑOS POR IMPACTO") and float(car.damage.cumulative.motor)>0,"The real impact report distinguishes damage from normal mechanical wear")
    check(vehicle.health.motor==100.0,"Unsettled damage does not also subtract persistent health during the collision callback")
    var pending_motor: float = car.damage.pending.motor
    scene.garage.measured_distance = car.distance_m
    scene._recover()
    check(vehicle.health.motor<=100.0-pending_motor and car.damage.pending.is_empty(),"Recovery settles crash damage into the same persistent garage unit")
    var health: Dictionary = vehicle.health.duplicate(true)
    var after_torque: float = car.powertrain.torque_at(4000)
    scene._recover()
    check(vehicle.health==health and car.powertrain.torque_at(4000)==after_torque,"Repeated recovery neither duplicates damage nor repairs the engine")
    check(session.game.balance==balance,"Impact and recovery never generate credits or charge an unquoted fee")
    var damage_entries := 0
    for entry in vehicle.history:
        if entry.get("event")=="danos": damage_entries+=1
    check(damage_entries==1,"Only one persistent damage history entry is written for the crash")
    var decoded: Dictionary = Store.decode(Store.encode(session.game,session.career))
    check(decoded.error.is_empty() and float(decoded.game.find_car(1).health.motor)<100.0,"Crash damage survives real JSON save/load")
    car.damage.pending["motor"]=NAN
    var snapshot: Dictionary = session.game.to_dict()
    scene.garage.measured_distance += 5
    check(not scene.garage.settle(car.powertrain.wear,car.damage) and session.game.to_dict()==snapshot,"Malformed impact state is rejected before any distance or health mutation")
    car.damage.pending.clear()
    scene.garage.measured_distance = car.distance_m
    vehicle.health.motor=0.0
    car.powertrain.config.engine_health=0.0
    check(not scene._mechanically_ready() and not scene._can_arm(),"An unroadworthy damaged vehicle cannot arm a new timed pass")
    scene._back_to_garage()
    await process_frame
    await process_frame
    check(current_scene.name=="Main" and current_scene.current_tab=="garaje","The player can still return to the workshop after severe damage")
    var quote: int = session.game.repair_quote(1,"motor")
    balance = session.game.balance
    check(session.game.repair(1,"motor").begins_with("Reparación") and session.game.balance==balance-quote,"A damaged engine can be repaired through the existing quoted workshop transaction")
    check(session.start_drag(1),"Repair restores eligibility without replacing the owned car or resetting progression")
    current_scene._change_tab("taller")
    var fit: Button
    for button in current_scene.content.find_children("*","Button",true,false):
        if button.text.begins_with("MONTAR DEPORTIVOS"):
            fit = button
            break
    balance = session.game.balance
    if fit!=null:
        fit.pressed.emit()
    check(fit!=null and session.game.balance==balance-650 and vehicle.tire_compound=="sport","The real workshop button installs the chosen compound with one quoted debit")
    if not failed: print("PASS: %d drag damage integration assertions" % checks)
    quit(1 if failed else 0)
