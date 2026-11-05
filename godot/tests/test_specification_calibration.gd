extends SceneTree

const Config = preload("res://scripts/drag_vehicle_config.gd")
const Specs = preload("res://scripts/stock_vehicle_specs.gd")
const Additional = preload("res://scripts/additional_vehicle_data.gd")
const Regional = preload("res://scripts/regional_vehicle_data.gd")
const Expanded = preload("res://scripts/expanded_vehicle_data.gd")
const Reference = preload("res://scripts/technical_reference_data.gd")

var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func config_for(model: String):
    return Config.from_vehicle({"model":model,"upgrades":[],"health":{"motor":100.0,"transmision":100.0,"neumaticos":100.0,"frenos":100.0,"suspension":100.0,"chasis":100.0}},true)

func _initialize() -> void:
    # 1000 engine RPM, a 1:1 transmission and a 1 m radius wheel cover
    # 1000 circumferences per minute: 120 pi km/h. This is gearing, not power.
    check(absf(Specs.speed_at_engine_rpm(1000.0,1.0,1.0,1.0)*3.6-120.0*PI)<0.00001,"Kinematic speed uses circumference, minutes and SI units correctly")
    check(absf(Specs.synchronous_engine_rpm(120.0*PI/3.6,1.0,1.0,1.0)-1000.0)<0.00001,"Synchronous RPM is consistent with a known wheel revolution rate")
    check(Specs.speed_at_engine_rpm(1000.0,-2.0,4.0,0.3)<0.0,"A negative reverse ratio produces reverse vehicle speed")
    check(absf(Specs.synchronous_engine_rpm(Specs.speed_at_engine_rpm(3500.0,-2.0,4.0,0.3),-2.0,4.0,0.3)-3500.0)<0.00001,"Reverse wheel rotation maps to positive engine RPM")
    check(Specs.synchronous_engine_rpm(10.0,0.0,4.0,0.3)==0.0 and Specs.speed_at_engine_rpm(1000.0,0.0,4.0,0.3)==0.0,"Neutral has no synchronous engine speed or driven speed")
    check(Specs.speed_at_engine_rpm(1000.0,2.0,0.0,0.3)==0.0 and Specs.speed_at_engine_rpm(1000.0,2.0,4.0,-0.3)==0.0,"Invalid gearing is rejected without division by zero")
    check(Specs.speed_at_engine_rpm(INF,2.0,4.0,0.3)==0.0 and Specs.synchronous_engine_rpm(10.0,NAN,4.0,0.3)==0.0,"Nonfinite measurements cannot contaminate diagnostics")

    var models: Array = Specs.PROFILES.keys()+Additional.MODELS+Regional.MODELS+Expanded.MODELS
    check(models.size()==26,"All 26 supplied-model profiles participate in the calibration audit")
    for model in models:
        var config = config_for(str(model))
        var metrics: Dictionary = config.metrics()
        for field in ["gear_ratios","reverse_ratio","final_drive","rolling_radius_m","mass_convention","curve_interpolation","drivetrain_efficiency","suspension_pitch_stiffness_nm_rad","differential_type"]:
            check(metrics.estimated_fields.has(field),"%s discloses unmeasured %s" % [model,field])
        check(not metrics.manufacturer_verified and metrics.calibration_status.contains("not validated"),"%s does not present model output as manufacturer validation" % model)
        check(metrics.gear_speed_kmh_per_1000_rpm.size()==config.gear_ratios.size(),"%s has one diagnostic per authored forward ratio" % model)
        check(metrics.gearing_basis.contains("not a measured top speed") and metrics.reverse_speed_kmh_per_1000_rpm<0.0,"%s distinguishes gearing diagnostics from measured performance" % model)
        for index in config.gear_ratios.size():
            var ratio := float(config.gear_ratios[index])
            var speed := float(metrics.gear_speed_kmh_per_1000_rpm[index])/3.6
            check(absf(Specs.synchronous_engine_rpm(speed,ratio,config.final_drive,config.wheel_radius)-1000.0)<0.001,"%s gear %d preserves the RPM/speed mapping" % [model,index+1])
            check(absf(float(metrics.geared_redline_speed_kmh[index])/float(metrics.gear_speed_kmh_per_1000_rpm[index])-config.redline_rpm/1000.0)<0.00001,"%s gear %d redline diagnostic is kinematic" % [model,index+1])
        for source in metrics.sources:
            if source.document==Reference.DOCUMENT:
                check(source.sha256==Reference.DOCUMENT_SHA256 and not source.primary_document_verified,"Compendium anchors retain the exact supplied document hash without primary-source certification")
            elif source.document==Reference.FIAT_DOCUMENT:
                check(source.sha256==Reference.FIAT_DOCUMENT_SHA256 and not source.primary_document_verified,"Fiat report anchors retain the exact supplied document hash without primary-source certification")

    var uno = config_for("Fiat Uno Fire 3 puertas")
    check(uno.estimated_fields.has("curb_mass_kg") and uno.estimated_fields.has("gear_ratios") and not uno.estimated_fields.has("power_rpm"),"Uno source-backed 5250 RPM remains distinct from its estimated mass/gearing")
    var gol = config_for("Volkswagen Gol Power 3 puertas")
    check(gol.estimated_fields.has("power_cv") and gol.estimated_fields.has("peak_torque_nm") and gol.reference_targets.is_empty(),"The Gol Power never inherits Gol Trend claims")
    var punto = config_for("Fiat Punto")
    check(punto.estimated_fields.has("power_cv") and punto.reference_targets.is_empty(),"Regional Punto power is explicitly estimated rather than borrowed from another generation")
    var fiat125 = config_for("Fiat 125")
    check(fiat125.reference_targets.curb_mass_kg==1020.0 and fiat125.metrics().reported_fields.has("curb_mass_kg") and fiat125.estimated_fields.has("mass_convention"),"The 125's reported 1020 kg does not imply a known fuel/fluid convention")
    var source_torques := {"Chevrolet Corsa 5 puertas":138.0,"Volkswagen Amarok":340.0,"Ford EcoSport":150.0,"Peugeot 208":150.0,"Volkswagen Virtus":155.0}
    for model in source_torques:
        var config = config_for(model)
        check(config.reference_targets.torque_nm==source_torques[model] and config.peak_torque==source_torques[model],"%s exposes the supplied torque anchor in SI units" % model)
        check(config.estimated_fields.has("variant_mapping") and not config.estimated_fields.has("peak_torque_nm"),"%s distinguishes a reported engine peak from its provisional body association" % model)
    var ranger = config_for("Ford Ranger cabina simple")
    check(not ranger.reference_targets.has("torque_nm") and ranger.estimated_fields.has("peak_torque_nm"),"The 3.0 Ranger cannot inherit the compendium's 470 Nm claim for the distinct 3.2 engine")
    var cross = config_for("Toyota Corolla Cross")
    check(cross.metrics().gear_list_basis.contains("launch gear only") and cross.metrics().cvt_ratio_range.size()==2,"CVT diagnostics label its launch gear separately from the variable ratio range")
    var first_speed := float(uno.metrics().gear_speed_kmh_per_1000_rpm[0])
    uno.drivetrain_efficiency *= 0.5
    uno.driver_mass += 200.0
    check(is_equal_approx(float(uno.metrics().gear_speed_kmh_per_1000_rpm[0]),first_speed),"Mass and efficiency cannot alter the geometric RPM/speed relationship")
    if not failed: print("PASS: %d specification calibration assertions" % checks)
    quit(1 if failed else 0)
