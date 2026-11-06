extends SceneTree

# Offline presentation examples from the exact runtime synth. RPM sweeps below
# are an acoustic demonstration, not a vehicle acceleration or dyno measurement.
const Config=preload("res://scripts/drag_vehicle_config.gd")
const Profile=preload("res://scripts/engine_sound_profile.gd")
const Synth=preload("res://scripts/engine_sound_synth.gd")
const Feedback=preload("res://scripts/transmission_feedback.gd")
const RATE:=44100
const DURATION:=7.0
func _initialize()->void: call_deferred("run")
func run()->void:
    var args:=OS.get_cmdline_user_args()
    if args.size()!=1:
        push_error("Pass one output directory after --")
        quit(1)
        return
    var output:=args[0]
    DirAccess.make_dir_recursive_absolute(output)
    var records:Array=[]
    for entry in [["Fiat 147 Vivace","gasoline_four"],["Volkswagen Amarok","turbodiesel_four"],["Nissan Skyline","gasoline_six"],["Mazda RX-7","two_rotor"]]:
        var config=Config.from_vehicle({"model":entry[0],"health":{"motor":100,"transmision":100,"neumaticos":100,"frenos":100}},true)
        var synth=Synth.new()
        synth.configure(Profile.from_vehicle(config,entry[0]),RATE)
        var frames:=PackedVector2Array()
        var started:=Time.get_ticks_usec()
        for block in range(int(DURATION*60)):
            var seconds:=float(block)/60.0
            var sweep:=clampf((seconds-0.75)/3.75,0.0,1.0)
            var revs:=lerpf(config.idle_rpm,config.redline_rpm*1.01,sweep)
            var load:=0.06 if seconds<0.75 else (0.9 if seconds<4.6 else 0.0)
            if seconds>5.3:
                revs=lerpf(config.redline_rpm,config.idle_rpm,clampf((seconds-5.3)/1.7,0.0,1.0))
                load=0.1
            synth.set_state(revs,load,true,seconds>4.2 and seconds<4.6,config.turbo_fraction*sweep,0.0)
            if block==288: synth.trigger(Feedback.CUES.acceptable)
            if block==360: synth.trigger(Feedback.CUES.rejected)
            frames.append_array(synth.render(RATE/60))
        var cpu_seconds:=float(Time.get_ticks_usec()-started)/1000000.0
        var data:=PackedByteArray()
        data.resize(frames.size()*4)
        var peak:=0.0
        var sum_squares:=0.0
        for index in range(frames.size()):
            var value:=frames[index].x
            peak=maxf(peak,absf(value))
            sum_squares+=value*value
            var integer:=int(round(clampf(value,-1,1)*32767.0))
            data.encode_s16(index*4,integer)
            data.encode_s16(index*4+2,integer)
        var stream:=AudioStreamWAV.new()
        stream.format=AudioStreamWAV.FORMAT_16_BITS
        stream.mix_rate=RATE
        stream.stereo=true
        stream.data=data
        var file:=output.path_join(entry[1]+".wav")
        if stream.save_to_wav(file)!=OK:
            push_error("Could not save "+file)
            quit(1)
            return
        records.append({"model":entry[0],"file":file,"sample_rate":RATE,"frames":frames.size(),"cpu_seconds":cpu_seconds,"peak":peak,"rms":sqrt(sum_squares/frames.size()),"source":"original_procedural_synth_not_a_recording_or_acceleration_test"})
        print("Rendered ",entry[0]," / ",DURATION," s in ",cpu_seconds," s CPU; peak ",peak)
    var report:=FileAccess.open(output.path_join("audio-verification.json"),FileAccess.WRITE)
    report.store_string(JSON.stringify(records,"  "))
    report.close()
    print("PASS: four original 44.1 kHz engine demonstrations written")
    quit(0)
