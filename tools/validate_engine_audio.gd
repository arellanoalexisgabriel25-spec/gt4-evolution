extends SceneTree

# Rendered validation of the exact runtime emitters. A deliberate main-thread
# stall verifies that synthesis no longer depends on the graphics frame rate.
const Audio = preload("res://scripts/engine_audio.gd")
const Model = preload("res://scripts/manual_powertrain.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks+=1
    if not ok:
        failed=true
        push_error(message)

func skips(emitters: Array) -> Vector2i:
    return Vector2i(emitters[0].playback.get_skips(),emitters[1].playback.get_skips())

func _initialize() -> void: call_deferred("run")

func run() -> void:
    if DisplayServer.get_name()=="headless":
        push_error("Spatial audio validation needs a rendered display and the Dummy audio driver")
        quit(1)
        return
    Engine.max_fps=60
    root.get_node("GameSession").menu_music.set_menu_active(false)
    var source:=Node3D.new()
    root.add_child(source)
    var camera:=Camera3D.new()
    camera.position=Vector3(0,2,6)
    source.add_child(camera)
    camera.current=true
    var emitters:Array=[]
    for name in ["Fiat 147 Vivace","Nissan Skyline"]:
        var emitter=Audio.new()
        emitter.model=Model.new()
        emitter.model.rpm=3500.0
        emitter.model.throttle=0.9
        emitter.vehicle_model=name
        emitter.source_actor=source
        source.add_child(emitter)
        emitter.doppler_tracking=AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
        emitters.append(emitter)
    camera.doppler_tracking=Camera3D.DOPPLER_TRACKING_DISABLED
    await create_timer(0.5).timeout
    check(emitters[0].playback!=null and emitters[1].playback!=null,"Both spatial generator voices actually start")
    check(emitters[0].statistics().producer_started and emitters[1].statistics().producer_started,"Each generator uses one independent audio producer")
    var startup:=skips(emitters)
    var before:=startup
    await create_timer(0.7).timeout
    var disabled_delta:=skips(emitters)-before
    check(disabled_delta==Vector2i.ZERO,"Steady audio has zero new underruns with Doppler disabled")
    for emitter in emitters: emitter.doppler_tracking=AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
    camera.doppler_tracking=Camera3D.DOPPLER_TRACKING_IDLE_STEP
    await create_timer(0.2).timeout
    before=skips(emitters)
    await create_timer(0.7).timeout
    var doppler_delta:=skips(emitters)-before
    check(doppler_delta==Vector2i.ZERO,"Steady audio has zero new underruns with Doppler enabled")
    before=skips(emitters)
    OS.delay_msec(500)
    var stall_delta:=skips(emitters)-before
    check(stall_delta==Vector2i.ZERO,"A 500 ms main-thread stall cannot starve either engine generator")
    for emitter in emitters: emitter.stream_paused=true
    await create_timer(0.06).timeout
    var paused_generated:=Vector2i(emitters[0].statistics().generated_frames,emitters[1].statistics().generated_frames)
    await create_timer(0.15).timeout
    check(paused_generated==Vector2i(emitters[0].statistics().generated_frames,emitters[1].statistics().generated_frames),"Paused engine producers stop advancing their sample clocks")
    before=skips(emitters)
    for emitter in emitters: emitter.stream_paused=false
    await create_timer(0.3).timeout
    check(skips(emitters)==before,"Pause/resume does not add audio underruns")
    check(emitters[0].statistics().generated_frames>paused_generated.x and emitters[1].statistics().generated_frames>paused_generated.y,"Both engines resume producing samples")
    before=skips(emitters)
    source.position.x+=5.0
    await create_timer(0.2).timeout
    check(skips(emitters)==before,"A source/listener alignment teleport does not starve the audio stream")
    check(emitters[0].global_position.distance_to(source.global_position)<2.0 and emitters[0].doppler_tracking==AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP,"The emitter follows the real source and restores tracking after teleport reset")
    print("Spatial audio evidence: startup ",startup,"; no-Doppler ",disabled_delta,"; Doppler ",doppler_delta,"; 500ms-stall ",stall_delta,"; final ",skips(emitters))
    source.queue_free()
    await process_frame
    await process_frame
    await create_timer(0.2).timeout
    if not failed: print("PASS: %d spatial engine audio assertions"%checks)
    quit(1 if failed else 0)
