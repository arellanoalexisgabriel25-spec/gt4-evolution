extends RefCounted

const FWD = preload("res://resources/front_wheel_drive.tres")
const RWD = preload("res://resources/rear_wheel_drive.tres")

static func configuration(vehicle: Dictionary):
    var model := str(vehicle.get("model", ""))
    var front := model.contains("Civic") or model.contains("Prelude") or model.contains("FTO")
    var config = (FWD if front else RWD).duplicate()
    if model.contains("Impreza") or model.contains("Skyline"):
        config.drivetrain = "AWD"
    var values := parameters(vehicle)
    config.acceleration *= float(values["acceleration"]) / 15.0
    config.top_speed *= float(values["top_speed"]) / 38.0
    config.braking = float(values["braking"])
    config.grip *= float(values["grip"])
    return config

# Provisional arcade balance. These are not recovered GT4 specifications.
static func parameters(vehicle: Dictionary) -> Dictionary:
    var health: Dictionary = vehicle.get("health", {})
    var upgrades: Array = vehicle.get("upgrades", [])
    var motor := clampf(float(health.get("motor", 50.0)) / 100.0, 0.0, 1.0)
    var brakes := clampf(float(health.get("frenos", 50.0)) / 100.0, 0.0, 1.0)
    var tires := clampf(float(health.get("neumaticos", 50.0)) / 100.0, 0.0, 1.0)
    var power := 1.0 + (0.10 if upgrades.has("ecu") else 0.0) + (0.05 if upgrades.has("escape") else 0.0)
    return {
        "acceleration": (10.0 + 5.0 * motor) * power,
        "top_speed": (30.0 + 8.0 * motor) * power,
        "braking": (16.0 + 9.0 * brakes) * (1.20 if upgrades.has("brakes") else 1.0),
        "grip": (0.72 + 0.28 * tires) * (1.10 if upgrades.has("tires") else 1.0) * (1.05 if upgrades.has("suspension") else 1.0)
    }
