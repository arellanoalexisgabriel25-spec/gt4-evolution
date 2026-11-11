extends Node3D

const Strip = preload("res://scripts/drag_strip.gd")
const Actor = preload("res://scripts/drag_actor.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Camera = preload("res://scripts/chase_camera.gd")
const Run = preload("res://scripts/drag_run.gd")
const Garage = preload("res://scripts/drag_garage_session.gd")
const HUD = preload("res://scripts/drag_hud.gd")
const Audio = preload("res://scripts/engine_audio.gd")
const Controls = preload("res://scripts/control_settings.gd")
const PauseMenu = preload("res://scripts/pause_menu.gd")
const Duel = preload("res://scripts/drag_duel.gd")
const Classes = preload("res://scripts/drag_class_rules.gd")
const Procedure = preload("res://scripts/drag_start_procedure.gd")
const WARMUP_POSITION := 5.0 # Ahead of the line, art.11; never a timed spawn.
const WARMUP_LIMIT := 35.0
const RivalDriver = preload("res://scripts/drag_rival_driver.gd")
var procedure = Procedure.new()
var alignment_pending := false
var _opponent_alignment_pending := false
var strip
var car
var camera
var hud
var engine_audio
var run = Run.new()
var garage = Garage.new()
var paused := false
var leaving := false
var enabled := false
var personal_best := false
var handled_finish := false
var message := ""
var message_time := 0.0
var input_provider: Callable
var attempt_wear_start: Dictionary = {}
var pause_menu
var last_pad := -1
var controller_lost := false
var is_duel := false
var class_data: Dictionary = {}
var opponent
var opponent_run = Run.new()
var opponent_driver
var duel = Duel.new()
var duel_result: Dictionary = {}
var opponent_audio
var opponent_name := "Nico Vega"
var _sampled_controls: Dictionary = {}
var _applied_controls: Dictionary = {}
var _last_player_ready := false

func _ready() -> void:
    GameSession.menu_music.set_menu_active(false)
    var vehicle: Dictionary = GameSession.game.find_car(GameSession.selected_vehicle)
    enabled = GameSession.driving_mode == "drag" and garage.begin(GameSession.game,GameSession.career,GameSession.selected_vehicle)
    is_duel = GameSession.drag_format=="duel"
    class_data = Classes.class_by_id(GameSession.drag_class_id) if is_duel else {}
    opponent_name = {"technical":"Nico Vega","aggressive":"Claire Moreau","conservative":"Akira Sato"}.get(GameSession.drag_rival_profile,"Nico Vega")
    strip = Strip.new()
    strip.dual_lanes = is_duel
    add_child(strip)
    car = Actor.new()
    car.model_name = str(vehicle.get("model",""))
    car.color = Color("963645")
    car.position = Vector3(Strip.LANE_X,0.75,-WARMUP_POSITION)
    car.collision_layer = 2
    car.collision_mask = 3 if is_duel else 1
    car.powertrain.config = Config.from_vehicle(vehicle,is_duel)
    if not is_duel:
        car.powertrain.config.abs_assist = GameSession.controls.abs_assist
        car.powertrain.traction_control = GameSession.controls.traction_control
    car.powertrain.reset(false)
    _apply_transmission_preferences()
    add_child(car)
    camera = Camera.new()
    camera.target = car
    camera.mode = GameSession.controls.camera_mode
    camera.current = true
    add_child(camera)
    camera.snap()
    var canvas := CanvasLayer.new()
    add_child(canvas)
    hud = HUD.new()
    canvas.add_child(hud)
    hud.return_requested.connect(_back_to_garage)
    hud.camera_requested.connect(_cycle_camera)
    engine_audio = Audio.new()
    engine_audio.model = car.powertrain
    engine_audio.vehicle_model = car.model_name
    engine_audio.source_actor = car
    add_child(engine_audio)
    if is_duel:
        _create_opponent(vehicle)
        camera.race_peer = opponent
        camera.snap()
    pause_menu = PauseMenu.new()
    pause_menu.mode = self
    canvas.add_child(pause_menu)
    Input.joy_connection_changed.connect(_controller_connection)
    get_window().focus_exited.connect(_focus_lost)
    if not enabled:
        message = "Seleccioná un auto propio y apto desde el garaje."
    _refresh_hud()

func _create_opponent(vehicle: Dictionary) -> void:
    opponent = Actor.new()
    opponent.model_name = GameSession.drag_opponent_model if not GameSession.drag_opponent_model.is_empty() else str(vehicle.get("model",""))
    opponent.driver_name = opponent_name
    opponent.color = Color("345c8a")
    opponent.position = Vector3(-Strip.LANE_X,0.75,-WARMUP_POSITION)
    opponent.collision_layer = 2
    opponent.collision_mask = 3
    var stock: Dictionary = vehicle.duplicate(true)
    stock["model"] = opponent.model_name
    stock["upgrades"] = []
    stock["tire_compound"] = "street"
    for component in stock.get("health",{}):
        stock["health"][component] = 100.0
    opponent.powertrain.config = Config.from_vehicle(stock,true)
    opponent.powertrain.traction_control = car.powertrain.traction_control
    opponent.powertrain.reset(false)
    add_child(opponent)
    opponent_driver = RivalDriver.new(GameSession.drag_rival_profile)
    opponent_driver.controls(opponent.powertrain,0,1.0/60.0)
    opponent_audio = Audio.new()
    opponent_audio.model = opponent.powertrain
    opponent_audio.vehicle_model = opponent.model_name
    opponent_audio.source_actor = opponent
    add_child(opponent_audio)
    opponent_audio.volume_db = -24.0

func _advance_opponent(delta: float) -> void:
    var controls: Dictionary = opponent_driver.controls(opponent.powertrain,opponent_run.clock,delta)
    if opponent_run.phase in ["finished","invalid"] or duel.finished:
        controls = {"throttle":0.0,"clutch":1.0,"brake":0.8,"steer":0.0}
    if _opponent_alignment_pending or procedure.phase=="expired":
        controls = {"throttle":0.0,"clutch":1.0,"brake":1.0,"steer":0.0}
    opponent.drive_manual(delta,controls,absf(opponent.position.x)<8.5)

func _duel_result() -> void:
    if duel.finished and duel_result.is_empty():
        duel_result = duel.report()

func _controls() -> Dictionary:
    if input_provider.is_valid():
        return input_provider.call()
    var controls: Dictionary = GameSession.controls.read_controls(true,car.powertrain.config.transmission_type=="cvt")
    controls["clutch"] = GameSession.controls.clutch_input()
    return controls

func _apply_transmission_preferences() -> void:
    car.powertrain.shift_mode = GameSession.controls.shift_mode
    car.powertrain.auto_rev_match = GameSession.controls.auto_rev_match

func _readiness_issue(controls: Dictionary) -> String:
    var model = car.powertrain
    if not _mechanically_ready(): return "MECÁNICA NO APTA · Revisá el taller"
    if model.gear<0: return "MARCHA ATRÁS · Seleccioná N y luego primera"
    if model.gear==0: return "PUNTO MUERTO · Seleccioná D" if model.config.transmission_type=="cvt" else "PUNTO MUERTO · Embrague y subir marcha"
    if model.gear!=1: return "ALINEACIÓN · Seleccioná primera"
    if not model.engine_running: return model.shift_hint()
    if absf(model.speed_mps)>=0.10: return "ALINEACIÓN · Detené el auto"
    if not _staged(): return "ALINEACIÓN · Esperá apoyo y posición estable"
    if model.config.transmission_type=="cvt":
        if maxf(float(controls.get("brake",0.0)),-float(controls.get("throttle",0.0)))<0.7: return "MANTENÉ EL FRENO PARA ALINEAR"
    elif model.shift_mode=="manual" and float(controls.get("clutch",0.0))<model.config.clutch_release_pedal:
        return "MANTENÉ EL EMBRAGUE PARA ALINEAR"
    elif model.shift_mode!="manual" and float(controls.get("brake",0.0))<0.7:
        return "MANTENÉ EL FRENO PARA ALINEAR"
    elif model.shift_mode!="manual" and model.effective_clutch_pedal<model.config.clutch_release_pedal:
        return "ACOPLE ASISTIDO · ESPERÁ EL DESEMBRAGUE"
    return ""

func _launch_hint(controls: Dictionary) -> String:
    if run.phase!="running": return ""
    var model = car.powertrain
    if model.clutch_health<=0.0: return "TRANSMISIÓN AGOTADA · REQUIERE TALLER" if model.config.transmission_type=="cvt" else "EMBRAGUE AGOTADO · REQUIERE TALLER"
    if not model.engine_running: return model.shift_hint()
    if model.gear==0: return "VERDE · PUNTO MUERTO, SELECCIONÁ UNA MARCHA"
    if model.gear<0: return "MARCHA ATRÁS · NO ES UNA LARGADA VÁLIDA"
    if absf(model.speed_mps)>8.0 or (run.launch_time>=0.0 and run.elapsed>5.0): return ""
    if float(controls.get("handbrake",0.0))>0.15: return "FRENO DE MANO APLICADO · LIBERALO PARA LARGAR"
    if maxf(float(controls.get("brake",0.0)),-float(controls.get("throttle",0.0)))>0.15: return "FRENO APLICADO · LIBERALO PARA LARGAR"
    if model.config.transmission_type!="cvt" and model.shift_mode=="manual" and float(controls.get("clutch",0.0))>=model.config.clutch_release_pedal:
        return "VERDE · SOLTÁ PROGRESIVAMENTE EL EMBRAGUE"
    if float(controls.get("throttle",0.0))<0.05: return "VERDE · ACELERÁ Y CONTROLÁ EL ACOPLE"
    return ""

func _controller_connection(device: int, connected: bool) -> void:
    if not connected and device==last_pad and enabled and not leaving:
        paused = true
        controller_lost = true
        message = "Mando desconectado · Reconectá o continuá con teclado"
        message_time = 5.0

func _focus_lost() -> void:
    # Alt-Tab may prevent a matching pedal/button release reaching the scene.
    # Clear the cached input and pause explicitly; focus returning never resumes.
    for action_name in GameSession.controls.all_keys():
        Input.action_release(Controls.action(action_name))
    GameSession.controls.controller.reset_cached()
    if enabled and not leaving:
        paused = true
        message = "VENTANA INACTIVA · P/Inicio para continuar"
        message_time = 5.0

func _in_lane() -> bool:
    return absf(car.position.x-Strip.LANE_X) <= 2.7

func _staged() -> bool:
    return absf(car.position.z)<=0.10 and absf(car.powertrain.speed_mps)<0.10 and _in_lane() and int(car.ground_state.get("wheels_on_ground",0))==4

func _ready_for_start(controls: Dictionary = {}) -> bool:
    if controls.is_empty(): controls=_controls()
    return enabled and not paused and run.phase=="preparation" and _readiness_issue(controls).is_empty()

func _can_arm(controls: Dictionary = {}) -> bool:
    return procedure.phase=="countdown" and _ready_for_start(controls)

func _opponent_ready() -> bool:
    if not is_duel:
        return true
    return absf(opponent.position.z)<=0.10 and absf(opponent.powertrain.speed_mps)<0.10 and absf(opponent.position.x+Strip.LANE_X)<=2.7 and opponent.powertrain.gear==1 and opponent.powertrain.engine_running and opponent.powertrain.clutch_engagement<0.25 and int(opponent.ground_state.get("wheels_on_ground",0))==4

func _warmup_in_zone() -> bool:
    # Both axles of every supplied stock car begin ahead of the painted line.
    return -car.position.z>=2.5 and -car.position.z<=WARMUP_LIMIT and _in_lane() and not car.is_on_wall()

func _advance_procedure(delta: float, controls: Dictionary = {}) -> void:
    if run.phase!="preparation":
        return
    if procedure.phase=="burnout" and not _warmup_in_zone():
        procedure.cancel_start("FUERA DE ZONA DE CALENTAMIENTO · R PARA REPETIR")
    if alignment_pending and car.powertrain.gear<0:
        # Selecting reverse is an explicit choice to return to the beam under
        # the driver's own controls. Do not stop/teleport that return forever.
        alignment_pending = false
    if alignment_pending and absf(car.powertrain.speed_mps)<0.15:
        car.align_for_start(Vector3(Strip.LANE_X,0.75,0))
        alignment_pending = false
        camera.snap()
    # Each lane owns its preparation movement. A manual reverse return must
    # never leave the AI waiting five metres in front of its timing beam.
    if _opponent_alignment_pending and absf(opponent.powertrain.speed_mps)<0.15:
        opponent.align_for_start(Vector3(-Strip.LANE_X,0.75,0))
        _opponent_alignment_pending = false
    var previous_phase: String = procedure.phase
    if controls.is_empty(): controls=_controls()
    _last_player_ready = _ready_for_start(controls) and not alignment_pending
    procedure.advance(delta,_last_player_ready,_opponent_ready() and not _opponent_alignment_pending)
    if previous_phase=="burnout" and procedure.phase=="staging":
        alignment_pending = true
        _opponent_alignment_pending = is_duel
    if procedure.consume_start():
        _arm(controls)

func _mechanically_ready() -> bool:
    var model = car.powertrain
    return model.config.engine_health-float(model.wear["motor"])>=20.0 and model.config.brake_health-float(model.wear["frenos"])>=40.0 and model.config.tire_health-float(model.wear["neumaticos"])>=40.0 and model.clutch_health>0.0

func _arm(controls: Dictionary = {}) -> void:
    if not _can_arm(controls):
        procedure.cancel_start("ALINEACIÓN PERDIDA · R PARA REPETIR")
        message = procedure.reason
        message_time = 3.0
        return
    if run.arm(-car.position.z,car.powertrain.speed_mps):
        if is_duel:
            if not opponent_run.arm(-opponent.position.z,opponent.powertrain.speed_mps) or not duel.begin(run,opponent_run,float(class_data.get("minimum_et",0.0)),123.0,"argentina_reference" if not class_data.is_empty() else "legacy_practice"):
                run = Run.new()
                opponent_run = Run.new()
                procedure.cancel_start("EL RIVAL NO ESTÁ ALINEADO · R PARA REPETIR")
                message = procedure.reason
                message_time = 3.0
                return
        message = ""
        message_time = 0.0
        car.reset_metrics()
        if is_duel:
            opponent.reset_metrics()

func _physics_process(delta: float) -> void:
    if not enabled or leaving:
        return
    var look: Dictionary = GameSession.controls.camera_look()
    camera.look_input = look["axis"]
    camera.look_back = Input.is_physical_key_pressed(KEY_SHIFT)
    if GameSession.controls.controller.selected()>=0:
        last_pad = GameSession.controls.controller.selected()
    camera.look_back = camera.look_back or GameSession.controls.controller.pressed(JOY_BUTTON_RIGHT_STICK)
    engine_audio.stream_paused = paused
    if is_duel:
        opponent_audio.stream_paused = paused
    if paused:
        _refresh_hud()
        return
    message_time = maxf(0,message_time-delta)
    if message_time == 0.0:
        message = ""
    var controls := _controls().duplicate()
    _sampled_controls = controls.duplicate()
    _apply_transmission_preferences()
    if not _mechanically_ready():
        controls["throttle"] = 0.0
        controls["brake"] = 1.0
        controls["clutch"] = 1.0
        message = "MECÁNICA NO APTA · Volvé al taller para reparar"
        message_time = 2.0
    # Alignment assistance waits for the player to stop; it never presses
    # pedals on their behalf. Reverse immediately cancels the placement.
    # A false start or an opponent finishing does not disable the driver's
    # controls. A completed run still brakes automatically in the runoff.
    if run.phase == "finished":
        controls["throttle"] = 0.0
        controls["brake"] = maxf(0.65,float(controls.get("brake",0.0)))
        controls["clutch"] = 1.0
    _applied_controls = controls.duplicate()
    car.drive_manual(delta,controls,absf(car.position.x)<8.5)
    garage.measured_distance = car.distance_m
    if is_duel:
        _advance_opponent(delta)
    _advance_procedure(delta,_sampled_controls)
    run.advance(delta,-car.position.z,car.powertrain.speed_mps,_in_lane() and not car.is_on_wall())
    if is_duel:
        opponent_run.advance(delta,-opponent.position.z,opponent.powertrain.speed_mps,absf(opponent.position.x+Strip.LANE_X)<=2.7 and not opponent.is_on_wall())
        duel.advance(delta)
        _duel_result()
    if run.phase == "finished" and not handled_finish:
        if garage.settle(car.powertrain.wear,car.damage):
            if is_duel:
                personal_best = GameSession.career.stock_drag_records.consider_for_profile(GameSession.selected_vehicle,run.report(),garage.record_profile)
            else:
                personal_best = garage.record_finish(run.report())
            handled_finish = true
    strip.update_tree(run,_staged(),opponent_run if is_duel else null,is_duel and absf(opponent.position.z)<0.1 and opponent.powertrain.speed_mps<0.1,procedure.snapshot())
    _refresh_hud()

func _refresh_hud() -> void:
    var best: Dictionary = (GameSession.career.stock_drag_records if is_duel else GameSession.career.drag_records).best_for_profile(GameSession.selected_vehicle,garage.record_profile)
    hud.refresh({"raw_controls":_sampled_controls,"applied_controls":_applied_controls,"readiness_issue":_readiness_issue(_sampled_controls) if procedure.phase=="staging" else "","launch_hint":_launch_hint(_sampled_controls),"procedure_phase":procedure.phase,"procedure_remaining":procedure.remaining,"procedure_message":procedure.status(),"procedure_ready":procedure.player_ready and procedure.rival_ready,"model":car.powertrain,"run":run,"settings":GameSession.controls,"name":car.model_name,"position":-car.position.z,"best":best,"staged":_staged(),"can_arm":procedure.phase=="countdown" and _last_player_ready,"message":message,"paused":paused,"personal_best":personal_best,"wear_start":attempt_wear_start,"impacts":car.damage.impacts,"damage":car.damage.cumulative,"duel":is_duel,"opponent_name":opponent_name,"opponent_model":opponent.model_name if is_duel else "","opponent_run":opponent_run,"opponent_gap":opponent.position.z-car.position.z if is_duel else 0.0,"duel_result":duel_result,"zero_to_hundred":car.zero_to_hundred,"class_data":class_data,"ground":car.ground_state})

func _shift(direction: int) -> void:
    if enabled and not leaving and not paused and run.phase not in ["finished","invalid"]:
        car.powertrain.request_shift(direction,float(_controls().get("clutch",0.0)))

func _recover() -> void:
    if not enabled or leaving:
        return
    if not garage.settle(car.powertrain.wear,car.damage):
        message = "No se pudo registrar el uso. Volvé al garaje."
        message_time = 5.0
        return
    car.recover(Vector3(Strip.LANE_X,0.75,-WARMUP_POSITION))
    _sampled_controls.clear()
    _applied_controls.clear()
    _last_player_ready = false
    procedure.reset()
    alignment_pending = false
    _opponent_alignment_pending = false
    attempt_wear_start = car.powertrain.wear.duplicate(true)
    run = Run.new()
    if is_duel:
        opponent.recover(Vector3(-Strip.LANE_X,0.75,-WARMUP_POSITION))
        opponent_run = Run.new()
        opponent_driver.reset()
        opponent_driver.controls(opponent.powertrain,0,1.0/60.0)
        duel = Duel.new()
        duel_result.clear()
    garage.next_attempt()
    handled_finish = false
    personal_best = false
    message = ""
    message_time = 0.0
    paused = false
    camera.snap()
    _refresh_hud()

func _cycle_camera() -> void:
    camera.cycle_mode()
    GameSession.controls.camera_mode = camera.mode

func _input(event: InputEvent) -> void:
    var viewport := get_viewport()
    var fresh: bool = GameSession.controls.controller.feed(event)
    if event is InputEventJoypadButton or event is InputEventJoypadMotion:
        last_pad = GameSession.controls.controller.selected()
    if not enabled or leaving or (event is InputEventKey and event.echo):
        return
    var pad: bool = event is InputEventJoypadButton and fresh
    if GameSession.controls.key_event_pressed(event,"shift_up") or event.is_action_pressed(Controls.action("shift_up")) or (pad and event.button_index==JOY_BUTTON_A):
        _shift(1)
    elif GameSession.controls.key_event_pressed(event,"shift_down") or event.is_action_pressed(Controls.action("shift_down")) or (pad and event.button_index==JOY_BUTTON_Y):
        _shift(-1)
    elif event.is_action_pressed(Controls.action("recover")) or (pad and event.button_index==JOY_BUTTON_X):
        _recover()
    elif event.is_action_pressed(Controls.action("pause")) or (pad and event.button_index==JOY_BUTTON_START):
        paused = not paused
    elif pad and event.button_index==JOY_BUTTON_BACK:
        paused = not paused
    elif (event is InputEventKey and event.pressed and event.physical_keycode==KEY_TAB) or (pad and event.button_index==JOY_BUTTON_RIGHT_SHOULDER):
        _cycle_camera()
    elif event is InputEventKey and event.pressed and event.physical_keycode==KEY_ESCAPE:
        _back_to_garage()
    else:
        var driving_event := event is InputEventJoypadButton or event is InputEventJoypadMotion
        for name in GameSession.controls.all_keys():
            driving_event = driving_event or event.is_action(Controls.action(name))
        if not driving_event:
            return
    viewport.set_input_as_handled()

func _back_to_garage() -> void:
    if leaving:
        return
    if enabled and not garage.settle(car.powertrain.wear,car.damage):
        message = "No se pudo registrar el uso."
        message_time = 5.0
        return
    leaving = true
    GameSession.last_notice = "¼ de milla: uso y desgaste registrados. Guardá para conservar marcas y progreso."
    GameSession.selected_vehicle = 0
    GameSession.driving_mode = "practice"
    GameSession.menu_tab = "garaje"
    get_tree().change_scene_to_file("res://scenes/main.tscn")
