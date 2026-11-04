extends RefCounted

# The supplied GLB has a single static mesh. Partition its triangles into body
# and wheel regions without changing the source file or losing UVs/materials.
# Cache render meshes across showroom and race instances. Physical collision is
# deliberately separate: these detailed visual triangles are never colliders.
static var cache: Dictionary = {}

# Fit the lower tire outline, where neither the fender nor the sill covers it.
# These are render-only estimates: the physical wheel radius remains in config.
# Sampling one lowest point per longitudinal bin avoids weighting dense scan
# patches more heavily than sparse patches of the same tire.
static func _wheel_contour(vertices: PackedVector3Array, approximate: Vector3, radius: float, width: float, visual_scale: Vector3) -> Dictionary:
    const BINS := 24
    var lows := PackedFloat32Array()
    var positions := PackedFloat32Array()
    lows.resize(BINS)
    positions.resize(BINS)
    lows.fill(INF)
    for vertex in vertices:
        if absf(vertex.x)<width*0.31 or signf(vertex.x)!=signf(approximate.x):
            continue
        var along := vertex.z-approximate.z
        if absf(along)>radius*0.85 or vertex.y>approximate.y-radius*0.15:
            continue
        var bin := clampi(int((along/(radius*1.7)+0.5)*BINS),0,BINS-1)
        if vertex.y<lows[bin]:
            lows[bin] = vertex.y
            positions[bin] = vertex.z
    # Fit in the pre-normalization Y/Z scale. A circle fit to the stretched
    # lower arc biases the hub upward and can include the fender; undoing the
    # known visual scale keeps the scan's original circular tire envelope.
    var count := 0.0
    var uu := 0.0
    var uv := 0.0
    var vv := 0.0
    var u := 0.0
    var v := 0.0
    var rhs := Vector3.ZERO
    for index in range(BINS):
        if not is_finite(lows[index]): continue
        var point := Vector2((positions[index]-approximate.z)/visual_scale.z,(lows[index]-approximate.y)/visual_scale.y)
        var squared := point.length_squared()
        uu += point.x*point.x
        uv += point.x*point.y
        vv += point.y*point.y
        u += point.x
        v += point.y
        count += 1.0
        rhs -= Vector3(point.x*squared,point.y*squared,squared)
    var fallback := {"center":approximate,"radius":radius,"radii":Vector2(radius,radius),"fitted":false}
    var system := Basis(Vector3(uu,uv,u),Vector3(uv,vv,v),Vector3(u,v,count))
    if count<8.0 or absf(system.determinant())<0.00000001: return fallback
    var coefficients := system.inverse()*rhs
    var offset := Vector2(-coefficients.x*0.5,-coefficients.y*0.5)
    var squared_radius := offset.length_squared()-coefficients.z
    if squared_radius<=0.0: return fallback
    var fitted_radius := sqrt(squared_radius)
    var radii := Vector2(fitted_radius*visual_scale.y,fitted_radius*visual_scale.z)
    var center_delta := Vector3(0,offset.y*visual_scale.y,offset.x*visual_scale.z)
    if radii.x<radius*0.65 or radii.x>radius*1.5 or radii.y<radius*0.65 or radii.y>radius*1.5 or absf(center_delta.z)>radius*0.6 or absf(center_delta.y)>radius*0.6:
        return fallback
    return {"center":approximate+center_delta,"radius":radii.x,"radii":radii,"fitted":true}

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
    var segmentation := str(profile.get("wheel_segmentation","color"))
    var cache_key := [path,size_value,float(radius_value),float(wheelbase_value),segmentation]
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
    var contours: Array = []
    for wheel in range(4):
        contours.append(_wheel_contour(transformed,centers[wheel],radius,size.x,scale) if segmentation=="contour" else {"center":centers[wheel],"radius":radius,"radii":Vector2(radius,radius),"fitted":false})
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
            var candidate := wheel_surface and Vector2(delta.y,delta.z).length()<radius*1.15
            if segmentation=="contour":
                var contour: Dictionary = contours[wheel]
                var offset: Vector3 = midpoint-contour.center
                var radial := Vector2(offset.y/contour.radii.x,offset.z/contour.radii.y).length()
                # Bright wheel centers belong to the wheel too. Color alone
                # cannot distinguish a white hubcap from white paint, or black
                # rubber from a black fender. The fitted circular envelope keeps
                # the upper fender fixed while retaining the hubcap interior.
                # The lower scan contains tread thickness and small contour
                # irregularities. Above the hub the tighter envelope protects
                # the fender lip, particularly on the supplied black car.
                var outer_limit := 1.10 if offset.y<float(contour.radius)*0.10 else 1.01
                candidate = radial<0.80 or (wheel_surface and radial<outer_limit)
                if candidate:
                    for corner in range(3):
                        var edge: Vector3 = transformed[indices[triangle+corner]]-contour.center
                        var corner_limit := 1.15 if edge.y<0.0 else 1.08
                        if Vector2(edge.y/contour.radii.x,edge.z/contour.radii.y).length()>corner_limit:
                            candidate = false
                            break
            if candidate and absf(midpoint.x)>size.x*0.31 and signf(midpoint.x)==signf(centers[wheel].x):
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
    var result := {"meshes":meshes,"centers":centers,"triangle_counts":counts,"source_triangles":int(indices.size()/3),"size":size,"material_mode":"baked_lit" if material!=source_material else "source","wheel_segmentation":segmentation,"contours":contours}
    cache[cache_key] = result
    return result
