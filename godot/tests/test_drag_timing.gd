extends SceneTree

const Run = preload("res://scripts/drag_run.gd")
const Records = preload("res://scripts/drag_records.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func constant_pass(wait_time: float):
    var run = Run.new()
    run.arm(0,0)
    run.advance(wait_time,0,0)
    var position := 0.0
    for i in range(300):
        position += 2.0
        run.advance(0.1,position,20)
        if run.phase=="finished":
            break
    return run

func _initialize() -> void:
    var run = Run.new()
    check(not run.arm(1.0,0.0) and not run.arm(0.0,1.0),"Unstaged or rolling vehicles cannot arm the tree")
    check(run.arm(0.0,0.0) and not run.arm(0.0,0.0),"The tree can be armed once per fresh attempt")
    run.advance(1.5,0,0)
    run.advance(0.1,0.4,4)
    check(run.phase=="invalid" and run.reason=="LARGADA EN FALSO" and run.report().is_empty(),"A real beam crossing before green rejects the entire ticket")
    var exact = Run.new()
    exact.arm(0,0)
    exact.advance(1.99,0,0)
    exact.advance(0.02,0.4,20)
    check(exact.phase=="running" and absf(exact.reaction)<0.000001,"Interpolated crossings exactly at green are legal even within the same tick")
    var fast = constant_pass(2.25)
    var slow = constant_pass(2.75)
    check(fast.phase=="finished" and slow.phase=="finished","Complete forward passes generate actual measured tickets")
    check(absf(fast.elapsed-(Run.DISTANCE-Run.ROLLOUT)/20.0)<0.00001,"Finish timing interpolates the 402.336 m beam rather than rounding to a frame")
    check(absf(slow.elapsed-fast.elapsed)<0.000001 and absf(slow.reaction-fast.reaction-0.5)<0.000001,"Reaction is independent from elapsed time and remains part of total time")
    check(absf(fast.trap_speed-72.0)<0.00001,"Trap speed is measured over the final 20.1168 metres")
    var ticket: Dictionary = fast.report()
    check(absf(ticket.sixty_ft-(18.288-0.20)/20.0)<0.00001 and ticket.sixty_ft<ticket.eighth and ticket.eighth<ticket.et,"60-foot and eighth-mile splits share the real launch beam clock")
    var records = Records.new()
    check(records.consider(1,ticket) and records.best(1)==ticket,"A valid measured ticket establishes that vehicle's record")
    check(not records.consider(1,ticket) and records.best(2).is_empty(),"Duplicate or other-vehicle tickets cannot overwrite the personal best")
    var corrupt := ticket.duplicate(true)
    corrupt["reaction"] = -0.1
    check(not records.consider(1,corrupt),"A red-light reaction cannot enter the record store")
    corrupt = ticket.duplicate(true)
    corrupt["trap_kmh"] = NAN
    check(not records.consider(1,corrupt),"Non-finite speeds are rejected")
    var previous: Dictionary = records.to_dict()
    check(not records.from_dict({"0":ticket}) and records.to_dict()==previous,"Invalid record loads preserve existing valid records atomically")
    for case in ["lane","teleport","timeout"]:
        var invalid = Run.new()
        invalid.arm(0,0)
        if case=="lane":
            invalid.advance(0.1,0,0,false)
        elif case=="teleport":
            invalid.advance(0.1,100,0)
        else:
            invalid.advance(123,0,0)
        check(invalid.phase=="invalid" and invalid.report().is_empty(),"Invalid physical pass cannot produce a ticket: "+case)
    if not failed:
        print("PASS: %d drag timing assertions" % checks)
    quit(1 if failed else 0)
