extends Node3D

const Visual = preload("res://scripts/car_visual.gd")
const Style = preload("res://scripts/racing_theme.gd")
const Surfaces = preload("res://scripts/track_surface.gd")
const Run = preload("res://scripts/drag_run.gd")
const Night = preload("res://scripts/drag_night.gd")
const LANE_X := -3.75
var blue_lamp: StandardMaterial3D
var far_yellow: Array[StandardMaterial3D] = []
var marshal_sign: Label3D
var lamps: Array[StandardMaterial3D] = []
var stage_lamps: Array[StandardMaterial3D] = []
var dual_lanes := false
var opponent_lamps: Array[StandardMaterial3D] = []
var opponent_stage_lamps: Array[StandardMaterial3D] = []

func box(size: Vector3, location: Vector3, color: Color, solid: bool = false, mat: Material = null) -> Node3D:
    var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
    node.position = location
    add_child(node)
    if solid:
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        node.add_child(collision)
    var instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    instance.mesh = mesh
    instance.material_override = mat if mat != null else Visual.material(color,0,0.85)
    node.add_child(instance)
    return node

func sign_text(value: String, location: Vector3, font_size: int = 90, scale: float = 0.004) -> Label3D:
    var label := Label3D.new()
    label.text = value
    label.font = Style.FONT
    label.font_size = font_size
    label.pixel_size = scale
    label.position = location
    label.outline_size = 3
    add_child(label)
    return label

func _ready() -> void:
    var night := Night.new()
    night.name = "NightPresentation"
    add_child(night)
    var ground := box(Vector3(200,1,920),Vector3(0,-0.56,-320),Color("263327"),true)
    ground.get_child(0).position.y = 0.10
    var shader := Shader.new()
    shader.code = "shader_type spatial; varying vec3 p; void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){float grain=fract(sin(dot(floor(p.xz*18.0),vec2(12.9898,78.233)))*43758.5453); float rubber=1.0-smoothstep(0.3,0.8,abs(abs(p.x)-3.75)); float dz=mod(p.z+16.0,32.0)-16.0; float pool=exp(-dz*dz/105.0)*0.075; ALBEDO=vec3(0.16,0.17,0.19)*mix(0.90,1.06,grain)*(1.0-rubber*0.30); EMISSION=vec3(1.0,0.60,0.26)*pool*(1.0-rubber*0.25); ROUGHNESS=0.88;}"
    var asphalt := ShaderMaterial.new()
    asphalt.shader = shader
    # Surface borders and tire queries share these exact dimensions.
    box(Vector3(Surfaces.GRAVEL_HALF_WIDTH*2.0,0.04,Surfaces.LENGTH),Vector3(0,-0.025,Surfaces.CENTER_Z),Color("b5ae94"))
    box(Vector3(Surfaces.APRON_HALF_WIDTH*2.0,0.04,Surfaces.LENGTH),Vector3(0,0.005,Surfaces.CENTER_Z),Color("686b69"))
    box(Vector3(Surfaces.ROAD_HALF_WIDTH*2.0,0.06,Surfaces.LENGTH),Vector3(0,0.01,Surfaces.CENTER_Z),Color("343b43"),false,asphalt)
    for side in [-1,1]:
        box(Vector3(0.35,0.92,780),Vector3(side*9.7,0.46,-325),Color("c7c8be"),true)
        box(Vector3(0.12,0.012,775),Vector3(side*8.5,0.047,-325),Color("d5d5ca"))
        for z in range(30,-690,-12):
            box(Vector3(0.055,2.3,0.055),Vector3(side*10.15,1.3,z),Color("7b878b"))
    for z in range(10,-690,-10):
        box(Vector3(0.12,0.01,4),Vector3(0,0.05,z),Color("e2dfcd"))
    for x in [-3.75,3.75]:
        for z in [0.0,18.288,100.0,201.168,402.336]:
            box(Vector3(6.9,0.012,0.18),Vector3(x,0.053,-z-1.25),Color("d8d8d0"))
    for x in range(18):
        for row in range(2):
            box(Vector3(0.95,0.015,0.65),Vector3(-8.5+x,0.058,-Run.DISTANCE-1.25-row*0.65),Color("d8d8d0") if (x+row)%2==0 else Color("1d252d"))
    for distance in [18.288,100.0,201.168,402.336,500.0,600.0]:
        var text := "60 FT" if distance < 20 else ("1/8 MILLA" if distance < 202 and distance > 200 else ("402,336 M / META" if distance < 403 and distance > 402 else "%d M" % int(distance)))
        var board := box(Vector3(2.8,0.7,0.12),Vector3(12.0,1.6,-distance-1.25),Color("173650"))
        var label := sign_text(text,board.position+Vector3(0,0,0.08),64,0.004)
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    _grandstand()
    _paddock()
    _tree()
    # Authorized warm-up lies AHEAD of the line (sports text art.11).
    # Paint only: it changes neither the road grip nor the stock engine's power.
    for lane in [LANE_X,-LANE_X] if dual_lanes else [LANE_X]:
        for distance in [2.5,35.0]:
            box(Vector3(6.2,0.008,0.12),Vector3(lane,0.055,-distance),Color("c3a65a"))
    blue_lamp = _lamp(Vector3(0,4.1,-6.75),Color("3595ff"))
    for side in [-1,1]:
        far_yellow.append(_lamp(Vector3(side*7.5,3.0,-410),Color("ecb543")))
        box(Vector3(0.08,3.0,0.08),Vector3(side*7.5,1.5,-410),Color("63717a"))
    marshal_sign = sign_text("CALENTAMIENTO",Vector3(0,4.6,-6.75),55,0.003)
    # Long braking zone beyond the finish, ending in a real collision barrier.
    box(Vector3(19,1.2,0.5),Vector3(0,0.6,-710),Color("ba433c"),true)
    sign_text("FRENAR / FIN DE PISTA",Vector3(0,2.3,-706),110,0.007)
    sign_text("AUTÓDROMO SUR   /   402",Vector3(0,5.5,-1.25),96,0.004)
    box(Vector3(19,0.85,0.18),Vector3(0,5.5,-1.35),Color("183650"))
    for x in [-9.2,9.2]:
        box(Vector3(0.22,5.8,0.22),Vector3(x,2.9,-1.25),Color("7d8c92"))

func _grandstand() -> void:
    for row in range(7):
        box(Vector3(1.4,0.5,105),Vector3(-16.0-row*1.3,0.3+row*0.48,-32),Color("929994"))
        for section in range(13):
            box(Vector3(0.85,0.15,5.9),Vector3(-16.0-row*1.3,0.63+row*0.48,15-section*8),Color("426987") if section%3!=0 else Color("b4c3c5"))
    box(Vector3(12.8,0.18,109),Vector3(-20,7,-32),Color("c2c6bc"))
    for z in range(18,-90,-18):
        box(Vector3(0.16,7,0.16),Vector3(-15.0,3.5,z),Color("8d9899"))
    # Irregular overlapping crowns replace the repeated single-sphere trees.
    # Shared meshes and materials keep distant vegetation inexpensive.
    var crown := SphereMesh.new()
    crown.radius = 2.6
    crown.height = 4.6
    var foliage := [Visual.material(Color("263c31"),0,1),Visual.material(Color("304a39"),0,1),Visual.material(Color("385342"),0,1)]
    var clusters := [Vector3(-1.6,6.3,0),Vector3(1.3,6.8,0.8),Vector3(0.0,8.0,-0.9),Vector3(-0.2,5.7,1.7)]
    for z in range(-110,-600,-50):
        box(Vector3(0.6,5,0.6),Vector3(-22,2.5,z),Color("514c40"))
        for index in range(clusters.size()):
            var leaf := MeshInstance3D.new()
            leaf.mesh = crown
            leaf.material_override = foliage[index%foliage.size()]
            leaf.position = Vector3(-22,0,z)+clusters[index]
            leaf.scale = Vector3(1.0+0.08*(index%2),0.82+0.1*(index%3),1.0)
            leaf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
            add_child(leaf)

func _paddock() -> void:
    box(Vector3(12,6.0,17),Vector3(21,3,6),Color("bdbaab"))
    box(Vector3(13,0.35,18),Vector3(21,6.2,6),Color("405567"))
    box(Vector3(11,1.4,0.08),Vector3(21,4.8,14.55),Color("1c364d"))
    sign_text("CONTROL / CUARTO DE MILLA",Vector3(21,3.3,14.6),66,0.003)
    for z in range(-20,-90,-16):
        box(Vector3(9,3.2,12),Vector3(22,1.6,z),Color("c5c1af"))
        box(Vector3(9.7,0.18,12.6),Vector3(22,3.25,z),Color("547385"))
        box(Vector3(0.06,2.4,8),Vector3(17.45,1.2,z),Color("555f64"))
    # Original geometry for the Argentine colours; no borrowed stadium imagery.
    for x in [16.0,28.0]:
        box(Vector3(0.065,9,0.065),Vector3(x,4.5,21),Color("b3c0c3"))
        for stripe in range(3):
            box(Vector3(2.6,0.42,0.035),Vector3(x+1.3,8.2-stripe*0.42,21),Color("70b8da") if stripe!=1 else Color("eeeeeb"))

func _lamp(location: Vector3, color: Color) -> StandardMaterial3D:
    var instance := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.17
    sphere.height = 0.34
    instance.mesh = sphere
    var mat := Visual.material(color*0.2)
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = 0.03
    instance.material_override = mat
    instance.position = location
    add_child(instance)
    return mat

func _tree() -> void:
    box(Vector3(0.1,3.5,0.1),Vector3(0,1.75,-7.0),Color("5d6970"))
    box(Vector3(0.8,2.8,0.25),Vector3(0,2.4,-6.95),Color("182128"))
    for y in [3.5,3.15]:
        stage_lamps.append(_lamp(Vector3(-0.22 if dual_lanes else 0.0,y,-6.75),Color("d3e7ed")))
        if dual_lanes:
            opponent_stage_lamps.append(_lamp(Vector3(0.22,y,-6.75),Color("d3e7ed")))
    for i in range(5):
        var color := Color("ecb543") if i < 3 else (Color("43c575") if i == 3 else Color("e73743"))
        lamps.append(_lamp(Vector3(-0.22 if dual_lanes else 0.0,2.75-float(i)*0.43,-6.75),color))
        if dual_lanes:
            opponent_lamps.append(_lamp(Vector3(0.22,2.75-float(i)*0.43,-6.75),color))

func update_tree(run, staged: bool, other = null, other_staged: bool = false, procedure: Dictionary = {}) -> void:
    for mat in stage_lamps:
        mat.emission_energy_multiplier = 1.3 if staged else 0.03
    for i in range(lamps.size()):
        var active: bool = (run.phase == "countdown" and i < 3 and run.clock>=0.5+float(i)*0.5) or (i==3 and run.phase in ["running","finished"]) or (i==4 and run.phase=="invalid")
        lamps[i].emission_energy_multiplier = 1.5 if active else 0.03
    if other!=null:
        for mat in opponent_stage_lamps:
            mat.emission_energy_multiplier = 1.3 if other_staged else 0.03
        for i in range(opponent_lamps.size()):
            var active: bool = (other.phase=="countdown" and i<3 and other.clock>=0.5+float(i)*0.5) or (i==3 and other.phase in ["running","finished"]) or (i==4 and other.phase=="invalid")
            opponent_lamps[i].emission_energy_multiplier = 1.5 if active else 0.03

    if not procedure.is_empty():
        var warming: bool = bool(procedure.get("red_flashing",false))
        var flash: bool = fmod(float(procedure.get("elapsed",0.0)),0.6)<0.3
        if warming:
            for index in range(lamps.size()):
                lamps[index].emission_energy_multiplier = 1.5 if index==4 and flash else 0.03
            for index in range(opponent_lamps.size()):
                opponent_lamps[index].emission_energy_multiplier = 1.5 if index==4 and flash else 0.03
        if blue_lamp!=null:
            blue_lamp.emission_energy_multiplier = 1.8 if procedure.get("blue_on",false) else 0.03
        for mat in far_yellow:
            mat.emission_energy_multiplier = 1.5 if procedure.get("far_yellow_on",false) else 0.03
        if marshal_sign!=null:
            marshal_sign.text = "CALENTAMIENTO" if warming else ("ALINEAR · LUZ AZUL" if procedure.get("blue_on",false) else "ATENCIÓN AL SEMÁFORO")
        if procedure.get("phase")=="expired":
            lamps[4].emission_energy_multiplier = 1.5
            for mat in opponent_lamps:
                mat.emission_energy_multiplier = 0.03
            marshal_sign.text = "LARGADA CANCELADA"
