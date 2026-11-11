extends SceneTree

const Economy = preload("res://scripts/economy.gd")
const Catalog = preload("res://scripts/market_catalog.gd")
const Pricing = preload("res://scripts/market_pricing.gd")
const Fees = preload("res://scripts/market_fees.gd")
const Listings = preload("res://scripts/market_listings.gd")
const Negotiation = preload("res://scripts/market_negotiation.gd")
const Deal = preload("res://scripts/market_deal.gd")
const Store = preload("res://scripts/save_store.gd")
const Career = preload("res://scripts/career.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func health_of(value: float) -> Dictionary:
    var health := {}
    for component in Pricing.WEIGHTS:
        health[component] = value
    return health

func gol_listing(id: int, price: int = 12000) -> Dictionary:
    return {
        "id": id, "model": "Volkswagen Gol / Gol Trend", "km": 100000, "health": health_of(70.0), "faults": {},
        "owner": "seller", "listed": true, "inspected": false, "price": price, "upgrades": [], "history": [],
        "catalog_id": "volkswagen-gol-gol-trend", "year": 2018, "seller": "particular",
        "documents": {"deuda": 500, "prenda": true, "sin_titularidad": false, "vtv": true},
        "flex": 0.10, "listed_day": 0, "doc_checked": false, "locked_until_day": 0}

func _initialize() -> void:
    # Catalog.
    var seen := {}
    var unique := true
    var priced := true
    for entry in Catalog.all():
        unique = unique and not seen.has(entry["id"])
        seen[entry["id"]] = true
        priced = priced and int(entry["price_min"]) > 0 and int(entry["price_max"]) >= int(entry["price_min"]) and int(entry["year_min"]) <= int(entry["year_max"]) and ["", "manual", "automatic", "mixto"].has(entry["transmission"])
    check(Catalog.all().size() == 120 and unique and priced, "Catalog has 120 unique, well-formed entries")
    var gol: Dictionary = Catalog.find("volkswagen-gol-gol-trend")
    check(not gol.is_empty() and int(gol["price_min"]) == 8500000 and int(gol["price_max"]) == 18000000 and Catalog.find_by_name("Toyota Hilux")["id"] == "toyota-hilux", "Entries keep the prices of the source list")
    check(Catalog.find("nope").is_empty() and Catalog.find_by_name("nope").is_empty(), "Unknown models are not found")
    var palio: Dictionary = Catalog.find("fiat-palio-weekend-adventure-1-6-2018")
    check(palio["power_hp"] == 115 and is_equal_approx(float(palio["torque_nm"]), 158.9) and palio["transmission"] == "manual" and palio["year_min"] == 2018, "Fiat report specs are kept")
    check(Catalog.find("fiat-argo-2020")["transmission"] == "mixto" and Catalog.find("fiat-128")["drive"] == "FWD" and Catalog.find("fiat-133")["drive"] == "", "Unknown or mixed specs are not invented")

    # Pricing.
    check(Pricing.to_credits(12369317.0) == 12369 and is_equal_approx(Pricing.to_ars(12.0), 12000.0) and Pricing.to_credits(-5.0) == 0, "ARS and credits convert at 1,000 ARS per credit")
    check(is_equal_approx(Pricing.condition_from_health(health_of(70.0)), 70.0) and Pricing.condition_from_health({}) == 0.0, "Condition is the weighted average of component health")
    var reference := Catalog.reference_ars(gol)
    var typical := Pricing.fair_value_ars(gol, 2019, 84000.0, 75.0)
    check(absf(typical / reference - 1.0) < 0.06, "A typical unit is worth about the reference price")
    check(Pricing.fair_value_ars(gol, 2016, 150000.0, 60.0) > float(gol["price_min"]) * 0.9 and Pricing.fair_value_ars(gol, 2016, 150000.0, 60.0) < reference, "A tired old unit sits at the low end of the range")
    check(Pricing.fair_value_ars(gol, 2024, 20000.0, 92.0) > float(gol["price_max"]) * 0.95, "A nearly new unit is worth about the top of the range")
    check(Pricing.fair_value_ars(gol, 2015, 100000.0, 75.0) < Pricing.fair_value_ars(gol, 2020, 100000.0, 75.0), "Older cars are worth less")
    check(Pricing.fair_value_ars(gol, 2019, 200000.0, 75.0) < Pricing.fair_value_ars(gol, 2019, 50000.0, 75.0), "Higher mileage lowers the value")
    check(Pricing.fair_value_ars(gol, 2019, 84000.0, 40.0) < typical and Pricing.fair_value_ars(gol, 2019, 84000.0, 95.0) > typical, "Condition moves the value both ways")
    check(is_equal_approx(Pricing.condition_factor(75.0), 1.0) and Pricing.condition_factor(100.0) > 1.2 and Pricing.condition_factor(40.0) < 0.75, "Condition factor spans roughly 0.7 to 1.23")
    check(Pricing.fair_value_ars(gol, 2019, 84000.0, 75.0, {"motor": true}) < typical * 0.86 and Pricing.fault_loss({"motor": true, "chasis": true, "transmision": true, "suspension": true, "frenos": true, "neumaticos": true, "electrico": true}) == 0.5, "Faults cost value and the loss is capped")
    check(is_equal_approx(Pricing.fair_value_ars(gol, 2019, 84000.0, 75.0, {}, 1000000.0) - typical, 450000.0), "Fitted parts retain part of their price")
    var classic: Dictionary = Catalog.find("fiat-128")
    check(absf(Pricing.fair_value_ars(classic, 1980, 150000.0, 75.0) / Catalog.reference_ars(classic) - 1.0) < 0.02, "Classics are priced around their reference at typical age and mileage")
    check(Pricing.repair_cost_credits(gol, "nitro", 10.0) == -1 and absi(Pricing.repair_cost_credits(gol, "motor", 50.0) - 2 * Pricing.repair_cost_credits(gol, "motor", 25.0)) <= 1 and Pricing.repair_cost_credits(gol, "motor", 25.0, true) > Pricing.repair_cost_credits(gol, "motor", 25.0), "Repair cost scales with points and faults")
    var worn := Pricing.fair_value_ars(gol, 2017, 140000.0, 45.0)
    var restored := Pricing.fair_value_ars(gol, 2017, 140000.0, 95.0)
    var bill := 0.0
    for component in Pricing.WEIGHTS:
        bill += float(Pricing.repair_cost_credits(gol, component, 50.0)) * Pricing.ARS_PER_CREDIT
    check((restored - worn) / bill > 1.15 and (restored - worn) / bill < 1.50, "Restoring a worn car pays modestly: value gain 15-50 percent above the repair bill")

    # Fees.
    var fees := Fees.purchase_fees(10000)
    check(fees["arancel"] == 100 and fees["sellos"] == 300 and fees["verificacion"] == 55 and fees["formulario_08"] == 15 and fees["informes"] == 20 and fees["gestoria"] == 0 and fees["total"] == 490, "Purchase fees follow the document: 1 % fee, 3 % stamps and fixed paperwork")
    check(Fees.purchase_fees(10000, true)["total"] == 470 and Fees.purchase_fees(10000, false, true)["total"] == 580, "A prepaid domain report is not charged twice and the agent is optional")
    check(Fees.purchase_fees(8000)["total"] >= 390 and Fees.purchase_fees(8000)["total"] <= 420, "Transfer cost of an 8 M car matches the document's example")
    check(Fees.sale_fees(10000, "particular")["total"] == 50 and Fees.sale_fees(500, "particular")["total"] == 40 and Fees.sale_fees(10000, "agencia")["total"] == 0, "Private sales pay paperwork, dealers do not")
    check(Fees.inspection_cost(0) == 80 and Fees.inspection_cost(10000) == 100 and Fees.inspection_cost(10000000) == 400, "Inspection cost scales with the car and is bounded")

    # Negotiation.
    check(Negotiation.reserve_for(10000, 0.10, 0) == 9000 and Negotiation.reserve_for(10000, 0.10, 20) == 8400 and Negotiation.reserve_for(10000, 0.10, 500) == 8000 and Negotiation.reserve_for(10000, 0.10, 0, 500) == 8500, "Reserve falls with time on the market and with proven problems")
    var talk = Negotiation.new(10000, 9000)
    check(talk.offer(10500).price == 10000 and talk.closed, "An offer above the ask pays only the ask")
    talk = Negotiation.new(10000, 9000)
    check(talk.offer(9000).status == "accepted" and talk.offer(9500).status == "closed", "An offer at the reserve is accepted and the talk closes")
    talk = Negotiation.new(10000, 9000)
    var counter: Dictionary = talk.offer(8000)
    check(counter.status == "counter" and counter.price >= 9500 and counter.price <= 9900 and counter.rounds_left == 2, "A fair offer gets a counter well above the reserve")
    var deal: Dictionary = talk.accept_counter()
    check(deal.status == "accepted" and deal.price == counter.price and talk.accept_counter().status == "invalid", "The counter can be accepted once")
    talk = Negotiation.new(10000, 9000)
    check(talk.offer(6000).status == "rejected" and talk.offer(6000).status == "rejected" and talk.offer(6000).status == "rejected", "Lowballs are rejected")
    check(talk.offer(6000).status == "walked" and talk.walked and talk.offer(9500).status == "closed", "A persistent buyer makes the seller walk away")
    check(Negotiation.new(10000, 9000).offer(0).status == "invalid" and Negotiation.new(10000, 99999).reserve == 10000, "Invalid offers and absurd reserves are handled")

    # Listings are valid economy cars with plausible prices and sellers.
    var rng := RandomNumberGenerator.new()
    rng.seed = 12345
    var market = Economy.new()
    var ratios := {"particular": [], "agencia": [], "urgente": []}
    var fault_count := {"particular": 0, "agencia": 0, "urgente": 0}
    var in_range := 0
    var total := 0
    var all_valid := true
    var id := 1
    for entry in Catalog.all():
        for i in range(3):
            var listing: Dictionary = Listings.generate(entry, id, rng)
            market.cars.append(listing)
            id += 1
    for car in market.cars:
        var entry: Dictionary = Catalog.find(car["catalog_id"])
        var clean := Pricing.fair_value_credits(entry, int(car["year"]), float(car["km"]), market.condition(car), {}, 0.0, 1.0, Pricing.gnc_factor(entry, bool(car.get("gnc", false))))
        var ratio := float(car["price"]) / float(maxi(clean, 1))
        ratios[car["seller"]].append(ratio)
        if not car["faults"].is_empty():
            fault_count[car["seller"]] += 1
        var spread: Array = Listings.SELLERS[car["seller"]]["markup"]
        var volatile_price := str(entry.get("liquidity", "media")) == "baja"
        var lower := float(clean) * float(spread[0]) * (0.94 if volatile_price else 1.0) - 26.0
        var upper := float(clean) * float(spread[1]) * (1.06 if volatile_price else 1.0) + 26.0
        all_valid = all_valid and float(car["price"]) >= lower and float(car["price"]) <= upper and int(car["year"]) >= int(entry["year_min"]) and int(car["year"]) <= int(entry["year_max"]) and int(car["km"]) >= 0 and int(car["price"]) >= 100
        total += 1
        if float(car["price"]) * 1000.0 >= 0.7 * float(entry["price_min"]) and float(car["price"]) * 1000.0 <= 1.3 * float(entry["price_max"]):
            in_range += 1
    check(all_valid, "Asking prices stay within each seller's markup of the clean value")
    check(float(in_range) / float(total) > 0.85, "Over 85 percent of asking prices fall inside the source price ranges")
    var mean := func(values: Array) -> float:
        var sum := 0.0
        for value in values:
            sum += float(value)
        return sum / maxf(float(values.size()), 1.0)
    check(float(mean.call(ratios["urgente"])) < float(mean.call(ratios["agencia"])) and ratios["particular"].size() > ratios["agencia"].size() and ratios["agencia"].size() > ratios["urgente"].size(), "Urgent sellers ask less than dealers and private sellers are the most common")
    check(float(fault_count["urgente"]) / float(ratios["urgente"].size()) > float(fault_count["agencia"]) / float(ratios["agencia"].size()), "Dealers hide fewer faults than urgent sellers")
    var rng_a := RandomNumberGenerator.new()
    rng_a.seed = 99
    var rng_b := RandomNumberGenerator.new()
    rng_b.seed = 99
    check(Listings.generate(gol, 7, rng_a, 3) == Listings.generate(gol, 7, rng_b, 3), "Listings are deterministic for a given seed")
    var round_trip = Economy.new()
    check(round_trip.from_dict(market.to_dict()) and round_trip.cars.size() == market.cars.size(), "Market listings survive the existing save schema")
    var decoded: Dictionary = Store.decode(Store.encode(market, Career.new()))
    check(decoded.error.is_empty(), "Market listings survive a JSON save")

    # Deals on top of the economy.
    var game = Economy.new()
    game.seed_demo()
    var gid := Deal.next_id(game)
    check(gid == game.cars.size() + 1 and Deal.add_listing(game, gol_listing(gid)) and not Deal.add_listing(game, gol_listing(gid)) and not Deal.add_listing(game, {}), "Listings are added once with unique ids")
    var quote: Dictionary = Deal.quote_purchase(game, gid)
    check(quote.ok and quote.price == 12000 and quote.fees.total == 570 and quote.documents == 860 and quote.total == 13430 and not quote.documents_known, "Purchase quote includes fees and paperwork")
    check(not Deal.quote_purchase(game, gid, 12500).ok and not Deal.quote_purchase(game, 999).ok, "Cannot pay above the ask or buy missing cars")
    var before: int = game.balance
    var revealed: Dictionary = Deal.purchase(game, gid)
    var listing_now: Dictionary = game.find_car(gid)
    check(not revealed.ok and revealed.reason == "documents_revealed" and listing_now["doc_checked"] and listing_now["owner"] == "seller" and game.balance == before - Fees.DOMAIN_REPORT, "Hidden paperwork problems are revealed at the notary when the buyer cannot cover them")
    check(Deal.check_domain(game, gid).begins_with("El informe de dominio ya fue pedido") and game.balance == before - Fees.DOMAIN_REPORT, "The domain report is not charged twice")
    var talk2 = Deal.start_negotiation(game, gid, 0)
    check(talk2 != null and talk2.reserve == 10370 and talk2.ask == 12000, "Verified paperwork debts give the buyer a concession")
    check(talk2.offer(10400).status == "accepted", "An offer above the reserve is accepted")
    var bought: Dictionary = Deal.purchase(game, gid, 10400)
    check(bought.ok and bought.total == 11698 and game.balance == before - Fees.DOMAIN_REPORT - 11698 and game.balance >= 0, "Purchase charges price, fees and paperwork once")
    var owned: Dictionary = game.find_car(gid)
    check(owned["owner"] == "player" and not owned["listed"] and owned["documents"]["deuda"] == 0 and not owned["documents"]["prenda"] and Deal.net_result(game, gid) == -(11698 + Fees.DOMAIN_REPORT), "The car is transferred with clean paperwork and the ledger adds up")
    check(not Deal.purchase(game, gid).ok and Deal.start_negotiation(game, gid, 0) == null, "A bought car cannot be bought or negotiated again")
    var lock_id := Deal.next_id(game)
    Deal.add_listing(game, gol_listing(lock_id))
    Deal.lock_seller(game, lock_id, 2)
    check(Deal.start_negotiation(game, lock_id, 5) == null and not Deal.purchase(game, lock_id, -1, 5).ok and Deal.start_negotiation(game, lock_id, 9) != null, "A seller who walked away is unavailable for a week")

    # Inspection reveals faults and justifies a concession.
    var lemon := gol_listing(Deal.next_id(game), 9000)
    lemon["faults"] = {"motor": true}
    lemon["documents"] = {"deuda": 0, "prenda": false, "sin_titularidad": false, "vtv": true}
    Deal.add_listing(game, lemon)
    var lid: int = lemon["id"]
    var blind = Deal.start_negotiation(game, lid, 0)
    var money: int = game.balance
    var report := Deal.inspect(game, lid)
    var informed = Deal.start_negotiation(game, lid, 0)
    check(report.begins_with("Inspección completada") and game.balance < money and informed.reserve < blind.reserve and Deal.inspect(game, lid).begins_with("Este vehículo ya fue"), "Inspecting costs credits, finds the fault and lowers the seller's reserve")
    var dealer_listing := gol_listing(Deal.next_id(game), 9000)
    dealer_listing["seller"] = "agencia"
    dealer_listing["faults"] = {"motor": true}
    Deal.add_listing(game, dealer_listing)
    Deal.inspect(game, int(dealer_listing["id"]))
    var firm = Deal.start_negotiation(game, int(dealer_listing["id"]), 0)
    check(firm.reserve == Negotiation.reserve_for(9000, 0.10, 0, 0, Deal.skill(game)), "Dealerships do not concede for faults")

    # Selling.
    var fair := Deal.fair_credits(game, gid)
    var offer_dealer := Deal.dealer_quote(game, gid)
    check(fair > 0 and offer_dealer < int(float(fair) * 0.9) and offer_dealer > int(float(fair) * 0.7) and Deal.dealer_quote(game, 1) == 0, "Dealers pay 70-90 percent of the true value and only for owned cars")
    check(Deal.daily_interest(int(fair * 1.5), fair) < Deal.daily_interest(fair, fair) and Deal.daily_interest(fair, fair) < Deal.daily_interest(int(fair * 0.9), fair) and Deal.daily_interest(fair * 100, fair) == 0.02 and Deal.daily_interest(1, fair) == 0.60 and Deal.daily_interest(10, 0) == 0.0, "Buyer interest falls steeply as the price rises above value")
    var days_with_offers := 0
    var offers_ok := true
    for day in range(60):
        var offers: Array = Deal.private_offers(game, gid, fair, day)
        if offers == Deal.private_offers(game, gid, fair, day):
            days_with_offers += 1 if not offers.is_empty() else 0
        else:
            offers_ok = false
        for amount in offers:
            offers_ok = offers_ok and amount >= int(float(fair) * 0.82) - 1 and amount <= int(float(fair) * 0.97) + 1
    check(offers_ok and days_with_offers > 3 and Deal.private_offers(game, 1, fair, 0).is_empty(), "Private buyers make deterministic offers around the asking price")
    var balance_before: int = game.balance
    var private_sale: Dictionary = Deal.sell_private(game, gid, 14000)
    check(private_sale.ok and private_sale.net == 14000 - Fees.sale_fees(14000, "particular")["total"] and game.balance == balance_before + int(private_sale.net) and game.find_car(gid)["owner"] == "sold", "A private sale pays the price minus paperwork")
    check(not Deal.sell_private(game, gid, 14000).ok and not Deal.sell_dealer(game, gid).ok and not Deal.sell_private(game, 1, 10).ok, "A car cannot be sold twice or by someone else")
    var net := Deal.net_result(game, gid)
    check(net == -(11698 + Fees.DOMAIN_REPORT) + int(private_sale.net), "Net result adds purchases, costs and the sale")
    var second := gol_listing(Deal.next_id(game), 13000)
    second["documents"] = {"deuda": 0, "prenda": false, "sin_titularidad": false, "vtv": true}
    Deal.add_listing(game, second)
    var sid: int = second["id"]
    Deal.purchase(game, sid, -1)
    var dealer_money: int = game.balance
    var sold: Dictionary = Deal.sell_dealer(game, sid)
    check(sold.ok and game.balance == dealer_money + int(sold.net) and Deal.net_result(game, sid) < 0, "Buying at the ask and selling to a dealer loses money")
    check(game.balance >= 0, "The balance never goes negative")
    check(Deal.deals(game) == 4, "Every completed purchase and sale counts as a deal")
    var exported: Dictionary = game.to_dict()
    check(Economy.new().from_dict(exported), "The economy still loads after market operations")
    if failed:
        quit(1)
    else:
        print("PASS: %d market assertions" % checks)
        quit(0)
