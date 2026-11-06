# GT4 Evolution 0.25 / Pedales, largada y audio espacial

Se corrige una retención real durante el llamado a largada: en manual, el juego
imponía embrague y freno completos aunque la reversa estuviera seleccionada.
Los pedales ahora conservan su efecto después del calentamiento, y el jugador
puede regresar físicamente al haz mientras el rival alinea por separado.

## Funcionamiento corregido

- La alineación inicial sigue disponible antes del árbol. Elegir R cancela sólo
  el posicionamiento asistido del jugador: el rival conserva su propia secuencia.
  En manual, staging no sustituye el embrague ni el freno del conductor.
- También se puede seleccionar reversa después del posicionamiento inicial y
  moverse hacia atrás. Un llamado vencido cancela el intento deportivo, pero no
  congela los pedales: permite detenerse o volver sin habilitar una carrera,
  ticket, premio o reputación nuevos. R sigue preparando otro intento sin reparar.
- Mando: el mismo evento conserva su flanco entre observadores, en vez de que
  un muestreo previo lo consuma antes de llegar al cambio de marcha. El estado
  de un mando conectado se consulta en vivo; la caché queda para pruebas/eventos
  sintéticos. Perder foco pausa y limpia entradas; volver no reanuda sin orden.
- Teclado: W/C/E-Q se conservan; Ctrl y RePág/AvPág permiten otra combinación de
  embrague/cambios sin levantar acelerador. Una reasignación propia tiene prioridad
  sobre las alternativas. Se mantienen los archivos de controles anteriores.
- F3 muestra entrada de pedales, orden aplicada, acople, par y sincronización.
  En pausa también está disponible con mando. La preparación muestra recepción
  de pedales; la pasada conserva la vista compacta si no se activa el visor.

La reproducción del código exacto 0.24 falló al elegir R antes y después del
llamado. Las pruebas anteriores comprobaban reversa en calentamiento y largadas
con tiempos abreviados; no cubrían ese retorno completo. La regresión nueva usa
las duraciones de producción: 25 s para calentar, 30 s de presentación y 1,5 s de
listos, con burnout físico, retorno de 6,31 m y salida real al verde. Son parámetros
del juego, no duraciones homologadas del reglamento.

No se encontró una condición que rechace un cambio por acelerar en manual. Se
verifican W+Ctrl+E/RePág y RT+LB+A/Y a través de eventos reales de Godot, incluido
un observador previo. El visor ayuda a distinguir señal recibida y asistencia.
Las salidas por teclado y mando también recorren los 25 s completos sin un
proveedor de entrada artificial. Con embrague automático, se sostiene el freno
durante la preparación y se libera al verde, como indica la guía.
Las pruebas de eventos no certifican el rollover eléctrico ni el hardware del
usuario; no se atribuye a ese fenómeno un fallo que no se midió en su equipo.

## Audio y presentación

El motor pasa de una suma breve de tonos a una síntesis original modular a
44,1 kHz. `engine_sound_profile.gd` configura órdenes de encendido y capas;
`engine_sound_synth.gd` genera escape, admisión, resonancia, ruido filtrado,
carga/retención, turbo, limitador y señales de caja. Los perfiles distinguen
cuatro cilindros nafteros y diésel, seis en línea, bóxer y dos rotores donde
corresponde al vehículo de desarrollo. No son grabaciones ni firmas acústicas
certificadas de cada versión.

`engine_audio.gd` ubica una fuente 3D en cada vehículo y transmite instantáneas
de la física al productor de audio. La síntesis no modifica RPM, torque ni
aleatoriedad de carreras. La pausa y la salida de escena detienen el productor.
Pasaron 22 comprobaciones de señal y 10 de reproducción gráfica. En dos motores
hubo cero pérdidas de muestras con Doppler activo/inactivo, pausa/reanudación y
un bloqueo deliberado de 500 ms del hilo principal. También se comprobó la escena
nocturna real a resolución y antialiasing predeterminados, sin pérdidas en ambos
emisores. La alimentación del generador es independiente del render.

Se corrigieron dos causas de cortes: reposición ligada a los cuadros gráficos y
un búfer de 0,08 s que redondeaba a 4095 posiciones ante solicitudes de 4096 del
controlador Dummy. Se usa 0,12 s (8191 posiciones) y un productor por voz, con
instantáneas protegidas por mutex y cierre mediante señal de parada/espera.
Eso no certifica todas las latencias, dispositivos ni condiciones de hardware.

AJUSTES ofrece calidad 3D de rendimiento (MSAA apagado), equilibrada (2×, inicial)
y alta (4×). Se aplica al viewport de pista y a las nuevas vistas del showroom.
No equivale a una medición de FPS; la mejor opción depende del equipo. Se conserva
el renderizador Compatibility y los recursos optimizados anteriores.

## Taos

El GLB aportado se preserva sin modificar fuera del juego. El derivado conserva
39.998 triángulos, textura 1024² con mipmaps y cuatro ruedas animadas. Se suma a
Inicio como exhibición, separado de las 26 carrocerías manejables y las 36 ofertas.
No se inventa una caja manual o CVT para representar una automática convencional:
faltan variante, ficha y transmisión para incorporarlo a carreras de fábrica.
[Procedencia y métricas](assets/cars/vw_taos/README.md).

## Validación y límites

Godot 4.6.3 compila 72 scripts; la batería reúne 96 suites y 3.651 comprobaciones,
incluida la recepción de pedales durante pausa. Se revisan 77 capturas 1280×720.
El cierre de entrega verifica además ZIP extraído, PCK exportado y descarga pública.
El paquete exportado pasó 124 comprobaciones, 41 capturas y las 10 pruebas de
audio sobre su mismo PCK. El proyecto extraído pasó las 96 suites completas.
La captura con MSAA por software tardó 311 s localmente; en GitHub alcanzó el
límite anterior de 420 s. Se conserva la secuencia completa de 77 imágenes y
se amplía su presupuesto a 600 s para los servidores sin GPU.
Las pruebas nuevas
cubren la preparación completa, reversa, vencimiento del llamado, teclado,
mando/orden de eventos, foco, visor de pedales, señal de audio, calidad gráfica
y Taos de galería. Se mantiene la batería anterior.

La física longitudinal conserva sus ecuaciones y revisión de 0.24; no cambia
potencia ni relaciones para ocultar problemas de entrada. Las fichas y los
modelos de suspensión, diferencial y embrague siguen reducidos/estimados.
Windows, mandos físicos y escucha en distintos equipos requieren prueba humana.
La investigación original de GT4 y main se conservan.

[Arquitectura de transmisión](MANUAL-TRANSMISSION-0.24.md) ·
[Fichas y estimaciones](CALIBRATION-0.24.md).

Rama `fix/drag-controls-launch-engine-audio`, basada en 0.24.
[Comparación preparada para PR](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/compare/feat/manual-transmission-chassis-realism...fix/drag-controls-launch-engine-audio?expand=1).

[Windows](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/raw/refs/heads/downloads/v0.25/GT4-Evolution-0.25-Windows.zip)
· [Proyecto Godot](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/raw/refs/heads/downloads/v0.25/GT4-Evolution-0.25-Proyecto.zip).
Extraé todo el ZIP Windows y ejecutá `JUGAR.cmd` o `GT4Evolution.exe`.
