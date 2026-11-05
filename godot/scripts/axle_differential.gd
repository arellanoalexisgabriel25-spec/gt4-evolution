extends RefCounted

# Quasi-static driven-axle traction envelope. The live model still has one
# rotational inertia per axle: it does not simulate independent wheel speeds or
# differential locking heat. No differential multiplies engine torque or power.
# Open: equal left/right torque limited by the weaker contact. Limited-slip:
# finite bias and preload, bounded by each contact. Locked: combined contacts.
static func capacity(left_n: float, right_n: float, kind: String, bias_ratio: float, preload_force_n: float) -> float:
    if not is_finite(left_n) or not is_finite(right_n) or not is_finite(bias_ratio) or not is_finite(preload_force_n): return 0.0
    var weak := minf(maxf(left_n,0.0),maxf(right_n,0.0))
    var strong := maxf(maxf(left_n,0.0),maxf(right_n,0.0))
    match kind:
        "locked": return weak+strong
        "limited_slip": return weak+minf(strong,weak*maxf(1.0,bias_ratio)+maxf(0.0,preload_force_n))
        _: return 2.0*weak
