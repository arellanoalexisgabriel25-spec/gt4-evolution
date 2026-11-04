extends Node

const Economy = preload("res://scripts/economy.gd")
const Career = preload("res://scripts/career.gd")
const VERSION := "0.14"
const ControlSettings = preload("res://scripts/control_settings.gd")
const Music = preload("res://scripts/menu_music.gd")
var controls = ControlSettings.new()
var menu_music

var game: EvolutionEconomy
var career: EvolutionCareer
var selected_vehicle: int = 0
var driving_mode := "practice"
var last_notice := ""
var menu_tab := "inicio"
var entry_ticket: Dictionary = {}
var active_race

func _ready() -> void:
    get_window().title = "GT4 Evolution · " + VERSION
    reset()
    if not controls.load_file():
        controls.restore_defaults()
        last_notice = "No se pudo leer la configuración de controles. Se usan los valores por defecto."
    menu_music = Music.new()
    add_child(menu_music)
    menu_music.set_volume(controls.music_volume)
    Input.joy_connection_changed.connect(_controller_connection)

func _controller_connection(device: int, connected: bool) -> void:
    controls.controller.connection_changed(device,connected)

func _input(event: InputEvent) -> void:
    controls.controller.feed(event)

func reset() -> void:
    game = Economy.new()
    game.seed_demo()
    career = Career.new()
    selected_vehicle = 0
    driving_mode = "practice"
    last_notice = ""
    menu_tab = "inicio"
    entry_ticket = {}
    active_race = null

func start_driving(car_id: int, mode: String = "practice") -> bool:
    if not entry_ticket.is_empty() or mode not in ["practice", "race"] or not choose_vehicle(car_id):
        return false
    driving_mode = mode
    return true

func start_drag(car_id: int) -> bool:
    if not entry_ticket.is_empty() or career.has_pending_track_entry() or not choose_vehicle(car_id):
        return false
    driving_mode = "drag"
    return true

func enter_track_event(event_id: String, car_id: int) -> String:
    if not entry_ticket.is_empty():
        return "Ya tenés una inscripción en curso."
    if event_id != "debut":
        return "Este evento todavía utiliza la simulación de carrera."
    var issue := career.begin_track_entry(game, event_id, car_id)
    if not issue.is_empty():
        return issue
    var fee := int(career.event_by_id(event_id)["fee"])
    entry_ticket = {"event_id":event_id, "vehicle_id":car_id, "fee":fee, "started":false}
    selected_vehicle = car_id
    driving_mode = "race"
    return ""

func attach_race(race) -> bool:
    if entry_ticket.is_empty():
        return true # Free exhibition.
    if active_race != null or entry_ticket["vehicle_id"] != selected_vehicle:
        return false
    active_race = race
    entry_ticket["started"] = true
    career.mark_track_started()
    return true

func cancel_unstarted_entry() -> void:
    if entry_ticket.is_empty() or entry_ticket["started"]:
        return
    career.cancel_track_entry(game, true)
    entry_ticket = {}
    driving_mode = "practice"
    selected_vehicle = 0

func finish_track_event(race) -> String:
    if entry_ticket.is_empty() or race == null or race != active_race or race.phase != "finished":
        return "No hay una llegada pendiente de validar."
    var result: Dictionary = career.award_track_result(game, entry_ticket["event_id"], entry_ticket["vehicle_id"], race.report())
    if bool(result["ok"]) or bool(race.entries["player"]["dnf"]):
        career.cancel_track_entry(game)
        entry_ticket = {}
        active_race = null
    return str(result["message"])

func abandon_track_event() -> String:
    if entry_ticket.is_empty():
        return ""
    var fee: int = entry_ticket["fee"]
    career.cancel_track_entry(game)
    entry_ticket = {}
    active_race = null
    return "Abandono sin premio: inscripción de %s consumida." % preload("res://scripts/money.gd").format(fee)

func choose_vehicle(car_id: int) -> bool:
    if not entry_ticket.is_empty() and int(entry_ticket["vehicle_id"]) != car_id:
        return false
    var car: Dictionary = game.find_car(car_id)
    if car.is_empty() or car.get("owner", "") != "player" or not game.eligible(car):
        return false
    selected_vehicle = car_id
    return true
