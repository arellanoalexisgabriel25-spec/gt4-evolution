extends RefCounted

# Every render vertex assigned to a rotating wheel must remain within the
# wheel's fitted/configured ellipse. Otherwise a long fender triangle can
# rotate outside the rim and tear the body in motion.
static func within_envelope(mesh: ArrayMesh, contour: Dictionary) -> bool:
    var radii: Vector2 = contour.radii
    if radii.x<=0.0 or radii.y<=0.0: return false
    var arrays: Array = mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    if vertices.is_empty(): return false
    for point in vertices:
        if Vector2(point.y/radii.x,point.z/radii.y).length()>1.01:
            return false
    return true
