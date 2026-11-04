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

## Fiat 147 y Uno Fire / incorporación 0.17

Los ZIP nuevos `base_basic_shaded.zip` y `base_basic_shaded (1).zip` sí pudieron
transferirse. La inspección de malla, atlas y vistas reales identifica al primero
como **Uno Fire de cinco puertas** y al segundo como **147 Vivace**. El catálogo
sigue apuntando a un Uno de tres puertas: el recurso visual aportado es una
referencia provisional y no acredita esa variante. No se borran puertas del modelo
ni se cambia su ficha mecánica para justificar el aspecto.

Cada original contiene **1.000.000 de triángulos** y una textura de 2048² almacenada
en emisión. Se preservan intactos fuera del juego en el directorio de referencias;
la distribución incluye derivados de **79.998 triángulos por auto**. El Gol original
permanece sin cambios. Todos los modelos son exclusivamente visuales; la colisión
usa un volumen simple separado.

La simplificación con Blender 4.3.2 suelda posiciones coincidentes a 1e-7 unidades
y fija vértices de costura UV antes de Decimate Collapse, objetivo 80.000 triángulos.
La primera prueba sin protección UV dejó pequeñas marcas negras y se descartó.
Los derivados finales conservan **los bytes originales de cada imagen PNG**; no se
reescalan ni se repintan. Se revisaron comparativas reales de frente, atrás y perfil.

`tools/optimize_flagship_models.py` permite reproducir el proceso con los originales
extraídos en `model-1/` y `model-2/`:

```sh
blender --background --python tools/optimize_flagship_models.py -- --sources /ruta/originales --output /ruta/derivados
```

El importador clona sólo los materiales basados exclusivamente en emisión y utiliza
su misma imagen como albedo iluminado, con emisión apagada. No modifica la escena
importada ni el material PBR del Gol. Las ruedas se separan en memoria conservando
todos los triángulos del derivado y las UV. Las imágenes permanecen embebidas en
la importación (`gltf/embedded_image_handling=3`), sin dependencias PNG externas.
La escala y orientación se normalizan al catálogo; no constituyen medidas del auto.

| Modelo | GLB original SHA-256 | Derivado SHA-256 | Bytes derivado |
| --- | --- | --- | ---: |
| Uno Fire | `899fd2ed2c32f20137874ddd72a5e93ea9a63993aa95a99dff3272ed94812abd` | `c48e3dc3c4bc7dc36be2c7f26e3e920e187dd189087d77a7d49819750be8ff7b` | 6.958.084 |
| 147 Vivace | `4f593961394820140744df279a6420abda66d1626f5328f611b78c93a72227f8` | `ab9dc49629df9192dced6197dcd6d36429bacea7903379942c4c4e8d657b6c07` | 6.805.924 |

Textura Uno SHA-256: `eb912982038a62a761b3db06cddad1066d0a2ea080ae73b13eeb977bf613b481`.
Textura 147 SHA-256: `217633bf0a962f2c22006ab8f35bef939b63daad53b5244a21189a4df776d501`.

Los recursos nuevos no identifican licencia o autor verificable en sus metadatos.
Se registran como aportes del usuario para su integración y conservan los derechos
de sus autores; no se atribuyen al proyecto ni se relicencian bajo MIT.
