extends RefCounted

const Pricing = preload("res://scripts/market_pricing.gd")
const COMPONENTS := ["motor", "transmision", "suspension", "frenos", "neumaticos", "chasis", "electrico"]
const FAULT_POOL := ["motor", "transmision", "frenos", "chasis", "electrico", "suspension"]
# Seller profiles: asking markup over the true clean value, how far they will come
# down, how likely a hidden structural fault is, and how likely paperwork problems are.
const SELLERS := {
    "particular": {"weight": 0.60, "markup": [0.98, 1.14], "flex": [0.06, 0.16], "fault_chance": 0.25, "doc_chance": 0.20, "fraud_chance": 0.06, "warranty_days": 0},
    "agencia": {"weight": 0.25, "markup": [1.05, 1.15], "flex": [0.02, 0.06], "fault_chance": 0.06, "doc_chance": 0.02, "fraud_chance": 0.0, "warranty_days": 30},
    "urgente": {"weight": 0.15, "markup": [0.80, 0.96], "flex": [0.04, 0.10], "fault_chance": 0.35, "doc_chance": 0.25, "fraud_chance": 0.12, "warranty_days": 0},
}

static func _pick_seller(rng: RandomNumberGenerator) -> String:
    var roll := rng.randf()
    var cumulative := 0.0
    for kind in SELLERS:
        cumulative += float(SELLERS[kind]["weight"])
        if roll < cumulative:
            return kind
    return "particular"

# Builds a listing in the Economy car schema plus market fields (all ignored by the
# existing economy code and preserved by its save/load). Deterministic per rng state.
static func generate(entry: Dictionary, id: int, rng: RandomNumberGenerator, day: int = 0, index: float = 1.0) -> Dictionary:
    var year := mini(rng.randi_range(int(entry["year_min"]), int(entry["year_max"])), Pricing.CURRENT_YEAR)
    var age := float(Pricing.CURRENT_YEAR - year)
    var typical := Pricing.typical_km(entry, age)
    var km := roundi(typical * rng.randf_range(0.55, 1.55) / 100.0) * 100
    var seller := _pick_seller(rng)
    var profile: Dictionary = SELLERS[seller]
    # A rolled-back odometer: the car shows `km` but has more. Inspection reveals it.
    var hidden_km := 0
    if rng.randf() < float(profile["fraud_chance"]):
        hidden_km = km + roundi(rng.randf_range(20000.0, 80000.0) / 100.0) * 100
    var base := clampf(90.0 - float(maxi(hidden_km, km)) / 4000.0 + rng.randf_range(-12.0, 12.0), 25.0, 96.0)
    var health := {}
    for component in COMPONENTS:
        var wear_bias := -6.0 if component == "neumaticos" or component == "frenos" else 0.0
        health[component] = snappedf(clampf(base + wear_bias + rng.randf_range(-10.0, 10.0), 5.0, 99.0), 0.1)
    var faults := {}
    if rng.randf() < float(profile["fault_chance"]):
        faults[FAULT_POOL[rng.randi_range(0, FAULT_POOL.size() - 1)]] = true
    var condition := Pricing.condition_from_health(health)
    # The seller prices the car as if it had no hidden fault.
    var gnc := age >= 12.0 and rng.randf() < (0.40 if str(entry.get("era", "modern")) == "classic" else 0.25)
    var clean_ars := Pricing.fair_value_ars(entry, year, float(km), condition, {}, 0.0, index, Pricing.gnc_factor(entry, gnc))
    var markup_range: Array = profile["markup"]
    var flex_range: Array = profile["flex"]
    var markup := rng.randf_range(float(markup_range[0]), float(markup_range[1]))
    # Low-liquidity cars (classics) have more volatile asking prices.
    var volatility := rng.randf_range(0.94, 1.06) if str(entry.get("liquidity", "media")) == "baja" else 1.0
    var ask := maxi(100, roundi(float(Pricing.to_credits(clean_ars * markup * volatility)) / 50.0) * 50)
    var documents := {"deuda": 0, "prenda": false, "sin_titularidad": false, "vtv": true}
    if rng.randf() < float(profile["doc_chance"]):
        match rng.randi_range(0, 3):
            0:
                documents["deuda"] = maxi(20, roundi(float(ask) * rng.randf_range(0.01, 0.05)))
            1:
                documents["prenda"] = true
            2:
                documents["sin_titularidad"] = true
            _:
                documents["vtv"] = false
    var listing := {
        "id": id, "model": entry["name"], "km": km, "health": health, "faults": faults,
        "owner": "seller", "listed": true, "inspected": false, "price": ask,
        "upgrades": [], "history": [],
        "catalog_id": entry["id"], "year": year, "seller": seller, "documents": documents, "gnc": gnc,
        "flex": rng.randf_range(float(flex_range[0]), float(flex_range[1])),
        "listed_day": day, "doc_checked": false, "locked_until_day": 0,
        "service_km": maxi(km - rng.randi_range(0, 16000), 0), "warranty_days": int(profile["warranty_days"]),
    }
    if hidden_km > 0:
        listing["km_real"] = hidden_km
    return listing

# Turns an original offer (no market fields yet) into a market listing without
# changing its ID, model, mileage, condition or faults: it gets a year, seller,
# paperwork and a market-based asking price. Returns false if it already is one.
static func upgrade(car: Dictionary, entry: Dictionary, rng: RandomNumberGenerator, day: int = 0, index: float = 1.0) -> bool:
    if car.has("catalog_id") or entry.is_empty():
        return false
    var year := mini(rng.randi_range(int(entry["year_min"]), int(entry["year_max"])), Pricing.CURRENT_YEAR)
    var seller := _pick_seller(rng)
    var profile: Dictionary = SELLERS[seller]
    var markup_range: Array = profile["markup"]
    var flex_range: Array = profile["flex"]
    var condition := Pricing.condition_from_health(car["health"])
    var clean_ars := Pricing.fair_value_ars(entry, year, float(car["km"]), condition, {}, 0.0, index)
    var markup := rng.randf_range(float(markup_range[0]), float(markup_range[1]))
    car["catalog_id"] = entry["id"]
    car["year"] = year
    car["seller"] = seller
    car["documents"] = {"deuda": 0, "prenda": false, "sin_titularidad": false, "vtv": true}
    car["gnc"] = false
    car["flex"] = rng.randf_range(float(flex_range[0]), float(flex_range[1]))
    car["service_km"] = maxi(int(car["km"]) - rng.randi_range(0, 16000), 0)
    car["warranty_days"] = int(profile["warranty_days"])
    car["listed_day"] = day
    car["doc_checked"] = false
    car["locked_until_day"] = 0
    car["price"] = maxi(100, roundi(float(Pricing.to_credits(clean_ars * markup)) / 50.0) * 50)
    return true
