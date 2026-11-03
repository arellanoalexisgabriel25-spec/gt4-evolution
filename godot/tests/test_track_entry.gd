extends SceneTree

const Economy = preload("res://scripts/economy.gd")
const Career = preload("res://scripts/career.gd")
const Store = preload("res://scripts/save_store.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    var game = Economy.new()
    game.seed_demo()
    var career = Career.new()
    var report := {"laps":2,"standings":[
        {"id":"player","position":1,"time":60.0,"laps":2,"dnf":false},
        {"id":"claire","position":2,"time":65.0,"laps":2,"dnf":false},
        {"id":"nico","position":3,"time":70.0,"laps":2,"dnf":false}]}
    var before: int = game.balance
    check(not career.award_track_result(game, "debut", 1, report).ok, "Unpaid report cannot mint a prize")
    check(not career.begin_track_entry(game, "debut", 1).is_empty(), "Unowned entry rejected")
    check(game.balance == before, "Rejected entry cannot consume credits")
    game.buy(1)
    before = game.balance
    check(career.begin_track_entry(game, "debut", 1).is_empty(), "Eligible paid admission accepted")
    check(game.balance == before - 120, "Admission charged once before racing")
    check(not career.begin_track_entry(game, "debut", 1).is_empty(), "Second pending entry blocked")
    check(game.balance == before - 120, "Blocked duplicate cannot double charge")
    var temporary := "user://blocked-admission-%d.json" % Time.get_ticks_usec()
    check(Store.save_file(temporary, game, career) == ERR_BUSY and not FileAccess.file_exists(temporary), "Cannot save an unpaid-to-result transition as a garage state")
    check(not career.award_track_result(game, "debut", 1, report).ok, "Unstarted race cannot pay")
    career.cancel_track_entry(game, true)
    check(game.balance == before and not career.has_pending_track_entry(), "Failed scene startup can refund once")
    career.cancel_track_entry(game, true)
    check(game.balance == before, "Repeated refund cannot mint credits")
    career.begin_track_entry(game, "debut", 1)
    career.mark_track_started()
    career.cancel_track_entry(game, true)
    check(game.balance == before - 120 and career.has_pending_track_entry(), "Started entry cannot be refunded")
    check(career.simulate_event(game, "local", 1).contains("en curso"), "Cannot mix simulation with active paid race")
    var invalid := report.duplicate(true)
    invalid["standings"][2]["id"] = "claire"
    check(not career.award_track_result(game, "debut", 1, invalid).ok, "Duplicate rival invalidates result")
    invalid = report.duplicate(true)
    invalid["standings"][0]["laps"] = 1
    check(not career.award_track_result(game, "debut", 1, invalid).ok, "Partial player distance cannot pay")
    invalid = report.duplicate(true)
    invalid["standings"][0]["time"] = NAN
    check(not career.award_track_result(game, "debut", 1, invalid).ok, "Non-finite finish time rejected")
    invalid = report.duplicate(true)
    invalid["standings"][2]["time"] = 50.0
    check(not career.award_track_result(game, "debut", 1, invalid).ok, "Unsorted finish times cannot assign a false position")
    check(game.balance == before - 120 and career.completed.is_empty(), "Invalid reports cannot change money or progress")
    career.cancel_track_entry(game)
    check(game.balance == before - 120 and not career.has_pending_track_entry(), "Abandonment consumes fee without prize")
    career.begin_track_entry(game, "debut", 1)
    career.mark_track_started()
    var outcome: Dictionary = career.award_track_result(game, "debut", 1, report)
    check(outcome.ok and career.completed.has("debut"), "Valid physical finish completes event")
    check(game.balance == before - 240 + 700, "Two paid attempts and one prize conserve credits")
    var awarded: int = game.balance
    check(not career.award_track_result(game, "debut", 1, report).ok and game.balance == awarded, "Repeated settlement cannot pay twice")
    check(career.rivalries["nico"]["victories"] == 1 and career.rivalries["claire"]["encounters"] == 1, "Track placement updates persistent rival memories")
    check(not career.begin_track_entry(game, "debut", 1).is_empty(), "Completed track event cannot re-enter for prizes")
    career.simulate_event(game, "local", 1)
    check(career.license == "B", "Track and legacy events jointly unlock next license")
    if not failed:
        print("PASS: %d track entry assertions" % checks)
    quit(1 if failed else 0)
