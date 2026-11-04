extends Node3D

# Original procedural bodywork: no manufacturer meshes or game assets.
var paint_color := Color("9e2933")
var model_name := ""
var wheels: Array[Node3D] = []
var front_pivots: Array[Node3D] = []
var brake_material: StandardMaterial3D

static func material(color: Color, metallic: float = 0.0, roughness: float = 0.5) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metallic
    mat.roughness = roughness
    return mat

func _box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    var shape := BoxMesh.new()
    shape.size = size
    mesh.mesh = shape
    mesh.position = pos
    mesh.material_override = mat
    add_child(mesh)
    return mesh

func _shell(rings: Array, mat: Material) -> void:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Each ring is (z, half-width, lower-height, upper-height).
    var vertices: Array[PackedVector3Array] = []
    for r in rings:
        vertices.append(PackedVector3Array([Vector3(-r[1],r[2],r[0]),Vector3(r[1],r[2],r[0]),Vector3(r[1],r[3],r[0]),Vector3(-r[1],r[3],r[0])]))
    for i in range(vertices.size() - 1):
        for j in range(4):
            var k := (j + 1) % 4
            for v in [vertices[i][j],vertices[i + 1][j],vertices[i + 1][k],vertices[i][j],vertices[i + 1][k],vertices[i][k]]:
                surface.add_vertex(v)
    for end in [0,vertices.size() - 1]:
        var ring := vertices[end]
        var order := [0,1,2,0,2,3] if end == 0 else [2,1,0,3,2,0]
        for j in order:
            surface.add_vertex(ring[j])
    surface.generate_normals()
    var mesh := MeshInstance3D.new()
    mesh.mesh = surface.commit()
    mesh.material_override = mat
    add_child(mesh)

func _ready() -> void:
    var body := material(paint_color, 0.55, 0.25)
    body.cull_mode = BaseMaterial3D.CULL_DISABLED
    var glass := material(Color("172c3e"), 0.65, 0.12)
    glass.cull_mode = BaseMaterial3D.CULL_DISABLED
    var black := material(Color("141a21"), 0.15, 0.55)
    var trim := material(Color("8c969e"), 0.8, 0.22)
    _shell([[-1.96,0.70,-0.13,0.17],[-1.5,0.85,-0.20,0.38],[-0.65,0.88,-0.20,0.42],[0.8,0.88,-0.20,0.42],[1.75,0.82,-0.16,0.32],[1.96,0.72,-0.10,0.20]],body)
    var hatch := model_name.contains("Civic") or model_name.contains("FTO") or model_name.contains("Levin")
    var roof_end := 1.1 if hatch else 0.72
    _shell([[-0.76,0.72,0.4,0.42],[-0.15,0.65,0.4,0.91],[roof_end,0.63,0.4,0.89],[1.43 if hatch else 1.05,0.72,0.4,0.42]],glass)
    _box(Vector3(1.30,0.065,roof_end + 0.18),Vector3(0,0.93,(roof_end - 0.15) * 0.5),body)
    _box(Vector3(0.055,0.44,0.10),Vector3(-0.72,0.64,0.39),body)
    _box(Vector3(0.055,0.44,0.10),Vector3(0.72,0.64,0.39),body)
    _box(Vector3(1.0,0.17,0.035),Vector3(0,0.02,-1.966),black)
    _box(Vector3(1.47,0.05,0.08),Vector3(0,-0.09,-1.97),black)
    _box(Vector3(1.45,0.08,0.09),Vector3(0,-0.09,1.96),black)
    var light := material(Color("edf3e5"),0.2,0.15)
    light.emission_enabled = true
    light.emission = Color("c7d5cc")
    light.emission_energy_multiplier = 0.45
    brake_material = material(Color("9f1521"),0.3,0.2)
    brake_material.emission_enabled = true
    brake_material.emission = Color("ff2638")
    brake_material.emission_energy_multiplier = 0.25
    for x in [-0.56,0.56]:
        _box(Vector3(0.38,0.14,0.05),Vector3(x,0.20,-1.94),light)
        _box(Vector3(0.40,0.13,0.05),Vector3(x,0.22,1.94),brake_material)
        _box(Vector3(0.2,0.11,0.16),Vector3(signf(x)*0.91,0.53,-0.25),body)
    for x in [-0.89,0.89]:
        for z in [-1.25,1.25]:
            var pivot := Node3D.new()
            pivot.position = Vector3(x,-0.20,z)
            add_child(pivot)
            if z < 0.0:
                front_pivots.append(pivot)
            var spin := Node3D.new()
            pivot.add_child(spin)
            wheels.append(spin)
            var tire := MeshInstance3D.new()
            var cylinder := CylinderMesh.new()
            cylinder.top_radius = 0.30
            cylinder.bottom_radius = 0.30
            cylinder.height = 0.22
            cylinder.radial_segments = 24
            tire.mesh = cylinder
            tire.material_override = black
            tire.rotation.z = PI * 0.5
            spin.add_child(tire)
            var rim := MeshInstance3D.new()
            var ring := CylinderMesh.new()
            ring.top_radius = 0.205
            ring.bottom_radius = 0.205
            ring.height = 0.228
            ring.radial_segments = 12
            rim.mesh = ring
            rim.rotation.z = PI * 0.5
            rim.material_override = trim
            spin.add_child(rim)
            for angle in range(5):
                var spoke := MeshInstance3D.new()
                var bar := BoxMesh.new()
                bar.size = Vector3(0.235,0.035,0.34)
                spoke.mesh = bar
                spoke.rotation.x = float(angle) * TAU / 5.0
                spoke.material_override = black
                spin.add_child(spoke)

func update_motion(delta: float, speed: float, steering: float, load_shift: float, brake: float) -> void:
    for wheel in wheels:
        wheel.rotation.x -= speed * delta / 0.30
    for pivot in front_pivots:
        pivot.rotation.y = -steering * 0.4
    rotation.x = lerp_angle(rotation.x,-load_shift * 0.045,1.0-exp(-8.0*delta))
    rotation.z = lerp_angle(rotation.z,-steering * speed * 0.0015,1.0-exp(-8.0*delta))
    brake_material.emission_energy_multiplier = 2.0 if brake > 0.05 else 0.25
