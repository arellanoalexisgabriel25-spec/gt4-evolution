# GT4 Evolution 0.23 / Gravedad, fuerzas y CVT

Se refina la física longitudinal, se incorporan siete modelos y una CVT funcional,
y se reduce el tamaño de los recursos importados. Las carreras continúan siendo
duelos físicos de 402,336 m de noche, con largador automático y uso persistente.

## Implementado

- Gravedad común 9,81 m/s² para ambos controladores. Los cuatro rayos consultan
  normales reales; carga normal, pendiente y transferencia utilizan ese plano.
  En N el auto puede retroceder; los frenos sostienen sólo dentro del agarre y
  par disponibles. La colisión/visual se alinean de forma rígida al plano medio.
- Aire seco ideal por temperatura/presión, resistencia respecto al viento y
  rodadura por carga/superficie. Las fuerzas tienen signo y no propulsan desde
  reposo por un error de resistencia. Baseline: 20°C, 101325 Pa, viento cero.
- Límites de impulso en neumáticos y embrague. La fricción no puede inyectar
  energía por sobrepasar la sincronización dentro del paso numérico.
- Frenos con trabajo en joules, masas térmicas por eje, refrigeración y fade.
  El calor se conserva al recuperar; retener sin movimiento no fabrica calor.
  Los coeficientes y capacidades térmicas son estimaciones configurables.
- Yaris sedán, Ka 3p, 208, Polo Classic, Virtus, Onix y Corolla Cross. Hay 26
  carrocerías aportadas y 36 ofertas; se preservan los 29 IDs anteriores.
  Los modelos antiguos de Yaris/Ka/Polo/Onix no reciben fichas modernas ajenas.
- Cross 2.0 de 170 CV con CVT original aproximada: engranaje de salida, relación
  continua, convertidor con pérdidas y acople directo. D/N con E/Q detenido;
  freno para alinear. La preparación, rival y mando reconocen la automática.
- Pausa con temperatura de frenos, fuerzas, densidad, viento, pendiente y g;
  HUD en carrera libre de la telemetría extensa. La CVT muestra D y su relación.
- Configuración y garaje usan la misma revisión de marcas. Se corrige el tag
  regional que no llegaba al guardado en 0.22. Los tiempos anteriores sobreviven
  como históricos y los resultados nuevos no alteran créditos ni propiedad.

## Problemas corregidos durante la comprobación

Se reemplaza la gravedad 15 m/s² del controlador anterior por la del proyecto.
Se elimina la interacción de retención/deslizamiento de CharacterBody que
introducía movimiento en pendientes; se verifica con caída libre, retroceso y
frenado sobre un suelo 3D inclinado. Tras un impacto, la velocidad resuelta se
separa de la distancia recorrida antes del choque para evitar nueva propulsión.

El conductor de pruebas podía subir varias marchas con las RPM todavía altas
después del cambio anterior. Ahora espera sincronización, evitando atribuir ese
error del protocolo al auto. Esto no automatiza los cambios manuales del jugador.
La CVT no pide embrague o subir una marcha inexistente; LT frena incluso si la
preferencia del jugador asigna ese gatillo a embrague para autos manuales.

Las 26 importaciones pasan de 42.460.229 a 20.812.924 bytes omitiendo LOD, malla
de sombra y datos auxiliares que el constructor no usa. Se preservan los GLB/PNG
anteriores y la geometría de máxima resolución. No es una medición de FPS.
Los siete nuevos originales se preservan aparte; derivados de alrededor de
40.000 triángulos y texturas 1024² con mipmaps. [Procedencia y hashes](assets/cars/README.md).

## Comprobación

Godot 4.6.3: **65 scripts, 80 suites y 2.748 verificaciones aprobadas**. Incluye
siete nuevos duelos físicos completos, caja CVT, flujos de potencia, mando,
caída libre real, pendiente real, estabilidad térmica, contacto en aire/vacío,
pasividad, todos los rigs y compatibilidad JSON/finanzas/marcas.

Se revisan **71 capturas 1280×720** con modelos, duelo CVT y nueva telemetría.
El banco numérico mide los 26 perfiles con un protocolo identificado; no impone
prestaciones. La entrega comprueba además fuentes/plantilla/hashes del paquete,
los 26 modelos y 13 temas en el PCK, cuatro duelos, render del mismo PCK,
proyecto recién extraído, Actions del commit exacto y descarga HTTPS con CRC/SHA.
El informe final distingue los resultados efectivamente completados.

[Modelo físico y límites](PHYSICS-0.23.md) · [Banco numérico](STOCK-BENCHMARK-0.23.md).
Las fichas, cajas, neumáticos, convertidor y materiales siguen provisionales.
No hay suspensión dinámica completa, cuatro ruedas independientes, impactos con
intercambio realista de impulsos ni deformación. El regreso a línea continúa
asistido; no hay R manual. Windows/mando físico necesitan prueba en esos equipos.
No se afirma una simulación hiperrealista completa ni datos de fábrica verificados.

## Archivos e integración

Nuevos: `driving_environment.gd`, `brake_thermal.gd`, `cvt_transmission.gd`,
`expanded_vehicle_data.gd`, siete derivados y sus texturas, pruebas de gravedad,
entorno, CVT, flota/rigs, conductor y duelos. Actualizados: powertrain/ejes,
controladores, catálogo, métricas, garaje/UI/HUD, controles, importaciones,
banco y herramientas de captura/exportación. Investigación GT4 original intacta.

Rama `feat/longitudinal-physics-road-loads`, basada en 0.22.
[Comparación preparada para PR](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/compare/feat/night-drag-regional-fleet-playlist...feat/longitudinal-physics-road-loads?expand=1).
Main se preserva hasta revisión e integración; la entrega informa el estado real
si la API vuelve a bloquear la creación del PR.

[Windows](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/raw/refs/heads/downloads/v0.23/GT4-Evolution-0.23-Windows.zip)
· [Proyecto Godot](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/raw/refs/heads/downloads/v0.23/GT4-Evolution-0.23-Proyecto.zip).
Extraé todo Windows y ejecutá `JUGAR.cmd` o `GT4Evolution.exe`.

Próximo incremento: fichas y relaciones exactas, validación de conducción humana,
y evolución a cuatro ruedas/suspensión/diferenciales sin perder la comparabilidad.
