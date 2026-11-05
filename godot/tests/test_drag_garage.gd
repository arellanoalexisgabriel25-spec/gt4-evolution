extends SceneTree

const Economy = preload("res://scripts/economy.gd")
const Career = preload("res://scripts/career.gd")
const Garage = preload("res://scripts/drag_garage_session.gd")
const Store = preload("res://scripts/save_store.gd")
const Settings = preload("res://scripts/control_settings.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    var game = Economy.new()
    game.seed_demo()
    var career = Career.new()
    var garage = Garage.new()
    check(not garage.begin(game,career,1),"Unowned used offers cannot enter the drag mode")
    game.buy(1)
    var balance: int = game.balance
    check(garage.begin(game,career,1),"An eligible owned car can enter free timed practice")
    var wear := {"motor":0.2,"transmision":0.3,"neumaticos":0.4,"frenos":0.1}
    var vehicle: Dictionary = game.find_car(1)
    var health: Dictionary = vehicle.health.duplicate(true)
    garage.measured_distance = 402.5
    check(garage.settle(wear),"Actual short-run distance and mechanical stress settle into the existing car")
    check(absf(float(vehicle.get("distance_remainder_m",0.0))-402.5)<0.000001,"Sub-kilometre measured distance is preserved")
    check(absf(float(vehicle.health.motor)-(float(health.motor)-0.2-0.4025*Economy.WEAR.motor))<0.000001,"Engine health combines measured base wear and additional actual stress")
    var settled: Dictionary = vehicle.duplicate(true)
    check(garage.settle(wear) and vehicle==settled,"Repeated settlement cannot duplicate mileage or mechanical wear")
    var invalid := wear.duplicate()
    invalid["transmision"] = NAN
    garage.measured_distance = 500
    check(not garage.settle(invalid) and vehicle==settled,"Malformed wear is rejected before any distance or health mutation")
    garage.measured_distance = 402.5
    var ticket := {"distance":402.336,"et":19.0,"reaction":0.25,"total":19.25,"trap_kmh":120.0,"finish_kmh":121.0,"sixty_ft":3.0,"eighth":12.0}
    check(garage.record_finish(ticket) and not garage.record_finish(ticket),"A completed attempt can record a personal best once")
    check(game.balance==balance,"Records and retries cannot mint credits or charge hidden fees")
    var path := "user://drag-save-%d.json" % Time.get_ticks_usec()
    check(Store.save_file(path,game,career)==OK,"Drag wear and records can be written using the existing atomic save path")
    var loaded: Dictionary = Store.load_file(path)
    check(loaded.get("error")=="" and loaded.career.drag_records.best(1)==ticket,"Actual JSON files restore complete per-car timing tickets")
    var health_matches := true
    for component in vehicle.health:
        health_matches = health_matches and is_equal_approx(float(loaded.game.find_car(1).health[component]),float(vehicle.health[component]))
    check(health_matches,"Mechanical stress survives a real game save/reload")
    var legacy: Dictionary = career.to_dict()
    legacy.erase("drag_records")
    var old = Career.new()
    check(old.from_dict(legacy) and old.drag_records.best(1).is_empty(),"Older career saves without quarter-mile records remain loadable")
    var previous: Dictionary = career.to_dict()
    var corrupt := previous.duplicate(true)
    corrupt["drag_records"]["1"]["et"] = NAN
    check(not career.from_dict(corrupt) and career.to_dict()==previous,"Corrupt new record data cannot replace the current valid career")
    var settings = Settings.new()
    var old_controls: Dictionary = settings.to_dict()
    old_controls.erase("drag_keys")
    old_controls["keys"]["accelerate"] = KEY_E
    check(settings.from_dict(old_controls) and settings.keys.accelerate==KEY_E,"Legacy custom bindings are preserved even when they used the new default shift key")
    check(settings.drag_keys.shift_up!=KEY_E and settings.all_keys().values().size()==11,"Migration assigns a free key for each manual action instead of stealing an existing binding")
    check(settings.bind("shift_up",KEY_U).is_empty(),"Manual shifts are rebindable through the same settings interface")
    var preferences := "user://drag-controls-%d.json" % Time.get_ticks_usec()
    check(settings.save_file(preferences)==OK,"Migrated manual controls persist in the existing preference schema")
    var restored = Settings.new()
    check(restored.load_file(preferences) and restored.drag_keys.shift_up==KEY_U and restored.keys.accelerate==KEY_E,"Manual and original controls survive file reload together")
    check(not restored.bind("clutch",KEY_E).is_empty(),"A clutch binding cannot collide with acceleration")
    career.begin_track_entry(game,"debut",1)
    check(not Garage.new().begin(game,career,1),"A paid circuit admission cannot overlap a free drag session")
    career.cancel_track_entry(game,true)
    vehicle.health.motor = 0.0
    check(not Garage.new().begin(game,career,1),"Unroadworthy vehicles still require repair before timed practice")
    DirAccess.remove_absolute(path)
    DirAccess.remove_absolute(preferences)
    if not failed:
        print("PASS: %d drag garage assertions" % checks)
    quit(1 if failed else 0)
