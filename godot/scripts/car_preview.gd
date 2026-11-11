extends Control

const Style = preload("res://scripts/racing_theme.gd")
const Visual = preload("res://scripts/car_visual.gd")
const Catalog = preload("res://scripts/car_catalog.gd")
var model_name := ""
var paint_color := Color("a12b39")
var car
var viewport: SubViewport

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    viewport = SubViewport.new()
    viewport.own_world_3d = true
    # Match the 1080p window scale without making the low-cost setting heavier.
    # The imported 3D preview otherwise gets enlarged from just 520x300.
    var session = get_tree().root.get_node_or_null("GameSession")
    var quality: String = session.controls.visual_quality if session!=null else "balanced"
    viewport.size = {"performance":Vector2i(520,300),"balanced":Vector2i(780,450),"high":Vector2i(1040,600)}.get(quality,Vector2i(780,450))
    viewport.msaa_3d = session.controls.msaa_level() if session!=null else Viewport.MSAA_2X
    viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
    add_child(viewport)
    # Draw the high-resolution render into the logical UI rectangle. Using a
    # SubViewportContainer with stretch=true silently resizes its viewport to
    # the low-resolution UI size, discarding any supersampling request.
    var display := TextureRect.new()
    display.mouse_filter = Control.MOUSE_FILTER_IGNORE
    display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    display.texture = viewport.get_texture()
    display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(display)
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Style.BACKGROUND
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color("c8d5e5")
    environment.environment.ambient_light_energy = 0.50
    viewport.add_child(environment)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-42,-35,0)
    light.light_energy = 1.7
    light.light_color = Color("fff0d9")
    light.shadow_enabled = true
    light.directional_shadow_max_distance = 15.0
    viewport.add_child(light)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-20,120,0)
    fill.light_color = Color("a3bcdc")
    fill.light_energy = 0.6
    viewport.add_child(fill)
    var rim := DirectionalLight3D.new()
    rim.rotation_degrees = Vector3(-30,160,0)
    rim.light_color = Color("9dc9ed")
    rim.light_energy = 0.55
    viewport.add_child(rim)
    var floor_mesh := MeshInstance3D.new()
    var stage := CylinderMesh.new()
    stage.top_radius = 3.4
    stage.bottom_radius = 3.5
    stage.height = 0.14
    stage.radial_segments = 64
    floor_mesh.mesh = stage
    floor_mesh.position.y = -0.12
    floor_mesh.material_override = Visual.material(Style.ELEVATED,0.25,0.42)
    viewport.add_child(floor_mesh)
    var ring := MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = 3.25
    torus.outer_radius = 3.28
    torus.rings = 64
    torus.ring_segments = 6
    ring.mesh = torus
    ring.position.y = -0.035
    ring.material_override = Visual.material(Style.ACCENT,0.55,0.35)
    viewport.add_child(ring)
    # Original studio backing gives dark bodywork a readable outline.
    for row in range(3):
        var strip := MeshInstance3D.new()
        var shape := BoxMesh.new()
        shape.size = Vector3(10.0,0.025,0.025)
        strip.mesh = shape
        strip.position = Vector3(0,0.45+row*0.35,4.3)
        strip.material_override = Visual.material(Style.BORDER,0.0,0.8)
        viewport.add_child(strip)
    car = Visual.new()
    car.model_name = model_name
    car.paint_color = paint_color
    car.position.y = 0.47
    car.rotation.y = 0.25
    viewport.add_child(car)
    var camera := Camera3D.new()
    var dimensions: Vector3 = Catalog.definition(model_name).get("size",Vector3(1.8,1.4,3.9))
    var framing := clampf(dimensions.z/3.9,0.92,1.4)
    camera.position = Vector3(4.6,2.55,-5.1)*framing
    viewport.add_child(camera)
    camera.look_at(Vector3(0,maxf(0.65,dimensions.y*0.45),0))
    camera.fov = 36.0
    camera.current = true

func _process(delta: float) -> void:
    if is_instance_valid(car):
        car.rotation.y += delta * 0.10
