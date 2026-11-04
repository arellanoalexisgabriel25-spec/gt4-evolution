extends RefCounted

# The supplied GLB has a single static mesh. Partition its triangles into body
# and wheel regions without changing the source file or losing UVs/materials.
# Cache render meshes across showroom and race instances. Physical collision is
# deliberately separate: these detailed visual triangles are never colliders.
static var cache: Dictionary = {}

static func _render_material(source: Material) -> Material:
    if not source is BaseMaterial3D or source.albedo_texture!=null or not source.emission_enabled or source.emission_texture==null:
        return source
    # The supplied shaded scans store their baked appearance in emission over a
    # black base. Reuse that unchanged texture as lit albedo in a material copy:
    # the car then reacts to scene light/shadows instead of illuminating itself.
    # Never mutate the imported resource; the Gol's actual PBR material is kept.
    var material: BaseMaterial3D = source.duplicate()
    material.albedo_color = Color.WHITE
    material.albedo_texture = source.emission_texture
    material.emission_enabled = false
    material.emission_texture = null
    material.emission = Color.BLACK
    material.metallic = 0.0
    material.roughness = 0.8
    return material

static func build(profile: Dictionary) -> Dictionary:
    var path := str(profile.get("asset",""))
    var size_value = profile.get("size")
    var radius_value = profile.get("radius")
    var wheelbase_value = profile.get("wheelbase")
    if typeof(size_value)!=TYPE_VECTOR3 or not size_value.is_finite() or size_value.x<=0.0 or size_value.y<=0.0 or size_value.z<=0.0:
        return {}
    if typeof(radius_value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(radius_value)) or float(radius_value)<=0.0:
        return {}
    if typeof(wheelbase_value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(wheelbase_value)) or float(wheelbase_value)<=0.0:
        return {}
    # One source may be normalized for more than one configured variant.
    var cache_key := [path,size_value,float(radius_value),float(wheelbase_value)]
    if cache.has(cache_key):
        return cache[cache_key]
    if path.is_empty() or not ResourceLoader.exists(path):
        return {}
    var scene = load(path)
    if not scene is PackedScene:
        return {}
    var source = scene.instantiate()
    var nodes: Array = source.find_children("*","MeshInstance3D",true,false)
    if source is MeshInstance3D:
        nodes.push_front(source)
    if nodes.size()!=1 or nodes[0].mesh==null or nodes[0].mesh.get_surface_count()!=1:
        source.free()
        return {}
    var mesh_node: MeshInstance3D = nodes[0]
    var transform := Transform3D.IDENTITY
    var cursor: Node = mesh_node
    while cursor is Node3D:
        transform = cursor.transform*transform
        cursor = cursor.get_parent()
    var bounds: AABB = transform*mesh_node.mesh.get_aabb()
    if not bounds.position.is_finite() or not bounds.size.is_finite() or bounds.size.x<=0.0 or bounds.size.y<=0.0 or bounds.size.z<=0.0:
        source.free()
        return {}
    var size: Vector3 = profile["size"]
    var scale: Vector3 = size/bounds.size
    # The provided model faces +Z; the game's forward direction is -Z.
    var basis := Basis(Vector3.UP,PI)*Basis.from_scale(scale)
    var normal_basis := (basis*transform.basis).inverse().transposed()
    var center := Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
    var arrays: Array = mesh_node.mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
    var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
    var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
    if indices.is_empty():
        for i in range(vertices.size()): indices.append(i)
    var transformed := PackedVector3Array()
    for vertex in vertices:
        transformed.append(basis*(transform*vertex-center)+Vector3.DOWN*0.5)
    var radius := float(profile["radius"])
    var wheelbase := float(profile["wheelbase"])
    var centers: Array[Vector3] = []
    for x in [-1.0,1.0]:
        for z in [-1.0,1.0]:
            centers.append(Vector3(x*size.x*0.42,radius-0.5,z*wheelbase*0.5))
    var groups: Array = [[],[],[],[],[]]
    var source_material: Material = mesh_node.mesh.surface_get_material(0)
    var material: Material = _render_material(source_material)
    var diffuse: Image
    if material is BaseMaterial3D and material.albedo_texture!=null:
        diffuse = material.albedo_texture.get_image()
        if diffuse!=null and diffuse.is_compressed():
            diffuse.decompress()
    for triangle in range(0,indices.size(),3):
        var midpoint := (transformed[indices[triangle]]+transformed[indices[triangle+1]]+transformed[indices[triangle+2]])/3.0
        var group := 0
        var wheel_surface := true
        if diffuse!=null and uv.size()==vertices.size():
            var texcoord := (uv[indices[triangle]]+uv[indices[triangle+1]]+uv[indices[triangle+2]])/3.0
            var color := diffuse.get_pixel(clampi(int(texcoord.x*diffuse.get_width()),0,diffuse.get_width()-1),clampi(int(texcoord.y*diffuse.get_height()),0,diffuse.get_height()-1))
            # A spatial wheel region also contains painted fender triangles.
            # Keep those in the body; dark, nearly neutral rubber/rim texels
            # identify the supplied model's actual wheel surfaces.
            wheel_surface = color.get_luminance()<0.40 and maxf(color.r,maxf(color.g,color.b))-minf(color.r,minf(color.g,color.b))<0.22
        for wheel in range(4):
            var delta: Vector3 = midpoint-centers[wheel]
            if wheel_surface and absf(midpoint.x)>size.x*0.31 and signf(midpoint.x)==signf(centers[wheel].x) and Vector2(delta.y,delta.z).length()<radius*1.15:
                group = wheel+1
                break
        groups[group].append_array([indices[triangle],indices[triangle+1],indices[triangle+2]])
    for group in groups:
        if group.is_empty():
            source.free()
            return {}
    for wheel in range(4):
        var wheel_box := AABB(transformed[groups[wheel+1][0]],Vector3.ZERO)
        for vertex in groups[wheel+1]:
            wheel_box = wheel_box.expand(transformed[vertex])
        # Derive the visual pivot from the supplied wheel geometry. Approximate
        # catalog wheelbase is a search region, not a reason to make a tire wobble.
        centers[wheel] = wheel_box.get_center()
    var meshes: Array[ArrayMesh] = []
    var counts: Array[int] = []
    for group in range(5):
        var surface := SurfaceTool.new()
        surface.begin(Mesh.PRIMITIVE_TRIANGLES)
        surface.set_material(material)
        var offset := Vector3.ZERO if group==0 else centers[group-1]
        for vertex in groups[group]:
            if normals.size()==vertices.size():
                surface.set_normal((normal_basis*normals[vertex]).normalized())
            if uv.size()==vertices.size():
                surface.set_uv(uv[vertex])
            surface.add_vertex(transformed[vertex]-offset)
        if normals.size()!=vertices.size():
            surface.generate_normals()
        if uv.size()==vertices.size() and material is BaseMaterial3D and material.normal_enabled and material.normal_texture!=null:
            surface.generate_tangents()
        surface.index()
        meshes.append(surface.commit())
        counts.append(int(groups[group].size()/3))
    source.free()
    var result := {"meshes":meshes,"centers":centers,"triangle_counts":counts,"source_triangles":int(indices.size()/3),"size":size,"material_mode":"baked_lit" if material!=source_material else "source"}
    cache[cache_key] = result
    return result
