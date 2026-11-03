extends Node

const Economy = preload("res://scripts/economy.gd")
const Career = preload("res://scripts/career.gd")

var game: EvolutionEconomy
var career: EvolutionCareer
var selected_vehicle: int = 0

func _ready() -> void:
    reset()

func reset() -> void:
    game = Economy.new()
    game.seed_demo()
    career = Career.new()
    selected_vehicle = 0

func choose_vehicle(car_id: int) -> bool:
    var car: Dictionary = game.find_car(car_id)
    if car.is_empty() or car.get("owner", "") != "player" or not game.eligible(car):
        return false
    selected_vehicle = car_id
    return true
