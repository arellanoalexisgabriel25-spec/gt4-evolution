"""Externalize/downsample supplied GLB textures without changing geometry or UVs.

python3 tools/optimize_runtime_textures.py --manifest sources.json --output /derivatives
The manifest contains [{"model": "safe_name", "source": "/backup/model.glb"}].
Keep sources separate; the tool refuses an in-place conversion. Pillow is needed
only for asset preparation, never by the shipped game. No Blender round-trip is
used, so accessor bytes, materials and wheel contours remain unchanged.
"""
import argparse
import copy
import hashlib
import io
import json
import math
from pathlib import Path
import re
import struct

from PIL import Image


def digest(data):
    return hashlib.sha256(data).hexdigest()


def read_glb(path):
    raw = path.read_bytes()
    if raw[:4] != b"glTF" or struct.unpack_from("<II", raw, 4) != (2, len(raw)):
        raise ValueError("Expected a complete GLB2")
    length, kind = struct.unpack_from("<II", raw, 12)
    if kind != 0x4E4F534A:
        raise ValueError("Missing GLB JSON")
    doc = json.loads(raw[20:20 + length])
    start = 20 + length
    binary_length, kind = struct.unpack_from("<II", raw, start)
    if kind != 0x004E4942 or len(doc["buffers"]) != 1:
        raise ValueError("Expected a single embedded BIN buffer")
    binary = raw[start + 8:start + 8 + binary_length]
    return raw, doc, binary


def image_role(doc, image_index):
    roles = set()
    for material in doc.get("materials", []):
        pbr = material.get("pbrMetallicRoughness", {})
        for key, role in [("normalTexture", "normal"), ("emissiveTexture", "albedo"),
                          ("occlusionTexture", "orm")]:
            texture = material.get(key)
            if texture and doc["textures"][texture["index"]]["source"] == image_index:
                roles.add(role)
        for key, role in [("baseColorTexture", "albedo"), ("metallicRoughnessTexture", "orm")]:
            texture = pbr.get(key)
            if texture and doc["textures"][texture["index"]]["source"] == image_index:
                roles.add(role)
    if len(roles) != 1:
        raise ValueError("Inspect images with unknown or mixed semantic roles separately")
    return roles.pop()


def resize_image(data, size, role):
    image = Image.open(io.BytesIO(data))
    if "A" in image.getbands() and image.getextrema()[image.getbands().index("A")] != (255, 255):
        raise ValueError("Inspect transparent material textures separately")
    image = image.convert("RGB")
    original_size = image.size
    image.thumbnail((size, size), Image.Resampling.LANCZOS)
    if role == "normal":
        # Averages of unit tangent-space normals need normalization after filtering.
        normalized = []
        pixels = image.get_flattened_data() if hasattr(image, "get_flattened_data") else image.getdata()
        for pixel in pixels:
            vector = [(channel / 127.5) - 1.0 for channel in pixel]
            length = math.sqrt(sum(value * value for value in vector))
            vector = [value / length for value in vector] if length > 1e-9 else [0, 0, 1]
            normalized.append(tuple(max(0, min(255, round((value + 1) * 127.5))) for value in vector))
        image.putdata(normalized)
    return image, original_size


def remap_views(value, mapping):
    if isinstance(value, dict):
        for key, child in value.items():
            if key == "bufferView":
                if child not in mapping:
                    raise ValueError("A removed image view has a non-image consumer")
                value[key] = mapping[child]
            else:
                remap_views(child, mapping)
    elif isinstance(value, list):
        for child in value:
            remap_views(child, mapping)


def convert(item, output, size):
    name, source = item["model"], Path(item["source"])
    if not re.fullmatch(r"[a-z0-9_]+", name):
        raise ValueError("Unsafe model identifier")
    target = output / name / (name + ".glb")
    if target.resolve() == source.resolve():
        raise ValueError("Keep source and derivative separate")
    target.parent.mkdir(parents=True, exist_ok=True)
    raw, original, binary = read_glb(source)
    doc = copy.deepcopy(original)
    removed = set()
    image_reports = []
    for index, image in enumerate(doc.get("images", [])):
        if "bufferView" not in image:
            raise ValueError("Expected embedded original images")
        view_index = image.pop("bufferView")
        removed.add(view_index)
        view = original["bufferViews"][view_index]
        start = view.get("byteOffset", 0)
        pixels = binary[start:start + view["byteLength"]]
        role = image_role(original, index)
        resized, original_size = resize_image(pixels, size, role)
        texture = target.with_name(name + "_" + role + ".png")
        if texture.exists():
            raise ValueError("Refusing duplicate texture role or existing output: " + str(texture))
        resized.save(texture, format="PNG", optimize=True, compress_level=9)
        image.pop("mimeType", None)
        image["uri"] = texture.name
        # Normal maps use the normal-map importer flag; other maps keep RGB data.
        normal_mode = 1 if role == "normal" else 2
        Path(str(texture) + ".import").write_text(
            '[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\n'
            'compress/mode=2\ncompress/high_quality=false\n'
            f'compress/normal_map={normal_mode}\nmipmaps/generate=true\n')
        image_reports.append({"role": role, "source_dimensions": original_size,
                              "runtime_dimensions": resized.size, "source_bytes": len(pixels),
                              "runtime_bytes": texture.stat().st_size,
                              "source_sha256": digest(pixels), "runtime_sha256": digest(texture.read_bytes())})
    mapping = {}
    views, packed = [], bytearray()
    geometry_hashes = []
    for index, original_view in enumerate(original["bufferViews"]):
        if index in removed:
            continue
        offset = original_view.get("byteOffset", 0)
        data = binary[offset:offset + original_view["byteLength"]]
        packed.extend(b"\0" * ((-len(packed)) % 4))
        view = copy.deepcopy(original_view)
        view["byteOffset"] = len(packed)
        mapping[index] = len(views)
        views.append(view)
        packed.extend(data)
        geometry_hashes.append(digest(data))
    doc["bufferViews"] = views
    remap_views(doc, mapping)
    doc["buffers"][0]["byteLength"] = len(packed)
    encoded = json.dumps(doc, separators=(",", ":")).encode()
    encoded += b" " * ((-len(encoded)) % 4)
    packed.extend(b"\0" * ((-len(packed)) % 4))
    length = 12 + 8 + len(encoded) + 8 + len(packed)
    target.write_bytes(struct.pack("<III", 0x46546C67, 2, length)
                      + struct.pack("<II", len(encoded), 0x4E4F534A) + encoded
                      + struct.pack("<II", len(packed), 0x004E4942) + packed)
    Path(str(target) + ".import").write_text(
        '[remap]\nimporter="scene"\nimporter_version=1\ntype="PackedScene"\n\n[params]\n'
        'gltf/embedded_image_handling=3\n')
    # Verify every non-image view after reconstruction, including normals/UV/index data.
    _, checked, checked_binary = read_glb(target)
    if checked.get("materials") != original.get("materials") or checked.get("meshes") != original.get("meshes"):
        raise ValueError("Material or mesh definitions changed")
    for view, expected in zip(checked["bufferViews"], geometry_hashes):
        offset = view.get("byteOffset", 0)
        if digest(checked_binary[offset:offset + view["byteLength"]]) != expected:
            raise ValueError("Geometry changed during texture conversion")
    triangles = sum(original["accessors"][primitive["indices"]]["count"] // 3
                    for mesh in original["meshes"] for primitive in mesh["primitives"])
    return {"model": name, "source": str(source), "source_sha256": digest(raw),
            "runtime_sha256": digest(target.read_bytes()), "source_bytes": len(raw),
            "runtime_glb_bytes": target.stat().st_size, "runtime_triangles": triangles,
            "geometry_and_uv_byte_identical": True, "images": image_reports,
            "runtime_total_bytes": target.stat().st_size + sum(image["runtime_bytes"] for image in image_reports)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--texture-size", type=int, default=1024)
    args = parser.parse_args()
    if args.texture_size < 256 or args.texture_size > 4096:
        parser.error("Choose a texture size in 256..4096")
    args.output.mkdir(parents=True, exist_ok=True)
    reports = [convert(item, args.output, args.texture_size)
               for item in json.loads(args.manifest.read_text())]
    (args.output / "texture-derivatives.json").write_text(json.dumps(reports, indent=2) + "\n")
    for report in reports:
        print(report["model"], report["source_bytes"], "->", report["runtime_total_bytes"], "bytes")


if __name__ == "__main__":
    main()
