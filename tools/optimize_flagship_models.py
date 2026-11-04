"""Reproducible visual derivative; run with Blender 4.3+ --background --python.
Preserves supplied GLBs and their embedded texture bytes. Geometry is decimated
using Blender's UV-aware collapse operator to ~80k triangles. No body restyling.
"""
import argparse, sys
import bpy, bmesh, hashlib, json, struct, time
from pathlib import Path

parser = argparse.ArgumentParser(description="Create render-only derivatives without modifying the supplied GLBs")
parser.add_argument("--sources", type=Path, required=True, help="Root containing model-1/base_basic_shaded.glb and model-2/base_basic_shaded (1).glb")
parser.add_argument("--output", type=Path, required=True, help="Separate derivative directory; never use the original source directory")
args = parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
BASE = args.sources.resolve()
REPORTS = args.output.resolve()
REPORTS.mkdir(parents=True, exist_ok=True)
TARGET_TRIANGLES = 80000
SOURCES = [
    ('uno_fire', BASE/'model-1'/'base_basic_shaded.glb'),
    ('fiat_147', BASE/'model-2'/'base_basic_shaded (1).glb'),
]

def load_glb(path):
    raw = path.read_bytes()
    length = struct.unpack_from('<I', raw, 12)[0]
    doc = json.loads(raw[20:20+length])
    return raw, doc, raw[28+length:]

def preserve_original_texture(source, dest):
    original_raw, original, original_bin = load_glb(source)
    raw, doc, blob = load_glb(dest)
    image = original['images'][0]
    image_view = original['bufferViews'][image['bufferView']]
    start = image_view.get('byteOffset', 0)
    original_texture = original_bin[start:start+image_view['byteLength']]
    image = doc['images'][0]
    view = doc['bufferViews'][image['bufferView']]
    offset = view.get('byteOffset', 0)
    # Blender embeds image at the last view; keep all geometry byte-exact.
    assert offset+view['byteLength'] <= len(blob)
    assert all(v.get('byteOffset',0) < offset for i,v in enumerate(doc['bufferViews']) if i != image['bufferView'])
    blob = blob[:offset] + original_texture
    view['byteLength'] = len(original_texture)
    doc['buffers'][0]['byteLength'] = len(blob)
    json_raw = json.dumps(doc,separators=(',',':')).encode('utf8')
    json_raw += b' '*((-len(json_raw))%4)
    blob += b'\0'*((-len(blob))%4)
    total = 12+8+len(json_raw)+8+len(blob)
    dest.write_bytes(struct.pack('<III',0x46546c67,2,total)+struct.pack('<II',len(json_raw),0x4e4f534a)+json_raw+struct.pack('<II',len(blob),0x004e4942)+blob)
    return hashlib.sha256(original_texture).hexdigest()

reports=[]
for name, source in SOURCES:
    started=time.monotonic()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source))
    objects=[obj for obj in bpy.context.scene.objects if obj.type=='MESH']
    assert len(objects)==1
    obj=objects[0]
    input_triangles=sum(max(0,len(poly.vertices)-2) for poly in obj.data.polygons)
    bm=bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=0.0000001)
    bm.verts.index_update()
    layer=bm.loops.layers.uv.active
    pinned=set()
    for edge in bm.edges:
        if not edge.is_manifold:
            pinned.update(v.index for v in edge.verts)
            continue
        a,b=edge.link_loops
        # An oriented manifold pair traverses its shared edge in reverse.
        same_a=(a[layer].uv-b.link_loop_next[layer].uv).length_squared < 1e-12
        same_b=(a.link_loop_next[layer].uv-b[layer].uv).length_squared < 1e-12
        if not (same_a and same_b):
            pinned.update(v.index for v in edge.verts)
    bm.to_mesh(obj.data)
    bm.free()
    print('UV_PROTECTION',name,len(obj.data.vertices),'vertices',len(pinned),'pinned',flush=True)
    group=obj.vertex_groups.new(name='Simplify interior only; preserve UV boundaries')
    group.add(list(range(len(obj.data.vertices))),1.0,'REPLACE')
    group.add(list(pinned),0.0,'REPLACE')
    mod=obj.modifiers.new('Runtime 80k UV-preserving simplification','DECIMATE')
    mod.decimate_type='COLLAPSE'
    mod.ratio=TARGET_TRIANGLES/input_triangles
    mod.use_collapse_triangulate=True
    mod.vertex_group=group.name
    mod.vertex_group_factor=1.0
    bpy.context.view_layer.objects.active=obj
    bpy.ops.object.modifier_apply(modifier=mod.name)
    output_triangles=sum(max(0,len(poly.vertices)-2) for poly in obj.data.polygons)
    target=REPORTS/name/(name+'.glb')
    if target.resolve()==source.resolve(): raise ValueError('Source and derivative must be separate')
    target.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=False,export_materials='EXPORT',export_image_format='AUTO',export_yup=True,export_apply=True,export_animations=False)
    texture_hash=preserve_original_texture(source,target)
    raw,doc,_=load_glb(target)
    report={'model':name,'source':str(source),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'derivative':str(target),'derivative_sha256':hashlib.sha256(raw).hexdigest(),'source_triangles':input_triangles,'runtime_triangles':output_triangles,'runtime_bytes':len(raw),'texture_sha256':texture_hash,'texture_original_bytes_preserved':True,'blender':bpy.app.version_string,'algorithm':'Decimate COLLAPSE ratio0.08, triangulate true, UV boundary vertices pinned, coincident positions welded, UVs retained','seconds':round(time.monotonic()-started,1),'gltf_asset':doc['asset']}
    reports.append(report)
    print('DERIVATIVE',json.dumps(report),flush=True)
    (REPORTS/'derivatives-uv-protected.json').write_text(json.dumps(reports,indent=2)+'\n')
