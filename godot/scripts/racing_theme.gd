extends RefCounted

const BLUE := Color("163858")
const INK := Color("25394e")
const RED := Color("b52c35")
const FONT = preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")

static func panel(color: Color = Color("edf0f4"), padding: float = 12.0) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = color
    box.set_border_width_all(1)
    box.border_color = Color("b4bfcc")
    box.content_margin_left = padding
    box.content_margin_right = padding
    box.content_margin_top = padding
    box.content_margin_bottom = padding
    box.shadow_color = Color(0, 0, 0, 0.12)
    box.shadow_size = 3
    box.shadow_offset = Vector2(0, 2)
    return box

static func build() -> Theme:
    var theme := Theme.new()
    theme.default_font_size = 15
    theme.set_color("font_color", "Label", INK)
    theme.set_font("font", "Button", FONT)
    theme.set_font_size("font_size", "Button", 19)
    theme.set_color("font_color", "Button", BLUE)
    theme.set_color("font_hover_color", "Button", BLUE)
    theme.set_color("font_pressed_color", "Button", Color.WHITE)
    theme.set_color("font_disabled_color", "Button", Color("8592a1"))
    theme.set_stylebox("normal", "Button", panel(Color("f4f6f9"), 9))
    theme.set_stylebox("hover", "Button", panel(Color("d9e5f2"), 9))
    theme.set_stylebox("pressed", "Button", panel(BLUE, 9))
    theme.set_stylebox("disabled", "Button", panel(Color("dce1e7"), 9))
    var focus := StyleBoxFlat.new()
    focus.bg_color = Color.TRANSPARENT
    focus.border_color = RED
    focus.set_border_width_all(2)
    theme.set_stylebox("focus", "Button", focus)
    theme.set_stylebox("panel", "PanelContainer", panel())
    theme.set_constant("separation", "VBoxContainer", 10)
    theme.set_constant("separation", "HBoxContainer", 10)
    return theme
