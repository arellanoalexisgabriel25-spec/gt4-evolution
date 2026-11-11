extends RefCounted

const Catalog = preload("res://scripts/car_catalog.gd")
const CURRENT_YEAR := 2026

# Market reference for every car the game can drive. Prices are in units
# (1 unit = ARS 1,000). Sources, in order of preference:
#  - PRIORITY: the "priority models" table of the Buenos Aires document, with three
#    condition tiers. "good" is the reference value (condition 75, typical mileage) at
#    the middle of the typical years.
#  - LISTED: the document's list of common models (5-10 year old units, good condition).
#  - the game's own catalog / economy price for the rest (imports, 147 Vivace,
#    128 Súper Europa, 500 Sport). These are PROVISIONAL.
# "liquidity" says how easily the car sells (alta / media / baja).
const PRIORITY := {
    "Fiat 133": {"years": [1977, 1982], "regular": [1800, 3000], "good": [3200, 4800], "very_good": [5000, 7000], "liquidity": "baja"},
    "Fiat 128 estándar": {"years": [1971, 1990], "regular": [2000, 3500], "good": [3800, 5500], "very_good": [6000, 8500], "liquidity": "baja"},
    "Fiat 125": {"years": [1972, 1982], "regular": [2200, 4000], "good": [4200, 6500], "very_good": [7000, 10000], "liquidity": "baja"},
    "Fiat Duna": {"years": [1987, 2001], "regular": [2800, 4500], "good": [4800, 7000], "very_good": [7500, 11000], "liquidity": "baja"},
    "Fiat Regatta": {"years": [1985, 1995], "regular": [2500, 4200], "good": [4500, 6800], "very_good": [7000, 10000], "liquidity": "baja"},
    "Fiat Punto": {"years": [1999, 2018], "regular": [4500, 8000], "good": [8500, 14000], "very_good": [15000, 22000], "liquidity": "media"},
    "Fiat Uno Fire 3 puertas": {"years": [2004, 2018], "regular": [5500, 8500], "good": [9000, 13000], "very_good": [14000, 18000], "liquidity": "alta"},
    "Volkswagen Gol Power 3 puertas": {"years": [2008, 2022], "regular": [6500, 10000], "good": [11000, 16000], "very_good": [17000, 22000], "liquidity": "alta"},
}
# Models taken from the document's list of common models. The list describes 5-10
# year old units in good condition, so the reference year is 2019. The years of the
# newer models (marked "default") are NOT known from the sources: they use the list's
# own 5-10 year window and are provisional.
const DEFAULT_YEARS := [2016, 2021]
const LISTED := {
    "Fiat Cronos": {"range": [14000, 24000], "ref_year": 2019, "years": [2018, 2022], "liquidity": "media"},
    "Fiat Siena": {"range": [7000, 14000], "ref_year": 2019, "years": [2004, 2010], "liquidity": "media"},
    "Chevrolet Corsa 5 puertas": {"range": [6000, 12000], "ref_year": 2019, "liquidity": "alta"},
    "Volkswagen Amarok": {"range": [18000, 40000], "ref_year": 2019, "liquidity": "media"},
    "Ford Ranger cabina simple": {"range": [18000, 42000], "ref_year": 2019, "liquidity": "media"},
    "Ford EcoSport": {"range": [12000, 22000], "ref_year": 2019, "liquidity": "media"},
    "Toyota Corolla": {"range": [15000, 28000], "ref_year": 2019, "liquidity": "media"},
    "Fiat Palio 5 puertas": {"range": [7000, 14000], "ref_year": 2019, "liquidity": "alta"},
    "Toyota Yaris Sedán": {"range": [13000, 22000], "ref_year": 2019, "liquidity": "media"},
    "Ford Ka 3 puertas": {"range": [9000, 16000], "ref_year": 2019, "liquidity": "media"},
    "Peugeot 208": {"range": [12000, 22000], "ref_year": 2019, "liquidity": "media"},
    "Volkswagen Polo Classic": {"range": [14000, 25000], "ref_year": 2019, "liquidity": "media"},
    "Volkswagen Virtus": {"range": [14000, 25000], "ref_year": 2019, "liquidity": "media"},
    "Chevrolet Onix": {"range": [12000, 22000], "ref_year": 2019, "liquidity": "alta"},
    "Toyota Corolla Cross": {"range": [22000, 35000], "ref_year": 2019, "liquidity": "media"},
}
const IMPORTS := {
    "Mazda MX-5 NA": {"units": 5700, "year": 1992},
    "Honda Civic EK": {"units": 7000, "year": 1998},
    "Toyota Corolla Levin AE86": {"units": 8300, "year": 1985},
    "Nissan Silvia S13": {"units": 9600, "year": 1992},
    "Toyota MR2 SW20": {"units": 10900, "year": 1994},
    "Honda Prelude": {"units": 12200, "year": 1996},
    "Mitsubishi FTO": {"units": 13500, "year": 1995},
    "Mazda RX-7 FC": {"units": 14800, "year": 1988},
    "Subaru Impreza GC8": {"units": 16100, "year": 1997},
    "Nissan Skyline R32": {"units": 17400, "year": 1991},
}
const CATALOG_YEARS := {"Fiat 147 Vivace": 1997, "Fiat 128 Súper Europa 1.5": 1990, "Fiat 500 Sport": 2021}

static func models() -> Array:
    var names: Array = IMPORTS.keys()
    names.append_array(CATALOG_YEARS.keys())
    names.append_array(PRIORITY.keys())
    names.append_array(LISTED.keys())
    return names

static func _mid(range_pair: Array) -> float:
    return (float(range_pair[0]) + float(range_pair[1])) / 2.0

# Entry understood by market_pricing.gd / market_listings.gd; empty for unknown cars.
static func entry_for(model: String) -> Dictionary:
    var units := 0.0
    var ref_year := 0
    var year_min := 0
    var year_max := 0
    var liquidity := "baja"
    var tiers := {}
    if PRIORITY.has(model):
        var data: Dictionary = PRIORITY[model]
        var years: Array = data["years"]
        units = _mid(data["good"])
        year_min = int(years[0])
        year_max = mini(int(years[1]), CURRENT_YEAR)
        ref_year = floori(float(year_min + year_max) / 2.0)
        liquidity = str(data["liquidity"])
        tiers = {"regular": data["regular"], "good": data["good"], "very_good": data["very_good"]}
    elif LISTED.has(model):
        var listed: Dictionary = LISTED[model]
        var span: Array = listed["range"]
        units = sqrt(float(span[0]) * float(span[1]))
        ref_year = int(listed["ref_year"])
        var years: Array = listed.get("years", DEFAULT_YEARS)
        year_min = int(years[0])
        year_max = mini(int(years[1]), CURRENT_YEAR)
        liquidity = str(listed["liquidity"])
    elif IMPORTS.has(model):
        units = float(IMPORTS[model]["units"])
        ref_year = int(IMPORTS[model]["year"])
        year_min = ref_year - 3
        year_max = mini(ref_year + 3, CURRENT_YEAR)
    elif CATALOG_YEARS.has(model) and Catalog.has_definition(model):
        units = float(Catalog.definition(model).get("price", 0))
        ref_year = int(CATALOG_YEARS[model])
        var spread := 3 if ref_year < 2000 else 2
        year_min = ref_year - spread
        year_max = mini(ref_year + spread, CURRENT_YEAR)
    if units <= 0.0 or ref_year <= 0:
        return {}
    return {
        "id": model.to_lower().replace(" ", "-"), "name": model, "kind": "", "era": "classic" if ref_year < 2000 else "modern",
        "ref_ars": units * 1000.0, "ref_year": ref_year, "year_min": year_min, "year_max": year_max,
        "price_min": int(units * 700.0), "price_max": int(units * 1400.0),
        "liquidity": liquidity, "tiers": tiers,
    }
