extends Node3D

# Presentation only. Fixtures never create colliders or change surface grip.
# Four nearby lights move between fixed posts; distant asphalt pools are shaded
# analytically, avoiding fifty active lights on the long Compatibility road mesh.
const SPACING := 32.0
const POST_X := 10.6
const LAMP_HEIGHT := 8.6
var pool: Array[OmniLight3D] = []
var last_section := -9999

static func environment() -> Environment:
    var result := Environment.new()
    result.background_mode = Environment.BG_COLOR
    result.background_color = Color("080e1a")
    result.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    result.ambient_light_color = Color("9badc8")
    result.ambient_light_energy = 0.34
    result.fog_enabled = true
    result.fog_light_color = Color("101b2b")
    result.fog_light_energy = 0.45
    result.fog_density = 0.0018
    return result

func _mesh(size: Vector3, point: Vector3, color: Color, emitting: bool = false) -> void:
    var node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.78
    if emitting:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 1.3
    node.material_override = mat
    node.position = point
    add_child(node)

func _ready() -> void:
    var world := WorldEnvironment.new()
    world.environment = environment()
    add_child(world)
    var moon := DirectionalLight3D.new()
    moon.rotation_degrees = Vector3(-28,-32,0)
    moon.light_color = Color("a5b9d4")
    moon.light_energy = 0.18
    moon.shadow_enabled = true
    moon.directional_shadow_max_distance = 70.0
    add_child(moon)
    for z in range(32,-737,-32):
        for side in [-1.0,1.0]:
            _mesh(Vector3(0.12,LAMP_HEIGHT,0.12),Vector3(side*POST_X,LAMP_HEIGHT*0.5,z),Color("414854"))
            _mesh(Vector3(2.4,0.10,0.10),Vector3(side*(POST_X-1.15),LAMP_HEIGHT,z),Color("414854"))
            _mesh(Vector3(0.9,0.08,0.40),Vector3(side*8.5,LAMP_HEIGHT-0.06,z),Color("ffb65c"),true)
    for i in range(4):
        var light := OmniLight3D.new()
        light.light_color = Color("ffc17a")
        light.light_energy = 6.0
        light.omni_range = 29.0
        light.omni_attenuation = 1.3
        light.shadow_enabled = false
        add_child(light)
        pool.append(light)
    update_focus(0.0)
    # Original, lightweight silhouettes behind the paddock and runoff.
    for i in range(20):
        var height := 7.0+float((i*7)%13)
        var x := 48.0+float(i%4)*16.0
        var z := 8.0-float(i)*37.0
        _mesh(Vector3(10,height,18),Vector3(x,height*0.5,z),Color("18202b"))
        for row in range(3):
            _mesh(Vector3(0.02,0.45,6),Vector3(x-5.02,height-2.0-float(row)*1.7,z),Color("8c805b"),true)
    for z in range(14,-85,-16):
        _mesh(Vector3(0.05,0.2,7.5),Vector3(17.35,2.75,z),Color("acc5dd"),true)

func update_focus(z: float) -> void:
    var section := clampi(int(floor(z/SPACING)),-22,0)
    if section==last_section: return
    last_section = section
    for i in range(pool.size()):
        pool[i].position = Vector3(-8.5 if i%2==0 else 8.5,LAMP_HEIGHT-0.3,float(section+(i>>1))*SPACING)

func _process(_delta: float) -> void:
    var camera := get_viewport().get_camera_3d()
    if camera!=null: update_focus(camera.global_position.z)
