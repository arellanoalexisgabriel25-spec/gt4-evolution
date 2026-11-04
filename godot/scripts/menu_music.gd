extends Node

const TRACK_PATH := "res://assets/audio/menu_track.mp3"
const TITLE := "Lezcano Alan — PERRA #Ritmomanijero · Prod Sketchy"
var player: AudioStreamPlayer
var active := false
var volume := 0.35
var gain := 0.0
var resume_position := 0.0
var track: AudioStreamMP3

func _ready() -> void:
    player = AudioStreamPlayer.new()
    track = load(TRACK_PATH)
    var song = track.duplicate()
    song.loop = true
    player.stream = song
    player.volume_db = -80.0
    add_child(player)

func set_menu_active(value: bool) -> void:
    active = value
    if active and volume>0 and not player.playing and DisplayServer.get_name()!="headless":
        player.play(resume_position)

func set_volume(value: float) -> void:
    volume = clampf(value,0,1)
    if active:
        set_menu_active(true)

func _process(delta: float) -> void:
    var target := volume if active else 0.0
    gain = move_toward(gain,target,maxf(delta,0)*2.0)
    player.volume_db = linear_to_db(maxf(gain,0.0001))
    if gain<=0.0001 and player.playing:
        resume_position = fmod(player.get_playback_position(),track.get_length())
        player.stop()

func _exit_tree() -> void:
    if is_instance_valid(player):
        player.stop()
