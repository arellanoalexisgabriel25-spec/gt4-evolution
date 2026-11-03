extends Control

const Economy = preload("res://scripts/economy.gd")
const Career = preload("res://scripts/career.gd")
const Tuning = preload("res://scripts/tuning.gd")
const Rivals = preload("res://scripts/rivals.gd")
const SAVE_PATH := "user://evolution_save_v1.json"
var game: EvolutionEconomy
var career: EvolutionCareer
var current_tab := "mercado"
var content: VBoxContainer
var funds: Label
var notice: Label

func _ready() -> void:
    game = GameSession.game
    career = GameSession.career
    _build_interface()
    _render()

func _label(value: String, size: int = 17) -> Label:
    var label := Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size", size)
    return label

func _button(value: String, action: Callable) -> Button:
    var button := Button.new()
    button.text = value
    button.custom_minimum_size = Vector2(0, 42)
    button.pressed.connect(action)
    return button

func _build_interface() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#101823")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 24)
    add_child(margin)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 12)
    margin.add_child(root)
    var header := HBoxContainer.new()
    root.add_child(header)
    header.add_child(_label("GT4 EVOLUTION  /  PROTOTIPO 0.8", 27))
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(spacer)
    funds = _label("", 22)
    header.add_child(funds)
    root.add_child(_label("Modo amateur · Mercado exigente · Vehículos persistentes", 14))
    var tabs := HBoxContainer.new()
    root.add_child(tabs)
    for entry in [{"key":"mercado","title":"CONCESIONARIO"}, {"key":"garaje","title":"GARAJE"}, {"key":"taller","title":"TALLER"}, {"key":"historial","title":"MOVIMIENTOS"}]:
        tabs.add_child(_button(entry["title"], _change_tab.bind(entry["key"])))
    tabs.add_child(_button("MODO CARRERA", _change_tab.bind("carrera")))
    tabs.add_child(_button("TUNING", _change_tab.bind("tuning")))
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(scroll)
    content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 9)
    scroll.add_child(content)
    notice = _label("Empezá comprando un vehículo en el concesionario.", 15)
    notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root.add_child(notice)
    var actions := HBoxContainer.new()
    root.add_child(actions)
    actions.add_child(_button("GUARDAR", _save))
    actions.add_child(_button("CARGAR", _load))
    actions.add_child(_button("NUEVA PARTIDA", _reset))

func _change_tab(next: String) -> void:
    current_tab = next
    _render()

func _render() -> void:
    funds.text = "%d Cr." % game.balance
    for item in content.get_children():
        content.remove_child(item)
        item.queue_free()
    match current_tab:
        "mercado": _market()
        "garaje": _garage()
        "taller": _workshop()
        "historial": _history()
        "carrera": _career()
        "tuning": _tuning()

func _market() -> void:
    content.add_child(_label("MERCADO DE USADOS", 22))
    content.add_child(_label("Los precios reflejan kilometraje, desgaste y posibles averías. Inspeccioná antes de comprar.", 14))
    for car in game.cars:
        if car["owner"] != "seller":
            continue
        var line := HBoxContainer.new()
        content.add_child(line)
        var status := ("Estado %.1f/100" % game.condition(car)) if bool(car.get("inspected", false)) else "Estado desconocido"
        var info := _label("%s · %d km · %s · %d Cr." % [car["model"], car["km"], status, car["price"]], 16)
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        line.add_child(info)
        var inspection_button := _button("INSPECCIONAR 200 Cr.", _inspect.bind(int(car["id"])))
        inspection_button.disabled = bool(car.get("inspected", false)) or game.balance < 200
        line.add_child(inspection_button)
        var b := _button("COMPRAR", _buy.bind(int(car["id"])))
        b.disabled = game.balance < int(car["price"])
        line.add_child(b)
        if bool(car.get("inspected", false)):
            content.add_child(_label("  " + game.inspection_summary(car), 14))

func _garage() -> void:
    content.add_child(_label("MI GARAJE", 22))
    var found := false
    for car in game.cars:
        if car["owner"] != "player":
            continue
        found = true
        var line := HBoxContainer.new()
        content.add_child(line)
        var state := "APTO" if game.eligible(car) else "NECESITA REPARACIÓN"
        var info := _label("%s · %d km · %.1f/100 · %s" % [car["model"], car["km"], game.condition(car), state], 15)
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        line.add_child(info)
        var drive_button := _button("PRUEBA 10 KM", _drive.bind(int(car["id"])))
        drive_button.disabled = not game.eligible(car)
        line.add_child(drive_button)
        var drive_3d := _button("CONDUCIR 3D", _drive_3d.bind(int(car["id"])))
        drive_3d.disabled = not game.eligible(car)
        line.add_child(drive_3d)
        line.add_child(_button("VENDER %d Cr." % game.resale_quote(int(car["id"])), _sell.bind(int(car["id"]))))
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
    content.add_child(_label("Las mejoras influyen en carreras simuladas. Motor más potente = más desgaste.", 14))
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
    content.add_child(_label("Reputación: %d · Eventos de carrera simulados · Contrarreloj 3D disponible en el garaje." % career.reputation, 15))
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
        var summary := "%s · Licencia %s · %d Cr. de inscripción · %d km" % [event["name"],event["license"],event["fee"],event["distance"]]
        content.add_child(_label(summary, 17))
        if career.completed.has(event_id):
            content.add_child(_label("  COMPLETADO · premio único cobrado", 14))
            continue
        if owned.is_empty():
            content.add_child(_label("  Necesitás comprar un vehículo para inscribirte.", 14))
        for car in owned:
            var car_id := int(car["id"])
            var problem := career.can_enter(game, event_id, car_id)
            var button := _button("SIMULAR con %s" % car["model"], _race.bind(event_id, car_id))
            button.disabled = not problem.is_empty()
            content.add_child(button)
            if not problem.is_empty():
                content.add_child(_label("  " + problem, 13))

func _race(event_id: String, car_id: int) -> void:
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
    if not GameSession.choose_vehicle(id):
        notice.text = "El auto no está disponible o requiere reparación."
        return
    get_tree().change_scene_to_file("res://scenes/driving.tscn")

func _drive(id: int) -> void:
    notice.text = game.drive(id, 10)
    _render()

func _save() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        notice.text = "Error al guardar."
        return
    file.store_string(JSON.stringify({"save_version":2,"economy":game.to_dict(),"career":career.to_dict()}))
    file.close()
    notice.text = "Partida guardada."

func _load() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        notice.text = "No hay partida guardada."
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        notice.text = "Error al cargar."
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        notice.text = "Partida inválida."
        return
    var economy_data: Dictionary = parsed.get("economy", parsed)
    var career_data: Dictionary = parsed.get("career", Career.new().to_dict())
    var candidate_game: EvolutionEconomy = Economy.new()
    var candidate_career: EvolutionCareer = Career.new()
    if not candidate_game.from_dict(economy_data) or not candidate_career.from_dict(career_data):
        notice.text = "Partida inválida, no se realizaron cambios."
        return
    game = candidate_game
    career = candidate_career
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
