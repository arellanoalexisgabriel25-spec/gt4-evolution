extends RefCounted
class_name EvolutionRivals

# Deterministic simulated competition. This is NOT driving AI.
# Skill, aggression and consistency are game-design ratings, not real-world estimates.
const DRIVERS := [
    {"id":"nico","name":"Nico Vega","skill":56.0,"aggression":0.45,"consistency":0.75},
    {"id":"claire","name":"Claire Moreau","skill":64.0,"aggression":0.65,"consistency":0.90},
    {"id":"akira","name":"Akira Sato","skill":72.0,"aggression":0.35,"consistency":0.95},
    {"id":"marco","name":"Marco Ferri","skill":79.0,"aggression":0.85,"consistency":0.70}
]
const FIELDS := {
    "debut": ["nico","claire"],
    "local": ["claire","nico"],
    "regional": ["akira","claire"],
    "endurance": ["akira","marco"],
    "national": ["marco","akira"]
}
const DIFFICULTY := {"debut":0.0,"local":4.0,"regional":6.0,"endurance":10.0,"national":13.0}

func driver_by_id(id: String) -> Dictionary:
    for driver in DRIVERS:
        if driver["id"] == id:
            return driver
    return {}

func field_for_event(event_id: String) -> Array:
    var field: Array = []
    for id in FIELDS.get(event_id, []):
        var driver := driver_by_id(id)
        if not driver.is_empty():
            field.append(driver)
    return field

func score(driver: Dictionary, event_id: String) -> float:
    # Higher consistency rewards endurance; aggression helps more in a sprint.
    var base := float(driver["skill"]) + float(DIFFICULTY.get(event_id, 0.0))
    if event_id == "endurance":
        base += float(driver["consistency"]) * 5.0 - float(driver["aggression"]) * 2.0
    else:
        base += float(driver["aggression"]) * 3.0 + float(driver["consistency"])
    return snappedf(base, 0.01)

func classify(player_score: float, event_id: String) -> Dictionary:
    var opponents := field_for_event(event_id)
    if opponents.size() != 2 or not is_finite(player_score):
        return {}
    var position := 1
    var rankings: Array[Dictionary] = []
    for rival in opponents:
        var opponent_score := score(rival, event_id)
        if opponent_score >= player_score:
            position += 1
        rankings.append({"id": rival["id"], "name": rival["name"], "score": opponent_score})
    return {"position":position, "opponents":rankings}
