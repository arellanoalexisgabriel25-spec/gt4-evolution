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


## Fiat 128 y 133 / incorporación 0.18

Se incorporan tres recursos adicionales aportados por el usuario, sin reemplazar
los GLB anteriores de 147, Uno y Gol:

| Adjunto | Recurso integrado | Identificación |
| --- | --- | --- |
| `128 super europa.zip` | `fiat_128/fiat_128.glb` | Fiat 128 Súper Europa, sedán crema de cuatro puertas. El nombre del adjunto y la inspección visual coinciden; el GLB no certifica año o motor. |
| `133.zip` | `fiat_133/fiat_133.glb` | Fiat 133 rojo de dos puertas. |
| `2e941ec7-839f-449b-959e-b4393ae14972.zip` | `fiat_128_standard/fiat_128_standard.glb` | Sedán negro de cuatro puertas, identificado posteriormente por el usuario como **Fiat 128 estándar**. No se atribuye un año o una motorización al recurso a partir de su apariencia. |

Los originales se conservan intactos fuera del proyecto, en el directorio de
referencias de la entrega. Los tres contienen una malla, una superficie y una
textura RGB de 2048×2048 almacenada en emisión sobre albedo negro. Su orientación
original tiene el frente hacia +Z y el piso en y=0. No declaran autor o licencia
verificable en sus metadatos, únicamente el exportador Blender/glTF; se mantienen
como recursos aportados, con los derechos de sus autores, sin relicenciarlos bajo MIT.

Los derivados se prepararon con Blender 4.3.2: soldadura de posiciones coincidentes
a 1e-7 unidades, fijación de los vértices de costura UV y Decimate Collapse con
objetivo de 80.000 triángulos. Conservan **los bytes originales de las imágenes PNG**,
sin remuestreo ni repintado. Las comparativas reales de frente, atrás y perfil en
Godot conservaron siluetas y superficies sin artefactos de costura. La partición
posterior de ruedas se realiza en memoria; no modifica estos GLB.

| Modelo | Triángulos originales | Triángulos del derivado | Bytes del derivado |
| --- | ---: | ---: | ---: |
| 128 Súper Europa | 500.000 | 79.998 | 5.866.600 |
| 133 | 1.000.000 | 79.998 | 7.282.936 |
| 128 estándar | 500.000 | 79.996 | 6.473.388 |

| Modelo | GLB original SHA-256 | Derivado SHA-256 |
| --- | --- | --- |
| 128 Súper Europa | `b5ceaf48f17308aa10a3e5a12501e439569d84fe914bcab267721fc7039fd4a8` | `1676f8e9bbeb591748da289bdb5854bb149d50b853bdf4130d1c6c123f0e2fc3` |
| 133 | `b3b179c108ad4f3488363bf1ae69657ffff6bb3c73341a13614d93aae4286033` | `3a60fabda6f147b8bd5dec4113347cbaf9125ab9dff615528c3999278acd24f5` |
| 128 estándar | `d09fdc01a258e3cb2bdb7ca8d2d58312abb158801969968b5f8430bbf74f0274` | `4d29587428ffe65c44fef99b95bfb66b9234ace0f993760c59137655bda501c7` |

SHA-256 de las texturas originales, conservadas dentro de los derivados:

- 128 Súper Europa: `27ace6a02eb7ed306f7bbd3375b12ed2035dc4ffc8956426c7639a7eadb16355`.
- 133: `d8ffc57691fbf2f4b70fab8781ace05866f06d691832f64343cbe2aefb707a32`.
- 128 estándar: `f8b449fb8156a5329effff363f95eae243958c0419cea6c9e2c5cf28600392cc`.

El tercer ZIP contiene además `texture_emissive.png`, de 32.344 bytes, SHA-256
`c294d9fcae241b027a67f3adc2ace238d96a011de3c5eb034c8e88f95cd709a4`.
No está referenciado por el GLB; se conserva aparte como recurso de referencia y
no sustituye la imagen shaded embebida.

La escala, posición de ejes y tamaño visual se normalizan a los parámetros del
catálogo. Esos parámetros siguen siendo estimados donde no hay ficha dimensional:
**el GLB no es una medición métrica del vehículo ni acredita su configuración de
fábrica**. Los detalles e iluminación están horneados en las texturas; la importación
no crea cristales transparentes, un interior completo o deformación de carrocería.
La colisión utiliza volúmenes simples independientes de las mallas visuales.

Estos recursos se incluyen tanto en el proyecto fuente como en el PCK de la
exportación de juego. El paquete Windows de esta entrega utiliza una plantilla
oficial de exportación; no necesita distribuir el editor completo para ejecutar
los modelos. Los originales permanecen separados de ambos paquetes jugables.
