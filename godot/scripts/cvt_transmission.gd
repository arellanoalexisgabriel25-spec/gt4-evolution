extends RefCounted

# Original continuously variable ratio controller and a simplified hydrodynamic
# converter map. Values require exact gearbox data. Torque multiplication is
# bounded by pump/turbine power; the converter cannot generate shaft power.
var ratio := 3.377
var launch_gear := true
var locked := false
var converter_heat_j := 0.0

func reset(config, keep_heat: bool = true) -> void:
    ratio = config.cvt_launch_ratio
    launch_gear = true
    locked = false
    if not keep_heat: converter_heat_j = 0.0

func advance(dt: float, speed: float, wheel_omega: float, throttle: float, config) -> float:
    if absf(speed)<1.0: launch_gear=true
    if absf(speed)>config.cvt_handover_mps: launch_gear=false
    var target: float = config.cvt_launch_ratio
    if not launch_gear:
        var target_rpm: float = lerpf(config.cvt_cruise_rpm,config.cvt_power_rpm,clampf(throttle,0.0,1.0))
        target = clampf(target_rpm*TAU/60.0/maxf(absf(wheel_omega)*config.final_drive,1.0),config.cvt_min_ratio,config.cvt_max_ratio)
    ratio = move_toward(ratio,target,config.cvt_ratio_rate*dt)
    return ratio

func converter(engine_omega: float, turbine_omega: float, engagement: float, config) -> Dictionary:
    var speed_ratio := clampf(turbine_omega/maxf(engine_omega,0.001),0.0,1.0)
    var multiplier := lerpf(config.converter_stall_multiplier,1.0,clampf(speed_ratio/0.88,0.0,1.0))
    var coefficient: float = config.converter_capacity_factor*(1.0+speed_ratio*1.6)
    var pump: float = minf(config.clutch_capacity,pow(maxf(engine_omega,0.0)/maxf(coefficient,0.1),2.0))*engagement
    var turbine := pump*minf(multiplier,1.0/maxf(speed_ratio,0.001))
    return {"pump_torque":pump,"turbine_torque":turbine,"loss_w":maxf(0.0,pump*engine_omega-turbine*turbine_omega)}
