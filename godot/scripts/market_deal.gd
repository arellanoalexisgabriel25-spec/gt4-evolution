extends RefCounted

# Buying, selling and paperwork on top of EvolutionEconomy. Every money movement goes
# through the economy's balance and ledger; nothing is charged twice and the balance
# never goes negative. `game` is duck-typed so this file has no dependency on it.
const Pricing = preload("res://scripts/market_pricing.gd")
const Profiles = preload("res://scripts/market_profiles.gd")
const MarketCatalog = preload("res://scripts/market_catalog.gd")
const Fees = preload("res://scripts/market_fees.gd")
const Negotiation = preload("res://scripts/market_negotiation.gd")
const Tuning = preload("res://scripts/tuning.gd")
const Money = preload("res://scripts/money.gd")
const Loans = preload("res://scripts/market_loans.gd")
const LIEN_RATE := 0.03 # cancelling a lien, on the price
const OWNERSHIP_RATE := 0.05 # regularising a car sold without registered ownership
const LOCK_DAYS := 7 # a seller who walked away will not talk again for a week
const SERVICE_INTERVAL := 10000 # km between basic services
const SERVICE_MIN_KM := 5000 # earlier than this the service is not needed yet
const SERVICE_MIN := 80
const SERVICE_MAX := 200
const SERVICE_OVERDUE_FACTOR := 0.97 # resale value with an overdue service
const SKILL_PER_DEAL := 0.004 # extra seller flexibility per completed deal, up to 4 points
const REASONS := {
    "unavailable": "La oferta ya no está disponible.",
    "invalid_price": "El precio no es válido: no podés pagar más que el pedido.",
    "seller_unavailable": "El vendedor no quiere tratar con vos por unos días.",
    "insufficient": "Saldo insuficiente para el precio, los gastos y los trámites.",
    "not_owned": "Solo podés vender vehículos propios.",
    "loan_shortfall": "La venta no alcanza para cancelar la deuda prendaria y no tenés saldo para cubrir la diferencia.",
}

static func day(game) -> int:
    var market = game.get("market")
    return int(market.get("day", 0)) if typeof(market) == TYPE_DICTIONARY else 0

static func price_index(game) -> float:
    var market = game.get("market")
    return float(market.get("index", 1.0)) if typeof(market) == TYPE_DICTIONARY else 1.0

# Demand for each model drifts on its own around the global index (1.0 = neutral).
static func trend(game, model: String) -> float:
    var market = game.get("market")
    if typeof(market) != TYPE_DICTIONARY or typeof(market.get("trends")) != TYPE_DICTIONARY:
        return 1.0
    return float(market["trends"].get(model, 1.0))

static func deals(game) -> int:
    var market = game.get("market")
    return int(market.get("deals", 0)) if typeof(market) == TYPE_DICTIONARY else 0

static func _count_deal(game) -> void:
    var market = game.get("market")
    if typeof(market) == TYPE_DICTIONARY:
        market["deals"] = int(market.get("deals", 0)) + 1

# Experienced traders get a little more out of sellers.
static func skill(game) -> float:
    return minf(0.04, SKILL_PER_DEAL * float(deals(game)))

static func service_overdue(car: Dictionary) -> bool:
    return int(car.get("km", 0)) - int(car.get("service_km", car.get("km", 0))) >= SERVICE_INTERVAL

static func describe(result: Dictionary) -> String:
    if str(result.get("reason", "")) == "loan_denied":
        return Loans.reason_text(str(result.get("detail", "")))
    if str(result.get("reason", "")) == "documents_revealed":
        return "En la escribanía aparecieron problemas: %s Total a pagar %s. Renegociá o juntá el saldo." % [str(result.get("report", "")), Money.format(int(result.get("total", 0)))]
    return str(REASONS.get(str(result.get("reason", "")), result.get("message", "Operación no disponible.")))

static func next_id(game) -> int:
    var highest := 0
    for car in game.cars:
        highest = maxi(highest, int(car["id"]))
    return highest + 1

static func add_listing(game, listing: Dictionary) -> bool:
    if listing.is_empty() or int(listing.get("id", 0)) <= 0 or not game.find_car(int(listing["id"])).is_empty():
        return false
    game.cars.append(listing)
    return true

static func _entry(car: Dictionary) -> Dictionary:
    var entry: Dictionary = Profiles.entry_for(str(car.get("model", "")))
    if entry.is_empty():
        entry = MarketCatalog.find(str(car.get("catalog_id", "")))
    if entry.is_empty():
        entry = MarketCatalog.find_by_name(str(car.get("model", "")))
    return entry

static func year_of(car: Dictionary) -> int:
    if car.has("year"):
        return int(car["year"])
    var entry := _entry(car)
    return floori(float(int(entry["year_min"]) + int(entry["year_max"])) / 2.0) if not entry.is_empty() else Pricing.CURRENT_YEAR

static func _upgrades_ars(car: Dictionary) -> float:
    var tuning = Tuning.new()
    var total := 0.0
    for part_id in car.get("upgrades", []):
        total += float(tuning.part_by_id(str(part_id)).get("price", 0))
    return Pricing.to_ars(total)

# True value in units (including hidden faults). Cars without a market profile fall
# back to their recorded price. index < 0 uses the game's current price index.
static func fair_credits(game, id: int, index: float = -1.0) -> int:
    var car: Dictionary = game.find_car(id)
    if car.is_empty():
        return 0
    var entry := _entry(car)
    if entry.is_empty():
        return int(car.get("price", 0))
    var market_index := (price_index(game) if index < 0.0 else index) * trend(game, str(car["model"]))
    var extra := Pricing.gnc_factor(entry, bool(car.get("gnc", false))) * Pricing.history_factor(car.get("history", []))
    if service_overdue(car):
        extra *= SERVICE_OVERDUE_FACTOR
    var kilometres := float(car.get("km_real", car["km"]))
    return Pricing.to_credits(Pricing.fair_value_ars(entry, year_of(car), kilometres, game.condition(car), car.get("faults", {}), _upgrades_ars(car), market_index, extra))

static func documents_cost(car: Dictionary, price: int) -> int:
    var docs: Dictionary = car.get("documents", {})
    var cost := int(docs.get("deuda", 0))
    if bool(docs.get("prenda", false)):
        cost += roundi(float(price) * LIEN_RATE)
    if bool(docs.get("sin_titularidad", false)):
        cost += roundi(float(price) * OWNERSHIP_RATE)
    if not bool(docs.get("vtv", true)):
        cost += Fees.VTV_COST
    return cost

static func documents_report(car: Dictionary) -> String:
    var docs: Dictionary = car.get("documents", {})
    var issues: Array[String] = []
    if int(docs.get("deuda", 0)) > 0:
        issues.append("deuda de patentes/multas por %s" % Money.format(int(docs["deuda"])))
    if bool(docs.get("prenda", false)):
        issues.append("prenda sobre el dominio")
    if bool(docs.get("sin_titularidad", false)):
        issues.append("el vendedor no figura como titular")
    if not bool(docs.get("vtv", true)):
        issues.append("VTV vencida")
    return "Documentación en regla." if issues.is_empty() else "Problemas: " + ", ".join(issues) + "."

static func inspection_price(game, id: int) -> int:
    return Fees.inspection_cost(fair_credits(game, id))

# Mechanic inspection, priced by the car instead of a flat fee.
static func inspect(game, id: int) -> String:
    var car: Dictionary = game.find_car(id)
    if car.is_empty() or car["owner"] != "seller" or not car["listed"]:
        return "Oferta no disponible."
    if bool(car.get("inspected", false)):
        return "Este vehículo ya fue inspeccionado."
    var cost := inspection_price(game, id)
    if game.balance < cost:
        return "Saldo insuficiente para la inspección (%s)." % Money.format(cost)
    game.balance -= cost
    car["inspected"] = true
    game._record(car, "inspeccion", -cost)
    var extra := ""
    if car.has("km_real"):
        car["km_claimed"] = int(car["km"])
        car["km"] = int(car["km_real"])
        car.erase("km_real")
        car["odometer_fraud"] = true
        extra += " ¡Odómetro adulterado! Marcaba %d km y el kilometraje real es %d." % [int(car["km_claimed"]), int(car["km"])]
    if service_overdue(car):
        extra += " El service está vencido."
    return "Inspección completada (%s): condición %.1f/100. %s%s" % [Money.format(cost), game.condition(car), game.inspection_summary(car), extra]

static func check_domain(game, id: int) -> String:
    var car: Dictionary = game.find_car(id)
    if car.is_empty() or car["owner"] != "seller" or not car["listed"]:
        return "Oferta no disponible."
    if bool(car.get("doc_checked", false)):
        return "El informe de dominio ya fue pedido. " + documents_report(car)
    if game.balance < Fees.DOMAIN_REPORT:
        return "Saldo insuficiente para el informe de dominio."
    game.balance -= Fees.DOMAIN_REPORT
    car["doc_checked"] = true
    game._record(car, "informe_dominio", -Fees.DOMAIN_REPORT)
    return documents_report(car)

# Haggling session for a listing. Problems the buyer has verified (by inspection or
# domain report) justify a concession, except at dealerships. null when unavailable.
static func start_negotiation(game, id: int, today: int = -1):
    var now := day(game) if today < 0 else today
    var car: Dictionary = game.find_car(id)
    if car.is_empty() or car["owner"] != "seller" or not car["listed"] or int(car.get("locked_until_day", 0)) > now:
        return null
    var ask := int(car["price"])
    var concession := 0
    if str(car.get("seller", "particular")) != "agencia":
        if bool(car.get("doc_checked", false)):
            concession += int(float(documents_cost(car, ask)) * 0.5)
        if bool(car.get("inspected", false)) and not car.get("faults", {}).is_empty():
            var entry := _entry(car)
            if not entry.is_empty():
                var loss := Pricing.fault_loss(car["faults"])
                concession += int(float(Pricing.to_credits(Pricing.reference_ars(entry) * loss)) * 0.5)
    if bool(car.get("odometer_fraud", false)) and str(car.get("seller", "particular")) != "agencia":
        var entry := _entry(car)
        if not entry.is_empty():
            var extra_value := Pricing.fair_value_ars(entry, year_of(car), float(car["km_claimed"]), game.condition(car)) - Pricing.fair_value_ars(entry, year_of(car), float(car["km"]), game.condition(car))
            concession += int(float(Pricing.to_credits(maxf(extra_value, 0.0))) * 0.5)
    var reserve := Negotiation.reserve_for(ask, float(car.get("flex", 0.08)), now - int(car.get("listed_day", now)), concession, skill(game))
    return Negotiation.new(ask, reserve)

static func lock_seller(game, id: int, today: int = -1) -> void:
    var car: Dictionary = game.find_car(id)
    if not car.is_empty():
        car["locked_until_day"] = (day(game) if today < 0 else today) + LOCK_DAYS

# Full cost of buying at `price` (-1 = the ask): fees plus every paperwork cost.
static func quote_purchase(game, id: int, price: int = -1) -> Dictionary:
    var car: Dictionary = game.find_car(id)
    if car.is_empty() or car["owner"] != "seller" or not car["listed"]:
        return {"ok": false, "reason": "unavailable"}
    var final_price := int(car["price"]) if price < 0 else price
    if final_price <= 0 or final_price > int(car["price"]):
        return {"ok": false, "reason": "invalid_price"}
    var fees := Fees.purchase_fees(final_price, bool(car.get("doc_checked", false)))
    var docs := documents_cost(car, final_price)
    return {"ok": true, "price": final_price, "fees": fees, "documents": docs, "documents_known": bool(car.get("doc_checked", false)), "total": final_price + int(fees["total"]) + docs}

# Pays and transfers the car. Hidden paperwork costs are discovered at the notary: if
# the balance cannot cover them nothing is charged beyond the verification fee, and
# the problems are revealed so the player can renegotiate.
static func purchase(game, id: int, price: int = -1, today: int = -1, financing_months: int = 0) -> Dictionary:
    var quote := quote_purchase(game, id, price)
    if not bool(quote["ok"]):
        return quote
    var terms := {}
    if financing_months > 0:
        terms = Loans.offer(game, int(quote["price"]), financing_months)
        if not bool(terms["ok"]):
            return {"ok": false, "reason": "loan_denied", "detail": str(terms["reason"])}
    var now := day(game) if today < 0 else today
    var car: Dictionary = game.find_car(id)
    if int(car.get("locked_until_day", 0)) > now:
        return {"ok": false, "reason": "seller_unavailable"}
    var total := int(quote["total"])
    # With a loan the bank pays the principal; the buyer adds the loan's own fees.
    var cash_needed := total if terms.is_empty() else total - int(terms["principal"]) + int(terms["fees"])
    if game.balance < cash_needed:
        if not bool(quote["documents_known"]) and int(quote["documents"]) > 0 and game.balance >= Fees.DOMAIN_REPORT:
            game.balance -= Fees.DOMAIN_REPORT
            car["doc_checked"] = true
            game._record(car, "informes", -Fees.DOMAIN_REPORT)
            return {"ok": false, "reason": "documents_revealed", "report": documents_report(car), "total": total}
        return {"ok": false, "reason": "insufficient", "total": cash_needed}
    var fees: Dictionary = quote["fees"]
    game.balance -= cash_needed
    car["owner"] = "player"
    car["listed"] = false
    game._record(car, "compra", -int(quote["price"]))
    if not terms.is_empty():
        game._record(car, "prestamo", int(terms["principal"]))
        game._record(car, "gastos_prenda", -int(terms["fees"]))
        Loans.attach(car, terms)
    for line in ["arancel", "sellos", "verificacion", "formulario_08", "informes", "gestoria"]:
        if int(fees[line]) > 0:
            game._record(car, line, -int(fees[line]))
    if int(quote["documents"]) > 0:
        game._record(car, "regularizacion_documentos", -int(quote["documents"]))
    car["documents"] = {"deuda": 0, "prenda": false, "sin_titularidad": false, "vtv": true}
    car["bought_day"] = now
    car["vtv_day"] = now
    if int(car.get("warranty_days", 0)) > 0:
        car["warranty_until"] = now + int(car["warranty_days"])
    var surprise := ""
    if car.has("km_real"):
        surprise = " ¡El odómetro estaba adulterado! Tiene %d km reales y no %d." % [int(car["km_real"]), int(car["km"])]
        car["odometer_fraud"] = true
        car["km"] = int(car["km_real"])
        car.erase("km_real")
        game._record(car, "odometro_adulterado", 0)
    _count_deal(game)
    var financing := "" if terms.is_empty() else " Financiado: cuota de %s durante %d meses." % [Money.format(int(terms["payment"])), int(terms["months"])]
    return {"ok": true, "price": int(quote["price"]), "total": cash_needed, "message": "Compraste %s por %s (con gastos y trámites %s).%s%s" % [car["model"], Money.format(int(quote["price"])), Money.format(total), financing, surprise]}

# Dealer's immediate offer: 73-87 % of the true value by condition, a little more for
# liquid cars and less for classics. Paperwork debts are settled out of the payment.
static func dealer_gross(game, id: int, index: float = -1.0) -> int:
    var car: Dictionary = game.find_car(id)
    if car.is_empty() or car["owner"] != "player":
        return 0
    var factor := 0.80 + 0.07 * clampf((game.condition(car) - 50.0) / 50.0, -1.0, 1.0) + float(Pricing.liquidity_of(_entry(car))["dealer"])
    return maxi(0, floori(float(fair_credits(game, id, index)) * factor))

static func dealer_quote(game, id: int, index: float = -1.0) -> int:
    var gross := dealer_gross(game, id, index)
    var car: Dictionary = game.find_car(id)
    return maxi(0, gross - documents_cost(car, gross)) if not car.is_empty() else 0

# Cash change of a sale: what the buyer pays minus paperwork debts, fees and the
# payoff of the car's loan (negative when the sale does not cover the loan).
static func sale_net(car: Dictionary, gross: int, fee: int) -> int:
    return gross - mini(documents_cost(car, gross), gross) - fee - Loans.payoff_amount(car)

static func _settle_sale(game, car: Dictionary, gross: int, fee: int) -> int:
    var owed := mini(documents_cost(car, gross), gross)
    var payoff := Loans.payoff_amount(car)
    var net := gross - owed - fee - payoff
    if payoff > 0:
        car.erase("loan")
        game._record(car, "cancelacion_prestamo", -payoff)
    game.balance += net
    car["owner"] = "sold"
    _clear_sale(car)
    _count_deal(game)
    game._record(car, "venta", gross)
    if owed > 0:
        game._record(car, "regularizacion_documentos", -owed)
    if fee > 0:
        game._record(car, "gestoria_venta", -fee)
    return net

static func sell_dealer(game, id: int, index: float = -1.0) -> Dictionary:
    var car: Dictionary = game.find_car(id)
    if car.is_empty() or car["owner"] != "player":
        return {"ok": false, "reason": "not_owned"}
    var gross := dealer_gross(game, id, index)
    if game.balance + sale_net(car, gross, 0) < 0:
        return {"ok": false, "reason": "loan_shortfall"}
    var net := _settle_sale(game, car, gross, 0)
    return {"ok": true, "price": gross, "net": net, "message": "La agencia compró %s por %s (neto %s)" % [car["model"], Money.format(gross), Money.format(net)]}

# Chance per day that a buyer shows up falls steeply as the asking price rises above value.
static func daily_interest(asking: int, fair: int, liquidity_multiplier: float = 1.0) -> float:
    if fair <= 0:
        return 0.0
    return clampf(0.35 * exp(-6.0 * (float(asking) / float(fair) - 0.95)) * liquidity_multiplier, 0.02, 0.60)

# Buyer offers received on a given day for a car listed at `asking` (0 to 2 offers).
# Deterministic for the same car, day and price.
static func private_offers(game, id: int, asking: int, today: int, index: float = -1.0) -> Array:
    var car: Dictionary = game.find_car(id)
    var offers: Array = []
    if car.is_empty() or car["owner"] != "player" or asking <= 0:
        return offers
    var fair := fair_credits(game, id, index)
    var rng := RandomNumberGenerator.new()
    rng.seed = hash([id, today, asking, int(car["km"])])
    var chance := daily_interest(asking, fair, float(Pricing.liquidity_of(_entry(car))["interest"]))
    # Buyers pay for what the car is worth, not for what the seller wants: an
    # inflated ad draws fewer offers and none above the car's value.
    for slot in range(2):
        if rng.randf() < chance:
            var valuation := float(fair) * rng.randf_range(0.92, 1.08)
            offers.append(maxi(1, roundi(minf(float(asking) * 0.97, valuation))))
    return offers

static func _clear_sale(car: Dictionary) -> void:
    car.erase("sale_ask")
    car.erase("sale_day")
    car.erase("offers")

# Publishes an owned car for private sale; buyers answer each market day.
static func publish(game, id: int, ask: int) -> Dictionary:
    var car: Dictionary = game.find_car(id)
    if car.is_empty() or car["owner"] != "player":
        return {"ok": false, "reason": "not_owned"}
    if ask <= 0:
        return {"ok": false, "reason": "invalid_price"}
    car["sale_ask"] = ask
    car["sale_day"] = day(game)
    car["offers"] = []
    return {"ok": true, "message": "%s publicado por %s. Esperá un día para recibir ofertas." % [car["model"], Money.format(ask)]}

static func withdraw(game, id: int) -> void:
    var car: Dictionary = game.find_car(id)
    if not car.is_empty() and car["owner"] == "player":
        _clear_sale(car)

static func sell_private(game, id: int, price: int) -> Dictionary:
    var car: Dictionary = game.find_car(id)
    if car.is_empty() or car["owner"] != "player":
        return {"ok": false, "reason": "not_owned"}
    if price <= 0:
        return {"ok": false, "reason": "invalid_price"}
    var private_fee := int(Fees.sale_fees(price, "particular")["total"])
    if game.balance + sale_net(car, price, private_fee) < 0:
        return {"ok": false, "reason": "loan_shortfall"}
    var net := _settle_sale(game, car, price, private_fee)
    return {"ok": true, "price": price, "net": net, "message": "Vendiste %s por %s (neto %s)" % [car["model"], Money.format(price), Money.format(net)]}

# Accepts one of the offers currently on the table for a published car.
static func accept_offer(game, id: int, amount: int) -> Dictionary:
    var car: Dictionary = game.find_car(id)
    if car.is_empty() or car["owner"] != "player" or not car.get("offers", []).has(amount):
        return {"ok": false, "reason": "unavailable"}
    return sell_private(game, id, amount)

# Net result of a car over its whole life with the player (sales minus purchases and costs).
static func net_result(game, id: int) -> int:
    var total := 0
    for entry in game.ledger:
        if int(entry.get("car_id", -1)) == id:
            total += int(entry.get("amount", 0))
    return total

# --- Service, warranty and price guide ---

static func service_cost(game, id: int) -> int:
    return clampi(roundi(float(fair_credits(game, id)) * 0.009), SERVICE_MIN, SERVICE_MAX)

# Basic service every 10,000 km: resets the counter, counts as documented maintenance.
static func do_service(game, id: int) -> String:
    var car: Dictionary = game.find_car(id)
    if car.is_empty() or car["owner"] != "player":
        return str(REASONS["not_owned"])
    if int(car["km"]) - int(car.get("service_km", car["km"])) < SERVICE_MIN_KM:
        return "El service está al día: todavía no hace falta."
    var cost := service_cost(game, id)
    if game.balance < cost:
        return "Saldo insuficiente para el service (%s)." % Money.format(cost)
    game.balance -= cost
    car["service_km"] = int(car["km"])
    game._record(car, "service", -cost)
    return "Service realizado por %s." % Money.format(cost)

# Dealerships repair hidden faults found during the first 30 days, once.
static func warranty_days_left(game, car: Dictionary) -> int:
    return maxi(int(car.get("warranty_until", 0)) - day(game), 0) if car.get("owner") == "player" else 0

static func claim_warranty(game, id: int) -> String:
    var car: Dictionary = game.find_car(id)
    if car.is_empty() or car["owner"] != "player":
        return str(REASONS["not_owned"])
    if warranty_days_left(game, car) <= 0:
        return "La garantía no está vigente."
    if car.get("faults", {}).is_empty():
        return "No hay averías estructurales cubiertas por la garantía."
    var fixed: Array = car["faults"].keys()
    car["faults"] = {}
    car.erase("warranty_until")
    game._record(car, "garantia", 0)
    return "La agencia reparó sin cargo: %s." % ", ".join(PackedStringArray(fixed))

static func guide_text(car_or_model) -> String:
    var model := str(car_or_model.get("model", "")) if typeof(car_or_model) == TYPE_DICTIONARY else str(car_or_model)
    var entry: Dictionary = Profiles.entry_for(model)
    if entry.is_empty():
        return ""
    var guide: Dictionary = Pricing.tier_guide(entry, 1.0)
    return "GUÍA DE PRECIOS · REGULAR %s a %s · BUEN ESTADO %s a %s · MUY BUENO %s a %s" % [Money.format(int(guide["regular"][0])), Money.format(int(guide["regular"][1])), Money.format(int(guide["good"][0])), Money.format(int(guide["good"][1])), Money.format(int(guide["very_good"][0])), Money.format(int(guide["very_good"][1]))]
