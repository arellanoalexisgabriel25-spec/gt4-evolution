extends SceneTree

const Feedback = preload("res://scripts/transmission_feedback.gd")
const Model = preload("res://scripts/manual_powertrain.gd")
const HUD = preload("res://scripts/drag_hud.gd")
const Run = preload("res://scripts/drag_run.gd")
const Settings = preload("res://scripts/control_settings.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void: call_deferred("run")

func run() -> void:
    var model = Model.new()
    var reader = Feedback.new()
    check(reader.observe(model).is_empty(),"A newly attached feedback reader does not fabricate an old shift event")
    for quality in ["perfect","acceptable","poor","rejected"]:
        model.shift_quality = quality
        model.shift_event_serial += 1
        var event: Dictionary = reader.observe(model)
        check(event.quality==quality and event.duration>0.0 and event.gain>0.0,"Each actual quality outcome selects a bounded synthesized cue")
        check(event.weak>=0.0 and event.weak<=1.0 and event.strong>=0.0 and event.strong<=1.0,"Haptic amplitudes stay in hardware limits")
        check(reader.observe(model).is_empty(),"Repeated frames cannot replay the same grinding sound or rumble")
    check(Feedback.CUES.rejected.duration>Feedback.CUES.perfect.duration and Feedback.CUES.rejected.noise>Feedback.CUES.perfect.noise,"A rejected shift has a distinct longer grinding cue than a clean engagement")
    model.shift_event_serial = 0
    check(reader.observe(model).is_empty(),"Recovery resetting event serial does not create an extra shift")
    var hud = HUD.new()
    root.add_child(hud)
    await process_frame
    var timer = Run.new()
    var settings = Settings.new()
    var data := {"model":model,"run":timer,"settings":settings,"name":"Fiat 147 Vivace","position":0.0,"best":{},"staged":true,"message":"","wear_start":{},"procedure_phase":"staging","procedure_remaining":20.0,"procedure_message":"LLAMADO · ALINEACIÓN","readiness_issue":"Seleccioná primera","procedure_ready":false}
    hud.refresh(data)
    check(hud.status_label.text=="LLAMADO · ALINEACIÓN" and hud.preparation_label.text.contains("Seleccioná primera"),"Readiness guidance preserves the official starter status")
    timer.phase = "running"
    data.launch_hint = "Soltá el embrague"
    hud.refresh(data)
    check(hud.status_label.text.contains("VERDE") and hud.status_label.text.contains("Soltá el embrague"),"A green light explains the actual held-control launch obstruction")
    model.gear = -1
    model.speed_mps = -3.0
    model.shift_quality = "rejected"
    model.shift_event_serial += 1
    hud.refresh(data)
    check(hud.gear_label.text=="R" and hud.speed_label.text=="11","Reverse uses the actual signed gear and speed in the compact instruments")
    check(hud.instruments.shift_remaining>0.0,"The actual shift event reaches the gear-feedback instrument")
    data.paused = true
    hud.refresh(data)
    check(hud.environment_label.text.contains("EMBRAGUE") and hud.help_label.text.contains("entra R"),"Pause exposes clutch condition and real reverse-selection instructions")
    await process_frame
    var visible := root.get_visible_rect()
    check(visible.encloses(hud.details_panel.get_global_rect()) and visible.encloses(hud.help_label.get_global_rect()),"Expanded mechanical diagnostics and help remain inside the viewport")
    check(not hud.details_panel.get_global_rect().intersects(hud.help_label.get_global_rect()),"Mechanical diagnostics do not overlap the longer reverse/assist guide")
    hud.queue_free()
    await process_frame
    if not failed: print("PASS: %d transmission presentation assertions" % checks)
    quit(1 if failed else 0)
