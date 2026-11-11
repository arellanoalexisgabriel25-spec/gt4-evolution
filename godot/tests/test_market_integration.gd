extends SceneTree

const Economy = preload("res://scripts/economy.gd")
const Profiles = preload("res://scripts/market_profiles.gd")
const Pricing = preload("res://scripts/market_pricing.gd")
const MarketState = preload("res://scripts/market_state.gd")
const Deal = preload("res://scripts/market_deal.gd")
const Catalog = preload("res://scripts/car_catalog.gd")
const Upkeep = preload("res://scripts/market_upkeep.gd")
const Negotiation = preload("res://scripts/market_negotiation.gd")
const Listings = preload("res://scripts/market_listings.gd")
const Store = preload("res://scripts/save_store.gd")
const Career = preload("res://scripts/career.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func listings(game) -> Array:
    var found: Array = []
    for car in game.cars:
        if car["owner"] == "seller":
            found.append(car)
    return found

func _initialize() -> void:
    # Profiles cover every drivable car and follow the game's own prices.
    var models: Array = Profiles.models()
    var complete := models.size() == 36
    for model in models:
        var entry: Dictionary = Profiles.entry_for(model)
        complete = complete and not entry.is_empty() and float(entry["ref_ars"]) > 0.0 and int(entry["ref_year"]) >= 1970 and int(entry["year_min"]) <= int(entry["ref_year"]) and int(entry["year_max"]) <= 2026
    check(complete, "Every drivable car has a market profile")
    check(Profiles.entry_for("Fiat 133")["ref_ars"] == 4000000.0 and Profiles.entry_for("Fiat Punto")["ref_ars"] == 11250000.0 and Profiles.entry_for("Fiat Uno Fire 3 puertas")["liquidity"] == "alta" and Profiles.entry_for("Fiat 125")["liquidity"] == "baja", "Priority models take their reference and liquidity from the price document")
    check(absf(Profiles.entry_for("Fiat Cronos")["ref_ars"] - sqrt(14000.0 * 24000.0) * 1000.0) < 1.0 and Profiles.entry_for("Fiat 147 Vivace")["ref_ars"] == float(Catalog.definition("Fiat 147 Vivace")["price"]) * 1000.0 and Profiles.entry_for("Nissan Skyline R32")["ref_ars"] == 17400000.0 and Profiles.entry_for("nope").is_empty(), "Other models use the document's list or the game's own prices")
    var uno: Dictionary = Profiles.entry_for("Fiat 133")
    var uno_year := int(uno["ref_year"])
    check(absf(Pricing.fair_value_ars(uno, uno_year, 150000.0, 75.0) / float(uno["ref_ars"]) - 1.0) < 0.01 and Pricing.fair_value_ars(uno, uno_year, 150000.0, 95.0) > float(uno["ref_ars"]), "A typical unit is worth its reference value and restoring raises it")
    # The three condition tiers of the document are reproduced for every priority model.
    var tiers_ok := true
    for model in Profiles.PRIORITY:
        var entry: Dictionary = Profiles.entry_for(model)
        var year := floori(float(int(entry["year_min"]) + int(entry["year_max"])) / 2.0)
        var typical := Pricing.typical_km(entry, float(2026 - year))
        var low_km := typical * 0.55 if entry["era"] == "modern" else 100000.0
        var regular := Pricing.fair_value_ars(entry, year, typical, 50.0) / 1000.0
        var good := Pricing.fair_value_ars(entry, year, typical, 75.0) / 1000.0
        var very_good := Pricing.fair_value_ars(entry, year, low_km, 92.0) / 1000.0
        var data: Dictionary = Profiles.PRIORITY[model]
        tiers_ok = tiers_ok and regular >= float(data["regular"][0]) * 0.95 and regular <= float(data["regular"][1]) * 1.05 and good >= float(data["good"][0]) and good <= float(data["good"][1]) and very_good >= float(data["very_good"][0]) * 0.95 and very_good <= float(data["very_good"][1]) * 1.05
    check(tiers_ok, "Regular, good and very good condition reproduce the document's price tiers")
    var classic_entry: Dictionary = Profiles.entry_for("Fiat 125")
    var modern_entry: Dictionary = Profiles.entry_for("Fiat Punto")
    check(Pricing.gnc_factor(classic_entry, true) == 0.95 and Pricing.gnc_factor(modern_entry, true) == 1.03 and Pricing.gnc_factor(modern_entry, false) == 1.0, "GNC lowers classics and raises daily drivers")
    check(is_equal_approx(Pricing.history_factor([{"event": "reparacion:motor"}, {"event": "reparacion:frenos"}]), 1.02) and is_equal_approx(Pricing.history_factor([{"event": "danos", "points": 100.0}]), 0.88) and Pricing.history_factor([]) == 1.0 and Pricing.history_factor([{"event": "danos", "points": 10000.0}]) >= 0.85, "Service history helps and crash damage hurts the resale value")
    check(Pricing.liquidity_of(modern_entry)["interest"] == 1.0 and Pricing.liquidity_of({"liquidity": "alta"})["interest"] > 1.0 and Pricing.liquidity_of(classic_entry)["interest"] < 1.0 and Deal.daily_interest(1000, 1000, 1.3) > Deal.daily_interest(1000, 1000, 0.6), "Liquid cars attract more buyers than classics")

    # The market fills up without touching existing offers.
    var game = Economy.new()
    game.seed_demo()
    var original_ids: Array = []
    for car in game.cars:
        original_ids.append(car["id"])
    var snapshot := {}
    for car in game.cars:
        snapshot[car["id"]] = {"km": car["km"], "health": car["health"].duplicate(true), "faults": car["faults"].duplicate(true)}
    var added: int = game.ensure_market_listings()
    var upgraded := true
    for car in game.cars:
        if snapshot.has(car["id"]):
            upgraded = upgraded and car.has("catalog_id") and car.has("year") and int(car["price"]) >= 100 and car["km"] == snapshot[car["id"]]["km"] and car["health"] == snapshot[car["id"]]["health"] and car["faults"] == snapshot[car["id"]]["faults"]
    check(upgraded, "Original offers become market listings keeping their mileage, condition and faults")
    check(added == MarketState.TARGET_OFFERS - 36 and listings(game).size() == MarketState.TARGET_OFFERS and game.ensure_market_listings() == 0, "The market grows to its target once")
    var ids_kept := true
    for car in game.cars:
        if original_ids.has(car["id"]):
            ids_kept = ids_kept and car["owner"] == "seller"
    check(ids_kept and game.cars.size() == MarketState.TARGET_OFFERS, "Original offers keep their IDs")
    var restored = Economy.new()
    check(restored.from_dict(game.to_dict()) and restored.market == game.market and restored.cars.size() == MarketState.TARGET_OFFERS, "Listings and the market clock survive the save schema")
    var decoded: Dictionary = Store.decode(Store.encode(game, Career.new()))
    check(decoded.error.is_empty(), "Listings survive a JSON save")
    var legacy: Dictionary = game.to_dict()
    legacy.erase("market")
    var old_game = Economy.new()
    check(old_game.from_dict(legacy) and old_game.market == MarketState.default_state(), "Saves without a market clock load with the default clock")
    var broken: Dictionary = game.to_dict()
    broken["market"] = {"day": 3, "index": 5.0, "seed": 1}
    check(not Economy.new().from_dict(broken) and not MarketState.valid_state(null) and not MarketState.valid_state({"day": -1, "index": 1.0, "seed": 1}), "Invalid clocks are rejected")

    # Existing buy / inspect / sell entry points now run through the market.
    game.balance = 50000
    var target: Dictionary = game.find_car(1)
    var price := int(target["price"])
    var before: int = game.balance
    var inspect_cost: int = Deal.inspection_price(game, 1)
    check(game.inspect(1).begins_with("Inspección completada") and game.balance == before - inspect_cost and inspect_cost != 200, "Inspection is priced by the car")
    var message: String = game.buy(1)
    check(message.begins_with("Compraste") and target["owner"] == "player" and game.balance < before - inspect_cost - price, "Buying charges fees on top of the price")
    check(game.buy(1).begins_with("La oferta ya no") and game.sell(2).begins_with("Solo podés"), "Buying twice or selling someone else's car is refused")
    var dealer: int = game.resale_quote(1)
    var fair: int = Deal.fair_credits(game, 1)
    check(dealer > 0 and dealer < fair and dealer > int(float(fair) * 0.65), "Dealers pay well under the true value")
    var balance_before: int = game.balance
    check(game.sell(1).begins_with("La agencia compró") and game.balance == balance_before + dealer and game.find_car(1)["owner"] == "sold", "Selling to a dealer pays the quote once")

    # Repairs scale with the car.
    var cheap := Economy.new()
    cheap.seed_demo()
    var cheap_id := 0
    var rich_id := 0
    for car in cheap.cars:
        if car["model"] == "Fiat 133":
            cheap_id = car["id"]
        if car["model"] == "Nissan Skyline R32":
            rich_id = car["id"]
    cheap.find_car(cheap_id)["health"]["motor"] = 50.0
    cheap.find_car(rich_id)["health"]["motor"] = 50.0
    cheap.find_car(cheap_id)["faults"] = {}
    cheap.find_car(rich_id)["faults"] = {}
    check(cheap.repair_quote(cheap_id, "motor") * 3 < cheap.repair_quote(rich_id, "motor") and cheap.repair_quote(cheap_id, "nitro") == -1, "Repair cost follows the value of the car")
    cheap.find_car(cheap_id)["health"]["frenos"] = 100.0
    check(cheap.repair_quote(cheap_id, "frenos") == 0, "A healthy component needs no repair")

    # The market clock.
    var clock = Economy.new()
    clock.seed_demo()
    clock.ensure_market_listings()
    var twin = Economy.new()
    twin.from_dict(clock.to_dict())
    var sold_total := 0
    var new_total := 0
    var cuts_total := 0
    var index_ok := true
    for day in range(10):
        var report: Dictionary = MarketState.advance_day(clock)
        MarketState.advance_day(twin)
        sold_total += report["sold"].size()
        new_total += int(report["new"])
        cuts_total += int(report["cuts"])
        index_ok = index_ok and float(clock.market["index"]) >= MarketState.INDEX_MIN and float(clock.market["index"]) <= MarketState.INDEX_MAX
    check(int(clock.market["day"]) == 10 and index_ok and clock.to_dict() == twin.to_dict(), "Days advance deterministically and the price index stays bounded")
    check(sold_total > 0 and new_total > 0 and cuts_total > 0 and listings(clock).size() >= 20, "Listings sell, appear and get cheaper over time")
    check(MarketState.describe({"day": 4, "sold": ["Fiat Uno Fire 3 puertas"], "new": 2, "cuts": 1, "offers": 0}).begins_with("Día 4"), "Daily reports are readable")

    # Private sales answer to the asking price over the days.
    var seller = Economy.new()
    seller.seed_demo()
    seller.ensure_market_listings()
    var mine := 0
    for car in seller.cars:
        if car["owner"] == "seller" and car["model"] == "Fiat Uno Fire 3 puertas":
            mine = car["id"]
            break
    seller.balance = 100000
    seller.buy(mine)
    var worth: int = Deal.fair_credits(seller, mine)
    check(Deal.publish(seller, mine, worth).ok and int(seller.find_car(mine)["sale_ask"]) == worth and not Deal.publish(seller, 9999, worth).ok and not Deal.publish(seller, mine, 0).ok, "An owned car can be published")
    var accepted := false
    for day in range(25):
        MarketState.advance_day(seller)
        var car: Dictionary = seller.find_car(mine)
        var offers: Array = car.get("offers", [])
        var value_now: int = Deal.fair_credits(seller, mine)
        for amount in offers:
            check(amount <= int(float(worth) * 0.97) + 1 and amount <= int(float(value_now) * 1.08) + 1 and amount >= int(minf(float(worth) * 0.97, float(value_now) * 0.92)) - 1, "Offers stay below the ask and near the car's value")
        if not offers.is_empty() and not accepted:
            var before_sale: int = seller.balance
            var result: Dictionary = Deal.accept_offer(seller, mine, int(offers[0]))
            accepted = bool(result.get("ok", false)) and seller.balance == before_sale + int(result["net"]) and seller.find_car(mine)["owner"] == "sold" and not seller.find_car(mine).has("offers")
            check(not Deal.accept_offer(seller, mine, int(offers[0])).get("ok", false), "A sold car cannot be sold again")
    check(accepted, "A published car receives offers and can be sold to a private buyer")
    # Monthly costs of owning a car.
    check(Upkeep.monthly_patente(10000, 10) == 21 and Upkeep.monthly_patente(10000, 25) == 0 and Upkeep.monthly_seguro(100) == 40 and Upkeep.monthly_seguro(10000) == 60 and Upkeep.monthly_seguro(50000) == 120, "Plate tax and insurance follow the document's ranges")
    check(not Upkeep.vtv_due({"vtv_day": 0}, 2, 400) and Upkeep.vtv_due({"vtv_day": 0}, 5, 365) and not Upkeep.vtv_due({"vtv_day": 0}, 5, 364), "The VTV is yearly and only for cars over three years")
    var owner = Economy.new()
    owner.seed_demo()
    owner.ensure_market_listings()
    owner.balance = 100000
    var owned_id := 0
    for car in owner.cars:
        if car["owner"] == "seller" and car["model"] == "Fiat Uno Fire 3 puertas":
            owned_id = car["id"]
            break
    owner.buy(owned_id)
    var kept: Dictionary = owner.find_car(owned_id)
    var estimate: Dictionary = Upkeep.estimate(owner, kept)
    check(kept["owner"] == "player" and estimate["patente"] > 0 and estimate["seguro"] >= 40 and Upkeep.describe(owner, kept).begins_with("GASTO MENSUAL"), "Owned cars have a monthly cost estimate")
    owner.market["day"] = 29
    var money_before: int = owner.balance
    var month: Dictionary = MarketState.advance_day(owner)["upkeep"]
    check(int(month["cars"]) == 1 and int(month["paid"]) > 0 and owner.balance == money_before - int(month["paid"]) and int(month["unpaid"]) == 0 and int(kept["documents"]["deuda"]) == 0, "A month of costs is charged from the balance")
    owner.balance = 0
    owner.market["day"] = 59
    var broke: Dictionary = MarketState.advance_day(owner)["upkeep"]
    check(int(broke["unpaid"]) > 0 and owner.balance == 0 and int(kept["documents"]["deuda"]) > 0 and kept["uninsured_months"] == 1, "Unpaid costs become a debt and never push the balance below zero")
    var debt := int(kept["documents"]["deuda"])
    var quote_net: int = Deal.dealer_quote(owner, owned_id)
    check(quote_net == Deal.dealer_gross(owner, owned_id) - debt, "The dealer settles the car's debt out of the payment")
    var cash: int = owner.balance
    var sale: Dictionary = Deal.sell_dealer(owner, owned_id)
    check(sale.ok and owner.balance == cash + quote_net and int(sale.net) == quote_net, "Selling pays the net of debts")
    var vtv_game = Economy.new()
    vtv_game.seed_demo()
    vtv_game.ensure_market_listings()
    vtv_game.balance = 100000
    var old_id := 0
    for car in vtv_game.cars:
        if car["owner"] == "seller" and car["model"] == "Fiat Duna":
            old_id = car["id"]
            break
    vtv_game.buy(old_id)
    var duna: Dictionary = vtv_game.find_car(old_id)
    duna["vtv_day"] = 0
    vtv_game.market["day"] = 389
    var charged: int = vtv_game.balance
    MarketState.advance_day(vtv_game)
    var vtv_paid := false
    for entry in vtv_game.ledger:
        if entry["car_id"] == old_id and entry["event"] == "vtv":
            vtv_paid = true
    check(vtv_paid and duna["documents"]["vtv"] and duna["vtv_day"] == 390 and vtv_game.balance < charged, "The VTV is renewed when due")
    check_refinements()
    if failed:
        quit(1)
    else:
        print("PASS: %d market integration assertions" % checks)
        quit(0)

func clean_listing(game, price: int, extra: Dictionary = {}) -> int:
    var id: int = Deal.next_id(game)
    var listing := {
        "id": id, "model": "Fiat Uno Fire 3 puertas", "km": 80000, "health": {"motor": 70.0, "transmision": 70.0, "suspension": 70.0, "frenos": 70.0, "neumaticos": 70.0, "chasis": 70.0, "electrico": 70.0}, "faults": {},
        "owner": "seller", "listed": true, "inspected": false, "price": price, "upgrades": [], "history": [],
        "catalog_id": "fiat-uno-fire-3-puertas", "year": 2012, "seller": "particular",
        "documents": {"deuda": 0, "prenda": false, "sin_titularidad": false, "vtv": true},
        "flex": 0.10, "listed_day": 0, "doc_checked": false, "locked_until_day": 0, "service_km": 75000, "warranty_days": 0}
    for key in extra:
        listing[key] = extra[key]
    Deal.add_listing(game, listing)
    return id

func check_refinements() -> void:
    # Offers are anchored to the car's value, not to the ad.
    var anchor = Economy.new()
    anchor.seed_demo()
    var anchor_id := clean_listing(anchor, 9000)
    anchor.balance = 100000
    anchor.buy(anchor_id)
    var anchor_fair: int = Deal.fair_credits(anchor, anchor_id)
    var ask := int(float(anchor_fair) * 1.5)
    var above_value := false
    var any_offer := false
    for day in range(400):
        for amount in Deal.private_offers(anchor, anchor_id, ask, day):
            any_offer = true
            above_value = above_value or amount > int(float(anchor_fair) * 1.08) + 1
    check(any_offer and not above_value, "Overpriced ads draw few offers and none above the car's value")
    # Counters give away the reserve slowly and decrease round by round.
    var talk = Negotiation.new(10000, 9000)
    var first: Dictionary = talk.offer(8000)
    var second: Dictionary = talk.offer(8100)
    var third: Dictionary = talk.offer(8200)
    check(first.price >= 9560 and first.price <= 9840 and second.price >= 9360 and second.price <= 9540 and third.price >= 9200 and third.price <= 9300, "Counters concede less every round")
    check(first.price > second.price and second.price > third.price and first.price > int(9000.0 * 1.05), "Counters do not point straight at the reserve")
    check(Negotiation.reserve_for(10000, 0.10, 0, 0, 0.02) == 8800 and Negotiation.reserve_for(10000, 0.10, 0, 0, 0.5) == 8500, "Experience lowers the seller's reserve, with a cap")
    var veteran = Economy.new()
    veteran.seed_demo()
    check(Deal.skill(veteran) == 0.0, "A new trader has no experience")
    veteran.market["deals"] = 5
    check(is_equal_approx(Deal.skill(veteran), 0.02), "Experience grows with completed deals")
    veteran.market["deals"] = 100
    check(is_equal_approx(Deal.skill(veteran), 0.04), "Experience is capped at four points")
    var green = Economy.new()
    green.seed_demo()
    var green_id := clean_listing(green, 9000)
    var veteran_id := clean_listing(veteran, 9000)
    check(Deal.start_negotiation(veteran, veteran_id, 0).reserve < Deal.start_negotiation(green, green_id, 0).reserve, "Sellers give experienced buyers a better price")

    # Rolled-back odometers.
    var cheat = Economy.new()
    cheat.seed_demo()
    cheat.balance = 100000
    var honest_id := clean_listing(cheat, 9000)
    var rigged_id := clean_listing(cheat, 9000, {"km_real": 140000})
    check(Deal.fair_credits(cheat, rigged_id) < Deal.fair_credits(cheat, honest_id), "The true mileage lowers the value")
    var rigged_reserve = Deal.start_negotiation(cheat, rigged_id, 0).reserve
    var message: String = Deal.inspect(cheat, rigged_id)
    var rigged: Dictionary = cheat.find_car(rigged_id)
    check(message.contains("Odómetro adulterado") and rigged["km"] == 140000 and not rigged.has("km_real") and rigged["odometer_fraud"] and rigged["km_claimed"] == 80000, "Inspection reveals a rolled-back odometer")
    Deal.inspect(cheat, honest_id)
    check(Deal.start_negotiation(cheat, rigged_id, 0).reserve < Deal.start_negotiation(cheat, honest_id, 0).reserve and Deal.start_negotiation(cheat, rigged_id, 0).reserve < rigged_reserve, "A proven odometer fraud justifies a big concession")
    var blind_id := clean_listing(cheat, 9000, {"km_real": 150000})
    var blind: Dictionary = Deal.purchase(cheat, blind_id)
    var blind_car: Dictionary = cheat.find_car(blind_id)
    var logged := false
    for entry in cheat.ledger:
        if entry["car_id"] == blind_id and entry["event"] == "odometro_adulterado":
            logged = true
    check(blind.ok and blind.message.contains("odómetro estaba adulterado") and blind_car["km"] == 150000 and logged, "Buying without inspecting reveals the fraud after paying")
    var rng := RandomNumberGenerator.new()
    rng.seed = 777
    var frauds := 0
    var dealer_frauds := 0
    var inconsistent := 0
    var next_listing_id := 1000
    for model in Profiles.models():
        for i in range(10):
            var listing: Dictionary = Listings.generate(Profiles.entry_for(model), next_listing_id, rng)
            next_listing_id += 1
            if listing.has("km_real"):
                frauds += 1
                dealer_frauds += 1 if listing["seller"] == "agencia" else 0
                inconsistent += 1 if int(listing["km_real"]) <= int(listing["km"]) else 0
    check(frauds > 0 and dealer_frauds == 0 and inconsistent == 0, "Private and urgent sellers roll back odometers, dealerships never do")

    # Basic service every 10,000 km.
    var shop = Economy.new()
    shop.seed_demo()
    shop.balance = 100000
    var due_id := clean_listing(shop, 9000, {"service_km": 60000})
    var fresh_id := clean_listing(shop, 9000, {"service_km": 79000})
    var due_value: int = Deal.fair_credits(shop, due_id)
    var fresh_value: int = Deal.fair_credits(shop, fresh_id)
    check(Deal.service_overdue(shop.find_car(due_id)) and not Deal.service_overdue(shop.find_car(fresh_id)) and float(due_value) / float(fresh_value) > 0.96 and float(due_value) / float(fresh_value) < 0.98, "An overdue service lowers the value by about three percent")
    Deal.purchase(shop, due_id)
    var cost: int = Deal.service_cost(shop, due_id)
    var cash: int = shop.balance
    var done: String = Deal.do_service(shop, due_id)
    var serviced: Dictionary = shop.find_car(due_id)
    check(cost >= 80 and cost <= 200 and done.begins_with("Service realizado") and shop.balance == cash - cost and serviced["service_km"] == 80000 and not Deal.service_overdue(serviced), "A service costs credits and resets the counter")
    check(Deal.do_service(shop, due_id).begins_with("El service está al día") and shop.balance == cash - cost, "A second service right away is not charged")
    check(Deal.fair_credits(shop, due_id) > due_value, "A documented service raises the resale value")
    check(Deal.do_service(shop, 1).begins_with("Solo podés"), "Only owned cars can be serviced")

    # Dealership warranty.
    var warranty = Economy.new()
    warranty.seed_demo()
    warranty.balance = 100000
    var covered_id := clean_listing(warranty, 9000, {"seller": "agencia", "warranty_days": 30, "faults": {"motor": true}})
    var private_id := clean_listing(warranty, 9000, {"faults": {"motor": true}})
    Deal.purchase(warranty, covered_id)
    Deal.purchase(warranty, private_id)
    var covered: Dictionary = warranty.find_car(covered_id)
    check(covered["warranty_until"] == 30 and Deal.warranty_days_left(warranty, covered) == 30 and not warranty.find_car(private_id).has("warranty_until"), "Only dealership cars come with a 30 day warranty")
    check(Deal.claim_warranty(warranty, private_id).begins_with("La garantía no está vigente"), "Private sales have no warranty")
    check(Deal.claim_warranty(warranty, covered_id).begins_with("La agencia reparó sin cargo") and covered["faults"].is_empty() and not covered.has("warranty_until"), "The dealership repairs hidden faults for free")
    check(Deal.claim_warranty(warranty, covered_id).begins_with("La garantía no está vigente"), "The warranty is used once")
    var late_id := clean_listing(warranty, 9000, {"seller": "agencia", "warranty_days": 30, "faults": {"frenos": true}})
    Deal.purchase(warranty, late_id)
    warranty.market["day"] = 31
    check(Deal.claim_warranty(warranty, late_id).begins_with("La garantía no está vigente") and not warranty.find_car(late_id)["faults"].is_empty(), "An expired warranty covers nothing")
    var clean_id := clean_listing(warranty, 9000, {"seller": "agencia", "warranty_days": 30})
    warranty.market["day"] = 0
    Deal.purchase(warranty, clean_id)
    check(Deal.claim_warranty(warranty, clean_id).begins_with("No hay averías"), "A car without faults has nothing to claim")

    # Demand drifts per model and makes the news.
    var trend_game = Economy.new()
    trend_game.seed_demo()
    trend_game.ensure_market_listings()
    var trend_id := 0
    for car in trend_game.cars:
        if car["owner"] == "seller" and car["model"] == "Fiat 133":
            trend_id = car["id"]
            break
    var flat: int = Deal.fair_credits(trend_game, trend_id)
    trend_game.market["trends"] = {"Fiat 133": 1.10}
    var hot: int = Deal.fair_credits(trend_game, trend_id)
    check(absf(float(hot) / float(flat) - 1.10) < 0.003 and Deal.trend(trend_game, "Fiat 133") == 1.10 and Deal.trend(trend_game, "Fiat 125") == 1.0, "A model's demand trend scales its value")
    trend_game.market["trends"] = {}
    var headlines := 0
    for day in range(20):
        if str(MarketState.advance_day(trend_game)["news"]) != "":
            headlines += 1
    var trends: Dictionary = trend_game.market["trends"]
    var trends_ok := trends.size() == 36
    var moved := false
    for model in trends:
        trends_ok = trends_ok and float(trends[model]) >= MarketState.TREND_MIN and float(trends[model]) <= MarketState.TREND_MAX
        moved = moved or float(trends[model]) != 1.0
    check(trends_ok and moved and headlines > 0, "Every model's demand drifts within bounds and the biggest mover makes the news")
    check(MarketState.describe({"day": 2, "sold": [], "new": 0, "cuts": 0, "offers": 0, "upkeep": {}, "news": "Sube la demanda de Fiat 133 (+1.1 %)"}).contains("Sube la demanda"), "The daily report includes the news")
    check(not MarketState.valid_state({"day": 1, "index": 1.0, "seed": 1, "trends": {"Fiat 133": 5.0}}) and not MarketState.valid_state({"day": 1, "index": 1.0, "seed": 1, "trends": 3}) and MarketState.valid_state({"day": 1, "index": 1.0, "seed": 1, "trends": {"Fiat 133": 1.05}}) and MarketState.default_state()["trends"] == {}, "Trends are validated")

    # Price guide.
    var guide_text := Deal.guide_text("Fiat 133")
    var other: Dictionary = Profiles.entry_for("Nissan Skyline R32")
    var guide: Dictionary = Pricing.tier_guide(other)
    var regular_mid := float(guide["regular"][0] + guide["regular"][1]) / 2.0
    var good_mid := float(guide["good"][0] + guide["good"][1]) / 2.0
    var best_mid := float(guide["very_good"][0] + guide["very_good"][1]) / 2.0
    check(guide_text.begins_with("GUÍA DE PRECIOS") and guide_text.contains("REGULAR") and Deal.guide_text("nope") == "" and Pricing.tier_guide(Profiles.entry_for("Fiat 133"))["regular"] == [1800, 3000], "The price guide uses the document's tiers when available")
    check(regular_mid < good_mid and good_mid < best_mid and absf(good_mid - 17400.0) < 1.0 and Pricing.tier_guide(other, 1.1)["good"][0] > guide["good"][0], "Other models get derived tiers that follow the market index")
    check(MarketState.valid_state({"day": 1, "index": 1.0, "seed": 1, "deals": 3}) and not MarketState.valid_state({"day": 1, "index": 1.0, "seed": 1, "deals": -1}) and MarketState.default_state()["deals"] == 0, "The market clock validates the deal counter")
