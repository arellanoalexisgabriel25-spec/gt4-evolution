extends SceneTree
const Catalog = preload("res://scripts/car_catalog.gd")
const Imported = preload("res://scripts/imported_car.gd")
const Visual = preload("res://scripts/car_visual.gd")
var checks:=0
var failed:=false
func check(ok: bool, why: String) -> void:
    checks+=1
    if not ok:
        failed=true
        push_error(why)
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

func _initialize() -> void: call_deferred("run")
func run() -> void:
    for name in ["Fiat 147 Vivace","Fiat Uno Fire 3 puertas","Volkswagen Gol Power 3 puertas","Fiat 128 estándar","Fiat 133","Volkswagen Amarok"]:
        var profile: Dictionary = Catalog.definition(name)
        var rig: Dictionary = Imported.build(profile)
        check(not rig.is_empty(),"The supplied vehicle model loads: "+name)
        if rig.is_empty(): continue
        var source_area := original_area(profile)
        var rendered_area := 0.0
        for mesh in rig.meshes: rendered_area+=area_of_mesh(mesh)
        check(absf(rendered_area-source_area)<=maxf(0.0001,source_area*0.00001),"Wheel separation preserves the complete original surface area: "+name)
        var visual=Visual.new()
        visual.model_name=name
        root.add_child(visual)
        await process_frame
        check(visual.wheels.size()==4,"Four separate wheels are present: "+name)
        if visual.wheels.size()!=4:
            visual.queue_free()
            continue
        var ratio: float = rig.wheel_scale_yz.x/rig.wheel_scale_yz.y
        for index in range(4):
            var arrays: Array = rig.meshes[index+1].surface_get_arrays(0)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var radii: Vector2 = rig.contours[index].radii
            var outside := 0
            for v in vertices:
                if Vector2(v.y/radii.x,v.z/radii.y).length()>1.01: outside+=1
            check(outside==0,"No rotating vertex extends outside the tire envelope: "+name)
        for wheel in visual.wheels:
            var restore: Node3D = wheel.get_parent()
            var unscale: Node3D = wheel.get_child(0)
            var vertex := Vector3(0.0,ratio*0.3,0.11)
            var expected := Vector2(vertex.y/ratio,vertex.z).length()
            for angle in [0.0,0.7,1.6,2.8]:
                wheel.rotation.x=angle
                var point: Vector3 = restore.transform * wheel.transform * unscale.transform * vertex
                check(absf(Vector2(point.y/ratio,point.z).length()-expected)<0.0001,"A rotating rim retains its source-space radius: "+name)
        visual.queue_free()
        await process_frame
    if not failed: print("PASS: %d wheel rotation shape assertions"%checks)
    quit(1 if failed else 0)
