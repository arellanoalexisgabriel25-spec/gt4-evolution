extends RefCounted

# Deterministic original procedural engine. The audio clock advances combustion
# phase continuously; a render-frame update never restarts a waveform. Harmonic
# mip tables limit partials below Nyquist and keep GDScript work bounded per sample.
const Profile = preload("res://scripts/engine_sound_profile.gd")
const TABLE_SIZE := 1024
const HARMONIC_LIMITS := [1,2,4,8,16]
var profile = Profile.new()
var sample_rate := 44100.0
var rpm := 900.0
var load := 0.0
var running := 0.0
var target_rpm := 900.0
var target_load := 0.0
var target_running := 0.0
var boost := 0.0
var clutch_loss_kw := 0.0
var limiting := false
var crank_phase := 0.0
var firing_phase := 0.0
var turbo_phase := 0.0
var relief_level := 0.0
var _relief_decay := 0.0
var limiter_phase := 0.0
var combustion_events := 0
var cue: Dictionary = {}
var cue_remaining := 0.0
var cue_phase := 0.0
var _random := RandomNumberGenerator.new()
var _exhaust_tables: Array[PackedFloat32Array] = []
var _intake_tables: Array[PackedFloat32Array] = []
var _rpm_alpha := 0.0
var _load_alpha := 0.0
var _run_alpha := 0.0
var _exhaust_alpha := 0.0
var _intake_alpha := 0.0
var _noise_alpha := 0.0
var _rumble_a := 0.0
var _rumble_b := 0.0
var _rumble_input_gain := 0.0
var _exhaust_low := 0.0
var _intake_low := 0.0
var _noise_low := 0.0
var _air_low := 0.0
var _rumble_y1 := 0.0
var _rumble_y2 := 0.0
var _previous_input := 0.0
var _dc_output := 0.0
var _dc_pole := 0.0

func configure(selected_profile, rate: float = 44100.0, seed_value: int = 13) -> void:
    profile = selected_profile
    sample_rate = clampf(rate,22050.0,192000.0)
    rpm = profile.idle_rpm
    target_rpm = rpm
    load = 0.0
    target_load = 0.0
    running = 0.0
    target_running = 0.0
    crank_phase = 0.0
    firing_phase = 0.0
    turbo_phase = 0.0
    relief_level = 0.0
    _relief_decay = exp(-1.0/(0.16*sample_rate))
    limiter_phase = 0.0
    combustion_events = 0
    cue.clear()
    cue_remaining = 0.0
    _exhaust_low = 0.0
    _intake_low = 0.0
    _noise_low = 0.0
    _air_low = 0.0
    _rumble_y1 = 0.0
    _rumble_y2 = 0.0
    _previous_input = 0.0
    _dc_output = 0.0
    _random.seed = seed_value
    _rpm_alpha = 1.0-exp(-1.0/(0.025*sample_rate))
    _load_alpha = 1.0-exp(-1.0/(0.045*sample_rate))
    _run_alpha = 1.0-exp(-1.0/(0.015*sample_rate))
    _exhaust_alpha = 1.0-exp(-TAU*profile.exhaust_cutoff_hz/sample_rate)
    _intake_alpha = 1.0-exp(-TAU*profile.intake_cutoff_hz/sample_rate)
    _noise_alpha = 1.0-exp(-TAU*950.0/sample_rate)
    _dc_pole = exp(-TAU*18.0/sample_rate)
    var radius := exp(-1.0/(maxf(profile.exhaust_resonance_decay,0.001)*sample_rate))
    _rumble_a = 2.0*radius*cos(TAU*profile.exhaust_resonance_hz/sample_rate)
    _rumble_b = -radius*radius
    _rumble_input_gain = (1.0-radius)*0.12
    _exhaust_tables = _build_tables(profile.exhaust_partials)
    _intake_tables = _build_tables(profile.intake_partials)

static func ignition_frequency(engine_rpm: float, events_per_revolution: float) -> float:
    return maxf(0.0,engine_rpm)*maxf(0.0,events_per_revolution)/60.0

func _build_tables(partials: PackedFloat32Array) -> Array[PackedFloat32Array]:
    var result: Array[PackedFloat32Array] = []
    # Keep one normalization for every mip: crossing the harmonic cutoff does
    # not turn the fundamental up as high-frequency partials disappear.
    var total := 0.0
    for weight in partials: total += absf(weight)
    total = maxf(total,1.0)
    for limit in HARMONIC_LIMITS:
        var table := PackedFloat32Array()
        table.resize(TABLE_SIZE+1)
        for index in range(TABLE_SIZE):
            var angle := TAU*float(index)/TABLE_SIZE
            var value := 0.0
            for harmonic in range(mini(limit,partials.size())):
                value += partials[harmonic]*sin(angle*float(harmonic+1)+0.035*float(harmonic%3))/total
            table[index] = value
        table[TABLE_SIZE] = table[0]
        result.append(table)
    return result

func _table(tables: Array[PackedFloat32Array], phase: float, frequency: float) -> float:
    var allowed := sample_rate*0.42/maxf(frequency,0.001)
    var selected := 4 if allowed>=16.0 else (3 if allowed>=8.0 else (2 if allowed>=4.0 else (1 if allowed>=2.0 else 0)))
    var table: PackedFloat32Array = tables[selected]
    var position := phase*TABLE_SIZE
    var first := clampi(int(position),0,TABLE_SIZE-1)
    return lerpf(table[first],table[first+1],position-first)

func set_state(engine_rpm: float, throttle: float, is_running: bool, fuel_cut: bool, pressure: float = 0.0, friction_kw: float = 0.0) -> void:
    target_rpm = clampf(engine_rpm,0.0,50000.0) if is_finite(engine_rpm) else 0.0
    var next_load := clampf(throttle,0.0,1.0) if is_finite(throttle) else 0.0
    if profile.turbo>0.0 and target_load>0.55 and next_load<0.25 and boost>0.12 and is_running:
        relief_level = maxf(relief_level,boost*minf(profile.turbo*3.0,1.0))
    target_load = next_load
    target_running = 1.0 if is_running else 0.0
    limiting = fuel_cut
    boost = clampf(pressure,0.0,1.0) if is_finite(pressure) else 0.0
    clutch_loss_kw = clampf(friction_kw,0.0,300.0) if is_finite(friction_kw) else 0.0

func trigger(event: Dictionary) -> void:
    if event.is_empty(): return
    cue = event.duplicate()
    cue_remaining = maxf(0.0,float(event.get("duration",0.0)))
    cue_phase = 0.0

func sample() -> float:
    if _exhaust_tables.is_empty(): configure(profile,sample_rate)
    rpm = lerpf(rpm,target_rpm,_rpm_alpha)
    load = lerpf(load,target_load,_load_alpha)
    running = lerpf(running,target_running,_run_alpha)
    var crank_hz := rpm/60.0
    var ignition_hz := ignition_frequency(rpm,profile.firings_per_revolution)
    crank_phase = fposmod(crank_phase+crank_hz/sample_rate,1.0)
    var next_phase := firing_phase+ignition_hz/sample_rate
    if next_phase>=1.0: combustion_events+=1
    firing_phase = fposmod(next_phase,1.0)
    limiter_phase = fposmod(limiter_phase+13.0/sample_rate,1.0)
    var cut := 0.08 if limiting and limiter_phase<0.52 else 1.0
    var random_value := _random.randf_range(-1.0,1.0)
    _noise_low = lerpf(_noise_low,random_value,_noise_alpha)
    _air_low = lerpf(_air_low,random_value,_intake_alpha)
    var high_noise := _air_low-_noise_low
    var crank := sin(crank_phase*TAU)
    var irregularity: float = 1.0+profile.roughness*crank
    var exhaust := _table(_exhaust_tables,firing_phase,ignition_hz)*irregularity
    # Air charge adds high harmonics and intake only under throttle. A closed
    # throttle retains the lower engine-braking pulse rather than becoming mute.
    var charge := (0.20+0.80*load)*running*cut
    exhaust *= charge
    _exhaust_low = lerpf(_exhaust_low,exhaust,_exhaust_alpha)
    var rumble := _rumble_input_gain*exhaust+_rumble_a*_rumble_y1+_rumble_b*_rumble_y2
    _rumble_y2 = _rumble_y1
    _rumble_y1 = rumble
    var intake := _table(_intake_tables,fposmod(firing_phase+0.18,1.0),ignition_hz)*load*running
    _intake_low = lerpf(_intake_low,intake,_intake_alpha)
    var rev_fraction := clampf(rpm/maxf(profile.redline_rpm,1.0),0.0,1.5)
    var pulse_gate := 0.4+0.6*maxf(0.0,exhaust)
    var mechanical: float = high_noise*profile.clatter*pulse_gate*(0.3+0.7*rev_fraction)*running
    var air: float = high_noise*profile.induction*load*load*running
    var turbo_hz := minf(1800.0+5000.0*sqrt(boost)+rpm*0.08,sample_rate*0.40)
    turbo_phase = fposmod(turbo_phase+turbo_hz/sample_rate,1.0)
    var turbo_tone: float = (sin(turbo_phase*TAU)*0.060+high_noise*0.045)*boost*minf(profile.turbo*3.0,1.0)*running
    var relief := high_noise*relief_level*0.11*running
    relief_level *= _relief_decay
    var friction := high_noise*sqrt(clutch_loss_kw/300.0)*0.018
    var value: float = _exhaust_low*1.35+rumble*0.22+_intake_low*0.25+mechanical+air+turbo_tone+relief+friction
    value += crank*0.018*rev_fraction*running
    if cue_remaining>0.0:
        cue_phase = fposmod(cue_phase+float(cue.get("frequency",800.0))/sample_rate,1.0)
        var fraction := clampf(cue_remaining/maxf(float(cue.get("duration",0.1)),0.001),0.0,1.0)
        var attack := minf(1.0,(1.0-fraction)*30.0)
        var envelope := attack*fraction
        value += lerpf(sin(cue_phase*TAU),high_noise,float(cue.get("noise",0.0)))*float(cue.get("gain",0.0))*envelope
        cue_remaining = maxf(0.0,cue_remaining-1.0/sample_rate)
    # A DC blocker removes asymmetric envelope offsets; soft saturation bounds
    # extreme combined transients without hard clipping the output waveform.
    _dc_output = value-_previous_input+_dc_pole*_dc_output
    _previous_input = value
    return _dc_output/(1.0+absf(_dc_output))

func render(frames: int) -> PackedVector2Array:
    var output := PackedVector2Array()
    output.resize(maxi(0,frames))
    for index in range(output.size()):
        var value := sample()
        output[index] = Vector2(value,value)
    return output
