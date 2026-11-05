extends SceneTree

const HUD = preload("res://scripts/drag_hud.gd")
const Model = preload("res://scripts/manual_powertrain.gd")
const Run = preload("res://scripts/drag_run.gd")
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
    root.size = Vector2i(1280,720)
    var hud = HUD.new()
    root.add_child(hud)
    await process_frame
    await process_frame
    var model = Model.new()
    var timer = Run.new()
    var opponent = Run.new()
    var settings = Settings.new()
    var data := {
        "model":model,"run":timer,"settings":settings,"name":"Fiat 500 Sport",
        "position":0.0,"best":{},"staged":true,"can_arm":false,"message":"",
        "paused":false,"personal_best":false,"wear_start":{},"duel":true,
        "opponent_name":"Nico Vega","opponent_model":"Fiat 133","opponent_run":opponent,
        "opponent_gap":0.0,"duel_result":{},"zero_to_hundred":-1.0,"class_data":{},
        "procedure_phase":"burnout","procedure_remaining":25.0,"procedure_ready":false
    }
    model.config.drivetrain = "FWD"
    model.axles.temperatures = Vector2(53,24)
    hud.refresh(data)
    await process_frame
    check(hud.status_label.text=="CALENTAMIENTO" and hud.clock_label.text=="25 s","The preparation overlay identifies the current timed warmup phase")
    check(hud.preparation_label.text.contains("H/L3") and hud.preparation_label.text.contains("DL 53°C") and hud.preparation_label.text.contains("TR 24°C"),"Warmup instructions expose the rear parking brake and actual temperatures of both axles")
    check(hud.preparation_panel.visible and not hud.help_label.visible and not hud.details_panel.visible,"Preparation has a short guide without displaying the full control and telemetry panels")
    check(not hud.preparation_label.text.contains("Enter") and not hud.status_label.text.contains("Enter"),"The guide does not tell the driver to start the tree")
    var has_manual_start := false
    for button in hud.find_children("*","Button",true,false):
        has_manual_start = has_manual_start or button.text.contains("SEMÁFORO") or button.text.contains("Enter")
    check(not has_manual_start,"No manual-start button remains on the screen")
    check(hud.opponent_label.text.contains("Fiat 133"),"The compact rival overlay retains the actual opponent model")
    data.procedure_message = "CALENTAMIENTO AUTORIZADO"
    check(settings.bind("handbrake",KEY_J).is_empty(),"The parking-brake guide supports a real remapped binding")
    hud.refresh(data)
    check(hud.status_label.text=="CALENTAMIENTO AUTORIZADO" and hud.preparation_label.text.contains("J/L3") and hud.preparation_label.text.contains("C+E: primera"),"The real starter status does not replace the gear and warmup instructions")
    check(hud.preparation_label.text.contains("Puede avanzar") and hud.preparation_label.text.contains("2,5–35 m") and hud.preparation_label.text.contains("C + Espacio"),"The guide states that warming can move the car, its permitted zone and how to stop")
    data.paused = true
    hud.refresh(data)
    check(hud.help_label.text.contains("J/L3: freno de mano trasero"),"Pause exposes the actual rebound parking-brake control and rear-axle effect")
    data.paused = false
    data.erase("procedure_message")
    data.procedure_phase = "staging"
    data.procedure_remaining = 18.2
    data.procedure_ready = true
    hud.refresh(data)
    check(hud.status_label.text.contains("LLAMADO") and hud.clock_label.text=="19 s","The starter call and remaining presentation time are visible, rounded upward")
    check(hud.preparation_label.text.contains("Asistencia de alineación") and hud.reaction_label.text.contains("EMBRAGUE"),"The guide discloses staging assistance and the clutch requirement")
    timer.phase = "countdown"
    timer.clock = 1.2
    hud.refresh(data)
    check(hud.show_tree and hud.clock_label.text=="LARGADA" and hud.status_label.text=="ESPERÁ EL VERDE","The small countdown display identifies the starter-controlled tree")
    check(not hud.preparation_panel.visible and not hud.actions.visible,"Preparation controls disappear during the countdown")
    timer.phase = "running"
    timer.clock = 7.8
    timer.launch_time = 2.2
    timer.reaction = 0.2
    timer.elapsed = 5.6
    model.speed_mps = 25.0
    model.gear = 3
    model.rpm = 4200.0
    model.feedback_time = 0.0
    data.position = 80.0
    hud.refresh(data)
    await process_frame
    check(not hud.help_label.is_visible_in_tree() and not hud.details_panel.is_visible_in_tree() and not hud.preparation_panel.visible,"The active pass removes detailed telemetry, help and preparation from view")
    check(not hud.actions.visible and not hud.ticket_panel.visible and not hud.show_tree,"The pass leaves no action buttons, result card or persistent tree over the road")
    check(hud.status_label.text.is_empty() and not hud.status_label.visible,"Normal driving does not produce a permanent central instruction banner")
    check(hud.gear_label.text=="3" and hud.speed_label.text=="90" and hud.rpm_label.text.contains("4200"),"The remaining instruments display actual gear, speed and RPM")
    check(hud.clock_label.text=="5.600 s" and hud.reaction_label.text=="RT 0.200 s","ET and reaction remain separate in the compact timer")
    check(hud.power_label.text.contains("0–100") and not hud.power_label.is_visible_in_tree(),"The diagnostic metric remains available without occupying the racing view")
    var viewport := Rect2(Vector2.ZERO,Vector2(1280,720))
    check(viewport.encloses(hud.speed_panel.get_global_rect()),"The compact speed panel remains inside a 1280×720 viewport")
    check(hud.speed_panel.get_global_rect().get_area()<viewport.get_area()*0.05,"The main instrument panel uses less than five percent of the screen")
    check(hud.progress>0.19 and hud.progress<0.21,"The small progress indicator follows the measured position")
    model.feedback = "CAMBIO RECHAZADO · Pisá el embrague"
    model.feedback_time = 1.0
    hud.refresh(data)
    check(hud.status_label.visible and hud.status_label.text.contains("embrague"),"A transient mechanical rejection remains visible when the driver needs feedback")
    data.paused = true
    hud.refresh(data)
    check(hud.details_panel.visible and hud.help_label.visible and hud.actions.visible,"Pause exposes the detailed telemetry, controls and actions")
    check(hud.status_label.text.begins_with("PAUSA") and not hud.help_label.text.contains("Enter"),"The pause overlay explains controls without a manual-start instruction")
    data.paused = false
    timer.phase = "finished"
    timer.elapsed = 18.4
    timer.total = 18.6
    timer.trap_speed = 120.0
    timer.finish_speed = 121.0
    hud.refresh(data)
    check(not hud.ticket_panel.visible and hud.status_label.text=="ESPERANDO AL RIVAL","One finished lane does not show a result card while the rival is still racing")
    data.duel_result = {"winner":"player","outcome":"win","reason":"PRIMERA LLEGADA VÁLIDA","entries":{"player":{"status":"finished","ticket":timer.report()},"rival":{"status":"timeout","reason":"TIEMPO MÁXIMO AGOTADO","ticket":{}}}}
    hud.refresh(data)
    check(hud.ticket_panel.visible and hud.ticket_label.text.contains("VICTORIA") and hud.ticket_label.text.contains("TOTAL"),"The complete adjudicated duel exposes the result and measured arrival time")
    check(hud.wear_label.text.contains("DESGASTE") and hud.wear_label.text.contains("Caja"),"The final card retains the actual mechanical-use report")
    data.paused = true
    hud.refresh(data)
    check(not hud.ticket_panel.visible and hud.details_panel.visible,"Pausing the completed race shows diagnostics without overlapping the result card")
    data.paused = false
    data.duel = false
    data.duel_result = {}
    hud.refresh(data)
    check(hud.ticket_panel.visible and hud.ticket_label.text.contains("TICKET"),"Individual practice retains its timing ticket")
    check(not hud.opponent_panel.visible,"Individual practice removes the opponent card")
    hud.queue_free()
    await process_frame
    if not failed: print("PASS: %d compact drag HUD assertions" % checks)
    quit(1 if failed else 0)
