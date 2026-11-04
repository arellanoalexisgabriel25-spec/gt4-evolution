extends Control

# The map uses the actual circuit polyline and world positions; no race progress
# or checkpoint order is inferred from its display coordinates.
var route := PackedVector2Array()
var bounds := Rect2()
var positions: Array = []

func set_route(points: Array[Vector3]) -> void:
    route.clear()
    if points.is_empty():
        return
    bounds = Rect2(Vector2(points[0].x,points[0].z),Vector2.ZERO)
    for point in points:
        var planar := Vector2(point.x,point.z)
        route.append(planar)
        bounds = bounds.expand(planar)
    route.append(route[0])
    queue_redraw()

func map_point(point: Vector3) -> Vector2:
    var scale := minf((size.x-28.0)/maxf(bounds.size.x,1.0),(size.y-24.0)/maxf(bounds.size.y,1.0))
    return size*0.5 + (Vector2(point.x,point.z)-bounds.get_center())*scale

func _draw() -> void:
    if route.size() < 2:
        return
    draw_rect(Rect2(Vector2.ZERO,size),Color(0.025,0.06,0.11,0.58))
    var path := PackedVector2Array()
    for point in route:
        path.append(map_point(Vector3(point.x,0,point.y)))
    draw_polyline(path,Color("162433"),7,true)
    draw_polyline(path,Color("e4ebf1"),3,true)
    var start := path[0]
    var tangent := (path[1]-start).normalized()
    var side := Vector2(-tangent.y,tangent.x)*6
    draw_line(start-side,start+side,Color("e34449"),3,true)
    # Draw the player last so it remains visible in a close pack.
    for index in range(positions.size()-1,-1,-1):
        var point := map_point(positions[index])
        draw_circle(point,5,Color("162433"))
        draw_circle(point,3.5,Color("f3d778") if index == 0 else Color("7db9eb"))
