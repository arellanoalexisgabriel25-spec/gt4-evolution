# GT4 Evolution 0.19 / Flota Fiat y duelos entre modelos

Se añaden siete modelos aportados, se permite elegir otro auto rival y se corrigen dos incoherencias mecánicas de la versión anterior. Este incremento conserva la simulación longitudinal y sus límites; no presenta los perfiles estimados como calibraciones homologadas.

## Integración de los modelos

| ID | Auto | Perfil usado | Procedencia y límites |
| --- | --- | --- | --- |
| 17 | Fiat 125 | 1.6, 90 CV aproximados, RWD | Guía aportada: 90 «caballos», 1.020 kg. Unidad CV y parámetros restantes estimados. |
| 18 | Fiat Duna | 1.7 diésel, 72 CV, FWD | Entrada Duna del informe; no representa automáticamente todos los motores/trim del modelo. |
| 19 | Fiat Cronos | 1.8, 130 CV, FWD | Potencia de la guía; masa, curva completa, relaciones y versión pendientes. |
| 20 | Fiat Siena | 1.8, 103 CV, FWD | Entrada 2007 del informe; no certifica año ni motor de la malla. |
| 21 | Fiat Punto | 1.4 Fire, 87 CV provisionales, FWD | El modelo posterior/regional difiere del Punto europeo 2002 del PDF. Se usa una estimación separada, sin atribuirle los 130 CV de esa ficha. |
| 22 | Fiat Regatta | 1.6, 100 CV, FWD | Referencia de la guía; identificación de variante y demás parámetros pendientes. |
| 23 | Fiat 500 Sport | 1.4 16V, 100 CV, 128,467115 N·m, manual de seis marchas | Instrucción expresa del usuario: usar la ficha Sport existente: 100 CV a 6.000 RPM y 13,1 kgf·m a 4.250 RPM. |

El 500 tiene emblemas y carrocería **Abarth** en el archivo suministrado. Se mantiene esa limitación visual, sin inferir turbo ni potencia Abarth. Sus 10,5 s de 0–100 y 182 km/h son referencias del informe, no velocidades impuestas al juego. El mismo criterio separa datos aportados, año/versión visual y parámetros estimados en toda la flota.

Los trece modelos aportados se seleccionan desde un desplegable de Inicio. Se conservan los diez vehículos anteriores, seis incorporaciones previas y todos sus IDs. La migración añade ofertas faltantes sin cambiar saldo, salud, propiedad, historial ni IDs ocupados. Los precios son del juego, no cotizaciones reales.

## Duelo entre autos diferentes

El garaje permite elegir rival y modelo, además de libre/clase. Vacío significa el mismo modelo que el jugador, conservando la API anterior. Un quinto argumento opcional en `start_drag` selecciona un modelo soportado; formatos inválidos se rechazan antes de modificar la selección.

Cada carril conserva su propio cuerpo de colisión, masa, caja, tracción y equipo de ABS del perfil. La réplica del rival usa salud completa sin modificar el auto del vendedor ni otorgar su propiedad al jugador. El HUD identifica el modelo rival. Al volver al garaje se mantiene la elección durante esa sesión. Continúa siendo una exhibición sin inscripción, premios ni campeonato nuevo.

## Refinamientos mecánicos

- El reparto de daño al motor distingue compartimento delantero, central y trasero. Los impactos longitudinales del 133 y del 125 ya no utilizan ciegamente la misma asignación frontal. Se conserva el total de puntos, la severidad previa, el historial y la aplicación única.
- Es un reparto aproximado por compartimento: no hay simulación estructural ni deformación visual, y no se infiere un lugar de contacto detallado a partir de una caja de colisión.
- `Manual.shift` rechaza embrague NaN, infinito o fuera de 0..1 antes de cambiar marcha, temporizadores, feedback o salud. Un intento válido sin embrague mantiene el rechazo mecánico y desgaste normal.
- ABS de las configuraciones modernas se conserva por perfil; no se copia el equipo del jugador sobre un rival diferente. El control de estabilidad no se presenta como implementado.

## Adaptación visual y distribución

Los siete originales se preservan intactos. Los derivados protegen costuras UV y apuntan a 40.000 caras; Cronos/Punto conservan más por sus costuras. Las texturas nuevas se reducen de 2048² a 1024² con Lanczos y se importan con mipmaps y compresión VRAM. Sus PNG externas son recursos explícitos que se incluyen en el proyecto y se validan dentro del PCK. Los hashes y proceso están en [assets/cars/README.md](assets/cars/README.md).

El GLB fuente del Gol permanece byteidéntico; `Embed as Basis Universal` reduce el peso/memoria de sus texturas importadas sin cambiar la geometría original. La primera compilación con trece modelos excedía 100 MiB; la optimización del recurso importado evita recortar modelos del juego para distribuirlo.

Los siete nuevos rigs usan contornos visuales configurados por rueda y recorte de triángulos sólo durante el render. Las caras que cruzan el contorno se subdividen e interpolan sus UV, de modo que el neumático gire sin arrastrar el guardabarros. Por ello se distinguen las caras originales de las caras de render: no se afirma que los conteos sean idénticos. Las pruebas comparan conservación de área y UV, y miden unos 0,22–0,37 s de construcción por auto en el fixture. Los seis modos previos se mantienen.

Los centros/radios visuales están separados de batalla y radios mecánicos. No se alteran éstos para ocultar un problema del escaneo. Persisten pequeñas irregularidades de las mallas; no es una suspensión articulada ni un modelo metrológico.

## Validación

Godot 4.6.3 en Linux: **54 scripts, 59 suites y 1.761 verificaciones aprobadas**, sin errores de importación, scripts o arranque. Incluye siete duelos nuevos completos, migración 16→23, curvas, liquidación única, modelo rival distinto, daños por compartimento, validación de embrague y compatibilidad de los autos anteriores.

Se revisaron **43 capturas reales a 1280×720**, incluidos los trece modelos, el selector de Inicio y el duelo 500 Sport contra 133. El rig nuevo suma 107 casos de área/UV/configuración y 68 de regresión de modelos previos; su construcción se midió entre 0,22 y 0,37 s por modelo en el fixture.

El empaquetado exige comparación de fuentes y ejecutable oficial, integridad de todas las entradas del PCK y **36 comprobaciones adicionales** para los trece modelos y una carrera física. Se utiliza el mismo PCK con runtime Linux y se comprueba la importación del proyecto recién extraído antes de entregar. La publicación verifica el commit exacto, CRC/SHA256 y descarga HTTPS completa; el estado de Actions se confirma en la respuesta de entrega.

En la pasada visual automatizada, el 500 registró 13,48 s de 0–100 km/h frente a los 10,5 s de referencia. El protocolo incluye conductor automatizado, cambios y 75 kg de piloto; no es todavía una calibración lograda. Las prestaciones conservan parámetros estimados y requieren calibración de masa, caja y protocolo. Windows, mando físico y GPU real requieren prueba en esos equipos; una captura de software no es un benchmark de rendimiento.

## Archivos principales

Datos: `additional_vehicle_data.gd`, `car_catalog.gd`, `economy.gd`, `stock_vehicle_specs.gd`. Gameplay: `session.gd`, `main.gd`, `drag_mode.gd`, `drag_hud.gd`, `drag_vehicle_config.gd`. Mecánica: `damage_model.gd`, `drag_actor.gd`, `manual_powertrain.gd`. Visuales: `imported_car.gd`, siete directorios de recursos y `optimize_fleet_models.py`. Entrega: herramientas de exportación/captura, lista de imágenes y este informe.

Rama de trabajo: [`feat/national-fleet-mechanical-refinements`](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/tree/feat/national-fleet-mechanical-refinements), basada en 0.18. La revisión automática de permisos falló temporalmente por cuota y luego se restableció; no se publicó durante el bloqueo. Se conserva `main`. [Comparación preparada para PR](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/compare/feat/surface-contact-classic-fiats...feat/national-fleet-mechanical-refinements?expand=1) · [Descripción](PULL_REQUEST-0.19.md). La entrega informa el resultado real de la creación por API.

Descargas separadas: [Windows](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/raw/refs/heads/downloads/v0.19/GT4-Evolution-0.19-Windows.zip) · [Proyecto Godot](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/raw/refs/heads/downloads/v0.19/GT4-Evolution-0.19-Proyecto.zip). La rama de distribución identifica el commit fuente y los archivos `.sha256` acompañan a cada ZIP.

Próximo incremento: calibrar masas/relaciones y el 0–100 con variantes exactas; materiales por componente y modelos acordes al 500 Sport/Uno de tres puertas; eventos profesionales de picadas con liquidación validada.
