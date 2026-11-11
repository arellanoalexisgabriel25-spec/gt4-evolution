extends SceneTree

const Money = preload("res://scripts/money.gd")
const Economy = preload("res://scripts/economy.gd")
const Career = preload("res://scripts/career.gd")
const Store = preload("res://scripts/save_store.gd")
var checks := 0
var failed := false

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed = true
        push_error(message)

func _initialize() -> void:
    check(Money.format(12000)=="$ 12.000.000 ARS","Starting funds display Argentine pesos with local grouping")
    check(Money.format(200)=="$ 200.000 ARS" and Money.format(0)=="$ 0 ARS","Quotes and zero balances share the same denomination")
    check(Money.format(-120)=="-$ 120.000 ARS" and Money.format(700,true)=="+$ 700.000 ARS","Debits and awards retain their correct signs")
    var game = Economy.new()
    game.seed_demo()
    var career = Career.new()
    var original: Dictionary = game.to_dict()
    original.erase("currency_code")
    original.erase("money_unit_ars")
    var old_balance: int = original.balance
    var old_price: int = original.cars[0].price
    check(game.from_dict(original) and game.balance==old_balance,"A legacy save migrates currency metadata without multiplying its ledger")
    check(game.to_dict().currency_code=="ARS" and game.to_dict().money_unit_ars==1000,"New saves explicitly declare Argentine pesos and integer denomination")
    var total: int = preload("res://scripts/market_deal.gd").quote_purchase(game, 1).total
    check(game.buy(1).contains("ARS") and game.balance==old_balance-total,"A purchase displays pesos and debits exactly once")
    var before: int = game.balance
    var quote: int = game.resale_quote(1)
    check(game.sell(1).contains(Money.format(quote)) and game.balance==before+quote,"Resale credits the same denomination used by purchase")
    var snapshot: Dictionary = game.to_dict()
    for i in range(5):
        var loaded: Dictionary = Store.decode(Store.encode(game,career))
        check(loaded.get("error")=="" and loaded.game.balance==game.balance and loaded.game.cars[0].price==old_price,"Repeated JSON reload cannot compound the denomination conversion")
        game = loaded.game
        career = loaded.career
    snapshot = game.to_dict()
    var invalid := snapshot.duplicate(true)
    invalid["currency_code"] = "USD"
    check(not game.from_dict(invalid) and game.to_dict()==snapshot,"A different declared currency is rejected atomically")
    invalid = snapshot.duplicate(true)
    invalid["money_unit_ars"] = 1
    check(not game.from_dict(invalid) and game.to_dict()==snapshot,"A mixed monetary unit cannot silently change balances")
    var ledger_before: Array = game.ledger.duplicate(true)
    var legacy: Dictionary = game.to_dict()
    legacy.erase("currency_code")
    legacy.erase("money_unit_ars")
    check(game.from_dict(legacy) and game.ledger==ledger_before,"Historical debits and credits keep their original proportions")
    if not failed:
        print("PASS: %d ARS money assertions" % checks)
    quit(1 if failed else 0)
