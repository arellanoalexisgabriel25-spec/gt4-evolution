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
