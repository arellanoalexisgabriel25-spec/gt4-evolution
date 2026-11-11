extends RefCounted

# Costs of owning a car, charged every 30 market days (the player controls time with
# "wait a day"): provincial plate tax (exempt after 25 years), insurance and the yearly
# technical inspection. Ranges follow the Buenos Aires document. Whatever the balance
# cannot cover is never lost: unpaid plate tax becomes a debt that travels with the car
# and is settled when it is sold, unpaid insurance is counted, and an unpaid VTV lapses.
const Deal = preload("res://scripts/market_deal.gd")
const Money = preload("res://scripts/money.gd")
const Fees = preload("res://scripts/market_fees.gd")
const Pricing = preload("res://scripts/market_pricing.gd")
const MONTH := 30
const VTV_INTERVAL := 365
const VTV_MIN_AGE := 3
const PATENTE_RATE := 0.025 # per year, on the value (document range 1.5-3.5 %)
const EXEMPT_AGE := 25
const SEGURO_RATE := 0.006 # per month, on the value, bounded to 40-120
const SEGURO_MIN := 40
const SEGURO_MAX := 120
const FREE_GARAGE_SLOTS := 2 # cars kept at home for free
const COCHERA := 55 # monthly parking for each additional car (document range 30-80)

static func monthly_patente(value: int, age: int) -> int:
    return 0 if age >= EXEMPT_AGE else roundi(float(value) * PATENTE_RATE / 12.0)

static func monthly_seguro(value: int) -> int:
    return clampi(roundi(float(value) * SEGURO_RATE), SEGURO_MIN, SEGURO_MAX)

static func vtv_due(car: Dictionary, age: int, today: int) -> bool:
    return age >= VTV_MIN_AGE and today - int(car.get("vtv_day", car.get("bought_day", 0))) >= VTV_INTERVAL

# Cars are kept in order of purchase: from the third on, each needs paid parking.
static func garage_rank(game, car: Dictionary) -> int:
    var rank := 0
    for other in game.cars:
        if other["owner"] == "player" and int(other["id"]) < int(car["id"]):
            rank += 1
    return rank

static func estimate(game, car: Dictionary) -> Dictionary:
    var value := Deal.fair_credits(game, int(car["id"]))
    var age := Pricing.CURRENT_YEAR - Deal.year_of(car)
    var patente := monthly_patente(value, age)
    var seguro := monthly_seguro(value)
    var cochera := COCHERA if garage_rank(game, car) >= FREE_GARAGE_SLOTS else 0
    return {"patente": patente, "seguro": seguro, "cochera": cochera, "total": patente + seguro + cochera}

static func describe(game, car: Dictionary) -> String:
    var cost := estimate(game, car)
    var docs: Dictionary = car.get("documents", {})
    var text := "GASTO MENSUAL ESTIMADO %s (patente %s + seguro %s%s)" % [Money.format(int(cost["total"])), Money.format(int(cost["patente"])), Money.format(int(cost["seguro"])), " + cochera " + Money.format(int(cost["cochera"])) if int(cost["cochera"]) > 0 else ""]
    if int(docs.get("deuda", 0)) > 0:
        text += " · DEUDA DE PATENTES " + Money.format(int(docs["deuda"]))
    if not bool(docs.get("vtv", true)):
        text += " · VTV VENCIDA"
    return text

static func _pay(game, car: Dictionary, event: String, due: int) -> int:
    var paid := mini(game.balance, maxi(due, 0))
    if paid > 0:
        game.balance -= paid
        game._record(car, event, -paid)
    return paid

# Charges one month to every owned car. Returns {"paid", "unpaid", "cars"}.
static func apply_month(game, today: int) -> Dictionary:
    var report := {"paid": 0, "unpaid": 0, "cars": 0}
    for car in game.cars:
        if car["owner"] != "player":
            continue
        report["cars"] += 1
        if typeof(car.get("documents")) != TYPE_DICTIONARY:
            car["documents"] = {"deuda": 0, "prenda": false, "sin_titularidad": false, "vtv": true}
        var cost := estimate(game, car)
        var patente_paid := _pay(game, car, "patente", int(cost["patente"]))
        car["documents"]["deuda"] = int(car["documents"].get("deuda", 0)) + int(cost["patente"]) - patente_paid
        var cochera_paid := _pay(game, car, "cochera", int(cost["cochera"]))
        car["documents"]["deuda"] = int(car["documents"].get("deuda", 0)) + int(cost["cochera"]) - cochera_paid
        report["paid"] += cochera_paid
        report["unpaid"] += int(cost["cochera"]) - cochera_paid
        var seguro_paid := _pay(game, car, "seguro", int(cost["seguro"]))
        if seguro_paid < int(cost["seguro"]):
            car["uninsured_months"] = int(car.get("uninsured_months", 0)) + 1
        report["paid"] += patente_paid + seguro_paid
        report["unpaid"] += int(cost["patente"]) - patente_paid + int(cost["seguro"]) - seguro_paid
        var age := Pricing.CURRENT_YEAR - Deal.year_of(car)
        if vtv_due(car, age, today):
            var vtv_paid := _pay(game, car, "vtv", Fees.VTV_COST) if game.balance >= Fees.VTV_COST else 0
            if vtv_paid > 0:
                car["documents"]["vtv"] = true
                car["vtv_day"] = today
                report["paid"] += vtv_paid
            else:
                car["documents"]["vtv"] = false
                report["unpaid"] += Fees.VTV_COST
    return report
