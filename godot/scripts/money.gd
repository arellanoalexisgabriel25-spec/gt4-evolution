extends RefCounted

# Ledger integers retain their old granularity: one stored unit is ARS 1,000.
# This keeps every old balance, price, prize and historical transaction in the
# same proportion without multiplying them again each time a save is loaded.
const CODE := "ARS"
const UNIT_ARS := 1000

static func format(amount: int, signed: bool = false) -> String:
    var digits := str(amount)
    var negative := digits.begins_with("-")
    if negative:
        digits = digits.substr(1)
    if amount != 0:
        digits += "000"
    var grouped := ""
    for i in range(digits.length()):
        if i > 0 and (digits.length()-i)%3 == 0:
            grouped += "."
        grouped += digits[i]
    var prefix := "-" if negative else ("+" if signed and amount>0 else "")
    return "%s$ %s ARS" % [prefix,grouped]

static func valid_metadata(data: Dictionary) -> bool:
    if not data.has("currency_code") and not data.has("money_unit_ars"):
        return true # Legacy saves are re-denominated at their original proportions.
    return data.get("currency_code")==CODE and typeof(data.get("money_unit_ars"))==TYPE_INT and data["money_unit_ars"]==UNIT_ARS
