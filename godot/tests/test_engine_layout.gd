extends SceneTree

const Damage = preload("res://scripts/damage_model.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Economy = preload("res://scripts/economy.gd")
const Career = preload("res://scripts/career.gd")
const Actor = preload("res://scripts/drag_actor.gd")
const Store = preload("res://scripts/save_store.gd")
var checks := 0
var failed := false
var fixture: Node3D

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    call_deferred("run")

func sum_values(values: Dictionary) -> float:
    var total := 0.0
    for component in values:
        total += float(values[component])
    return total

func pure_layouts() -> void:
    var forward := Vector2(0,-1)
    var zones: Dictionary = Damage.ZONES.duplicate(true)
    for layout in ["front","mid","rear"]:
        for direction in ["front","rear","side"]:
            var incoming: Vector2 = {"front":Vector2(0,-20),"rear":Vector2(0,20),"side":Vector2(20,0)}[direction]
            var model = Damage.new()
            var points: float = model.record(incoming,Vector2.ZERO,forward,layout)
            check(absf(model.total_pending()-points)<0.00001 and absf(sum_values(model.latest_damage)-points)<0.00001,"Every layout preserves the total accepted impact severity for "+direction)
            var motor_expected: bool = (layout=="front" and direction=="front") or (layout in ["mid","rear"] and direction=="rear")
            check((float(model.pending.get("motor",0.0))>0.0)==motor_expected,"Engine damage follows the configured compartment for "+layout+" engine / "+direction+" impact")
            var before: Dictionary = model.pending.duplicate(true)
            check(model.record(incoming,Vector2.ZERO,forward,layout)==0.0 and model.pending==before and model.impacts==1,"Repeated frames cannot duplicate the same layout-specific impact")
    check(Damage.ZONES==zones,"Layout adaptation never mutates the shared front-engine zone definitions")
    var legacy = Damage.new()
    var explicit = Damage.new()
    legacy.record(Vector2(0,-20),Vector2.ZERO,forward)
    explicit.record(Vector2(0,-20),Vector2.ZERO,forward,"front")
    check(legacy.pending==explicit.pending,"The previous three-argument damage API retains its front-engine behavior")
    var invalid = Damage.new()
    check(invalid.record(Vector2(0,-20),Vector2.ZERO,forward,"unknown")==0.0 and invalid.pending.is_empty() and invalid.impacts==0,"An unsupported layout cannot distribute or persist damage")
    var staged = Damage.new()
    var first: float = staged.record(Vector2(0,10),Vector2.ZERO,forward,"rear")
    var extra: float = staged.record(Vector2(0,20),Vector2.ZERO,forward,"rear")
    check(extra>0.0 and absf(staged.total_pending()-(first+extra))<0.00001 and staged.impacts==1,"A harder rear-impact frame adds only its incremental severity")
    check(absf(float(staged.pending.motor)-staged.total_pending()*0.25)<0.00001,"Incremental rear impacts preserve the rear-engine allocation")

func add_box(size: Vector3, location: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = location
    body.collision_layer = 1
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    fixture.add_child(body)

func physical_collision(model_name: String, rear: bool) -> void:
    var game = Economy.new()
    game.seed_demo()
    var id := 0
    for vehicle in game.cars:
        if vehicle.model==model_name:
            id=int(vehicle.id)
            break
    check(id>0 and game.buy(id).begins_with("Compraste"),"The collision fixture uses an actual purchasable "+model_name)
    if id<=0: return
    var owned: Dictionary = game.find_car(id)
    for component in owned.health: owned.health[component]=100.0
    var balance: int = game.balance
    var config = Config.from_vehicle(owned,true)
    check(config.drivetrain=="RWD" and config.engine_position==("rear" if rear else "front"),"Rear-wheel drive does not imply a rear engine: "+model_name)
    fixture = Node3D.new()
    root.add_child(fixture)
    add_box(Vector3(40,1,40),Vector3(0,-0.5,0))
    add_box(Vector3(8,3,0.25),Vector3(0,1,5.0 if rear else -5.0))
    var actor = Actor.new()
    actor.model_name=model_name
    actor.powertrain.config=config
    actor.collision_layer=2
    actor.collision_mask=1
    actor.position=Vector3(0,0.51,0)
    fixture.add_child(actor)
    await physics_frame
    await physics_frame
    var torque_before: float=actor.powertrain.torque_at(4000.0)
    var resolved_change := 0.0
    if rear:
        # The quarter-mile controller currently has no reverse gear. This is a
        # physical backwards-motion fixture, not a claim that reverse is playable.
        # Damage receives the real pre/post collision velocities, never a made-up
        # terminal speed or a manually constructed damage ticket.
        for i in range(40):
            actor.velocity=Vector3(0,-1,20)
            var incoming := Vector2(actor.velocity.x,actor.velocity.z)
            actor.move_and_slide()
            if actor.is_on_wall():
                var outgoing := Vector2(actor.velocity.x,actor.velocity.z)
                resolved_change=(outgoing-incoming).length()
                if actor.damage.record(incoming,outgoing,Vector2(0,-1),config.engine_position)>0.0:
                    config.apply_damage(actor.damage.latest_damage)
                break
    else:
        actor.powertrain.speed_mps=20.0
        actor.powertrain.wheel_omega=20.0/config.wheel_radius
        for i in range(40):
            var incoming: float=actor.powertrain.speed_mps
            actor.drive_manual(1.0/60.0,{"throttle":0.0,"clutch":1.0,"brake":0.0})
            if actor.damage.impacts>0:
                resolved_change=actor.damage.worst_change
                check(resolved_change<=incoming-actor.powertrain.speed_mps+0.00001,"Impact severity excludes the ordinary propulsion/road-load velocity change before collision")
                break
    check(actor.is_on_wall() and actor.damage.impacts==1 and resolved_change>Damage.MIN_IMPACT,"A real barrier resolves the configured "+("rear" if rear else "front")+" collision for "+model_name)
    check(actor.damage.pending.has("motor") and float(actor.damage.pending.motor)>0.0,"The actual impact reaches the engine in its configured compartment")
    check(actor.powertrain.torque_at(4000.0)<torque_before,"The physical impact reduces engine output immediately")
    check(float(owned.health.motor)==100.0,"Immediate actor damage does not also debit persistent health before settlement")
    var total: float=actor.damage.total_pending()
    check(absf(total-Damage.points_for(resolved_change))<0.01,"Configured compartment redistribution preserves measured impact severity")
    var health: Dictionary=owned.health.duplicate(true)
    var applied: Dictionary=actor.damage.settle(game,id)
    var lost := 0.0
    for component in health:
        lost+=float(health[component])-float(owned.health[component])
    check(not applied.is_empty() and absf(lost-total)<0.00001,"One settlement applies exactly the pending damage to the owned unit")
    var settled: Dictionary=game.to_dict().duplicate(true)
    check(actor.damage.settle(game,id).is_empty() and game.to_dict()==settled,"A repeated settlement cannot apply engine damage twice")
    check(game.balance==balance,"Collision layout and settlement never create credits or hidden fees")
    var entries := 0
    for event in owned.history:
        if event.get("event")=="danos": entries+=1
    check(entries==1,"The measured layout-specific collision creates one damage history entry")
    var decoded: Dictionary=Store.decode(Store.encode(game,Career.new()))
    check(decoded.error.is_empty() and float(decoded.game.find_car(id).health.motor)==float(owned.health.motor),"Layout-specific engine damage survives the real save format")
    print("Engine layout collision ",model_name,": measured change=",resolved_change," m/s, damage=",total," points")
    fixture.free()
    await physics_frame
    await physics_frame

func run() -> void:
    pure_layouts()
    await physical_collision("Fiat 133",true)
    await physical_collision("Fiat 125",false)
    if not failed: print("PASS: %d engine compartment damage assertions" % checks)
    quit(1 if failed else 0)
