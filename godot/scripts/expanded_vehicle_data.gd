extends RefCounted

# The supplied body never certifies engine/year/gearbox. Missing data remain estimates.
const Regional = preload("res://scripts/regional_vehicle_data.gd")
const MODELS := ["Toyota Yaris Sedán","Ford Ka 3 puertas","Peugeot 208","Volkswagen Polo Classic","Volkswagen Virtus","Chevrolet Onix","Toyota Corolla Cross"]
const DATA := {
    "Toyota Yaris Sedán": {
        "key":"yaris", "catalog_revision":"023", "price":10500, "mass":1050.0, "torque":141.0,
        "redline":6500.0, "wheelbase":2.55, "radius":0.3, "gears":[3.545, 1.904, 1.31, 0.969, 0.815], "final_drive":4.312,
        "drivetrain":"FWD", "front_weight_bias":0.61, "cg_height":0.51, "drag_area":0.64,
        "size":Vector3(1.7,1.46,4.3), "paint":Color("bdc3c8"),
        "asset":"res://assets/cars/yaris/yaris.glb", "wheel_segmentation":"configured_clip",
        "visual_wheels":[
            {"center":Vector3(-0.714,-0.194,-1.349),"radii":Vector2(0.306,0.307)},
            {"center":Vector3(-0.714,-0.211,1.2),"radii":Vector2(0.287,0.288)},
            {"center":Vector3(0.714,-0.194,-1.349),"radii":Vector2(0.306,0.307)},
            {"center":Vector3(0.714,-0.211,1.2),"radii":Vector2(0.287,0.288)},
        ],
        "power_cv":106.0, "power_rpm":6000.0, "torque_rpm":4200.0,
        "variant":"Sedán 1.5 VVT-i · generación del escaneo y ficha provisionales", "source_page":0, "power_reference":false, "factory_abs":true,
    },
    "Ford Ka 3 puertas": {
        "key":"ka", "catalog_revision":"023", "price":4200, "mass":930.0, "torque":104.0,
        "redline":6000.0, "wheelbase":2.45, "radius":0.28, "gears":[3.58, 1.93, 1.28, 0.95, 0.76], "final_drive":4.06,
        "drivetrain":"FWD", "front_weight_bias":0.61, "cg_height":0.48, "drag_area":0.66,
        "size":Vector3(1.631,1.368,3.62), "paint":Color("bdc3c8"),
        "asset":"res://assets/cars/ka/ka.glb", "wheel_segmentation":"configured_clip",
        "visual_wheels":[
            {"center":Vector3(-0.68502,-0.252,-1.13),"radii":Vector2(0.248,0.308)},
            {"center":Vector3(-0.68502,-0.279,1.268),"radii":Vector2(0.223,0.279)},
            {"center":Vector3(0.68502,-0.252,-1.13),"radii":Vector2(0.248,0.308)},
            {"center":Vector3(0.68502,-0.279,1.268),"radii":Vector2(0.223,0.279)},
        ],
        "power_cv":60.0, "power_rpm":5000.0, "torque_rpm":2500.0,
        "variant":"1ª generación · 1.3 Endura · MT5 estimado; no es el Ka SEL del PDF", "source_page":0, "power_reference":false, "factory_abs":false,
    },
    "Peugeot 208": {
        "key":"peugeot_208", "catalog_revision":"023", "price":10100, "mass":1050.0, "torque":150.0,
        "redline":6500.0, "wheelbase":2.538, "radius":0.303, "gears":[3.45, 1.87, 1.28, 0.95, 0.75], "final_drive":4.063,
        "drivetrain":"FWD", "front_weight_bias":0.61, "cg_height":0.51, "drag_area":0.66,
        "size":Vector3(1.739,1.46,3.962), "paint":Color("bdc3c8"),
        "asset":"res://assets/cars/peugeot_208/peugeot_208.glb", "wheel_segmentation":"configured_clip",
        "visual_wheels":[
            {"center":Vector3(-0.73038,-0.275,-1.16),"radii":Vector2(0.225,0.296)},
            {"center":Vector3(-0.73038,-0.27,1.321),"radii":Vector2(0.23,0.303)},
            {"center":Vector3(0.73038,-0.275,-1.16),"radii":Vector2(0.225,0.296)},
            {"center":Vector3(0.73038,-0.27,1.321),"radii":Vector2(0.23,0.303)},
        ],
        "power_cv":115.0, "power_rpm":6000.0, "torque_rpm":4000.0,
        "variant":"1ª generación · Active 1.6 EC5 · MT5 provisional", "source_page":3, "power_reference":true, "reference_torque_nm":150.0, "factory_abs":true,
    },
    "Volkswagen Polo Classic": {
        "key":"polo", "catalog_revision":"023", "price":6200, "mass":1040.0, "torque":140.0,
        "redline":6300.0, "wheelbase":2.44, "radius":0.286, "gears":[3.455, 1.944, 1.286, 0.969, 0.805], "final_drive":4.111,
        "drivetrain":"FWD", "front_weight_bias":0.61, "cg_height":0.5, "drag_area":0.68,
        "size":Vector3(1.64,1.42,4.14), "paint":Color("bdc3c8"),
        "asset":"res://assets/cars/polo/polo.glb", "wheel_segmentation":"configured_clip",
        "visual_wheels":[
            {"center":Vector3(-0.6888,-0.2,-1.183),"radii":Vector2(0.3,0.3)},
            {"center":Vector3(-0.6888,-0.222,1.173),"radii":Vector2(0.278,0.279)},
            {"center":Vector3(0.6888,-0.2,-1.183),"radii":Vector2(0.3,0.3)},
            {"center":Vector3(0.6888,-0.222,1.173),"radii":Vector2(0.278,0.279)},
        ],
        "power_cv":100.0, "power_rpm":5600.0, "torque_rpm":3000.0,
        "variant":"Classic sedán · 1.6 MPI · MT5 estimado; no es Polo MSI 2018", "source_page":0, "power_reference":false, "factory_abs":false,
    },
    "Volkswagen Virtus": {
        "key":"virtus", "catalog_revision":"023", "price":11400, "mass":1190.0, "torque":155.0,
        "redline":6500.0, "wheelbase":2.651, "radius":0.307, "gears":[3.769, 1.955, 1.281, 0.927, 0.74], "final_drive":4.188,
        "drivetrain":"FWD", "front_weight_bias":0.61, "cg_height":0.52, "drag_area":0.66,
        "size":Vector3(1.751,1.472,4.482), "paint":Color("bdc3c8"),
        "asset":"res://assets/cars/virtus/virtus.glb", "wheel_segmentation":"configured_clip",
        "visual_wheels":[
            {"center":Vector3(-0.73542,-0.179,-1.3156),"radii":Vector2(0.321,0.346)},
            {"center":Vector3(-0.73542,-0.179,1.3545),"radii":Vector2(0.321,0.346)},
            {"center":Vector3(0.73542,-0.179,-1.3156),"radii":Vector2(0.321,0.346)},
            {"center":Vector3(0.73542,-0.179,1.3545),"radii":Vector2(0.321,0.346)},
        ],
        "power_cv":110.0, "power_rpm":5750.0, "torque_rpm":4000.0,
        "variant":"1.6 MSI · MT5 provisional; aspecto deportivo del escaneo", "source_page":2, "power_reference":true, "reference_torque_nm":155.0, "factory_abs":true,
    },
    "Chevrolet Onix": {
        "key":"onix", "catalog_revision":"023", "price":8400, "mass":1060.0, "torque":126.0,
        "redline":6500.0, "wheelbase":2.528, "radius":0.297, "gears":[3.73, 2.14, 1.41, 1.12, 0.89], "final_drive":4.29,
        "drivetrain":"FWD", "front_weight_bias":0.61, "cg_height":0.51, "drag_area":0.68,
        "size":Vector3(1.705,1.475,3.93), "paint":Color("bdc3c8"),
        "asset":"res://assets/cars/onix/onix.glb", "wheel_segmentation":"configured_clip",
        "visual_wheels":[
            {"center":Vector3(-0.7161,-0.178,-1.127),"radii":Vector2(0.312,0.351)},
            {"center":Vector3(-0.7161,-0.221,1.3226),"radii":Vector2(0.278,0.313)},
            {"center":Vector3(0.7161,-0.178,-1.127),"radii":Vector2(0.312,0.351)},
            {"center":Vector3(0.7161,-0.221,1.3226),"radii":Vector2(0.278,0.313)},
        ],
        "power_cv":98.0, "power_rpm":6000.0, "torque_rpm":2800.0,
        "variant":"1ª generación · 1.4 SPE/4 · MT5 estimado; no es 1.2 Ecotec", "source_page":0, "power_reference":false, "factory_abs":true,
    },
    "Toyota Corolla Cross": {
        "key":"cross", "catalog_revision":"023", "price":11800, "mass":1450.0, "torque":199.0,
        "redline":7000.0, "wheelbase":2.64, "radius":0.335, "gears":[3.377], "final_drive":4.623,
        "drivetrain":"FWD", "front_weight_bias":0.61, "cg_height":0.64, "drag_area":0.84,
        "size":Vector3(1.825,1.62,4.46), "paint":Color("bdc3c8"),
        "asset":"res://assets/cars/cross/cross.glb", "wheel_segmentation":"configured_clip",
        "visual_wheels":[
            {"center":Vector3(-0.7665,-0.2,-1.269),"radii":Vector2(0.3,0.405)},
            {"center":Vector3(-0.7665,-0.15,1.24),"radii":Vector2(0.345,0.466)},
            {"center":Vector3(0.7665,-0.2,-1.269),"radii":Vector2(0.3,0.405)},
            {"center":Vector3(0.7665,-0.15,1.24),"radii":Vector2(0.345,0.466)},
        ],
        "power_cv":170.0, "power_rpm":6600.0, "torque_rpm":4400.0,
        "variant":"2.0 nafta · CVT con engranaje de salida · mapa y versión provisionales", "source_page":3, "power_reference":true, "factory_abs":true,
        "transmission_type":"cvt",
    },
}

static func profile(model: String) -> Dictionary:
    return Regional.profile_data(DATA[model]) if DATA.has(model) else {}
