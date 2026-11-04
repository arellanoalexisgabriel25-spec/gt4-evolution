extends RefCounted

# These are carried-forward development estimates, NOT homologated data. The
# broad garage names do not identify engine/year/market uniquely. Keep provenance
# beside each profile so later verified sheets can replace values without silently
# turning model output into a manufacturer's specification.
const EngineTorque = preload("res://scripts/engine_torque.gd")
const TEST_DRIVER_KG := 75.0
const PROFILES := {
    "Fiat 147 Vivace": {"id":"147_vivace_provisional","variant":"Vivace · motor/año por verificar","curb_mass_kg":840.0,"peak_torque_nm":112.0,"redline_rpm":6200.0,"wheelbase_m":2.22,"rolling_radius_m":0.275,"gear_ratios":[3.91,2.24,1.47,1.04,0.86],"final_drive":3.76},
    "Fiat Uno Fire 3 puertas": {"id":"uno_fire_13_8v_2014_reference","variant":"Fire 1.3 8V · 3 puertas · 2014 (ref. aportada)","curb_mass_kg":910.0,"peak_torque_nm":110.815145,"redline_rpm":6300.0,"wheelbase_m":2.36,"rolling_radius_m":0.285,"gear_ratios":[3.91,2.16,1.48,1.12,0.90],"final_drive":3.73},
    "Volkswagen Gol Power 3 puertas": {"id":"gol_power_provisional","variant":"Power 3 puertas · motor/año por verificar","curb_mass_kg":980.0,"peak_torque_nm":143.0,"redline_rpm":6200.0,"wheelbase_m":2.47,"rolling_radius_m":0.29,"gear_ratios":[3.45,1.94,1.29,0.97,0.80],"final_drive":4.11}
}

static func for_model(model: String) -> Dictionary:
    var profile: Dictionary = PROFILES.get(model,{}).duplicate(true)
    if not profile.is_empty():
        profile["status"] = "development_estimate"
        profile["sources"] = []
        profile["basis"] = "GT4 Evolution v0.15 estimates; external validation pending"
        profile["torque_rpm"] = [900.0,1500.0,2300.0,3000.0,3800.0,4600.0,5400.0,float(profile["redline_rpm"])]
        profile["torque_factors"] = [0.62,0.78,0.92,1.0,0.98,0.89,0.76,0.60]
        if model=="Fiat Uno Fire 3 puertas":
            # Two supplied factory claims anchor the curve; all intervening
            # values remain estimates, not a recovered dynamometer trace.
            profile["peak_torque_nm"] = EngineTorque.kgfm_to_nm(11.3)
            var power_anchor := EngineTorque.torque_for_cv_at_rpm(68.0,5250.0)/float(profile["peak_torque_nm"])
            profile["torque_rpm"] = [900.0,1500.0,2250.0,3000.0,3800.0,4600.0,5250.0,5600.0,6300.0]
            profile["torque_factors"] = [0.62,0.85,1.0,0.98,0.95,0.88,power_anchor,0.74,0.60]
            profile["sources"] = [{"kind":"manufacturer_report_transcribed_by_user","document":"Uno Fire 3 puertas 2014 · descripción aportada","primary_document_verified":false}]
            profile["basis"] = "Supplied 2014 1.3 8V claims: 68 CV @5250 rpm and 11.3 kgf m @2250 rpm; remaining parameters estimated"
            profile["reference_targets"] = {"power_cv":68.0,"power_rpm":5250.0,"torque_kgfm":11.3,"torque_rpm":2250.0,"zero_to_hundred_s":13.2,"top_speed_kmh":158.0,"manufacturer_verified":false}
    return profile

# ISO tire-size geometry gives unloaded radius only. A loaded rolling radius
# still requires a tire/circumference measurement; do not invent its deflection.
static func unloaded_tire_radius_m(width_mm: float, aspect_percent: float, rim_inches: float) -> float:
    if not is_finite(width_mm) or not is_finite(aspect_percent) or not is_finite(rim_inches) or width_mm<=0.0 or aspect_percent<=0.0 or rim_inches<=0.0:
        return 0.0
    return rim_inches*0.0254*0.5+width_mm*0.001*aspect_percent/100.0

static func metric_snapshot(config) -> Dictionary:
    var peak: Dictionary = EngineTorque.maximum_power(config)
    return {
        "profile_id":config.profile_id,"variant":config.variant_label,
        "status":config.specification_status,"sources":config.specification_sources.duplicate(),
        "manufacturer_verified":false,
        "curb_mass_kg":config.curb_mass,"driver_mass_kg":config.driver_mass,"test_mass_kg":config.mass,
        "mass_basis":"development curb estimate; fuel-fill definition unverified",
        "peak_torque_nm":config.peak_torque,
        "calculated_peak_power_kw":peak["kw"],"calculated_peak_power_cv":EngineTorque.kw_to_cv(float(peak["kw"])),
        "calculated_peak_power_rpm":peak["rpm"],"power_basis":"healthy full-load crankshaft curve, not a measured factory result",
        "gear_ratios":config.gear_ratios.duplicate(),"final_drive":config.final_drive,
        "rolling_radius_m":config.wheel_radius,"wheelbase_m":config.wheelbase,
        "drag_area_m2":config.drag_area,"air_density_kg_m3":config.air_density,
        "factory_only":config.factory_class,
        "reference_targets":config.reference_targets.duplicate(true),
        "rotational_equivalent_mass_kg":2.0*config.wheel_inertia/(config.wheel_radius*config.wheel_radius)
    }
