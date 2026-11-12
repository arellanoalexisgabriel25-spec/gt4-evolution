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

func bright_faces(mesh: ArrayMesh) -> int:
    var material: BaseMaterial3D = mesh.surface_get_material(0)
    var image: Image = material.albedo_texture.get_image()
    if image.is_compressed(): image.decompress()
    var arrays: Array = mesh.surface_get_arrays(0)
    var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
    var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
    var count := 0
    for face in range(0,indices.size(),3):
        var uv := (uvs[indices[face]]+uvs[indices[face+1]]+uvs[indices[face+2]])/3.0
        var color := image.get_pixel(clampi(int(uv.x*image.get_width()),0,image.get_width()-1),clampi(int(uv.y*image.get_height()),0,image.get_height()-1))
        if color.get_luminance()>0.55: count += 1
    return count

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    for index in range(Catalog.CLASSICS.size()):
        var name: String = Catalog.CLASSICS[index]
        var profile: Dictionary = Catalog.definition(name)
        var built: Dictionary = Imported.build(profile)
        check(not built.is_empty(),"Every classic supplied mesh partitions into body and four complete wheel regions")
        if built.is_empty(): continue
        var triangles := 0
        for count in built.triangle_counts: triangles += int(count)
        check(built.source_triangles==(79996 if index==2 else 79998) and triangles>=built.source_triangles and built.triangle_counts.min()>0,"Clipped partitions preserve the source and have no empty wheels")
        check(built.wheel_segmentation=="contour" and built.material_mode=="baked_lit","Classics use geometric wheel envelopes and an independent lit copy of their texture")
        var bright_hubs := 0
        var fitted := 0
        for wheel in range(4):
            check(preload("res://tests/wheel_geometry_helpers.gd").within_envelope(built.meshes[wheel+1],built.contours[wheel]),"The rotating wheel stays inside its fitted envelope: "+name)
            bright_hubs += bright_faces(built.meshes[wheel+1])
            if built.contours[wheel].fitted: fitted += 1
            check(built.centers[wheel].is_finite() and absf(built.centers[wheel].z)>float(profile.wheelbase)*0.25,"Wheel pivots stay at the real separated front/rear geometry")
        check(fitted==4,"All four scanned tires provide a usable lower contour fit")
        check(bright_hubs>20,"Bright wheel-center triangles rotate with their tires instead of remaining in the body")
        var legacy: Dictionary = profile.duplicate(true)
        legacy.erase("wheel_segmentation")
        var color_only: Dictionary = Imported.build(legacy)
        check(not color_only.is_empty() and color_only.wheel_segmentation=="color","A mode change receives an independent cache entry")
        if not color_only.is_empty():
            var old_bright := 0
            for wheel in range(4): old_bright += bright_faces(color_only.meshes[wheel+1])
            check(old_bright>20,"Both legacy and contour profiles retain visible hub centers")
        var visual = Visual.new()
        visual.model_name = name
        root.add_child(visual)
        await process_frame
        check(visual.imported_model and visual.wheels.size()==4 and visual.front_pivots.size()==2,"The real car visual consumes all four separated classic wheels")
        var before: Array = []
        for child in visual.get_children():
            if child is MeshInstance3D: before.append(child.transform)
        visual.update_motion(0.1,15,0.5,0,0,Vector2(5,30))
        check(absf(visual.wheels[1].rotation.x)>absf(visual.wheels[0].rotation.x)*5.9,"Rear-driven axle speed is visible independently of front-wheel steering")
        var after: Array = []
        for child in visual.get_children():
            if child is MeshInstance3D: after.append(child.transform)
        check(before==after,"Animating wheels does not rotate the body mesh")
        visual.queue_free()
        await process_frame
        print("Classic wheel partition ",name," faces=",built.triangle_counts," light hub faces=",bright_hubs," fitted=",fitted)
    if not failed: print("PASS: %d classic visual assertions" % checks)
    quit(1 if failed else 0)
