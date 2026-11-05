extends Control

signal return_requested
signal camera_requested
# Kept for callers of the previous HUD; the starter now controls the tree.
@warning_ignore("unused_signal")
signal arm_requested
const Style = preload("res://scripts/racing_theme.gd")
const Run = preload("res://scripts/drag_run.gd")
const Tire = preload("res://scripts/tire_model.gd")
const Instruments = preload("res://scripts/drag_instruments.gd")
var instruments
var model_label: Label
var clock_label: Label
var reaction_label: Label
var best_label: Label
var gear_label: Label
var speed_label: Label
var rpm_label: Label
var pedals_label: Label
var condition_label: Label
var power_label: Label
var environment_label: Label
var wear_label: Label
var damage_label: Label
var opponent_label: Label
var status_label: Label
var help_label: Label
var preparation_label: Label
var ticket_label: Label
var ticket_panel: PanelContainer
var details_panel: PanelContainer
var preparation_panel: PanelContainer
var opponent_panel: PanelContainer
var actions: HBoxContainer
var speed_panel: PanelContainer
var rpm_fraction := 0.0
var progress := 0.0
var tree_phase := "preparation"
var tree_clock := 0.0
var staged := true
var show_tree := false

func label(parent: Node, value: String, font_size: int) -> Label:
    var node := Label.new()
    node.text = value
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    node.add_theme_font_override("font",Style.FONT)
    node.add_theme_font_size_override("font_size",font_size)
    node.add_theme_color_override("font_color",Style.TEXT)
    parent.add_child(node)
    return node

func panel(rect: Rect2, anchor: Vector2 = Vector2.ZERO) -> PanelContainer:
    var node := PanelContainer.new()
    node.anchor_left = anchor.x
    node.anchor_right = anchor.x
    node.anchor_top = anchor.y
    node.anchor_bottom = anchor.y
    node.offset_left = rect.position.x
    node.offset_right = rect.end.x
    node.offset_top = rect.position.y
    node.offset_bottom = rect.end.y
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    node.add_theme_stylebox_override("panel",Style.panel(Style.HUD_BACKGROUND,8))
    add_child(node)
    return node

func column(parent: Node) -> VBoxContainer:
    var node := VBoxContainer.new()
    node.add_theme_constant_override("separation",2)
    parent.add_child(node)
    return node

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    theme = Style.build()
    var intro := column(panel(Rect2(18,16,278,62)))
    model_label = label(intro,"",18)
    model_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    best_label = label(intro,"",14)
    var clock := column(panel(Rect2(-158,16,316,74),Vector2(0.5,0)))
    status_label = label(clock,"",17)
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    clock_label = label(clock,"0.000 s",28)
    clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    reaction_label = label(clock,"",14)
    reaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    opponent_panel = panel(Rect2(-284,16,266,62),Vector2(1,0))
    var rival := column(opponent_panel)
    opponent_label = label(rival,"",16)
    opponent_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    actions = HBoxContainer.new()
    actions.offset_left = 18
    actions.offset_right = 244
    actions.offset_top = 86
    actions.offset_bottom = 116
    add_child(actions)
    for entry in [["GARAJE",return_requested],["CÁMARA",camera_requested]]:
        var button := Button.new()
        button.text = entry[0]
        button.add_theme_font_size_override("font_size",16)
        button.custom_minimum_size = Vector2(102,30)
        button.pressed.connect(func(): entry[1].emit())
        actions.add_child(button)
    speed_panel = panel(Rect2(-324,-162,306,144),Vector2.ONE)
    instruments = Instruments.new()
    instruments.custom_minimum_size = Vector2(290,128)
    instruments.mouse_filter = Control.MOUSE_FILTER_IGNORE
    speed_panel.add_child(instruments)
    gear_label = label(instruments,"N",27)
    gear_label.position = Vector2(193,89)
    gear_label.size = Vector2(54,32)
    gear_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    gear_label.add_theme_color_override("font_color",Style.SELECTED)
    speed_label = label(instruments,"0",27)
    speed_label.position = Vector2(38,89)
    speed_label.size = Vector2(64,32)
    speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    rpm_label = label(instruments,"900 RPM",10)
    rpm_label.position = Vector2(152,115)
    rpm_label.size = Vector2(136,13)
    rpm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    for metric in [gear_label,speed_label,rpm_label,clock_label,reaction_label,best_label]:
        metric.add_theme_font_override("font",Style.MONO)
    details_panel = panel(Rect2(18,-380,352,260),Vector2(0,1))
    # The pause menu shades the track; side diagnostics stay above that shade.
    details_panel.z_index = 2
    var details := column(details_panel)
    pedals_label = label(details,"",16)
    condition_label = label(details,"",15)
    power_label = label(details,"",15)
    environment_label = label(details,"",13)
    help_label = label(self,"",15)
    help_label.z_index = 2
    help_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    help_label.offset_left = 22
    help_label.offset_right = 395
    help_label.offset_top = -112
    help_label.offset_bottom = -18
    help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    help_label.add_theme_color_override("font_shadow_color",Color.BLACK)
    help_label.add_theme_constant_override("shadow_offset_x",1)
    help_label.add_theme_constant_override("shadow_offset_y",1)
    preparation_panel = panel(Rect2(-310,-124,620,104),Vector2(0.5,1))
    preparation_label = label(preparation_panel,"",17)
    preparation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    preparation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    ticket_panel = panel(Rect2(18,-390,350,370),Vector2(0,1))
    var ticket_body := column(ticket_panel)
    ticket_body.add_theme_constant_override("separation",6)
    ticket_label = label(ticket_body,"",19)
    ticket_label.add_theme_font_override("font",Style.MONO)
    ticket_label.add_theme_font_size_override("font_size",16)
    ticket_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    wear_label = label(ticket_body,"",15)
    damage_label = label(ticket_body,"",14)
    damage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    ticket_panel.visible = false
    details_panel.visible = false
    help_label.visible = false

func refresh(data: Dictionary) -> void:
    var model = data["model"]
    var run = data["run"]
    var settings = data["settings"]
    var is_duel: bool = data.get("duel",false)
    var paused: bool = data.get("paused",false)
    var preparing: bool = run.phase=="preparation"
    var procedure_phase := str(data.get("procedure_phase","staging"))
    var procedure_remaining := maxf(0.0,float(data.get("procedure_remaining",0.0)))
    var category: Dictionary = data.get("class_data",{})
    var duel_result: Dictionary = data.get("duel_result",{})
    var automatic: bool = model.config.transmission_type=="cvt"
    model_label.text = str(data["name"]) + (" / FÁBRICA" if is_duel else (" / CVT" if automatic else " / MANUAL"))
    model_label.tooltip_text = model_label.text
    opponent_panel.visible = is_duel
    if is_duel:
        var gap := float(data.get("opponent_gap",0.0))
        opponent_label.text = str(data["opponent_name"]).to_upper()+" · "+("%.1f m ATRÁS" % gap if gap>=0 else "%.1f m DELANTE" % -gap)+"\n"+str(data.get("opponent_model",""))
        opponent_label.tooltip_text = str(data.get("opponent_model",""))
    clock_label.text = "%.3f s" % run.elapsed
    reaction_label.text = "RT %.3f s" % run.reaction if run.launch_time>=0 else ""
    reaction_label.visible = not reaction_label.text.is_empty()
    gear_label.text = "N" if model.gear==0 else ("R" if model.gear<0 else str(model.gear))
    if automatic and model.gear>0: gear_label.text = "D"
    speed_label.text = "0" if absf(model.speed_mps)<0.15 else "%.0f" % absf(model.speed_mps*3.6)
    rpm_label.text = "%.0f RPM" % model.rpm
    instruments.readings(model.speed_mps*3.6,model.rpm,model.config.redline_rpm)
    pedals_label.text = "ACEL %.0f%%   EMBRAGUE %.0f%%" % [model.throttle*100,(1.0-model.clutch_engagement)*100]
    if automatic: pedals_label.text = "ACEL %.0f%% · CVT %.2f:1" % [model.throttle*100,model.cvt.ratio]
    condition_label.text = "GOMAS DL %.0f°C / TR %.0f°C · MOTOR %.0f°C\n%s · %s · %s" % [model.axles.temperatures.x,model.axles.temperatures.y,model.engine_temperature,model.config.drivetrain,"TCS ACTIVO" if model.tcs_cut<0.95 else ("TCS ON" if model.traction_control else "TCS OFF"),"ABS" if model.axles.abs_active else ("PATINA" if model.wheelspin>0.18 and model.gear>0 else "AGARRE")]
    var acceleration_time := float(data.get("zero_to_hundred",-1.0))
    power_label.text = "MOTOR %.0f Nm · EJE %.0f kW\n%s · EMBRAGUE PIERDE %.0f kW\n%s · IMPACTOS %d\nMASA %.0f kg · 0–100 %s" % [model.engine_torque_nm,model.wheel_power_kw,"TURBO %.0f%%" % (model.engine.boost*100) if model.config.turbo_fraction>0 else "ASPIRADO",model.clutch_loss_kw,Tire.title(model.config.tire_compound).to_upper(),int(data.get("impacts",0)),model.config.mass,"%.2f s" % acceleration_time if acceleration_time>=0 else "—"]
    if automatic: power_label.text = power_label.text.replace("EMBRAGUE","ACOPLE CVT")
    environment_label.text = "FRENOS DL %.0f°C / TR %.0f°C\nAIRE %.3f kg/m³ · VIENTO %+.1f m/s\nAERO %.0f N · RODADURA %.0f N\nGRAVEDAD %.2f m/s² · PENDIENTE %+.1f%%" % [model.brakes.temperatures.x,model.brakes.temperatures.y,model.config.air_density,model.wind_along,model.aerodynamic_force_n,model.rolling_force_n,model.config.gravity_mps2,-model.grade_acceleration/maxf(model.normal_g,0.1)*100.0]
    rpm_fraction = clampf(model.rpm/model.config.redline_rpm,0,1)
    progress = clampf(float(data["position"])/Run.DISTANCE,0,1)
    tree_phase = run.phase
    tree_clock = run.clock
    staged = data["staged"]
    show_tree = run.phase=="countdown" or (run.phase=="running" and run.clock<Run.GREEN_TIME+0.8)
    best_label.text = "MEJOR " + ("%.3f s" % data["best"]["et"] if not data["best"].is_empty() else "—")
    if is_duel:
        best_label.text = ("CLASE %s · PISO %.2f s" % [category.id,category.minimum_et] if not category.is_empty() else "LIBRE") + " · " + best_label.text
    var status := ""
    if preparing:
        var title: String = {"burnout":"CALENTAMIENTO", "call":"LLAMADO A LARGADA", "staging":"LLAMADO · ALINEACIÓN", "ready":"LISTOS", "timeout":"FUERA DE LLAMADO", "expired":"FUERA DE LLAMADO"}.get(procedure_phase,"PRELARGADA")
        status = str(data.get("procedure_message",title))
        if status.is_empty():
            status = title
        clock_label.text = "%d s" % int(ceil(procedure_remaining)) if procedure_remaining>0.0 else "ESPERÁ LA INDICACIÓN"
        if model.feedback_time>0.0:
            status = model.shift_hint()
        var clutch_key: String = settings.key_label("clutch")
        var up_key: String = settings.key_label("shift_up")
        var handbrake_key: String = settings.key_label("handbrake")
        var stop_keys := clutch_key+" + "+str(settings.key_label("brake"))
        var guide := "Asistencia de alineación y sostén · Primera con %s+%s.\nMantené %s embrague: el largador inicia automáticamente." % [clutch_key,up_key,clutch_key]
        if procedure_phase=="burnout":
            var technique := "Ráfagas %s + %s/L3 (FWD)" % [settings.key_label("accelerate"),handbrake_key] if model.config.drivetrain=="FWD" else "Ráfagas de acelerador con freno suave"
            guide = "%s+%s: primera · %s.\nPuede avanzar: zona 2,5–35 m · Para parar: %s." % [clutch_key,up_key,technique,stop_keys]
        elif procedure_phase in ["expired","timeout"]:
            guide = "Llamado vencido · %s: otra preparación.\nEl uso y el desgaste se conservan." % settings.key_label("recover")
        if automatic and procedure_phase not in ["expired","timeout"]:
            guide = "%s: N → D · %s/L3: freno de mano para calentar.\nCVT automática · Mantené el freno hasta el verde." % [up_key,handbrake_key]
        # The starter's status belongs above; it must never replace the guide.
        preparation_label.text = guide
        preparation_label.text += "\nGOMAS DL %.0f°C · TR %.0f°C" % [model.axles.temperatures.x,model.axles.temperatures.y]
        if bool(data.get("procedure_ready",false)):
            reaction_label.text = "ALINEADO · MANTENÉ EL FRENO" if automatic else "ALINEADO · MANTENÉ EL EMBRAGUE"
            reaction_label.visible = true
    elif run.phase=="countdown":
        status = "ESPERÁ EL VERDE"
        clock_label.text = "LARGADA"
    elif run.phase=="running":
        if run.launch_time<0.0:
            status = "¡VERDE!"
        elif model.feedback_time>0.0 or model.limiter or not model.engine_running:
            status = model.shift_hint()
    elif run.phase=="finished":
        status = "ESPERANDO AL RIVAL" if is_duel and duel_result.is_empty() else "PASADA VÁLIDA"
    elif run.phase=="invalid":
        status = run.reason
    if not str(data.get("message","")).is_empty():
        status = str(data["message"])
    if paused:
        status = "PAUSA · CRONÓMETRO DETENIDO"
    status_label.text = status
    status_label.add_theme_color_override("font_color",Style.DANGER if run.phase=="invalid" or procedure_phase=="expired" else Style.TEXT)
    status_label.visible = not status.is_empty()
    details_panel.visible = paused
    help_label.visible = paused
    actions.visible = preparing or paused or run.phase in ["finished","invalid"]
    preparation_panel.visible = preparing and not paused
    # A finished player lane must not cover the view while the rival is racing.
    ticket_panel.visible = not paused and ((not is_duel and run.phase in ["finished","invalid"]) or (is_duel and not duel_result.is_empty()))
    if run.phase=="finished":
        var result: Dictionary = run.report()
        ticket_label.text = "TICKET / 402,336 METROS\nET                 %.3f s\nREACCIÓN       %+.3f s\nTOTAL             %.3f s\n60 PIES           %.3f s\n1/8 MILLA       %.3f s\nTRAMPA          %.1f km/h\n%s" % [result.et,result.reaction,result.total,result.sixty_ft,result.eighth,result.trap_kmh,"MEJOR MARCA PERSONAL" if data.get("personal_best",false) else "R: OTRA PASADA"]
    elif run.phase=="invalid":
        ticket_label.text = "PASADA INVÁLIDA\n\n%s\n\nNo se registra una marca.\nR: volver a preparar\nEl uso mecánico se conserva." % run.reason
    if is_duel and not duel_result.is_empty():
        var heading := "VICTORIA" if duel_result["winner"]=="player" else ("DERROTA" if duel_result["winner"]=="rival" else ("EMPATE" if duel_result["outcome"]=="tie" else "SIN GANADOR"))
        status_label.text = "PAUSA · "+heading if paused else heading
        status_label.visible = true
        ticket_label.text = heading+" / DUELO DE FÁBRICA\n"+_lane_result("VOS",duel_result["entries"]["player"])+"\n"+_lane_result(str(data["opponent_name"]),duel_result["entries"]["rival"])+"\n"+("CLASE %s · PISO ET %.2f s\n" % [category.id,category.minimum_et] if not category.is_empty() else "")+("EXCEPCIÓN ART. 12 / FALSO INDIVIDUAL\n" if duel_result.get("exception","")=="art12_single_false_start" else "")+"Sin inscripción ni premios"
    var start: Dictionary = data["wear_start"]
    wear_label.text = "DESGASTE ADICIONAL / ESTA PASADA\nMotor %.3f · Caja %.3f · Gomas %.3f" % [float(model.wear.motor)-float(start.get("motor",0.0)),float(model.wear.transmision)-float(start.get("transmision",0.0)),float(model.wear.neumaticos)-float(start.get("neumaticos",0.0))]
    var damage: Dictionary = data.get("damage",{})
    damage_label.text = "DAÑOS POR IMPACTO / SESIÓN\nMotor −%.1f · Chasis −%.1f · Suspensión −%.1f" % [float(damage.get("motor",0.0)),float(damage.get("chasis",0.0)),float(damage.get("suspension",0.0))] if not damage.is_empty() else ""
    damage_label.visible = not damage_label.text.is_empty()
    var pad_clutch := "LT/LB embrague · B frena" if settings.analog_clutch else "LB embrague · LT/B frena"
    help_label.text = "%s acelerar · %s/%s frenar · %s embrague\n%s subir / %s bajar · %s repetir\n%s/Select pausa · Esc garaje · Tab/RB cámara\nMando: A sube / Y baja · %s\n%s/L3: freno de mano trasero" % [settings.key_label("accelerate"),settings.key_label("reverse"),settings.key_label("brake"),settings.key_label("clutch"),settings.key_label("shift_up"),settings.key_label("shift_down"),settings.key_label("recover"),settings.key_label("pause"),pad_clutch,settings.key_label("handbrake")]
    if automatic:
        help_label.text = "%s acelerar · %s/%s frenar\n%s: D / %s: N · Selector con el auto detenido\n%s repetir · %s/Select pausa · Esc garaje\nMando: RT acelera · LT/B frena · A/Y D/N\n%s/L3: freno de mano · Tab/RB cámara" % [settings.key_label("accelerate"),settings.key_label("reverse"),settings.key_label("brake"),settings.key_label("shift_up"),settings.key_label("shift_down"),settings.key_label("recover"),settings.key_label("pause"),settings.key_label("handbrake")]
    var ground: Dictionary = data.get("ground",{})
    if not ground.is_empty():
        power_label.text += "\n%s · APOYO %d/4 RUEDAS" % [ground.label,int(ground.wheels_on_ground)]
    queue_redraw()

func _lane_result(name: String, entry: Dictionary) -> String:
    if entry["ticket"].is_empty():
        return name+": "+str(entry["reason"])
    var ticket: Dictionary = entry["ticket"]
    return "%s%s\nET %.3f · RT %.3f\nTOTAL %.3f s" % [name," · CAÍDA" if entry["status"]=="breakout" else "",ticket["et"],ticket["reaction"],ticket["total"]]

func _draw() -> void:
    if tree_phase=="running":
        var track := Rect2(size.x*0.5-105,size.y-18,210,2)
        draw_rect(track,Color(0.1,0.15,0.2,0.7))
        draw_rect(Rect2(track.position,Vector2(track.size.x*progress,2)),Style.HOVER)
    if show_tree:
        for i in range(4):
            var on := (tree_phase=="countdown" and i<3 and tree_clock>=0.5+float(i)*0.5) or (tree_phase=="running" and i==3)
            var color := Style.WARNING if i<3 else Style.SUCCESS
            draw_circle(Vector2(size.x*0.5-48+i*32,108),9,color if on else Color("32434f"))
