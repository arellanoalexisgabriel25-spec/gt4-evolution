extends Control

const Style = preload("res://scripts/racing_theme.gd")
const Money = preload("res://scripts/money.gd")
const Preview = preload("res://scripts/car_preview.gd")
const CityMap = preload("res://scripts/city_map.gd")
const Navigation = preload("res://scripts/menu_controller.gd")
const Catalog = preload("res://scripts/car_catalog.gd")
const Tire = preload("res://scripts/tire_model.gd")
const DragClasses = preload("res://scripts/drag_class_rules.gd")
const DragConfig = preload("res://scripts/drag_vehicle_config.gd")

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
var navigation
var controller_label: Label
var music_label: Label
var home_featured := ""
var garage_featured := 0
var duel_profile := "technical"
var duel_class := "1"
var duel_opponent_model := ""

func _ready() -> void:
    game = GameSession.game
    game.ensure_flagship_offers()
    career = GameSession.career
    if GameSession.drag_format=="duel":
        duel_profile = GameSession.drag_rival_profile
        duel_class = GameSession.drag_class_id
        duel_opponent_model = GameSession.drag_opponent_model
    current_tab = GameSession.menu_tab
    GameSession.menu_tab = "inicio"
    _build_interface()
    _render()
    navigation = Navigation.new()
    navigation.page = self
    navigation.initial_focus = nav_buttons[current_tab]
    navigation.back_action = _controller_back
    navigation.tab_action = _controller_tab
    add_child(navigation)
    GameSession.menu_music.set_menu_active(true)
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
    if value in ["COMPRAR","GUARDAR","DUELO ¼ DE MILLA / FÁBRICA"]:
        button.theme_type_variation = "PrimaryButton"
    button.pressed.connect(action)
    return button

func _build_interface() -> void:
    theme = Style.build()
    var bg := ColorRect.new()
    bg.color = Style.BACKGROUND
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
    header.add_theme_stylebox_override("panel", Style.panel(Style.ELEVATED,14))
    root.add_child(header)
    var header_row := HBoxContainer.new()
    header.add_child(header_row)
    var brand := _label("GT4  /  EVOLUTION", 32)
    brand.add_theme_font_override("font",Style.FONT)
    brand.add_theme_color_override("font_color",Color.WHITE)
    brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header_row.add_child(brand)
    license_badge = _label("",18)
    license_badge.add_theme_font_override("font",Style.FONT)
    license_badge.add_theme_color_override("font_color",Style.SECONDARY)
    license_badge.custom_minimum_size.x = 200
    header_row.add_child(license_badge)
    funds = _label("",22)
    funds.custom_minimum_size.x = 260
    funds.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    funds.add_theme_font_override("font",Style.MONO)
    funds.add_theme_color_override("font_color",Style.TEXT)
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
    subtitle.add_theme_color_override("font_color",Style.SECONDARY)
    sidebar.add_child(subtitle)
    for entry in [{"key":"inicio","title":"INICIO"},{"key":"garaje","title":"MI GARAJE"},{"key":"mercado","title":"CONCESIONARIO"},{"key":"carrera","title":"EVENTOS DE CARRERA"},{"key":"taller","title":"CENTRO DE SERVICIO"},{"key":"tuning","title":"TUNING SHOP"},{"key":"historial","title":"MOVIMIENTOS"},{"key":"ajustes","title":"AJUSTES"}]:
        var button := _button(entry["title"],_change_tab.bind(entry["key"]))
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.custom_minimum_size.y = 36
        sidebar.add_child(button)
        nav_buttons[entry["key"]] = button
    var version := _label("GT4 EVOLUTION
VERSION " + GameSession.VERSION,11)
    version.add_theme_color_override("font_color",Style.SECONDARY)
    sidebar.add_child(version)
    var workspace := PanelContainer.new()
    workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_child(workspace)
    var page := VBoxContainer.new()
    workspace.add_child(page)
    page_title = _label("",23)
    page_title.add_theme_font_override("font",Style.FONT)
    page.add_child(page_title)
    var line := ColorRect.new()
    line.color = Style.ACCENT
    line.custom_minimum_size.y = 2
    page.add_child(line)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.follow_focus = true
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
    if navigation!=null:
        navigation.initial_focus = nav_buttons[current_tab]
        if GameSession.controls.controller.selected()>=0:
            navigation.initial_focus.grab_focus()

func _controller_back() -> void:
    if not pending_binding.is_empty():
        pending_binding = ""
        notice.text = "Cambio de tecla cancelado."
    else:
        _change_tab("inicio")

func _controller_tab(direction: int) -> void:
    var tabs := nav_buttons.keys()
    _change_tab(tabs[wrapi(tabs.find(current_tab)+direction,0,tabs.size())])

func _process(_delta: float) -> void:
    if is_instance_valid(controller_label):
        controller_label.text = GameSession.controls.controller.description()+" · A confirma / B vuelve / LB–RB pestañas"

func _render() -> void:
    funds.text = Money.format(game.balance)
    license_badge.text = "GT MODE   /   LICENCIA " + career.license
    var titles := {"inicio":"GT MODE / EVOLUTION HOME","mercado":"USED CAR DEALER / CONCESIONARIO","garaje":"MY GARAGE / COLECCIÓN","carrera":"RACE EVENTS / CARRERA","taller":"SERVICE CENTER / TALLER","tuning":"TUNING SHOP / PREPARACIÓN","historial":"ACCOUNT / MOVIMIENTOS","ajustes":"OPTIONS / AJUSTES"}
    page_title.text = titles.get(current_tab, "GT MODE")
    for key in nav_buttons:
        var selected: bool = key == current_tab
        nav_buttons[key].add_theme_stylebox_override("normal",Style.navigation(selected))
        nav_buttons[key].add_theme_color_override("font_color",Style.TEXT if selected else Style.SECONDARY)
        for state in ["hover","pressed"]:
            nav_buttons[key].add_theme_stylebox_override(state,Style.navigation(selected,true))
        for state in ["font_focus_color","font_hover_color","font_pressed_color"]:
            nav_buttons[key].add_theme_color_override(state,Style.TEXT if selected else Style.SECONDARY)
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
    var featured: Dictionary = Catalog.market_order(game.cars)[0] if owned.is_empty() else owned
    for vehicle in game.cars:
        if vehicle["model"]==home_featured:
            featured = vehicle
    var preview = Preview.new()
    preview.model_name = featured["model"]
    preview.custom_minimum_size = Vector2(380,185)
    preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hero.add_child(preview)
    var intro := VBoxContainer.new()
    intro.custom_minimum_size.x = 220
    intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hero.add_child(intro)
    intro.add_child(_label("402,336 M / CAJA MANUAL",23))
    intro.add_child(_label("De fábrica a la pista. Una pasión por el ¼ de milla.",14))
    intro.add_child(_label(featured["model"],22))
    if featured["owner"]!="player":
        intro.add_child(_button("VISITAR EL CONCESIONARIO",_change_tab.bind("mercado")))
    else:
        intro.add_child(_button("DUELO ¼ DE MILLA / FÁBRICA",_drag_duel.bind(int(featured["id"]))))
    var selector := OptionButton.new()
    selector.custom_minimum_size.y = 32
    selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var models: Array = []
    for entry in Catalog.market_order(game.cars):
        var name := str(entry["model"])
        if not models.has(name): models.append(name)
    for index in range(models.size()):
        selector.add_item(models[index])
        if str(models[index])==str(featured["model"]): selector.select(index)
    selector.item_selected.connect(func(index): _feature(str(models[index])))
    intro.add_child(selector)
    var map = CityMap.new()
    map.destination_selected.connect(_change_tab)
    content.add_child(map)

func _feature(model: String) -> void:
    home_featured = model
    _render()

func _market() -> void:
    content.add_child(_label("GARAGE NACIONAL / AUTOS INSIGNIA",24))
    content.add_child(_label("Inspeccioná antes de comprar. La condición oculta puede convertir una oferta en una restauración costosa.",13))
    var grid := GridContainer.new()
    grid.columns = 2 if size.x >= 1100 else 1
    grid.add_theme_constant_override("h_separation",12)
    grid.add_theme_constant_override("v_separation",12)
    content.add_child(grid)
    for car in Catalog.market_order(game.cars):
        if car["owner"] != "seller":
            continue
        var panel := PanelContainer.new()
        panel.set_meta("vehicle_id",int(car["id"]))
        panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        panel.custom_minimum_size.x = 390 if grid.columns == 2 else 0
        grid.add_child(panel)
        var column := VBoxContainer.new()
        panel.add_child(column)
        column.add_child(_label(car["model"],24))
        if Catalog.flagship(str(car["model"])):
            column.add_child(_label("INSIGNIA · 3 PUERTAS · TRACCIÓN DELANTERA",12))
        var status := "CONDICIÓN %.1f / 100" % game.condition(car) if bool(car.get("inspected",false)) else "CONDICIÓN SIN VERIFICAR"
        column.add_child(_label("%s KM   /   %s" % [car["km"],status],12))
        var price := _label(Money.format(int(car["price"])),30)
        price.add_theme_color_override("font_color",Style.RED)
        column.add_child(price)
        if bool(car.get("inspected",false)):
            column.add_child(_label(game.inspection_summary(car),13))
        var actions := HFlowContainer.new()
        actions.add_theme_constant_override("h_separation",8)
        column.add_child(actions)
        var inspect_button := _button("INSPECCIÓN " + Money.format(200),_inspect.bind(int(car["id"])))
        inspect_button.disabled = bool(car.get("inspected",false)) or game.balance < 200
        actions.add_child(inspect_button)
        var buy := _button("COMPRAR",_buy.bind(int(car["id"])))
        buy.disabled = game.balance < int(car["price"])
        actions.add_child(buy)

func _garage() -> void:
    content.add_child(_label("MI GARAJE", 22))
    content.add_child(_label("¼ de milla: duelo contra otro auto de fábrica · Práctica individual disponible", 14))
    content.add_child(_label("Fábrica: sin preparación; conserva el desgaste. La categoría oficial «serie» tiene otro alcance.",13))
    var rivals := OptionButton.new()
    for title in ["NICO VEGA / TÉCNICO","CLAIRE MOREAU / AGRESIVA","AKIRA SATO / CONSERVADOR"]:
        rivals.add_item(title)
    rivals.select(["technical","aggressive","conservative"].find(duel_profile))
    rivals.item_selected.connect(func(index): duel_profile=["technical","aggressive","conservative"][index])
    content.add_child(rivals)
    var opponent_models := OptionButton.new()
    opponent_models.add_item("RIVAL: MISMO MODELO / COMPARAR PILOTOS")
    opponent_models.set_item_metadata(0,"")
    for model in Catalog.FLAGSHIPS+Catalog.CLASSICS+Catalog.NATIONALS:
        var index := opponent_models.item_count
        opponent_models.add_item("RIVAL: "+str(model))
        opponent_models.set_item_metadata(index,str(model))
        if str(model)==duel_opponent_model: opponent_models.select(index)
    opponent_models.item_selected.connect(func(index): duel_opponent_model=str(opponent_models.get_item_metadata(index)))
    content.add_child(opponent_models)
    var classes := OptionButton.new()
    classes.add_item("LIBRE / PRIMERA LLEGADA")
    classes.set_item_metadata(0,"")
    for category in DragClasses.classes():
        if category.unlimited: continue
        var index := classes.item_count
        classes.add_item("CLASE %s / PISO %.2f s ET" % [category.id,category.minimum_et])
        classes.set_item_metadata(index,category.id)
        if str(category.id)==duel_class: classes.select(index)
    classes.item_selected.connect(func(index): duel_class=str(classes.get_item_metadata(index)))
    content.add_child(classes)
    content.add_child(_label("Clases según art. 21 del reglamento aportado. Caer bajo el piso elimina; la reacción cuenta para llegar primero. Exhibición sin premios.",13))
    var selected: Dictionary = {}
    for vehicle in game.cars:
        if vehicle["owner"] == "player":
            if selected.is_empty() or int(vehicle["id"])==garage_featured:
                selected = vehicle
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
        layout.add_child(_label("Neumáticos: "+Tire.title(Tire.for_vehicle(car)),14))
        var metrics: Dictionary = DragConfig.from_vehicle(car,true).metrics()
        layout.add_child(_label("FICHA PROVISIONAL / FÁBRICA · %.0f kg + piloto %.0f kg · potencia base calculada %.1f CV (%.1f kW)" % [metrics["curb_mass_kg"],metrics["driver_mass_kg"],metrics["calculated_peak_power_cv"],metrics["calculated_peak_power_kw"]],13))
        var targets: Dictionary = metrics["reference_targets"]
        if not targets.is_empty():
            var details: Array[String] = []
            if targets.has("zero_to_hundred_s"): details.append("0–100 %.1f s" % float(targets.zero_to_hundred_s))
            if targets.has("top_speed_kmh"): details.append("máxima %.0f km/h" % float(targets.top_speed_kmh))
            if targets.has("power_cv"): details.append("%.0f CV" % float(targets.power_cv))
            layout.add_child(_label("%s · referencia: %s · calibración pendiente" % [metrics["variant"]," / ".join(details)],13))
        else:
            layout.add_child(_label(str(metrics["variant"])+" · perfil provisional",13))
        var best := career.lap_records.get_best(int(car["id"]))
        if best > 0.0:
            layout.add_child(_label("Mejor vuelta al club: %.2f s" % best, 15))
        if not metrics["record_revision"].is_empty():
            layout.add_child(_label("Referencia parcial: 1.4 BIO 1997 · 10,4 kgm · régimen de potencia y caja estimados",13))
        for record_set in [[career.drag_records,"manual"],[career.stock_drag_records,"fábrica"]]:
            var drag_best: Dictionary = record_set[0].best_for_profile(int(car["id"]),str(metrics["record_revision"]))
            if not drag_best.is_empty():
                layout.add_child(_label("Mejor ¼ de milla / %s: %.3f s · trampa %.1f km/h · reacción %.3f s" % [record_set[1],drag_best.et,drag_best.trap_kmh,drag_best.reaction],15))
            var historical: Dictionary = record_set[0].previous_best(int(car["id"]),str(metrics["record_revision"]))
            if not historical.is_empty():
                layout.add_child(_label("Marca histórica / %s (ficha anterior): %.3f s" % [record_set[1],historical.et],13))
        var actions := HFlowContainer.new()
        actions.add_theme_constant_override("h_separation", 8)
        layout.add_child(actions)
        actions.add_child(_button("VER MODELO",_preview_vehicle.bind(int(car["id"]))))
        var duel_button := _button("DUELO ¼ DE MILLA / FÁBRICA",_drag_duel.bind(int(car["id"])))
        duel_button.disabled = not game.eligible(car)
        actions.add_child(duel_button)
        var drag := _button("¼ DE MILLA / MANUAL",_drag_3d.bind(int(car["id"])))
        drag.disabled = not game.eligible(car)
        actions.add_child(drag)
        var drive_button := _button("PRUEBA SIMULADA 10 KM", _drive.bind(int(car["id"])))
        drive_button.disabled = not game.eligible(car)
        actions.add_child(drive_button)
        var drive_3d := _button("CONTRARRELOJ 3D", _drive_3d.bind(int(car["id"])))
        drive_3d.disabled = not game.eligible(car)
        actions.add_child(drive_3d)
        var race_3d := _button("CARRERA LIBRE 3D", _race_3d.bind(int(car["id"])))
        race_3d.disabled = not game.eligible(car)
        actions.add_child(race_3d)
        actions.add_child(_button("VENDER " + Money.format(game.resale_quote(int(car["id"]))), _sell.bind(int(car["id"]))))
    if not found:
        content.add_child(_label("No tenés vehículos. Visitá el concesionario."))

func _preview_vehicle(id: int) -> void:
    garage_featured = id
    _change_tab("garaje")

func _workshop() -> void:
    content.add_child(_label("TALLER MECÁNICO", 22))
    for car in game.cars:
        if car["owner"] != "player":
            continue
        content.add_child(_label("%s  ·  Estado %.1f" % [car["model"], game.condition(car)], 19))
        var problems := game.inspection_summary({"inspected": true, "faults": car.get("faults", {})})
        content.add_child(_label("Diagnóstico: " + problems, 14))
        var tires := HFlowContainer.new()
        tires.add_theme_constant_override("h_separation",8)
        content.add_child(tires)
        for kind in Economy.TIRE_PRICES:
            var quote := game.tire_quote(int(car["id"]),str(kind))
            var fit := _button("MONTAR " + Tire.title(str(kind)).to_upper() + " · " + Money.format(maxi(0,quote)),_replace_tires.bind(int(car["id"]),str(kind)))
            fit.disabled = quote<=0 or quote>game.balance
            tires.add_child(fit)
        content.add_child(_label("Calle: agarre desde frío · Deportivos: mayor exigencia térmica · Slick: más agarre en caliente y mayor desgaste",13))
        for component in Economy.WEIGHTS:
            var line := HBoxContainer.new()
            content.add_child(line)
            var state := _label("%s: %.1f / 100" % [component.capitalize(), float(car["health"][component])], 15)
            state.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            line.add_child(state)
            var price := game.repair_quote(int(car["id"]), component)
            var b := _button("REPARAR " + Money.format(price), _repair.bind(int(car["id"]), component))
            b.disabled = price <= 0 or price > game.balance
            line.add_child(b)

func _history() -> void:
    content.add_child(_label("MOVIMIENTOS ECONÓMICOS", 22))
    for entry in game.ledger:
        content.add_child(_label("Auto #%d · %s · %s" % [entry["car_id"], entry["event"], Money.format(int(entry["amount"]),true)], 16))

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
            var description := _label("%s · +%.1f · %s" % [part["name"], part["gain"], Money.format(int(part["price"]))], 15)
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
        var summary := "%s · Licencia %s · %s · %s" % [event["name"],event["license"],Money.format(int(event["fee"])),distance]
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

func _drag_3d(id: int) -> void:
    if not GameSession.start_drag(id):
        notice.text = "El auto no está disponible o tenés una inscripción pendiente."
        return
    get_tree().change_scene_to_file("res://scenes/drag.tscn")

func _drag_duel(id: int) -> void:
    if not GameSession.start_drag(id,"duel",duel_profile,duel_class,duel_opponent_model):
        notice.text = "El auto no está disponible o tenés una inscripción pendiente."
        return
    get_tree().change_scene_to_file("res://scenes/drag.tscn")

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
    game.ensure_flagship_offers()
    career = loaded["career"]
    GameSession.game = game
    GameSession.career = career
    notice.text = "Partida recuperada."
    _render()

func _replace_tires(id: int, kind: String) -> void:
    notice.text = game.replace_tires(id,kind)
    _render()

func _reset() -> void:
    GameSession.reset()
    game = GameSession.game
    career = GameSession.career
    notice.text = "Nueva partida iniciada."
    _render()

func _settings() -> void:
    content.add_child(_label("MÚSICA DE MENÚ",22))
    content.add_child(_label(GameSession.menu_music.TITLE,15))
    music_label = _label("Volumen: %.0f%%" % (GameSession.controls.music_volume*100),15)
    content.add_child(music_label)
    var volume_slider := HSlider.new()
    volume_slider.min_value = 0
    volume_slider.max_value = 1
    volume_slider.step = 0.05
    volume_slider.value = GameSession.controls.music_volume
    volume_slider.value_changed.connect(_set_music_volume)
    content.add_child(volume_slider)
    content.add_child(_label("MANDO Y AYUDAS / ¼ DE MILLA",22))
    controller_label = _label(GameSession.controls.controller.description(),14)
    content.add_child(controller_label)
    var clutch := OptionButton.new()
    clutch.add_item("EMBRAGUE: LB / L1 · LT / L2 FRENA")
    clutch.add_item("EMBRAGUE ANALÓGICO: LT / L2 · B / CÍRCULO FRENA")
    clutch.selected = 1 if GameSession.controls.analog_clutch else 0
    clutch.item_selected.connect(func(index): GameSession.controls.analog_clutch=index==1; _save_controls())
    content.add_child(clutch)
    for entry in [["Control de tracción (TCS)","traction_control"],["Freno antibloqueo (ABS)","abs_assist"]]:
        var toggle := CheckButton.new()
        toggle.text = entry[0]
        toggle.button_pressed = GameSession.controls.get(entry[1])
        toggle.toggled.connect(func(value): GameSession.controls.set(entry[1],value); _save_controls())
        content.add_child(toggle)
    content.add_child(_label("Stick/cruceta navega; A confirma; B vuelve; LB/RB cambia pestaña. Izquierda/derecha ajusta opciones y volumen.",14))
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
    for name in GameSession.controls.all_keys():
        var row := HBoxContainer.new()
        row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        bindings.add_child(row)
        var title := _label(GameSession.controls.TITLES[name])
        title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(title)
        row.add_child(_button(GameSession.controls.key_label(name),_request_binding.bind(name)))
    content.add_child(_label("MANDO EN CIRCUITO · Stick/cruceta: dirección · RT/R2: acelerar · LT/L2: freno
B/Círculo: reversa · X/Cuadrado: recuperar · Inicio/Select: pausa y salida al garaje", 14))
    deadzone_label = _label("Zona muerta del mando (%.0f%%)" % (GameSession.controls.deadzone * 100.0), 16)
    content.add_child(deadzone_label)
    var slider := HSlider.new()
    slider.min_value = 0.10
    slider.max_value = 0.40
    slider.step = 0.01
    slider.value = GameSession.controls.deadzone
    slider.value_changed.connect(_set_deadzone)
    content.add_child(slider)
    content.add_child(_button("RESTAURAR AJUSTES", _restore_controls))
    content.add_child(_label("Los ajustes se guardan automáticamente, separados de la partida. Mové o pulsá el mando para activarlo.", 14))

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
    GameSession.menu_music.set_volume(GameSession.controls.music_volume)
    _save_controls()
    _render()

func _set_music_volume(value: float) -> void:
    GameSession.controls.music_volume = value
    GameSession.menu_music.set_volume(value)
    if is_instance_valid(music_label):
        music_label.text = "Volumen: %.0f%%" % (value*100)
    _save_controls()

func _set_camera_mode(value: int) -> void:
    GameSession.controls.camera_mode = value
    _save_controls()

func _set_keyboard_steering(value: float) -> void:
    GameSession.controls.keyboard_steering = value
    if is_instance_valid(steering_label):
        steering_label.text = "Dirección del teclado: %.0f%% · Reducila para entradas más suaves." % (value*100.0)
    _save_controls()
