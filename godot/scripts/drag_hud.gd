extends Control

signal return_requested
signal camera_requested
signal arm_requested
const Style = preload("res://scripts/racing_theme.gd")
const Run = preload("res://scripts/drag_run.gd")
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
var wear_label: Label
var status_label: Label
var help_label: Label
var ticket_label: Label
var ticket_panel: PanelContainer
var arm_button: Button
var rpm_fraction := 0.0
var progress := 0.0
var tree_phase := "preparation"
var tree_clock := 0.0
var staged := true

func label(parent: Node, value: String, font_size: int) -> Label:
    var node := Label.new()
    node.text = value
    node.add_theme_font_override("font",Style.FONT)
    node.add_theme_font_size_override("font_size",font_size)
    node.add_theme_color_override("font_color",Color.WHITE)
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
    node.add_theme_stylebox_override("panel",Style.panel(Color(0.025,0.06,0.11,0.90),12))
    add_child(node)
    return node

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    theme = Style.build()
    var intro := VBoxContainer.new()
    panel(Rect2(20,20,410,100)).add_child(intro)
    label(intro,"¼ DE MILLA / AUTÓDROMO SUR",26)
    model_label = label(intro,"",19)
    best_label = label(intro,"MEJOR UNIDAD  —",16)
    var clock := VBoxContainer.new()
    panel(Rect2(-140,20,280,100),Vector2(0.5,0)).add_child(clock)
    clock_label = label(clock,"0.000 s",38)
    clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    reaction_label = label(clock,"REACCIÓN  —",19)
    reaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var actions := HBoxContainer.new()
    actions.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    actions.offset_left = -250
    actions.offset_right = -20
    actions.offset_top = 20
    actions.offset_bottom = 60
    add_child(actions)
    for entry in [["GARAJE",return_requested],["CÁMARA",camera_requested]]:
        var button := Button.new()
        button.text = entry[0]
        button.custom_minimum_size = Vector2(105,38)
        button.pressed.connect(func(): entry[1].emit())
        actions.add_child(button)
    arm_button = Button.new()
    arm_button.text = "INICIAR SEMÁFORO [Enter]"
    arm_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    arm_button.offset_left = -250
    arm_button.offset_right = -20
    arm_button.offset_top = 77
    arm_button.offset_bottom = 120
    arm_button.pressed.connect(func(): arm_requested.emit())
    add_child(arm_button)
    var numbers := VBoxContainer.new()
    numbers.add_theme_constant_override("separation",3)
    panel(Rect2(-320,-282,300,260),Vector2.ONE).add_child(numbers)
    var row := HBoxContainer.new()
    numbers.add_child(row)
    gear_label = label(row,"N",65)
    gear_label.add_theme_color_override("font_color",Color("f0d48c"))
    speed_label = label(row,"0",65)
    speed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    rpm_label = label(numbers,"KM/H    900 RPM",20)
    rpm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    pedals_label = label(numbers,"",17)
    condition_label = label(numbers,"",16)
    power_label = label(numbers,"",17)
    status_label = label(self,"",25)
    status_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
    status_label.offset_left = -320
    status_label.offset_right = 320
    status_label.offset_top = 140
    status_label.offset_bottom = 225
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_color_override("font_shadow_color",Color.BLACK)
    status_label.add_theme_constant_override("shadow_offset_x",2)
    status_label.add_theme_constant_override("shadow_offset_y",2)
    help_label = label(self,"",17)
    help_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    help_label.offset_left = 24
    help_label.offset_right = 910
    help_label.offset_top = -130
    help_label.offset_bottom = -10
    help_label.add_theme_color_override("font_shadow_color",Color.BLACK)
    help_label.add_theme_constant_override("shadow_offset_x",1)
    help_label.add_theme_constant_override("shadow_offset_y",1)
    ticket_panel = panel(Rect2(20,150,405,360))
    var ticket_body := VBoxContainer.new()
    ticket_body.add_theme_constant_override("separation",8)
    ticket_panel.add_child(ticket_body)
    ticket_label = label(ticket_body,"",24)
    ticket_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    wear_label = label(ticket_body,"",17)
    ticket_panel.visible = false

func refresh(data: Dictionary) -> void:
    var model = data["model"]
    var run = data["run"]
    var settings = data["settings"]
    model_label.text = data["name"] + " / MANUAL · PRÁCTICA"
    clock_label.text = "%.3f s" % run.elapsed
    reaction_label.text = "REACCIÓN  %s" % ("%.3f s" % run.reaction if run.launch_time >= 0 else "—")
    gear_label.text = "N" if model.gear == 0 else str(model.gear)
    speed_label.text = "0" if model.speed_mps<0.15 else "%.0f" % (model.speed_mps*3.6)
    rpm_label.text = "KM/H    %.0f RPM" % model.rpm
    pedals_label.text = "ACEL %.0f%%   EMBRAGUE %.0f%%" % [model.throttle*100,(1.0-model.clutch_engagement)*100]
    condition_label.text = "GOMAS DL %.0f°C / TR %.0f°C · MOTOR %.0f°C\n%s · %s · %s" % [model.axles.temperatures.x,model.axles.temperatures.y,model.engine_temperature,model.config.drivetrain,"TCS ACTIVO" if model.tcs_cut<0.95 else ("TCS ON" if model.traction_control else "TCS OFF"),"ABS" if model.axles.abs_active else ("PATINA" if model.wheelspin>0.18 and model.gear>0 else "AGARRE")]
    power_label.text = "MOTOR %.0f Nm · RUEDAS %.0f kW\n%s · EMBRAGUE PIERDE %.0f kW" % [model.engine_torque_nm,model.wheel_power_kw,"TURBO %.0f%%" % (model.engine.boost*100) if model.config.turbo_fraction>0 else "ASPIRADO",model.clutch_loss_kw]
    rpm_fraction = clampf(model.rpm/model.config.redline_rpm,0,1)
    progress = clampf(float(data["position"])/Run.DISTANCE,0,1)
    tree_phase = run.phase
    tree_clock = run.clock
    staged = data["staged"]
    arm_button.disabled = not data["can_arm"]
    best_label.text = "MEJOR UNIDAD  " + ("%.3f s" % data["best"]["et"] if not data["best"].is_empty() else "—") + " · SIN PREMIOS"
    var status := "PREPARACIÓN · Primera, embrague y Enter"
    if run.phase == "preparation" and model.feedback_time>0.0:
        status = model.shift_hint()
    if run.phase == "countdown":
        status = "ESPERÁ EL VERDE · Regulá las RPM"
    elif run.phase == "running":
        status = "¡VERDE! · Soltá el embrague" if run.launch_time < 0 else model.shift_hint()
    elif run.phase == "finished":
        status = "PASADA VÁLIDA · Frenando"
    elif run.phase == "invalid":
        status = run.reason
    if not str(data["message"]).is_empty():
        status = str(data["message"])
    if data["paused"]:
        status = "PAUSA · Piloto y cronómetro detenidos"
    status_label.text = status
    ticket_panel.visible = run.phase in ["finished","invalid"]
    if run.phase == "finished":
        var result: Dictionary = run.report()
        ticket_label.text = "TICKET / 402,336 METROS\nET                 %.3f s\nREACCIÓN       %+.3f s\nTOTAL             %.3f s\n60 PIES           %.3f s\n1/8 MILLA       %.3f s\nTRAMPA          %.1f km/h\n%s" % [result.et,result.reaction,result.total,result.sixty_ft,result.eighth,result.trap_kmh,"MEJOR MARCA PERSONAL" if data["personal_best"] else "R: OTRA PASADA"]
    elif run.phase == "invalid":
        ticket_label.text = "PASADA INVÁLIDA\n\n%s\n\nNo se registra una marca.\nR: volver a preparar\nEl uso mecánico se conserva." % run.reason
    var start: Dictionary = data["wear_start"]
    wear_label.text = "DESGASTE ADICIONAL / ESTA PASADA\nMotor %.3f · Caja %.3f · Gomas %.3f" % [float(model.wear.motor)-float(start.get("motor",0.0)),float(model.wear.transmision)-float(start.get("transmision",0.0)),float(model.wear.neumaticos)-float(start.get("neumaticos",0.0))]
    var pad_clutch := "LT/LB embrague · B frena" if settings.analog_clutch else "LB embrague · LT/B frena"
    help_label.text = "%s acelerar · %s/%s frenar · %s embrague · %s subir / %s bajar\nEnter: semáforo · %s repetir · %s/Select pausa · Esc: garaje\nTab/RB: cámara · Shift/R3: atrás · A sube / Y baja · %s" % [settings.key_label("accelerate"),settings.key_label("reverse"),settings.key_label("brake"),settings.key_label("clutch"),settings.key_label("shift_up"),settings.key_label("shift_down"),settings.key_label("recover"),settings.key_label("pause"),pad_clutch]
    queue_redraw()

func _draw() -> void:
    for i in range(24):
        var color := Color("728495")
        if float(i)/24.0 < rpm_fraction:
            color = Color("df3445") if i>=21 else Color("f2d78e")
        draw_rect(Rect2(size.x-320+i*12.5,size.y-294,10,7),color)
    var track := Rect2(size.x*0.5-190,size.y-32,380,5)
    draw_rect(track,Color(0.1,0.15,0.2,0.8))
    draw_rect(Rect2(track.position,Vector2(track.size.x*progress,5)),Color("e2ca83"))
    if tree_phase in ["preparation","countdown","running"]:
        draw_rect(Rect2(24,155,62,215),Color(0.025,0.06,0.11,0.9))
        draw_circle(Vector2(55,174),6,Color("e6f5ff") if staged else Color("3a4b58"))
        for i in range(5):
            var on := (tree_phase == "countdown" and i < 3 and tree_clock>=0.5+float(i)*0.5) or (tree_phase=="running" and i==3)
            var color := Color("f1bb55") if i<3 else (Color("60d58a") if i==3 else Color("d94252"))
            draw_circle(Vector2(55,207+i*34),12,color if on else Color("32434f"))
