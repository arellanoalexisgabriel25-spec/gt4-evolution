extends SceneTree

const Rules = preload("res://scripts/drag_class_rules.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func check_table(distance: String, expected: Array) -> void:
    var table: Array = Rules.classes(distance)
    check(table.size()==expected.size()+1,"Published table has indexed classes plus L1: "+distance)
    for i in range(expected.size()):
        var id: String = expected[i][0]
        var floor_et: float = expected[i][1]
        var selected: Dictionary = Rules.class_by_id(id,distance)
        check(selected.id==id and selected.distance==distance and selected.minimum_et==floor_et,"Exact Article 21 floor: "+distance+" / "+id)
        check(table[i]==selected,"Class order and lookup agree: "+distance+" / "+id)
        var exact: Dictionary = Rules.evaluate(floor_et,id,distance)
        check(exact.valid_input and not exact.breakout and exact.meets_minimum,"An ET exactly on the class floor is legal: "+distance+" / "+id)
        var below: Dictionary = Rules.evaluate(floor_et-0.000001,id,distance)
        check(below.valid_input and below.breakout and not below.meets_minimum,"Every ET strictly below the floor is a breakout: "+distance+" / "+id)
        var above: Dictionary = Rules.evaluate(floor_et+0.000001,id,distance)
        check(above.valid_input and not above.breakout,"An ET above the floor is not a breakout: "+distance+" / "+id)
        check(Rules.recommend(floor_et,distance).id==id,"The exact floor recommends its indexed class: "+distance+" / "+id)
        var upper_et: float = 100.0 if i==0 else float(expected[i-1][1])
        check(Rules.recommend((upper_et+floor_et)/2.0,distance).id==id,"A measured ET within each band recommends that class: "+distance+" / "+id)
        check(not selected.admission_confirmed and not exact.admission_confirmed,"Time limits cannot grant admission: "+distance+" / "+id)

func _initialize() -> void:
    check_table(Rules.QUARTER_MILE,[
        ["1",18.00], ["2",17.00], ["3",16.00], ["4",15.00],
        ["4i",14.50], ["5",14.00], ["5i",13.50], ["6",13.00],
        ["7",12.40], ["8",11.80], ["9",11.40], ["10",10.60],
    ])
    check_table(Rules.EIGHTH_MILE,[
        ["1",11.30], ["2",10.80], ["3",10.30], ["4",9.70],
        ["5",9.00], ["6",8.50], ["7",8.00], ["8",7.60],
        ["9",7.20], ["10",6.80],
    ])
    check(Rules.class_by_id("1").minimum_et==18.0 and Rules.class_by_id("1",Rules.EIGHTH_MILE).minimum_et==11.3,"Quarter-mile and eighth-mile classes never share floors")
    check(Rules.class_by_id("4i",Rules.EIGHTH_MILE).is_empty() and Rules.class_by_id("5i",Rules.EIGHTH_MILE).is_empty(),"Intermediate classes belong only to the supplied quarter-mile table")
    check(Rules.class_by_id("6",Rules.EIGHTH_MILE).minimum_et==8.50,"The Article 23 prize-table discrepancy cannot change Article 21 class 6")
    check(Rules.recommend(17.999999).id=="2" and Rules.recommend(18).id=="1" and Rules.recommend(30).id=="1","Class 1 has no invented maximum ET and class 2 starts strictly below 18 seconds")
    check(Rules.recommend(14.50).id=="4i" and Rules.recommend(13.50).id=="5i","Quarter-mile intermediate classes are selectable from valid ET")
    check(Rules.recommend(10.599999).is_empty() and Rules.recommend(6.799999,Rules.EIGHTH_MILE).is_empty(),"Out-of-index fast ET cannot automatically enter L1")
    var suggestion: Dictionary = Rules.recommend(17.5)
    check(suggestion.recommendation_only and not suggestion.admission_confirmed,"A time band suggestion is not official Article 18 registration")
    var slower: Dictionary = Rules.evaluate(24.0,"2")
    check(slower.valid_input and slower.meets_minimum and not slower.breakout,"A slow ET does not become a breakout or use the separate prize upper limit")
    var late_reaction_et: Dictionary = Rules.evaluate(17.9,"1")
    check(late_reaction_et.breakout,"ET under 18 remains a breakout even if a late reaction could put RT+ET above 18")
    for distance in [Rules.QUARTER_MILE,Rules.EIGHTH_MILE]:
        var unlimited: Dictionary = Rules.class_by_id("L1",distance)
        var unrestricted_time: Dictionary = Rules.evaluate(5.0,"L1",distance)
        check(unlimited.unlimited and unlimited.minimum_et==0.0 and unlimited.requires_specific_admission,"L1 has no minimum but retains its own admission conditions: "+distance)
        check(unrestricted_time.valid_input and not unrestricted_time.breakout and not unrestricted_time.admission_confirmed,"Meeting L1's time rule grants no technical admission: "+distance)
    for invalid in [NAN,INF,-INF,0.0,-1.0,"18",null,true,{},[]]:
        check(Rules.recommend(invalid).is_empty(),"Malformed elapsed times do not generate a recommendation")
        var rejected: Dictionary = Rules.evaluate(invalid,"1")
        check(not rejected.valid_input and rejected.error=="invalid_et" and not rejected.admission_confirmed,"Malformed ET is rejected independently of technical admission")
    check(Rules.classes("unknown").is_empty() and Rules.class_by_id("1","unknown").is_empty() and Rules.recommend(18.0,"unknown").is_empty(),"Unknown distances never silently fall back to quarter-mile")
    check(not Rules.evaluate(18.0,"1","unknown").valid_input and Rules.evaluate(18.0,"1","unknown").error=="unknown_distance","Evaluation rejects an unknown distance explicitly")
    for invalid_class in ["", "11", "4I", "l1", "01"]:
        check(Rules.class_by_id(invalid_class).is_empty() and Rules.evaluate(18.0,invalid_class).error=="unknown_class","Unknown or ambiguous class IDs are rejected: "+invalid_class)
    var first: Array = Rules.classes()
    first[0].minimum_et = 0.1
    first[0].source.live_verified = true
    first.clear()
    suggestion.minimum_et = 0.2
    suggestion.source.live_verified = true
    var standalone: Dictionary = Rules.class_by_id("1")
    standalone.minimum_et = 0.3
    var source: Dictionary = Rules.source_metadata()
    source.article = 23
    source.live_verified = true
    var pristine: Dictionary = Rules.class_by_id("1")
    check(Rules.classes().size()==13 and pristine.minimum_et==18.0 and Rules.recommend(17.5).minimum_et==17.0,"Returned table, lookup and recommendation dictionaries do not mutate future results")
    check(pristine.source.article==21 and not pristine.source.live_verified and not Rules.source_metadata().live_verified,"Nested source metadata is returned independently")
    check(pristine.source.source_kind=="user_supplied_text" and pristine.source.document=="Reglamento Deportivo","Provenance identifies supplied text, not a current independently verified regulation")
    check(not pristine.source.factory_stock_classification and not pristine.source.safety_homologation and not pristine.source.admission_confirmed,"Time classes imply neither factory configuration nor safety approval")
    if not failed:
        print("PASS: %d supplied regulation class assertions" % checks)
    quit(1 if failed else 0)
