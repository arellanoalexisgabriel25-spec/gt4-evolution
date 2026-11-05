extends SceneTree
const Model=preload("res://scripts/manual_powertrain.gd")
const Clutch=preload("res://scripts/manual_clutch.gd")
var checks:=0
var failed:=false
func check(ok:bool,message:String)->void:
    checks+=1
    if not ok:
        failed=true
        push_error(message)
func wait_shift(model)->void:
    for i in range(180):
        model.step(1.0/120.0,1.0,1.0,0.0)
        if model.shift_timer<=0:break
func _initialize()->void:
    var car=Model.new()
    car.throttle=1
    car.rpm=6000
    check(car.request_shift(1,1) and car.gear==1,"Clutch plus held full throttle selects first independently of free engine RPM")
    var before:float=car.rpm
    car.step(1.0/480.0,1,1,0)
    check(car.rpm>5000 and car.rpm>=before-100,"Selecting a gear never teleports the crankshaft to wheel RPM")
    wait_shift(car)
    check(car.request_shift(1,1) and car.gear==2,"A synchronized gearbox accepts another WOT clutch upshift")
    wait_shift(car)
    check(car.request_shift(-1,1) and car.gear==1,"Held throttle is also legal with clutch during a downshift")
    var reverse=Model.new()
    check(reverse.shift(-1,1) and reverse.gear==-1,"Down from neutral deliberately selects real reverse")
    wait_shift(reverse)
    for i in range(240):reverse.step(1.0/120.0,0.45,0,0)
    check(reverse.speed_mps< -1 and reverse.axles.omega.y<0,"Negative reverse gearing sends actual torque and wheel rotation backward")
    check(reverse.shift(1,1) and reverse.gear==0,"A rolling reverse car can disengage safely into neutral")
    wait_shift(reverse)
    check(not reverse.shift(1,1) and reverse.gear==0,"Forward gear rejects significant opposite-direction motion")
    var forward=Model.new()
    forward.speed_mps=20
    check(not forward.shift(-1,1) and forward.gear==0 and forward.missed_shifts==1,"A moving forward car cannot select reverse; rejection is mechanical feedback")
    var cold=Clutch.new()
    var config=car.config
    var initial:float=cold.capacity_factor(config)
    for i in range(120):cold.step(0.1,150000.0,0,config)
    check(cold.temperature>config.clutch_fade_start_c and cold.capacity_factor(config)<initial and cold.wear_points>0.1,"Dissipated slip energy burns the pack, reduces torque capacity and wears it")
    var thermal_config = config.duplicate()
    thermal_config.clutch_cooling_w_per_k = 0.0
    var insulated = Clutch.new()
    insulated.step(2.0,13000.0,0.0,thermal_config)
    check(absf(insulated.temperature-(20.0+13000.0/thermal_config.clutch_heat_capacity))<0.0000001,"An insulated clutch heats by dissipated joules divided by thermal capacity even with zero cooling")
    var held_temperature: float = insulated.temperature
    var held_wear: float = insulated.wear_points
    check(insulated.step(0.0,13000.0,0.0,thermal_config)==0.0 and insulated.step(-1.0,13000.0,0.0,thermal_config)==0.0,"Nonpositive time cannot create heat or wear")
    check(insulated.step(0.1,INF,0.0,thermal_config)==0.0 and insulated.step(0.1,13000.0,NAN,thermal_config)==0.0 and insulated.temperature==held_temperature and insulated.wear_points==held_wear,"Invalid thermal samples leave the finite clutch state unchanged")
    thermal_config.clutch_cooling_w_per_k = config.clutch_cooling_w_per_k
    var cooled = Clutch.new()
    cooled.step(10.0,65000.0,0.0,thermal_config)
    var thermal_decay: float = exp(-thermal_config.clutch_cooling_w_per_k*10.0/thermal_config.clutch_heat_capacity)
    var expected_temperature: float = 20.0+65000.0/(10.0*thermal_config.clutch_cooling_w_per_k)*(1.0-thermal_decay)
    check(absf(cooled.temperature-expected_temperature)<0.0000001,"Finite cooling matches the analytic constant-power thermal solution")
    cooled.temperature = 400.0
    cooled.step(1.0,0.0,0.0,thermal_config)
    check(absf(cooled.temperature-(20.0+380.0*exp(-thermal_config.clutch_cooling_w_per_k/thermal_config.clutch_heat_capacity)))<0.0000001,"Zero slip work cools a hot clutch toward ambient without generating heat")
    car.clutch_pack.temperature=cold.temperature
    car.wear.transmision=12
    var temp:float=car.clutch_temperature
    car.reset()
    check(car.clutch_temperature==temp and car.clutch_health<100,"Recovery retains clutch heat and persistent transmission wear")
    var raw=Model.new()
    raw.gear=2;raw.speed_mps=25;raw.wheel_omega=25/raw.config.wheel_radius
    raw.rpm=1500;raw.pending_engagement=true
    var assisted=Model.new()
    assisted.gear=2;assisted.speed_mps=25;assisted.wheel_omega=25/assisted.config.wheel_radius
    assisted.rpm=1500;assisted.pending_engagement=true;assisted.auto_rev_match=true
    for i in range(30):
        raw.step(1.0/120.0,0,1,1)
        assisted.step(1.0/120.0,0,1,1)
    check(assisted.rpm>raw.rpm+100 and assisted.throttle>0 and assisted.speed_mps<25,"Rev matching blips real engine torque while brakes and clutch remain independent")
    var abusive=Model.new()
    abusive.gear=1;abusive.speed_mps=55;abusive.wheel_omega=55/abusive.config.wheel_radius
    abusive.rpm=6500;abusive.clutch_engagement=1
    for i in range(180):abusive.step(1.0/120.0,0,0,0)
    check(abusive.wear.motor>0.1,"A forced low gear mechanically over-revs and damages the engine despite fuel cut")
    var automatic=Model.new()
    automatic.shift_mode="auto_clutch"
    check(automatic.request_shift(1,0),"Optional auto-clutch accepts a lever command without a clutch pedal")
    for i in range(240):automatic.step(1.0/120.0,0.7,0,0)
    check(automatic.speed_mps>1 and automatic.gear==1,"Assisted clutch still launches through real finite coupling and tire forces")
    for persisted_damage in [false,true]:
        var exhausted = Model.new()
        if persisted_damage: exhausted.wear.transmision = 100.0
        else: exhausted.config.transmission_health = 0.0
        exhausted.shift(1,1.0)
        wait_shift(exhausted)
        var peak_wheel_torque := 0.0
        for i in range(240):
            exhausted.step(1.0/120.0,1.0,0.0,0.0)
            peak_wheel_torque = maxf(peak_wheel_torque,absf(exhausted.wheel_torque_nm))
        check(exhausted.clutch_health==0.0 and peak_wheel_torque==0.0 and exhausted.speed_mps==0.0,"An exhausted manual clutch transmits no power after two seconds of first-gear full throttle, from either saved condition or session wear")
        check(exhausted.rpm>5000.0 and exhausted.engine_running,"A burned clutch lets the independently running engine rev without inventing vehicle propulsion")
    var healthy = Model.new()
    var worn_plate = Model.new()
    worn_plate.config.transmission_health = 5.0
    for candidate in [healthy,worn_plate]:
        candidate.shift(1,1.0)
        wait_shift(candidate)
        candidate.clutch_engagement = 1.0
        candidate.rpm = 6500.0
        candidate.step(1.0/480.0,1.0,0.0,0.0)
    check(healthy.wheel_torque_nm>worn_plate.wheel_torque_nm*2.0 and worn_plate.wheel_torque_nm>0.0 and worn_plate.clutch_loss_kw>0.0,"A partially worn plate still slips and transmits reduced torque; a healthy clutch retains full rated capacity")
    if not failed:print("PASS: %d manual realism assertions"%checks)
    quit(1 if failed else 0)
