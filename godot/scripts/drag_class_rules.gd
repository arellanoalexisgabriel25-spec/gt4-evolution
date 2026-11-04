extends RefCounted

## Time limits transcribed from Article 21 of the sporting text supplied by the
## user. This module evaluates ET only; it cannot grant technical admission,
## establish a vehicle's official class history, award points or approve safety.

const QUARTER_MILE := "quarter"
const EIGHTH_MILE := "eighth"

# Keep the two published tables independent. In particular, 4i/5i exist only in
# the quarter-mile table and the eighth-mile class 6 floor in Article 21 is 8.50,
# despite the different number printed in the Article 23 prize table.
const _QUARTER_MINIMUMS := [
    ["1",18.00], ["2",17.00], ["3",16.00], ["4",15.00],
    ["4i",14.50], ["5",14.00], ["5i",13.50], ["6",13.00],
    ["7",12.40], ["8",11.80], ["9",11.40], ["10",10.60],
    ["L1",0.0],
]
const _EIGHTH_MINIMUMS := [
    ["1",11.30], ["2",10.80], ["3",10.30], ["4",9.70],
    ["5",9.00], ["6",8.50], ["7",8.00], ["8",7.60],
    ["9",7.20], ["10",6.80], ["L1",0.0],
]

static func source_metadata() -> Dictionary:
    return {
        "source_kind":"user_supplied_text",
        "document":"Reglamento Deportivo",
        "article":21,
        "breakout_article":20,
        "live_verified":false,
        "classification_basis":"elapsed_time",
        "admission_confirmed":false,
        "factory_stock_classification":false,
        "safety_homologation":false,
    }

static func _table(distance: String) -> Array:
    if distance==QUARTER_MILE:
        return _QUARTER_MINIMUMS
    if distance==EIGHTH_MILE:
        return _EIGHTH_MINIMUMS
    return []

static func _class_data(row: Array, distance: String) -> Dictionary:
    return {
        "id":str(row[0]),
        "label":"Clase "+str(row[0]),
        "distance":distance,
        # Zero is a sentinel for no floor, not an ET admissible for a ticket.
        "minimum_et":float(row[1]),
        "unlimited":row[0]=="L1",
        "admission_confirmed":false,
        "requires_specific_admission":row[0]=="L1",
        "source":source_metadata(),
    }

static func classes(distance: String = QUARTER_MILE) -> Array:
    var result: Array = []
    for row in _table(distance):
        result.append(_class_data(row,distance))
    return result

static func class_by_id(id: String, distance: String = QUARTER_MILE) -> Dictionary:
    for row in _table(distance):
        if row[0]==id:
            return _class_data(row,distance)
    return {}

static func _valid_et(et: Variant) -> bool:
    return typeof(et) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(et)) and float(et)>0.0

## Suggest the closest indexed floor at or below a completed, valid pass's ET.
## This is a time band, not official registration: Article 18 also requires
## competition history/authorities. L1 has separate admission requirements and
## is deliberately never chosen automatically when no indexed floor fits.
static func recommend(et: Variant, distance: String = QUARTER_MILE) -> Dictionary:
    if not _valid_et(et):
        return {}
    for row in _table(distance):
        if row[0]!="L1" and float(et)>=float(row[1]):
            var result := _class_data(row,distance)
            result["recommendation_only"] = true
            result["elapsed_et"] = float(et)
            return result
    return {}

## Article 20 defines a breakout by ET strictly below the class minimum. A
## slower ET remains above that floor; prize eligibility is a separate rule.
## A caller must validate the physical ticket before passing its ET here.
## Reaction time and RT+ET are intentionally absent from this interface.
static func evaluate(et: Variant, class_id: String, distance: String = QUARTER_MILE) -> Dictionary:
    var result := {
        "valid_input":false,
        "admission_confirmed":false,
    }
    if _table(distance).is_empty():
        result["error"] = "unknown_distance"
        return result
    var selected := class_by_id(class_id,distance)
    if selected.is_empty():
        result["error"] = "unknown_class"
        return result
    if not _valid_et(et):
        result["error"] = "invalid_et"
        return result
    var breakout := not bool(selected.unlimited) and float(et)<float(selected.minimum_et)
    result.merge({
        "valid_input":true,
        "class_id":class_id,
        "distance":distance,
        "elapsed_et":float(et),
        "minimum_et":selected.minimum_et,
        "unlimited":selected.unlimited,
        "requires_specific_admission":selected.requires_specific_admission,
        "breakout":breakout,
        "meets_minimum":not breakout,
        "source":source_metadata(),
    },true)
    return result
