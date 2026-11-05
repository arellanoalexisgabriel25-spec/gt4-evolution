extends RefCounted

# One authoring definition per new car. Visual measurements, prices and missing
# mechanical parameters are development estimates; references remain separate.
const TorqueData = preload("res://scripts/engine_torque.gd")
const ReferenceData = preload("res://scripts/technical_reference_data.gd")
const MODELS := ["Fiat 125","Fiat Duna","Fiat Cronos","Fiat Siena","Fiat Punto","Fiat Regatta","Fiat 500 Sport"]
const DATA := {
    "Fiat 125": {
        "key":"fiat_125", "price":4400, "mass":1020.0, "torque":126.0,
        "redline":6500.0, "wheelbase":2.505, "radius":0.292,
        "gears":[3.75,2.3,1.49,1.0,0.86], "final_drive":4.1, "drivetrain":"RWD", "front_weight_bias":0.54,
        "size":Vector3(1.61, 1.44, 4.23), "paint":Color("45779c"),
        "asset":"res://assets/cars/fiat_125/fiat_125.glb", "wheel_segmentation":"configured_clip",
        # Render-only envelopes; the mechanical wheel radius and wheelbase remain independent.
        "visual_wheels":[
            {"center":Vector3(-0.6762,-0.23,-1.38),"radii":Vector2(0.27,0.305)},
            {"center":Vector3(-0.6762,-0.23,1.13),"radii":Vector2(0.27,0.305)},
            {"center":Vector3(0.6762,-0.23,-1.38),"radii":Vector2(0.27,0.305)},
            {"center":Vector3(0.6762,-0.23,1.13),"radii":Vector2(0.27,0.305)},
        ],
        "power_cv":90.0, "power_rpm":6000.0, "torque_peak_rpm":4000.0,
        "variant":"1.6 Twin Cam · guía aportada; año por confirmar", "source_page":1, "power_reference":true,
        "engine_position":"front", "factory_abs":false, "turbo_fraction":0.0
    },
    "Fiat Duna": {
        "key":"fiat_duna", "price":4700, "mass":980.0, "torque":128.0,
        "redline":5200.0, "wheelbase":2.36, "radius":0.28,
        "gears":[3.91,2.24,1.47,1.04,0.86], "final_drive":3.56, "drivetrain":"FWD", "front_weight_bias":0.63,
        "size":Vector3(1.64, 1.43, 4.04), "paint":Color("b8babc"),
        "asset":"res://assets/cars/fiat_duna/fiat_duna.glb", "wheel_segmentation":"configured_clip",
        # Render-only envelopes; the mechanical wheel radius and wheelbase remain independent.
        "visual_wheels":[
            {"center":Vector3(-0.6888,-0.225,-1.305),"radii":Vector2(0.27,0.295)},
            {"center":Vector3(-0.6888,-0.225,1.075),"radii":Vector2(0.27,0.295)},
            {"center":Vector3(0.6888,-0.225,-1.305),"radii":Vector2(0.27,0.295)},
            {"center":Vector3(0.6888,-0.225,1.075),"radii":Vector2(0.27,0.295)},
        ],
        "power_cv":72.0, "power_rpm":4500.0, "torque_peak_rpm":2600.0,
        "variant":"1.7 diésel · referencia de guía; versión por verificar", "source_page":6, "power_reference":true,
        "engine_position":"front", "factory_abs":false, "turbo_fraction":0.0
    },
    "Fiat Cronos": {
        "key":"fiat_cronos", "price":10400, "mass":1240.0, "torque":182.0,
        "redline":6500.0, "wheelbase":2.521, "radius":0.31,
        "gears":[4.27,2.35,1.52,1.12,0.87], "final_drive":3.73, "drivetrain":"FWD", "front_weight_bias":0.6,
        "size":Vector3(1.724, 1.508, 4.364), "paint":Color("c52c34"),
        "asset":"res://assets/cars/fiat_cronos/fiat_cronos.glb", "wheel_segmentation":"configured_clip",
        # Render-only envelopes; the mechanical wheel radius and wheelbase remain independent.
        "visual_wheels":[
            {"center":Vector3(-0.72408,-0.22,-1.3),"radii":Vector2(0.225,0.275)},
            {"center":Vector3(-0.72408,-0.22,1.25),"radii":Vector2(0.225,0.275)},
            {"center":Vector3(0.72408,-0.22,-1.3),"radii":Vector2(0.225,0.275)},
            {"center":Vector3(0.72408,-0.22,1.25),"radii":Vector2(0.225,0.275)},
        ],
        "power_cv":130.0, "power_rpm":5500.0, "torque_peak_rpm":4000.0,
        "variant":"1.8 · guía aportada; año y equipamiento por confirmar", "source_page":5, "power_reference":true,
        "engine_position":"front", "factory_abs":true, "turbo_fraction":0.0
    },
    "Fiat Siena": {
        "key":"fiat_siena", "price":6400, "mass":1050.0, "torque":167.0,
        "redline":6500.0, "wheelbase":2.373, "radius":0.29,
        "gears":[3.91,2.24,1.47,1.04,0.86], "final_drive":3.56, "drivetrain":"FWD", "front_weight_bias":0.61,
        "size":Vector3(1.64, 1.45, 4.17), "paint":Color("afada5"),
        "asset":"res://assets/cars/fiat_siena/fiat_siena.glb", "wheel_segmentation":"configured_clip",
        # Render-only envelopes; the mechanical wheel radius and wheelbase remain independent.
        "visual_wheels":[
            {"center":Vector3(-0.6888,-0.245,-1.26),"radii":Vector2(0.26,0.29)},
            {"center":Vector3(-0.6888,-0.245,1.12),"radii":Vector2(0.26,0.29)},
            {"center":Vector3(0.6888,-0.245,-1.26),"radii":Vector2(0.26,0.29)},
            {"center":Vector3(0.6888,-0.245,1.12),"radii":Vector2(0.26,0.29)},
        ],
        "power_cv":103.0, "power_rpm":5500.0, "torque_peak_rpm":3000.0,
        "variant":"1.8 · referencia 2007; variante por verificar", "source_page":6, "power_reference":true,
        "engine_position":"front", "factory_abs":false, "turbo_fraction":0.0
    },
    "Fiat Punto": {
        "key":"fiat_punto", "price":7600, "mass":1080.0, "torque":123.0,
        "redline":6500.0, "wheelbase":2.51, "radius":0.3,
        "gears":[3.91,2.16,1.48,1.12,0.9], "final_drive":4.07, "drivetrain":"FWD", "front_weight_bias":0.62,
        "size":Vector3(1.687, 1.49, 4.03), "paint":Color("e0e0de"),
        "asset":"res://assets/cars/fiat_punto/fiat_punto.glb", "wheel_segmentation":"configured_clip",
        # Render-only envelopes; the mechanical wheel radius and wheelbase remain independent.
        "visual_wheels":[
            {"center":Vector3(-0.70854,-0.235,-1.14),"radii":Vector2(0.265,0.316)},
            {"center":Vector3(-0.70854,-0.235,1.39),"radii":Vector2(0.265,0.316)},
            {"center":Vector3(0.70854,-0.235,-1.14),"radii":Vector2(0.265,0.316)},
            {"center":Vector3(0.70854,-0.235,1.39),"radii":Vector2(0.265,0.316)},
        ],
        "power_cv":87.0, "power_rpm":5750.0, "torque_peak_rpm":3500.0,
        "variant":"1.4 Fire · estimación para la carrocería regional aportada", "source_page":8, "power_reference":false,
        "engine_position":"front", "factory_abs":false, "turbo_fraction":0.0
    },
    "Fiat Regatta": {
        "key":"fiat_regatta", "price":5000, "mass":1000.0, "torque":142.0,
        "redline":6500.0, "wheelbase":2.448, "radius":0.285,
        "gears":[3.58,2.24,1.45,1.04,0.86], "final_drive":3.765, "drivetrain":"FWD", "front_weight_bias":0.6,
        "size":Vector3(1.65, 1.42, 4.26), "paint":Color("b8ac94"),
        "asset":"res://assets/cars/fiat_regatta/fiat_regatta.glb", "wheel_segmentation":"configured_clip",
        # Render-only envelopes; the mechanical wheel radius and wheelbase remain independent.
        "visual_wheels":[
            {"center":Vector3(-0.693,-0.22,-1.332),"radii":Vector2(0.282,0.318)},
            {"center":Vector3(-0.693,-0.22,1.194),"radii":Vector2(0.282,0.318)},
            {"center":Vector3(0.693,-0.22,-1.332),"radii":Vector2(0.282,0.318)},
            {"center":Vector3(0.693,-0.22,1.194),"radii":Vector2(0.282,0.318)},
        ],
        "power_cv":100.0, "power_rpm":5800.0, "torque_peak_rpm":3200.0,
        "variant":"1.6 · guía aportada; año y versión por confirmar", "source_page":7, "power_reference":true,
        "engine_position":"front", "factory_abs":false, "turbo_fraction":0.0
    },
    "Fiat 500 Sport": {
        "key":"fiat_500", "price":10800, "mass":1015.0, "torque":128.467115,
        "redline":6500.0, "wheelbase":2.3, "radius":0.295,
        "gears":[3.909,2.158,1.48,1.121,0.897,0.744], "final_drive":3.35, "drivetrain":"FWD", "front_weight_bias":0.64,
        "size":Vector3(1.627, 1.488, 3.657), "paint":Color("d8d5c8"),
        "asset":"res://assets/cars/fiat_500/fiat_500.glb", "wheel_segmentation":"configured_clip",
        # Render-only envelopes; the mechanical wheel radius and wheelbase remain independent.
        "visual_wheels":[
            {"center":Vector3(-0.68334,-0.155,-1.06),"radii":Vector2(0.345,0.341)},
            {"center":Vector3(-0.68334,-0.155,1.235),"radii":Vector2(0.345,0.341)},
            {"center":Vector3(0.68334,-0.155,-1.06),"radii":Vector2(0.345,0.341)},
            {"center":Vector3(0.68334,-0.155,1.235),"radii":Vector2(0.345,0.341)},
        ],
        "power_cv":100.0, "power_rpm":6000.0, "torque_peak_rpm":4250.0,
        "variant":"Sport 1.4 16V · referencia 2021; carrocería Abarth provisional", "source_page":4, "power_reference":true,
        "engine_position":"front", "factory_abs":true, "turbo_fraction":0.0
    },
}

static func profile(model: String) -> Dictionary:
    if not DATA.has(model): return {}
    var data: Dictionary = DATA[model]
    var power_rpm := float(data.power_rpm)
    var torque_rpm := float(data.torque_peak_rpm)
    var anchor := TorqueData.torque_for_cv_at_rpm(float(data.power_cv),power_rpm)/float(data.torque)
    var between := (torque_rpm+power_rpm)*0.5
    var sources: Array = []
    var targets: Dictionary = {}
    if data.power_reference:
        sources.append(ReferenceData.fiat_source(int(data.source_page)))
        targets["power_cv"] = float(data.power_cv)
    var estimated := ["curb_mass_kg","peak_torque_nm","power_rpm","torque_peak_rpm","gear_ratios","final_drive","drag_area_m2","curve_interpolation","dimensions","rolling_radius_m"]
    if not data.power_reference: estimated.append("power_cv")
    if model=="Fiat 125":
        targets["curb_mass_kg"] = 1020.0
        estimated.erase("curb_mass_kg")
    if model=="Fiat 500 Sport":
        for field in ["peak_torque_nm","power_rpm","torque_peak_rpm"]: estimated.erase(field)
        targets.merge({"power_rpm":6000.0,"torque_kgfm":13.1,"torque_rpm":4250.0,"zero_to_hundred_s":10.5,"top_speed_kmh":182.0})
    return {
        "id":str(data.key)+"_development_019", "variant":str(data.variant),
        "status":"development_estimate", "sources":sources,
        "basis":"Separate supplied guide claims from estimated geometry, engine curve, mass and gearing",
        "curb_mass_kg":float(data.mass), "peak_torque_nm":float(data.torque),
        "redline_rpm":float(data.redline), "wheelbase_m":float(data.wheelbase),
        "rolling_radius_m":float(data.radius), "gear_ratios":data.gears.duplicate(),
        "final_drive":float(data.final_drive), "drivetrain":str(data.drivetrain),
        "front_weight_bias":float(data.front_weight_bias), "drag_area_m2":0.68,
        "engine_position":str(data.engine_position), "factory_abs":bool(data.factory_abs),
        "turbo_fraction":float(data.turbo_fraction),
        "torque_rpm":[900.0,1500.0,torque_rpm,between,power_rpm,float(data.redline)],
        "torque_factors":[0.62,0.78,1.0,(1.0+anchor)*0.5,anchor,0.60],
        "reference_targets":targets,
        "estimated_fields":estimated,
    }
