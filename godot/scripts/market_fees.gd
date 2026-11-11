extends RefCounted

# Transaction costs in units (1 unit = ARS 1,000). Rates and ranges follow the
# provided Buenos Aires price/cost document (November 2026): DNRPA fee 1 %, stamp
# tax 3 %, police verification 50-70, reports 15-25, form 08 10-20, optional agent
# 60-120. Midpoints are used. Approximations for the game, not official tariffs.
const ARANCEL_RATE := 0.01 # DNRPA fee, on the price
const STAMP_RATE := 0.03 # provincial stamp tax, on the price
const POLICE_CHECK := 55 # verificación policial
const DOMAIN_REPORT := 20 # informe de dominio e infracciones
const FORM_08 := 15 # formulario 08 and basic paperwork
const AGENT := 90 # gestoría, optional
const VTV_COST := 105 # technical inspection (VTV) renewal
const PRIVATE_SALE_RATE := 0.005 # seller's paperwork when selling to a private buyer
const PRIVATE_SALE_MIN := 40

# Mechanic inspection scales with the car: 80 for cheap cars, up to 400.
static func inspection_cost(value_credits: int) -> int:
    return clampi(60 + roundi(0.004 * float(maxi(value_credits, 0))), 80, 400)

# reports_paid: the domain report was already bought, so it is not charged again.
static func purchase_fees(price: int, reports_paid: bool = false, with_agent: bool = false) -> Dictionary:
    var fees := {
        "arancel": roundi(float(price) * ARANCEL_RATE),
        "sellos": roundi(float(price) * STAMP_RATE),
        "verificacion": POLICE_CHECK,
        "formulario_08": FORM_08,
        "informes": 0 if reports_paid else DOMAIN_REPORT,
        "gestoria": AGENT if with_agent else 0,
    }
    var total := 0
    for key in fees:
        total += int(fees[key])
    fees["total"] = total
    return fees

# channel: "particular" (private buyer) or "agencia" (dealer pays instantly, no fees).
static func sale_fees(price: int, channel: String) -> Dictionary:
    var agent := 0
    if channel == "particular":
        agent = maxi(PRIVATE_SALE_MIN, roundi(float(price) * PRIVATE_SALE_RATE))
    return {"gestoria": agent, "total": agent}
