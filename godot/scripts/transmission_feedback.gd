extends RefCounted

# Presentation event reader shared by sound and haptics. It never requests a
# shift or modifies physics, and consumes each outcome once even while paused.
const CUES := {
    "perfect":{"duration":0.07,"frequency":1750.0,"noise":0.12,"gain":0.045,"weak":0.10,"strong":0.04},
    "acceptable":{"duration":0.10,"frequency":1250.0,"noise":0.30,"gain":0.055,"weak":0.18,"strong":0.08},
    "poor":{"duration":0.18,"frequency":360.0,"noise":0.70,"gain":0.09,"weak":0.36,"strong":0.25},
    "rejected":{"duration":0.24,"frequency":180.0,"noise":0.92,"gain":0.12,"weak":0.68,"strong":0.48},
}
var last_serial := -1

func observe(model: Object) -> Dictionary:
    if model==null or not is_instance_valid(model): return {}
    var event = model.get("shift_event_serial")
    if typeof(event) not in [TYPE_INT,TYPE_FLOAT]: return {}
    var serial := int(event)
    if last_serial<0 or serial<last_serial:
        last_serial = serial
        return {}
    if serial==last_serial: return {}
    last_serial = serial
    var quality := str(model.get("shift_quality"))
    if not CUES.has(quality): return {}
    var result: Dictionary = CUES[quality].duplicate()
    result["quality"] = quality
    return result

static func color(quality: String) -> Color:
    var style = preload("res://scripts/racing_theme.gd")
    return {"perfect":style.SUCCESS,"acceptable":style.SELECTED,"poor":style.WARNING,"rejected":style.DANGER}.get(quality,style.TEXT)
