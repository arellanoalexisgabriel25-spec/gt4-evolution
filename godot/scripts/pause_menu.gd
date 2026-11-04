extends Control

const Style = preload("res://scripts/racing_theme.gd")
const Navigation = preload("res://scripts/menu_controller.gd")
var mode
var first: Button
var nav
var heading: Label

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    visible = false
    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.02,0.04,0.08,0.78)
    add_child(shade)
    var card := PanelContainer.new()
    card.set_anchors_preset(Control.PRESET_CENTER)
    card.offset_left = -205
    card.offset_right = 205
    card.offset_top = -160
    card.offset_bottom = 160
    card.theme = Style.build()
    add_child(card)
    var column := VBoxContainer.new()
    card.add_child(column)
    heading = Label.new()
    heading.text = "PAUSA / GT4 EVOLUTION"
    heading.add_theme_font_override("font",Style.FONT)
    heading.add_theme_font_size_override("font_size",28)
    column.add_child(heading)
    for entry in [["CONTINUAR",_resume],["RECUPERAR VEHÍCULO",_recover],["VOLVER AL GARAJE",_leave]]:
        var button := Button.new()
        button.text = entry[0]
        button.custom_minimum_size.y = 44
        button.pressed.connect(entry[1])
        column.add_child(button)
        if first==null:
            first = button
    var help := Label.new()
    help.text = "Stick/cruceta: elegir · A: confirmar · B/Inicio: seguir"
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(help)
    nav = Navigation.new()
    nav.page = self
    nav.initial_focus = first
    nav.back_action = _resume
    nav.start_is_back = true
    add_child(nav)

func _process(_delta: float) -> void:
    var showing: bool = mode!=null and mode.paused
    if showing and not visible:
        visible = true
        first.grab_focus()
    elif not showing and visible:
        visible = false
        var focused := get_viewport().gui_get_focus_owner()
        if focused!=null and is_ancestor_of(focused):
            focused.release_focus()
    heading.text = "MANDO DESCONECTADO" if mode!=null and mode.controller_lost else "PAUSA / GT4 EVOLUTION"

func _input(event: InputEvent) -> void:
    if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
        return
    var viewport := get_viewport()
    if event.physical_keycode in [KEY_UP,KEY_DOWN]:
        nav._move(Vector2i(0,-1 if event.physical_keycode==KEY_UP else 1))
    elif event.physical_keycode==KEY_ENTER:
        var focused: Control = nav._focus()
        if focused is BaseButton:
            focused.pressed.emit()
    elif event.physical_keycode==KEY_ESCAPE:
        _resume()
    else:
        return
    viewport.set_input_as_handled()

func _resume() -> void:
    mode.paused = false
    mode.controller_lost = false
    _hide_menu()

func _hide_menu() -> void:
    visible = false
    var focused := get_viewport().gui_get_focus_owner()
    if focused!=null and is_ancestor_of(focused):
        focused.release_focus()

func _recover() -> void:
    mode.paused = false
    _hide_menu()
    if mode.has_method("_recover"):
        mode._recover()
    else:
        mode._reset_car()

func _leave() -> void:
    _hide_menu()
    mode._back_to_garage()
