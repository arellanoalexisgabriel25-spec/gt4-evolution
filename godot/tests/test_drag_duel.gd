extends SceneTree

const Run = preload("res://scripts/drag_run.gd")
const Duel = preload("res://scripts/drag_duel.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func pair(index: float = 0.0, limit: float = 125.0) -> Dictionary:
    var player = Run.new()
    var rival = Run.new()
    player.arm(0,0)
    rival.arm(0,0)
    var duel = Duel.new()
    if not duel.begin(player,rival,index,limit):
        push_error("Test fixture could not begin")
        failed = true
    return {"player":player,"rival":rival,"duel":duel}

# Advance actual beam models on one shared clock, rather than fabricating times.
func run_pair(player_wait: float, rival_wait: float, player_speed: float = 20.0, rival_speed: float = 20.0, index: float = 0.0) -> Dictionary:
    var race := pair(index)
    var clock := 0.0
    var positions := Vector2.ZERO
    for i in range(5000):
        var delta := 0.01
        clock += delta
        if clock>=player_wait: positions.x += player_speed*delta
        if clock>=rival_wait: positions.y += rival_speed*delta
        race.player.advance(delta,positions.x,player_speed if clock>=player_wait else 0.0)
        race.rival.advance(delta,positions.y,rival_speed if clock>=rival_wait else 0.0)
        race.duel.advance(delta)
        if race.duel.finished: break
    return race

func _initialize() -> void:
    var invalid = Duel.new()
    check(not invalid.begin(null,null),"Missing lanes cannot start a race")
    var same = Run.new()
    same.arm(0,0)
    check(not invalid.begin(same,same),"A car cannot race against the same timer instance")
    var unstaged = Run.new()
    check(not invalid.begin(same,unstaged),"Both physical lanes must be staged and armed")
    unstaged.arm(0,0)
    unstaged.clock=0.2
    check(not invalid.begin(same,unstaged),"The common tree cannot be attached after one lane's clock advances")
    unstaged.clock=0.0
    check(not invalid.begin(same,unstaged,NAN) and not invalid.begin(same,unstaged,0,INF),"Non-finite competition configuration is rejected atomically")
    check(not invalid.started and invalid.report().is_empty(),"Rejected starts leave no partial race or result")
    var equal_cars := run_pair(2.25,2.75)
    check(equal_cars.duel.finished and equal_cars.duel.report().winner=="player","The better reaction wins between equally fast cars")
    var report: Dictionary = equal_cars.duel.report()
    check(absf(float(report.entries.player.ticket.et)-float(report.entries.rival.ticket.et))<0.00001,"Equal-speed measured passes retain equal ET independently of reaction")
    check(absf(float(report.margin_s)-0.5)<0.011,"Winning margin follows measured arrival difference from the common green")
    var holeshot := run_pair(3.0,2.10,21.0,20.5)
    var holeshot_report: Dictionary = holeshot.duel.report()
    check(holeshot_report.entries.player.ticket.et<holeshot_report.entries.rival.ticket.et and holeshot_report.winner=="rival","A faster ET loses when late reaction puts its actual arrival behind the opponent")
    var tie := run_pair(2.25,2.25)
    check(tie.duel.report().outcome=="tie" and tie.duel.report().winner.is_empty(),"An actual simultaneous arrival does not arbitrarily favor the player")
    report.entries.player.ticket.et=1.0
    report.winner="rival"
    check(equal_cars.duel.report().winner=="player" and equal_cars.duel.report().entries.player.ticket.et>10,"Consumers cannot mutate the frozen result or nested timing tickets")
    var frozen: Dictionary = equal_cars.duel.report()
    equal_cars.player.elapsed=1.0
    equal_cars.player.reason="CHANGED"
    equal_cars.duel.advance(1000)
    check(equal_cars.duel.report()==frozen and not equal_cars.duel.begin(same,unstaged),"Late callbacks and duplicate starts cannot replace an adjudicated result")
    var red := run_pair(1.0,2.25)
    check(red.duel.report().winner=="rival" and red.duel.report().entries.player.status=="invalid" and red.duel.report().entries.player.reason=="LARGADA EN FALSO","A measured false start loses to the opponent's valid finish")
    var both_red := run_pair(1.0,1.0)
    check(both_red.duel.report().outcome=="no_winner" and both_red.duel.report().winner.is_empty(),"Two invalid starts cannot generate a fabricated victory")
    var lane := pair()
    lane.player.advance(0.1,0,0,false)
    lane.rival.invalidate("FUERA DE CARRIL")
    lane.duel.advance(0.1)
    check(lane.duel.report().outcome=="no_winner" and lane.duel.report().entries.player.reason=="FUERA DE CARRIL","Lane infringements are preserved as explicit failures")
    var timeout := pair(0,0.5)
    timeout.duel.advance(0.49)
    check(not timeout.duel.finished and timeout.duel.report().is_empty(),"An unfinished race remains pending until its deadline")
    timeout.duel.advance(0.01)
    check(timeout.duel.finished and timeout.duel.report().outcome=="no_winner" and timeout.duel.report().entries.rival.status=="timeout","A deadline closes both uncompleted lanes without inventing times")
    check(timeout.duel.report().entries.player.ticket.is_empty(),"Timeouts do not carry a fake finish ticket")
    var solo_finish := pair(0,24.0)
    var clock := 0.0
    var position := 0.0
    for i in range(2500):
        clock += 0.01
        if clock>=2.25: position += 0.2
        solo_finish.player.advance(0.01,position,20.0 if clock>=2.25 else 0.0)
        solo_finish.rival.advance(0.01,0,0)
        solo_finish.duel.advance(0.01)
        if solo_finish.duel.finished: break
    check(solo_finish.duel.report().winner=="player" and solo_finish.duel.report().entries.rival.status=="timeout","A real valid finisher defeats an opponent that never completes the course")
    check(solo_finish.duel.report().entries.player.ticket.et>20 and solo_finish.duel.report().entries.rival.ticket.is_empty(),"The deadline preserves the valid measured ticket and leaves no fake opponent time")
    var paused := pair()
    paused.duel.advance(0)
    paused.duel.advance(NAN)
    check(not paused.duel.finished and paused.duel.entries().player.status=="pending","Zero or malformed delta cannot advance adjudication")
    paused.player.advance(0.2,0,0)
    paused.rival.advance(0.1,0,0)
    paused.duel.advance(0.2)
    check(paused.duel.report().outcome=="no_winner" and paused.duel.report().entries.player.reason=="ÁRBOL DESINCRONIZADO","Asynchronous live trees are rejected instead of comparing incomparable arrivals")
    var indexed := run_pair(2.25,2.25,21.0,20.0,19.5)
    check(indexed.duel.report().winner=="rival" and indexed.duel.report().entries.player.status=="breakout","An explicitly configured practice floor disqualifies an under-index ET")
    check(indexed.duel.report().ruleset=="indexed_practice" and indexed.duel.report().minimum_et==19.5,"A game index is labelled practice rather than an invented official category")
    var double_breakout := run_pair(2.25,2.25,21.0,22.0,25.0)
    check(double_breakout.duel.report().outcome=="no_winner","Without verified double-breakout rules, neither invalid indexed pass is declared the winner")
    var corrupt := pair()
    corrupt.player.phase="finished"
    corrupt.rival.invalidate("ABANDONO")
    corrupt.duel.advance(0.1)
    check(corrupt.duel.report().outcome=="no_winner" and corrupt.duel.report().entries.player.reason=="TICKET INVÁLIDO","A terminal flag without a valid measured ticket cannot manufacture victory")
    var reset_lane := pair()
    reset_lane.player.phase="preparation"
    reset_lane.rival.invalidate("ABANDONO")
    reset_lane.duel.advance(0.01)
    check(reset_lane.duel.report().outcome=="no_winner" and reset_lane.duel.report().entries.player.reason=="CRONOMETRAJE REINICIADO","Resetting a timer during a race is an explicit invalid result")
    if not failed: print("PASS: %d drag duel assertions" % checks)
    quit(1 if failed else 0)
