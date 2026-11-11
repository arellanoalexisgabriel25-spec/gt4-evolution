extends RefCounted

# One haggling session with a seller. Deterministic: the seller's behaviour comes
# from the ask and the (hidden) reserve price, so the same offers get the same answers.
var ask := 0
var reserve := 0
var rounds_left := 3
var closed := false
var walked := false
var last_counter := 0

# The lowest price the seller will take: flexibility grows with time on the market
# (up to 10 points), experienced buyers get up to 5 more points (`skill`), and
# `concession` credits are given for problems the buyer proved (known faults, debts,
# a rolled-back odometer).
static func reserve_for(asking: int, flex: float, days_listed: int, concession: int = 0, skill: float = 0.0) -> int:
    var effective := flex + minf(0.10, 0.003 * float(maxi(days_listed, 0))) + clampf(skill, 0.0, 0.05)
    return maxi(1, roundi(float(asking) * (1.0 - effective)) - maxi(concession, 0))

func _init(asking: int, reserve_price: int, rounds: int = 3) -> void:
    ask = maxi(asking, 1)
    reserve = clampi(reserve_price, 1, ask)
    rounds_left = maxi(rounds, 0)

func _result(status: String, price: int) -> Dictionary:
    return {"status": status, "price": price, "rounds_left": maxi(rounds_left, 0)}

# status: accepted (price = final), counter (price = seller's counter), rejected
# (lowball: under 70 % of the ask), walked (seller ends the talk), closed, invalid.
func offer(amount: int) -> Dictionary:
    if closed:
        return _result("closed", 0)
    if amount <= 0:
        return _result("invalid", 0)
    if amount >= ask:
        closed = true
        return _result("accepted", ask)
    if amount >= reserve:
        closed = true
        return _result("accepted", amount)
    rounds_left -= 1
    if rounds_left < 0:
        closed = true
        walked = true
        return _result("walked", 0)
    if float(amount) < 0.70 * float(ask):
        return _result("rejected", 0)
    # The seller concedes less each round; a deterministic +-20 % wobble keeps the
    # counter from pointing straight at the reserve price.
    var step := 2 - clampi(rounds_left, 0, 2) # 0 on the first round, 2 on the last
    var progress: float = [0.70, 0.45, 0.25][step]
    var wobble := 0.8 + 0.4 * float(absi(hash([ask, reserve, rounds_left])) % 1000) / 999.0
    last_counter = clampi(reserve + roundi(float(ask - reserve) * progress * wobble), amount + 1, ask)
    return _result("counter", last_counter)

func accept_counter() -> Dictionary:
    if closed or last_counter <= 0:
        return _result("invalid", 0)
    closed = true
    return _result("accepted", last_counter)
