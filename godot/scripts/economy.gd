extends RefCounted
class_name EvolutionEconomy

const SCHEMA_VERSION := 1
const START_BALANCE := 12000
const MODELS := ["Mazda MX-5 NA", "Honda Civic EK", "Toyota Corolla Levin AE86", "Nissan Silvia S13", "Toyota MR2 SW20", "Honda Prelude", "Mitsubishi FTO", "Mazda RX-7 FC", "Subaru Impreza GC8", "Nissan Skyline R32"]
const WEIGHTS := {"motor": 0.25, "transmision": 0.15, "suspension": 0.15, "frenos": 0.15, "neumaticos": 0.10, "chasis": 0.15, "electrico": 0.05}
const WEAR := {"motor": 0.0010, "transmision": 0.0008, "suspension": 0.0012, "frenos": 0.0030, "neumaticos": 0.0090, "chasis": 0.0003, "electrico": 0.0004}

var balance: int = START_BALANCE
var cars: Array[Dictionary] = []
var ledger: Array[Dictionary] = []

func seed_demo() -> void:
    balance = START_BALANCE
    cars.clear()
    ledger.clear()
    var rng := RandomNumberGenerator.new()
    rng.seed = 42026
    for i in range(MODELS.size()):
        var health: Dictionary = {}
        for component in WEIGHTS:
            health[component] = float(rng.randi_range(40, 95))
        var km := rng.randi_range(60000, 260000)
        var faults: Dictionary = {}
        if i % 3 == 2:
            faults["motor" if i % 2 == 0 else "frenos"] = true
        var price := calculate_market_price(i, km, health, faults)
        cars.append({"id": i + 1, "model": MODELS[i], "km": km, "health": health, "faults": faults, "owner": "seller", "listed": true, "inspected": false, "price": price, "history": []})

# Reference value, mileage, mechanical health and known structural defects determine asking prices.
# These tuning coefficients are deliberately game-balance values, not real-world appraisals.
func calculate_market_price(index: int, km: int, health: Dictionary, faults: Dictionary) -> int:
    var base := 4400.0 + 1300.0 * float(index + 1)
    var weighted := 0.0
    for component in WEIGHTS:
        weighted += float(health.get(component, 0.0)) * float(WEIGHTS[component])
    var state_factor := 0.40 + clampf(weighted / 100.0, 0.0, 1.0) * 0.75
    var mileage_factor := clampf(1.20 - float(km) / 400000.0, 0.60, 1.10)
    var faults_factor := 0.82 if not faults.is_empty() else 1.0
    return maxi(900, roundi(base * state_factor * mileage_factor * faults_factor / 50.0) * 50)

func inspection_summary(car: Dictionary) -> String:
    if not bool(car.get("inspected", false)):
        return "Estado mecánico no verificado."
    var defects: Dictionary = car.get("faults", {})
    if defects.is_empty():
        return "Inspección: sin averías ocultas detectadas."
    var components: Array[String] = []
    for component in defects:
        if bool(defects[component]):
            components.append(str(component))
    if components.is_empty():
        return "Inspección: sin averías ocultas detectadas."
    return "Averías detectadas: " + ", ".join(components)

func find_car(id: int) -> Dictionary:
    for car in cars:
        if int(car["id"]) == id:
            return car
    return {}

func condition(car: Dictionary) -> float:
    var value := 0.0
    for component in WEIGHTS:
        value += float(car["health"].get(component, 0.0)) * float(WEIGHTS[component])
    return snappedf(value, 0.01)

func eligible(car: Dictionary) -> bool:
    var h: Dictionary = car["health"]
    var faults: Dictionary = car.get("faults", {})
    return float(h["frenos"]) >= 40.0 and float(h["neumaticos"]) >= 40.0 and float(h["motor"]) >= 20.0 and not bool(faults.get("frenos", false)) and not bool(faults.get("motor", false))

func _record(car: Dictionary, event: String, amount: int) -> void:
    var item := {"car_id": int(car["id"]), "event": event, "amount": amount}
    ledger.append(item.duplicate(true))
    car["history"].append(item.duplicate(true))

func inspect(id: int) -> String:
    var car := find_car(id)
    if car.is_empty() or car["owner"] != "seller" or not car["listed"]:
        return "Oferta no disponible."
    if bool(car.get("inspected", false)):
        return "Este vehículo ya fue inspeccionado."
    const INSPECTION_COST := 200
    if balance < INSPECTION_COST:
        return "Créditos insuficientes para la inspección."
    balance -= INSPECTION_COST
    car["inspected"] = true
    _record(car, "inspeccion", -INSPECTION_COST)
    return "Inspección completada: condición %.1f/100. %s" % [condition(car), inspection_summary(car)]

func buy(id: int) -> String:
    var car := find_car(id)
    if car.is_empty() or car["owner"] != "seller" or not car["listed"]:
        return "La oferta ya no está disponible."
    var price: int = int(car["price"])
    if price < 0 or balance < price:
        return "Créditos insuficientes."
    balance -= price
    car["owner"] = "player"
    car["listed"] = false
    _record(car, "compra", -price)
    return "Compraste %s por %d Cr." % [car["model"], price]

func repair_quote(id: int, component: String) -> int:
    var car := find_car(id)
    if car.is_empty() or not WEIGHTS.has(component):
        return -1
    var amount := minf(25.0, 100.0 - float(car["health"][component]))
    var rate := {"motor": 65.0, "transmision": 55.0, "suspension": 38.0, "frenos": 32.0, "neumaticos": 28.0, "chasis": 60.0, "electrico": 25.0}
    var defects: Dictionary = car.get("faults", {})
    var surcharge := 900 if bool(defects.get(component, false)) else 0
    if amount <= 0.0 and surcharge == 0:
        return 0
    return maxi(100, ceili(amount * float(rate[component])) + surcharge)

func repair(id: int, component: String) -> String:
    var car := find_car(id)
    if car.is_empty() or car["owner"] != "player":
        return "Vehículo no disponible."
    var price := repair_quote(id, component)
    if price <= 0:
        return "Componente desconocido o ya reparado."
    if balance < price:
        return "Créditos insuficientes para reparar."
    var old := float(car["health"][component])
    balance -= price
    car["health"][component] = minf(100.0, old + 25.0)
    if car.has("faults"):
        car["faults"].erase(component)
    _record(car, "reparacion:" + component, -price)
    return "Reparación de %s completada por %d Cr." % [component, price]

func drive(id: int, km: int, severity: float = 2.0) -> String:
    var car := find_car(id)
    if car.is_empty() or car["owner"] != "player":
        return "Vehículo no disponible."
    if km <= 0 or km > 10000 or severity < 0.5 or severity > 5.0:
        return "Parámetros de recorrido inválidos."
    if not eligible(car):
        return "Vehículo no apto: revisá frenos, neumáticos y motor."
    car["km"] = int(car["km"]) + km
    for component in WEAR:
        car["health"][component] = snappedf(maxf(0.0, float(car["health"][component]) - float(WEAR[component]) * km * severity), 0.0001)
    car["history"].append({"event": "prueba", "km": km})
    return "Prueba de %d km completada." % km

func resale_quote(id: int) -> int:
    var car := find_car(id)
    if car.is_empty():
        return 0
    var quality := clampf(condition(car) / 100.0, 0.15, 1.0)
    var faults: Dictionary = car.get("faults", {})
    var defects_factor := 0.78 if not faults.is_empty() else 1.0
    var mileage_factor := clampf(1.0 - maxf(0.0, float(car["km"]) - 120000.0) / 600000.0, 0.65, 1.0)
    return maxi(0, floori(float(car["price"]) * 0.85 * (0.5 + quality * 0.5) * defects_factor * mileage_factor))

func sell(id: int) -> String:
    var car := find_car(id)
    if car.is_empty() or car["owner"] != "player":
        return "Solo podés vender vehículos propios."
    var quote := resale_quote(id)
    balance += quote
    car["owner"] = "sold"
    _record(car, "venta", quote)
    return "Vendiste %s por %d Cr." % [car["model"], quote]

func to_dict() -> Dictionary:
    return {"schema_version": SCHEMA_VERSION, "balance": balance, "cars": cars.duplicate(true), "ledger": ledger.duplicate(true)}

func from_dict(data: Dictionary) -> bool:
    if data.get("schema_version") != SCHEMA_VERSION or typeof(data.get("balance")) != TYPE_INT:
        return false
    if int(data["balance"]) < 0 or typeof(data.get("cars")) != TYPE_ARRAY or typeof(data.get("ledger")) != TYPE_ARRAY:
        return false
    var seen := {}
    for car in data["cars"]:
        if typeof(car) != TYPE_DICTIONARY:
            return false
        var id := int(car.get("id", 0))
        if id <= 0 or seen.has(id) or int(car.get("km", -1)) < 0 or int(car.get("price", -1)) < 0:
            return false
        seen[id] = true
        if not ["seller", "player", "sold"].has(car.get("owner", "")):
            return false
        if typeof(car.get("history")) != TYPE_ARRAY or typeof(car.get("health")) != TYPE_DICTIONARY:
            return false
        if typeof(car.get("faults", {})) != TYPE_DICTIONARY:
            return false
        for component in car.get("faults", {}):
            if not WEIGHTS.has(component) or typeof(car["faults"][component]) != TYPE_BOOL:
                return false
        if (car["owner"] == "seller") != bool(car.get("listed", false)):
            return false
        for component in WEIGHTS:
            if not car["health"].has(component):
                return false
            var v = car["health"][component]
            if typeof(v) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(v)) or float(v) < 0.0 or float(v) > 100.0:
                return false
    for entry in data["ledger"]:
        if typeof(entry) != TYPE_DICTIONARY:
            return false
    balance = int(data["balance"])
    cars.clear()
    for car in data["cars"]:
        cars.append(car.duplicate(true))
    ledger.clear()
    for entry in data["ledger"]:
        ledger.append(entry.duplicate(true))
    return true
