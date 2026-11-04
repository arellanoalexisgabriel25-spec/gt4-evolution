"""Package the standalone prototype, optionally with a verified Windows Godot runtime."""
import argparse
import hashlib
import re
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.15"
ENGINE = "Godot_v4.6.3-stable_win64.exe"
README = """GT4 EVOLUTION — PROTOTIPO 0.15 / AUTOS INSIGNIA, DAÑOS Y NEUMÁTICOS

Extraé TODO el ZIP antes de abrir el juego.
Windows 10/11 de 64 bits: doble clic en JUGAR.cmd. El primer inicio importa
el proyecto; puede tardar unos segundos. No requiere instalar Godot aparte.
Si descargaste el ZIP de código, abrí juego/project.godot con Godot 4.6.3.

AUTOS INSIGNIA: Fiat 147 Vivace, Fiat Uno Fire 3 puertas y Gol Power 3 puertas.
Encabezan el concesionario; Inicio permite verlos con 147 / UNO / GOL.
En GARAJE, VER MODELO selecciona la vista si tenés varias unidades.
El Gol usa el GLB texturizado suministrado, con sus ruedas animadas.
Los modelos adjuntos del 147 y del Uno todavía no pudieron descargarse;
usan carrocerías originales provisionales y configuraciones de manejo propias.
Ver juego/assets/cars/README.md e informe RELEASE-0.15.md.

TALLER: montar calle ($320.000 ARS), deportivos ($650.000 ARS) o slick ($1.400.000 ARS).
El juego de neumáticos restaura su salud y queda guardado al guardar la partida.
Calle funciona desde frío; los slick exigen temperatura y se desgastan más.
El contacto y el patinamiento generan el calor, por separado para cada eje.
Los impactos reales en el cuarto de milla dañan componentes y reducen rendimiento.
R no repara: volvé al taller. El ticket diferencia daños y desgaste.
Se conserva el cronometraje, los cambios manuales y la liquidación existentes.
La evaluación del aporte de Claude está en juego/INTEGRATION-CLAUDE-0.11d.md.

Novedades: ejes delantero/trasero independientes, torque por RPM y carga de turbo,
pérdidas de transmisión, ABS y TCS opcionales. TCS recorta motor, no añade agarre.
El embrague y las ruedas conservan inercia; la masa y los neumáticos importan.
Los importes se muestran en PESOS ARGENTINOS (ARS), conservando las proporciones
del saldo y de los precios anteriores. Cada unidad histórica equivale a $1.000 ARS;
el saldo inicial se muestra como $12.000.000 ARS. No es una cotización real.
La conversión no se vuelve a multiplicar al cargar la partida.

Música de menú: Lezcano Alan — PERRA #Ritmomanijero, Prod Sketchy.
Archivo original aportado por el usuario con autorización de redistribución.
Volumen independiente en AJUSTES; se desvanece al entrar en pista y vuelve al garaje.
Ver juego/assets/audio/README.md. La música no está cubierta por la licencia MIT.

Mando en menús: stick/cruceta mueve el foco; A/Cruz confirma; B/Círculo vuelve;
LB/RB cambia pestaña. Izquierda/derecha modifica opciones y volumen.
En pista, Select/Back abre la pausa con botones para continuar, recuperar o salir.
Desconectar el mando activo pausa la conducción y libera los gatillos.
AJUSTES permite embrague analógico LT/L2; en ese modo B/Círculo frena.

Nuevo foco: una pista original de 402,336 m con ambiente inspirado en el
autódromo Gálvez, sin reproducir exactamente su trazado ni sus instalaciones.
Comprá un auto en CONCESIONARIO, abrí GARAJE y elegí ¼ DE MILLA / MANUAL.
Es práctica libre, sin inscripción ni premios en pesos; el desgaste sí se conserva.

1. Mantené C (embrague) y tocá E para poner primera. Mantené C presionado.
2. Enter inicia el semáforo. Regulá W para preparar las RPM y esperá el verde.
3. Soltá C y acelerá. Cambiar en la banda de potencia mejora la marca.
4. Para subir: soltá W, pisá C, tocá E, soltá C y volvé a acelerar.
Q baja una marcha. El cambio sin embrague se rechaza y desgasta la caja.
El limitador corta potencia; reducir demasiado puede forzar el motor.
R prepara otra pasada y conserva el uso, el desgaste y la temperatura acumulados.
P pausa, Tab cambia cámara y Esc regresa al garaje. Guardá el progreso al volver.
Las teclas son configurables; los controles anteriores migran sin perder sus asignaciones.
Mando en ¼ de milla: RT acelera, LT o B frena, LB embrague, A sube, Y baja,
X repite, RB cámara, R3 mirada trasera. Inicio arma en preparación o pausa durante la pasada.

El ticket mide ET, reacción, total, 60 pies, 1/8 de milla y velocidad de trampa.
Salir de carril o cruzar antes del verde invalida la marca. Las mejores pasadas
se conservan por unidad de vehículo; ET y reacción se muestran por separado.
El motor tiene inercia, curva de par, embrague con acople finito y tracción limitada.
El estado y las mejoras del garaje afectan potencia y agarre; errores, patinamiento
y deslizamiento del embrague añaden desgaste. Son aproximaciones de desarrollo,
no mediciones oficiales de los autos. Sonido de motor sintetizado provisional.

El circuito del club conserva CONTRARRELOJ 3D y CARRERA LIBRE 3D.
La carrera libre no cobra ni da premios.
Para competir con progreso: MODO CARRERA -> Copa de Debutantes -> CORRER 3D.
La inscripción cuesta $120.000 ARS. Abandonar consume la inscripción y no da premio.
Son dos vueltas contra Nico y Claire; la llegada paga $700.000/$400.000/$200.000 ARS.
Los demás eventos y la prueba de 10 km siguen siendo simulados.

W/flecha arriba: acelerar. S/abajo: frenar y reversa. A/D o flechas: girar.
ESPACIO: frenar. R: recuperar (tres segundos de detención en carrera).
TAB / RB: cambiar cámara. SHIFT / Y: mirar atrás. Stick derecho: mirar alrededor.
AJUSTES permite elegir cámara inicial y suavizar la dirección del teclado.
P: pausar a todos. ESC: volver al garaje / abandonar la carrera.
AJUSTES permite cambiar teclas y la zona muerta del mando. Las flechas quedan
siempre disponibles. Los controles se guardan automáticamente, separados de la partida.
Mando: stick/cruceta gira, RT/R2 acelera, LT/L2 frena proporcionalmente,
B/Círculo reversa, X/Cuadrado recupera e Inicio pausa. Se activa al moverlo o pulsarlo.
Cruzá las ocho puertas en orden. Salir del asfalto invalida la vuelta actual.
Se guardan mejores tiempos por auto y toda la distancia recorrida, incluso
menos de 1 km. Volvé al garaje y presioná GUARDAR; el guardado es manual.
CARGAR recupera la partida anterior. Las partidas viejas siguen siendo compatibles.

Incluye rivales físicos, barreras con colisión, ritmo y adelantamientos básicos,
cronómetro, posiciones, resultado real de Debutantes, economía y desgaste.
La aceleración sigue una curva de par por RPM, la carga afecta al agarre de
cada eje y el frenado está limitado por neumáticos, también al pedir reversa.
Cuatro cámaras, mirada trasera y brazo de seguimiento con prevención de obstáculos.
Menú con mapa de servicios, garaje 3D y HUD de carrera; gráficos propios.
La dirección de teclado entra progresivamente y vuelve al centro con mayor rapidez.
La dirección del ¼ de milla tiene asistencia; aún no hay un modelo lateral completo.
Salvo el Gol importado, los modelos siguen siendo provisionales, al igual que
las temperaturas y el audio de motor. Hay daños mecánicos por impacto en el
cuarto de milla, sin deformación visual ni simulación térmica/mecánica completa.
Se consultó gt4-decomp como referencia para RPM y cambios secuenciales.
La IA y el circuito son implementaciones originales. No se han incluido
recursos del juego comercial. Ver juego/REFERENCES.md y juego/README.md.

Validación: Godot 4.6.3 en Linux, pruebas headless y capturas reales con OpenGL por software.
Las capturas no constituyen una prueba de rendimiento o compatibilidad con tu GPU.
El paquete Windows no ha sido ejecutado en Windows en este entorno.
Si no abre, ejecutá DIAGNOSTICO.cmd y compartí los archivos importacion.log y juego.log.
Godot: https://godotengine.org/license/ (motor oficial, licencia MIT).
Tipografía Barlow Condensed: licencia SIL OFL en juego/assets/fonts/OFL-Barlow.txt.
Créditos y licencia del proyecto en LICENSE y README-proyecto.md.
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
        if path.suffix not in {".gd", ".uid", ".tscn", ".tres", ".godot", ".md", ".ttf", ".otf", ".txt", ".import", ".mp3", ".glb"}:
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
    with zipfile.ZipFile(source, "w", zipfile.ZIP_DEFLATED) as archive:
        write_project(archive)
    if args.windows_engine:
        windows = args.output / f"GT4-Evolution-{VERSION}-Windows.zip"
        with zipfile.ZipFile(windows, "w", zipfile.ZIP_DEFLATED) as archive:
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
