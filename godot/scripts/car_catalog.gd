extends RefCounted

# Stable names are also used by old save files. New offers are appended, so no
# existing persistent vehicle ID changes when the flagship range is introduced.
const FLAGSHIPS := ["Fiat 147 Vivace", "Fiat Uno Fire 3 puertas", "Volkswagen Gol Power 3 puertas"]
const DATA := {
    "Fiat 147 Vivace": {
        "key":"fiat_147", "price":3400, "mass":840.0, "torque":112.0,
        "redline":6200.0, "wheelbase":2.22, "radius":0.275,
        "gears":[3.91,2.24,1.47,1.04,0.86], "final_drive":3.76,
        "size":Vector3(1.54,1.38,3.58), "paint":Color("c5c2b3"),
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
    }
}

static func definition(model: String) -> Dictionary:
    return DATA.get(model,{})

static func flagship(model: String) -> bool:
    return DATA.has(model)

static func market_order(cars: Array) -> Array:
    var ordered: Array = []
    for model in FLAGSHIPS:
        for car in cars:
            if car.get("model")==model:
                ordered.append(car)
    for car in cars:
        if not flagship(str(car.get("model",""))):
            ordered.append(car)
    return ordered
