extends RefCounted


# Market value model. Pure functions over catalog entries (see market_catalog.gd).
# Values are computed in ARS (the unit of the source documents) and converted to
# game credits with ARS_PER_CREDIT. Coefficients are game balance, not appraisals.
const CURRENT_YEAR := 2026
const ARS_PER_CREDIT := 1000.0 # 1 credit = 1,000 ARS (12,000 starting credits = 12 M ARS)
const REFERENCE_AGE := 7.5 # the source price ranges describe 5-10 year old units
const REFERENCE_CONDITION := 75.0
const CLASSIC_TYPICAL_KM := 150000.0
# Same weights as Economy.condition(); kept here so pricing has no dependency on it.
const WEIGHTS := {"motor": 0.25, "transmision": 0.15, "suspension": 0.15, "frenos": 0.15, "neumaticos": 0.10, "chasis": 0.15, "electrico": 0.05}
# Share of the car's value lost when a component has a known structural fault.
const FAULT_VALUE := {"motor": 0.15, "transmision": 0.10, "suspension": 0.05, "frenos": 0.04, "neumaticos": 0.02, "chasis": 0.15, "electrico": 0.04}
# Share of the reference value that restoring a component from 0 to 100 costs.
const REPAIR_SHARE := {"motor": 0.22, "transmision": 0.14, "suspension": 0.10, "frenos": 0.06, "neumaticos": 0.05, "chasis": 0.30, "electrico": 0.05}
# Value multiplier by condition (0-100), calibrated on the three condition tiers of
# the Buenos Aires document: "regular" ~0.6x, "buen estado" 1.0x, "muy bueno" ~1.4x
# (the rest of that premium comes from low mileage).
const CONDITION_ANCHORS := [[0.0, 0.20], [25.0, 0.35], [50.0, 0.62], [75.0, 1.0], [90.0, 1.22], [100.0, 1.32]]
const MAX_TYPICAL_KM := 250000.0
# Older cars on gas (GNC) are worth a little less to collectors and a little more as work cars.
const GNC_COLLECTOR := 0.95
const GNC_WORKHORSE := 1.03
# How easily each liquidity class sells: buyer interest multiplier and dealer adjustment.
const LIQUIDITY := {"alta": {"interest": 1.30, "dealer": 0.02}, "media": {"interest": 1.0, "dealer": 0.0}, "baja": {"interest": 0.60, "dealer": -0.04}}
const UPGRADE_RETENTION := 0.45 # fraction of a fitted part's price that adds to resale value

static func to_credits(ars: float) -> int:
    return maxi(0, roundi(ars / ARS_PER_CREDIT))

static func to_ars(credits: float) -> float:
    return credits * ARS_PER_CREDIT

static func condition_from_health(health: Dictionary) -> float:
    var value := 0.0
    for component in WEIGHTS:
        value += clampf(float(health.get(component, 0.0)), 0.0, 100.0) * float(WEIGHTS[component])
    return value

# Share of new value kept at a given age: falls quickly, then flattens at 35 %.
static func depreciation(age: float) -> float:
    return 0.35 + 0.65 * exp(-0.10 * maxf(age, 0.0))

# Reference price (ARS) of a typical unit. Game profiles carry it as "ref_ars";
# catalog entries give a price range and use its geometric mean.
static func reference_ars(entry: Dictionary) -> float:
    if entry.has("ref_ars"):
        return float(entry["ref_ars"])
    return sqrt(float(entry["price_min"]) * float(entry["price_max"]))

static func reference_age(entry: Dictionary) -> float:
    if entry.has("ref_year"):
        return maxf(float(CURRENT_YEAR) - float(entry["ref_year"]), 1.0)
    if str(entry.get("era", "modern")) == "classic":
        return maxf(float(CURRENT_YEAR) - (float(entry["year_min"]) + float(entry["year_max"])) / 2.0, 1.0)
    return REFERENCE_AGE

static func typical_km(entry: Dictionary, age: float) -> float:
    if str(entry.get("era", "modern")) == "classic":
        return CLASSIC_TYPICAL_KM
    return minf(12000.0 * maxf(age, 0.5), MAX_TYPICAL_KM)

static func age_factor(entry: Dictionary, age: float) -> float:
    return depreciation(age) / depreciation(reference_age(entry))

# Restoring condition pays: 50 -> 0.62x, 75 -> 1.0x, 100 -> 1.32x (piecewise linear).
static func condition_factor(condition: float) -> float:
    var value := clampf(condition, 0.0, 100.0)
    for i in range(CONDITION_ANCHORS.size() - 1):
        var low: Array = CONDITION_ANCHORS[i]
        var high: Array = CONDITION_ANCHORS[i + 1]
        if value <= float(high[0]):
            return lerpf(float(low[1]), float(high[1]), (value - float(low[0])) / (float(high[0]) - float(low[0])))
    return float(CONDITION_ANCHORS[CONDITION_ANCHORS.size() - 1][1])

static func liquidity_of(entry: Dictionary) -> Dictionary:
    return LIQUIDITY.get(str(entry.get("liquidity", "media")), LIQUIDITY["media"])

# GNC conversion: collectors dislike it, daily drivers value it.
static func gnc_factor(entry: Dictionary, installed: bool) -> float:
    if not installed:
        return 1.0
    return GNC_COLLECTOR if str(entry.get("era", "modern")) == "classic" else GNC_WORKHORSE

# Documented maintenance helps resale; crash damage hurts it.
static func history_factor(history: Array) -> float:
    var repairs := 0
    var damage := 0.0
    for item in history:
        var event := str(item.get("event", ""))
        if event.begins_with("reparacion:") or event == "service":
            repairs += 1
        elif event == "danos":
            damage += float(item.get("points", 0.0))
    return clampf(1.0 + minf(0.04, 0.01 * float(repairs)) - minf(0.12, 0.002 * damage), 0.85, 1.05)

static func km_factor(km: float, typical: float) -> float:
    return clampf(1.0 - 2.5e-6 * (km - typical), 0.60, 1.12)

static func fault_loss(faults: Dictionary) -> float:
    var loss := 0.0
    for component in faults:
        if bool(faults[component]) and FAULT_VALUE.has(component):
            loss += float(FAULT_VALUE[component])
    return minf(loss, 0.5)

# Value in ARS of a unit. index: market price index (1.0 = reference market).
# upgrades_ars: price of fitted parts (retained at UPGRADE_RETENTION).
static func fair_value_ars(entry: Dictionary, year: int, km: float, condition: float, faults: Dictionary = {}, upgrades_ars: float = 0.0, index: float = 1.0, extra: float = 1.0) -> float:
    var age := maxf(float(CURRENT_YEAR - year), 0.0)
    var base := reference_ars(entry)
    var value := base * age_factor(entry, age) * km_factor(km, typical_km(entry, age)) * condition_factor(condition) * (1.0 - fault_loss(faults)) * maxf(index, 0.1) * maxf(extra, 0.1)
    return maxf(value + UPGRADE_RETENTION * maxf(upgrades_ars, 0.0), 0.0)

static func fair_value_credits(entry: Dictionary, year: int, km: float, condition: float, faults: Dictionary = {}, upgrades_ars: float = 0.0, index: float = 1.0, extra: float = 1.0) -> int:
    return to_credits(fair_value_ars(entry, year, km, condition, faults, upgrades_ars, index, extra))

# Cost in credits of restoring `points` of a component. A known fault adds 60 % of
# its value loss as a surcharge. Costs scale with the car, like real parts.
static func repair_cost_credits(entry: Dictionary, component: String, points: float, faulty: bool = false) -> int:
    if not REPAIR_SHARE.has(component):
        return -1
    var base := reference_ars(entry)
    var cost := base * float(REPAIR_SHARE[component]) * clampf(points, 0.0, 100.0) / 100.0
    if faulty:
        cost += base * float(FAULT_VALUE[component]) * 0.60
    return maxi(to_credits(cost), 1)

# Orientative price guide for a model, in units: three condition tiers. Models with
# tiers in the price document use them (scaled by the market index); the others
# derive them from the reference value with the same condition curve, +-12 %.
static func tier_guide(entry: Dictionary, index: float = 1.0) -> Dictionary:
    var tiers = entry.get("tiers", {})
    if typeof(tiers) == TYPE_DICTIONARY and not tiers.is_empty():
        var scaled := {}
        for name in tiers:
            scaled[name] = [roundi(float(tiers[name][0]) * index), roundi(float(tiers[name][1]) * index)]
        return scaled
    var reference := to_credits(reference_ars(entry)) * maxf(index, 0.1)
    var guide := {}
    for pair in [["regular", 0.62], ["good", 1.0], ["very_good", 1.38]]:
        var centre: float = reference * float(pair[1])
        guide[pair[0]] = [roundi(centre * 0.88), roundi(centre * 1.12)]
    return guide
