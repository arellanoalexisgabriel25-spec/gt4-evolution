extends RefCounted

# Secured car loans (financiación prendaria). The bank lends a share of the price
# against a lien on the car; installments are collected every 30 market days. Late
# payments cost a fee and credit score; three missed installments in a row end with
# the car being seized. Rates and limits are game parameters, not bank offers.
const Money = preload("res://scripts/money.gd")
const TERMS := {12: 0.030, 24: 0.034, 36: 0.038} # monthly rate by term in months
const MAX_LOANS := 2
const MIN_SCORE := 30
const MIN_PRINCIPAL := 300
const ORIGINATION_RATE := 0.015 # bank fee on the principal
const PRENDA_RATE := 0.010 # lien registration on the principal
const LATE_RATE := 0.02 # penalty on a missed installment
const SEIZE_AFTER := 3
const SCORE_ON_TIME := 2
const SCORE_LATE := -5
const SCORE_CLEARED := 5
const SCORE_PAYOFF := 3
const SCORE_SEIZED := -35
const REASONS := {
    "term": "Plazo no disponible.",
    "score": "Tu calificación crediticia no alcanza para un préstamo.",
    "limit": "Ya tenés el máximo de préstamos prendarios abiertos.",
    "arrears": "Tenés cuotas atrasadas: ponete al día antes de pedir otro préstamo.",
    "small": "El monto a financiar es demasiado chico.",
}

static func score(game) -> int:
    var market = game.get("market")
    return int(market.get("credit", 50)) if typeof(market) == TYPE_DICTIONARY else 50

static func _add_score(game, change: int) -> void:
    var market = game.get("market")
    if typeof(market) == TYPE_DICTIONARY:
        market["credit"] = clampi(int(market.get("credit", 50)) + change, 0, 100)

static func has_loan(car: Dictionary) -> bool:
    return typeof(car.get("loan")) == TYPE_DICTIONARY

static func active_loans(game) -> int:
    var count := 0
    for car in game.cars:
        if car["owner"] == "player" and has_loan(car):
            count += 1
    return count

static func has_arrears(game) -> bool:
    for car in game.cars:
        if car["owner"] == "player" and has_loan(car) and int(car["loan"].get("missed", 0)) > 0:
            return true
    return false

# Share of the price the bank lends: 52 % at score 30, 60 % at 50, 75 % from 88.
static func ltv(game) -> float:
    return clampf(0.40 + 0.004 * float(score(game)), 0.40, 0.75)

static func monthly_rate(game, months: int) -> float:
    return maxf(float(TERMS.get(months, 0.04)) + float(50 - score(game)) * 0.00008, 0.005)

static func payment_for(principal: int, rate: float, months: int) -> int:
    return ceili(float(principal) * rate / (1.0 - pow(1.0 + rate, -float(months))))

# Terms the bank would give for a purchase at `price`.
static func offer(game, price: int, months: int) -> Dictionary:
    if not TERMS.has(months):
        return {"ok": false, "reason": "term"}
    if score(game) < MIN_SCORE:
        return {"ok": false, "reason": "score"}
    if active_loans(game) >= MAX_LOANS:
        return {"ok": false, "reason": "limit"}
    if has_arrears(game):
        return {"ok": false, "reason": "arrears"}
    var principal := floori(float(price) * ltv(game))
    if principal < MIN_PRINCIPAL:
        return {"ok": false, "reason": "small"}
    var rate := monthly_rate(game, months)
    var payment := payment_for(principal, rate, months)
    return {
        "ok": true, "months": months, "principal": principal, "rate": rate, "payment": payment,
        "fees": roundi(float(principal) * ORIGINATION_RATE) + roundi(float(principal) * PRENDA_RATE),
        "interest": payment * months - principal,
    }

static func reason_text(reason: String) -> String:
    return str(REASONS.get(reason, "Préstamo no disponible."))

static func attach(car: Dictionary, terms: Dictionary) -> void:
    car["loan"] = {"balance": float(terms["principal"]), "rate": float(terms["rate"]), "payment": int(terms["payment"]), "months": int(terms["months"]), "missed": 0}

static func payoff_amount(car: Dictionary) -> int:
    return ceili(float(car["loan"]["balance"])) if has_loan(car) else 0

static func months_left(loan: Dictionary) -> int:
    var balance := float(loan["balance"])
    var rate := float(loan["rate"])
    var left := 0
    while balance > 0.5 and left < 120:
        balance = balance * (1.0 + rate) - float(mini(int(loan["payment"]), ceili(balance * (1.0 + rate))))
        left += 1
    return left

static func describe(car: Dictionary) -> String:
    if not has_loan(car):
        return ""
    var loan: Dictionary = car["loan"]
    var text := "PRÉSTAMO PRENDARIO: cuota %s · saldo %s · faltan %d cuotas" % [Money.format(int(loan["payment"])), Money.format(payoff_amount(car)), months_left(loan)]
    if int(loan.get("missed", 0)) > 0:
        text += " · ¡%d CUOTA(S) ATRASADA(S)!" % int(loan["missed"])
    return text

# Early payoff of the whole balance; releases the lien.
static func payoff(game, id: int) -> String:
    var car: Dictionary = game.find_car(id)
    if car.is_empty() or car["owner"] != "player" or not has_loan(car):
        return "Ese auto no tiene un préstamo prendario."
    var amount := payoff_amount(car)
    if game.balance < amount:
        return "Saldo insuficiente para cancelar el préstamo (%s)." % Money.format(amount)
    game.balance -= amount
    game._record(car, "cancelacion_prestamo", -amount)
    car.erase("loan")
    _add_score(game, SCORE_PAYOFF)
    return "Cancelaste el préstamo de %s por %s." % [car["model"], Money.format(amount)]

static func seize(game, car: Dictionary) -> void:
    car["owner"] = "sold"
    car["listed"] = false
    car.erase("loan")
    car.erase("sale_ask")
    car.erase("offers")
    game._record(car, "secuestro", 0)
    _add_score(game, SCORE_SEIZED)

# Collects one installment from every financed car. Returns
# {"paid", "late", "seized": [models], "cleared"}.
static func apply_month(game) -> Dictionary:
    var report := {"paid": 0, "late": 0, "seized": [], "cleared": 0}
    for car in game.cars:
        if car["owner"] != "player" or not has_loan(car):
            continue
        var loan: Dictionary = car["loan"]
        var owed := float(loan["balance"]) * (1.0 + float(loan["rate"]))
        var due := mini(int(loan["payment"]), ceili(owed))
        var paid := mini(game.balance, due)
        if paid > 0:
            game.balance -= paid
            game._record(car, "cuota", -paid)
            report["paid"] += paid
        if paid >= due:
            loan["balance"] = owed - float(due)
            loan["missed"] = 0
            _add_score(game, SCORE_ON_TIME)
        else:
            loan["balance"] = owed - float(paid) + float(due) * LATE_RATE
            loan["missed"] = int(loan.get("missed", 0)) + 1
            report["late"] += 1
            _add_score(game, SCORE_LATE)
            if int(loan["missed"]) >= SEIZE_AFTER:
                report["seized"].append(str(car["model"]))
                seize(game, car)
                continue
        if float(loan["balance"]) <= 0.5:
            car.erase("loan")
            game._record(car, "prestamo_cancelado", 0)
            _add_score(game, SCORE_CLEARED)
            report["cleared"] += 1
    return report

# One-line description of the financing available for a purchase at `price`.
static func summary(game, price: int) -> String:
    var base := offer(game, price, 24)
    if not bool(base["ok"]):
        return "SIN FINANCIACIÓN: " + reason_text(str(base["reason"]))
    var quotes: Array[String] = []
    for months in TERMS:
        var terms := offer(game, price, months)
        quotes.append("%d meses: cuota %s" % [months, Money.format(int(terms["payment"]))])
    var entry := price - int(base["principal"]) + int(base["fees"])
    return "FINANCIACIÓN %d %% DEL PRECIO (calificación %d) · %s · entrega aprox. %s + gastos" % [roundi(ltv(game) * 100.0), score(game), " · ".join(PackedStringArray(quotes)), Money.format(entry)]
