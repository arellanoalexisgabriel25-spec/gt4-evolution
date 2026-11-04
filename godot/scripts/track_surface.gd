extends RefCounted

# Original dry-surface approximations. The same dimensions build the visible
# strip and classify actual wheel ray hits; these are not surveyed Gálvez data.
const ROAD_HALF_WIDTH := 8.5
const APRON_HALF_WIDTH := 9.5
const GRAVEL_HALF_WIDTH := 12.5
const START_Z := 65.0
const END_Z := -715.0
const LENGTH := START_Z-END_Z
const CENTER_Z := (START_Z+END_Z)*0.5
const PROFILES := {
    "asphalt":{"id":"asphalt","label":"ASFALTO","grip":1.0,"rolling":1.0},
    "apron":{"id":"apron","label":"BANQUINA PAVIMENTADA","grip":0.85,"rolling":1.15},
    "gravel":{"id":"gravel","label":"TIERRA","grip":0.52,"rolling":3.0},
    "grass":{"id":"grass","label":"PASTO","grip":0.38,"rolling":4.0},
}

static func at(point: Vector3) -> Dictionary:
    if not point.is_finite(): return {}
    if point.z>=END_Z and point.z<=START_Z:
        var x := absf(point.x)
        if x<=ROAD_HALF_WIDTH: return PROFILES.asphalt.duplicate()
        if x<=APRON_HALF_WIDTH: return PROFILES.apron.duplicate()
        if x<=GRAVEL_HALF_WIDTH: return PROFILES.gravel.duplicate()
    return PROFILES.grass.duplicate()

# Samples are front left/right, rear left/right; an empty dictionary means no
# physical support. Average only supported tires, then scale normal force by
# their support fraction. Never move a missing tire's weight onto the other axle.
static func combine(samples: Array) -> Dictionary:
    var loads := Vector2.ZERO
    var grip := Vector2.ZERO
    var rolling := 0.0
    var wheels := 0
    var names: Array[String] = []
    if samples.size()!=4: return {}
    for index in range(4):
        var sample = samples[index]
        if not sample is Dictionary: return {}
        if sample.is_empty(): continue
        if not PROFILES.has(str(sample.get("id",""))): return {}
        var profile: Dictionary = PROFILES[str(sample.id)]
        var axle := 0 if index<2 else 1
        loads[axle] += 0.5
        grip[axle] += float(profile.grip)
        rolling += float(profile.rolling)*0.25
        wheels += 1
        if not names.has(str(profile.label)): names.append(str(profile.label))
    for axle in range(2):
        grip[axle] = grip[axle]/(loads[axle]*2.0) if loads[axle]>0.0 else 0.0
    return {"contact":loads,"grip":grip,"rolling":rolling,"wheels_on_ground":wheels,"label":" / ".join(names) if wheels>0 else "SIN APOYO"}
