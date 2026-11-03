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
                if not source.is_file() or ".godot" in source.parts or source.suffix not in {".gd", ".tscn", ".tres", ".godot", ".md"}:
                    continue
                key = "juego/" + source.relative_to(ROOT / "godot").as_posix()
                if archive.read(key) != source.read_bytes():
                    raise SystemExit(f"Package differs from committed source: {key}")
    base = f"https://github.com/{identity}/raw/refs/heads/{branch}"
    readme = f"""# GT4 Evolution {VERSION} · Descargas

- [Descargar juego para Windows]({base}/{names[0]})
- [Descargar proyecto para Godot]({base}/{names[1]})

Extraé TODO el ZIP Windows y abrí **JUGAR.cmd**. El motor está incluido.
Comprá un auto; en GARAJE hay práctica y carrera libre. En MODO CARRERA,
Debutantes se corre en pista con inscripción y premios. Volvé al garaje y
presioná GUARDAR para conservar el progreso. AJUSTES permite cambiar controles.

El paquete incluye LEEME.txt con controles y limitaciones, y DIAGNOSTICO.cmd
para registrar fallos de arranque. Windows y los mandos físicos requieren
prueba en esos equipos; la validación automatizada se realiza en Linux.
Las licencias se incluyen. No se distribuyen recursos comerciales de GT4.

Código: [{source_commit[:7]}](https://github.com/{identity}/commit/{source_commit}).
Esta rama contiene únicamente distribución y no se integra en main.
Los archivos .sha256 permiten verificar los ZIP.
"""
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
