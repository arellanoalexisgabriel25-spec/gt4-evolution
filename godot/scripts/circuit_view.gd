extends Node3D

const Layout = preload("res://scripts/circuit_layout.gd")
const Vehicle = preload("res://scripts/vehicle_actor.gd")
var layout = Layout.new()

func _box(size: Vector3, location: Vector3, color: Color, angle: float = 0.0, solid: bool = false, custom_material: Material = null) -> Node3D:
    var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
    node.position = location
    node.rotation.y = angle
    add_child(node)
    if solid:
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        node.add_child(collision)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.material_override = custom_material if custom_material != null else Vehicle.paint(color)
    node.add_child(mesh)
    return node

func _ready() -> void:
    var world := WorldEnvironment.new()
    world.environment = Environment.new()
    world.environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var atmosphere := ProceduralSkyMaterial.new()
    atmosphere.sky_top_color = Color("426c99")
    atmosphere.sky_horizon_color = Color("c4d4e0")
    atmosphere.ground_horizon_color = Color("c0ced8")
    atmosphere.ground_bottom_color = Color("718084")
    atmosphere.sun_angle_max = 4.0
    atmosphere.sun_curve = 0.12
    sky.sky_material = atmosphere
    world.environment.sky = sky
    world.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
    world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    world.environment.ambient_light_color = Color("f7fbff")
    world.environment.ambient_light_energy = 0.3
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -30, 0)
    sun.light_energy = 0.95
    sun.light_color = Color("fff0d8")
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 120.0
    add_child(sun)
    var grass_shader := Shader.new()
    grass_shader.code = "shader_type spatial; varying vec3 p; void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){float strip=step(0.5,fract(p.z*0.055)); float grain=fract(sin(dot(floor(p.xz*10.0),vec2(12.9898,78.233)))*43758.5453); ALBEDO=mix(vec3(0.20,0.30,0.12),vec3(0.27,0.37,0.17),strip)*mix(0.92,1.05,grain); ROUGHNESS=1.0;}"
    var grass := ShaderMaterial.new()
    grass.shader = grass_shader
    var ground := _box(Vector3(340,1,340),Vector3(40,-0.55,0),Color("537345"),0.0,true,grass)
    # Match the character floor to the visible road top; grass is a shallow verge.
    ground.get_child(0).position.y = 0.09
    var road_shader := Shader.new()
    road_shader.code = "shader_type spatial; varying vec3 p; void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){float n=fract(sin(dot(floor(p.xz*22.0),vec2(12.9898,78.233)))*43758.5453); ALBEDO=vec3(0.135,0.15,0.17)*mix(0.86,1.12,n); ROUGHNESS=0.94;}"
    var asphalt := ShaderMaterial.new()
    asphalt.shader = road_shader
    for i in range(layout.points.size()):
        var start: Vector3 = layout.points[i]
        var end: Vector3 = layout.points[(i + 1) % layout.points.size()]
        var direction := (end - start).normalized()
        var side := Vector3(-direction.z, 0, direction.x)
        var center := (start + end) * 0.5
        var segment_length := start.distance_to(end)
        var angle := atan2(-direction.x, -direction.z)
        _box(Vector3(20,0.025,segment_length+0.3),center-Vector3.UP*0.025,Color("b9b2a0"),angle)
        _box(Vector3(16,0.08,segment_length+0.3),center,Color("303942"),angle,false,asphalt)
        for edge in [-1, 1]:
            _box(Vector3(1, 0.04, segment_length + 0.2), center + side * float(edge) * 7.5 + Vector3.UP * 0.07, Color("e8e7e0") if i % 2 == 0 else Color("bb4242"), angle)
            _box(Vector3(0.4, 0.9, segment_length + 0.15), center + side * float(edge) * Layout.BARRIER_OFFSET + Vector3.UP * 0.4, Color("dce4e6"), angle, true)
    for i in range(8):
        var location: Vector3 = layout.gates[i]
        var direction: Vector3 = layout.gate_directions[i]
        var angle := atan2(-direction.x, -direction.z)
        _box(Vector3(15, 0.025, 0.6), location + Vector3.UP * 0.07, Color("f3c969") if i > 0 else Color.WHITE, angle)
        for edge in [-1, 1]:
            _box(Vector3(0.3, 2.5, 0.3), location + Vector3(-direction.z, 0, direction.x) * edge * 8.5 + Vector3.UP * 1.2, Color("edaa33"))
        var label := Label3D.new()
        label.text = "" if i == 0 else str(i)
        label.position = location + Vector3(-direction.z,0,direction.x)*8.6 + Vector3.UP*2.9
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        label.font_size = 48
        add_child(label)

    # Start gantry and chequered line, with original circuit signage.
    var origin: Vector3 = layout.points[0]
    for x in [-8.7,8.7]:
        _box(Vector3(0.24,5.2,0.24),origin+Vector3(x,2.6,0),Color("a7b3bf"))
    _box(Vector3(17.6,0.95,0.22),origin+Vector3(0,4.8,0),Color("193a59"))
    var sign := Label3D.new()
    sign.text = "EVOLUTION  /  CLUB CIRCUIT"
    sign.position = origin+Vector3(0,4.8,0.14)
    sign.font = preload("res://scripts/racing_theme.gd").FONT
    sign.font_size = 68
    sign.pixel_size = 0.004
    sign.no_depth_test = false
    sign.outline_size = 3
    add_child(sign)
    for x in range(16):
        for z in range(2):
            _box(Vector3(0.95,0.012,0.75),origin+Vector3(-7.5+x,0.049,float(z)*0.75),Color.WHITE if (x+z)%2==0 else Color("19242d"))
    for distance in [28.0,52.0,82.0]:
        var along: float = distance
        var tangent: Vector3 = layout.tangent(along)
        var location: Vector3 = layout.sample(along) + Vector3(-tangent.z,0,tangent.x)*9.0
        var marker := Label3D.new()
        marker.text = "%d" % int(116.0-distance)
        marker.position = location + Vector3.UP*1.2
        marker.font_size = 88
        marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        add_child(marker)
    _scenery()

func _scenery() -> void:
    for i in range(11):
        var hill := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.top_radius = 0.0
        mesh.bottom_radius = 40.0 + float(i%4)*8.0
        mesh.height = 35.0 + float(i%3)*11.0
        mesh.radial_segments = 7
        hill.mesh = mesh
        hill.position = Vector3(-115.0+float(i)*32.0,5.0,-155.0-float(i%2)*20.0)
        hill.material_override = Vehicle.paint(Color("637b75") if i%2==0 else Color("748b85"))
        add_child(hill)
    for i in range(24):
        var location := Vector3(-27.0-float(i%3)*8.0,0,-110.0+float(i)*10.0)
        _box(Vector3(0.35,3.5,0.35),location+Vector3.UP*1.7,Color("635342"))
        var tree := MeshInstance3D.new()
        var cone := CylinderMesh.new()
        cone.top_radius = 0.15
        cone.bottom_radius = 2.1
        cone.height = 5.0
        cone.radial_segments = 8
        tree.mesh = cone
        tree.position = location+Vector3.UP*5.0
        tree.material_override = Vehicle.paint(Color("354f34"))
        add_child(tree)
    for row in range(5):
        _box(Vector3(1.8,0.5,30),Vector3(-19.0-row*1.6,0.3+row*0.45,5),Color("788894"))
        for section in range(6):
            _box(Vector3(1.1,0.18,3.8),Vector3(-19.0-row*1.6,0.65+row*0.45,-7.5+section*5.0),Color("284d75") if section%2==0 else Color("c7d1da"))
    _box(Vector3(12,0.25,33),Vector3(-22.5,5.0,5),Color("c2cbd1"))
    for z in [-10.0,20.0]:
        _box(Vector3(0.2,5.0,0.2),Vector3(-18,2.5,z),Color("8395a3"))
