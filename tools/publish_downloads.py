"""Publish checked release ZIPs on an immutable, separate GitHub download branch."""
import argparse
import hashlib
from pathlib import Path
import re
import subprocess
import zipfile
from urllib.parse import urlsplit

from package_game import ROOT, VERSION


def git(*args, data=None):
    return subprocess.check_output(["git", *args], cwd=ROOT, input=data).decode().strip()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--artifacts", type=Path, required=True)
    parser.add_argument("--screenshots", type=Path, help="Directory of the twenty-seven checked 1280x720 presentation PNGs")
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
    for name in names:
        with zipfile.ZipFile(args.artifacts / name) as archive:
            if archive.testzip() is not None:
                raise SystemExit(f"Corrupt package: {name}")
            for source in (ROOT / "godot").rglob("*"):
                if not source.is_file() or ".godot" in source.parts or source.suffix not in {".gd", ".tscn", ".tres", ".godot", ".md", ".ttf", ".otf", ".txt", ".import", ".mp3", ".glb", ".png"}:
                    continue
                key = "juego/" + source.relative_to(ROOT / "godot").as_posix()
                if archive.read(key) != source.read_bytes():
                    raise SystemExit(f"Package differs from committed source: {key}")
    base = f"https://github.com/{identity}/raw/refs/heads/{branch}"
    readme = f"""# GT4 Evolution {VERSION} · Descargas

- [Descargar juego para Windows]({base}/{names[0]})
- [Descargar proyecto para Godot]({base}/{names[1]})

Extraé TODO el ZIP Windows y abrí **JUGAR.cmd**. El motor está incluido.
**GARAJE → DUELO ¼ DE MILLA / FÁBRICA** corre contra otro auto físico.
Elegí piloto y clase (Clase 1: piso ET 18,00 s) o LIBRE, sin piso.
Clases de ¼ según el art. 21 del texto aportado; caída por ET bajo el piso.
La reacción cuenta para llegar primero. Un falso individual concede al rival
la excepción del art. 12 aunque su ET caiga. Exhibición sin inscripción ni premios.
Fábrica conserva salud del garaje y excluye preparaciones; «serie» oficial tiene
otro alcance. La práctica individual y sus marcas anteriores siguen disponibles.
147 Vivace y Uno Fire usan derivados optimizados de los nuevos modelos aportados,
con texturas conservadas y ruedas animadas. El Uno suministrado tiene cinco puertas,
referencia visual provisional de la variante de tres puertas del catálogo.
El Gol conserva el modelo aportado original. Las métricas físicas todavía son
estimaciones pendientes de fuentes de fabricante. Ver STOCK-SOURCES.md.
En Inicio podés elegir 147 / UNO / GOL; en garaje, VER MODELO cambia la vista.
El taller ofrece calle, deportivos o slick. Los impactos dejan daño mecánico
persistente; recuperar no repara. Ver RELEASE-0.17.md y REGULATIONS-REFERENCE.md.

Comprá un auto y abrí **GARAJE → ¼ DE MILLA / MANUAL**. Mantené C, tocá E
para primera, iniciá el árbol con Enter y esperá el verde. Regulá W para las RPM,
soltá C para largar y usá C+E en cada cambio. Q baja. R prepara otra pasada.
La práctica no cobra ni da premios en pesos; sí registra uso y desgaste.
Volvé al garaje y presioná GUARDAR para conservar marcas y progreso.
AJUSTES permite reasignar las teclas. El circuito del club sigue disponible.
Los importes están en pesos argentinos. Se incluye la música de menú aportada
por el usuario y autorizada para redistribución; volumen en AJUSTES.
Mando: stick/cruceta navega, A confirma, B vuelve, LB/RB cambia pestaña.
Select/Back abre la pausa en pista; embrague analógico LT/L2 opcional.

El paquete incluye LEEME.txt con controles y limitaciones, y DIAGNOSTICO.cmd
para registrar fallos de arranque. Windows y los mandos físicos requieren
prueba en esos equipos; la validación automatizada se realiza en Linux.
Las licencias se incluyen. No se distribuyen recursos comerciales de GT4.

Código: [{source_commit[:7]}](https://github.com/{identity}/commit/{source_commit}).
Esta rama contiene únicamente distribución y no se integra en main.
Los archivos .sha256 permiten verificar los ZIP.
"""
    if args.screenshots:
        shots = ["01-home", "02-dealer", "03-garage", "04-settings", "05-camera-0", "06-camera-1", "07-camera-2", "08-camera-3", "09-look-back", "10-race-grid", "11-drag-staging", "12-drag-tree", "13-drag-driving", "14-drag-close", "15-drag-ticket", "16-drag-red-light", "17-controller-pause", "18-147-showroom", "19-uno-showroom", "20-gol-showroom", "21-tire-workshop", "22-gol-staging", "23-impact-damage", "24-gol-driving", "25-duel-staging", "26-duel-driving", "27-duel-result"]
        for shot in shots:
            path = args.screenshots / (shot + ".png")
            header = path.read_bytes()[:24]
            if (path.stat().st_size > 5 * 1024 * 1024 or header[:8] != b"\x89PNG\r\n\x1a\n"
                    or header[12:16] != b"IHDR" or header[16:24] != b"\x00\x00\x05\x00\x00\x00\x02\xd0"):
                raise SystemExit(f"Invalid presentation capture (expected 1280x720 PNG): {shot}")
            files.append(("captura-" + path.name, path))
        readme += f"\n## Presentación {VERSION}\n\n"
        readme += "Capturas reales del juego en Linux con OpenGL por software. No son renders conceptuales.\n\n"
        readme += "Tab / RB cambia entre seguimiento, cercana, capó y paragolpes; Shift / Y permite mirar atrás.\n"
        readme += "AJUSTES conserva la cámara inicial y permite suavizar la dirección del teclado.\n\n"
        for title, shot in [("Dos autos de fábrica / Semáforo común", "25-duel-staging"), ("Carrera física contra un rival", "26-duel-driving"), ("Resultado por reacción más ET", "27-duel-result"), ("Gol Power / Modelo aportado", "20-gol-showroom"), ("Gol en una pasada manual real", "24-gol-driving"), ("Impacto real / Daños mecánicos", "23-impact-damage"), ("Taller / Compuestos de neumáticos", "21-tire-workshop"), ("147 Vivace / Modelo aportado", "18-147-showroom"), ("Uno Fire / Modelo aportado", "19-uno-showroom"), ("Inicio y autos insignia", "01-home"), ("Música, mando y ayudas", "04-settings"), ("Ticket de llegada real", "15-drag-ticket"), ("Pausa con mando", "17-controller-pause")]:
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
