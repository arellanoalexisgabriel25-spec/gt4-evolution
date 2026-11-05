extends SceneTree

const Playlist = preload("res://scripts/menu_playlist.gd")
const Settings = preload("res://scripts/control_settings.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var session = root.get_node("GameSession")
    var music = session.menu_music
    var same_player = music.player
    check(Playlist.SONGS.size()==13,"The original and twelve authorized new tracks form the playlist")
    var ids := {}
    var total := 0.0
    for index in range(Playlist.SONGS.size()):
        var id: String = Playlist.SONGS[index].id
        check(not ids.has(id) and Playlist.index_of(id)==index,"Stable unique IDs locate each song")
        ids[id] = true
        check(music.select_track(id),"The actual audio player loads each shipped stream: "+id)
        total += music.track.get_length()
        check(music.track.get_length()>85.0 and music.track.get_length()<220.0 and not music.player.stream.loop,"Each stream decodes a complete song and hands off at its end")
        check(music.player==same_player and music.resume_position==0.0,"Song selection retains one player and starts the new stream at zero")
    check(total>2100.0 and total<2120.0,"The thirteen full songs retain approximately 35 minutes of music")
    music.set_shuffle(false)
    music.player.finished.emit()
    check(music.track_id()=="perra","Finishing the last song wraps the real playlist to the original")
    music.advance(-1)
    check(music.track_id()=="tu_turrito","Previous wraps to the last song")
    music.set_shuffle(true)
    music.random.seed = 22026
    var played := {}
    for index in range(12):
        var previous: String = music.track_id()
        music.advance()
        check(music.track_id()!=previous and not played.has(music.track_id()),"Shuffle avoids immediate repeats and exhausts its bag before refilling")
        played[music.track_id()] = true
    var current: String = music.track_id()
    var stream = music.player.stream
    check(not music.select_track("missing") and music.track_id()==current and music.player.stream==stream,"A missing song cannot corrupt the current player")
    var settings = Settings.new()
    var legacy: Dictionary = settings.to_dict()
    legacy.erase("music_track_id")
    legacy.erase("music_shuffle")
    check(settings.from_dict(legacy) and settings.music_track_id=="perra" and not settings.music_shuffle,"Previous controls_v1 files migrate optional playlist preferences")
    settings.music_track_id = "butakera"
    settings.music_shuffle = true
    var path := "user://playlist-test.json"
    check(settings.save_file(path)==OK,"Playlist preferences use the atomic settings writer")
    var restored = Settings.new()
    check(restored.load_file(path) and restored.music_track_id=="butakera" and restored.music_shuffle,"Song and shuffle survive actual JSON serialization")
    var before: Dictionary = restored.to_dict()
    var corrupt := before.duplicate(true)
    corrupt.music_track_id = "unavailable"
    check(not restored.from_dict(corrupt) and restored.to_dict()==before,"Invalid playlist preferences cannot partially overwrite other controls")
    DirAccess.remove_absolute(path)
    music.set_shuffle(false)
    music.select_track("perra")
    if not failed: print("PASS: %d menu playlist assertions" % checks)
    quit(1 if failed else 0)
