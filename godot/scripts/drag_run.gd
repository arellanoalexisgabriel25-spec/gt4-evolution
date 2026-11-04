extends RefCounted

const DISTANCE := 402.336
const ROLLOUT := 0.20
const GREEN_TIME := 2.0
const SPLITS := [18.288,100.0,201.168,DISTANCE-20.1168,DISTANCE]
var phase := "preparation"
var clock := 0.0
var previous_position := 0.0
var previous_speed := 0.0
var launch_time := -1.0
var reaction := -1.0
var elapsed := 0.0
var total := 0.0
var trap_speed := 0.0
var finish_speed := 0.0
var splits: Dictionary = {}
var reason := ""

func arm(position: float, speed: float) -> bool:
    if phase != "preparation" or absf(position)>0.10 or absf(speed)>0.10:
        return false
    phase = "countdown"
    clock = 0.0
    previous_position = position
    previous_speed = speed
    return true

func invalidate(message: String) -> void:
    if phase in ["finished","invalid"]:
        return
    phase = "invalid"
    reason = message

func advance(delta: float, position: float, speed: float, in_lane: bool = true) -> void:
    if delta <= 0.0 or not is_finite(delta) or not is_finite(position) or not is_finite(speed):
        return
    if phase not in ["countdown","running"]:
        return
    var before := clock
    clock += delta
    if not in_lane:
        invalidate("FUERA DE CARRIL")
        return
    if position < previous_position-0.5 or position-previous_position > maxf(5.0,(absf(speed)+absf(previous_speed))*delta+1.0):
        invalidate("MOVIMIENTO INVÁLIDO")
        return
    var movement := position-previous_position
    if launch_time < 0.0 and previous_position <= ROLLOUT and position > ROLLOUT:
        launch_time = before+delta*(ROLLOUT-previous_position)/movement
        reaction = launch_time-GREEN_TIME
        if reaction < -0.000001:
            invalidate("LARGADA EN FALSO")
            return
        reaction = maxf(0,reaction)
    if clock >= GREEN_TIME:
        phase = "running"
    if launch_time >= 0.0:
        elapsed = clock-launch_time
        for marker in SPLITS:
            var key := str(marker)
            if not splits.has(key) and previous_position < marker and position >= marker:
                var fraction := (float(marker)-previous_position)/movement
                splits[key] = before+delta*fraction-launch_time
                if marker == DISTANCE:
                    elapsed = splits[key]
                    total = elapsed+reaction
                    finish_speed = lerpf(previous_speed,speed,fraction)*3.6
                    var trap_seconds := elapsed-float(splits.get(str(DISTANCE-20.1168),elapsed))
                    trap_speed = 20.1168/trap_seconds*3.6 if trap_seconds > 0 else finish_speed
                    phase = "finished"
    if clock > GREEN_TIME+120.0 and phase != "finished":
        invalidate("TIEMPO MÁXIMO AGOTADO")
    previous_position = position
    previous_speed = speed

func report() -> Dictionary:
    if phase != "finished":
        return {}
    return {"distance":DISTANCE,"et":elapsed,"reaction":reaction,"total":total,"trap_kmh":trap_speed,"finish_kmh":finish_speed,"sixty_ft":float(splits.get(str(SPLITS[0]),0.0)),"eighth":float(splits.get(str(SPLITS[2]),0.0))}
