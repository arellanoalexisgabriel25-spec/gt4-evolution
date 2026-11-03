extends Control

const Economy = preload("res://scripts/economy.gd")
const SAVE_PATH := "user://evolution_save_v1.json"
var game: EvolutionEconomy
var current_tab := "mercado"
var content: VBoxContainer
var funds: Label
var notice: Label

func _ready() -> void:
    game = Economy.new()
    game.seed_demo()
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
    header.add_child(_label("GT4 EVOLUTION  /  PROTOTIPO 0.3", 27))
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

func _drive(id: int) -> void:
    notice.text = game.drive(id, 10)
    _render()

func _save() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        notice.text = "Error al guardar."
        return
    file.store_string(JSON.stringify(game.to_dict()))
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
    if typeof(parsed) != TYPE_DICTIONARY or not game.from_dict(parsed):
        notice.text = "Partida inválida, no se realizaron cambios."
        return
    notice.text = "Partida recuperada."
    _render()

func _reset() -> void:
    game.seed_demo()
    notice.text = "Nueva partida iniciada."
    _render()
