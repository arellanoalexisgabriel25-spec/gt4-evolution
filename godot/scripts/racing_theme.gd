extends RefCounted

# Shared tokens from the user's GT4_UI_System design reference. One theme drives
# every service, popup and HUD; no borrowed game imagery or external UI runtime.
const BACKGROUND := Color("0f1419")
const PANEL := Color("1a2129")
const ELEVATED := Color("232b35")
const BORDER := Color("2e3845")
const ACCENT := Color("3a7ca5")
const HOVER := Color("5ba3d0")
const SELECTED := Color("7ec8e3")
const TEXT := Color("e8eef2")
const SECONDARY := Color("8a97a3")
const DISABLED := Color("5a6570")
const SUCCESS := Color("4caf82")
const WARNING := Color("d4a017")
const DANGER := Color("c44b4b")
const SILVER := Color("a8b2bc")
const HUD_BACKGROUND := Color(0.0588,0.0784,0.0980,0.78)
# Public aliases retain compatibility with original menu and circuit callers.
const BLUE := ACCENT
const INK := TEXT
const RED := DANGER
const FONT = preload("res://assets/fonts/Barlow-SemiBold.ttf")
const BODY = preload("res://assets/fonts/Barlow-Regular.ttf")
const MONO = preload("res://assets/fonts/RobotoMono-Variable.ttf")

static func panel(color: Color = PANEL, padding: float = 16.0) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = color
    box.set_border_width_all(1)
    box.border_color = BORDER
    box.set_corner_radius_all(6)
    box.content_margin_left = padding
    box.content_margin_right = padding
    box.content_margin_top = padding
    box.content_margin_bottom = padding
    return box

static func navigation(selected: bool, hovered: bool = false) -> StyleBoxFlat:
    var box := panel(Color(ACCENT,0.27) if selected else (ELEVATED if hovered else PANEL),9)
    box.set_border_width_all(0)
    box.border_width_left = 3 if selected else 0
    box.border_color = HOVER
    box.set_corner_radius_all(4)
    return box

static func build() -> Theme:
    var theme := Theme.new()
    theme.default_font = BODY
    theme.default_font_size = 16
    theme.set_color("font_color","Label",TEXT)
    theme.set_font("font","Button",FONT)
    theme.set_font_size("font_size","Button",16)
    for state in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]:
        theme.set_color(state,"Button",TEXT)
    theme.set_color("font_disabled_color","Button",DISABLED)
    for entry in [["normal",PANEL],["hover",ELEVATED],["pressed",ACCENT.darkened(0.3)],["disabled",PANEL]]:
        var button := panel(entry[1],8)
        button.set_corner_radius_all(4)
        button.content_margin_left=12
        button.content_margin_right=12
        button.border_color=HOVER if entry[0]=="hover" else BORDER
        theme.set_stylebox(entry[0],"Button",button)
    var focus := panel(Color.TRANSPARENT,0)
    focus.border_color=HOVER
    theme.set_stylebox("focus","Button",focus)
    theme.set_type_variation("PrimaryButton","Button")
    for entry in [["normal",ACCENT],["hover",HOVER],["pressed",ACCENT.darkened(0.25)]]:
        var primary := panel(entry[1],8)
        primary.set_corner_radius_all(4)
        theme.set_stylebox(entry[0],"PrimaryButton",primary)
    theme.set_color("font_hover_color","PrimaryButton",BACKGROUND)
    theme.set_font_size("font_size","PrimaryButton",19)
    theme.set_stylebox("panel","PanelContainer",panel())
    for kind in ["OptionButton","CheckButton","CheckBox"]:
        theme.set_font("font",kind,BODY)
        theme.set_font_size("font_size",kind,16)
        for state in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]:
            theme.set_color(state,kind,TEXT)
        theme.set_color("font_disabled_color",kind,DISABLED)
        for state in ["normal","hover","pressed","disabled","focus"]:
            theme.set_stylebox(state,kind,theme.get_stylebox(state,"Button"))
    theme.set_stylebox("panel","PopupMenu",panel(ELEVATED,8))
    theme.set_stylebox("hover","PopupMenu",navigation(true))
    theme.set_color("font_color","PopupMenu",TEXT)
    theme.set_color("font_hover_color","PopupMenu",TEXT)
    theme.set_color("font_disabled_color","PopupMenu",DISABLED)
    theme.set_stylebox("normal","LineEdit",panel(BACKGROUND,8))
    theme.set_stylebox("focus","LineEdit",focus)
    theme.set_color("font_color","LineEdit",TEXT)
    theme.set_color("font_placeholder_color","LineEdit",DISABLED)
    theme.set_color("caret_color","LineEdit",SELECTED)
    theme.set_color("selection_color","LineEdit",ACCENT)
    theme.set_stylebox("panel","ItemList",panel())
    theme.set_stylebox("selected","ItemList",navigation(true))
    theme.set_stylebox("selected_focus","ItemList",navigation(true))
    theme.set_color("font_color","ItemList",TEXT)
    theme.set_color("font_selected_color","ItemList",TEXT)
    var tab := panel(PANEL,10)
    tab.set_border_width_all(0)
    tab.border_width_bottom=2
    tab.border_color=HOVER
    theme.set_stylebox("tab_selected","TabBar",tab)
    theme.set_stylebox("tab_unselected","TabBar",panel(BACKGROUND,10))
    theme.set_color("font_selected_color","TabBar",TEXT)
    theme.set_color("font_unselected_color","TabBar",SECONDARY)
    theme.set_stylebox("panel","TabContainer",panel())
    theme.set_stylebox("background","ProgressBar",panel(BORDER,0))
    theme.set_stylebox("fill","ProgressBar",panel(ACCENT,0))
    theme.set_font("font","ProgressBar",MONO)
    theme.set_color("font_color","ProgressBar",TEXT)
    for kind in ["HSlider","VSlider"]:
        theme.set_stylebox("slider",kind,panel(BORDER,2))
        theme.set_stylebox("grabber_area",kind,panel(ACCENT,2))
        theme.set_stylebox("grabber_area_highlight",kind,panel(HOVER,2))
    for kind in ["VScrollBar","HScrollBar"]:
        theme.set_stylebox("scroll",kind,panel(BACKGROUND,2))
        theme.set_stylebox("grabber",kind,panel(BORDER,4))
        theme.set_stylebox("grabber_highlight",kind,panel(ACCENT,4))
        theme.set_stylebox("grabber_pressed",kind,panel(HOVER,4))
    theme.set_constant("separation","VBoxContainer",10)
    theme.set_constant("separation","HBoxContainer",10)
    return theme
