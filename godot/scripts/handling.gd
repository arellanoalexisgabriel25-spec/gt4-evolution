extends RefCounted

const FWD = preload("res://resources/front_wheel_drive.tres")
const RWD = preload("res://resources/rear_wheel_drive.tres")
const Catalog = preload("res://scripts/car_catalog.gd")
const Tire = preload("res://scripts/tire_model.gd")

static func configuration(vehicle: Dictionary):
    var model := str(vehicle.get("model", ""))
    var front := model.contains("Civic") or model.contains("Prelude") or model.contains("FTO") or Catalog.flagship(model)
    var config = (FWD if front else RWD).duplicate()
    if model.contains("Impreza") or model.contains("Skyline"):
        config.drivetrain = "AWD"
        config.front_weight_bias = 0.55
    var values := parameters(vehicle)
    config.acceleration *= float(values["acceleration"]) / 15.0
    config.top_speed *= float(values["top_speed"]) / 38.0
    config.braking = float(values["braking"])
    config.grip *= float(values["grip"])
    var local: Dictionary = Catalog.definition(model)
    if not local.is_empty():
        config.wheelbase = float(local["wheelbase"])
        config.wheel_radius = float(local["radius"])
        config.gear_ratios = PackedFloat32Array(local["gears"])
        config.final_drive = float(local["final_drive"])
        config.redline_rpm = float(local["redline"])
        config.upshift_rpm = config.redline_rpm*0.89
        config.acceleration *= float(local["torque"])/143.0*980.0/float(local["mass"])
    return config

# Provisional arcade balance. These are not recovered GT4 specifications.
static func parameters(vehicle: Dictionary) -> Dictionary:
    var health: Dictionary = vehicle.get("health", {})
    var upgrades: Array = vehicle.get("upgrades", [])
    var motor := clampf(float(health.get("motor", 50.0)) / 100.0, 0.0, 1.0)
    var brakes := clampf(float(health.get("frenos", 50.0)) / 100.0, 0.0, 1.0)
    var tires := clampf(float(health.get("neumaticos", 50.0)) / 100.0, 0.0, 1.0)
    var power := 1.0 + (0.10 if upgrades.has("ecu") else 0.0) + (0.05 if upgrades.has("escape") else 0.0)
    var tire_gain := float(Tire.COMPOUNDS[Tire.for_vehicle(vehicle)]["peak"]) if vehicle.has("tire_compound") else (1.10 if upgrades.has("tires") else 1.0)
    return {
        "acceleration": (10.0 + 5.0 * motor) * power,
        "top_speed": (30.0 + 8.0 * motor) * power,
        "braking": (16.0 + 9.0 * brakes) * (1.20 if upgrades.has("brakes") else 1.0),
        "grip": (0.72 + 0.28 * tires) * tire_gain * (1.05 if upgrades.has("suspension") else 1.0)
    }
