"""Package source and a real Godot Windows export using verified official templates."""
import argparse
import re
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.29"
README = """GT4 EVOLUTION — PROTOTIPO 0.29 / RUEDAS, PISTA Y PREPARACIÓN

Novedades: ruedas corregidas, asfalto detallado, concesionario con vista 3D y
turbo de calle disponible en TUNING. Para correr con mejoras seleccioná
GARAJE → DUELO ¼ / PREPARADO; FÁBRICA conserva el vehículo original.
El sonido de turbo es síntesis y el kit usa parámetros estimados.

WINDOWS: extraé TODO el ZIP y abrí GT4Evolution.exe o JUGAR.cmd.
La ventana inicia a 1920×1080; podés redimensionarla. La interfaz es vectorial,
y los modelos usan filtrado anisotrópico; las texturas conservan su resolución original.
Si avanzás fuera de la zona de calentamiento, el largador llama a alinear:
frená, esperá la alineación y soltá freno y embrague al verde.
Es un juego exportado independiente: no necesita Godot instalado ni importar el
proyecto al iniciar. Conservá GT4Evolution.pck junto al ejecutable.
El ZIP Proyecto contiene las fuentes: abrí juego/project.godot con Godot 4.6.3.

Gravedad unificada 9,81 m/s², contacto sobre pendientes, viento/densidad del aire
y frenos con temperatura y pérdida progresiva de eficacia. Se conservan los
récords anteriores como históricos; la nueva dinámica tiene su propia serie.
Yaris sedán, Ka 3p, 208, Polo Classic, Virtus, Onix y Corolla Cross se suman.
En Cross: CVT aproximada, selector R/N/D con Q/E estando detenido, freno sostenido
al alinear y soltalo al verde. No requiere embrague; LT siempre frena.
Ver MANUAL-TRANSMISSION-0.24.md y CALIBRATION-0.24.md para ecuaciones y límites.
Caja manual con sincronización finita, reversa, calor y desgaste del embrague,
sobrerégimen mecánico y rechazo de cambios. W, S y C son pedales independientes.
Suspensión de cabeceo y diferencial abierto/LSD/bloqueado configurables.
AJUSTES permite embrague automático, semiautomática y rev-matching opcionales;
manual total y sin rev-match por defecto. Las ayudas no salvan una mala reducción.

¼ de milla nocturno con alumbrado cálido, faros y dos instrumentos analógicos.
Corsa 5p, Amarok, Ranger cabina simple, EcoSport, Corolla y Palio 5p amplían
la flota a veintiséis modelos aportados. Sus variantes mecánicas son provisionales.

Interfaz oscura con azul acero y números monoespaciados, según GT4_UI_System.
El 147 Vivace representa la referencia 1.4 BIO 1997: 63 CV, 10,4 kgfm y 807 kg antes de
sumar 75 kg de piloto. Régimen de potencia/caja siguen estimados. Las marcas de
la ficha anterior se conservan como históricas; la nueva ficha tiene su propio PB.
Ver TECHNICAL-REPORT-REVIEW-0.21.md y STOCK-BENCHMARK-0.21.md.

Se incluyen 125, Duna, Cronos, Siena, Punto, Regatta y 500 Sport a los seis modelos
anteriores. Inicio permite elegirlos y el garaje permite seleccionar el auto rival.
El 500 usa la ficha Sport: 100 CV, 13,1 kgfm y seis marchas; su carrocería aportada
tiene estética Abarth provisional. No se le asignó potencia de Abarth.
Los derivados optimizados usan texturas derivadas de las aportadas; la colisión
sigue siendo independiente de las mallas visuales. El 133 usa tracción trasera; los 128,
delantera. Los parámetros sin ficha completa siguen siendo estimaciones.
Se conservan 147 Vivace, Uno Fire y Gol Power. El Uno recibido tiene cinco puertas,
referencia visual provisional de la variante de tres puertas del catálogo.

El nuevo contacto diferencia neumáticos apoyados, superficies y ruedas sin suelo.
La fuerza se limita al agarre de cada superficie. Calor y desgaste de frenos se
calculan a partir de la energía disipada por las ruedas. La conducción todavía es
una aproximación: no hay simulación completa de suspensión o deformación visual.

Comprá un auto en CONCESIONARIO y abrí GARAJE → DUELO ¼ DE MILLA / FÁBRICA.
Elegí rival y clase: por defecto Clase 1 / piso 18,00 s; LIBRE no aplica piso.
Los pisos de ¼ provienen del art. 21 del reglamento aportado. Caer bajo el piso
es descalificación por ET; la reacción cuenta para llegar primero (RT + ET).
El art. 12 permite ganar al rival de un falso individual aunque su ET caiga.
Exhibición sin inscripción, premios ni campeonato. FÁBRICA excluye preparaciones
y conserva la salud de tu unidad. La categoría oficial Serie tiene otro alcance.
¼ DE MILLA / MANUAL mantiene la práctica individual con mejoras anteriores.

PREPARACIÓN: hay 25 s de calentamiento autorizado delante de la línea y luego
30 s para prepararse. Son duraciones del juego, no tiempos oficiales publicados.
Rojo intermitente/amarillas fondo: calentar; azul: fin y llamado a alinear (art.11).
El asistente alinea antes de cronometrar si no seleccionás R. La reversa permite
volver físicamente; en manual se respetan tus pedales durante la alineación. Se conservan calor, desgaste y uso. Primera+embrague
sostenidos y ambos autos alineados activan el árbol automáticamente. Enter no inicia.

CONTROLES: C embrague, E sube marcha, Q baja, W acelera, S/Espacio frena.
Para calentar un FWD: C+E primera, prepará RPM con C; soltá C en ráfagas W+H.
H es freno de mano trasero: el auto puede avanzar; usá C+Espacio para detenerlo.
Zona de calentamiento 2,5–35 m delante de la línea; excederla cancela esta preparación.
No hace falta calentar todo el tiempo: demasiado calor y patinamiento desgastan.
Al llamado, mantené primera+C y prepará RPM; esperá verde y soltá C para largar.
Para cambiar, C+E o C+Q; podés mantener W, con limitador y desgaste normales.
REVERSA: detenido, C+Q desde N. Desde primera: bajar a N, esperar el selector,
bajar otra vez a R. Al verde liberá C/freno de mano; mantener C impide transmitir par.
Esperá la sincronización y controlá el acople: reducciones excesivas dañan el motor.
La palanca selecciona al instante; la transmisión entrega par al terminar el acople.
Alternativa de teclado: Ctrl embrague, RePág sube y AvPág baja; funcionan con W
mantenida y respetan las teclas reasignadas. F3 muestra pedales recibidos/aplicados.
En manual, después del calentamiento los pedales siguen bajo tu control. Podés
seleccionar R para volver físicamente al haz; el rival alinea independientemente.
Al perder foco, el juego pausa; P/Inicio continúa deliberadamente.
Audio de motor original por capas, 44,1 kHz, con fuente espacial por vehículo.
Perfiles de síntesis diferenciados; no son grabaciones certificadas de cada modelo.
AJUSTES incluye antialiasing apagado/2x/4x. Equilibrada usa 2x por defecto.
Volkswagen Taos se incorpora sólo a la galería: no tiene una caja manual ficticia
ni un perfil de carreras hasta identificar su versión y transmisión automática.
R repite conservando uso/calor; P pausa, Esc garaje, Tab cámara. La telemetría
completa y la ayuda aparecen al pausar; durante la pasada queda instrumental compacto.
Mando: RT acelera, LT/B frena, LB embrague, A sube, Y baja, L3 freno de mano,
X repite, RB cámara. Inicio/Select pausa; embrague analógico LT/L2 opcional.
AJUSTES reasigna teclas, también H. Menús: stick/cruceta navega, A confirma,
B vuelve, LB/RB cambia pestaña.

TALLER repara y cambia neumáticos. Recuperar no repara. Los importes están en
pesos argentinos (ARS); cada unidad contable histórica representa $ 1.000 ARS.
Volvé al garaje y presioná GUARDAR para conservar salud, marcas y progreso.
Las partidas previas conservan sus unidades; las ofertas nuevas se añaden sin
cambiar IDs existentes ni generar créditos.

Uno Fire 1.3 8V 2014: curva anclada en 68 CV/5250 RPM y 11,3 kgfm/2250 RPM,
según la transcripción de fabricante aportada. 13,2 s de 0–100 y 158 km/h son
referencias de contraste, no aceleraciones impuestas por el juego.
La pista original de 402,336 m se inspira en el ambiente del autódromo Gálvez.
Los modos anteriores siguen disponibles; los eventos simulados se identifican.
Música: trece temas aportados con autorización expresa de redistribución.
AJUSTES permite elegir tema, anterior/siguiente, aleatorio y volumen.
La música se desvanece en pista y retoma en los menús. No está cubierta por MIT.

Ver juego/RELEASE-0.29.md en el ZIP Proyecto y documentacion/ en Windows para el
alcance exacto y resultados de validación. El entorno valida Linux y el mismo PCK;
Windows y mando físico requieren prueba en esos equipos. Si no inicia, ejecutá
DIAGNOSTICO.cmd y compartí juego.log. Licencias incluidas. No se distribuyen
recursos comerciales de GT4.
"""

LAUNCH = r'''@echo off
setlocal
cd /d "%~dp0"
start "" "%~dp0GT4Evolution.exe"
'''
DIAGNOSTIC = r'''@echo off
setlocal
cd /d "%~dp0"
start "" /wait "%~dp0GT4Evolution.exe" --log-file "%~dp0juego.log"
echo Diagnostico guardado en juego.log.
pause
'''

from release_artifacts import (ENGINE_VERSION, TEMPLATE_ARCHIVE, TEMPLATE_ARCHIVE_SHA512,
                               digest_bytes, digest_file, project_files, source_snapshot,
                               pck_snapshot, validate_export)
import json
import os
import shutil
import subprocess
import tempfile


def write_common(archive):
    archive.write(ROOT / "LICENSE", "LICENSE")
    archive.writestr("LEEME.txt", README)


def write_project(archive):
    for path in project_files(ROOT / "godot"):
        archive.write(path, Path("juego") / path.relative_to(ROOT / "godot"))
    write_common(archive)


def verified_templates(archive_path, checksums, output):
    if archive_path.name != TEMPLATE_ARCHIVE:
        raise ValueError("Expected the official Godot 4.6.3 standard export templates")
    expected = next(line.split()[0] for line in checksums.read_text().splitlines()
                    if line.split()[-1] == archive_path.name)
    if expected != TEMPLATE_ARCHIVE_SHA512 or digest_file(archive_path, "sha512") != expected:
        raise ValueError("Complete official export-template SHA-512 mismatch")
    result = {}
    with zipfile.ZipFile(archive_path) as templates:
        if templates.read("templates/version.txt").strip() != b"4.6.3.stable":
            raise ValueError("Export template version differs from engine")
        for name in ["windows_release_x86_64.exe", "linux_release.x86_64"]:
            target = output / name
            target.write_bytes(templates.read("templates/" + name))
            result[name] = target
    return result


def run_engine(command, log, environment):
    completed = subprocess.run(command, capture_output=True, text=True, env=environment, timeout=180)
    output = completed.stdout + completed.stderr
    log.write_text(output)
    if completed.returncode or re.search(r"^SCRIPT ERROR:|^ERROR:", output, re.MULTILINE):
        raise RuntimeError("Godot import/export failed; inspect " + str(log))
    return output


def export_windows(args, sources):
    evidence = args.output / "export-validation"
    evidence.mkdir(exist_ok=True)
    binary = shutil.which(args.godot_bin)
    if binary is None:
        raise ValueError("Godot executable not found")
    version = subprocess.check_output([binary, "--version"], text=True).strip()
    if not version.startswith("4.6.3.stable."):
        raise ValueError("Export requires Godot 4.6.3 stable")
    with tempfile.TemporaryDirectory(prefix="gt4-export-") as temp:
        base = Path(temp)
        templates = verified_templates(args.export_templates, args.checksums, base)
        project = base / "game"
        project.mkdir()
        for path in project_files(ROOT / "godot"):
            target = project / path.relative_to(ROOT / "godot")
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, target)
        if source_snapshot(project) != sources:
            raise ValueError("Export staging differs from source snapshot")
        preset = (project / "export_presets.cfg").read_text()
        template_path = str(templates["windows_release_x86_64.exe"])
        preset = preset.replace('custom_template/debug=""', 'custom_template/debug=' + json.dumps(template_path))
        preset = preset.replace('custom_template/release=""', 'custom_template/release=' + json.dumps(template_path))
        (project / "export_presets.cfg").write_text(preset)
        environment = os.environ.copy()
        for variable, name in [("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache")]:
            target = base / name
            target.mkdir()
            environment[variable] = str(target)
        run_engine([binary, "--headless", "--path", str(project), "--editor", "--import"],
                   evidence / "import.log", environment)
        executable = evidence / "GT4Evolution.exe"
        run_engine([binary, "--headless", "--path", str(project), "--export-release", "Windows Desktop", str(executable)],
                   evidence / "export-windows.log", environment)
        pack = executable.with_suffix(".pck")
        manifest = {
            "schema": 1, "game_version": VERSION, "engine_version": ENGINE_VERSION,
            "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
            "sources": sources,
            "template_archive_sha512": TEMPLATE_ARCHIVE_SHA512,
            "windows_template_sha256": digest_file(templates["windows_release_x86_64.exe"]),
            "windows_executable_sha256": digest_file(executable),
            "pack_sha256": digest_file(pack),
            "pack_entries": pck_snapshot(pack.read_bytes()),
            "script_export_mode": "text_byte_exact",
            "windows_executed": False,
        }
        validate_export(manifest, executable.read_bytes(), pack.read_bytes(), sources)
        # Validate that the Windows-target pack also loads with the official
        # Linux release runtime of exactly the same version. This is not a test
        # of Windows OS integration or drivers.
        # Official release templates disable --main-pack overrides. Matching
        # the executable/PCK basenames exercises their normal shipping path.
        linux = evidence / "GT4Evolution.x86_64"
        shutil.copy2(templates["linux_release.x86_64"], linux)
        linux.chmod(0o700)
        run_engine([str(linux), "--headless", "--quit-after", "120"],
                   evidence / "same-pck-linux-smoke.log", environment)
        manifest["same_pck_linux_smoke"] = "passed"
        output = run_engine([binary, "--headless", "--main-pack", str(pack), "--fixed-fps", "60",
                             "--audio-driver", "Dummy", "--script", str(ROOT / "tools/validate_export.gd")],
                            evidence / "same-pck-physical-test.log", environment)
        if not re.search(r"^PASS: \d+ exported PCK assertions", output, re.MULTILINE):
            raise RuntimeError("The exported-PCK fixture did not complete")
        manifest["same_pck_physical_test"] = "passed"
        if source_snapshot(ROOT / "godot") != sources:
            raise ValueError("Source changed during export; rebuild from the final source")
        (evidence / "MANIFIESTO.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
        return evidence, manifest


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--export-templates", type=Path, help="Official complete Godot 4.6.3 standard .tpz")
    parser.add_argument("--checksums", type=Path)
    parser.add_argument("--engine-license", type=Path)
    parser.add_argument("--engine-copyright", type=Path, help="Godot 4.6.3 COPYRIGHT.txt with bundled-library notices")
    parser.add_argument("--godot-bin", default=os.environ.get("GODOT_BIN", "godot"))
    args = parser.parse_args()
    args.output = args.output.resolve()
    session_version = re.search(r'^const VERSION := "([^"]+)"', (ROOT / "godot/scripts/session.gd").read_text(), re.MULTILINE)
    if session_version is None or session_version.group(1) != VERSION:
        raise ValueError("Game and package versions differ")
    args.output.mkdir(parents=True, exist_ok=True)
    if args.export_templates and (not args.checksums or not args.engine_license or not args.engine_copyright):
        parser.error("--checksums, --engine-license and --engine-copyright are required with --export-templates")
    sources = source_snapshot(ROOT / "godot")
    if args.export_templates:
        evidence, manifest = export_windows(args, sources)
        windows = args.output / f"GT4-Evolution-{VERSION}-Windows.zip"
        with zipfile.ZipFile(windows, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            write_common(archive)
            for name in ["GT4Evolution.exe", "GT4Evolution.pck", "MANIFIESTO.json"]:
                archive.write(evidence / name, name)
            archive.writestr("JUGAR.cmd", LAUNCH.replace("\n", "\r\n"))
            archive.writestr("DIAGNOSTICO.cmd", DIAGNOSTIC.replace("\n", "\r\n"))
            archive.write(args.checksums, "Godot-SHA512-SUMS.txt")
            archive.write(args.engine_license, "Godot-LICENSE.txt")
            archive.write(args.engine_copyright, "Godot-COPYRIGHT.txt")
            for path in project_files(ROOT / "godot"):
                if path.suffix == ".md" or (path.suffix == ".txt" and "assets" in path.parts):
                    archive.write(path, "documentacion/" + path.relative_to(ROOT / "godot").as_posix())
    source = args.output / f"GT4-Evolution-{VERSION}-Proyecto.zip"
    with zipfile.ZipFile(source, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        write_project(archive)
    for package in sorted(args.output.glob(f"GT4-Evolution-{VERSION}-*.zip")):
        if package.stat().st_size >= 100 * 1024 * 1024:
            raise ValueError("Package exceeds GitHub's 100 MiB Git file limit: " + package.name)
        package.with_suffix(".zip.sha256").write_text(f"{digest_file(package)}  {package.name}\n")
        print(f"{package.name}: {package.stat().st_size:,} bytes")


if __name__ == "__main__":
    main()
