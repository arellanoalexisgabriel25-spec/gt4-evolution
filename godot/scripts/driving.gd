extends Node3D

const Hud = preload("res://scripts/race_hud.gd")
const Layout = preload("res://scripts/circuit_layout.gd")
const CircuitView = preload("res://scripts/circuit_view.gd")
const Actor = preload("res://scripts/vehicle_actor.gd")
const ChaseCamera = preload("res://scripts/chase_camera.gd")
const Driver = preload("res://scripts/rival_driver.gd")
const Race = preload("res://scripts/race_session.gd")
const Rivals = preload("res://scripts/rivals.gd")
const Trial = preload("res://scripts/time_trial.gd")
const ControlSettings = preload("res://scripts/control_settings.gd")
const Handling = preload("res://scripts/handling.gd")

var circuit = Layout.new()
var TRACK: Array:
    get: return circuit.gates
var car
var camera
var trial = Trial.new()
var physics:
    get: return car.physics
var speed_mps: float:
    get: return car.physics.signed_speed()
var distance_m: float:
    get: return car.distance_m
var readout: Label
var race_readout: Label
var hud
var enabled := false
var paused := false
var leaving := false
var settled := false
var outcome_handled := false
var outcome_text := ""
var career_event := false
var recorded_laps := 0
var race
var opponents: Array[Dictionary] = []
# Optional normalized input provider also enables real-scene navigation tests.
var input_provider: Callable

func _ready() -> void:
    var view = CircuitView.new()
    view.layout = circuit
    add_child(view)
    car = _spawn("player", "", Vector3(0, 0.75, 58), Color("ba3737"))
    enabled = GameSession.choose_vehicle(GameSession.selected_vehicle)
    if enabled:
        car.physics.config = Handling.configuration(GameSession.game.find_car(GameSession.selected_vehicle))
    trial.reset(car.position, circuit.gates, circuit.gate_directions)
    camera = ChaseCamera.new()
    add_child(camera)
    camera.target = car
    camera.current = true
    camera.mode = GameSession.controls.camera_mode
    camera.snap()
    if enabled and GameSession.driving_mode == "race":
        _start_race()
    if enabled:
        trial.best_time = GameSession.career.lap_records.get_best(GameSession.selected_vehicle)
    _build_hud()
    if not enabled:
        if not GameSession.entry_ticket.is_empty():
            if bool(GameSession.entry_ticket["started"]):
                GameSession.last_notice = GameSession.abandon_track_event()
            else:
                GameSession.cancel_unstarted_entry()
                GameSession.last_notice = "Carrera no disponible; inscripción reembolsada."
        readout.text = "Elegí primero un vehículo apto en el garaje."

func _spawn(id: String, name_text: String, location: Vector3, color: Color):
    var vehicle = Actor.new()
    vehicle.name = id
    vehicle.driver_name = name_text
    vehicle.position = location
    vehicle.color = color
    if id == "player":
        vehicle.model_name = str(GameSession.game.find_car(GameSession.selected_vehicle).get("model", ""))
    else:
        vehicle.model_name = "Honda Civic" if id == "nico" else "Mazda MX-5"
    vehicle.collision_layer = 2
    vehicle.collision_mask = 3
    add_child(vehicle)
    return vehicle

func _start_race() -> void:
    race = Race.new()
    race.circuit = circuit
    career_event = not GameSession.entry_ticket.is_empty()
    if not GameSession.attach_race(race):
        enabled = false
        return
    race.add_entry("player", "Vos", car.position)
    trial = race.entries["player"]["trial"]
    var profiles: Array = Rivals.new().field_for_event("debut")
    for i in range(profiles.size()):
        var profile: Dictionary = profiles[i]
        var actor = _spawn(profile["id"], profile["name"], Vector3(-3.0 if i == 0 else 3.0, 0.75, 63.0 + i * 5.0), Color("357acb") if i == 0 else Color("e8c44a"))
        var brain = Driver.new()
        brain.profile = profile.duplicate(true)
        brain.preferred_side = -1.0 if i == 0 else 1.0
        race.add_entry(profile["id"], profile["name"], actor.position)
        opponents.append({"id":profile["id"], "actor":actor, "driver":brain, "stuck":0.0})

func _build_hud() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)
    hud = Hud.new()
    canvas.add_child(hud)
    hud.track_map.set_route(circuit.points)
    hud.return_requested.connect(_back_to_garage)
    hud.camera_requested.connect(_cycle_camera)
    readout = hud.lap_details
    race_readout = hud.ranking

func _cycle_camera() -> void:
    camera.cycle_mode()
    GameSession.controls.camera_mode = camera.mode

func _player_controls() -> Dictionary:
    if input_provider.is_valid():
        return input_provider.call()
    return GameSession.controls.read_controls()

func _physics_process(delta: float) -> void:
    if not enabled or leaving:
        return
    var look: Dictionary = GameSession.controls.camera_look()
    camera.look_input = look["axis"]
    camera.look_back = look["back"]
    if paused:
        _refresh_hud()
        return
    if race == null:
        car.drive(delta, _player_controls(), _on_road(car.position))
        if not _on_road(car.position):
            trial.valid = false
        trial.advance(car.position, delta)
    else:
        race.tick(delta)
        var traffic: Array = []
        if not race.is_finished("player"):
            traffic.append(car.snapshot("player"))
        for opponent in opponents:
            if not race.is_finished(opponent["id"]):
                traffic.append(opponent["actor"].snapshot(opponent["id"]))
        if race.can_drive("player"):
            car.drive(delta, _player_controls(), _on_road(car.position))
            race.observe("player", car.position, delta)
            if race.is_finished("player"):
                _hold(car, 0.0, true)
        else:
            _hold(car, delta, race.is_finished("player"))
        for opponent in opponents:
            var actor = opponent["actor"]
            var id: String = opponent["id"]
            if race.can_drive(id):
                var others: Array = traffic.filter(func(item: Dictionary) -> bool: return item["id"] != id)
                var controls: Dictionary = opponent["driver"].controls(delta, actor.position, actor.physics, circuit, others)
                actor.drive(delta, controls, _on_road(actor.position))
                race.observe(id, actor.position, delta)
                if race.is_finished(id):
                    _hold(actor, 0.0, true)
                opponent["stuck"] = float(opponent["stuck"]) + delta if actor.physics.velocity.length() < 0.5 else 0.0
                if float(opponent["stuck"]) > 8.0 or actor.position.y < -5.0:
                    _recover_opponent(opponent)
            else:
                _hold(actor, delta, race.is_finished(id))
        race.finish_tick()
        if race.phase == "finished" and not outcome_handled:
            outcome_handled = true
            if career_event:
                outcome_text = GameSession.finish_track_event(race)
    if car.position.y < -5.0:
        _reset_car()
    if trial.completed_laps > recorded_laps:
        GameSession.career.lap_records.consider(GameSession.selected_vehicle, trial.last_time)
        recorded_laps = trial.completed_laps
    _refresh_hud()

func _hold(actor, delta: float, finished: bool) -> void:
    if finished:
        actor.collision_layer = 0 # Parked finishers do not block active racers.
        actor.velocity = Vector3.ZERO
        actor.physics.velocity = Vector2.ZERO
        actor.physics.rpm = actor.physics.config.idle_rpm
        actor.physics.gear = 1
    else:
        actor.drive(delta, {"brake":true}, _on_road(actor.position))

func _recover_opponent(opponent: Dictionary) -> void:
    var location := Vector3(-3.0 if opponent["driver"].preferred_side < 0 else 3.0, 0.75, 63)
    opponent["actor"].recover(location)
    opponent["stuck"] = 0.0
    race.recover(opponent["id"], location)

func _reset_car() -> void:
    if race != null and (race.phase != "running" or race.is_finished("player")):
        return
    car.recover(circuit.points[0] + Vector3.UP * 0.75)
    if race != null:
        race.recover("player", car.position)
    else:
        trial.reset(car.position, circuit.gates, circuit.gate_directions)
    camera.snap()

func _on_road(position: Vector3) -> bool:
    return circuit.on_road(position)

func _refresh_hud() -> void:
    var displayed_lap: int = mini(trial.completed_laps + 1,race.laps) if race != null else trial.completed_laps + 1
    var lap_text := "VUELTA %d%s" % [displayed_lap," / %d" % race.laps if race != null else ""]
    var ranking_text := "CONTROL %d / 8" % trial.passed_gates
    var status := ""
    if not trial.valid:
        status = "VUELTA INVÁLIDA · Completá la vuelta o recuperá"
    if paused:
        status = "PAUSA"
    elif race != null:
        if race.phase == "countdown":
            status = "SALIDA EN %d" % ceili(race.countdown)
        elif race.phase == "finished":
            status = outcome_text if career_event else "CARRERA FINALIZADA"
        elif race.is_finished("player"):
            status = "LLEGADA · Esperando a los demás"
        elif float(race.entries["player"]["hold"]) > 0.0:
            status = "RECUPERANDO · %.1f s" % race.entries["player"]["hold"]
        ranking_text = ""
        for row in race.standings():
            var detail := "%.2f s" % row["time"] if row["time"] >= 0.0 else ("DNF" if row["dnf"] else "V%d" % (int(row["laps"]) + 1))
            ranking_text += "%d  %s   %s\n" % [row["position"],row["name"],detail]
    var help := "TAB / RB: cámara · SHIFT / Y: mirar atrás"
    if paused or physics.speed() < 1.0:
        help = GameSession.controls.help_text() + "\nTAB / RB: cámara · SHIFT / Y: mirar atrás"
    var positions := [car.global_position]
    for opponent in opponents:
        positions.append(opponent["actor"].global_position)
    hud.update_telemetry({"speed":physics.speed()*3.6,"gear":physics.gear,"rpm":physics.rpm,"redline":physics.config.redline_rpm,"time":trial.elapsed,"best":trial.best_time,"camera":camera.MODES[camera.mode],"lap":lap_text,"ranking":ranking_text.strip_edges(),"status":status,"help":help,"positions":positions})

func _input(event: InputEvent) -> void:
    if not enabled or leaving:
        return
    if event is InputEventKey and event.echo:
        return
    var pad_pressed: bool = event is InputEventJoypadButton and event.pressed
    if (event is InputEventKey and event.pressed and event.physical_keycode == KEY_TAB) or (pad_pressed and event.button_index == JOY_BUTTON_RIGHT_SHOULDER):
        _cycle_camera()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed(ControlSettings.action("recover")) or (pad_pressed and event.button_index == JOY_BUTTON_X):
        _reset_car()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed(ControlSettings.action("pause")) or (pad_pressed and event.button_index == JOY_BUTTON_START):
        paused = not paused
        get_viewport().set_input_as_handled()
    elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
        # ui_cancel also maps to controller B, which is reverse while driving.
        get_viewport().set_input_as_handled()
        _back_to_garage()
    elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
        get_viewport().set_input_as_handled()
    else:
        for name in ControlSettings.DEFAULT_KEYS:
            if event.is_action(ControlSettings.action(name)):
                # Driving inputs must not activate a focused garage-return button.
                get_viewport().set_input_as_handled()
                break

func _back_to_garage() -> void:
    if leaving:
        return
    leaving = true
    if enabled and not settled:
        GameSession.game.record_distance(GameSession.selected_vehicle, distance_m, 2.5 if race != null else 1.0)
        settled = true
        var summary := "Carrera libre sin premios." if race != null else "Contrarreloj de práctica."
        if career_event:
            summary = outcome_text if outcome_handled else GameSession.abandon_track_event()
        GameSession.last_notice = "Conducción registrada: %.0f m. %s Guardá la partida para conservar los cambios." % [distance_m, summary]
    GameSession.selected_vehicle = 0
    GameSession.driving_mode = "practice"
    GameSession.menu_tab = "garaje"
    get_tree().change_scene_to_file("res://scenes/main.tscn")
