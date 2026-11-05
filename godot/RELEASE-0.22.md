# GT4 Evolution 0.22 / Picadas nocturnas y flota regional

El ¼ de milla tiene ambiente nocturno original, instrumental analógico compacto,
seis carrocerías nuevas y lista de trece canciones autorizadas. Se mantiene la
carrera física contra otro auto, preparación, largador automático y guardado.

## Implementación

`drag_night.gd` separa la presentación de la pista y su colisión. Postes cálidos,
fondo urbano simple, boxes iluminados y niebla ligera acompañan el recorrido.
Cuatro luces puntuales cercanas se recolocan entre postes; los demás focos son
geometría emisiva y el asfalto aproxima las manchas distantes en su shader.
Hay una luz direccional con sombra; las puntuales no generan mapas de sombra.
Los faros proyectan luz y al frenar aparece reflejo rojo detrás del vehículo.
Las ópticas del escaneo se preservan, evitando lámparas en el aire por usar
la caja envolvente como posición. No es una reproducción exacta del Gálvez.

`drag_instruments.gd` dibuja dos relojes originales de velocidad y RPM con
agujas independientes, marcha digital y limitador del vehículo. Ocupan menos
del 5% de 1280×720 y dejan libre la carretera central. ET, reacción y rival
siguen visibles; diagnóstico y controles extensos aparecen al pausar.
Las capturas de GT4 recibidas son referencia de dirección artística; no se
incorporan sus imágenes, logotipos o recursos comerciales al juego.

Se añaden **Corsa hatch 5p, Amarok, Ranger cabina simple, EcoSport, Corolla y
Palio hatch 5p**. Sus derivados pasan de 150.000 a aproximadamente 40.000
triángulos por modelo, con texturas 1024², mipmaps y ruedas separadas mediante
recorte que conserva UV, normales y área. Las subdivisiones del rig se cuentan
aparte. Los originales permanecen intactos fuera del juego. Hay 19 modelos
aportados y 29 ofertas incluyendo los modelos geométricos anteriores.

`regional_vehicle_data.gd` define cada ficha y alimenta catálogo, garaje,
configuración de pista y métricas. Se eligen variantes explícitamente
**provisionales**: Corsa 1.6 MPFI 92 CV, Amarok 2.0 TDI 140 CV/MT6/4×2,
Ranger 3.0 PowerStroke 163 CV/MT5/4×2, EcoSport 1.6 Rocam 99 CV,
Corolla XLi 1.6 110 CV y Palio hatch 1.3 MPI estimado de 72 CV.
La carrocería no certifica motor/año/versión. El Corsa recibido no es sedán;
el Palio no hereda los 115 CV del Weekend del PDF.

Las pickups usan RWD, centro de gravedad alto, mayor inercia de motor/ruedas y
respuesta turbo a bajas vueltas, con parámetros propios de presión/régimen.
La curva sana respeta la potencia declarada sin picos ocultos entre anclajes;
las prestaciones se miden, no se imponen. Masas, relaciones, radios, aerodinámica,
años y correspondencia de versión siguen pendientes de ficha exacta.
El compendio del usuario es una fuente secundaria identificada, no una
homologación ni consulta directa del fabricante. [Banco reproducible](STOCK-BENCHMARK-0.22.md).

El catálogo añade IDs 24–29 sin cambiar las 23 unidades anteriores. La migración
conserva propiedad, créditos, historial, modificaciones y salud; también respeta
IDs ocupados. Las seis nuevas fichas tienen revisión propia para sus PB.
Fábrica conserva salud, excluye mejoras y usa neumático de calle; no introduce
premios, cargos o potencia adicional. Los modos previos siguen disponibles.

`menu_playlist.gd` registra el MP3 anterior y doce canciones nuevas derivadas
como Ogg Vorbis estéreo 44,1 kHz/calidad 1. Se mantienen canciones completas;
los doce Ogg ocupan 18.972.016 bytes. El usuario confirmó autorización para
redistribuir todos los temas. Los originales se preservan por separado.
AJUSTES permite seleccionar, anterior/siguiente, aleatorio y volumen. Sólo se
carga el tema actual; terminarlo avanza la lista. El modo aleatorio usa su propio
RNG y bolsa sin repeticiones internas. El mismo reproductor permanece entre
menús y se desvanece en pista. Las preferencias opcionales migran controls_v1.
[Procedencia del audio](assets/audio/README.md) · [Modelos y hashes](assets/cars/README.md).

## Comprobación y límites

Godot 4.6.3: **61 scripts, 73 suites y 2.407 verificaciones**. Incluye seis
carreras físicas completas (ambos carriles), apoyo real de neumáticos, récords,
regreso al garaje, migración, curvas, turbo diésel, área/UV del rig, lista de
reproducción, controles, instrumentos y luces. Se generan y revisan 60 capturas
1280×720, incluidos los seis modelos, música, preparación y duelo nocturno.

El paquete se contrasta con sus fuentes y plantilla oficial; se comprueban los
19 modelos y 13 canciones desde el PCK, tres duelos físicos y el mismo PCK con
el runtime Linux. La entrega final informa el resultado real del proyecto recién
extraído, render del PCK, GitHub Actions del commit exacto y descargas HTTPS
con SHA256/CRC. Windows y mando físico requieren prueba en esos equipos.

Se corrigieron la reproducción de un solo tema en bucle, la asociación automática
de un hatch con fichas de sedán/Weekend, parámetros de turbo de nafta para las
pickups y ópticas adicionales flotantes. Las comprobaciones de neumáticos esperan
al asentamiento físico antes de consultar contacto, sin inventar apoyo.

Siguen provisionales: entorno y siluetas, carrocerías con iluminación horneada,
ópticas sin rig detallado, ruedas extraídas de escaneos, suspensión/neumáticos
simplificados, asistencia lateral y regreso asistido a línea. No hay deformación
visual ni intercambio realista de impulsos entre autos. Falta calibración con
ensayos de versiones exactas y medición en GPU real. No se afirma haber visto
los videos de YouTube bloqueados en el entorno.

## Entrega

Rama `feat/night-drag-regional-fleet-playlist`, basada en 0.21.
[Comparación preparada para PR](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/compare/feat/technical-reference-calibration...feat/night-drag-regional-fleet-playlist?expand=1).
Main se mantiene hasta revisión e integración. La creación del PR depende de
que la API de GitHub permita la operación; el informe final distingue su estado.

[Windows](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/raw/refs/heads/downloads/v0.22/GT4-Evolution-0.22-Windows.zip)
· [Proyecto Godot](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/raw/refs/heads/downloads/v0.22/GT4-Evolution-0.22-Proyecto.zip).
Extraé todo el ZIP Windows y abrí `JUGAR.cmd` o `GT4Evolution.exe`.

Próximo incremento: contrastar fichas exactas, pulir materiales/ruedas e iluminación
con pruebas humanas y ampliar el retorno a línea conservando el reglamento.
