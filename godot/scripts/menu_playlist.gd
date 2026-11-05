extends RefCounted

# Only the selected stream is loaded. Audio never consumes the race RNG.
const SONGS := [
    {"id":"perra", "title":"Lezcano Alan — PERRA #Ritmomanijero · Prod Sketchy", "path":"res://assets/audio/menu_track.mp3"},
    {"id":"fumo_y_manejo", "title":"Fumo y Manejo"},
    {"id":"butakera", "title":"Butakera"},
    {"id":"turreo_sessions_5", "title":"Kaleb Di Masi · DJ Tao — Turreo Sessions #5"},
    {"id":"l_gante_rkt", "title":"L-Gante · Papu DJ — L-Gante RKT"},
    {"id":"matatan", "title":"Kaleb Di Masi — Matatan"},
    {"id":"parte_y_choke", "title":"Parte & Choke"},
    {"id":"tapa_la_cara", "title":"Ponte Perro — Tapa la Cara"},
    {"id":"pipupipu", "title":"Pipupipu"},
    {"id":"gafita_y_chomba", "title":"Ponte Perro · Kaleb Di Masi — Gafita y Chomba"},
    {"id":"rally_funk", "title":"Rally Funk"},
    {"id":"rkt_turro", "title":"RKT Turro"},
    {"id":"tu_turrito", "title":"Tu Turrito"},
]

static func index_of(id: String) -> int:
    for i in range(SONGS.size()):
        if SONGS[i].id==id: return i
    return -1

static func path_at(index: int) -> String:
    if index<0 or index>=SONGS.size(): return ""
    return str(SONGS[index].get("path","res://assets/audio/playlist/"+str(SONGS[index].id)+".ogg"))
