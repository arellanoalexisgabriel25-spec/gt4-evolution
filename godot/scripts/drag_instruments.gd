extends Control

const Style = preload("res://scripts/racing_theme.gd")
var speed_kmh := 0.0
var rpm := 900.0
var redline := 6500.0
const Feedback = preload("res://scripts/transmission_feedback.gd")
var shift_color := Color.TRANSPARENT
var shift_remaining := 0.0
var clutch_warning := false

func show_shift(quality: String, seconds: float) -> void:
    shift_color = Feedback.color(quality)
    shift_remaining = maxf(seconds,0.0)
    queue_redraw()

func _process(delta: float) -> void:
    if shift_remaining<=0.0: return
    shift_remaining = maxf(0.0,shift_remaining-delta)
    queue_redraw()

func readings(speed: float, engine_rpm: float, limit: float) -> void:
    speed_kmh = maxf(0.0,absf(speed))
    rpm = maxf(0.0,engine_rpm)
    redline = maxf(1000.0,limit)
    queue_redraw()

func angle(fraction: float) -> float:
    return deg_to_rad(135.0+clampf(fraction,0.0,1.0)*270.0)

func _text(text: String, point: Vector2, font_size: int, color: Color) -> void:
    var width := Style.MONO.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
    draw_string(Style.MONO,point-Vector2(width*0.5,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _dial(center: Vector2, value: float, maximum: float, engine: bool) -> void:
    var radius := 58.0
    var ink := Color("dce4e9")
    draw_circle(center,radius+2,Color(0.025,0.035,0.045,0.7))
    draw_arc(center,radius,angle(0),angle(1),65,Color(0.65,0.72,0.79,0.75),1.2,true)
    var divisions := int(maximum/1000.0)*4 if engine else 48
    for i in range(divisions+1):
        var fraction := float(i)/float(divisions)
        var vector := Vector2.from_angle(angle(fraction))
        var major := i%(4 if engine else 8)==0
        var color := Style.DANGER if engine and fraction*maximum>=redline else ink
        draw_line(center+vector*(radius-(9 if major else 4)),center+vector*(radius-1),color,1.2,true)
        if major:
            var number := "%.0f" % (fraction*maximum/(1000.0 if engine else 1.0))
            _text(number,center+vector*(radius-19)+Vector2(0,3),9,color)
    var pointer := Vector2.from_angle(angle(value/maximum))
    draw_line(center-pointer*7,center+pointer*(radius-12),Color("e7e5dc"),2.0,true)
    draw_circle(center,3,Style.DANGER)
    _text("×1000 RPM" if engine else "km/h",center+Vector2(0,21),9,Style.SECONDARY)

func _draw() -> void:
    _dial(Vector2(70,66),speed_kmh,240.0,false)
    _dial(Vector2(220,66),rpm,ceilf(redline/1000.0)*1000.0,true)
    if shift_remaining>0.0:
        draw_rect(Rect2(194,91,52,32),Color(shift_color,0.12),true)
        draw_line(Vector2(195,123),Vector2(245,123),shift_color,2.0,true)
    if clutch_warning:
        draw_circle(Vector2(145,65),5,Style.WARNING)
        _text("!",Vector2(145,69),10,Style.BACKGROUND)
