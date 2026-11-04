extends Resource
const Tire = preload("res://scripts/tire_model.gd")
const Damage = preload("res://scripts/damage_model.gd")
const StockSpecs = preload("res://scripts/stock_vehicle_specs.gd")

# Original approximate presets for development, not measured manufacturer data.
@export var curb_mass := 980.0
@export var driver_mass := 75.0
var mass: float:
    get: return curb_mass+driver_mass
    set(value): curb_mass=maxf(1.0,value-driver_mass)
@export var air_density := 1.225
@export var peak_torque := 145.0
@export var engine_inertia := 0.26
@export var clutch_capacity := 230.0
@export var wheel_inertia := 3.2 # kg m² PER AXLE; still an estimated parameter
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
@export var torque_rpm := PackedFloat32Array([900,1500,2500,3500,4500,5500,6500,7000])
@export var drivetrain_efficiency := 0.88
@export var awd_front_split := 0.40
@export var brake_front_bias := 0.65
@export var brake_capacity := 1.4
@export var peak_slip := 0.12
@export var abs_assist := true
@export var turbo_fraction := 0.0
@export var spool_rpm := 2500.0
@export var turbo_response := 2.0
@export var brake_health := 100.0
@export var engine_wear_factor := 1.0
@export var tire_compound := "street"
@export var suspension_health := 100.0
@export var chassis_health := 100.0
@export var steering_factor := 1.0
var factory_class := false
var profile_id := "generic_development"
var variant_label := "Variante no identificada"
var specification_status := "development_estimate"
var specification_sources: Array = []
var reference_targets: Dictionary = {}

static func from_vehicle(vehicle: Dictionary, factory: bool = false):
    var result = load("res://scripts/drag_vehicle_config.gd").new()
    var handling = load("res://scripts/handling.gd").configuration(vehicle)
    result.drivetrain = handling.drivetrain
    result.front_weight_bias = handling.front_weight_bias
    result.gear_ratios = handling.gear_ratios.duplicate()
    result.final_drive = handling.final_drive
    var presets := {"MX-5":[980.0,145.0],"Civic":[1080.0,155.0],"Levin":[1010.0,148.0],"Silvia":[1180.0,245.0],"MR2":[1240.0,250.0],"Prelude":[1260.0,200.0],"FTO":[1170.0,200.0],"RX-7":[1280.0,265.0],"Impreza":[1250.0,300.0],"Skyline":[1430.0,340.0]}
    for name in presets:
        if str(vehicle.get("model","")).contains(name):
            result.curb_mass = presets[name][0]
            result.peak_torque = presets[name][1]
            break
    result.drivetrain_efficiency = 0.91 if result.drivetrain=="FWD" else (0.83 if result.drivetrain=="AWD" else 0.88)
    var name := str(vehicle.get("model",""))
    var local: Dictionary = StockSpecs.for_model(name)
    if not local.is_empty():
        result.curb_mass = float(local["curb_mass_kg"])
        result.peak_torque = float(local["peak_torque_nm"])
        result.redline_rpm = float(local["redline_rpm"])
        result.wheelbase = float(local["wheelbase_m"])
        result.wheel_radius = float(local["rolling_radius_m"])
        result.gear_ratios = PackedFloat32Array(local["gear_ratios"])
        result.final_drive = float(local["final_drive"])
        result.torque_rpm = PackedFloat32Array(local["torque_rpm"])
        result.torque_curve = PackedFloat32Array(local["torque_factors"])
        result.drag_area = 0.69
        result.cg_height = 0.48
        result.profile_id = str(local["id"])
        result.variant_label = str(local["variant"])
        result.specification_status = str(local["status"])
        result.specification_sources = local["sources"].duplicate(true)
        result.reference_targets = local.get("reference_targets",{}).duplicate(true)
    if name.contains("Civic") or name.contains("Levin") or name.contains("FTO"):
        result.redline_rpm = 7800.0
        result.torque_rpm = PackedFloat32Array([900,1800,2800,3800,4800,6000,7000,7800])
        result.torque_curve = PackedFloat32Array([0.48,0.62,0.76,0.88,0.96,1.0,0.96,0.82])
    if name.contains("Silvia") or name.contains("MR2") or name.contains("RX-7") or name.contains("Impreza") or name.contains("Skyline"):
        result.turbo_fraction = 0.45 if name.contains("RX-7") or name.contains("Skyline") else 0.35
        result.torque_curve = PackedFloat32Array([0.55,0.65,0.84,1.0,0.99,0.92,0.80,0.66])
    if name.contains("MR2"):
        result.front_weight_bias = 0.44
    if name.contains("Impreza"):
        result.awd_front_split = 0.50
    result.clutch_capacity = result.peak_torque*1.7
    result.engine_health = float(vehicle.get("health",{}).get("motor",50.0))
    result.transmission_health = float(vehicle.get("health",{}).get("transmision",50.0))
    result.tire_health = float(vehicle.get("health",{}).get("neumaticos",50.0))
    result.brake_health = float(vehicle.get("health",{}).get("frenos",50.0))
    result.suspension_health = float(vehicle.get("health",{}).get("suspension",100.0))
    result.chassis_health = float(vehicle.get("health",{}).get("chasis",100.0))
    result.factory_class = factory
    result.tire_compound = "street" if factory else Tire.for_vehicle(vehicle)
    var upgrades: Array = [] if factory else vehicle.get("upgrades",[])
    result.peak_torque *= (1.10 if upgrades.has("ecu") else 1.0)*(1.05 if upgrades.has("escape") else 1.0)
    result.grip *= 1.04 if upgrades.has("suspension") else 1.0
    result.brake_capacity *= 1.2 if upgrades.has("brakes") else 1.0
    if upgrades.has("suspension"):
        result.cg_height = 0.43
    result.engine_wear_factor = 1.0+(0.22 if upgrades.has("ecu") else 0.0)+(0.08 if upgrades.has("escape") else 0.0)
    var handicaps: Dictionary = Damage.handicaps(vehicle.get("health",{}))
    result.drivetrain_efficiency *= float(handicaps["acceleration"])
    result.grip *= float(handicaps["grip"])
    result.steering_factor = float(handicaps["steering"])
    if factory:
        # Baseline test protocol excludes gameplay assists. Exact factory safety
        # equipment is not established by the broad model names in old saves.
        result.abs_assist = false
    return result

func metrics() -> Dictionary:
    return StockSpecs.metric_snapshot(self)

func apply_damage(points: Dictionary) -> void:
    var previous := Damage.handicaps({"transmision":transmission_health,"suspension":suspension_health,"chasis":chassis_health})
    engine_health = maxf(0,engine_health-float(points.get("motor",0.0)))
    transmission_health = maxf(0,transmission_health-float(points.get("transmision",0.0)))
    tire_health = maxf(0,tire_health-float(points.get("neumaticos",0.0)))
    brake_health = maxf(0,brake_health-float(points.get("frenos",0.0)))
    suspension_health = maxf(0,suspension_health-float(points.get("suspension",0.0)))
    chassis_health = maxf(0,chassis_health-float(points.get("chasis",0.0)))
    var current := Damage.handicaps({"transmision":transmission_health,"suspension":suspension_health,"chasis":chassis_health})
    drivetrain_efficiency *= float(current["acceleration"])/float(previous["acceleration"])
    grip *= float(current["grip"])/float(previous["grip"])
    steering_factor = float(current["steering"])
