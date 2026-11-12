extends RefCounted

# The supplied GLB has a single static mesh. Partition its triangles into body
# and wheel regions without changing the source file or losing UVs/materials.
# Configured wheel envelopes are visual estimates for the scanned body. Only
# their crossing triangles are clipped, keeping UVs continuous and the fender fixed.
# Source and subdivided render face counts are reported separately.
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

static func _visual_vertex(index: int, positions: PackedVector3Array, normals: PackedVector3Array, uv: PackedVector2Array, normal_basis: Basis) -> Array:
    return [positions[index],(normal_basis*normals[index]).normalized() if normals.size()==positions.size() else Vector3.UP,uv[index] if uv.size()==positions.size() else Vector2.ZERO]

static func _interpolate_visual(a: Array, b: Array, weight: float) -> Array:
    return [a[0].lerp(b[0],weight),a[1].lerp(b[1],weight),a[2].lerp(b[2],weight)]

# Split a convex polygon across a plane. Both pieces preserve original winding
# and interpolate UV/normals at the same cut, avoiding holes from whole-face masks.
static func _split_visual_polygon(polygon: Array, normal: Vector3, distance: float) -> Array:
    var inside: Array = []
    var outside: Array = []
    var previous: Array = polygon[-1]
    var previous_distance: float = normal.dot(previous[0])-distance
    for current in polygon:
        var current_distance: float = normal.dot(current[0])-distance
        var previous_inside := previous_distance>=0.0
        var current_inside := current_distance>=0.0
        if previous_inside!=current_inside:
            var weight := previous_distance/(previous_distance-current_distance)
            var crossing := _interpolate_visual(previous,current,weight)
            inside.append(crossing)
            outside.append(crossing)
        if current_inside: inside.append(current)
        else: outside.append(current)
        previous=current
        previous_distance=current_distance
    return [inside,outside]

static func _triangulate_visual(polygon: Array, target: Array) -> void:
    if polygon.size()<3: return
    for index in range(1,polygon.size()-1):
        var a: Vector3 = polygon[index][0]-polygon[0][0]
        var b: Vector3 = polygon[index+1][0]-polygon[0][0]
        if a.cross(b).length_squared()<1e-18: continue
        target.append_array([polygon[0],polygon[index],polygon[index+1]])

static func _visual_wheel_candidates(a: Vector3, b: Vector3, c: Vector3, contours: Array, width: float) -> Array[int]:
    var minimum := a.min(b).min(c)
    var maximum := a.max(b).max(c)
    var result: Array[int] = []
    for wheel in range(contours.size()):
        var contour: Dictionary = contours[wheel]
        var center: Vector3 = contour.center
        var radii: Vector2 = contour.radii
        if maximum.y<center.y-radii.x or minimum.y>center.y+radii.x or maximum.z<center.z-radii.y or minimum.z>center.z+radii.y:
            continue
        if (maximum.x if center.x>0.0 else -minimum.x)<width*0.31: continue
        result.append(wheel)
    return result

static func _inside_visual_wheel(point: Vector3, contour: Dictionary, width: float) -> bool:
    var offset: Vector3 = point-contour.center
    return point.x*signf(contour.center.x)>=width*0.31 and Vector2(offset.y/contour.radii.x,offset.z/contour.radii.y).length_squared()<=1.0

static func _clip_visual_wheel(triangle: Array, contour: Dictionary, width: float) -> Dictionary:
    var center: Vector3 = contour.center
    var radii: Vector2 = contour.radii
    var side := signf(center.x)
    var min_y := minf(triangle[0][0].y,minf(triangle[1][0].y,triangle[2][0].y))
    var max_y := maxf(triangle[0][0].y,maxf(triangle[1][0].y,triangle[2][0].y))
    var min_z := minf(triangle[0][0].z,minf(triangle[1][0].z,triangle[2][0].z))
    var max_z := maxf(triangle[0][0].z,maxf(triangle[1][0].z,triangle[2][0].z))
    if max_y<center.y-radii.x or min_y>center.y+radii.x or max_z<center.z-radii.y or min_z>center.z+radii.y:
        return {}
    var max_x := maxf(triangle[0][0].x*side,maxf(triangle[1][0].x*side,triangle[2][0].x*side))
    if max_x<width*0.31: return {}
    var inside: Array = triangle
    var outside: Array = []
    for plane in contour.planes:
        var pieces := _split_visual_polygon(inside,plane.normal,plane.d)
        inside=pieces[0]
        if pieces[1].size()>=3: outside.append(pieces[1])
        if inside.size()<3: return {}
    return {"inside":inside,"outside":outside}

static func _render_material(source: Material) -> Material:
    if not source is BaseMaterial3D:
        return source
    var baked: bool = source.albedo_texture==null and source.emission_enabled and source.emission_texture!=null
    var textured: bool = source.albedo_texture!=null or source.normal_texture!=null or baked
    if not textured:
        return source
    # Work on a copy: scene-specific filtering and baked scan conversion must
    # never modify a shared imported GLB material or its original textures.
    var material: BaseMaterial3D = source.duplicate()
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    if baked:
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
    var configured: Array = profile.get("visual_wheels",[]) if segmentation=="configured_clip" else []
    if segmentation=="configured_clip" and configured.size()!=4: return {}
    var cache_key := [path,size_value,float(radius_value),float(wheelbase_value),segmentation,configured.duplicate(true)]
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
        # Fit the tire arc even for legacy color-segmented scans. An approximate
        # catalog wheelbase alone is not a reliable rotation center.
        var contour: Dictionary = _wheel_contour(transformed,centers[wheel],radius,size.x,scale) if configured.is_empty() else {"center":centers[wheel],"radius":radius,"radii":Vector2(radius,radius),"fitted":false}
        if configured.is_empty():
            # The lower scan arc can undershoot the tread by a few percent.
            # Keep the complete rubber edge in the rotating mesh while still
            # clipping long body triangles at a bounded elliptical envelope.
            if contour.fitted:
                contour.radii *= 1.06
                contour.radius = contour.radii.x
            centers[wheel]=contour.center
            var planes: Array[Plane] = [Plane(Vector3(signf(contour.center.x),0,0),size.x*0.31)]
            for segment in range(32):
                var angle := TAU*float(segment)/32.0
                var normal := Vector3(0,-cos(angle)/contour.radii.x,-sin(angle)/contour.radii.y)
                planes.append(Plane(normal,normal.dot(contour.center)-1.0))
            contour["planes"]=planes
        contours.append(contour)
    if not configured.is_empty():
        for wheel in range(4):
            var setting = configured[wheel]
            if not setting is Dictionary:
                source.free()
                return {}
            var configured_center = setting.get("center")
            var configured_radii = setting.get("radii")
            if typeof(configured_center)!=TYPE_VECTOR3 or typeof(configured_radii)!=TYPE_VECTOR2:
                source.free()
                return {}
            if not configured_center.is_finite() or not configured_radii.is_finite() or configured_radii.x<=0.0 or configured_radii.y<=0.0:
                source.free()
                return {}
            centers[wheel]=configured_center
            var planes: Array[Plane] = [Plane(Vector3(signf(configured_center.x),0,0),size.x*0.31)]
            for segment in range(32):
                var angle := TAU*float(segment)/32.0
                var normal := Vector3(0,-cos(angle)/configured_radii.x,-sin(angle)/configured_radii.y)
                planes.append(Plane(normal,normal.dot(configured_center)-1.0))
            contours[wheel]={"center":configured_center,"radius":configured_radii.x,"radii":configured_radii,"fitted":false,"configured":true,"planes":planes}
    var groups: Array = [[],[],[],[],[]]
    var clipped: Array = [[],[],[],[],[]]
    var source_material: Material = mesh_node.mesh.surface_get_material(0)
    var baked_source: bool = source_material is BaseMaterial3D and source_material.albedo_texture==null and source_material.emission_enabled and source_material.emission_texture!=null
    var material: Material = _render_material(source_material)
    var diffuse: Image
    if configured.is_empty() and material is BaseMaterial3D and material.albedo_texture!=null:
        diffuse = material.albedo_texture.get_image()
        if diffuse!=null and diffuse.is_compressed():
            diffuse.decompress()
    for triangle in range(0,indices.size(),3):
        if not configured.is_empty():
            var a: Vector3 = transformed[indices[triangle]]
            var b: Vector3 = transformed[indices[triangle+1]]
            var c: Vector3 = transformed[indices[triangle+2]]
            var candidates := _visual_wheel_candidates(a,b,c,contours,size.x)
            var assigned := false
            for wheel in candidates:
                if _inside_visual_wheel(a,contours[wheel],size.x) and _inside_visual_wheel(b,contours[wheel],size.x) and _inside_visual_wheel(c,contours[wheel],size.x):
                    groups[wheel+1].append_array([indices[triangle],indices[triangle+1],indices[triangle+2]])
                    assigned=true
                    break
            if assigned: continue
            if not candidates.is_empty():
                var vertices_of_face: Array = []
                for corner in range(3): vertices_of_face.append(_visual_vertex(indices[triangle+corner],transformed,normals,uv,normal_basis))
                for wheel in candidates:
                    var partition := _clip_visual_wheel(vertices_of_face,contours[wheel],size.x)
                    if partition.is_empty(): continue
                    _triangulate_visual(partition.inside,clipped[wheel+1])
                    for polygon in partition.outside: _triangulate_visual(polygon,clipped[0])
                    assigned=true
                    break
            if not assigned: groups[0].append_array([indices[triangle],indices[triangle+1],indices[triangle+2]])
            continue
        var a: Vector3 = transformed[indices[triangle]]
        var b: Vector3 = transformed[indices[triangle+1]]
        var c: Vector3 = transformed[indices[triangle+2]]
        var midpoint := (a+b+c)/3.0
        var wheel_surface := true
        if diffuse!=null and uv.size()==vertices.size():
            var texcoord := (uv[indices[triangle]]+uv[indices[triangle+1]]+uv[indices[triangle+2]])/3.0
            var color := diffuse.get_pixel(clampi(int(texcoord.x*diffuse.get_width()),0,diffuse.get_width()-1),clampi(int(texcoord.y*diffuse.get_height()),0,diffuse.get_height()-1))
            wheel_surface = color.get_luminance()<0.40 and maxf(color.r,maxf(color.g,color.b))-minf(color.r,minf(color.g,color.b))<0.22
        var assigned := false
        for wheel in _visual_wheel_candidates(a,b,c,contours,size.x):
            var contour: Dictionary = contours[wheel]
            var offset: Vector3 = midpoint-contour.center
            var radial := Vector2(offset.y/contour.radii.x,offset.z/contour.radii.y).length()
            # Preserve bright center caps, but leave light outer fenders fixed.
            if not wheel_surface and radial>=0.50:
                continue
            if _inside_visual_wheel(a,contour,size.x) and _inside_visual_wheel(b,contour,size.x) and _inside_visual_wheel(c,contour,size.x):
                groups[wheel+1].append_array([indices[triangle],indices[triangle+1],indices[triangle+2]])
                assigned=true
                break
            # A whole-face midpoint mask can include vertices far outside the
            # tire and rotate bodywork. Split the face and interpolate UVs and
            # normals so the original static surface remains intact.
            var vertices_of_face: Array = []
            for corner in range(3): vertices_of_face.append(_visual_vertex(indices[triangle+corner],transformed,normals,uv,normal_basis))
            var partition := _clip_visual_wheel(vertices_of_face,contour,size.x)
            if partition.is_empty(): continue
            _triangulate_visual(partition.inside,clipped[wheel+1])
            for polygon in partition.outside: _triangulate_visual(polygon,clipped[0])
            assigned=true
            break
        if not assigned: groups[0].append_array([indices[triangle],indices[triangle+1],indices[triangle+2]])
    for group in range(5):
        if groups[group].is_empty() and clipped[group].is_empty():
            source.free()
            return {}
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
        for vertex in clipped[group]:
            surface.set_normal(Vector3(vertex[1]).normalized())
            surface.set_uv(vertex[2])
            surface.add_vertex(vertex[0]-offset)
        if normals.size()!=vertices.size():
            surface.generate_normals()
        if uv.size()==vertices.size() and material is BaseMaterial3D and material.normal_enabled and material.normal_texture!=null:
            surface.generate_tangents()
        surface.index()
        meshes.append(surface.commit())
        counts.append(int((groups[group].size()+clipped[group].size())/3))
    source.free()
    var result := {"meshes":meshes,"centers":centers,"wheel_scale_yz":Vector2(scale.y,scale.z),"triangle_counts":counts,"source_triangles":int(indices.size()/3),"render_triangles":counts.reduce(func(total,value): return total+value,0),"size":size,"material_mode":"baked_lit" if baked_source else "source","wheel_segmentation":segmentation,"contours":contours}
    cache[cache_key] = result
    return result
