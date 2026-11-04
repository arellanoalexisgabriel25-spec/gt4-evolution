extends Control

signal destination_selected(destination: String)
const Style = preload("res://scripts/racing_theme.gd")
const ENTRIES := [
    {"key":"mercado","name":"USED CAR DEALER","sub":"Mercado de usados","point":Vector2(0.08,0.17)},
    {"key":"garaje","name":"MY GARAGE","sub":"Tu colección","point":Vector2(0.61,0.12)},
    {"key":"carrera","name":"RACE EVENTS","sub":"Carrera profesional","point":Vector2(0.34,0.42)},
    {"key":"taller","name":"SERVICE CENTER","sub":"Inspección y reparación","point":Vector2(0.07,0.71)},
    {"key":"tuning","name":"TUNING SHOP","sub":"Preparación mecánica","point":Vector2(0.66,0.68)}]
var buttons: Array[Button] = []

func _ready() -> void:
    custom_minimum_size = Vector2(0,220)
    for entry in ENTRIES:
        var button := Button.new()
        button.text = entry["name"] + "\n" + entry["sub"]
        button.custom_minimum_size = Vector2(180,61)
        button.add_theme_font_size_override("font_size",19)
        button.pressed.connect(func(): destination_selected.emit(entry["key"]))
        add_child(button)
        buttons.append(button)
    resized.connect(_layout)
    _layout()

func _layout() -> void:
    for i in range(buttons.size()):
        buttons[i].position = ENTRIES[i]["point"] * Vector2(maxf(size.x-180,0),maxf(size.y-61,0))
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,size),Color("e4e9ef"))
    # Abstract original city plan: park blocks, a waterfront and a road network.
    var water := PackedVector2Array()
    for point in [Vector2(0.83,0),Vector2(1,0),Vector2(1,1),Vector2(0.73,1),Vector2(0.86,0.48)]:
        water.append(point*size)
    draw_polygon(water,PackedColorArray([Color("b1c9dc")]))
    for x in range(1,12):
        for y in range(1,7):
            var point := Vector2(float(x)/13.0,float(y)/8.0)*size
            var color := Color("c6d5c2") if (x+y)%5==0 else Color("d1d8e0")
            draw_rect(Rect2(point,Vector2(size.x/22.0,size.y/15.0)),color)
    var roads := [PackedVector2Array([Vector2(0,0.3),Vector2(0.24,0.3),Vector2(0.43,0.56),Vector2(0.85,0.56)]),PackedVector2Array([Vector2(0.21,0),Vector2(0.21,0.65),Vector2(0.49,1)]),PackedVector2Array([Vector2(0.62,0),Vector2(0.59,0.35),Vector2(0.73,1)])]
    for road in roads:
        var scaled := PackedVector2Array()
        for point in road:
            scaled.append(point*size)
        draw_polyline(scaled,Color("adb9c6"),10.0,true)
        draw_polyline(scaled,Color("f4f6f8"),6.0,true)
    for x in range(0,int(size.x),32):
        draw_line(Vector2(x,0),Vector2(x,size.y),Color(1,1,1,0.15))
