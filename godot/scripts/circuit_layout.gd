extends RefCounted

# Original stadium-shaped club circuit. Geometry, AI and timing share this data.
const ROAD_HALF_WIDTH := 8.0
const BARRIER_OFFSET := 10.0
var points: Array[Vector3] = []
var distances: Array[float] = [0.0]
var length := 0.0
var gates: Array[Vector3] = []
var gate_directions: Array[Vector3] = []

func _init() -> void:
    points.append(Vector3(0, 0, 58))
    points.append(Vector3(0, 0, -58))
    _arc(Vector3(24, 0, -58), PI, PI * 1.5)
    points.append(Vector3(61, 0, -82))
    _arc(Vector3(61, 0, -58), PI * 1.5, TAU)
    points.append(Vector3(85, 0, 58))
    _arc(Vector3(61, 0, 58), 0.0, PI * 0.5)
    points.append(Vector3(24, 0, 82))
    _arc(Vector3(24, 0, 58), PI * 0.5, PI)
    points.pop_back() # Closing point equals the first point.
    for i in range(points.size()):
        length += points[i].distance_to(points[(i + 1) % points.size()])
        distances.append(length)
    for i in range(8):
        var along := length * float(i) / 8.0
        gates.append(sample(along))
        gate_directions.append(tangent(along))

func _arc(center: Vector3, start: float, end: float) -> void:
    for i in range(1, 17):
        var angle := lerpf(start, end, float(i) / 16.0)
        points.append(center + Vector3(cos(angle), 0, sin(angle)) * 24.0)

func sample(along: float) -> Vector3:
    var wrapped := fposmod(along, length)
    for i in range(points.size()):
        if wrapped <= distances[i + 1]:
            var fraction := (wrapped - distances[i]) / (distances[i + 1] - distances[i])
            return points[i].lerp(points[(i + 1) % points.size()], fraction)
    return points[0]

func tangent(along: float) -> Vector3:
    return (sample(along + 0.5) - sample(along - 0.5)).normalized()

func project(position: Vector3) -> Dictionary:
    var point := Vector2(position.x, position.z)
    var closest_distance := INF
    var along := 0.0
    var offset := 0.0
    for i in range(points.size()):
        var start := Vector2(points[i].x, points[i].z)
        var end3 := points[(i + 1) % points.size()]
        var end := Vector2(end3.x, end3.z)
        var closest := Geometry2D.get_closest_point_to_segment(point, start, end)
        var separation := point.distance_to(closest)
        if separation < closest_distance:
            closest_distance = separation
            along = distances[i] + start.distance_to(closest)
            var direction := (end - start).normalized()
            offset = (point - closest).dot(Vector2(-direction.y, direction.x))
    return {"along":fposmod(along, length), "distance":closest_distance, "offset":offset}

func on_road(position: Vector3) -> bool:
    return float(project(position)["distance"]) <= ROAD_HALF_WIDTH
