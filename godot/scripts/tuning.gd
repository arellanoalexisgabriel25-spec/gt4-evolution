extends RefCounted
class_name EvolutionTuning
const Money = preload("res://scripts/money.gd")

# Small, game-balanced tuning catalog. Does not modify GT4's original physics.
const PARTS := [
    {"id":"ecu", "name":"ECU deportiva", "price":1200, "gain":5.0, "category":"motor"},
    {"id":"escape", "name":"Escape deportivo", "price":800, "gain":2.5, "category":"motor"},
    {"id":"suspension", "name":"Suspensión regulable", "price":1100, "gain":4.0, "category":"suspension"},
    {"id":"brakes", "name":"Frenos de competición", "price":1000, "gain":3.5, "category":"frenos"},
    {"id":"tires", "name":"Neumáticos de altas prestaciones", "price":650, "gain":5.0, "category":"neumaticos"}
]

func part_by_id(part_id: String) -> Dictionary:
    for part in PARTS:
        if part["id"] == part_id:
            return part
    return {}

func installed(car: Dictionary) -> Array:
    return car.get("upgrades", [])

func has_part(car: Dictionary, part_id: String) -> bool:
    return installed(car).has(part_id)

func performance_bonus(car: Dictionary) -> float:
    var total := 0.0
    for part_id in installed(car):
        total += float(part_by_id(str(part_id)).get("gain", 0.0))
    return minf(total, 20.0)

func engine_wear_multiplier(car: Dictionary) -> float:
    var multiplier := 1.0
    if has_part(car, "ecu"):
        multiplier += 0.22
    if has_part(car, "escape"):
        multiplier += 0.08
    return multiplier

func can_install(game, car_id: int, part_id: String) -> String:
    var part := part_by_id(part_id)
    if part.is_empty():
        return "Pieza desconocida."
    var car: Dictionary = game.find_car(car_id)
    if car.is_empty() or car.get("owner", "") != "player":
        return "El vehículo debe pertenecer al jugador."
    if has_part(car, part_id):
        return "Esta mejora ya está instalada."
    var component: String = part["category"]
    if float(car["health"].get(component, 0.0)) < 40.0:
        return "Repará primero el componente %s." % component
    if game.balance < int(part["price"]):
        return "Saldo insuficiente."
    return ""

func install(game, car_id: int, part_id: String) -> String:
    var problem := can_install(game, car_id, part_id)
    if not problem.is_empty():
        return problem
    var part := part_by_id(part_id)
    var car: Dictionary = game.find_car(car_id)
    var price := int(part["price"])
    game.balance -= price
    if not car.has("upgrades"):
        car["upgrades"] = []
    car["upgrades"].append(part_id)
    if part_id=="tires":
        car["tire_compound"] = "sport"
        car["health"]["neumaticos"] = 100.0
    game._record(car, "tuning:" + part_id, -price)
    return "Instalaste %s por %s. Bonificación +%.1f." % [part["name"], Money.format(price), performance_bonus(car)]
