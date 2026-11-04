"""Package the standalone prototype, optionally with a verified Windows Godot runtime."""
import argparse
import hashlib
import re
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.17"
ENGINE = "Godot_v4.6.3-stable_win64.exe"
README = """GT4 EVOLUTION — PROTOTIPO 0.17 / MODELOS Y CLASES ARGENTINAS

Extraé TODO el ZIP. Windows 10/11 de 64 bits: doble clic en JUGAR.cmd.
El motor está incluido y el primer inicio importa el proyecto.
El ZIP Proyecto requiere Godot 4.6.3: abrí juego/project.godot.

NUEVO: modelos aportados del 147 Vivace y Uno Fire integrados con ruedas animadas.
Derivados optimizados conservan las texturas; fuentes originales preservadas aparte.
El Uno suministrado tiene cinco puertas: es una referencia visual provisional para la
variante de tres puertas del catálogo. El Gol conserva su modelo original. Ver assets/cars/README.md.

Comprá un auto en CONCESIONARIO y abrí GARAJE → DUELO ¼ DE MILLA / FÁBRICA.
Elegí rival y clase: por defecto Clase 1 / piso 18,00 s; LIBRE no aplica piso.
Los pisos de ¼ provienen del art. 21 del reglamento aportado. Ir por debajo del piso
es caída; la reacción NO se suma al ET para evaluarlo. La llegada usa reacción+ET.
Excepción art. 12: el falso individual entrega victoria al rival aunque caiga de tiempo.
El ticket conserva ambos tiempos y señala la excepción; ambos falsos/caídas no
generan un ganador. Es exhibición sin inscripción, premios ni campeonato oficial.
Fábrica ignora preparaciones y compuestos deportivos, conservando salud del auto.
La categoría oficial «serie» permite mecánica preparada y tiene otro alcance.
Los récords de fábrica se guardan separados de los de práctica.
GARAJE → ¼ DE MILLA / MANUAL conserva práctica individual con mejoras existentes.

CONTROLES DEL ¼: mantené C (embrague), tocá E para primera, Enter arma semáforo.
Regulá W para RPM, esperá verde y soltá C. Para subir: soltá W, pisá C, tocá E,
soltá C y acelerá. Q baja marcha. Cambiar sin embrague se rechaza y desgasta caja.
R repite conservando desgaste y temperatura; P pausa ambos autos; Esc vuelve a garaje.
Tab cambia cámara; Shift mira atrás. AJUSTES permite reasignar teclas y ayudas.
Mando: RT acelera, LT/B frena, LB embrague, A sube, Y baja, X repite, RB cámara.
Select abre pausa; embrague analógico LT/L2 opcional. Menús: stick/cruceta, A confirma,
B vuelve, LB/RB cambia pestaña. Desconectar mando activo pausa el juego.

Motor, embrague, caja, ejes, neumáticos, pérdidas y transferencia de carga se simulan.
El HUD muestra 0–100 medido, torque, potencia al eje, temperaturas, RT/ET y trampa.
Uno Fire 1.3 8V 2014: curva anclada en 68 CV/5250 RPM y 11,3 kgfm/2250 RPM,
según datos de fabricante transcritos por el usuario. 13,2 s de 0–100 es una referencia,
no una aceleración impuesta por el juego. La calibración completa sigue pendiente:
los reglamentos no demuestran potencia/masa/relaciones reales. Ver STOCK-SOURCES.md.
El circuito es original de 402,336 m, inspirado en el ambiente del Gálvez.
Colisiones y agarre lateral simplificados; sin deformación visual ni homologación.

TALLER: reparaciones y neumáticos calle/deportivos/slick. Recuperar NO repara.
Los importes están en pesos argentinos ARS; cada unidad contable histórica = $ 1.000 ARS.
GUARDAR conserva progreso; CARGAR recupera la partida. Mantiene guardados anteriores.
Música: Lezcano Alan — PERRA #Ritmomanijero, Prod Sketchy, aportada con autorización de
redistribución. Volumen en AJUSTES; se desvanece en pista. No cubierta por MIT.
El circuito del club, carrera y modos previos siguen disponibles; los eventos simulados
se identifican en su interfaz. No se distribuyen recursos comerciales de GT4.

Ver RELEASE-0.17.md y REGULATIONS-REFERENCE.md para alcance y reglas no implementadas.
Validación en Linux con Godot 4.6.3, headless y capturas OpenGL por software.
Windows, mando físico y GPU real requieren prueba en esos equipos. Si no abre, ejecutá
DIAGNOSTICO.cmd y compartí importacion.log/juego.log. Licencias incluidas.
"""

LAUNCH = r'''@echo off
setlocal
cd /d "%~dp0"
"motor\Godot_v4.6.3-stable_win64_console.exe" --headless --path "%~dp0juego" --editor --import > importacion.log 2>&1
if errorlevel 1 (
  echo No se pudo importar el juego. Revisa importacion.log.
  pause
  exit /b 1
)
"motor\Godot_v4.6.3-stable_win64.exe" --path "%~dp0juego"
'''
DIAGNOSTIC = r'''@echo off
setlocal
cd /d "%~dp0"
"motor\Godot_v4.6.3-stable_win64_console.exe" --headless --path "%~dp0juego" --editor --import > importacion.log 2>&1
"motor\Godot_v4.6.3-stable_win64_console.exe" --path "%~dp0juego" > juego.log 2>&1
echo Diagnostico guardado en importacion.log y juego.log.
pause
'''


def write_project(archive):
    for path in sorted((ROOT / "godot").rglob("*")):
        if not path.is_file() or ".godot" in path.parts:
            continue
        if path.suffix not in {".gd", ".uid", ".tscn", ".tres", ".godot", ".md", ".ttf", ".otf", ".txt", ".import", ".mp3", ".glb", ".png"}:
            continue
        archive.write(path, Path("juego") / path.relative_to(ROOT / "godot"))
    archive.write(ROOT / "LICENSE", "LICENSE")
    archive.write(ROOT / "README.md", "README-proyecto.md")
    archive.writestr("LEEME.txt", README)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--windows-engine", type=Path)
    parser.add_argument("--checksums", type=Path)
    parser.add_argument("--engine-license", type=Path)
    args = parser.parse_args()
    session_version = re.search(r'^const VERSION := "([^"]+)"', (ROOT / "godot/scripts/session.gd").read_text(), re.MULTILINE)
    if session_version is None or session_version.group(1) != VERSION:
        raise ValueError("Game and package versions differ")
    args.output.mkdir(parents=True, exist_ok=True)
    if args.windows_engine:
        if not args.checksums:
            parser.error("--checksums is required with --windows-engine")
        if not args.engine_license:
            parser.error("--engine-license is required with --windows-engine")
        expected = next(line.split()[0] for line in args.checksums.read_text().splitlines()
                        if line.split()[-1] == args.windows_engine.name)
        with args.windows_engine.open("rb") as handle:
            actual = hashlib.file_digest(handle, "sha512").hexdigest()
        if actual != expected:
            raise ValueError("Official engine SHA-512 mismatch")
    source = args.output / f"GT4-Evolution-{VERSION}-Proyecto.zip"
    with zipfile.ZipFile(source, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        write_project(archive)
    if args.windows_engine:
        windows = args.output / f"GT4-Evolution-{VERSION}-Windows.zip"
        with zipfile.ZipFile(windows, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            write_project(archive)
            with zipfile.ZipFile(args.windows_engine) as engine:
                for name in [ENGINE, ENGINE.replace(".exe", "_console.exe")]:
                    archive.writestr("motor/" + name, engine.read(name))
            archive.writestr("JUGAR.cmd", LAUNCH.replace("\n", "\r\n"))
            archive.writestr("DIAGNOSTICO.cmd", DIAGNOSTIC.replace("\n", "\r\n"))
            archive.write(args.checksums, "Godot-SHA512-SUMS.txt")
            archive.write(args.engine_license, "Godot-LICENSE.txt")
    for package in sorted(args.output.glob(f"GT4-Evolution-{VERSION}-*.zip")):
        with package.open("rb") as handle:
            checksum = hashlib.file_digest(handle, "sha256").hexdigest()
        package.with_suffix(".zip.sha256").write_text(f"{checksum}  {package.name}\n")
        print(f"{package.name}: {package.stat().st_size:,} bytes")


if __name__ == "__main__":
    main()
