## Cambio

La alineación imponía embrague y freno completos en manual, por lo que R podía
aparecer seleccionada sin mover el auto después del calentamiento. Ahora conserva
los pedales del jugador, permite volver físicamente al haz y alinea al rival de
forma independiente. Un llamado vencido cancela el intento sin congelar el auto.

Se conserva el flanco de botones de mando entre observadores, se consulta hardware
conectado en vivo y se pausa/limpia entrada al perder foco. Ctrl + RePág/AvPág son
alternativas de embrague/cambios con acelerador sostenido. F3 permite comparar
entrada y orden aplicada, también durante pausa sin avanzar la mecánica.

Audio original por capas a 44,1 kHz, emisores 3D y productor independiente del
render, con pruebas de ausencia de underruns ante un bloqueo de 500 ms. Se añade
MSAA configurable y Taos de galería optimizado, sin inventar su transmisión ni
modificar ofertas o las fichas físicas existentes. Ver RELEASE-0.25.md.

## Validación

72 scripts, 96 suites y 3.651 comprobaciones; 77 capturas 1280×720. Regresión de
preparación completa con duraciones de producción, burnout, retorno en R de
6,31 m y salida al verde. Teclado/mando con eventos inyectados y 25 s completos, observador previo,
foco, persistencia y UI. Audio: 22 verificaciones de señal y 10 gráficas; la escena
nocturna real mantiene cero pérdidas en ambas voces durante la prueba.

Se verifican la exportación oficial y su mismo PCK, el proyecto recién extraído,
Actions del commit y la descarga HTTPS antes de entregar los ZIP. Las fichas y
sonoridades siguen estimadas; Windows/mando/escucha física requieren prueba en
esos equipos. Main, investigación original y partidas se preservan.
