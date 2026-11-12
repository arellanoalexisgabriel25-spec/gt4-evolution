extends SceneTree

# Gallery scans never imply a mechanical variant. Exercise the real mesh rig and
# conserve all rendered surface area when cutting independent visual wheels.
const Catalog = preload("res://scripts/car_catalog.gd")
const Imported = preload("res://scripts/imported_car.gd")
const Visual = preload("res://scripts/car_visual.gd")
const StockSpecs = preload("res://scripts/stock_vehicle_specs.gd")
const Economy = preload("res://scripts/economy.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func mesh_area(mesh: ArrayMesh, basis: Basis = Basis.IDENTITY) -> float:
    var arrays: Array = mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
    if indices.is_empty():
        for i in range(vertices.size()): indices.append(i)
    var area := 0.0
    for face in range(0,indices.size(),3):
        var a: Vector3 = basis*vertices[indices[face]]
        var b: Vector3 = basis*vertices[indices[face+1]]
        var c: Vector3 = basis*vertices[indices[face+2]]
        area += (b-a).cross(c-a).length()*0.5
    return area

func _initialize() -> void: call_deferred("run")

func run() -> void:
    var profile: Dictionary = Catalog.definition("Volkswagen Taos")
    check(Catalog.SHOWROOM_ONLY.has("Volkswagen Taos") and profile.get("visual_only",false),"The supplied Taos is explicitly a gallery-only scan")
    check(not Catalog.DATA.has("Volkswagen Taos") and not profile.has("gears") and not profile.has("torque") and not profile.has("mass"),"A visual scan cannot silently acquire a fictional manual gearbox or factory powertrain")
    check(StockSpecs.for_model("Volkswagen Taos").is_empty(),"The gallery Taos has no fabricated stock specification")
    var game = Economy.new()
    game.seed_demo()
    check(not game.cars.any(func(car): return car.model=="Volkswagen Taos") and Catalog.market_order(game.cars).size()==game.cars.size(),"Gallery integration leaves every previous market offer and its ordering available")
    var built: Dictionary = Imported.build(profile)
    check(not built.is_empty(),"The optimized supplied Taos builds a complete render rig")
    if built.is_empty():
        quit(1)
        return
    check(built.source_triangles==39998 and built.meshes.size()==5 and built.triangle_counts.min()>0,"The runtime derivative contains a body and all four nonempty wheel groups")
    for wheel in range(4):
        check(preload("res://tests/wheel_geometry_helpers.gd").within_envelope(built.meshes[wheel+1],built.contours[wheel]),"Exhibition wheel geometry remains inside its envelope")
    check(built.wheel_segmentation=="configured_clip","Explicit estimated tire envelopes keep paint color out of wheel segmentation")
    var total_area := 0.0
    for mesh in built.meshes:
        total_area += mesh_area(mesh)
        var arrays: Array = mesh.surface_get_arrays(0)
        var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
        check(uv.size()>0 and uv.size()==arrays[Mesh.ARRAY_VERTEX].size(),"Every cut part retains its texture coordinates")
    var scene: Node = load(profile.asset).instantiate()
    var nodes: Array = scene.find_children("*","MeshInstance3D",true,false)
    if scene is MeshInstance3D: nodes.push_front(scene)
    var node: MeshInstance3D = nodes[0]
    var transform := Transform3D.IDENTITY
    var cursor: Node = node
    while cursor is Node3D:
        transform=cursor.transform*transform
        cursor=cursor.get_parent()
    var bounds: AABB = transform*node.mesh.get_aabb()
    var basis: Basis = Basis(Vector3.UP,PI)*Basis.from_scale(Vector3(profile.size)/bounds.size)*transform.basis
    var original_area := mesh_area(node.mesh,basis)
    check(absf(total_area-original_area)<maxf(0.0001,original_area*0.00001),"Separating the Taos wheels conserves source surface area without holes or duplicate patches")
    scene.free()
    var material: BaseMaterial3D = built.meshes[0].surface_get_material(0)
    check(material.albedo_texture!=null and not material.emission_enabled,"The supplied appearance is lit by the scene rather than self-illuminated")
    var image: Image = material.albedo_texture.get_image()
    check(image!=null and image.get_width()==1024 and image.get_height()==1024 and image.has_mipmaps(),"The compact external albedo resolves with its full mip chain")
    var visual = Visual.new()
    visual.model_name="Volkswagen Taos"
    root.add_child(visual)
    await process_frame
    check(visual.imported_model and visual.wheels.size()==4 and visual.front_pivots.size()==2,"The actual gallery visual consumes the optimized Taos and its complete rig")
    var body: Node3D = visual.get_child(0)
    var before: Transform3D = body.transform
    visual.update_motion(0.1,15.0,0.4,0.0,0.0,Vector2(30,5))
    check(absf(visual.wheels[0].rotation.x)>absf(visual.wheels[1].rotation.x)*5.9,"Wheel animation follows separate front and rear axle rotation")
    check(absf(visual.front_pivots[0].rotation.y)>0.0 and body.transform==before,"Steering and wheel animation leave the body mesh fixed")
    visual.queue_free()
    await process_frame
    if not failed: print("PASS: %d Taos gallery and visual rig assertions" % checks)
    quit(1 if failed else 0)
