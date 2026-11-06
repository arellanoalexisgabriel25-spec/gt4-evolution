# Volkswagen Taos — escaneo de galería

Modelo `vw taos.glb` aportado por el usuario en este chat. La identidad del
acabado, motor, año y caja no está documentada por el archivo. Esta integración
es **visual y de galería**: no crea una oferta, rival o ficha de rendimiento ni
atribuye una caja manual a un vehículo automático. El desarrollo mecánico queda
separado hasta disponer de variante/datos y transmisión adecuados.

El original se conserva fuera del juego en
`/workspace/original-assets/vw_taos/vw_taos-original.glb`; no se sobrescribió ni se
incluye en el paquete. SHA-256:
`4bd8c8551869275d3d2c833d76d0268316dba02e3e8fbc1be9afca69723ff044`.

| Recurso | Original | Derivado |
| --- | ---: | ---: |
| Triángulos fuente | 80.000 | 39.998 |
| GLB | 7.678.144 bytes con imagen | 1.214.204 bytes sin imagen embebida |
| Textura | 2048×2048 | PNG RGB 1024×1024, 971.417 bytes |

Derivado generado con Blender 4.3.2 y `tools/optimize_fleet_models.py`: reducción
UV protegida, PNG externo por Lanczos, importación VRAM con mipmaps. No se
generan LOD, mallas extra de sombra o datos de light baking que el rig no usa.
La textura horneada aportada se usa como albedo iluminado, sin autoiluminación.
No se añaden recursos comerciales de Gran Turismo.

SHA-256 GLB derivado:
`0249388c9d28e0447eca23a5579a5c52dc497b2a9f14ebb7f0949d1b4ff876a5`.
SHA-256 PNG derivado:
`19b3b08be5bf120fa04b3e02a4536094e3e3e817e7899a11e03ab48dd8978979`.

Las dimensiones de presentación 1,84×1,63×4,46 m, la referencia de ejes 2,68 m
y los cuatro contornos de rueda son estimaciones de encuadre del escaneo, no
mediciones físicas ni fichas de fabricante. El frente se orienta a −Z. El rig
separa cuerpo/cuatro ruedas mediante recorte de triángulos con UV continuas;
se conserva el área de superficie. Los neumáticos conservan irregularidades
del escaneo. No se modificó el collider ni una configuración mecánica.

Verificación: Godot 4.6.3, prueba `tests/test_taos_visual.gd`; imágenes de frente,
trasera, lateral y ruedas giradas revisadas con render OpenGL por software.
El permiso y procedencia del recurso aportado son independientes de la licencia
MIT del código; no se presenta como recurso creado por este proyecto.
