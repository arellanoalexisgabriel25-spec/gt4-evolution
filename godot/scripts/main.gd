extends Control

const Style = preload("res://scripts/racing_theme.gd")
const Preview = preload("res://scripts/car_preview.gd")
const CityMap = preload("res://scripts/city_map.gd")

const Economy = preload("res://scripts/economy.gd")
const Career = preload("res://scripts/career.gd")
const Tuning = preload("res://scripts/tuning.gd")
const Rivals = preload("res://scripts/rivals.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const ControlSettings = preload("res://scripts/control_settings.gd")
const SAVE_PATH := "user://evolution_save_v1.json"
var game: EvolutionEconomy
var career: EvolutionCareer
var current_tab := "inicio"
var nav_buttons: Dictionary = {}
var page_title: Label
var license_badge: Label
var content: VBoxContainer
var funds: Label
var notice: Label
var pending_binding := ""
var deadzone_label: Label
var steering_label: Label
var controls_path: String = ControlSettings.FILE_PATH

func _ready() -> void:
    game = GameSession.game
    career = GameSession.career
    current_tab = GameSession.menu_tab
    GameSession.menu_tab = "inicio"
    _build_interface()
    _render()
    if not GameSession.last_notice.is_empty():
        notice.text = GameSession.last_notice
        GameSession.last_notice = ""

func _label(value: String, size: int = 17) -> Label:
    var label := Label.new()
    label.text = value
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", size)
    if size >= 20:
        label.add_theme_font_override("font",Style.FONT)
    return label

func _button(value: String, action: Callable) -> Button:
    var button := Button.new()
    button.text = value
    button.custom_minimum_size = Vector2(0, 42)
    button.pressed.connect(action)
    return button

func _build_interface() -> void:
    theme = Style.build()
    var bg := ColorRect.new()
    bg.color = Color("cbd3df")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 22)
    add_child(margin)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 12)
    margin.add_child(root)
    var header := PanelContainer.new()
    header.add_theme_stylebox_override("panel", Style.panel(Style.BLUE,14))
    root.add_child(header)
    var header_row := HBoxContainer.new()
    header.add_child(header_row)
    var brand := _label("GT4  /  EVOLUTION", 34)
    brand.add_theme_font_override("font",Style.FONT)
    brand.add_theme_color_override("font_color",Color.WHITE)
    brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header_row.add_child(brand)
    license_badge = _label("",18)
    license_badge.add_theme_font_override("font",Style.FONT)
    license_badge.add_theme_color_override("font_color",Color("b9cada"))
    license_badge.custom_minimum_size.x = 200
    header_row.add_child(license_badge)
    funds = _label("",26)
    funds.custom_minimum_size.x = 185
    funds.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    funds.add_theme_font_override("font",Style.FONT)
    funds.add_theme_color_override("font_color",Color("f3dfae"))
    header_row.add_child(funds)
    var body := HBoxContainer.new()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation",16)
    root.add_child(body)
    var sidebar := VBoxContainer.new()
    sidebar.custom_minimum_size.x = 190
    sidebar.add_theme_constant_override("separation",7)
    body.add_child(sidebar)
    var mode := _label("EVOLUTION HOME",22)
    mode.add_theme_font_override("font",Style.FONT)
    sidebar.add_child(mode)
    var subtitle := _label("TU CAMINO EN EL
AUTOMOVILISMO",11)
    subtitle.add_theme_color_override("font_color",Color("68798d"))
    sidebar.add_child(subtitle)
    for entry in [{"key":"inicio","title":"INICIO"},{"key":"garaje","title":"MI GARAJE"},{"key":"mercado","title":"CONCESIONARIO"},{"key":"carrera","title":"EVENTOS DE CARRERA"},{"key":"taller","title":"CENTRO DE SERVICIO"},{"key":"tuning","title":"TUNING SHOP"},{"key":"historial","title":"MOVIMIENTOS"},{"key":"ajustes","title":"AJUSTES"}]:
        var button := _button(entry["title"],_change_tab.bind(entry["key"]))
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.custom_minimum_size.y = 36
        sidebar.add_child(button)
        nav_buttons[entry["key"]] = button
    var version := _label("GT4 EVOLUTION
VERSION " + GameSession.VERSION,11)
    version.add_theme_color_override("font_color",Color("68798d"))
    sidebar.add_child(version)
    var workspace := PanelContainer.new()
    workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_child(workspace)
    var page := VBoxContainer.new()
    workspace.add_child(page)
    page_title = _label("",25)
    page_title.add_theme_font_override("font",Style.FONT)
    page.add_child(page_title)
    var line := ColorRect.new()
    line.color = Style.RED
    line.custom_minimum_size.y = 3
    page.add_child(line)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    page.add_child(scroll)
    content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation",12)
    scroll.add_child(content)
    var footer := PanelContainer.new()
    root.add_child(footer)
    var footer_row := HBoxContainer.new()
    footer.add_child(footer_row)
    notice = _label("Bienvenido. Visitá el concesionario para comprar tu primer auto.",13)
    notice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    footer_row.add_child(notice)
    for entry in [["GUARDAR",_save],["CARGAR",_load],["NUEVA PARTIDA",_reset]]:
        var button := _button(entry[0],entry[1])
        button.add_theme_font_size_override("font_size",16)
        footer_row.add_child(button)

func _change_tab(next: String) -> void:
    pending_binding = ""
    current_tab = next
    _render()

func _render() -> void:
    funds.text = "%s Cr." % str(game.balance)
    license_badge.text = "GT MODE   /   LICENCIA " + career.license
    var titles := {"inicio":"GT MODE / EVOLUTION HOME","mercado":"USED CAR DEALER / CONCESIONARIO","garaje":"MY GARAGE / COLECCIÓN","carrera":"RACE EVENTS / CARRERA","taller":"SERVICE CENTER / TALLER","tuning":"TUNING SHOP / PREPARACIÓN","historial":"ACCOUNT / MOVIMIENTOS","ajustes":"OPTIONS / AJUSTES"}
    page_title.text = titles.get(current_tab, "GT MODE")
    for key in nav_buttons:
        var selected: bool = key == current_tab
        nav_buttons[key].add_theme_stylebox_override("normal",Style.panel(Style.BLUE if selected else Color("e8edf3"),9))
        nav_buttons[key].add_theme_color_override("font_color",Color.WHITE if selected else Style.BLUE)
    for item in content.get_children():
        content.remove_child(item)
        item.queue_free()
    match current_tab:
        "inicio": _home()
        "mercado": _market()
        "garaje": _garage()
        "taller": _workshop()
        "historial": _history()
        "carrera": _career()
        "tuning": _tuning()
        "ajustes": _settings()

func _home() -> void:
    var hero := HBoxContainer.new()
    hero.add_theme_constant_override("separation",16)
    content.add_child(hero)
    var owned: Dictionary = {}
    for vehicle in game.cars:
        if vehicle["owner"] == "player":
            owned = vehicle
            break
    var featured: Dictionary = game.cars[0] if owned.is_empty() else owned
    var preview = Preview.new()
    preview.model_name = featured["model"]
    preview.custom_minimum_size = Vector2(380,185)
    preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hero.add_child(preview)
    var intro := VBoxContainer.new()
    intro.custom_minimum_size.x = 220
    intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hero.add_child(intro)
    intro.add_child(_label("THE DRIVE STARTS HERE",25))
    intro.add_child(_label("Cada auto tiene una historia.
Encontrá el tuyo y construí tu carrera.",14))
    intro.add_child(_label(featured["model"],22))
    intro.add_child(_label("Licencia %s  /  Reputación %d" % [career.license,career.reputation],14))
    intro.add_child(_button("VISITAR EL CONCESIONARIO" if owned.is_empty() else "ENTRAR AL GARAJE",_change_tab.bind("mercado" if owned.is_empty() else "garaje")))
    var map = CityMap.new()
    map.destination_selected.connect(_change_tab)
    content.add_child(map)

func _market() -> void:
    content.add_child(_label("USED CAR LINEUP",24))
    content.add_child(_label("Inspeccioná antes de comprar. La condición oculta puede convertir una oferta en una restauración costosa.",13))
    var grid := GridContainer.new()
    grid.columns = 2 if size.x >= 1100 else 1
    grid.add_theme_constant_override("h_separation",12)
    grid.add_theme_constant_override("v_separation",12)
    content.add_child(grid)
    for car in game.cars:
        if car["owner"] != "seller":
            continue
        var panel := PanelContainer.new()
        panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        panel.custom_minimum_size.x = 390 if grid.columns == 2 else 0
        grid.add_child(panel)
        var column := VBoxContainer.new()
        panel.add_child(column)
        column.add_child(_label(car["model"],24))
        var status := "CONDICIÓN %.1f / 100" % game.condition(car) if bool(car.get("inspected",false)) else "CONDICIÓN SIN VERIFICAR"
        column.add_child(_label("%s KM   /   %s" % [car["km"],status],12))
        var price := _label("%d Cr." % car["price"],30)
        price.add_theme_color_override("font_color",Style.RED)
        column.add_child(price)
        if bool(car.get("inspected",false)):
            column.add_child(_label(game.inspection_summary(car),13))
        var actions := HFlowContainer.new()
        actions.add_theme_constant_override("h_separation",8)
        column.add_child(actions)
        var inspect_button := _button("INSPECCIÓN 200 Cr.",_inspect.bind(int(car["id"])))
        inspect_button.disabled = bool(car.get("inspected",false)) or game.balance < 200
        actions.add_child(inspect_button)
        var buy := _button("COMPRAR",_buy.bind(int(car["id"])))
        buy.disabled = game.balance < int(car["price"])
        actions.add_child(buy)

func _garage() -> void:
    content.add_child(_label("MI GARAJE", 22))
    content.add_child(_label("Práctica: contrarreloj · Carrera libre: dos rivales, sin inscripción ni premios", 14))
    var selected: Dictionary = {}
    for vehicle in game.cars:
        if vehicle["owner"] == "player":
            selected = vehicle
            break
    if not selected.is_empty():
        var preview = Preview.new()
        preview.model_name = selected["model"]
        preview.custom_minimum_size = Vector2(0,240)
        content.add_child(preview)
    var found := false
    for car in game.cars:
        if car["owner"] != "player":
            continue
        found = true
        var card := PanelContainer.new()
        content.add_child(card)
        var layout := VBoxContainer.new()
        layout.add_theme_constant_override("separation", 8)
        card.add_child(layout)
        var state := "APTO" if game.eligible(car) else "NECESITA REPARACIÓN"
        var remainder := float(car.get("distance_remainder_m", 0.0))
        var info := _label("%s · %.2f km · %.1f/100 · %s" % [car["model"], float(car["km"]) + remainder / 1000.0, game.condition(car), state], 17)
        info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        layout.add_child(info)
        var best := career.lap_records.get_best(int(car["id"]))
        if best > 0.0:
            layout.add_child(_label("Mejor vuelta al club: %.2f s" % best, 15))
        var actions := HFlowContainer.new()
        actions.add_theme_constant_override("h_separation", 8)
        layout.add_child(actions)
        var drive_button := _button("PRUEBA SIMULADA 10 KM", _drive.bind(int(car["id"])))
        drive_button.disabled = not game.eligible(car)
        actions.add_child(drive_button)
        var drive_3d := _button("CONTRARRELOJ 3D", _drive_3d.bind(int(car["id"])))
        drive_3d.disabled = not game.eligible(car)
        actions.add_child(drive_3d)
        var race_3d := _button("CARRERA LIBRE 3D", _race_3d.bind(int(car["id"])))
        race_3d.disabled = not game.eligible(car)
        actions.add_child(race_3d)
        actions.add_child(_button("VENDER %d Cr." % game.resale_quote(int(car["id"])), _sell.bind(int(car["id"]))))
    if not found:
        content.add_child(_label("No tenés vehículos. Visitá el concesionario."))

func _workshop() -> void:
    content.add_child(_label("TALLER MECÁNICO", 22))
    for car in game.cars:
        if car["owner"] != "player":
            continue
        content.add_child(_label("%s  ·  Estado %.1f" % [car["model"], game.condition(car)], 19))
        var problems := game.inspection_summary({"inspected": true, "faults": car.get("faults", {})})
        content.add_child(_label("Diagnóstico: " + problems, 14))
        for component in Economy.WEIGHTS:
            var line := HBoxContainer.new()
            content.add_child(line)
            var state := _label("%s: %.1f / 100" % [component.capitalize(), float(car["health"][component])], 15)
            state.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            line.add_child(state)
            var price := game.repair_quote(int(car["id"]), component)
            var b := _button("REPARAR %d Cr." % price, _repair.bind(int(car["id"]), component))
            b.disabled = price <= 0 or price > game.balance
            line.add_child(b)

func _history() -> void:
    content.add_child(_label("MOVIMIENTOS ECONÓMICOS", 22))
    for entry in game.ledger:
        content.add_child(_label("Auto #%d · %s · %+d Cr." % [entry["car_id"], entry["event"], entry["amount"]], 16))

func _tuning() -> void:
    content.add_child(_label("TUNING Y PREPARACIÓN", 22))
    content.add_child(_label("Las mejoras influyen en el manejo 3D y en las simulaciones. Más potencia aumenta el desgaste.", 14))
    var shop = Tuning.new()
    for car in game.cars:
        if car["owner"] != "player":
            continue
        content.add_child(_label("%s · bonificación +%.1f" % [car["model"], shop.performance_bonus(car)], 18))
        for part in Tuning.PARTS:
            var row := HBoxContainer.new()
            content.add_child(row)
            var description := _label("%s · +%.1f · %d Cr." % [part["name"], part["gain"], part["price"]], 15)
            description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            row.add_child(description)
            var part_id: String = part["id"]
            var issue := shop.can_install(game, int(car["id"]), part_id)
            var button := _button("INSTALADA" if shop.has_part(car, part_id) else "COMPRAR", _install_part.bind(int(car["id"]), part_id))
            button.disabled = not issue.is_empty()
            row.add_child(button)

func _install_part(car_id: int, part_id: String) -> void:
    notice.text = Tuning.new().install(game, car_id, part_id)
    _render()

func _career() -> void:
    content.add_child(_label("CARRERA PROFESIONAL · LICENCIA %s" % career.license, 22))
    content.add_child(_label("Reputación: %d · Debutantes: carrera 3D de 2 vueltas · Otros eventos: simulados." % career.reputation, 15))
    var owned: Array[Dictionary] = []
    for car in game.cars:
        if car["owner"] == "player":
            owned.append(car)
    content.add_child(_label("PILOTOS RIVALES", 18))
    for driver in Rivals.DRIVERS:
        var record: Dictionary = career.rivalries.get(driver["id"], {"encounters":0,"victories":0,"defeats":0})
        content.add_child(_label("%s · habilidad %.0f · enfrentamientos %d · victorias %d" % [driver["name"],driver["skill"],record["encounters"],record["victories"]], 14))
    content.add_child(_label("CAMPEONATOS", 18))
    for event in Career.EVENTS:
        var event_id: String = event["id"]
        var distance := "2 vueltas al circuito del club" if event_id == "debut" else "%d km simulados" % event["distance"]
        var summary := "%s · Licencia %s · %d Cr. · %s" % [event["name"],event["license"],event["fee"],distance]
        content.add_child(_label(summary, 17))
        if event_id == "debut":
            content.add_child(_label("  Carrera 3D: abandonar consume la inscripción. Otros eventos siguen siendo simulados.", 13))
        if career.completed.has(event_id):
            content.add_child(_label("  COMPLETADO · premio único cobrado", 14))
            continue
        if owned.is_empty():
            content.add_child(_label("  Necesitás comprar un vehículo para inscribirte.", 14))
        for car in owned:
            var car_id := int(car["id"])
            var problem := career.can_enter(game, event_id, car_id)
            var title := "CORRER 3D con %s" if event_id == "debut" else "SIMULAR con %s"
            var button := _button(title % car["model"], _race.bind(event_id, car_id))
            button.disabled = not problem.is_empty()
            content.add_child(button)
            if not problem.is_empty():
                content.add_child(_label("  " + problem, 13))

func _race(event_id: String, car_id: int) -> void:
    if event_id == "debut":
        var issue := GameSession.enter_track_event(event_id, car_id)
        if not issue.is_empty():
            notice.text = issue
            return
        var error := get_tree().change_scene_to_file("res://scenes/driving.tscn")
        if error != OK:
            GameSession.cancel_unstarted_entry()
            notice.text = "No se pudo abrir la carrera; inscripción reembolsada."
        return
    notice.text = career.simulate_event(game, event_id, car_id)
    _render()

func _inspect(id: int) -> void:
    notice.text = game.inspect(id)
    _render()

func _buy(id: int) -> void:
    notice.text = game.buy(id)
    _render()

func _sell(id: int) -> void:
    notice.text = game.sell(id)
    _render()

func _repair(id: int, component: String) -> void:
    notice.text = game.repair(id, component)
    _render()

func _drive_3d(id: int) -> void:
    if not GameSession.start_driving(id):
        notice.text = "El auto no está disponible o requiere reparación."
        return
    get_tree().change_scene_to_file("res://scenes/driving.tscn")

func _race_3d(id: int) -> void:
    if not GameSession.start_driving(id, "race"):
        notice.text = "El auto no está disponible o requiere reparación."
        return
    get_tree().change_scene_to_file("res://scenes/driving.tscn")

func _drive(id: int) -> void:
    notice.text = game.drive(id, 10)
    _render()

func _save() -> void:
    var error := SaveStore.save_file(SAVE_PATH, game, career)
    notice.text = "Partida guardada." if error == OK else "No se pudo guardar; se conserva la partida anterior."

func _load() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        notice.text = "No hay partida guardada."
        return
    var loaded: Dictionary = SaveStore.load_file(SAVE_PATH)
    if not str(loaded.get("error", "")).is_empty():
        notice.text = loaded["error"]
        return
    game = loaded["game"]
    career = loaded["career"]
    GameSession.game = game
    GameSession.career = career
    notice.text = "Partida recuperada."
    _render()

func _reset() -> void:
    GameSession.reset()
    game = GameSession.game
    career = GameSession.career
    notice.text = "Nueva partida iniciada."
    _render()

func _settings() -> void:
    content.add_child(_label("CÁMARA Y DIRECCIÓN",22))
    var camera_choice := OptionButton.new()
    camera_choice.add_theme_font_override("font",Style.FONT)
    camera_choice.add_theme_font_size_override("font_size",20)
    for title in ["CÁMARA: SEGUIMIENTO","CÁMARA: CERCANA","CÁMARA: CAPÓ","CÁMARA: PARAGOLPES"]:
        camera_choice.add_item(title)
    camera_choice.selected = GameSession.controls.camera_mode
    camera_choice.item_selected.connect(_set_camera_mode)
    content.add_child(camera_choice)
    content.add_child(_label("Tab / RB: cambiar vista · Shift / Y: mirar atrás · Stick derecho: mirar alrededor.",14))
    steering_label = _label("Dirección del teclado: %.0f%% · Reducila para entradas más suaves." % (GameSession.controls.keyboard_steering*100.0),14)
    content.add_child(steering_label)
    var steering_slider := HSlider.new()
    steering_slider.min_value = 0.4
    steering_slider.max_value = 1.0
    steering_slider.step = 0.05
    steering_slider.value = GameSession.controls.keyboard_steering
    steering_slider.value_changed.connect(_set_keyboard_steering)
    content.add_child(steering_slider)
    content.add_child(_label("CONTROLES",22))
    content.add_child(_label("Elegí una acción y presioná una letra, número o Espacio. Esc cancela. Las flechas siempre funcionan.",14))
    var bindings := GridContainer.new()
    bindings.columns = 2
    bindings.add_theme_constant_override("h_separation",30)
    content.add_child(bindings)
    for name in GameSession.controls.DEFAULT_KEYS:
        var row := HBoxContainer.new()
        row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        bindings.add_child(row)
        var title := _label(GameSession.controls.TITLES[name])
        title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(title)
        row.add_child(_button(GameSession.controls.key_label(name),_request_binding.bind(name)))
    content.add_child(_label("MANDO · Stick/cruceta: dirección · RT/R2: acelerar · LT/L2: freno
B/Círculo: reversa · X/Cuadrado: recuperar · Inicio: pausa · Esc o botón en pantalla: garaje", 14))
    deadzone_label = _label("Zona muerta del mando (%.0f%%)" % (GameSession.controls.deadzone * 100.0), 16)
    content.add_child(deadzone_label)
    var slider := HSlider.new()
    slider.min_value = 0.10
    slider.max_value = 0.40
    slider.step = 0.01
    slider.value = GameSession.controls.deadzone
    slider.value_changed.connect(_set_deadzone)
    content.add_child(slider)
    content.add_child(_button("RESTAURAR CONTROLES", _restore_controls))
    content.add_child(_label("Los ajustes se guardan automáticamente, separados de la partida. Se usa el primer mando conectado.", 14))

func _request_binding(name: String) -> void:
    pending_binding = name
    notice.text = "Nueva tecla para %s. Esc cancela." % str(GameSession.controls.TITLES[name]).to_lower()

func _input(event: InputEvent) -> void:
    if pending_binding.is_empty() or not (event is InputEventKey) or not event.pressed or event.echo:
        return
    get_viewport().set_input_as_handled()
    if event.physical_keycode == KEY_ESCAPE:
        pending_binding = ""
        notice.text = "Cambio de tecla cancelado."
        return
    if event.ctrl_pressed or event.alt_pressed or event.meta_pressed or event.shift_pressed:
        notice.text = "Usá una tecla sola, sin modificadores. Esc cancela."
        return
    var issue := GameSession.controls.bind(pending_binding, event.physical_keycode)
    if not issue.is_empty():
        notice.text = issue
        return
    pending_binding = ""
    _save_controls()
    _render()

func _save_controls() -> void:
    notice.text = "Controles guardados." if GameSession.controls.save_file(controls_path) == OK else "Controles aplicados en esta sesión; no se pudo guardar la configuración."

func _set_deadzone(value: float) -> void:
    GameSession.controls.deadzone = value
    if is_instance_valid(deadzone_label):
        deadzone_label.text = "Zona muerta del mando (%.0f%%)" % (value * 100.0)
    _save_controls()

func _restore_controls() -> void:
    pending_binding = ""
    GameSession.controls.restore_defaults()
    _save_controls()
    _render()

func _set_camera_mode(value: int) -> void:
    GameSession.controls.camera_mode = value
    _save_controls()

func _set_keyboard_steering(value: float) -> void:
    GameSession.controls.keyboard_steering = value
    if is_instance_valid(steering_label):
        steering_label.text = "Dirección del teclado: %.0f%% · Reducila para entradas más suaves." % (value*100.0)
    _save_controls()
