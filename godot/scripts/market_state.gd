extends RefCounted

# The market clock: days pass, prices drift, stale listings get cheaper, good deals
# sell to other buyers, new cars appear and buyers answer the player's ads. All
# randomness is seeded by (seed, day), so a given day always unfolds the same way.
const Pricing = preload("res://scripts/market_pricing.gd")
const Profiles = preload("res://scripts/market_profiles.gd")
const Listings = preload("res://scripts/market_listings.gd")
const Deal = preload("res://scripts/market_deal.gd")
const Upkeep = preload("res://scripts/market_upkeep.gd")
const Loans = preload("res://scripts/market_loans.gd")
const Money = preload("res://scripts/money.gd")
const TARGET_OFFERS := 48 # listings the market tries to keep on sale (36 originals plus extras)
const MAX_NEW_PER_DAY := 3
const CUT_INTERVAL := 7 # days between price cuts on an unsold listing
const CUT_RATE := 0.03
const INDEX_MIN := 0.85
const INDEX_MAX := 1.20
const TREND_MIN := 0.90 # demand drift of a single model
const TREND_MAX := 1.12

static func default_state() -> Dictionary:
    return {"day": 0, "index": 1.0, "seed": 42026, "deals": 0, "trends": {}, "credit": 50}

static func valid_state(data) -> bool:
    if typeof(data) != TYPE_DICTIONARY:
        return false
    for key in ["day", "index", "seed"]:
        if not data.has(key) or typeof(data[key]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(data[key])):
            return false
    if data.has("deals") and (typeof(data["deals"]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(data["deals"])) or float(data["deals"]) < 0.0):
        return false
    if data.has("credit") and (typeof(data["credit"]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(data["credit"])) or float(data["credit"]) < 0.0 or float(data["credit"]) > 100.0):
        return false
    if data.has("trends"):
        if typeof(data["trends"]) != TYPE_DICTIONARY:
            return false
        for model in data["trends"]:
            var value = data["trends"][model]
            if typeof(model) != TYPE_STRING or typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or float(value) < TREND_MIN or float(value) > TREND_MAX:
                return false
    return int(data["day"]) >= 0 and float(data["index"]) >= INDEX_MIN and float(data["index"]) <= INDEX_MAX

static func day(game) -> int:
    return Deal.day(game)

static func index(game) -> float:
    return Deal.price_index(game)

static func _rng(game, salt: int) -> RandomNumberGenerator:
    var rng := RandomNumberGenerator.new()
    rng.seed = hash([int(game.market["seed"]), int(game.market["day"]), salt])
    return rng

static func _seller_listings(game) -> Array:
    var listings: Array = []
    for car in game.cars:
        if car["owner"] == "seller" and bool(car["listed"]):
            listings.append(car)
    return listings

# Adds listings (up to `limit`) until the market holds TARGET_OFFERS. Models with
# fewer offers are more likely to appear. Returns how many were added.
static func ensure_listings(game, limit: int = TARGET_OFFERS) -> int:
    # Original offers become market listings (year, seller, paperwork, market price).
    for car in _seller_listings(game):
        if not car.has("catalog_id"):
            var own := RandomNumberGenerator.new()
            own.seed = hash([int(game.market["seed"]), int(car["id"])])
            Listings.upgrade(car, Profiles.entry_for(str(car["model"])), own, int(game.market["day"]), index(game) * Deal.trend(game, str(car["model"])))
    var added := 0
    var rng := _rng(game, 7)
    var models := Profiles.models()
    while added < limit and _seller_listings(game).size() < TARGET_OFFERS:
        var counts := {}
        for car in _seller_listings(game):
            counts[car["model"]] = int(counts.get(car["model"], 0)) + 1
        var total := 0.0
        var weights: Array = []
        for model in models:
            var weight := 1.0 / (1.0 + float(counts.get(model, 0)))
            weights.append(weight)
            total += weight
        var roll := rng.randf() * total
        var chosen: String = models[0]
        for i in range(models.size()):
            roll -= float(weights[i])
            if roll <= 0.0:
                chosen = models[i]
                break
        var listing := Listings.generate(Profiles.entry_for(chosen), Deal.next_id(game), rng, int(game.market["day"]), index(game) * Deal.trend(game, chosen))
        if not Deal.add_listing(game, listing):
            break
        added += 1
    return added

static func advance_day(game) -> Dictionary:
    game.market["day"] = int(game.market["day"]) + 1
    var today := int(game.market["day"])
    var rng := _rng(game, 1)
    game.market["index"] = clampf(float(game.market["index"]) + (1.0 - float(game.market["index"])) * 0.05 + rng.randf_range(-0.012, 0.012), INDEX_MIN, INDEX_MAX)
    var report := {"day": today, "sold": [], "new": 0, "cuts": 0, "offers": 0, "upkeep": {}, "loans": {}, "news": ""}
    report["news"] = _drift_trends(game, rng)
    for car in _seller_listings(game):
        if not car.has("listed_day"):
            car["listed_day"] = 0 # the original offers have been on sale since day 0
    # Good deals sell to other buyers faster.
    for car in _seller_listings(game):
        var price := int(car["price"])
        var bargain := clampf(float(Deal.fair_credits(game, int(car["id"]))) / float(maxi(price, 1)) - 0.95, 0.0, 0.5)
        var interest := float(Pricing.liquidity_of(Profiles.entry_for(str(car["model"])))["interest"])
        if rng.randf() < minf(0.03 + 0.25 * bargain, 0.30) * interest:
            report["sold"].append(str(car["model"]))
            game.cars.erase(car)
    # Unsold listings come down a little every week.
    for car in _seller_listings(game):
        var age := today - int(car.get("listed_day", today))
        if age > 0 and age % CUT_INTERVAL == 0:
            car["price"] = maxi(100, roundi(float(car["price"]) * (1.0 - CUT_RATE)))
            report["cuts"] += 1
    report["new"] = ensure_listings(game, rng.randi_range(0, MAX_NEW_PER_DAY))
    if today % Upkeep.MONTH == 0:
        report["loans"] = Loans.apply_month(game) # the bank collects first
        report["upkeep"] = Upkeep.apply_month(game, today)
    # Buyers answer the player's ads.
    for car in game.cars:
        if car["owner"] == "player" and int(car.get("sale_ask", 0)) > 0:
            car["offers"] = Deal.private_offers(game, int(car["id"]), int(car["sale_ask"]), today)
            report["offers"] += car["offers"].size()
    return report

# Moves every model's demand a little. Returns a headline about the biggest mover
# when it changed by at least 0.8 % today, or "".
static func _drift_trends(game, rng: RandomNumberGenerator) -> String:
    if typeof(game.market.get("trends")) != TYPE_DICTIONARY:
        game.market["trends"] = {}
    var trends: Dictionary = game.market["trends"]
    var headline := ""
    var biggest := 0.008
    for model in Profiles.models():
        var before := float(trends.get(model, 1.0))
        var after := clampf(before + (1.0 - before) * 0.04 + rng.randf_range(-0.012, 0.012), TREND_MIN, TREND_MAX)
        trends[model] = snappedf(after, 0.0001)
        var change := absf(after - before)
        if change > biggest:
            biggest = change
            headline = "%s la demanda de %s (%s%.1f %%)" % ["Sube" if after > before else "Baja", model, "+" if after > before else "-", change * 100.0]
    return headline

static func describe(report: Dictionary) -> String:
    var parts: Array[String] = ["Día %d" % int(report["day"])]
    var sold: Array = report["sold"]
    if not sold.is_empty():
        parts.append("se vendieron a otros compradores: " + ", ".join(PackedStringArray(sold)))
    if int(report["new"]) > 0:
        parts.append("%d publicaciones nuevas" % int(report["new"]))
    if int(report["cuts"]) > 0:
        parts.append("%d rebajas de precio" % int(report["cuts"]))
    if int(report["offers"]) > 0:
        parts.append("%d ofertas por tus autos" % int(report["offers"]))
    if str(report.get("news", "")) != "":
        parts.append(str(report["news"]))
    var loans: Dictionary = report.get("loans", {})
    if not loans.is_empty():
        if int(loans["paid"]) > 0:
            parts.append("cuotas del banco: pagaste %s" % Money.format(int(loans["paid"])))
        if int(loans["late"]) > 0:
            parts.append("¡%d cuota(s) atrasada(s) con recargo!" % int(loans["late"]))
        if int(loans["cleared"]) > 0:
            parts.append("terminaste de pagar %d préstamo(s)" % int(loans["cleared"]))
        if not loans["seized"].is_empty():
            parts.append("EL BANCO SECUESTRÓ: " + ", ".join(PackedStringArray(loans["seized"])))
    var upkeep: Dictionary = report.get("upkeep", {})
    if not upkeep.is_empty() and int(upkeep["cars"]) > 0:
        parts.append("gastos del mes de tus autos: pagaste %s" % Money.format(int(upkeep["paid"])) + (" y quedaron %s sin pagar (patente a deuda)" % Money.format(int(upkeep["unpaid"])) if int(upkeep["unpaid"]) > 0 else ""))
    return " · ".join(PackedStringArray(parts))
