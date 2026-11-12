extends SceneTree

const Catalog = preload("res://scripts/car_catalog.gd")
const Imported = preload("res://scripts/imported_car.gd")
const Visual = preload("res://scripts/car_visual.gd")
const TRIANGLES := {"corsa":39996,"amarok":39998,"ranger":39999,"ecosport":39996,"corolla":40000,"palio":39998}
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func area_of_mesh(mesh: ArrayMesh) -> float:
    var arrays: Array = mesh.surface_get_arrays(0)
    var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
    if indices.is_empty():
        for index in range(positions.size()): indices.append(index)
    var area := 0.0
    for face in range(0,indices.size(),3):
        area += (positions[indices[face+1]]-positions[indices[face]]).cross(positions[indices[face+2]]-positions[indices[face]]).length()*0.5
    return area

func original_area(profile: Dictionary) -> float:
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
    var basis := Basis(Vector3.UP,PI)*Basis.from_scale(Vector3(profile.size)/bounds.size)
    var arrays: Array = node.mesh.surface_get_arrays(0)
    var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
    if indices.is_empty():
        for index in range(positions.size()): indices.append(index)
    var area := 0.0
    for face in range(0,indices.size(),3):
        var a: Vector3 = basis*(transform*positions[indices[face]])
        var b: Vector3 = basis*(transform*positions[indices[face+1]])
        var c: Vector3 = basis*(transform*positions[indices[face+2]])
        area += (b-a).cross(c-a).length()*0.5
    scene.free()
    return area

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    for name in Catalog.REGIONALS:
        var profile: Dictionary = Catalog.definition(name)
        var started := Time.get_ticks_usec()
        var built: Dictionary = Imported.build(profile)
        var build_seconds := float(Time.get_ticks_usec()-started)/1000000.0
        check(not built.is_empty(),"The supplied regional model partitions into a complete body and four wheels: "+name)
        if built.is_empty(): continue
        var total := 0
        for count in built.triangle_counts: total += int(count)
        check(int(built.source_triangles)==int(TRIANGLES[str(profile.key)]) and built.triangle_counts.min()>0,"The source-face accounting remains exact with complete body and wheel groups: "+name)
        check(total==int(built.render_triangles) and total>=int(built.source_triangles),"Render subdivisions are accounted separately from source faces")
        var render_area := 0.0
        for mesh in built.meshes: render_area += area_of_mesh(mesh)
        var source_area := original_area(profile)
        check(absf(render_area-source_area)<=maxf(0.0001,source_area*0.00001),"Clipping conserves the supplied model's surface area without holes or duplicated patches")
        check(built.wheel_segmentation=="configured_clip","Each new model uses a tire envelope independent of body paint color")
        var configured := 0
        for wheel in range(4):
            check(preload("res://tests/wheel_geometry_helpers.gd").within_envelope(built.meshes[wheel+1],built.contours[wheel]),"The rotating wheel stays inside its fitted envelope: "+name)
            if built.contours[wheel].get("configured",false) and not built.contours[wheel].fitted: configured += 1
            check(built.centers[wheel].is_finite() and absf(built.centers[wheel].z)>float(profile.wheelbase)*0.25,"Wheel pivots remain on the actual front or rear axle region")
        check(configured==4,"All four visual wheel envelopes are explicit estimates, never passed off as automatic physical measurements: "+name)
        var material: BaseMaterial3D = built.meshes[0].surface_get_material(0)
        check(material.albedo_texture!=null and not material.emission_enabled,"The optimized appearance uses scene lighting rather than self-illumination")
        var image: Image = material.albedo_texture.get_image()
        check(image!=null and image.get_width()==1024 and image.get_height()==1024,"The explicit compact texture dependency remains present and decodable")
        var visual = Visual.new()
        visual.model_name = name
        root.add_child(visual)
        await process_frame
        check(visual.imported_model and visual.wheels.size()==4 and visual.front_pivots.size()==2,"The real car visual consumes the supplied model and all four wheel groups")
        var body: MeshInstance3D = visual.get_child(0)
        var before := body.transform
        visual.update_motion(0.1,15.0,0.4,0.0,0.0,Vector2(30.0,5.0))
        check(absf(visual.wheels[0].rotation.x)>absf(visual.wheels[1].rotation.x)*5.9,"Independent axle rotation reaches the new imported wheels")
        check(absf(visual.front_pivots[0].rotation.y)>0.0 and body.transform==before,"Steering and wheel rotation leave the body mesh fixed")
        visual.queue_free()
        await process_frame
        print("Regional wheel partition ",name," faces=",built.triangle_counts," render faces=",total," configured=",configured," build_s=",build_seconds)
    var synthetic := [[Vector3(-1,-1,0),Vector3.FORWARD,Vector2(-1,-1)],[Vector3(1,-1,0),Vector3.FORWARD,Vector2(1,-1)],[Vector3(0,1,0),Vector3.FORWARD,Vector2(0,1)]]
    var pieces := Imported._split_visual_polygon(synthetic,Vector3.RIGHT,0.0)
    var parts: Array = []
    for polygon in pieces: Imported._triangulate_visual(polygon,parts)
    check(pieces[0].size()>=3 and pieces[1].size()>=3,"A crossing triangle retains polygons on both sides of the wheel cut")
    var uv_preserved := true
    var area := 0.0
    for vertex in parts:
        var point: Vector3 = vertex[0]
        if not Vector2(point.x,point.y).is_equal_approx(vertex[2]): uv_preserved=false
    for index in range(0,parts.size(),3):
        var a: Vector3=parts[index][0]
        var b: Vector3=parts[index+1][0]
        var c: Vector3=parts[index+2][0]
        area += (b-a).cross(c-a).length()*0.5
    check(uv_preserved and absf(area-2.0)<0.000001,"Cut vertices interpolate the original UV field while conserving triangle area")
    if not failed: print("PASS: %d regional visual assertions" % checks)
    quit(1 if failed else 0)
