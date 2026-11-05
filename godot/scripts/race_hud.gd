extends Control

signal return_requested
signal camera_requested
const Style = preload("res://scripts/racing_theme.gd")
const TrackMap = preload("res://scripts/track_map.gd")
var track_map
var lap_details: Label
var ranking: Label
var time_label: Label
var best_label: Label
var speed_label: Label
var gear_label: Label
var rpm_label: Label
var status_label: Label
var help_label: Label
var camera_label: Label
var rpm_fraction := 0.0

func _text(parent: Node, value: String, font_size: int) -> Label:
    var label := Label.new()
    label.text = value
    label.add_theme_font_override("font",Style.FONT)
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",Style.TEXT)
    parent.add_child(label)
    return label

func _panel(rect: Rect2, anchors: Vector2 = Vector2.ZERO) -> VBoxContainer:
    var panel := PanelContainer.new()
    panel.anchor_left = anchors.x
    panel.anchor_right = anchors.x
    panel.anchor_top = anchors.y
    panel.anchor_bottom = anchors.y
    panel.offset_left = rect.position.x
    panel.offset_top = rect.position.y
    panel.offset_right = rect.end.x
    panel.offset_bottom = rect.end.y
    panel.add_theme_stylebox_override("panel",Style.panel(Style.HUD_BACKGROUND,12))
    add_child(panel)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation",2)
    panel.add_child(column)
    return column

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    theme = Style.build()
    var field := _panel(Rect2(20,20,235,130))
    lap_details = _text(field,"VUELTA 1",24)
    ranking = _text(field,"",18)
    var clock := _panel(Rect2(-160,20,320,83),Vector2(0.5,0))
    time_label = _text(clock,"0:00.000",36)
    time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    best_label = _text(clock,"MEJOR  —",16)
    best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var speed := _panel(Rect2(-265,-183,245,153),Vector2.ONE)
    var numbers := HBoxContainer.new()
    speed.add_child(numbers)
    gear_label = _text(numbers,"1",54)
    gear_label.add_theme_color_override("font_color",Style.SELECTED)
    speed_label = _text(numbers,"0",64)
    speed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    rpm_label = _text(speed,"KM/H     900 RPM",16)
    rpm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    for metric in [gear_label,speed_label,rpm_label,time_label,best_label]:
        metric.add_theme_font_override("font",Style.MONO)
    camera_label = _text(speed,"SEGUIMIENTO",14)
    camera_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    var actions := HBoxContainer.new()
    actions.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    actions.offset_left = -255
    actions.offset_right = -20
    actions.offset_top = 20
    actions.offset_bottom = 60
    add_child(actions)
    var back := Button.new()
    back.text = "VOLVER"
    back.custom_minimum_size = Vector2(105,36)
    back.pressed.connect(func(): return_requested.emit())
    actions.add_child(back)
    var camera_button := Button.new()
    camera_button.text = "CÁMARA"
    camera_button.custom_minimum_size = Vector2(105,36)
    camera_button.pressed.connect(func(): camera_requested.emit())
    actions.add_child(camera_button)
    track_map = TrackMap.new()
    track_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
    track_map.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    track_map.offset_left = -175
    track_map.offset_right = -20
    track_map.offset_top = 82
    track_map.offset_bottom = 248
    add_child(track_map)
    status_label = _text(self,"",26)
    status_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
    status_label.offset_left = -320
    status_label.offset_right = 320
    status_label.offset_top = 128
    status_label.offset_bottom = 218
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_color_override("font_shadow_color",Color.BLACK)
    status_label.add_theme_constant_override("shadow_offset_x",2)
    status_label.add_theme_constant_override("shadow_offset_y",2)
    help_label = _text(self,"",15)
    help_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    help_label.offset_left = 22
    help_label.offset_right = 702
    help_label.offset_top = -110
    help_label.offset_bottom = -10
    help_label.add_theme_color_override("font_shadow_color",Color.BLACK)
    help_label.add_theme_constant_override("shadow_offset_x",1)
    help_label.add_theme_constant_override("shadow_offset_y",1)

static func format_time(seconds: float) -> String:
    var milliseconds := maxi(0,int(roundf(seconds*1000.0)))
    return "%d:%02d.%03d" % [milliseconds/60000,(milliseconds/1000)%60,milliseconds%1000]

func update_telemetry(data: Dictionary) -> void:
    speed_label.text = "%.0f" % data["speed"]
    gear_label.text = "R" if int(data["gear"]) == -1 else str(data["gear"])
    rpm_label.text = "KM/H     %.0f RPM" % data["rpm"]
    rpm_fraction = clampf(float(data["rpm"])/maxf(float(data["redline"]),1.0),0,1)
    time_label.text = format_time(float(data["time"]))
    best_label.text = "MEJOR  " + (format_time(float(data["best"])) if float(data["best"]) > 0.0 else "—")
    camera_label.text = str(data["camera"])
    lap_details.text = str(data["lap"])
    ranking.text = str(data["ranking"])
    status_label.text = str(data["status"])
    help_label.text = str(data["help"])
    track_map.positions = data.get("positions",[])
    track_map.queue_redraw()
    queue_redraw()

func _draw() -> void:
    for i in range(20):
        var active := float(i)/20.0 < rpm_fraction
        var color := Style.BORDER
        if active:
            color = Style.DANGER if i >= 16 else Style.HOVER
        draw_rect(Rect2(Vector2(size.x-265+i*12.2,size.y-193),Vector2(10,6)),color)
