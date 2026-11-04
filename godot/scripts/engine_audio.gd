extends AudioStreamPlayer

# Original procedural placeholder: ignition harmonics and load-dependent noise.
# No commercial engine recording is used. Physics never depends on audio state.
var model
var playback: AudioStreamGeneratorPlayback
var phase := 0.0
var noise := RandomNumberGenerator.new()

func _ready() -> void:
    if DisplayServer.get_name() == "headless":
        set_process(false)
        return
    var generator := AudioStreamGenerator.new()
    generator.mix_rate = 22050.0
    generator.buffer_length = 0.12
    stream = generator
    volume_db = -14.0
    noise.seed = 13
    play()
    playback = get_stream_playback()

func _process(_delta: float) -> void:
    if playback == null or model == null:
        return
    var frames := mini(playback.get_frames_available(),4096)
    var frequency: float = model.rpm/30.0
    var load_factor: float = 0.25+model.throttle*0.75
    for i in range(frames):
        phase = fposmod(phase+frequency/22050.0,1.0)
        var tone := sin(phase*TAU)*0.34+sin(phase*TAU*2)*0.17+sin(phase*TAU*4)*0.08
        var value := (tone*load_factor+noise.randf_range(-1,1)*0.04*load_factor)*minf(1,float(model.rpm)/700.0)
        if not model.engine_running:
            value = 0.0
        playback.push_frame(Vector2(value,value))

func _exit_tree() -> void:
    stop()
    playback = null
