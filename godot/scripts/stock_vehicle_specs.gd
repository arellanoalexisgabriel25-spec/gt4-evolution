extends RefCounted

# These are carried-forward development estimates, NOT homologated data. The
# broad garage names do not identify engine/year/market uniquely. Keep provenance
# beside each profile so later verified sheets can replace values without silently
# turning model output into a manufacturer's specification.
const EngineTorque = preload("res://scripts/engine_torque.gd")
const TechnicalReference = preload("res://scripts/technical_reference_data.gd")
const Additional = preload("res://scripts/additional_vehicle_data.gd")
const Regional = preload("res://scripts/regional_vehicle_data.gd")
const Expanded = preload("res://scripts/expanded_vehicle_data.gd")
const EnvironmentData = preload("res://scripts/driving_environment.gd")
const TEST_DRIVER_KG := 75.0
const PROFILES := {
    "Fiat 147 Vivace": {"id":"147_vivace_14_bio_1997_reference","variant":"Vivace 1.4 BIO · 1997 (compendio aportado)","curb_mass_kg":TechnicalReference.VIVACE_MASS_KG,"peak_torque_nm":TechnicalReference.VIVACE_TORQUE_NM,"redline_rpm":6200.0,"wheelbase_m":2.22,"rolling_radius_m":0.275,"gear_ratios":[3.91,2.24,1.47,1.04,0.86],"final_drive":3.76},
    "Fiat Uno Fire 3 puertas": {"id":"uno_fire_13_8v_2014_reference","variant":"Fire 1.3 8V · 3 puertas · 2014 (ref. aportada)","curb_mass_kg":910.0,"peak_torque_nm":110.815145,"redline_rpm":6300.0,"wheelbase_m":2.36,"rolling_radius_m":0.285,"gear_ratios":[3.91,2.16,1.48,1.12,0.90],"final_drive":3.73},
    "Volkswagen Gol Power 3 puertas": {"id":"gol_power_provisional","variant":"Power 3 puertas · motor/año por verificar","curb_mass_kg":980.0,"peak_torque_nm":143.0,"redline_rpm":6200.0,"wheelbase_m":2.47,"rolling_radius_m":0.29,"gear_ratios":[3.45,1.94,1.29,0.97,0.80],"final_drive":4.11},
    "Fiat 128 Súper Europa 1.5": {
        "id":"128_super_europa_15_1990_reference", "variant":"Súper Europa 1.5 · 1990 (ref. aportada)",
        "curb_mass_kg":850.0, "peak_torque_nm":117.6798, "redline_rpm":6500.0,
        "wheelbase_m":2.445, "rolling_radius_m":0.285,
        "gear_ratios":[3.583,2.235,1.454,1.042,0.863], "final_drive":3.765,
        "drivetrain":"FWD", "front_weight_bias":0.62, "drag_area_m2":0.68,
        "estimated_fields":["curb_mass_kg","front_weight_bias","redline_rpm","wheelbase_m","rolling_radius_m","gear_ratios","final_drive","drag_area_m2","curve_interpolation"]
    },
    "Fiat 133": {
        "id":"133_843cc_reference", "variant":"133 · 843 cm³ (versión por verificar)",
        "curb_mass_kg":680.0, "peak_torque_nm":54.0, "redline_rpm":5800.0,
        "wheelbase_m":2.027, "rolling_radius_m":0.258,
        "gear_ratios":[3.583,2.235,1.454,1.042], "final_drive":4.375,
        "drivetrain":"RWD", "front_weight_bias":0.40, "drag_area_m2":0.60,
        "estimated_fields":["peak_torque_nm","front_weight_bias","power_rpm","redline_rpm","wheelbase_m","rolling_radius_m","gear_ratios","final_drive","drag_area_m2","curve_interpolation"]
    },
    "Fiat 128 estándar": {
        "id":"128_1116cc_reference", "variant":"128 estándar · 1.116 cm³ (año por verificar)",
        "curb_mass_kg":830.0, "peak_torque_nm":82.0, "redline_rpm":6200.0,
        "wheelbase_m":2.445, "rolling_radius_m":0.275,
        "gear_ratios":[3.583,2.235,1.454,1.042], "final_drive":4.071,
        "drivetrain":"FWD", "front_weight_bias":0.62, "drag_area_m2":0.67,
        "estimated_fields":["peak_torque_nm","front_weight_bias","power_rpm","redline_rpm","wheelbase_m","rolling_radius_m","gear_ratios","final_drive","drag_area_m2","curve_interpolation"]
    }
}

static func for_model(model: String) -> Dictionary:
    if Expanded.DATA.has(model): return _calibration_metadata(Expanded.profile(model))
    if Regional.DATA.has(model): return _calibration_metadata(Regional.profile(model))
    if Additional.DATA.has(model): return _calibration_metadata(Additional.profile(model))
    var profile: Dictionary = PROFILES.get(model,{}).duplicate(true)
    if not profile.is_empty():
        profile["status"] = "development_estimate"
        profile["sources"] = []
        profile["basis"] = "GT4 Evolution v0.15 estimates; external validation pending"
        profile["torque_rpm"] = [900.0,1500.0,2300.0,3000.0,3800.0,4600.0,5400.0,float(profile["redline_rpm"])]
        profile["torque_factors"] = [0.62,0.78,0.92,1.0,0.98,0.89,0.76,0.60]
        if model=="Fiat 147 Vivace":
            # No power RPM is supplied. 5500 RPM and interpolation remain
            # explicit estimates; the analytical peak still respects 63 CV.
            var anchor := EngineTorque.torque_for_cv_at_rpm(TechnicalReference.VIVACE_POWER_CV,5500.0)/float(profile.peak_torque_nm)
            profile["torque_rpm"] = [900.0,1500.0,2300.0,3000.0,3800.0,4600.0,5500.0,6200.0]
            profile["torque_factors"] = [0.62,0.78,0.93,1.0,0.97,0.90,anchor,0.60]
            profile["record_revision"] = TechnicalReference.VIVACE_REVISION
            profile["sources"] = TechnicalReference.vivace_sources()
            profile["basis"] = "User compilation p1: 1997 1372cc BIO, 63 CV, 10.4 kgf m, 807 kg, 3742 mm; earlier report p3 supplies 3000 rpm torque. Power RPM 5500 estimated."
            profile["mass_basis"] = "807 kg reported without fluid/fuel convention; assumed curb mass plus explicit driver"
            profile["reference_targets"] = {"power_cv":63.0,"torque_kgfm":10.4,"torque_rpm":3000.0,"curb_mass_kg":807.0,"length_m":3.742,"manufacturer_verified":false}
            profile["estimated_fields"] = ["power_rpm","mass_convention","redline_rpm","wheelbase_m","rolling_radius_m","gear_ratios","final_drive","drag_area_m2","curve_interpolation","drivetrain_efficiency","rotational_inertia"]
        elif model=="Fiat Uno Fire 3 puertas":
            # Two supplied factory claims anchor the curve; all intervening
            # values remain estimates, not a recovered dynamometer trace.
            profile["peak_torque_nm"] = EngineTorque.kgfm_to_nm(11.3)
            var power_anchor := EngineTorque.torque_for_cv_at_rpm(68.0,5250.0)/float(profile["peak_torque_nm"])
            profile["torque_rpm"] = [900.0,1500.0,2250.0,3000.0,3800.0,4600.0,5250.0,5600.0,6300.0]
            profile["torque_factors"] = [0.62,0.85,1.0,0.98,0.95,0.88,power_anchor,0.74,0.60]
            profile["sources"] = [{"kind":"manufacturer_report_transcribed_by_user","document":"Uno Fire 3 puertas 2014 · descripción aportada","primary_document_verified":false}]
            profile["basis"] = "Supplied 2014 1.3 8V claims: 68 CV @5250 rpm and 11.3 kgf m @2250 rpm; remaining parameters estimated"
            profile["reference_targets"] = {"power_cv":68.0,"power_rpm":5250.0,"torque_kgfm":11.3,"torque_rpm":2250.0,"zero_to_hundred_s":13.2,"top_speed_kmh":158.0,"manufacturer_verified":false}
        elif model=="Fiat 128 Súper Europa 1.5":
            profile["peak_torque_nm"] = EngineTorque.kgfm_to_nm(12.0)
            var anchor := EngineTorque.torque_for_cv_at_rpm(82.0,5600.0)/float(profile["peak_torque_nm"])
            profile["torque_rpm"] = [900.0,1500.0,2300.0,3000.0,3800.0,4600.0,5600.0,6000.0,6500.0]
            profile["torque_factors"] = [0.60,0.76,0.91,1.0,0.99,0.95,anchor,0.74,0.60]
            profile["sources"] = [TechnicalReference.fiat_source(2)]
            profile["basis"] = "Supplied 1990 1.5 claims: 82 DIN CV at 5600 rpm and 12 kgf m at 3000 rpm; mass and gearing estimated"
            profile["reference_targets"] = {"power_cv":82.0,"power_rpm":5600.0,"torque_kgfm":12.0,"torque_rpm":3000.0,"manufacturer_verified":false}
        elif model=="Fiat 133":
            # The supplied guide gives power and mass, but no dynamometer curve,
            # torque peak or power RPM. The 5000 RPM anchor below is an estimate.
            var anchor := EngineTorque.torque_for_cv_at_rpm(34.0,5000.0)/float(profile["peak_torque_nm"])
            profile["torque_rpm"] = [900.0,1500.0,2300.0,3200.0,3800.0,4600.0,5000.0,5800.0]
            profile["torque_factors"] = [0.58,0.78,0.93,1.0,0.99,0.93,anchor,0.64]
            profile["sources"] = [TechnicalReference.fiat_source(2)]
            profile["basis"] = "Supplied 133 guide: 843cc, 34 CV, 680 kg, 120 km/h; torque, power RPM, exact version and gearing estimated"
            profile["reference_targets"] = {"power_cv":34.0,"curb_mass_kg":680.0,"top_speed_kmh":120.0,"manufacturer_verified":false}
        elif model=="Fiat 128 estándar":
            # The generic 1116cc report supplies 55 CV and 830 kg only. Keep
            # torque, power RPM, exact year, gearbox and aero explicitly estimated.
            var anchor := EngineTorque.torque_for_cv_at_rpm(55.0,5600.0)/float(profile["peak_torque_nm"])
            profile["torque_rpm"] = [900.0,1500.0,2300.0,3000.0,3800.0,4600.0,5600.0,6200.0]
            profile["torque_factors"] = [0.60,0.76,0.91,1.0,0.98,0.90,anchor,0.64]
            profile["sources"] = [TechnicalReference.fiat_source(1)]
            profile["basis"] = "Supplied standard 128 guide: 1116cc, 55 CV, 830 kg; torque, power RPM, exact year and gearing estimated"
            profile["reference_targets"] = {"power_cv":55.0,"curb_mass_kg":830.0,"manufacturer_verified":false}
    return _calibration_metadata(profile)

# A source-backed peak does not certify the rest of a vehicle. In particular,
# neither supplied report contains individual forward/reverse/final ratios.
# Mark shared defaults explicitly, including older Uno/Gol profiles that had no
# estimate list. This changes provenance only, never physical calibration.
static func _calibration_metadata(profile: Dictionary) -> Dictionary:
    if profile.is_empty(): return profile
    var estimated: Array = profile.get("estimated_fields",[]).duplicate()
    for field in ["mass_convention","redline_rpm","wheelbase_m","rolling_radius_m","gear_ratios","reverse_ratio","final_drive","drag_area_m2","rolling_resistance","curve_interpolation","drivetrain_efficiency","engine_inertia","wheel_inertia","clutch_capacity_nm","front_weight_bias","cg_height_m","suspension_pitch_stiffness_nm_rad","suspension_pitch_damping_nms_rad","suspension_pitch_inertia_kg_m2","differential_type","differential_bias_ratio","differential_preload_nm"]:
        if not estimated.has(field): estimated.append(field)
    var targets: Dictionary = profile.get("reference_targets",{})
    if not targets.has("curb_mass_kg") and not estimated.has("curb_mass_kg"):
        estimated.append("curb_mass_kg")
    if not targets.has("torque_kgfm") and not targets.has("torque_nm") and not estimated.has("peak_torque_nm"):
        estimated.append("peak_torque_nm")
    if not targets.has("power_cv") and not estimated.has("power_cv"):
        estimated.append("power_cv")
    if not targets.has("power_rpm") and not estimated.has("power_rpm"):
        estimated.append("power_rpm")
    if not targets.has("torque_rpm") and not estimated.has("torque_peak_rpm"):
        estimated.append("torque_peak_rpm")
    profile["estimated_fields"] = estimated
    return profile

# Engine-sheet and simulation revisions both define a comparable record series.
# In 0.22 the regional config tag was not propagated to the garage's lookup.
static func record_revision(model: String) -> String:
    var profile := for_model(model)
    return EnvironmentData.record_profile(str(profile.get("record_revision",profile.get("id",""))))

# ISO tire-size geometry gives unloaded radius only. A loaded rolling radius
# still requires a tire/circumference measurement; do not invent its deflection.
static func unloaded_tire_radius_m(width_mm: float, aspect_percent: float, rim_inches: float) -> float:
    if not is_finite(width_mm) or not is_finite(aspect_percent) or not is_finite(rim_inches) or width_mm<=0.0 or aspect_percent<=0.0 or rim_inches<=0.0:
        return 0.0
    return rim_inches*0.0254*0.5+width_mm*0.001*aspect_percent/100.0

# Pure zero-slip kinematics. Use signed speed and signed gear ratio: reverse
# wheel motion through a negative ratio still produces positive engine RPM.
# These equations cannot predict top speed, tire slip or an acceleration time.
static func synchronous_engine_rpm(speed_mps: float, gear_ratio: float, final_drive: float, rolling_radius_m: float) -> float:
    if not _valid_gearing(speed_mps,gear_ratio,final_drive,rolling_radius_m): return 0.0
    return speed_mps/rolling_radius_m*gear_ratio*final_drive*60.0/TAU

static func speed_at_engine_rpm(rpm: float, gear_ratio: float, final_drive: float, rolling_radius_m: float) -> float:
    if not _valid_gearing(rpm,gear_ratio,final_drive,rolling_radius_m): return 0.0
    return rpm*TAU/60.0*rolling_radius_m/(gear_ratio*final_drive)

static func _valid_gearing(value: float, gear_ratio: float, final_drive: float, radius_m: float) -> bool:
    return is_finite(value) and is_finite(gear_ratio) and is_finite(final_drive) and is_finite(radius_m) and absf(gear_ratio)>0.000001 and final_drive>0.0 and radius_m>0.0

static func _reported_fields(targets: Dictionary) -> Array:
    var fields: Array = []
    for field in ["power_cv","power_rpm","curb_mass_kg","length_m"]:
        if targets.has(field): fields.append(field)
    if targets.has("torque_kgfm") or targets.has("torque_nm"): fields.append("peak_torque_nm")
    if targets.has("torque_rpm"): fields.append("torque_peak_rpm")
    return fields

static func metric_snapshot(config) -> Dictionary:
    var peak: Dictionary = EngineTorque.maximum_power(config)
    var speed_per_1000: Array = []
    var redline_speeds: Array = []
    for ratio in config.gear_ratios:
        speed_per_1000.append(speed_at_engine_rpm(1000.0,float(ratio),config.final_drive,config.wheel_radius)*3.6)
        redline_speeds.append(speed_at_engine_rpm(config.redline_rpm,float(ratio),config.final_drive,config.wheel_radius)*3.6)
    return {
        "profile_id":config.profile_id,"variant":config.variant_label,
        "status":config.specification_status,"sources":config.specification_sources.duplicate(true),
        "manufacturer_verified":false,
        "curb_mass_kg":config.curb_mass,"driver_mass_kg":config.driver_mass,"test_mass_kg":config.mass,
        "mass_basis":config.mass_basis,
        "record_revision":config.record_revision,"estimated_fields":config.estimated_fields.duplicate(),
        "peak_torque_nm":config.peak_torque,
        "calculated_peak_power_kw":peak["kw"],"calculated_peak_power_cv":EngineTorque.kw_to_cv(float(peak["kw"])),
        "calculated_peak_power_rpm":peak["rpm"],"power_basis":"healthy full-load crankshaft curve, not a measured factory result",
        "gear_ratios":config.gear_ratios.duplicate(),"final_drive":config.final_drive,
        "reverse_ratio":config.reverse_ratio,
        "gear_speed_kmh_per_1000_rpm":speed_per_1000,
        "geared_redline_speed_kmh":redline_speeds,
        "reverse_speed_kmh_per_1000_rpm":speed_at_engine_rpm(1000.0,-absf(config.reverse_ratio),config.final_drive,config.wheel_radius)*3.6,
        "gearing_basis":"zero-slip kinematics of configured ratios; not a measured top speed",
        "gear_list_basis":"launch gear only; CVT varies its ratio" if config.transmission_type=="cvt" else "fixed forward gears",
        "cvt_ratio_range":[config.cvt_min_ratio,config.cvt_max_ratio] if config.transmission_type=="cvt" else [],
        "reported_fields":_reported_fields(config.reference_targets),
        "calibration_status":"source anchors with estimated dynamics; factory acceleration not validated",
        "transmission_type":config.transmission_type,
        "rolling_radius_m":config.wheel_radius,"wheelbase_m":config.wheelbase,
        "drag_area_m2":config.drag_area,"air_density_kg_m3":config.air_density,
        "rolling_resistance":config.rolling_resistance,"drivetrain_efficiency":config.drivetrain_efficiency,
        "gravity_mps2":config.gravity_mps2,"dynamics_revision":EnvironmentData.REVISION,
        "brake_heat_capacity_j_k":[config.brake_heat_capacity.x,config.brake_heat_capacity.y],"brake_fade_start_c":config.brake_fade_start_c,
        "engine_inertia_kg_m2":config.engine_inertia,"wheel_inertia_per_axle_kg_m2":config.wheel_inertia,
        "clutch_capacity_nm":config.clutch_capacity,"factory_abs":config.abs_assist,
        "factory_only":config.factory_class,
        "engine_position":config.engine_position,
        "reference_targets":config.reference_targets.duplicate(true),
        "rotational_equivalent_mass_kg":2.0*config.wheel_inertia/(config.wheel_radius*config.wheel_radius)
    }
