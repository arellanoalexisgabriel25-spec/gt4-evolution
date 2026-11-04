extends SceneTree

const Catalog = preload("res://scripts/car_catalog.gd")
const Imported = preload("res://scripts/imported_car.gd")
const Visual = preload("res://scripts/car_visual.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var expected := [79998,79998,40000]
    for index in range(3):
        var name: String = Catalog.FLAGSHIPS[index]
        var profile: Dictionary = Catalog.DATA[name]
        check(ResourceLoader.exists(profile.asset),"Every flagship supplied model is present in the release")
        var visual = Visual.new()
        visual.model_name = name
        root.add_child(visual)
        await process_frame
        check(visual.imported_model and visual.wheels.size()==4 and visual.front_pivots.size()==2,"Every supplied model provides four separate wheel animations")
        var total := 0
        for count in visual.triangle_counts: total += int(count)
        check(total==expected[index] and visual.triangle_counts.min()>0,"Render partition preserves every runtime triangle without empty wheels")
        var bounds: AABB
        var first := true
        for node in visual.find_children("*","MeshInstance3D",true,false):
            var box: AABB = node.global_transform*node.mesh.get_aabb()
            bounds = box if first else bounds.merge(box)
            first = false
        check(bounds.size.is_equal_approx(profile.size),"The supplied model matches its configured visual dimensions")
        visual.update_motion(0.1,15,0.5,0,0,Vector2(30,10))
        check(absf(visual.wheels[0].rotation.x)>absf(visual.wheels[1].rotation.x)*2.9 and absf(visual.front_pivots[0].rotation.y)>0,"Front and rear wheel motion shows actual axle speed and steering")
        var built: Dictionary = Imported.build(profile)
        check(built.source_triangles==expected[index],"Cached render meshes retain their source triangle accounting")
        if index<2:
            check(built.material_mode=="baked_lit","Shaded model texture responds to lighting instead of illuminating the body")
            var source: Node = load(profile.asset).instantiate()
            var mesh: MeshInstance3D = source.find_children("*","MeshInstance3D",true,false)[0]
            var material: BaseMaterial3D = mesh.mesh.surface_get_material(0)
            check(material.emission_enabled and material.albedo_texture==null,"Building the visual never mutates the imported source material")
            var rendered: BaseMaterial3D = built.meshes[0].surface_get_material(0)
            check(not rendered.emission_enabled and rendered.albedo_texture!=null and rendered!=material,"Runtime uses an independent lit material with the supplied appearance")
            source.free()
        else:
            check(built.material_mode=="source","The Gol retains its original PBR material")
        visual.queue_free()
        await process_frame
    check(Imported.build({"asset":"res://missing.glb"}).is_empty(),"Missing/malformed profiles cannot produce partial render meshes")
    if not failed: print("PASS: %d imported flagship assertions" % checks)
    quit(1 if failed else 0)
