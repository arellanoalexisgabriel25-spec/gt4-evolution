# Modelos aportados para GT4 Evolution

## Optimización 0.20 / estado actual de los recursos

Los seis modelos incorporados antes de 0.19 utilizan ahora texturas externas de
**1024×1024**, con mipmaps y compresión VRAM, igual que los siete modelos nuevos.
Se reduce el atlas de los cinco escaneos y los tres mapas PBR del Gol desde 2048²
con Lanczos. El mapa normal del Gol se renormaliza después del filtrado; se conservan
sus materiales, mapa de color y mapa de metallic/roughness independientes.
**Las imágenes derivadas no son byteidénticas a las aportadas**.

Esta optimización no vuelve a simplificar la geometría: posiciones, normales,
UV, índices, nodos y definiciones de material conservan sus datos. Los cinco
escaneos mantienen sus ~80.000 triángulos y el Gol sus 40.000. Los contornos y
pivotes visuales se siguen calculando sobre las mismas mallas; ningún dato
mecánico cambia por reducir las texturas.

El respaldo exacto de los recursos jugables de 0.19 permanece separado en
`/workspace/references/user-changes-0.20/assets-before/`. Los originales completos
de los adjuntos siguen en sus directorios históricos de referencias. El juego
distribuye únicamente los derivados y sus PNG necesarias, sin duplicar originales.
Las secciones de versiones anteriores que siguen abajo registran el estado de
cada entrega histórica, no el formato actual de 0.20.

| Recurso | GLB de 0.19, bytes | GLB + PNG de 0.20, bytes | Triángulos conservados |
| --- | ---: | ---: | ---: |
| `fiat_147` | 6,805,924 | 4,163,074 | 79,998 |
| `uno_fire` | 6,958,084 | 4,302,312 | 79,998 |
| `gol_power` | 12,272,296 | 4,517,193 | 40,000 |
| `fiat_128` | 5,866,600 | 3,309,079 | 79,998 |
| `fiat_133` | 7,282,936 | 4,188,108 | 79,998 |
| `fiat_128_standard` | 6,473,388 | 3,994,014 | 79,996 |

Total GLB + imágenes de esos seis autos: **45.659.228 → 24.473.780 bytes**
(**46,4% menos**). Recursos importados en el fixture Godot 4.6.3, escenas y
texturas referenciadas: **52.199.882 → 22.058.753 bytes** (**57,7% menos**).
Son tamaños de recursos; no se presentan como mediciones de FPS, memoria máxima
ni tamaño final del ZIP Windows, que se verifica durante el empaquetado.

`tools/optimize_runtime_textures.py` reproduce el proceso desde un manifiesto
con `model` y `source`, usando Pillow sólo al preparar recursos. Reconstruye los
buffer views y comprueba SHA256 de **todos** los bloques no imagen; rechaza cambios
de malla/material, salida sobre fuente y texturas con transparencia sin inspección.
La importación usa referencias PNG explícitas, incluidas en fuente y exportación.

```sh
python3 tools/optimize_runtime_textures.py --manifest /ruta/texture-sources.json --output /ruta/derivados
```

Verificación: importación limpia y suites visuales reales, **26 casos de insignia,
42 de clásicos y 107 de los modelos 0.19**, todos aprobados en el fixture aislado.
Se comparan también 18 vistas antes y 18 después con las mismas cámaras,
incluyendo ruedas giradas; se conservan los detalles horneados e irregularidades
de las mallas. No se añaden interiores ni deformaciones.

SHA256 de los GLB de 0.20 (los atlas PNG son recursos distintos):

- `fiat_147`: `d72b1ae695d381afc00539dc968594df1c9fbe939021b7d3b5545439287eff05`.
- `uno_fire`: `5230a94dea6bead4452acb9782c56f2b223abe5b3e9ed5e5bff981fc7aeb6959`.
- `gol_power`: `8ec3da22c0b1fb2612de3f931f27a3a726fc6a8488144147549fdd535129c248`.
- `fiat_128`: `32b7bbffa5b67e350396fe3930ad332c642edc34bb36d26d4534eeae85370505`.
- `fiat_133`: `c1fc423ff585310c92618ae350f8e788eb528c4163b2b37256d2d57ec78ddac0`.
- `fiat_128_standard`: `be55fe5e0b7393644b6b465efc6e5c7e2f80dd8f8291f2664b9a0565f1464ace`.

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
La importación inicial usó `Embed as Uncompressed`; desde 0.19 utiliza
`Embed as Basis Universal` para comprimir las texturas de la escena importada.
El GLB fuente no cambia y no requiere copias PNG externas generadas junto a él.

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


## Incorporación 0.19 / siete modelos adicionales

Se preservan los seis GLB anteriores. Se añaden Fiat 125, Duna, Cronos, Siena,
Punto, Regatta y 500. Los siete originales se conservan intactos en el directorio
separado de referencias. El 500 es visualmente Abarth; por instrucción del usuario
utiliza la ficha mecánica del **500 Sport 1.4 16V de 100 CV y seis marchas** ya aportada,
sin atribuirle la potencia de una versión Abarth. El Punto es de carrocería regional
posterior al Punto europeo 2002 del PDF: su perfil 1.4 Fire de 87 CV es estimado, no una
transcripción de esa ficha de 130 CV. La identidad visual no certifica año ni motor.

Los nuevos derivados se simplifican hacia 40.000 triángulos, fijando costuras UV;
Cronos y Punto conservan más por los límites de esas costuras. Se generan texturas
RGB PNG de 1024² a partir de las originales de 2048² con filtro Lanczos. **Las texturas
nuevas están reprocesadas**, no son byteidénticas. Las imágenes externas son recursos
explícitos del proyecto, con mipmaps y compresión VRAM; sus PNG e importaciones se
incluyen en el ZIP fuente y se comprueba que el PCK resuelva todas sus referencias.

El Gol conserva su GLB original y texturas fuente de 2048². Su importación cambia a
`Embed as Basis Universal` para reducir memoria y distribución, conservando la
geometría y los materiales PBR. El resto de GLB anteriores no se modifica.

| Modelo | Triángulos originales → derivados | SHA256 GLB original | SHA256 GLB derivado |
| --- | ---: | --- | --- |
| 125 | 500,000 → 39,998 | `e5b0f4a1b5c29c535f2ccbeea2d711247c044bb206ccde1cfa5173b3acfb6dff` | `9deb681986dce6803e5cd88b7bdf40c4deb3c1283f825d792899c7ef13aeadf4` |
| Duna | 450,000 → 39,998 | `54189607f196c0e4c564b894af1db118c9ee676705e1760c373580f4b965750d` | `330fa96c06b9f81185753292a59901e464b7e2d039bd87a89bd172cc8a147200` |
| Cronos | 500,000 → 51,432 | `7a0c5af1feeedb8023ffd273c0d80766abdd1e5f381cfbef6a94ad0186aee646` | `a510e262b0cb564253d0195cbf6eb53d4484167cd91c6ef2d1d751fbb82a2c59` |
| Siena | 350,000 → 39,998 | `5e0372ad09594e31c135d483c7dff7d9373359523ffcbd0beab4fe725e51d2dc` | `bc3111f79ac5d3b207d63d874fd0b575c906c5f1659bccec3d8846c4cdfb7899` |
| Punto | 500,000 → 40,832 | `7a20917fa0450280290166601adfae0c70bee06c0ca8c22236091cae7fb9de00` | `9dc25d46683f37ff0392d14a044758093858886799fca23588fdeca6f6a368b9` |
| Regatta | 450,000 → 39,998 | `b3e7cab593cd9965d5f818c74d54df77f5c7d35395f26f816bb8aa5229a5ae77` | `482eb397a8b2eaed3988e26428a2fdd261d5867a7487864d5465ddec2ea3b2ec` |
| 500 / aspecto Abarth | 150,000 → 39,996 | `85167682c9242a4b4f9cc2fe8dc250ec08cbf06866a3e0d6af3d3acddca57b85` | `7e62696a96a45dc9138d5f3489ea8c6e6b6b998c2b7561aeb815d95f687f2bad` |

`tools/optimize_fleet_models.py` reproduce la simplificación y textura externa
con Blender 4.3.2 y Pillow. La importación conserva la orientación +Z de las fuentes;
la escala del juego es una normalización visual estimada, no una medición real.
Los recursos no indican una licencia de autor verificable en sus metadatos;
se conservan como aportes del usuario con derechos de sus autores, sin relicenciarlos
bajo MIT. Los rigs son aproximaciones sobre escaneos, no suspensión articulada.


## Incorporación 0.22 / seis modelos regionales

Los seis GLB recibidos tienen 150.000 triángulos y una textura de 2048².
Se preservan los originales fuera del juego y se generan derivados con Blender
4.3.2, `tools/optimize_fleet_models.py`, costuras UV protegidas y texturas RGB
PNG 1024² con Lanczos. Las texturas se reprocesan y usan mipmaps/compresión VRAM.
Los derivados se distribuyen como aportes del usuario; no se relicencian bajo MIT.

La inspección visual identifica Corsa hatch cinco puertas, Amarok doble cabina,
Ranger cabina simple, EcoSport primera generación, Corolla sedán y Palio hatch
cinco puertas. El ZIP llamado «Corsa Classic» no contiene el sedán Classic.
La carrocería Amarok no identifica el motor TDI base: se mantiene explícita la
asociación mecánica provisional. El Palio no usa la ficha Weekend del compendio.

| Recurso | Triángulos derivados | SHA256 original | SHA256 derivado |
| --- | ---: | --- | --- |
| corsa | 39,996 | `60001c8d07e8f35fb16917b4e642ca5ba966c14a18584692f463435d22c48917` | `77f193d7e6e4715d2a5563442b87e6c280c8a12a0ed80a479af30ce564eeef1e` |
| amarok | 39,998 | `a44ba417e1c7ceb2f450d8daa7c8f549649634804d8465dfd15ab86f493d5ebf` | `8436078f25795d3a0c3c21487915f550e247a11074006d8fd119c6d2700638ee` |
| ranger | 39,999 | `6aa427bccbbdb4c86bbaf15410b9c628a5ff15f55a17e7cb218bbe57bac42770` | `3649ae53c09a9ddcc1cbf600e8b1515fa691ff2a098b0aee23d67de41f2f36fa` |
| ecosport | 39,996 | `3eeeb3d67eecb07a8efa997287faff44b958cfcc60a32208593d56f5d94584a6` | `ff30edaa3e7fa5a69d984439e6c3d3df7c5fae3a9739961944c24671aa7303cd` |
| corolla | 40,000 | `20dc2b921318de09c1dda358d3d393a59dcd9e651a6e2bc6d651b598e046cb93` | `8a829dfd8692032d1c5f7066545a8dbd4c08c90f029dcf29721209d6d0c8250b` |
| palio | 39,998 | `e3dbd65026aa83146c1e14059f12aa3b940f80dd1ba74089fd0167d3237c161e` | `f9a0f1e3a9d87788e6bab9e90c892459f421260c70ae74129ac6be4001e8e7e7` |

Cada visual separa cuatro ruedas mediante sobres elípticos estimados y recorte
de triángulos que interpola UV/normales. Se comprueban área de superficie,
orientación, grupos no vacíos y textura. Las caras adicionales de recorte se
cuentan aparte; la colisión sigue siendo un volumen simple independiente.
Los faros proyectan luz y los frenos reflejan rojo sobre el suelo; no se añaden
ópticas flotantes a los escaneos. No hay rig de suspensión ni deformación visual.


## Incorporación 0.23 / siete modelos y datos importados eficientes

Se añaden Yaris sedán, Ka de tres puertas de primera generación, 208 de primera
generación, Polo Classic sedán, Virtus, Onix de primera generación y Corolla Cross
(confirmado por el usuario). Las versiones y medidas del escaneo son provisionales.
Yaris, Ka, Polo y Onix no heredan automáticamente las fichas de generaciones
posteriores del compendio. El Cross usa una implementación CVT original con
relaciones y convertidor estimados; no una caja manual ficticia.

| Recurso | Triángulos originales → derivados | SHA256 original | SHA256 derivado |
| --- | ---: | --- | --- |
| yaris | 80,000 → 40,000 | `4b3a688e6666eecf6ea26eceeb6d1569b834b7098f459d01248296950db13436` | `36b3a2e0b72f0e6c350379f1fb8f77793a0b4ffcd967b2216b7cd3e7a926c1dd` |
| ka | 90,000 → 39,998 | `1b1645dfb8c3264308513b27d56490d31f8c861040dd5d7a103f60a82ac4e219` | `bad6ef1c47388c16dc0eb10ed58e4eb4ebfd02616ad338cdbf838083198e7b13` |
| peugeot_208 | 150,000 → 39,998 | `b050050409a0b08b83f008b8793d8df4bf47122ddc674e4ab8ab883f4f716729` | `351b6bba2062812bdb09c3703abf76f5fe3ee2d137b5f4b19c3a31416e9f4f10` |
| polo | 60,000 → 39,994 | `5c3bb69a418e6f36f51d4eeccc197f08c33372ef16a48d94c5f7e22f6a26c344` | `757b2674b786697a3927b4b5af6d7c82ff869a3316c3f20264bea36fa4dbf422` |
| virtus | 80,000 → 39,996 | `3a355a6658310e578e084bc7886a2332ad7f3def41ec48d73fff4e4948709b09` | `fc09c31ccd688a91e6d1868eb7e6cbe3ef9337a6c8d803dac92e37a617ff7659` |
| onix | 80,000 → 39,998 | `b7aaa4355642f6b7a46c247e1cf58171bd39f5f8da02e2358f9750d6cf9359e1` | `9b829042b5ebbbcb8005cced5e825177229c24a67c2b119c7f1e0f422c6f71c5` |
| cross | 90,000 → 39,998 | `30dc8a865debabdd40b5fdb1456d2abec388e6b31310283d23520aa1ad4b8682` | `c1991fc07104dd660622377d0a8f05d6e9f04d873c38a6129ad8bc8d8a54c53c` |

Se conservan los originales fuera del proyecto. Derivados 1024² con UV protegidas,
PNG RGB/mipmaps y sobres elípticos visuales independientes de la rueda mecánica.
Las pruebas conservan área de superficie/UV y verifican los cuatro grupos.

Las 26 importaciones omiten LOD, malla auxiliar de sombra, UV de lightmap y
generación de tangentes que el constructor del rig no consume. El constructor
sigue generando las tangentes necesarias para materiales con normal map. No
se cambian los GLB/PNG anteriores ni sus caras de máxima resolución.
El tamaño agregado de recursos importados baja de **42.460.229 a 20.812.924 bytes**
para la misma flota de 26 modelos. Es tamaño de datos importados, no FPS ni memoria
total medida. Se vuelve a comprobar la flota desde el paquete exportado.
