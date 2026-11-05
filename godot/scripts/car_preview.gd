extends SubViewportContainer

const Style = preload("res://scripts/racing_theme.gd")
const Visual = preload("res://scripts/car_visual.gd")
var model_name := ""
var paint_color := Color("a12b39")
var car
var viewport: SubViewport

func _ready() -> void:
    stretch = true
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    viewport = SubViewport.new()
    viewport.size = Vector2i(520,300)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
    add_child(viewport)
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Style.BACKGROUND
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color("c8d5e5")
    environment.environment.ambient_light_energy = 0.8
    viewport.add_child(environment)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-42,-35,0)
    light.light_energy = 1.5
    viewport.add_child(light)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-20,120,0)
    fill.light_color = Color("a3bcdc")
    fill.light_energy = 0.6
    viewport.add_child(fill)
    var floor_mesh := MeshInstance3D.new()
    var stage := CylinderMesh.new()
    stage.top_radius = 3.4
    stage.bottom_radius = 3.5
    stage.height = 0.14
    stage.radial_segments = 64
    floor_mesh.mesh = stage
    floor_mesh.position.y = -0.12
    floor_mesh.material_override = Visual.material(Style.ELEVATED,0.2,0.65)
    viewport.add_child(floor_mesh)
    car = Visual.new()
    car.model_name = model_name
    car.paint_color = paint_color
    car.position.y = 0.47
    car.rotation.y = 0.25
    viewport.add_child(car)
    var camera := Camera3D.new()
    camera.position = Vector3(4.6,2.55,-5.1)
    viewport.add_child(camera)
    camera.look_at(Vector3(0,0.7,0))
    camera.fov = 36.0
    camera.current = true

func _process(delta: float) -> void:
    if is_instance_valid(car):
        car.rotation.y += delta * 0.10
