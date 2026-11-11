extends RefCounted

# Art. 11 authorizes warming ONLY ahead of the start line while the red tree /
# far-end yellow lamps permit it; blue calls drivers back to alignment. Art. 10
# gives the starter control of the tree. The source does not give a general
# warm-up duration or a ready-hold interval: the defaults below are game pacing.
# The special 60-second late-presentation rule is NOT a universal burnout timer.
# This module owns no vehicle, timing ticket, economy or save data. Its caller
# validates the authorized physical zone and actual stationary beam readiness.
const SOURCE_SHA256 := "46b13eb02fac46a50381509129a82a2eaa623754d7d0bd262d35e5c9cc089acc"
const SOURCE_ARTICLES := [10, 11, 27]
const DEFAULT_WARMUP_SECONDS := 25.0
const DEFAULT_STAGING_SECONDS := 30.0
const DEFAULT_READY_HOLD_SECONDS := 1.5

var phase := "burnout"
var phase_elapsed := 0.0
var elapsed := 0.0
var ready_elapsed := 0.0
var player_ready := false
var rival_ready := false
var reason := ""
var configuration_valid := true
var _warmup_seconds := DEFAULT_WARMUP_SECONDS
var _staging_seconds := DEFAULT_STAGING_SECONDS
var _ready_hold_seconds := DEFAULT_READY_HOLD_SECONDS
var _pending_start := false
var remaining: float:
    get:
        if phase == "burnout":
            return maxf(0.0, _warmup_seconds - phase_elapsed)
        if phase == "staging":
            return maxf(0.0, _staging_seconds - phase_elapsed)
        return 0.0
var warmup_allowed: bool:
    get: return phase == "burnout"

func _init(warmup_seconds: float = DEFAULT_WARMUP_SECONDS, staging_seconds: float = DEFAULT_STAGING_SECONDS, ready_hold_seconds: float = DEFAULT_READY_HOLD_SECONDS) -> void:
    if not configure(warmup_seconds, staging_seconds, ready_hold_seconds):
        configuration_valid = false
        cancel_start("CONFIGURACIÓN DE LARGADA INVÁLIDA")

# Validation is atomic. Rejected configuration does not change a live procedure.
# Successful reconfiguration starts a fresh preparation, useful for test fixtures.
func configure(warmup_seconds: float, staging_seconds: float, ready_hold_seconds: float) -> bool:
    for value in [warmup_seconds, staging_seconds, ready_hold_seconds]:
        if not is_finite(value) or value <= 0.0:
            return false
    if not is_finite(warmup_seconds + staging_seconds) or ready_hold_seconds > staging_seconds:
        return false
    _warmup_seconds = warmup_seconds
    _staging_seconds = staging_seconds
    _ready_hold_seconds = ready_hold_seconds
    configuration_valid = true
    reset()
    return true

func reset() -> void:
    phase = "burnout" if configuration_valid else "expired"
    phase_elapsed = 0.0
    elapsed = 0.0
    ready_elapsed = 0.0
    player_ready = false
    rival_ready = false
    reason = "" if configuration_valid else "CONFIGURACIÓN DE LARGADA INVÁLIDA"
    _pending_start = false

# Do not call during pause. Readiness must include the real beam, a stopped car,
# engine/gear/clutch state and safe mechanical condition. It is never an Enter
# action. A lost ready signal resets the continuous hold; neither car starts alone.
# A large valid delta carries the warm-up remainder into staging without skipping
# the mandatory ready hold. Delta after a start request belongs to DragRun.
func advance(delta: float, is_player_ready: bool, is_rival_ready: bool = true) -> void:
    if not is_finite(delta) or delta <= 0.0 or phase not in ["burnout", "staging"]:
        return
    player_ready = is_player_ready
    rival_ready = is_rival_ready
    var budget := delta
    if phase == "burnout":
        var warmup_step := minf(budget, remaining)
        phase_elapsed += warmup_step
        elapsed += warmup_step
        budget -= warmup_step
        if phase_elapsed < _warmup_seconds:
            return
        phase = "staging"
        phase_elapsed = 0.0
        ready_elapsed = 0.0
    if phase != "staging" or budget <= 0.0:
        return
    var staging_step := minf(budget, remaining)
    if player_ready and rival_ready:
        var hold_remaining := maxf(0.0, _ready_hold_seconds - ready_elapsed)
        var hold_step := minf(staging_step, hold_remaining)
        ready_elapsed += hold_step
        phase_elapsed += hold_step
        elapsed += hold_step
        if hold_step >= hold_remaining:
            phase = "countdown"
            _pending_start = true
            return
    else:
        ready_elapsed = 0.0
        phase_elapsed += staging_step
        elapsed += staging_step
    if phase_elapsed >= _staging_seconds:
        var missing := "POSICIÓN NO ESTABLE"
        if not player_ready and not rival_ready:
            missing = "AMBOS PILOTOS"
        elif not player_ready:
            missing = "PILOTO"
        elif not rival_ready:
            missing = "RIVAL"
        cancel_start("FUERA DE PLAZO DE ALINEACIÓN · " + missing)

# One request per fresh procedure. Physical arming may still fail between the
# readiness sample and Run.arm; callers then cancel explicitly instead of silently
# resuming a stale preparation or starting only one lane.
func consume_start() -> bool:
    if phase != "countdown" or not _pending_start:
        return false
    _pending_start = false
    return true

# The starter can end the warm-up early if a driver leaves its marked zone.
# This calls both cars to staging without fabricating a timed race or result.
func finish_warmup_early() -> bool:
    if phase != "burnout":
        return false
    phase = "staging"
    phase_elapsed = 0.0
    ready_elapsed = 0.0
    player_ready = false
    rival_ready = false
    _pending_start = false
    return true

func cancel_start(message: String) -> void:
    phase = "expired"
    _pending_start = false
    reason = message if not message.is_empty() else "LARGADA CANCELADA"

func status() -> String:
    match phase:
        "burnout": return "CALENTAMIENTO AUTORIZADO"
        "staging": return "LUZ AZUL · ALINEAR PARA LARGAR"
        "countdown": return "ATENCIÓN AL SEMÁFORO"
        _: return reason

func snapshot() -> Dictionary:
    return {
        "phase": phase, "remaining": remaining, "elapsed": elapsed,
        "ready_elapsed": ready_elapsed, "ready_hold_seconds": _ready_hold_seconds,
        "player_ready": player_ready, "rival_ready": rival_ready,
        "warmup_allowed": warmup_allowed, "reason": reason,
        "status": status(), "source_sha256": SOURCE_SHA256,
        "red_flashing": phase == "burnout", "far_yellow_on": phase == "burnout",
        "blue_on": phase == "staging",
        "timing_policy": "game_pacing_not_official_duration"
    }
