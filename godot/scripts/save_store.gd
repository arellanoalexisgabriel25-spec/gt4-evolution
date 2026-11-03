extends RefCounted

const Economy = preload("res://scripts/economy.gd")
const Career = preload("res://scripts/career.gd")

static func _numbers(value):
    # Godot's JSON parser returns every number as float. Restore exact integral
    # values before strict schema validation; fractional/unsafe numbers stay floats.
    if typeof(value) == TYPE_FLOAT and is_finite(value) and absf(value) <= 9007199254740991.0 and value == floorf(value):
        return int(value)
    if typeof(value) == TYPE_DICTIONARY:
        var result := {}
        for key in value:
            result[key] = _numbers(value[key])
        return result
    if typeof(value) == TYPE_ARRAY:
        var result: Array = []
        for item in value:
            result.append(_numbers(item))
        return result
    return value

static func encode(game, career) -> String:
    return JSON.stringify({"save_version":2, "economy":game.to_dict(), "career":career.to_dict()}, "", true, true)

static func decode(text: String) -> Dictionary:
    var parser := JSON.new()
    if parser.parse(text) != OK:
        return {"error":"Partida inválida: JSON dañado."}
    var data = _numbers(parser.data)
    if typeof(data) != TYPE_DICTIONARY:
        return {"error":"Partida inválida: no es un objeto JSON."}
    if data.has("save_version") and data["save_version"] != 2:
        return {"error":"Versión de partida no compatible."}
    var economy_data = data.get("economy", data)
    var career_data = data.get("career", Career.new().to_dict())
    if typeof(economy_data) != TYPE_DICTIONARY or typeof(career_data) != TYPE_DICTIONARY:
        return {"error":"Partida inválida: faltan los estados del juego."}
    var game = Economy.new()
    var career = Career.new()
    if not game.from_dict(economy_data) or not career.from_dict(career_data):
        return {"error":"Partida inválida, no se realizaron cambios."}
    return {"error":"", "game":game, "career":career}

static func save_file(path: String, game, career) -> Error:
    if career.has_pending_track_entry():
        return ERR_BUSY # In-flight admissions are not part of the garage save format.
    var text := encode(game, career)
    if not str(decode(text).get("error", "")).is_empty():
        return ERR_INVALID_DATA
    var temporary := path + ".tmp"
    var file := FileAccess.open(temporary, FileAccess.WRITE)
    if file == null:
        return FileAccess.get_open_error()
    file.store_string(text)
    file.flush()
    var error := file.get_error()
    file.close()
    if error != OK:
        DirAccess.remove_absolute(temporary)
        return error
    error = DirAccess.rename_absolute(temporary, path)
    if error != OK:
        DirAccess.remove_absolute(temporary)
    return error

static func load_file(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {"error":"No se pudo abrir la partida."}
    var text := file.get_as_text()
    file.close()
    return decode(text)
