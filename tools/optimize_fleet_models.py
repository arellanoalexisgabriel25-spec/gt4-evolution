"""Create lightweight, UV-protected derivatives of user-supplied scans.
Run with Blender: blender -b --python tools/optimize_fleet_models.py --
  --manifest sources.json --output /separate/derivatives
Original GLBs remain unchanged. Textures become explicit, mipmapped PNG assets.
"""
import argparse, hashlib, io, json, re, struct, sys, time
from pathlib import Path
import bpy, bmesh
from PIL import Image

parser=argparse.ArgumentParser()
parser.add_argument('--manifest',type=Path,required=True)
parser.add_argument('--output',type=Path,required=True)
parser.add_argument('--triangles',type=int,default=40000)
parser.add_argument('--texture-size',type=int,default=1024)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
args.output.mkdir(parents=True,exist_ok=True)

def glb(path):
 raw=path.read_bytes()
 if raw[:4]!=b'glTF' or struct.unpack_from('<I',raw,4)[0]!=2: raise ValueError('Expected GLB2')
 n=struct.unpack_from('<I',raw,12)[0]
 return json.loads(raw[20:20+n]),raw[28+n:]

def external_texture(path, source):
 original,original_bin=glb(source)
 if len(original['images'])!=1: raise ValueError('Inspect multi-texture sources separately')
 original_view=original['bufferViews'][original['images'][0]['bufferView']]
 pos=original_view.get('byteOffset',0)
 pixels=original_bin[pos:pos+original_view['byteLength']]
 image=Image.open(io.BytesIO(pixels)).convert('RGB')
 original_size=image.size
 image.thumbnail((args.texture_size,args.texture_size),Image.Resampling.LANCZOS)
 texture=path.with_name(path.stem+'_albedo.png')
 image.save(texture,format='PNG',optimize=True,compress_level=9)
 doc,blob=glb(path)
 view_index=doc['images'][0]['bufferView']
 view=doc['bufferViews'][view_index]
 offset=view.get('byteOffset',0)
 if view_index!=len(doc['bufferViews'])-1: raise ValueError('Image must follow all geometry buffer views')
 if any(v.get('byteOffset',0)>=offset for v in doc['bufferViews'][:-1]): raise ValueError('Unexpected buffer ordering')
 blob=blob[:offset]
 doc['bufferViews'].pop()
 doc['images']=[{'uri':texture.name}]
 doc['buffers'][0]['byteLength']=len(blob)
 encoded=json.dumps(doc,separators=(',',':')).encode()
 encoded+=b' '*((-len(encoded))%4)
 blob+=b'\0'*((-len(blob))%4)
 total=12+8+len(encoded)+8+len(blob)
 path.write_bytes(struct.pack('<III',0x46546c67,2,total)+struct.pack('<II',len(encoded),0x4e4f534a)+encoded+struct.pack('<II',len(blob),0x004e4942)+blob)
 Path(str(texture)+'.import').write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\ncompress/mode=2\ncompress/high_quality=false\nmipmaps/generate=true\n')
 Path(str(path)+'.import').write_text('[remap]\nimporter="scene"\nimporter_version=1\ntype="PackedScene"\n\n[params]\ngltf/embedded_image_handling=3\n')
 return {'texture_original_size':original_size,'texture_runtime_size':image.size,'source_texture_sha256':hashlib.sha256(pixels).hexdigest(),'runtime_texture_sha256':hashlib.sha256(texture.read_bytes()).hexdigest(),'runtime_texture_bytes':texture.stat().st_size,'texture_original_bytes_preserved':False,'texture_processing':'Lanczos downsample, RGB PNG, explicit VRAM-compressed mipmapped import'}

reports=[]
for item in json.loads(args.manifest.read_text()):
 started=time.monotonic();name=item['model'];source=Path(item['source'])
 if not re.fullmatch('[a-z0-9_]+',name): raise ValueError('Unsafe model name')
 target=args.output/name/(name+'.glb')
 if target.resolve()==source.resolve(): raise ValueError('Derivative cannot overwrite source')
 target.parent.mkdir(parents=True,exist_ok=True)
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.gltf(filepath=str(source))
 objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
 if len(objects)!=1: raise ValueError('Inspect multi-object models separately')
 obj=objects[0]
 original_triangles=sum(len(p.vertices)-2 for p in obj.data.polygons)
 bm=bmesh.new();bm.from_mesh(obj.data)
 bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-7);bm.verts.index_update()
 layer=bm.loops.layers.uv.active
 if layer is None: raise ValueError('Missing source UVs')
 pinned=set()
 for edge in bm.edges:
  if not edge.is_manifold:
   pinned.update(v.index for v in edge.verts);continue
  a,b=edge.link_loops
  if (a[layer].uv-b.link_loop_next[layer].uv).length_squared>=1e-12 or (a.link_loop_next[layer].uv-b[layer].uv).length_squared>=1e-12:
   pinned.update(v.index for v in edge.verts)
 bm.to_mesh(obj.data);bm.free()
 group=obj.vertex_groups.new(name='Protect UV boundaries')
 group.add(list(range(len(obj.data.vertices))),1.0,'REPLACE')
 if pinned: group.add(list(pinned),0.0,'REPLACE')
 modifier=obj.modifiers.new('Runtime geometry','DECIMATE')
 modifier.decimate_type='COLLAPSE';modifier.ratio=min(1,args.triangles/original_triangles)
 modifier.use_collapse_triangulate=True;modifier.vertex_group=group.name;modifier.vertex_group_factor=1.0
 bpy.context.view_layer.objects.active=obj
 bpy.ops.object.modifier_apply(modifier=modifier.name)
 count=sum(len(p.vertices)-2 for p in obj.data.polygons)
 bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',export_yup=True,export_apply=True,export_animations=False,export_materials='EXPORT')
 texture=external_texture(target,source)
 report={'model':name,'source':str(source),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'source_triangles':original_triangles,'runtime_triangles':count,'runtime_bytes':target.stat().st_size,'runtime_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'uv_pinned_vertices':len(pinned),'seconds':round(time.monotonic()-started,2),'blender':bpy.app.version_string,**texture}
 reports.append(report)
 (args.output/'derivatives.json').write_text(json.dumps(reports,indent=2)+'\n')
 print('DERIVATIVE',json.dumps(report),flush=True)
