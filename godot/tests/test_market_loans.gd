extends SceneTree

const Economy = preload("res://scripts/economy.gd")
const Loans = preload("res://scripts/market_loans.gd")
const Deal = preload("res://scripts/market_deal.gd")
const Upkeep = preload("res://scripts/market_upkeep.gd")
const MarketState = preload("res://scripts/market_state.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func clean_listing(game, price: int) -> int:
    var id: int = Deal.next_id(game)
    Deal.add_listing(game, {
        "id": id, "model": "Fiat Uno Fire 3 puertas", "km": 80000, "health": {"motor": 70.0, "transmision": 70.0, "suspension": 70.0, "frenos": 70.0, "neumaticos": 70.0, "chasis": 70.0, "electrico": 70.0}, "faults": {},
        "owner": "seller", "listed": true, "inspected": false, "price": price, "upgrades": [], "history": [],
        "catalog_id": "fiat-uno-fire-3-puertas", "year": 2012, "seller": "particular",
        "documents": {"deuda": 0, "prenda": false, "sin_titularidad": false, "vtv": true},
        "flex": 0.10, "listed_day": 0, "doc_checked": false, "locked_until_day": 0, "service_km": 75000, "warranty_days": 0})
    return id

func events(game, id: int, event: String) -> int:
    var count := 0
    for entry in game.ledger:
        if entry["car_id"] == id and entry["event"] == event:
            count += 1
    return count

func _initialize() -> void:
    var game = Economy.new()
    game.seed_demo()
    # Terms.
    var terms: Dictionary = Loans.offer(game, 10000, 24)
    check(terms.ok and terms.principal == 6000 and terms.payment == 370 and terms.months == 24 and terms.fees == 150 and terms.interest == 2880 and is_equal_approx(terms.rate, 0.034), "A 24 month loan on 10,000 at score 50 lends 60 percent")
    check(Loans.offer(game, 10000, 18).reason == "term" and Loans.offer(game, 400, 12).reason == "small", "Unknown terms and tiny loans are refused")
    game.market["credit"] = 20
    check(Loans.offer(game, 10000, 24).reason == "score" and Loans.summary(game, 10000).begins_with("SIN FINANCIACIÓN"), "A low credit score gets no loan")
    game.market["credit"] = 100
    check(is_equal_approx(Loans.ltv(game), 0.75) and is_equal_approx(Loans.monthly_rate(game, 24), 0.030) and Loans.offer(game, 10000, 24).payment == 443, "A top score gets more credit at a lower rate")
    game.market["credit"] = 50
    check(Loans.summary(game, 10000).begins_with("FINANCIACIÓN 60 %") and Loans.summary(game, 10000).contains("12 meses") and Loans.summary(game, 10000).contains("36 meses"), "The offer summary lists every term")

    # A financed purchase.
    var id := clean_listing(game, 10000)
    game.balance = 3000
    var poor: Dictionary = Deal.purchase(game, id, -1, -1, 24)
    check(not poor.ok and poor.reason == "insufficient" and game.balance == 3000 and game.find_car(id)["owner"] == "seller", "Without the down payment nothing is charged")
    check(not Deal.purchase(game, id, -1, -1, 18).ok and Deal.describe(Deal.purchase(game, id, -1, -1, 18)).begins_with("Plazo"), "Invalid terms are explained")
    game.balance = 12000
    var message: String = game.buy(id, -1, 24)
    var car: Dictionary = game.find_car(id)
    check(message.begins_with("Compraste") and message.contains("Financiado: cuota") and game.balance == 12000 - 4640 and car["owner"] == "player", "The buyer pays the price minus the loan plus its fees")
    check(Loans.has_loan(car) and is_equal_approx(float(car["loan"]["balance"]), 6000.0) and car["loan"]["payment"] == 370 and Deal.net_result(game, id) == -4640 and events(game, id, "prestamo") == 1 and events(game, id, "gastos_prenda") == 1, "The loan is attached and the ledger adds up")
    check(Loans.active_loans(game) == 1 and Loans.describe(car).begins_with("PRÉSTAMO PRENDARIO") and Loans.months_left(car["loan"]) >= 23 and Loans.months_left(car["loan"]) <= 24, "The loan is described with its remaining installments")

    # Paying it off on time.
    var first: Dictionary = Loans.apply_month(game)
    check(first.paid == 370 and is_equal_approx(float(car["loan"]["balance"]), 5834.0) and car["loan"]["missed"] == 0 and Loans.score(game) == 52 and events(game, id, "cuota") == 1, "An installment reduces the balance and raises the score")
    game.balance = 100000
    var cleared := 0
    for step_month in range(23):
        cleared += int(Loans.apply_month(game)["cleared"])
    check(cleared == 1 and not Loans.has_loan(car) and events(game, id, "cuota") == 24 and events(game, id, "prestamo_cancelado") == 1 and Loans.score(game) == 100, "24 on-time installments clear the loan and top the score")

    # Missing installments ends in seizure.
    var late = Economy.new()
    late.seed_demo()
    var late_id := clean_listing(late, 10000)
    late.balance = 12000
    late.buy(late_id, -1, 24)
    var owned: Dictionary = late.find_car(late_id)
    late.balance = 0
    var miss1: Dictionary = Loans.apply_month(late)
    check(miss1.late == 1 and owned["loan"]["missed"] == 1 and absf(float(owned["loan"]["balance"]) - 6211.4) < 0.01 and Loans.score(late) == 45 and Loans.has_arrears(late), "A missed installment adds a late fee and costs score")
    check(Loans.offer(late, 10000, 24).reason == "arrears", "With arrears no new loan is offered")
    late.balance = 1000
    var recover: Dictionary = Loans.apply_month(late)
    check(recover.paid == 370 and owned["loan"]["missed"] == 0 and late.balance == 630, "Paying again resets the missed count")
    late.balance = 0
    Loans.apply_month(late)
    Loans.apply_month(late)
    var seize: Dictionary = Loans.apply_month(late)
    check(seize.seized == [owned["model"]] and owned["owner"] == "sold" and not Loans.has_loan(owned) and events(late, late_id, "secuestro") == 1 and late.balance == 0 and Loans.score(late) < 30, "Three missed installments in a row lose the car")

    # Early payoff.
    var payoff_game = Economy.new()
    payoff_game.seed_demo()
    var pay_id := clean_listing(payoff_game, 10000)
    payoff_game.balance = 12000
    payoff_game.buy(pay_id, -1, 24)
    payoff_game.balance = 100
    check(Loans.payoff(payoff_game, pay_id).begins_with("Saldo insuficiente") and Loans.has_loan(payoff_game.find_car(pay_id)), "A payoff needs the balance")
    payoff_game.balance = 20000
    var amount: int = Loans.payoff_amount(payoff_game.find_car(pay_id))
    check(Loans.payoff(payoff_game, pay_id).begins_with("Cancelaste") and payoff_game.balance == 20000 - amount and not Loans.has_loan(payoff_game.find_car(pay_id)) and Loans.score(payoff_game) == 53, "Paying off releases the lien and raises the score")
    check(Loans.payoff(payoff_game, pay_id).begins_with("Ese auto no tiene") and Loans.payoff(payoff_game, 1).begins_with("Ese auto no tiene"), "Only financed cars can be paid off")

    # Selling a financed car.
    var sale_game = Economy.new()
    sale_game.seed_demo()
    var sale_id := clean_listing(sale_game, 10000)
    sale_game.balance = 12000
    sale_game.buy(sale_id, -1, 24)
    var sale_car: Dictionary = sale_game.find_car(sale_id)
    var gross: int = Deal.dealer_gross(sale_game, sale_id)
    var cash: int = sale_game.balance
    var sold: Dictionary = Deal.sell_dealer(sale_game, sale_id)
    check(sold.ok and sale_game.balance == cash + gross - 6000 and not Loans.has_loan(sale_car) and events(sale_game, sale_id, "cancelacion_prestamo") == 1, "A sale pays the loan off out of the proceeds")
    var short_game = Economy.new()
    short_game.seed_demo()
    var short_id := clean_listing(short_game, 10000)
    short_game.balance = 12000
    short_game.buy(short_id, -1, 24)
    var short_car: Dictionary = short_game.find_car(short_id)
    short_car["loan"]["balance"] = 50000.0
    short_game.balance = 100
    var blocked: Dictionary = Deal.sell_dealer(short_game, short_id)
    check(not blocked.ok and blocked.reason == "loan_shortfall" and short_car["owner"] == "player" and short_game.balance == 100 and Deal.describe(blocked).begins_with("La venta no alcanza"), "A sale that cannot cover the loan is refused")
    check(not Deal.sell_private(short_game, short_id, 9000).ok and short_game.balance == 100, "The same goes for private sales")
    short_game.balance = 100000
    var covered: Dictionary = Deal.sell_private(short_game, short_id, 9000)
    check(covered.ok and short_game.balance < 100000 and short_game.balance >= 0 and short_car["owner"] == "sold", "With enough balance the shortfall is paid and the balance stays non-negative")

    # Parking: the first two cars are free.
    var garage = Economy.new()
    garage.seed_demo()
    garage.balance = 200000
    var ids: Array = []
    for i in range(3):
        var car_id := clean_listing(garage, 8000)
        garage.buy(car_id)
        ids.append(car_id)
    check(Upkeep.estimate(garage, garage.find_car(ids[0]))["cochera"] == 0 and Upkeep.estimate(garage, garage.find_car(ids[1]))["cochera"] == 0 and Upkeep.estimate(garage, garage.find_car(ids[2]))["cochera"] == 55 and Upkeep.describe(garage, garage.find_car(ids[2])).contains("cochera"), "From the third car on parking is charged")
    var month: Dictionary = Upkeep.apply_month(garage, 30)
    check(events(garage, ids[2], "cochera") == 1 and events(garage, ids[0], "cochera") == 0 and month.cars == 3, "Only the third car pays parking")
    garage.balance = 0
    var debt_before := int(garage.find_car(ids[2])["documents"]["deuda"])
    Upkeep.apply_month(garage, 60)
    check(int(garage.find_car(ids[2])["documents"]["deuda"]) >= debt_before + 55 and garage.balance == 0, "Unpaid parking becomes a debt of the car")

    # The monthly tick collects installments before other costs and reports them.
    var tick = Economy.new()
    tick.seed_demo()
    var tick_id := clean_listing(tick, 10000)
    tick.balance = 12000
    tick.buy(tick_id, -1, 24)
    tick.market["day"] = 29
    var report: Dictionary = MarketState.advance_day(tick)
    check(report.loans.paid == 370 and MarketState.describe(report).contains("cuotas del banco"), "The month tick collects installments and reports them")
    tick.balance = 0
    tick.market["day"] = 59
    check(MarketState.describe(MarketState.advance_day(tick)).contains("atrasada"), "Late installments appear in the daily report")
    check(MarketState.valid_state({"day": 1, "index": 1.0, "seed": 1, "credit": 70}) and not MarketState.valid_state({"day": 1, "index": 1.0, "seed": 1, "credit": 150}) and MarketState.default_state()["credit"] == 50, "The credit score is validated")
    if failed:
        quit(1)
    else:
        print("PASS: %d market loan assertions" % checks)
        quit(0)
