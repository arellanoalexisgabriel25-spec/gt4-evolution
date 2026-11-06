extends RefCounted

# Stable names are also used by old save files. New offers are appended, so no
# existing persistent vehicle ID changes when the flagship range is introduced.
const FLAGSHIPS := ["Fiat 147 Vivace", "Fiat Uno Fire 3 puertas", "Volkswagen Gol Power 3 puertas"]
const TechnicalReference = preload("res://scripts/technical_reference_data.gd")
const Additional = preload("res://scripts/additional_vehicle_data.gd")
const NATIONALS = Additional.MODELS
const Regional = preload("res://scripts/regional_vehicle_data.gd")
const REGIONALS = Regional.MODELS
const Expanded = preload("res://scripts/expanded_vehicle_data.gd")
const EXPANDED = Expanded.MODELS
# Gallery-only scans have no inferred engine or gearbox and never create market
# offers. Their dimensions/wheel envelopes are render scale estimates only.
const SHOWROOM_ONLY := ["Volkswagen Taos"]
const SHOWROOM_DATA := {
    "Volkswagen Taos": {
        "key":"vw_taos", "visual_only":true,
        "size":Vector3(1.84,1.63,4.46), "wheelbase":2.68, "radius":0.33,
        "paint":Color("a1a8b3"), "wheel_segmentation":"configured_clip",
        "visual_wheels":[
            {"center":Vector3(-0.684,-0.1530,-1.2980),"radii":Vector2(0.3462,0.3760)},
            {"center":Vector3(-0.627,-0.1378,1.3470),"radii":Vector2(0.3616,0.3928)},
            {"center":Vector3(0.684,-0.1567,-1.2998),"radii":Vector2(0.3422,0.3717)},
            {"center":Vector3(0.616,-0.1275,1.3503),"radii":Vector2(0.3724,0.4045)},
        ],
        "asset":"res://assets/cars/vw_taos/vw_taos.glb",
        "visual_status":"Escaneo aportado · escala y rig estimados; sin ficha mecánica",
    },
}
const CLASSICS := ["Fiat 128 Súper Europa 1.5", "Fiat 133", "Fiat 128 estándar"]
const DATA := {
    "Fiat 147 Vivace": {
        "key":"fiat_147", "price":3400, "mass":TechnicalReference.VIVACE_MASS_KG, "torque":TechnicalReference.VIVACE_TORQUE_NM,
        "redline":6200.0, "wheelbase":2.22, "radius":0.275,
        "gears":[3.91,2.24,1.47,1.04,0.86], "final_drive":3.76,
        "size":Vector3(1.54,1.38,TechnicalReference.VIVACE_LENGTH_M), "paint":Color("c5c2b3"),
        "asset":"res://assets/cars/fiat_147/fiat_147.glb"
    },
    "Fiat Uno Fire 3 puertas": {
        "key":"uno_fire", "price":4600, "mass":910.0, "torque":110.815145,
        "redline":6300.0, "wheelbase":2.36, "radius":0.285,
        "gears":[3.91,2.16,1.48,1.12,0.90], "final_drive":3.73,
        "size":Vector3(1.63,1.44,3.69), "paint":Color("a32d2b"),
        "asset":"res://assets/cars/uno_fire/uno_fire.glb"
    },
    "Volkswagen Gol Power 3 puertas": {
        "key":"gol_power", "price":5900, "mass":980.0, "torque":143.0,
        "redline":6200.0, "wheelbase":2.47, "radius":0.29,
        "gears":[3.45,1.94,1.29,0.97,0.80], "final_drive":4.11,
        "size":Vector3(1.65,1.42,3.90), "paint":Color("e6e7df"),
        "asset":"res://assets/cars/gol_power/gol_power.glb"
    },
    "Fiat 128 Súper Europa 1.5": {
        "key":"fiat_128", "price":4300, "mass":850.0, "torque":117.6798,
        "redline":6500.0, "wheelbase":2.445, "radius":0.285,
        "gears":[3.583,2.235,1.454,1.042,0.863], "final_drive":3.765,
        "drivetrain":"FWD", "front_weight_bias":0.62,
        "size":Vector3(1.59,1.42,3.95), "paint":Color("d6c7a6"),
        "asset":"res://assets/cars/fiat_128/fiat_128.glb", "wheel_segmentation":"contour"
    },
    "Fiat 133": {
        "key":"fiat_133", "price":2100, "mass":680.0, "torque":54.0,
        "redline":5800.0, "wheelbase":2.027, "radius":0.258,
        "gears":[3.583,2.235,1.454,1.042], "final_drive":4.375,
        "drivetrain":"RWD", "front_weight_bias":0.40,
        "size":Vector3(1.42,1.328,3.455), "paint":Color("a92823"),
        "asset":"res://assets/cars/fiat_133/fiat_133.glb", "wheel_segmentation":"contour"
    },
    "Fiat 128 estándar": {
        "key":"fiat_128_standard", "price":3300, "mass":830.0, "torque":82.0,
        "redline":6200.0, "wheelbase":2.445, "radius":0.275,
        "gears":[3.583,2.235,1.454,1.042], "final_drive":4.071,
        "drivetrain":"FWD", "front_weight_bias":0.62,
        "size":Vector3(1.59,1.42,3.855), "paint":Color("202222"),
        "asset":"res://assets/cars/fiat_128_standard/fiat_128_standard.glb", "wheel_segmentation":"contour"
    },
    "Fiat 125": Additional.DATA["Fiat 125"],
    "Fiat Duna": Additional.DATA["Fiat Duna"],
    "Fiat Cronos": Additional.DATA["Fiat Cronos"],
    "Fiat Siena": Additional.DATA["Fiat Siena"],
    "Fiat Punto": Additional.DATA["Fiat Punto"],
    "Fiat Regatta": Additional.DATA["Fiat Regatta"],
    "Fiat 500 Sport": Additional.DATA["Fiat 500 Sport"],
    "Chevrolet Corsa 5 puertas": Regional.DATA["Chevrolet Corsa 5 puertas"],
    "Volkswagen Amarok": Regional.DATA["Volkswagen Amarok"],
    "Ford Ranger cabina simple": Regional.DATA["Ford Ranger cabina simple"],
    "Ford EcoSport": Regional.DATA["Ford EcoSport"],
    "Toyota Corolla": Regional.DATA["Toyota Corolla"],
    "Fiat Palio 5 puertas": Regional.DATA["Fiat Palio 5 puertas"],
    "Toyota Yaris Sedán": Expanded.DATA["Toyota Yaris Sedán"],
    "Ford Ka 3 puertas": Expanded.DATA["Ford Ka 3 puertas"],
    "Peugeot 208": Expanded.DATA["Peugeot 208"],
    "Volkswagen Polo Classic": Expanded.DATA["Volkswagen Polo Classic"],
    "Volkswagen Virtus": Expanded.DATA["Volkswagen Virtus"],
    "Chevrolet Onix": Expanded.DATA["Chevrolet Onix"],
    "Toyota Corolla Cross": Expanded.DATA["Toyota Corolla Cross"],

}

static func definition(model: String) -> Dictionary:
    return DATA.get(model,SHOWROOM_DATA.get(model,{}))

static func flagship(model: String) -> bool:
    return FLAGSHIPS.has(model)

static func has_definition(model: String) -> bool:
    return DATA.has(model)

static func market_order(cars: Array) -> Array:
    var ordered: Array = []
    for model in FLAGSHIPS+CLASSICS+NATIONALS+REGIONALS+EXPANDED:
        for car in cars:
            if car.get("model")==model:
                ordered.append(car)
    for car in cars:
        if not has_definition(str(car.get("model",""))):
            ordered.append(car)
    return ordered
