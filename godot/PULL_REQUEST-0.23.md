## Cambio

El drag usaba gravedad distinta del controlador anterior, ignoraba normales del
suelo y regularizaba la fricción de baja velocidad de forma que podía dejar un
auto con freno rodando en una pendiente. La dinámica ahora resuelve gravedad,
carga normal, viento/aire y rodadura, con límites pasivos y frenos térmicos.
Se corrige la realimentación de velocidad al colisionar o deslizar sobre suelo.

Se añaden siete modelos optimizados y Corolla Cross con CVT/convertidor original
aproximado, controles y largador adaptados. Se preservan unidades, finanzas y
marcas históricas mediante una revisión común de física. Las 26 importaciones
omiten datos que el rig no usa, reduciendo 42,46 a 20,81 MB sin cambiar los
GLB/PNG anteriores. Ver PHYSICS-0.23.md y RELEASE-0.23.md.

## Validación

Godot 4.6.3: 65 scripts, 80 suites y 2.748 verificaciones. Siete duelos nuevos
completos, gravedad/retroceso/frenado sobre colisión 3D real, energía/temperatura,
CVT, mando, guardados y rigs. Banco numérico de 26 perfiles y 71 capturas.
Exportación comprobada con la plantilla oficial, modelos/audio del mismo PCK,
cuatro duelos físicos y render; se completa validación de ZIP recién extraído,
Actions y descargas antes de entregar al usuario.

Las fichas, convertidor y termodinámica son estimaciones; no se certifica
hiperrealismo o prestaciones de fábrica. Windows/mando físico no se ejecutan en
este entorno Linux. Main y la investigación original se conservan.
