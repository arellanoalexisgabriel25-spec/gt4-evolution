extends SceneTree

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
    session.reset()
    var music = session.menu_music
    check(music.track!=null and music.track.get_length()>128 and music.track.get_length()<130,"The supplied MP3 actually loads and decodes with its expected duration")
    check(FileAccess.get_sha256(music.TRACK_PATH)=="d109a76148ab20504ffbfc07cec643c9c44a95d57a165a53dcd07694a56a08aa","The packaged menu track retains the user's original bytes")
    check(music.player.stream.loop,"Menu music repeats using the real MP3 stream loop flag")
    change_scene_to_file("res://scenes/main.tscn")
    await process_frame
    await process_frame
    check(music.active,"The actual home scene activates menu music")
    var same_player = music.player
    current_scene._change_tab("mercado")
    current_scene._change_tab("taller")
    check(music.active and music.player==same_player,"Navigation keeps the same music player instead of restarting the track per tab")
    var path := "user://music-settings-%d.json" % Time.get_ticks_usec()
    current_scene.controls_path = path
    current_scene._change_tab("ajustes")
    current_scene._set_music_volume(0.25)
    check(session.controls.music_volume==0.25 and music.volume==0.25 and current_scene.music_label.text.contains("25%"),"The settings control changes the actual independent music volume and visible value")
    var loaded = Settings.new()
    check(loaded.load_file(path) and loaded.music_volume==0.25,"Music preferences survive the existing settings file path")
    var before: String = FileAccess.get_file_as_string(path)
    loaded.music_volume = NAN
    check(loaded.save_file(path)!=OK and FileAccess.get_file_as_string(path)==before,"Invalid audio preferences cannot overwrite the last valid file")
    session.game.buy(1)
    session.start_drag(1)
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    check(not music.active,"Entering the real quarter-mile scene fades the menu track out")
    for i in range(30):
        await process_frame
    check(music.gain<0.001,"Track gain reaches silence during driving")
    current_scene._back_to_garage()
    await process_frame
    await process_frame
    check(music.active and music.player==same_player,"Returning to the garage resumes the persistent menu player")
    current_scene.controls_path = path
    current_scene._set_music_volume(0)
    for i in range(30):
        await process_frame
    check(music.gain<0.001 and not music.player.playing,"Zero volume genuinely stops playback after the fade")
    DirAccess.remove_absolute(path)
    if not failed:
        print("PASS: %d menu music assertions" % checks)
    quit(1 if failed else 0)
