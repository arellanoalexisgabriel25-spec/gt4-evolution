# Modelos aportados para GT4 Evolution

## Gol Power de tres puertas

`gol_power/gol_power.glb` procede de `base_basic_pbr.glb` en el adjunto
`4dcac1ad-7e54-4984-a0c4-b1b85f55183d.zip` enviado por el usuario para integrarlo
en el juego. El archivo se conserva sin modificar: **12.272.296 bytes**,
**40.000 triángulos**, tres texturas PBR de 2048×2048.

SHA-256: `c58f831539b3c6eee45ab26e410c2b4272e97b365e203bcf4442b5159a7cc059`.

`imported_car.gd` normaliza escala y orientación al instanciarlo y separa regiones
de rueda para animarlas. Conserva todos los triángulos, UV y material. El color de
la textura evita que los guardabarros pintados giren junto con los neumáticos.
Los pivotes visuales se calculan desde la geometría separada. La colisión utiliza
un volumen simple independiente. Las texturas ya contienen detalles y luces
horneados; no se presenta el resultado como una carrocería con deformación física.
La importación usa `Embed as Uncompressed`: las imágenes permanecen dentro de
la escena importada. No requiere copias PNG externas generadas junto al GLB.

El GLB no identifica autor ni licencia en sus metadatos, únicamente el exportador
Blender/glTF. Se conserva como recurso aportado por el usuario, con los derechos
de su autor; no se atribuye al proyecto ni se relicencia bajo MIT.

## Fiat 147 y Uno Fire

Los otros dos adjuntos, `7c067c33…zip` y `f39891b4…zip`, superan el límite de
transferencia de 32 MiB del lector. El usuario facilitó una carpeta de Drive,
pero el proxy del entorno rechazó ese destino con HTTP 403. Los dos dominios
de Drive figuran en el borrador de red y requieren aplicarse al entorno.

En esta entrega, ambos autos tienen ofertas, configuraciones y carrocerías
procedurales originales diferenciadas. **Sus modelos adjuntos todavía no se
han importado.** Las rutas previstas son `fiat_147/fiat_147.glb` y
`uno_fire/uno_fire.glb`; deben inspeccionarse los archivos antes de incorporarlos.
No se reutiliza el Gol bajo los nombres del 147 o del Uno.
