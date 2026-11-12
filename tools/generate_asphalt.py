from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter
out=Path(__file__).resolve().parents[1]/'godot/assets/track';n=1024;rng=np.random.default_rng(42029)
# Multi-scale periodic aggregate variation. Wrap padding keeps the tile seamless.
base=rng.normal(0,1,(n,n)); noise=np.zeros((n,n),dtype=np.float32)
for size,weight in [(4,0.23),(12,0.23),(40,0.19),(128,0.17),(512,0.18)]:
 a=(rng.random((size,size))*255).astype('uint8'); im=Image.fromarray(np.tile(a,(3,3))).resize((n*3,n*3),Image.Resampling.BICUBIC);noise+=np.asarray(im.crop((n,n,2*n,2*n)),dtype=np.float32)/255*weight
flecks=np.clip(rng.normal(0,0.1,(n,n)), -0.25,0.25);height=np.clip(noise*0.75+0.12+flecks,0,1)
# High-frequency mineral aggregate remains neutral under warm circuit lights.
y=np.clip(65+(height-.5)*38,36,101);rgb=np.stack([y*0.97,y*0.99,y*1.03],axis=2).clip(0,255).astype('uint8')
Image.fromarray(rgb,'RGB').save(out/'asphalt_albedo.png',optimize=True)
gx=(np.roll(height,-1,axis=1)-np.roll(height,1,axis=1))*1.1;gy=(np.roll(height,-1,axis=0)-np.roll(height,1,axis=0))*1.1
normal=np.stack([-gx,-gy,np.ones_like(gx)],axis=2);normal/=np.linalg.norm(normal,axis=2,keepdims=True);normal=((normal*.5+.5)*255).clip(0,255).astype('uint8')
Image.fromarray(normal,'RGB').save(out/'asphalt_normal.png',optimize=True)
