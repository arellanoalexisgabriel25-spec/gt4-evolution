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
    var settings = Settings.new()
    check(settings.visual_quality=="balanced" and settings.msaa_level()==Viewport.MSAA_2X,"The default requests 2x MSAA with an explicit balanced quality preference")
    var legacy: Dictionary = settings.to_dict()
    legacy.erase("visual_quality")
    legacy.keys.accelerate=KEY_I
    legacy.shift_mode="auto_clutch"
    legacy.music_volume=0.55
    check(settings.from_dict(legacy) and settings.visual_quality=="balanced" and settings.keys.accelerate==KEY_I and settings.shift_mode=="auto_clutch" and settings.music_volume==0.55,"Older controls migrate to balanced graphics without resetting keys, assists or audio")
    var levels := {"performance":Viewport.MSAA_DISABLED,"balanced":Viewport.MSAA_2X,"high":Viewport.MSAA_4X}
    var path := "user://visual-quality-test.json"
    for quality in Settings.VISUAL_QUALITIES:
        settings.visual_quality=quality
        check(settings.msaa_level()==levels[quality],"Each quality maps to the actual viewport MSAA enum")
        check(settings.save_file(path)==OK,"A valid visual preference writes through the existing atomic controls file")
        var restored = Settings.new()
        check(restored.load_file(path) and restored.to_dict()==settings.to_dict(),"Quality round-trips through actual JSON with all other preferences")
    var before: Dictionary = settings.to_dict().duplicate(true)
    for bad in ["ultra",1,true,null]:
        var corrupt := before.duplicate(true)
        corrupt.visual_quality=bad
        check(not settings.from_dict(corrupt) and settings.to_dict()==before,"Invalid quality cannot partially mutate a valid controls configuration")
    settings.visual_quality="invalid_internal"
    var valid_file := FileAccess.get_file_as_string(path)
    check(settings.save_file(path)!=OK and FileAccess.get_file_as_string(path)==valid_file,"An invalid visual preference cannot replace the last valid controls file")
    settings.restore_defaults()
    check(settings.visual_quality=="balanced","Restoring defaults also restores the explicit quality preference")
    var state = settings.controller
    var axis := InputEventJoypadMotion.new()
    axis.device=0
    axis.axis=JOY_AXIS_TRIGGER_RIGHT
    axis.axis_value=1.0
    state.feed(axis)
    var button := InputEventJoypadButton.new()
    button.device=0
    button.button_index=JOY_BUTTON_LEFT_SHOULDER
    button.pressed=true
    state.feed(button)
    check(state.axis_value(JOY_AXIS_TRIGGER_RIGHT)==1.0 and state.pressed(JOY_BUTTON_LEFT_SHOULDER),"Offline normalized events still support reproducible controller tests")
    state.reset_cached()
    check(state.selected()<0 and state.axis_value(JOY_AXIS_TRIGGER_RIGHT)==0.0 and not state.pressed(JOY_BUTTON_LEFT_SHOULDER),"Focus/reset clearing releases cached synthetic pedals and buttons")
    check(state.feed(button),"Reset also removes a stale memo so a subsequent physical delivery can become a fresh edge")
    DirAccess.remove_absolute(path)
    if not failed: print("PASS: %d visual quality and input reset assertions" % checks)
    quit(1 if failed else 0)
