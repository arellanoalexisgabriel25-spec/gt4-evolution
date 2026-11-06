extends AudioStreamPlayer3D

# A single producer fills the generator independently of rendering. It receives
# immutable telemetry snapshots; only the main thread reads the scene/physics.
# Stop and join the producer before releasing playback during scene teardown.
const Feedback = preload("res://scripts/transmission_feedback.gd")
const Profile = preload("res://scripts/engine_sound_profile.gd")
const Synth = preload("res://scripts/engine_sound_synth.gd")
const SAMPLE_RATE := 44100.0
const AUDIO_BLOCK := 512
var model
var source_actor: Node3D
var vehicle_model := ""
var playback: AudioStreamGeneratorPlayback
var feedback = Feedback.new()
var synth = Synth.new()
var _producer := Thread.new()
var _mailbox := Mutex.new()
var _telemetry: Dictionary = {}
var _pending_events: Array[Dictionary] = []
var _producer_quit := false
var _producer_paused := false
var _generated_frames := 0
var _last_free_frames := 0
var _source_initialized := false
var _previous_source_position := Vector3.ZERO

func _ready() -> void:
    if model!=null and model.config!=null:
        synth.configure(Profile.from_vehicle(model.config,vehicle_model),SAMPLE_RATE)
    if DisplayServer.get_name() == "headless":
        set_process(false)
        set_physics_process(false)
        return
    unit_size = 6.0
    max_distance = 160.0
    max_db = 0.0
    attenuation_filter_cutoff_hz = 6500.0
    doppler_tracking = DOPPLER_TRACKING_PHYSICS_STEP
    # Chase translation runs on the render clock. Tracking the moving listener
    # prevents a following camera from hearing a false approach of its own car.
    var listener := get_viewport().get_camera_3d()
    if listener!=null: listener.doppler_tracking = Camera3D.DOPPLER_TRACKING_IDLE_STEP
    volume_db = -10.0
    var generator := AudioStreamGenerator.new()
    generator.mix_rate = SAMPLE_RATE
    # The Dummy driver pulls 4096 source frames per mix. The rounded 4095-slot
    # ring from 0.08 s cannot hold even one complete pull and loses a sample on
    # each callback. 0.12 s creates an 8191-slot ring, leaving refill headroom.
    generator.buffer_length = 0.12
    stream = generator
    play()
    playback = get_stream_playback()
    _physics_process(0.0)
    # Prefill on the main thread before handing the ring to its sole producer.
    _apply_snapshot()
    var frames := playback.get_frames_available()
    if frames>0 and playback.push_buffer(synth.render(frames)): _generated_frames+=frames
    _producer.start(_produce_audio)

func _physics_process(_delta: float) -> void:
    if is_instance_valid(source_actor):
        var offset := Vector3(0,0.5,-0.8)
        if model!=null and model.config!=null and model.config.engine_position in ["rear","mid"]:
            offset.z = 0.65 if model.config.engine_position=="rear" else 0.25
        var point: Vector3 = source_actor.global_position+source_actor.global_basis*offset
        if _source_initialized and point.distance_to(_previous_source_position)>2.5:
            # Alignment/recovery are teleports, not a measured vehicle velocity.
            doppler_tracking = DOPPLER_TRACKING_DISABLED
            global_position = point
            doppler_tracking = DOPPLER_TRACKING_PHYSICS_STEP
            var listener := get_viewport().get_camera_3d()
            if listener!=null:
                var tracking: int = listener.doppler_tracking
                listener.doppler_tracking = Camera3D.DOPPLER_TRACKING_DISABLED
                listener.doppler_tracking = tracking
        else:
            global_position = point
        _source_initialized = true
        _previous_source_position = point
    _submit_snapshot()

func _process(_delta: float) -> void:
    _submit_snapshot()

func _submit_snapshot() -> void:
    if model==null: return
    var pressure := 0.0
    if model.engine!=null: pressure=float(model.engine.boost)
    var state := {"rpm":float(model.rpm),"load":float(model.throttle),"running":bool(model.engine_running),"limiter":bool(model.limiter),"boost":pressure,"clutch_loss":float(model.clutch_loss_kw)}
    var event: Dictionary = feedback.observe(model)
    _mailbox.lock()
    _telemetry = state
    _producer_paused = stream_paused
    if not event.is_empty(): _pending_events.append(event)
    _mailbox.unlock()

func _apply_snapshot() -> bool:
    _mailbox.lock()
    var finish := _producer_quit
    var paused := _producer_paused
    var state := _telemetry.duplicate()
    var events := _pending_events
    _pending_events = []
    _mailbox.unlock()
    if finish: return false
    if not state.is_empty():
        synth.set_state(state.rpm,state.load,state.running,state.limiter,state.boost,state.clutch_loss)
    for event in events: synth.trigger(event)
    return not paused

func _produce_audio() -> void:
    while true:
        _mailbox.lock()
        var finish := _producer_quit
        _mailbox.unlock()
        if finish: return
        if not _apply_snapshot():
            OS.delay_usec(2000)
            continue
        var free := playback.get_frames_available()
        var frames := mini(free,AUDIO_BLOCK)
        if frames>=128:
            var written := playback.push_buffer(synth.render(frames))
            _mailbox.lock()
            _last_free_frames = free
            if written: _generated_frames+=frames
            _mailbox.unlock()
        else:
            OS.delay_usec(2000)

func statistics() -> Dictionary:
    _mailbox.lock()
    var result := {"generated_frames":_generated_frames,"free_frames":_last_free_frames,"producer_started":_producer.is_started()}
    _mailbox.unlock()
    result["skips"] = playback.get_skips() if playback!=null else 0
    return result

func _exit_tree() -> void:
    _mailbox.lock()
    _producer_quit = true
    _mailbox.unlock()
    if _producer.is_started(): _producer.wait_to_finish()
    stop()
    playback = null
