extends Node

signal track_changed(id: String)
const Playlist = preload("res://scripts/menu_playlist.gd")
const TRACK_PATH := "res://assets/audio/menu_track.mp3"
const TITLE := "Lezcano Alan — PERRA #Ritmomanijero · Prod Sketchy"
var player: AudioStreamPlayer
var active := false
var volume := 0.35
var gain := 0.0
var resume_position := 0.0
var track: AudioStream
var track_index := 0
var shuffle := false
var random := RandomNumberGenerator.new()
var remaining: Array[int] = []

func _ready() -> void:
    player = AudioStreamPlayer.new()
    random.randomize()
    player.volume_db = -80.0
    add_child(player)
    player.finished.connect(_advance_finished)
    select_track("perra")

func title() -> String:
    return str(Playlist.SONGS[track_index].title)

func track_id() -> String:
    return str(Playlist.SONGS[track_index].id)

func select_track(id: String) -> bool:
    var index := Playlist.index_of(id)
    if index<0: return false
    if track!=null and index==track_index: return true
    var stream := load(Playlist.path_at(index)) as AudioStream
    if stream==null: return false
    player.stop()
    track_index = index
    track = stream
    var song = stream.duplicate()
    # End-of-track advances the playlist, including in sequential mode.
    song.loop = false
    player.stream = song
    resume_position = 0.0
    remaining.erase(index)
    set_menu_active(active)
    track_changed.emit(track_id())
    return true

func set_shuffle(value: bool) -> void:
    shuffle = value
    remaining.clear()

func advance(direction: int = 1) -> void:
    var index := posmod(track_index+(1 if direction>=0 else -1),Playlist.SONGS.size())
    if shuffle and direction>=0:
        if remaining.is_empty():
            for i in range(Playlist.SONGS.size()):
                if i!=track_index: remaining.append(i)
        var pick := random.randi_range(0,remaining.size()-1)
        index = remaining[pick]
        remaining.remove_at(pick)
    select_track(str(Playlist.SONGS[index].id))

func _advance_finished() -> void:
    advance()

func set_menu_active(value: bool) -> void:
    active = value
    if active and volume>0 and not player.playing and DisplayServer.get_name()!="headless":
        player.play(resume_position)

func set_volume(value: float) -> void:
    if not is_finite(value): return
    volume = clampf(value,0,1)
    if active:
        set_menu_active(true)

func _process(delta: float) -> void:
    var target := volume if active else 0.0
    gain = move_toward(gain,target,maxf(delta,0)*2.0)
    player.volume_db = linear_to_db(maxf(gain,0.0001))
    if gain<=0.0001 and player.playing:
        resume_position = fmod(player.get_playback_position(),maxf(track.get_length(),0.001))
        player.stop()

func _exit_tree() -> void:
    if is_instance_valid(player):
        player.stop()
