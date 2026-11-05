extends SceneTree
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Specs = preload("res://scripts/stock_vehicle_specs.gd")
const Catalog = preload("res://scripts/car_catalog.gd")
const Reference = preload("res://scripts/technical_reference_data.gd")
const Torque = preload("res://scripts/engine_torque.gd")
var checks := 0
var failed := false
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)
func vehicle(name: String) -> Dictionary:
    return {"model":name,"upgrades":[],"health":{"motor":100.0,"transmision":100.0,"neumaticos":100.0,"frenos":100.0,"suspension":100.0,"chasis":100.0}}
func _initialize() -> void:
    var config = Config.from_vehicle(vehicle("Fiat 147 Vivace"),true)
    var metrics: Dictionary = config.metrics()
    check(is_equal_approx(config.curb_mass,807.0) and is_equal_approx(config.mass,882.0),"Reported vehicle mass and explicit 75 kg driver are added once")
    check(absf(config.peak_torque-101.98916)<0.00001,"The 10.4 kgf m claim converts into SI torque")
    check(absf(config.peak_torque*Torque.curve_factor(3000.0,config)-101.98916)<0.0001,"Earlier report's 3000 RPM torque anchor remains explicit")
    check(absf(metrics.calculated_peak_power_cv-63.0)<0.0001,"The entire piecewise curve respects the supplied 63 CV power peak")
    check(is_equal_approx(metrics.calculated_peak_power_rpm,5500.0) and metrics.estimated_fields.has("power_rpm"),"Assumed power RPM is labelled estimated, not transcribed from the new PDF")
    var dense_peak := 0.0
    for rpm in range(900,6201): dense_peak=maxf(dense_peak,Torque.power_kw(config.peak_torque*Torque.curve_factor(rpm,config),rpm))
    check(absf(dense_peak-metrics.calculated_peak_power_kw)<0.001,"Dense sampling independently verifies the analytical power ceiling")
    check(not metrics.reference_targets.has("power_rpm") and metrics.reference_targets.power_cv==63.0,"Reference claims do not include the assumed power RPM")
    check(metrics.variant.contains("1.4 BIO") and metrics.variant.contains("1997"),"The broad persistent name now identifies its chosen technical variant")
    check(metrics.sources[0].document==Reference.DOCUMENT and metrics.sources[0].sha256==Reference.DOCUMENT_SHA256 and metrics.sources[0].page==1,"The applied values carry the exact PDF hash and page")
    check(metrics.sources[0].kind=="user_compilation" and not metrics.sources[0].primary_document_verified and not metrics.manufacturer_verified,"A secondary compilation is not promoted to verified manufacturer data")
    check(metrics.mass_basis.contains("assumed curb") and metrics.estimated_fields.has("mass_convention"),"Unknown fuel/fluid mass convention remains visible")
    check(metrics.estimated_fields.has("gear_ratios") and metrics.estimated_fields.has("rolling_radius_m"),"The PDF cannot silently certify missing gearbox or tire geometry")
    check(config.record_revision==Reference.VIVACE_REVISION,"A changed curve has a separate record comparison revision")
    var catalog: Dictionary = Catalog.definition("Fiat 147 Vivace")
    check(catalog.mass==config.curb_mass and catalog.torque==config.peak_torque,"Catalog/circuit authoring and drag configuration use the same mass and torque anchors")
    check(is_equal_approx(catalog.size.z,3.742),"Supplied overall length updates visual normalization and collision dimensions")
    check(config.gear_ratios.size()==5 and config.drivetrain=="FWD" and not config.abs_assist and config.turbo_fraction==0.0,"The update retains factory manual layout without adding equipment")
    check(is_equal_approx(metrics.rolling_resistance,0.014),"A broad rolling-resistance paragraph does not replace all vehicle coefficients without calibration")
    var uno = Config.from_vehicle(vehicle("Fiat Uno Fire 3 puertas"),true)
    check(absf(uno.metrics().calculated_peak_power_cv-68.0)<0.0001 and uno.reference_targets.power_rpm==5250.0,"The identified 2014 Uno keeps its specific 68 CV reference over the grouped 70 CV row")
    check(absf(uno.peak_torque-110.815145)<0.0001 and uno.reference_targets.torque_rpm==2250.0,"The grouped diesel entry cannot overwrite the gasoline Uno torque curve")
    var gol = Config.from_vehicle(vehicle("Volkswagen Gol Power 3 puertas"),true)
    check(gol.profile_id=="gol_power_provisional" and gol.curb_mass==980.0 and gol.reference_targets.is_empty(),"Gol Trend/GL figures are not assigned to the distinct Gol Power")
    var sport = Config.from_vehicle(vehicle("Fiat 500 Sport"),true)
    check(absf(sport.metrics().calculated_peak_power_cv-100.0)<0.0001 and sport.gear_ratios.size()==6 and sport.turbo_fraction==0.0,"The user-selected 100 CV Sport remains separate from its Abarth body")
    check(sport.curb_mass==1015.0,"An approximate 950 kg grouped reference does not silently replace the 500 development mass")
    var profile := Specs.for_model("Fiat 147 Vivace")
    profile.sources[0].page=99
    profile.torque_factors[0]=999.0
    check(Specs.for_model("Fiat 147 Vivace").sources[0].page==1 and Specs.for_model("Fiat 147 Vivace").torque_factors[0]<1.0,"Callers cannot mutate the source record or later physical configurations")
    check(Specs.record_revision("Fiat Uno Fire 3 puertas").is_empty(),"Unchanged profiles retain compatible previous record lookup")
    if not failed: print("PASS: %d technical reference assertions" % checks)
    quit(1 if failed else 0)
