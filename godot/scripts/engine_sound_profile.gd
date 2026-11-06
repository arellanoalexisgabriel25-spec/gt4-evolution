extends Resource

# Original synthesis settings, not recordings or certified acoustic signatures.
# Cylinder/rotor layouts describe the selected development vehicle; exhaust,
# intake and clatter coefficients remain tunable presentation estimates.
@export var label := "four cylinder gasoline"
@export var cylinders := 4
@export var firings_per_revolution := 2.0
@export var idle_rpm := 900.0
@export var redline_rpm := 7000.0
@export var exhaust_cutoff_hz := 2600.0
@export var intake_cutoff_hz := 5200.0
@export var exhaust_resonance_hz := 115.0
@export var exhaust_resonance_decay := 0.012
@export var clatter := 0.045
@export var induction := 0.18
@export var turbo := 0.0
@export var roughness := 0.035
@export var exhaust_partials := PackedFloat32Array([1.0,0.58,0.36,0.26,0.19,0.14,0.10,0.075,0.055,0.04,0.025,0.015])
@export var intake_partials := PackedFloat32Array([1.0,0.24,0.18,0.12,0.065,0.035])

static func from_vehicle(config, vehicle_name: String = ""):
    var result = load("res://scripts/engine_sound_profile.gd").new()
    result.idle_rpm = float(config.idle_rpm)
    result.redline_rpm = float(config.redline_rpm)
    result.turbo = float(config.turbo_fraction)
    var identity := (vehicle_name+" "+str(config.profile_id)+" "+str(config.variant_label)).to_lower()
    if identity.contains("ranger") or identity.contains("amarok") or identity.contains("tdi"):
        result.label = "four cylinder turbodiesel"
        result.exhaust_cutoff_hz = 1800.0
        result.intake_cutoff_hz = 3600.0
        result.exhaust_resonance_hz = 82.0
        result.exhaust_resonance_decay = 0.018
        result.clatter = 0.22
        result.induction = 0.12
        result.roughness = 0.065
        result.exhaust_partials = PackedFloat32Array([1.0,0.70,0.45,0.36,0.26,0.20,0.16,0.12,0.09,0.07,0.05,0.035])
    elif identity.contains("skyline"):
        result.label = "inline six gasoline"
        result.cylinders = 6
        result.firings_per_revolution = 3.0
        result.exhaust_resonance_hz = 135.0
        result.exhaust_cutoff_hz = 3400.0
        result.clatter = 0.025
        result.roughness = 0.012
        result.exhaust_partials = PackedFloat32Array([1.0,0.42,0.23,0.15,0.10,0.07,0.05,0.035,0.02])
    elif identity.contains("impreza"):
        result.label = "flat four gasoline"
        result.exhaust_resonance_hz = 95.0
        result.roughness = 0.10
        result.exhaust_partials = PackedFloat32Array([1.0,0.37,0.52,0.20,0.25,0.13,0.12,0.07,0.06,0.03])
    elif identity.contains("rx-7"):
        # A two-rotor Wankel has two combustion events per eccentric-shaft
        # revolution. It must not inherit a fictional six-cylinder firing rate.
        result.label = "two rotor gasoline"
        result.cylinders = 0
        result.firings_per_revolution = 2.0
        result.exhaust_resonance_hz = 155.0
        result.exhaust_cutoff_hz = 4500.0
        result.clatter = 0.015
        result.roughness = 0.09
        result.exhaust_partials = PackedFloat32Array([1.0,0.62,0.47,0.34,0.25,0.18,0.13,0.10,0.075,0.05,0.035,0.025])
    return result
