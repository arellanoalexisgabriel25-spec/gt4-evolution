"""Shared source/PCK validation for the independent game's release packages.

PCK directory parsing follows Godot 4.6.3 core/io/file_access_pack.cpp. Packs
are unencrypted and use separate data files; all entry digests are verified.
"""
import hashlib
from pathlib import Path, PurePosixPath
import struct

SOURCE_SUFFIXES = {".gd", ".uid", ".tscn", ".tres", ".godot", ".md", ".ttf", ".otf", ".txt", ".import", ".mp3", ".ogg", ".glb", ".png", ".cfg"}
ENGINE_VERSION = "4.6.3"
TEMPLATE_ARCHIVE = "Godot_v4.6.3-stable_export_templates.tpz"
TEMPLATE_ARCHIVE_SHA512 = "da606b61c10157844f8300172df374472665f95015495cb1a7cd132c40ede404faa96cc1016a4b9662db9909ddea69632c4948b2cd11163438dad4808881fb68"
WINDOWS_TEMPLATE_SHA256 = "91724f15024a3a545e28ccd83134403d31ce2323a38e51c95e4dfa282f732ab6"


def digest_bytes(data, algorithm="sha256"):
    return hashlib.new(algorithm, data).hexdigest()


def digest_file(path, algorithm="sha256"):
    with Path(path).open("rb") as stream:
        return hashlib.file_digest(stream, algorithm).hexdigest()


def project_files(project):
    project = Path(project)
    return sorted(path for path in project.rglob("*")
                  if path.is_file() and ".godot" not in path.parts and path.suffix in SOURCE_SUFFIXES)


def source_snapshot(project):
    project = Path(project)
    return {path.relative_to(project).as_posix(): digest_file(path) for path in project_files(project)}


def pck_entries(data):
    """Return validated plaintext PCK entries and contents (format v2 or v3)."""
    def u32(position):
        if position < 0 or position + 4 > len(data):
            raise ValueError("Truncated PCK directory")
        return struct.unpack_from("<I", data, position)[0]

    def u64(position):
        if position < 0 or position + 8 > len(data):
            raise ValueError("Truncated PCK directory")
        return struct.unpack_from("<Q", data, position)[0]

    if data[:4] != b"GDPC":
        raise ValueError("Expected a separate Godot PCK")
    version = u32(4)
    major, minor, patch = u32(8), u32(12), u32(16)
    if (major, minor, patch) != (4, 6, 3) or version not in (2, 3):
        raise ValueError("The release requires an unencrypted Godot 4.6.3 PCK")
    flags = u32(20)
    if flags & 1:
        raise ValueError("Encrypted PCK directories cannot be independently checked")
    file_base = u64(24)
    position = u64(32) if version == 3 else 96
    count = u32(position)
    position += 4
    if count <= 0 or count > 100000:
        raise ValueError("Invalid PCK entry count")
    result = {}
    for _ in range(count):
        size = u32(position)
        position += 4
        if size > 16384 or position + size > len(data):
            raise ValueError("Invalid PCK entry path")
        key = data[position:position + size].rstrip(b"\0").decode("utf-8")
        position += size
        offset, length = u64(position), u64(position + 8)
        position += 16
        expected_md5 = data[position:position + 16]
        position += 16
        entry_flags = u32(position)
        position += 4
        key = key.removeprefix("res://")
        if key in result or ".." in PurePosixPath(key).parts or key.startswith("/") or entry_flags:
            raise ValueError("Unsupported or unsafe PCK entry")
        start = file_base + offset
        payload = data[start:start + length]
        if start < 0 or start + length > len(data) or len(payload) != length:
            raise ValueError("PCK entry falls outside its pack")
        if hashlib.md5(payload).digest() != expected_md5:
            raise ValueError("PCK entry digest mismatch: " + key)
        result[key] = payload
    return result


def pck_snapshot(data):
    return {key: digest_bytes(value) for key, value in pck_entries(data).items()}


def validate_export(manifest, executable, pack, sources):
    """Check release contents against both their build manifest and source tree."""
    if manifest.get("schema") != 1 or manifest.get("engine_version") != ENGINE_VERSION:
        raise ValueError("Unknown export manifest")
    if manifest.get("sources") != sources:
        raise ValueError("Export source snapshot differs from current project")
    if manifest.get("template_archive_sha512") != TEMPLATE_ARCHIVE_SHA512:
        raise ValueError("The export did not use the verified official template archive")
    if manifest.get("windows_executable_sha256") != digest_bytes(executable):
        raise ValueError("Exported Windows executable differs from its manifest")
    if digest_bytes(executable) != WINDOWS_TEMPLATE_SHA256:
        raise ValueError("Windows executable differs from the official unmodified release template")
    if executable[:2] != b"MZ":
        raise ValueError("Missing Windows PE executable")
    if manifest.get("pack_sha256") != digest_bytes(pack):
        raise ValueError("Exported PCK differs from its manifest")
    entries = pck_entries(pack)
    if manifest.get("pack_entries") != {key: digest_bytes(value) for key, value in entries.items()}:
        raise ValueError("PCK directory differs from build manifest")
    # Text script export allows an independent byte comparison, avoiding a
    # self-reported success from a stale compiled script cache.
    scripts = [key for key in sources if key.startswith("scripts/") and key.endswith(".gd")]
    if not scripts or any(key not in entries or digest_bytes(entries[key]) != sources[key] for key in scripts):
        raise ValueError("The PCK does not contain every current game script byte-exact")
    if "project.binary" not in entries or not any(key.startswith("scenes/") for key in entries):
        raise ValueError("The PCK is missing the runnable project or scenes")
    return entries
