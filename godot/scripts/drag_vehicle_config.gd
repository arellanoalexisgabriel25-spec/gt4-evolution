extends Resource

# Original approximate presets for development, not measured manufacturer data.
@export var mass := 980.0
@export var peak_torque := 145.0
@export var engine_inertia := 0.26
@export var clutch_capacity := 230.0
@export var wheel_inertia := 3.2
@export var drag_area := 0.64
@export var rolling_resistance := 0.014
@export var drivetrain := "RWD"
@export var front_weight_bias := 0.5
@export var wheelbase := 2.5
@export var cg_height := 0.46
@export var grip := 1.1
@export var wheel_radius := 0.30
@export var final_drive := 4.10
@export var gear_ratios := PackedFloat32Array([3.10,2.10,1.50,1.15,0.90])
@export var idle_rpm := 900.0
@export var redline_rpm := 7000.0
@export var torque_curve := PackedFloat32Array([0.58,0.72,0.87,0.98,1.0,0.95,0.85,0.68])
@export var engine_health := 100.0
@export var transmission_health := 100.0
@export var tire_health := 100.0

static func from_vehicle(vehicle: Dictionary):
    var result = load("res://scripts/drag_vehicle_config.gd").new()
    var handling = load("res://scripts/handling.gd").configuration(vehicle)
    result.drivetrain = handling.drivetrain
    result.front_weight_bias = handling.front_weight_bias
    result.gear_ratios = handling.gear_ratios.duplicate()
    result.final_drive = handling.final_drive
    var presets := {"MX-5":[980.0,145.0],"Civic":[1080.0,155.0],"Levin":[1010.0,148.0],"Silvia":[1180.0,245.0],"MR2":[1240.0,250.0],"Prelude":[1260.0,200.0],"FTO":[1170.0,200.0],"RX-7":[1280.0,265.0],"Impreza":[1250.0,300.0],"Skyline":[1430.0,340.0]}
    for name in presets:
        if str(vehicle.get("model","")).contains(name):
            result.mass = presets[name][0]
            result.peak_torque = presets[name][1]
            break
    result.clutch_capacity = result.peak_torque*1.7
    result.engine_health = float(vehicle.get("health",{}).get("motor",50.0))
    result.transmission_health = float(vehicle.get("health",{}).get("transmision",50.0))
    result.tire_health = float(vehicle.get("health",{}).get("neumaticos",50.0))
    var upgrades: Array = vehicle.get("upgrades",[])
    result.peak_torque *= (1.10 if upgrades.has("ecu") else 1.0)*(1.05 if upgrades.has("escape") else 1.0)
    result.grip *= (1.12 if upgrades.has("tires") else 1.0)*(1.04 if upgrades.has("suspension") else 1.0)
    return result
