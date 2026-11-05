extends Node3D

# Original lamp geometry and one headlight cone per vehicle, with no physics.
var dimensions := Vector3(1.8,1.4,3.9)
var draw_housings := true
var rear_material: StandardMaterial3D
var beam: SpotLight3D
var brake_pool: SpotLight3D

func _lamp(size: Vector3, point: Vector3, mat: Material) -> void:
    var lamp := MeshInstance3D.new()
    var shape := BoxMesh.new()
    shape.size = size
    lamp.mesh = shape
    lamp.material_override = mat
    lamp.position = point
    add_child(lamp)

func _ready() -> void:
    var front := StandardMaterial3D.new()
    front.albedo_color = Color("f4dfae")
    front.emission_enabled = true
    front.emission = Color("fff0ca")
    front.emission_energy_multiplier = 1.7
    rear_material = StandardMaterial3D.new()
    rear_material.albedo_color = Color("991913")
    rear_material.emission_enabled = true
    rear_material.emission = Color("ed3022")
    rear_material.emission_energy_multiplier = 0.5
    var height := dimensions.y*0.34-0.5
    # Imported scans retain their actual textured housings. Bounding-box lamps
    # float outside tapered bumpers; reserve simple geometry for placeholders.
    if draw_housings:
        for side in [-1.0,1.0]:
            _lamp(Vector3(0.19,0.07,0.025),Vector3(side*dimensions.x*0.32,height,-dimensions.z*0.5-0.012),front)
            _lamp(Vector3(0.12,0.08,0.025),Vector3(side*dimensions.x*0.38,height+0.05,dimensions.z*0.5+0.012),rear_material)
    beam = SpotLight3D.new()
    beam.position = Vector3(0,height,-dimensions.z*0.5-0.06)
    beam.rotation_degrees.x = -5.0
    beam.light_color = Color("fff1ce")
    beam.light_energy = 2.0
    beam.spot_range = 42.0
    beam.spot_angle = 38.0
    beam.spot_attenuation = 0.8
    beam.shadow_enabled = false
    add_child(beam)
    brake_pool = SpotLight3D.new()
    brake_pool.position = Vector3(0,height+0.1,dimensions.z*0.5+0.06)
    brake_pool.rotation_degrees = Vector3(-12,180,0)
    brake_pool.light_color = Color("ee3826")
    brake_pool.light_energy = 1.8
    brake_pool.spot_range = 5.0
    brake_pool.spot_angle = 65.0
    brake_pool.shadow_enabled = false
    brake_pool.visible = false
    add_child(brake_pool)

func set_brake(value: float) -> void:
    rear_material.emission_energy_multiplier = 2.8 if value>0.05 else 0.5
    brake_pool.visible = value>0.05
