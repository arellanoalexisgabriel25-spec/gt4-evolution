## Cambio

La transmisión ahora separa selección, sincronización y acople: el jugador puede
mantener acelerador al pisar embrague y pedir una marcha, con tiempo/par finitos,
calor por deslizamiento, desgaste y daño por sobrerégimen. Se añade reversa manual
y R/N/D en CVT. Los intentos que no sincronizan se rechazan a neutro sin saltar RPM.

Se endurece la entrada física y el orden de eventos W+C+E/Q, se informa por qué
no sale al verde y se añaden ayudas explícitas persistentes sin cambiar el manual
por defecto. No se atribuye a 0.23 un bloqueo por acelerador que no se reprodujo.
El chasis gana cabeceo con muelle/amortiguador y envolventes de diferencial
abierto/LSD/bloqueado sobre cuatro contactos; mantiene dos inercias de eje.

Se auditan las 26 fichas y sus métricas cinemáticas sin inventar relaciones o
ajustar cronómetros. Showroom, noche, cámara y feedback se refinan conservando
la interfaz compacta. Las marcas anteriores quedan históricas en la nueva revisión.
Ver RELEASE-0.24.md, MANUAL-TRANSMISSION-0.24.md y CALIBRATION-0.24.md.

## Validación

Godot 4.6.3: 70 scripts, 87 suites y 3.497 verificaciones aprobadas, con arranque
sin errores. Banco numérico de 26 perfiles y 74 capturas 1280×720.
Las nuevas pruebas ejercitan teclado físico inyectado,
reversa CharacterBody, salida al verde, sincronización móvil/timeout, caja de seis
marchas, potencia firmada, embrague agotado y calor con refrigeración cero, ayudas
con JSON, suspensión pasiva y diferenciales con agarre desigual. Se comprueban
exportación oficial/PCK, proyecto extraído y descarga antes de compartir los ZIP.

Las relaciones, termodinámica y variantes siguen estimadas; no se certifican
prestaciones de fábrica. Windows/mando físico requieren prueba en esos equipos.
Se preservan main, los archivos originales de investigación y las partidas.
