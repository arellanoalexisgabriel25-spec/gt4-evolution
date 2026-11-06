extends SceneTree
const HUD = preload("res://scripts/drag_hud.gd")
const Model = preload("res://scripts/manual_powertrain.gd")
const Run = preload("res://scripts/drag_run.gd")
const Settings = preload("res://scripts/control_settings.gd")
var checks := 0
var failed := false
func check(ok: bool,message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var hud = HUD.new()
    root.add_child(hud)
    await process_frame
    var model = Model.new()
    var timer = Run.new()
    var settings = Settings.new()
    var raw := {"throttle":1.0,"clutch":0.0,"brake":0.0,"handbrake":0.0}
    var applied := {"throttle":1.0,"clutch":1.0,"brake":1.0,"handbrake":0.0}
    var data := {"model":model,"run":timer,"settings":settings,"name":"Fiat 147 Vivace","position":0.0,"best":{},"staged":true,"message":"","wear_start":{},"procedure_phase":"staging","procedure_remaining":20.0,"raw_controls":raw,"applied_controls":applied}
    hud.refresh(data)
    check(not hud.input_panel.visible,"Normal driving starts with extended pedal diagnosis hidden")
    check(hud.preparation_label.text.contains("ENTRADA") and hud.preparation_label.text.contains("Ctrl"),"Preparation exposes actual pedal reception and an alternate clutch key")
    var event := InputEventKey.new()
    event.physical_keycode = KEY_F3
    event.pressed = true
    Input.parse_input_event(event)
    Input.flush_buffered_events()
    await process_frame
    hud.refresh(data)
    check(hud.input_panel.visible and hud.diagnostics_enabled,"A real F3 event opens the live pedal panel")
    check(hud.input_label.text.contains("ENTRADA   A 100  E   0") and hud.input_label.text.contains("APLICADO  A 100  E 100"),"The display distinguishes a missing physical clutch signal from an assisted command")
    check(hud.input_label.text.contains("C/Ctrl"),"The current binding and nonconflicting fallback are visible")
    check(raw.clutch==0.0 and applied.clutch==1.0 and model.clutch_engagement==0.0,"Diagnosis observes without changing pedals or the physical clutch")
    var bounds := root.get_visible_rect()
    check(bounds.encloses(hud.input_panel.get_global_rect()),"The panel stays inside the player viewport")
    data.paused = true
    hud.diagnostics_enabled = false
    hud.refresh(data)
    check(hud.input_panel.visible,"Pause offers diagnosis without requiring a keyboard F3 on a controller")
    for code in [KEY_W,KEY_CTRL]:
        var pedal:=InputEventKey.new()
        pedal.physical_keycode=code
        pedal.pressed=true
        Input.parse_input_event(pedal)
    Input.flush_buffered_events()
    hud.refresh(data)
    check(hud.input_label.text.contains("ENTRADA   A 100  E 100") and model.clutch_engagement==0.0,"Paused diagnostics read new physical pedal input without advancing frozen mechanics")
    for code in [KEY_W,KEY_CTRL]:
        var pedal:=InputEventKey.new()
        pedal.physical_keycode=code
        pedal.pressed=false
        Input.parse_input_event(pedal)
    Input.flush_buffered_events()
    check(not hud.input_panel.get_global_rect().intersects(hud.details_panel.get_global_rect()),"Input and mechanical diagnostics do not overlap")
    data.paused = false
    timer.phase = "running"
    hud.refresh(data)
    check(not hud.input_panel.visible and not hud.preparation_panel.visible,"The race returns to compact instruments when diagnosis is disabled")
    hud.queue_free()
    await process_frame
    if not failed: print("PASS: %d pedal diagnostics assertions" % checks)
    quit(1 if failed else 0)
