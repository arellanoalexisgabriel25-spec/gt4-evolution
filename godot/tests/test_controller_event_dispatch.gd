extends SceneTree

const Controller = preload("res://scripts/controller_state.gd")
var checks := 0
var failed := false

class EarlierSampler extends Node:
    var state
    var seen := 0
    func _input(event: InputEvent) -> void:
        if event is InputEventJoypadButton or event is InputEventJoypadMotion:
            seen += 1
            state.feed(event)

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func button(code: int, pressed: bool) -> InputEventJoypadButton:
    var event := InputEventJoypadButton.new()
    event.device=0
    event.button_index=code
    event.pressed=pressed
    Input.parse_input_event(event)
    Input.flush_buffered_events()
    return event

func axis(code: int, value: float) -> void:
    var event := InputEventJoypadMotion.new()
    event.device=0
    event.axis=code
    event.axis_value=value
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func _initialize() -> void: call_deferred("run")

func run() -> void:
    var state = Controller.new()
    var press := InputEventJoypadButton.new()
    press.device=0
    press.button_index=JOY_BUTTON_A
    press.pressed=true
    check(state.feed(press),"A new physical controller press produces a rising edge")
    check(state.feed(press),"Sampling the same physical delivery from another node preserves its rising edge")
    var held := InputEventJoypadButton.new()
    held.device=0
    held.button_index=JOY_BUTTON_A
    held.pressed=true
    check(not state.feed(held),"A new held-button delivery does not fabricate a second rising edge")
    held.pressed=false
    check(not state.feed(held) and not state.pressed(JOY_BUTTON_A),"A reused event object with a changed release payload releases the actual button")
    held.pressed=true
    check(state.feed(held),"A reused event object with a new press payload can produce a new edge")
    state.connection_changed(0,false)
    check(state.selected()<0 and state.feed(held),"Disconnect clears both pedal state and any previous event-delivery memo")
    var session = root.get_node("GameSession")
    session.reset()
    session.controls.restore_defaults()
    session.controls.controller.devices.clear()
    session.controls.controller.active_device=-1
    session.game.buy(11)
    for part in session.game.find_car(11).health: session.game.find_car(11).health[part]=100.0
    check(session.start_drag(11,"duel","technical",""),"The actual owned car opens a physical duel for controller dispatch")
    change_scene_to_file("res://scenes/drag.tscn")
    await process_frame
    await process_frame
    var scene = current_scene
    # Godot delivers _input in reverse tree order. This observer deliberately
    # samples before the scene, like an autoload/platform observer may do.
    var observer := EarlierSampler.new()
    observer.state=session.controls.controller
    root.add_child(observer)
    axis(JOY_AXIS_TRIGGER_RIGHT,1.0)
    button(JOY_BUTTON_LEFT_SHOULDER,true)
    button(JOY_BUTTON_A,true)
    button(JOY_BUTTON_A,false)
    for i in range(40): await physics_frame
    check(observer.seen>=4,"The early observer actually received the production joypad deliveries")
    check(scene._controls().throttle==1.0 and scene._controls().clutch==1.0,"Held RT and LB remain independent full accelerator and clutch")
    check(scene.car.powertrain.gear==1 and scene.car.powertrain.missed_shifts==0,"A valid RT+LB+A edge survives prior event sampling and selects first in the real scene")
    button(JOY_BUTTON_A,true)
    button(JOY_BUTTON_A,false)
    for i in range(40): await physics_frame
    check(scene.car.powertrain.gear==2 and scene.car.powertrain.missed_shifts==0,"A second real A edge selects the next gear without releasing RT or LB")
    button(JOY_BUTTON_Y,true)
    button(JOY_BUTTON_Y,false)
    for i in range(40): await physics_frame
    check(scene.car.powertrain.gear==1 and scene.car.powertrain.missed_shifts==0,"Y also downshifts under held accelerator and clutch after a prior observer")
    check(scene.procedure._warmup_seconds==25.0 and scene.procedure._staging_seconds==30.0,"The native controller run retains the complete shipped preparation timings")
    for i in range(3000):
        await physics_frame
        if scene.run.phase in ["running","invalid"] or scene.procedure.phase=="expired": break
    check(scene.procedure.elapsed>=25.0 and scene.run.phase=="running" and scene.duel.started,"RT+LB held through the full 25-second call reaches the actual shared green")
    var launch_z:float=scene.car.position.z
    button(JOY_BUTTON_LEFT_SHOULDER,false)
    for i in range(100): await physics_frame
    check(scene._controls().throttle==1.0 and scene._controls().clutch==0.0,"Releasing LB never releases or suppresses the controller accelerator")
    check(scene.car.powertrain.speed_mps>1.0 and scene.car.position.z<launch_z-1.0 and scene.run.launch_time>=0.0,"The same real controller event path launches the actual vehicle after full warmup without an input provider")
    observer.queue_free()
    await process_frame
    axis(JOY_AXIS_TRIGGER_RIGHT,0.0)
    button(JOY_BUTTON_LEFT_SHOULDER,false)
    scene._back_to_garage()
    await process_frame
    await process_frame
    session.menu_music.set_menu_active(false)
    for i in range(8): await process_frame
    if not failed: print("PASS: %d controller dispatch assertions" % checks)
    quit(1 if failed else 0)
