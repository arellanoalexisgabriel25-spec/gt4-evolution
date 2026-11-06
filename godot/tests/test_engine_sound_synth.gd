extends SceneTree

const Profile = preload("res://scripts/engine_sound_profile.gd")
const Synth = preload("res://scripts/engine_sound_synth.gd")
const Config = preload("res://scripts/drag_vehicle_config.gd")
const Model = preload("res://scripts/manual_powertrain.gd")
const Audio = preload("res://scripts/engine_audio.gd")
const Feedback = preload("res://scripts/transmission_feedback.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks+=1
    if not ok:
        failed=true
        push_error(message)

func statistics(frames: PackedVector2Array) -> Dictionary:
    var energy := 0.0
    var peak := 0.0
    var mean := 0.0
    var valid := true
    var biggest_step := 0.0
    var before := 0.0
    for value in frames:
        valid = valid and value.is_finite()
        energy+=value.x*value.x
        peak=maxf(peak,absf(value.x))
        mean+=value.x
        biggest_step=maxf(biggest_step,absf(value.x-before))
        before=value.x
    return {"rms":sqrt(energy/maxi(frames.size(),1)),"peak":peak,"mean":mean/maxi(frames.size(),1),"finite":valid,"step":biggest_step}

func voice(name: String, rate: float = 22050.0):
    var config=Config.new()
    var synth=Synth.new()
    synth.configure(Profile.from_vehicle(config,name),rate,77)
    return synth

func _initialize() -> void: call_deferred("run")

func run() -> void:
    var spatial=Audio.new()
    check(spatial is AudioStreamPlayer3D,"Live engine emitters use Godot spatial distance and Doppler rather than two centered sounds")
    spatial.free()
    var four=voice("Fiat 147 Vivace")
    var six=voice("Nissan Skyline")
    var diesel=voice("Volkswagen Amarok")
    var rotary=voice("Mazda RX-7")
    check(four.profile.cylinders==4 and six.profile.cylinders==6,"Four and six cylinder layouts select distinct combustion orders")
    check(diesel.profile.clatter>four.profile.clatter and diesel.profile.exhaust_cutoff_hz<four.profile.exhaust_cutoff_hz,"Turbodiesel clatter and lower exhaust filtering differ from gasoline")
    check(rotary.profile.cylinders==0 and rotary.profile.firings_per_revolution==2.0,"Two rotor synthesis uses the correct eccentric-shaft event count instead of fictional cylinders")
    check(Synth.ignition_frequency(3000,2.0)==100.0 and Synth.ignition_frequency(3000,3.0)==150.0,"Four-stroke firing order uses RPM times cylinders / 120 in Hz")
    for engine in [four,six]:
        engine.set_state(3000,0.8,true,false)
        engine.render(11025)
        var before: int=engine.combustion_events
        engine.render(22050)
        var expected := 100 if engine.profile.cylinders==4 else 150
        check(absi(engine.combustion_events-before-expected)<=1,"The actual sample-clock combustion phase emits the expected events in one second")
    var quiet=voice("Fiat 147 Vivace")
    var loaded=voice("Fiat 147 Vivace")
    quiet.set_state(3500,0.0,true,false)
    loaded.set_state(3500,1.0,true,false)
    quiet.render(11025);loaded.render(11025)
    var q:=statistics(quiet.render(11025))
    var l:=statistics(loaded.render(11025))
    check(l.finite and l.peak<1.0 and l.rms>0.03,"Loaded output is finite, audible and strictly below digital clipping")
    check(l.rms>q.rms*1.8 and q.rms>0.001,"Real throttle load is clearly louder than closed-throttle engine braking, which remains audible")
    check(absf(l.mean)<0.01 and absf(q.mean)<0.01,"The DC blocker removes asymmetric pulse-envelope offsets")
    var seeded=voice("Fiat 147 Vivace")
    var another=voice("Fiat 147 Vivace")
    seeded.set_state(4000,0.6,true,false)
    another.set_state(4000,0.6,true,false)
    check(seeded.render(4096)==another.render(4096),"Identical seeded sample streams reproduce exactly for automated audio regression")
    var chunked=voice("Fiat 147 Vivace")
    var whole=voice("Fiat 147 Vivace")
    chunked.set_state(5000,0.9,true,false)
    whole.set_state(5000,0.9,true,false)
    var joined:=chunked.render(1024)
    joined.append_array(chunked.render(3072))
    check(joined==whole.render(4096),"Buffer boundaries do not restart phase, noise, filters or envelopes")
    var previous: float=whole.rpm
    whole.set_state(900,0.0,true,false)
    var tick:=whole.sample()
    check(whole.rpm>900.0 and absf(whole.rpm-previous)<10.0 and is_finite(tick),"An input RPM jump is smoothed on the sample clock without teleporting audio phase")
    var normal=voice("Volkswagen Amarok")
    var cutting=voice("Volkswagen Amarok")
    normal.set_state(4200,1.0,true,false,1.0,300.0)
    cutting.set_state(4200,1.0,true,true,1.0,300.0)
    normal.render(11025);cutting.render(11025)
    var n:=statistics(normal.render(22050))
    var c:=statistics(cutting.render(22050))
    check(c.finite and c.peak<1.0 and c.rms<n.rms*0.9,"Fuel-cut limiter modulates real combustion intensity without clipping turbo/friction layers")
    for layout in ["Fiat 147 Vivace","Nissan Skyline","Mazda RX-7","Volkswagen Amarok"]:
        var extreme=voice(layout)
        extreme.set_state(50000,1.0,true,true,1.0,300.0)
        extreme.trigger(Feedback.CUES.rejected)
        var values:=statistics(extreme.render(8192))
        check(values.finite and values.peak<1.0,"Extreme RPM and grinding/turbo/friction combinations remain finite and bounded for "+layout)
    loaded.set_state(NAN,INF,true,false,NAN,INF)
    var invalid:=statistics(loaded.render(2048))
    check(invalid.finite and loaded.target_rpm==0.0 and loaded.target_load==0.0,"Malformed telemetry cannot poison the audio stream with NaN or infinity")
    var off=voice("Fiat 147 Vivace")
    off.set_state(0.0,0.0,false,false)
    check(statistics(off.render(1024)).peak==0.0,"A stopped silent motor and no mechanical cue produces digital silence")
    var cue=voice("Fiat 147 Vivace")
    cue.trigger(Feedback.CUES.rejected)
    check(statistics(cue.render(1024)).rms>0.001,"Gear-rejection feedback remains audible even when the engine is stopped")
    var unused=Audio.new()
    root.add_child(unused)
    await process_frame
    check(unused.playback==null and not unused.is_processing(),"Headless validation does not create an unused audio playback thread")
    unused.queue_free()
    await process_frame
    print("Audio evidence: loaded RMS ",l.rms," / coasting ",q.rms,"; peak ",l.peak,"; limiter RMS ",c.rms," / full ",n.rms)
    if not failed: print("PASS: %d procedural engine audio assertions"%checks)
    quit(1 if failed else 0)
