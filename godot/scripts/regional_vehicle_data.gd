extends RefCounted

# Body identification comes from inspecting the supplied meshes. Engine choices
# are explicit development variants, not identification by a badge or body scan.
const Torque = preload("res://scripts/engine_torque.gd")
const ReferenceData = preload("res://scripts/technical_reference_data.gd")
const MODELS := ["Chevrolet Corsa 5 puertas","Volkswagen Amarok","Ford Ranger cabina simple","Ford EcoSport","Toyota Corolla","Fiat Palio 5 puertas"]
const DATA := {
    "Chevrolet Corsa 5 puertas": {
        "key":"corsa", "price":5400, "mass":1005.0, "torque":138.0,
        "redline":6500.0, "wheelbase":2.443, "radius":0.287,
        "gears":[3.73,2.14,1.41,1.12,0.89], "final_drive":3.74,
        "drivetrain":"FWD", "front_weight_bias":0.62, "cg_height":0.49, "drag_area":0.67,
        "size":Vector3(1.608,1.42,3.729), "paint":Color("e9e9e3"),
        "asset":"res://assets/cars/corsa/corsa.glb", "wheel_segmentation":"configured_clip",
        # Render envelopes estimated from the supplied scan, separate from mechanics.
        "visual_wheels":[
            {"center":Vector3(-0.67536,-0.22,-1.13),"radii":Vector2(0.275,0.3)},
            {"center":Vector3(-0.67536,-0.22,1.22),"radii":Vector2(0.275,0.3)},
            {"center":Vector3(0.67536,-0.22,-1.13),"radii":Vector2(0.275,0.3)},
            {"center":Vector3(0.67536,-0.22,1.22),"radii":Vector2(0.275,0.3)},
        ],
        "power_cv":92.0, "power_rpm":5600.0, "torque_rpm":2800.0,
        "variant":"Hatch 5p · 1.6 MPFI 8V · provisional", "source_page":2,
        "power_reference":true, "reference_torque_nm":138.0, "factory_abs":false
    },
    "Volkswagen Amarok": {
        "key":"amarok", "price":11200, "mass":1857.0, "torque":340.0,
        "redline":4700.0, "wheelbase":3.095, "radius":0.365,
        "gears":[4.81,2.54,1.5,1.0,0.76,0.63], "final_drive":4.1,
        "drivetrain":"RWD", "front_weight_bias":0.55, "cg_height":0.75, "drag_area":1.06,
        "size":Vector3(1.954,1.834,5.254), "paint":Color("1a344f"),
        "asset":"res://assets/cars/amarok/amarok.glb", "wheel_segmentation":"configured_clip",
        # Render envelopes estimated from the supplied scan, separate from mechanics.
        "visual_wheels":[
            {"center":Vector3(-0.82068,-0.155,-1.62),"radii":Vector2(0.345,0.355)},
            {"center":Vector3(-0.82068,-0.155,1.5),"radii":Vector2(0.345,0.355)},
            {"center":Vector3(0.82068,-0.155,-1.62),"radii":Vector2(0.345,0.355)},
            {"center":Vector3(0.82068,-0.155,1.5),"radii":Vector2(0.345,0.355)},
        ],
        "power_cv":140.0, "power_rpm":4000.0, "torque_rpm":1750.0,
        "variant":"2.0 TDI 140 · MT6 · 4×2 · carrocería y versión provisionales", "source_page":2,
        "power_reference":true, "reference_torque_nm":340.0, "factory_abs":true, "turbo_fraction":0.55,
        "idle_rpm":800.0, "spool_rpm":1000.0, "boost_span_rpm":650.0,
        "engine_inertia":0.38, "wheel_inertia":6.5
    },
    "Ford Ranger cabina simple": {
        "key":"ranger", "price":9900, "mass":1690.0, "torque":380.0,
        "redline":4400.0, "wheelbase":2.985, "radius":0.36,
        "gears":[4.08,2.29,1.47,1.0,0.72], "final_drive":3.73,
        "drivetrain":"RWD", "front_weight_bias":0.56, "cg_height":0.72, "drag_area":1.04,
        "size":Vector3(1.805,1.75,5.075), "paint":Color("d7d9d5"),
        "asset":"res://assets/cars/ranger/ranger.glb", "wheel_segmentation":"configured_clip",
        # Render envelopes estimated from the supplied scan, separate from mechanics.
        "visual_wheels":[
            {"center":Vector3(-0.7581,-0.15,-1.54),"radii":Vector2(0.35,0.373)},
            {"center":Vector3(-0.7581,-0.15,1.41),"radii":Vector2(0.35,0.373)},
            {"center":Vector3(0.7581,-0.15,-1.54),"radii":Vector2(0.35,0.373)},
            {"center":Vector3(0.7581,-0.15,1.41),"radii":Vector2(0.35,0.373)},
        ],
        "power_cv":163.0, "power_rpm":3800.0, "torque_rpm":1750.0,
        "variant":"Cabina simple · 3.0 PowerStroke · MT5 · 4×2 · provisional", "source_page":4,
        "power_reference":true, "factory_abs":false, "turbo_fraction":0.55,
        "idle_rpm":800.0, "spool_rpm":1000.0, "boost_span_rpm":650.0,
        "engine_inertia":0.42, "wheel_inertia":6.2
    },
    "Ford EcoSport": {
        "key":"ecosport", "price":8200, "mass":1220.0, "torque":150.0,
        "redline":6500.0, "wheelbase":2.49, "radius":0.316,
        "gears":[3.85,2.04,1.28,0.95,0.76], "final_drive":4.56,
        "drivetrain":"FWD", "front_weight_bias":0.61, "cg_height":0.66, "drag_area":0.92,
        "size":Vector3(1.737,1.66,4.245), "paint":Color("20292c"),
        "asset":"res://assets/cars/ecosport/ecosport.glb", "wheel_segmentation":"configured_clip",
        # Render envelopes estimated from the supplied scan, separate from mechanics.
        "visual_wheels":[
            {"center":Vector3(-0.72954,-0.2,-1.35),"radii":Vector2(0.3,0.33)},
            {"center":Vector3(-0.72954,-0.2,1.215),"radii":Vector2(0.3,0.33)},
            {"center":Vector3(0.72954,-0.2,-1.35),"radii":Vector2(0.3,0.33)},
            {"center":Vector3(0.72954,-0.2,1.215),"radii":Vector2(0.3,0.33)},
        ],
        "power_cv":99.0, "power_rpm":5500.0, "torque_rpm":4250.0,
        "variant":"1.6 Rocam 8V · MT5 · 4×2 · provisional", "source_page":4,
        "power_reference":true, "reference_torque_nm":150.0, "factory_abs":false
    },
    "Toyota Corolla": {
        "key":"corolla", "price":9700, "mass":1130.0, "torque":150.0,
        "redline":6500.0, "wheelbase":2.60, "radius":0.305,
        "gears":[3.17,1.9,1.31,0.97,0.82], "final_drive":4.31,
        "drivetrain":"FWD", "front_weight_bias":0.60, "cg_height":0.51, "drag_area":0.61,
        "size":Vector3(1.705,1.48,4.53), "paint":Color("c4c2b2"),
        "asset":"res://assets/cars/corolla/corolla.glb", "wheel_segmentation":"configured_clip",
        # Render envelopes estimated from the supplied scan, separate from mechanics.
        "visual_wheels":[
            {"center":Vector3(-0.7161,-0.198,-1.295),"radii":Vector2(0.302,0.31)},
            {"center":Vector3(-0.7161,-0.198,1.28),"radii":Vector2(0.302,0.31)},
            {"center":Vector3(0.7161,-0.198,-1.295),"radii":Vector2(0.302,0.31)},
            {"center":Vector3(0.7161,-0.198,1.28),"radii":Vector2(0.302,0.31)},
        ],
        "power_cv":110.0, "power_rpm":6000.0, "torque_rpm":4800.0,
        "variant":"XLi 1.6 VVT-i · MT5 · generación y ficha por confirmar", "source_page":3,
        "power_reference":true, "factory_abs":false
    },
    "Fiat Palio 5 puertas": {
        "key":"palio", "price":5100, "mass":955.0, "torque":115.0,
        "redline":6200.0, "wheelbase":2.373, "radius":0.285,
        "gears":[3.91,2.16,1.48,1.12,0.9], "final_drive":3.73,
        "drivetrain":"FWD", "front_weight_bias":0.62, "cg_height":0.49, "drag_area":0.68,
        "size":Vector3(1.62,1.445,3.735), "paint":Color("5c697c"),
        "asset":"res://assets/cars/palio/palio.glb", "wheel_segmentation":"configured_clip",
        # Render envelopes estimated from the supplied scan, separate from mechanics.
        "visual_wheels":[
            {"center":Vector3(-0.6804,-0.23,-1.074),"radii":Vector2(0.27,0.28)},
            {"center":Vector3(-0.6804,-0.23,1.18),"radii":Vector2(0.27,0.28)},
            {"center":Vector3(0.6804,-0.23,-1.074),"radii":Vector2(0.27,0.28)},
            {"center":Vector3(0.6804,-0.23,1.18),"radii":Vector2(0.27,0.28)},
        ],
        "power_cv":72.0, "power_rpm":5000.0, "torque_rpm":3000.0,
        "variant":"Hatch 5p · 1.3 MPI 8V estimado · ficha pendiente", "source_page":0,
        "power_reference":false, "factory_abs":false
    },
}

static func profile(model: String) -> Dictionary:
    if not DATA.has(model): return {}
    var data: Dictionary = DATA[model]
    return profile_data(data)

static func profile_data(data: Dictionary) -> Dictionary:
    var peak_rpm := float(data.power_rpm)
    var torque_rpm := float(data.torque_rpm)
    var anchor := Torque.torque_for_cv_at_rpm(float(data.power_cv),peak_rpm)/float(data.torque)
    var diesel: bool = data.get("turbo_fraction",0.0)>0.0
    var sources: Array = []
    if data.power_reference:
        sources.append(ReferenceData.compilation_source(int(data.source_page)))
    var targets: Dictionary = {"power_cv":float(data.power_cv)} if data.power_reference else {}
    # A numeric engine claim does not identify the scanned body/year/trim.
    # Keep variant_mapping estimated even when the reported peak is present.
    if data.has("reference_torque_nm"): targets["torque_nm"] = float(data.reference_torque_nm)
    var estimated := ["variant_mapping","curb_mass_kg","peak_torque_nm","power_rpm","torque_peak_rpm","gear_ratios","final_drive","drag_area_m2","curve_interpolation","dimensions","rolling_radius_m","cg_height_m","front_weight_bias","turbo_response","factory_abs","engine_inertia","wheel_inertia"]+([] if data.power_reference else ["power_cv"])
    if targets.has("torque_nm"): estimated.erase("peak_torque_nm")
    return {
        "id":str(data.key)+"_development_"+str(data.get("catalog_revision","022")), "record_revision":str(data.key)+"_factory_"+str(data.get("catalog_revision","022")), "variant":str(data.variant),
        "status":"development_estimate", "sources":sources,
        "basis":"Inspected supplied body; explicit provisional factory engine choice; no verified homologation",
        "curb_mass_kg":float(data.mass), "peak_torque_nm":float(data.torque),
        "redline_rpm":float(data.redline), "wheelbase_m":float(data.wheelbase),
        "rolling_radius_m":float(data.radius), "gear_ratios":data.gears.duplicate(),
        "final_drive":float(data.final_drive), "drivetrain":str(data.drivetrain),
        "front_weight_bias":float(data.front_weight_bias), "drag_area_m2":float(data.drag_area),
        "cg_height_m":float(data.cg_height), "engine_position":"front",
        "transmission_type":str(data.get("transmission_type","manual")),
        "factory_abs":bool(data.factory_abs), "turbo_fraction":float(data.get("turbo_fraction",0.0)),
        "idle_rpm":float(data.get("idle_rpm",900.0)), "spool_rpm":float(data.get("spool_rpm",2500.0)),
        "boost_span_rpm":float(data.get("boost_span_rpm",1400.0)),
        "engine_inertia":float(data.get("engine_inertia",0.26)), "wheel_inertia":float(data.get("wheel_inertia",3.2)),
        "torque_rpm":[800.0 if diesel else 900.0,1200.0 if diesel else 1500.0,torque_rpm,peak_rpm,float(data.redline)],
        "torque_factors":[0.55,0.76,1.0,anchor,0.32 if diesel else 0.55],
        "reference_targets":targets,
        "estimated_fields":estimated
    }
