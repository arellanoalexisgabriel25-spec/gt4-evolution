extends Resource

# Configurable arcade defaults, measured in metres, seconds and radians.
@export_enum("FWD", "RWD", "AWD") var drivetrain: String = "RWD"
@export var acceleration: float = 15.0
@export var top_speed: float = 38.0
@export var reverse_speed: float = 10.0
@export var braking: float = 25.0
@export var grip: float = 1.0
@export var steering_angle: float = 0.58
@export var wheelbase: float = 2.5
@export var input_response: float = 3.0
@export var lateral_response: float = 5.0
@export var gear_ratios := PackedFloat32Array([3.10, 2.10, 1.50, 1.15, 0.90])
@export var final_drive: float = 4.10
@export var wheel_radius: float = 0.30
@export var reverse_ratio: float = 3.20
@export var idle_rpm: float = 900.0
@export var redline_rpm: float = 7000.0
@export var upshift_rpm: float = 6200.0
@export var downshift_rpm: float = 2200.0
@export var shift_interval: float = 0.35

# Normalized engine torque sampled evenly from idle_rpm to redline_rpm. It scales
# forward drive acceleration; an empty array means a flat 1.0 (previous behaviour).
@export var torque_curve := PackedFloat32Array([0.78, 0.90, 1.00, 1.00, 0.97, 0.90, 0.80, 0.70])
# Share of static weight on the front axle (0.3-0.7). Drives load transfer effects.
@export var front_weight_bias: float = 0.50
# Fraction of drive acceleration lost near top speed (aerodynamic/rolling drag).
@export var drag_taper: float = 0.45
# Maximum braking deceleration as a multiple of tire acceleration (grip * g).
@export var brake_grip_factor: float = 2.2
# Extra yaw rate allowed beyond what tire grip can follow; the excess becomes a slide.
@export var yaw_grip_overdrive: float = 0.35
