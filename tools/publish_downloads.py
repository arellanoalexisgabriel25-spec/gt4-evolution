"""Publish checked release ZIPs on an immutable, separate GitHub download branch."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import zipfile
from urllib.parse import urlsplit

from package_game import ROOT, VERSION
from release_artifacts import project_files, source_snapshot, validate_export


def git(*args, data=None):
    return subprocess.check_output(["git", *args], cwd=ROOT, input=data).decode().strip()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--artifacts", type=Path, required=True)
    parser.add_argument("--screenshots", type=Path, help="Directory of checked 1280x720 presentation PNGs")
    parser.add_argument("--push", action="store_true")
    args = parser.parse_args()
    if git("status", "--porcelain"):
        raise SystemExit("Commit development changes before publishing packages.")
    if not re.fullmatch(r"[0-9]+(?:\.[0-9]+)*", VERSION):
        raise SystemExit("Invalid release version.")
    remote = git("remote", "get-url", "origin")
    if remote.startswith("git@github.com:"):
        identity = remote.split(":", 1)[1]
    else:
        parsed = urlsplit(remote)
        if parsed.hostname != "github.com":
            raise SystemExit("This publisher requires a GitHub origin.")
        identity = parsed.path.lstrip("/")
    identity = identity.removesuffix(".git")
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", identity):
        raise SystemExit("Origin repository identity is ambiguous.")
    branch = f"downloads/v{VERSION}"
    ref = f"refs/heads/{branch}"
    names = [f"GT4-Evolution-{VERSION}-{kind}.zip" for kind in ["Windows", "Proyecto"]]
    files = []
    for name in names:
        path = args.artifacts / name
        if path.stat().st_size >= 100 * 1024 * 1024:
            raise SystemExit(f"Package exceeds GitHub's 100 MiB Git file limit: {name}")
        with path.open("rb") as handle:
            digest = hashlib.file_digest(handle, "sha256").hexdigest()
        checksum = args.artifacts / (name + ".sha256")
        if checksum.read_text().split() != [digest, name]:
            raise SystemExit(f"Package checksum mismatch: {name}")
        files.extend([(name, path), (checksum.name, checksum)])
    source_commit = git("rev-parse", "HEAD")
    sources = source_snapshot(ROOT / "godot")
    for name in names:
        with zipfile.ZipFile(args.artifacts / name) as archive:
            if archive.testzip() is not None:
                raise SystemExit(f"Corrupt package: {name}")
            if name.endswith("-Proyecto.zip"):
                for source in project_files(ROOT / "godot"):
                    key = "juego/" + source.relative_to(ROOT / "godot").as_posix()
                    if archive.read(key) != source.read_bytes():
                        raise SystemExit(f"Package differs from committed source: {key}")
            else:
                manifest = json.loads(archive.read("MANIFIESTO.json"))
                if manifest.get("game_version") != VERSION or manifest.get("source_commit") != source_commit:
                    raise SystemExit("Windows export was built from another version/commit")
                if manifest.get("same_pck_linux_smoke") != "passed":
                    raise SystemExit("The exported PCK has not passed its release-runtime smoke test")
                if manifest.get("same_pck_physical_test") != "passed":
                    raise SystemExit("The exported PCK has not passed its full-fleet and physical-duel checks")
                validate_export(manifest, archive.read("GT4Evolution.exe"), archive.read("GT4Evolution.pck"), sources)
    base = f"https://github.com/{identity}/raw/refs/heads/{branch}"
    readme = f"""# GT4 Evolution {VERSION} · Descargas

- [Descargar juego para Windows]({base}/{names[0]})
- [Descargar proyecto para Godot]({base}/{names[1]})

Las ruedas conservan sus formas al girar; la pista tiene asfalto y barreras detalladas.
El concesionario ofrece filtros y vista 3D; TUNING permite instalar turbo de calle.
Elegí **DUELO ¼ / PREPARADO** para correr con mejoras y escuchar el turbo sintetizado.

Extraé TODO el ZIP Windows y abrí **GT4Evolution.exe** o **JUGAR.cmd**.
La ventana inicia en **1920×1080** y se puede redimensionar. La interfaz se dibuja
con fuentes vectoriales y los modelos usan filtrado anisotrópico; las texturas
conservan la resolución de sus archivos de origen. Si el auto sale de la zona
de calentamiento, el largador llama a alinear: frená y preparate para el verde.
Es una exportación independiente; no requiere instalar Godot ni importar el proyecto.
Conservá **GT4Evolution.pck** junto al ejecutable. El ZIP Proyecto conserva las fuentes.
**GARAJE → DUELO ¼ DE MILLA / FÁBRICA** corre contra otro auto físico.
Elegí piloto y clase (Clase 1: piso ET 18,00 s) o LIBRE, sin piso.
Clases de ¼ según el art. 21 del texto aportado; caída por ET bajo el piso.
La reacción cuenta para llegar primero. Un falso individual concede al rival
la excepción del art. 12 aunque su ET caiga. Exhibición sin inscripción ni premios.
Fábrica conserva salud del garaje y excluye preparaciones; «serie» oficial tiene
otro alcance. La práctica individual y sus marcas anteriores siguen disponibles.
La versión 0.25 corrige la retención de embrague/freno durante el llamado.
Reversa permite regresar físicamente al haz; el rival alinea independientemente.
Ctrl + RePág/AvPág son alternativas de embrague/cambios con W sostenida.
F3 muestra los pedales recibidos y aplicados. Se conserva la sincronización finita, embrague con calor/desgaste,
reversa real y rechazo de cambios. W+C+E/Q funciona sin levantar el acelerador.
En manual detenido: C+Q desde N selecciona R; C+E primera. Al verde liberá
embrague y frenos. El HUD indica qué control retiene el auto.
Suspensión de cabeceo y diferencial abierto/LSD/bloqueado configurables.
AJUSTES ofrece embrague automático, semiautomática y rev-matching opcionales;
manual sin rev-match es el valor inicial. Una mala reducción puede romper motor.
Se conserva la gravedad 9,81 m/s², pendientes, viento y frenos térmicos.
Se suman Yaris sedán, Ka 3p, 208, Polo Classic, Virtus, Onix y Corolla Cross.
El Cross incorpora una CVT original aproximada: E/Q recorre R/N/D detenido;
freno sostenido al alinear y soltarlo al verde. LT siempre frena en CVT.
Las marcas anteriores se preservan como históricas frente a esta revisión.
No se certifica hiperrealismo completo ni prestaciones de fábrica.
El ¼ de milla transcurre de noche con alumbrado cálido e instrumentos analógicos.
Corsa 5p, Amarok, Ranger cabina simple, EcoSport, Corolla y Palio 5p se suman
con modelos optimizados y fichas mecánicas provisionales.
La interfaz adopta fondos oscuros, azul acero y números monoespaciados según
la guía GT4_UI_System aportada. El 147 Vivace usa la referencia 1.4 BIO 1997:
63 CV, 10,4 kgfm, 807 kg más 75 kg de piloto; otros parámetros siguen estimados.
Las marcas anteriores se conservan como históricas y no se mezclan con la
nueva ficha. Ver TECHNICAL-REPORT-REVIEW-0.21.md y STOCK-BENCHMARK-0.21.md.
Se incluyen 125, Duna, Cronos, Siena, Punto, Regatta y 500 Sport a los seis
modelos anteriores. El garaje permite elegir un modelo rival distinto.
El 500 utiliza 100 CV y caja de seis marchas; su estética Abarth es provisional.
El 133 tiene tracción trasera y los 128 delantera, con perfiles diferenciados.
El contacto distingue superficies, apoyo y ruedas sin suelo; el agarre respeta
la capacidad actual del piso y el frenado registra la energía disipada.
147 Vivace y Uno Fire conservan derivados optimizados de los modelos aportados,
con texturas derivadas de 1024², mipmaps y ruedas animadas. El Uno suministrado tiene cinco puertas,
referencia visual provisional de la variante de tres puertas del catálogo.
Los veintiséis modelos aportados usan derivados optimizados; los originales quedan fuera del paquete. Las fichas distinguen datos aportados
y parámetros estimados; la calibración de prestaciones sigue pendiente.
Ver STOCK-SOURCES.md. En Inicio podés elegir todos los modelos; en garaje,
VER MODELO cambia la vista.
El taller ofrece calle, deportivos o slick. Los impactos dejan daño mecánico
persistente; recuperar no repara. Ver RELEASE-0.25.md, MANUAL-TRANSMISSION-0.24.md y REGULATIONS-REFERENCE.md.

Comprá un auto y abrí **GARAJE → DUELO ¼ DE MILLA / FÁBRICA**.
Hay 25 s de calentamiento delante de línea, luego azul y 30 s de preparación.
Son tiempos de juego; el art.11 define las señales, no esas duraciones.
C+E engrana primera; en FWD, ráfagas de W+H calientan con patinamiento real.
El auto puede avanzar: C+Espacio frena. Zona 2,5–35 m delante de línea.
El asistente alinea al llamado salvo si elegís R; manual conserva tus pedales.
Audio de motor por capas a 44,1 kHz con fuentes espaciales y perfiles diferenciados.
AJUSTES ofrece MSAA apagado/2x/4x. Taos está en galería sin ficha de carreras.
Al perder foco pausa; no se reanuda sin una orden nueva.
Primera+C y ambos listos activan automáticamente el árbol; Enter no lo inicia.
Esperá el verde y soltá C para largar. C+E/Q cambia sin obligar a soltar W.
El HUD de pasada es compacto; la pausa muestra telemetría completa.
R prepara otra pasada. Mando: L3 freno de mano, Inicio/Select pausa.
La práctica no cobra ni da premios en pesos; sí registra uso y desgaste.
Volvé al garaje y presioná GUARDAR para conservar marcas y progreso.
AJUSTES permite reasignar las teclas. El circuito del club sigue disponible.
Los importes están en pesos argentinos. Se incluye la música de menú aportada
por el usuario y autorizada para redistribución: 13 temas, selección, anterior/siguiente,
aleatorio y volumen en AJUSTES.
Mando: stick/cruceta navega, A confirma, B vuelve, LB/RB cambia pestaña.
Select/Back abre la pausa en pista; embrague analógico LT/L2 opcional.

El paquete incluye LEEME.txt con controles y limitaciones, MANIFIESTO.json con
hashes de fuentes/exportación y DIAGNOSTICO.cmd para registrar fallos de arranque. Windows y los mandos físicos requieren
prueba en esos equipos; la validación automatizada se realiza en Linux.
Las licencias se incluyen. No se distribuyen recursos comerciales de GT4.

Código: [{source_commit[:7]}](https://github.com/{identity}/commit/{source_commit}).
Esta rama contiene únicamente distribución y no se integra en main.
Los archivos .sha256 permiten verificar los ZIP.
"""
    if args.screenshots:
        shots = (ROOT / "tools/presentation_shots.txt").read_text().splitlines()
        for shot in shots:
            if not re.fullmatch(r"[a-z0-9-]+",shot): raise SystemExit("Invalid screenshot name")
            path = args.screenshots / (shot + ".png")
            header = path.read_bytes()[:24]
            if (path.stat().st_size > 5 * 1024 * 1024 or header[:8] != b"\x89PNG\r\n\x1a\n"
                    or header[12:16] != b"IHDR" or header[16:24] != b"\x00\x00\x05\x00\x00\x00\x02\xd0"):
                raise SystemExit(f"Invalid presentation capture (expected 1280x720 PNG): {shot}")
            files.append(("captura-" + path.name, path))
        readme += f"\n## Presentación {VERSION}\n\n"
        readme += "Capturas reales del juego en Linux con OpenGL por software. No son renders conceptuales.\n\n"
        readme += "Tab / RB cambia entre seguimiento, cercana, capó y paragolpes; Shift / R3 permite mirar atrás en picadas.\n"
        readme += "AJUSTES conserva la cámara inicial y permite suavizar la dirección del teclado.\n\n"
        for title, shot in [("Corolla Cross CVT contra Virtus manual", "69-cvt-driving"), ("Telemetría de fuerzas y temperatura", "71-physics-telemetry"), ("Resultado medido CVT", "70-cvt-result"), ("Yaris sedán", "61-yaris-showroom"), ("Ka 3 puertas", "62-ka-showroom"), ("208", "63-208-showroom"), ("Polo Classic", "64-polo-showroom"), ("Virtus", "65-virtus-showroom"), ("Onix", "66-onix-showroom"), ("Corolla Cross", "67-cross-showroom"), ("Picada nocturna / Amarok contra Corsa", "59-night-pickup-driving"), ("Resultado físico nocturno", "60-night-pickup-result"), ("Lista de trece canciones", "57-playlist-settings"), ("Corsa cinco puertas", "51-corsa-showroom"), ("Amarok", "52-amarok-showroom"), ("Ranger cabina simple", "53-ranger-showroom"), ("EcoSport", "54-ecosport-showroom"), ("Corolla", "55-corolla-showroom"), ("Palio cinco puertas", "56-palio-showroom"), ("Inicio / Línea visual aportada", "01-home"), ("147 / Referencia técnica parcial", "47-reference-147-garage"), ("Tuning / Tema compartido", "48-tuning-system"), ("Carrera / Tema compartido", "49-career-system"), ("Movimientos / Tema compartido", "50-transactions-system"), ("HUD / Números monoespaciados", "42-mixed-duel-driving"), ("Calentamiento real", "44-burnout-preparation"), ("Luz azul y llamado del largador", "45-starter-call"), ("Telemetría al pausar", "46-paused-telemetry"), ("125 / Modelo adaptado", "34-125-showroom"), ("Duna / Modelo adaptado", "35-duna-showroom"), ("Cronos / Modelo adaptado", "36-cronos-showroom"), ("Siena / Modelo adaptado", "37-siena-showroom"), ("Punto / Modelo adaptado", "38-punto-showroom"), ("Regatta / Modelo adaptado", "39-regatta-showroom"), ("500 Sport / Carrocería Abarth provisional", "40-500-showroom"), ("500 Sport contra 133", "42-mixed-duel-driving"), ("Resultado entre modelos distintos", "43-mixed-duel-result"), ("Fiat 128 Súper Europa / Modelo aportado", "28-128-super-showroom"), ("Fiat 133 / Modelo aportado", "29-133-showroom"), ("Fiat 128 / Modelo aportado", "30-128-standard-showroom"), ("133 / Duelo de tracción trasera", "31-133-duel-staging"), ("133 / Carrera física", "32-133-duel-driving"), ("133 / Dos tickets medidos", "33-133-duel-result"), ("Dos autos de fábrica / Semáforo común", "25-duel-staging"), ("Carrera física contra un rival", "26-duel-driving"), ("Resultado por reacción más ET", "27-duel-result"), ("Gol Power / Modelo aportado", "20-gol-showroom"), ("Gol en una pasada manual real", "24-gol-driving"), ("Impacto real / Daños mecánicos", "23-impact-damage"), ("Taller / Compuestos de neumáticos", "21-tire-workshop"), ("147 Vivace / Modelo aportado", "18-147-showroom"), ("Uno Fire / Modelo aportado", "19-uno-showroom"), ("Inicio y autos insignia", "01-home"), ("Música, mando y ayudas", "04-settings"), ("Ticket de llegada real", "15-drag-ticket"), ("Pausa con mando", "17-controller-pause")]:
            readme += f"### {title}\n\n![{title}](captura-{shot}.png)\n\n"
    blob = git("hash-object", "-w", "--stdin", data=readme.encode())
    rows = [f"100644 blob {blob}\tREADME.md\n"]
    for name, path in files:
        blob = git("hash-object", "-w", str(path.resolve()))
        rows.append(f"100644 blob {blob}\t{name}\n")
    tree = git("mktree", data="".join(rows).encode())
    existing = subprocess.run(["git", "rev-parse", "--verify", ref], cwd=ROOT, capture_output=True, text=True)
    if existing.returncode == 0:
        commit = existing.stdout.strip()
        if git("rev-parse", commit + "^{tree}") != tree:
            raise SystemExit("Release exists with different contents; use a new version.")
    else:
        # Link distribution snapshots for efficient deltas of the unchanged engine.
        previous = []
        current = tuple(map(int, VERSION.split(".")))
        for candidate in git("for-each-ref", "--format=%(refname)", "refs/heads/downloads/").splitlines():
            suffix = candidate.rsplit("/v", 1)[-1]
            if re.fullmatch(r"[0-9]+(?:\.[0-9]+)*", suffix):
                version = tuple(map(int, suffix.split(".")))
                if version < current:
                    previous.append((version, candidate))
        parents = ["-p", max(previous)[1]] if previous else []
        commit = git("commit-tree", tree, *parents, "-m", f"Publish GT4 Evolution {VERSION} download packages")
        git("update-ref", ref, commit, "0" * 40)
    if args.push:
        advertised = git("ls-remote", "origin", ref)
        if advertised and advertised.split()[0] != commit:
            raise SystemExit("Remote release differs; refusing to overwrite it.")
        subprocess.run(["git", "push", "origin", f"{ref}:{ref}"], cwd=ROOT, check=True)
    print(f"Download branch: {branch} ({commit})")
    for name in names:
        print(f"{base}/{name}")


if __name__ == "__main__":
    main()
