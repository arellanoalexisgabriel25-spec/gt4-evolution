# GT4 Evolution 0.21 / Referencia técnica y línea visual

Se integra la guía visual aportada y se reemplaza la ficha genérica del 147 por
una variante identificada, sin borrar las marcas anteriores. Se conservan las
carreras físicas contra rival, largador automático, calentamiento, controles,
economía y partidas. El entorno 3D continúa siendo un prototipo.

## Línea visual aplicada

`GT4_UI_System.zip` contiene dirección artística y especificaciones Markdown.
Se aplica un tema compartido: fondo #0F1419, panel #1A2129, elevado #232B35,
borde #2E3845, azul acero #3A7CA5 y hover #5BA3D0. Barlow Regular/SemiBold
sustituyen la presentación condensada; Roboto Mono alinea velocidad, RPM, marcha,
tiempos y ARS. Fuentes libres con licencias OFL incluidas, mipmaps y hashes.

Inicio, concesionario, garaje, taller, tuning, carrera, movimientos, ajustes,
pausa y ambos HUDs adoptan el sistema. El mapa y la plataforma de exhibición
usan fondos oscuros. Los servicios conservan navegación de teclado/mando,
compras, guardado y selecciones. En carrera no vuelve la telemetría permanente:
la pausa conserva diagnóstico/ayuda y el HUD mantiene libre el centro.

Botones primarios/secundarios, foco, opciones/popups, inputs, listas, pestañas,
barras y sliders comparten estilos. Se verifican límites de controles a 1280×720
y 1280×800. No se añaden imágenes comerciales de GT4 ni un framework externo.
La base visual está implementada; transiciones sutiles y materiales/rigs de las
carrocerías siguen como pulido posterior. [Guía adoptada](UI-VISUAL-SYSTEM.md).

## Datos técnicos aplicados

Se leyó completo el compendio de cinco páginas, SHA256
`4aeb432f9ca26c72e09f39742fc1421921c5536286d9de40fac88a633934f1f0`.
Para 147 Vivace se adopta **1.4 BIO 1372 cc 1997, 63 CV, 10,4 kgfm = 101,98916 Nm,
807 kg y largo 3742 mm**. Catálogo/circuito y drag consumen los mismos anclajes.
La masa de ensayo suma 75 kg de piloto: 882 kg. La convención de líquidos/combustible
no está especificada; se asume masa en vacío y se declara esa limitación.

El informe anterior aporta 3000 RPM de par. El nuevo compendio no da el régimen
de potencia: 5500 RPM es **estimado**, al igual que la interpolación, relaciones,
radio de rodadura y aerodinámica. El máximo analítico de toda la curva respeta
63 CV; no se imponen velocidad, ET ni aceleración objetivo.

Se preserva la referencia específica del Uno Fire 2014 de 68 CV/5250 RPM y
11,3 kgfm/2250 RPM. Gol Trend/GL no sustituye a Gol Power. El 500 mantiene 100 CV,
13,1 kgfm y seis marchas, sin turbo, con su malla Abarth provisional. Los rangos
agrupados de masa, MT/AT o motores de otros modelos se conservan como candidatos
sin escoger variantes silenciosamente. [Revisión completa](TECHNICAL-REPORT-REVIEW-0.21.md).

## Marcas y compatibilidad

La revisión del 147 tiene su propia serie de PB. El HUD no usa tiempos de otra
ficha como objetivo; el garaje muestra los anteriores como históricos. El primer
nuevo resultado válido archiva el mejor anterior; una repetición, abandono o
resultado inválido no borra ni mejora marcas. Se preservan los tickets numéricos
y su procedencia, sin cambiarlos para adaptarlos a la nueva simulación.

Career admite campos opcionales de historial en el mismo guardado. Las partidas
sin ellos cargan; ID, modelo persistente, propiedad, créditos y desgaste permanecen.
Pruebas reales cubren JSON, validación atómica, duplicados, copias defensivas y
un duelo 147 contra Uno con liquidación y retorno al garaje. No se requiere reinicio.

## Banco y límites de fidelidad

`tools/benchmark_stock.gd` mide los trece perfiles sanos en un protocolo numérico
reproducible: piloto 75 kg, calle 20°C, asfalto seco, aire 1,225 kg/m³, cambios al 92%
del limitador y 90 s de ensayo. No es un ensayo físico de fábrica ni un replay 3D.
La velocidad a 90 s no es una máxima certificada. [Resultados y reproducción](STOCK-BENCHMARK-0.21.md).

El 500 registra 0–100 de 13,362 s en ese protocolo frente a 10,5 s de referencia;
el Uno 15,308 s frente a 13,2 s (consultar tabla exacta). Esto
mantiene visible la calibración pendiente, sin ajustar el cronómetro para
ocultar diferencias. Masa, relaciones, pérdidas, conductor y protocolo necesitan
contraste. Crr 0,008–0,010 del informe no sustituye automáticamente el 0,014 actual.

Se intentaron el canal Comunidad de las Picadas y el vivo mzLhNHNwW-I mediante
la ruta de red configurada: ambos CONNECT 403. No se vio el contenido ni se
atribuyeron maniobras/tiempos a los videos. Continúa el fundamento documental
del calentamiento delante de la línea y las luces de largada; los intervalos
25/30/1,5 s siguen siendo parámetros del juego. El regreso a línea sigue asistido.

## Validación

Godot 4.6.3: **56 scripts, 68 suites y 2.058 verificaciones aprobadas**. Incluye
referencias/unidades/picos de curva, preservación histórica, carrera medida,
interfaz funcional, foco y resolución. Se revisan 50 capturas reales 1280×720,
incluidos ficha del 147, menús, instrumentos, preparación, resultados y pausa.

La entrega confirma el proyecto recién extraído, checks del PCK, render del
mismo paquete, Actions del commit exacto y descarga HTTPS de los dos ZIP con
SHA256/CRC. El ejecutable se compara con la plantilla oficial. Windows, mando
físico y rendimiento de GPU requieren prueba en esos equipos.

Archivos principales: `technical_reference_data.gd`, `stock_vehicle_specs.gd`,
`car_catalog.gd`, `drag_vehicle_config.gd`, `drag_records.gd`, `career.gd`,
`drag_garage_session.gd`, `drag_mode.gd`, `main.gd`, `racing_theme.gd`,
`drag_hud.gd`, `race_hud.gd`, `city_map.gd`, `car_preview.gd`, fuentes,
banco y herramientas de captura/exportación. No se modifican la investigación
GT4 original ni las mallas/texturas optimizadas de 0.20.

Rama [`feat/technical-reference-calibration`](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/tree/feat/technical-reference-calibration),
basada en 0.20. [Comparación preparada para PR](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/compare/feat/drag-preparation-driver-controls...feat/technical-reference-calibration?expand=1).
Main se conserva hasta revisión/integración; la entrega informa el resultado
real de crear el PR mediante API.

[Windows](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/raw/refs/heads/downloads/v0.21/GT4-Evolution-0.21-Windows.zip) · [Proyecto Godot](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/raw/refs/heads/downloads/v0.21/GT4-Evolution-0.21-Proyecto.zip).

Próximo incremento: contrastar relaciones/masas exactas y prestaciones, regreso
manual a línea y pulido de materiales/ruedas de los modelos provisionales.
