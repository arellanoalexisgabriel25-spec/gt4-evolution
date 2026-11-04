# GT4 Evolution 0.13 / Cuarto de milla manual

El desarrollo pasa a un entorno acotado para trabajar largada, cambios, desgaste
y presentación. Se implementó una contrarreloj individual de **402,336 m** sobre
el proyecto existente, con el mismo auto comprado y preparado en el garaje.

## Implementado y comprobado

- Autódromo Sur: recta original de dos carriles, semáforo, tribuna, boxes, control,
  colores argentinos, meta y escapatoria con barrera final. Se inspira en el ambiente
  del Gálvez; no replica exactamente sus instalaciones ni usa sus gráficos.
- Entrada desde Inicio y el garaje. La práctica no cobra ni paga créditos.
- Motor con curva de par e inercia, caja manual, punto muerto, capacidad de embrague,
  inercia de ruedas, agarre longitudinal, transferencia de carga y resistencia aerodinámica.
  Datos aproximados por auto; potencia y agarre responden a salud y tuning existentes.
- C sostiene embrague, E sube y Q baja. Sin embrague, el cambio se rechaza y desgasta
  la transmisión. El corte interrumpe entrega; una reducción excesiva puede forzar
  el motor. Se comprueba calado contra el freno y recuperación en neutral.
- Árbol secuencial, rollout de 0,20 m, reacción, ET, total, 60 pies, 1/8 de milla y
  velocidad de trampa en los últimos 20,1168 m. Cruces interpolados entre cuadros físicos.
  Salida anticipada, fuera de carril, discontinuidades de movimiento y timeout invalidan.
- Ticket real, marca por unidad y frenado de llegada. Repetir o abandonar conserva
  distancia y estrés; liquidar nuevamente no duplica desgaste. Temperaturas de sesión
  y desgaste adicional de motor, caja/embrague, gomas y frenos. El HUD muestra potencia
  en rueda y pérdidas de embrague; el ticket expone el estrés de esa pasada.
- Carrocería original con biseles, llantas, detalles de puertas, luces y matrícula;
  sonido de motor sintetizado que responde a RPM/carga y se pausa con la conducción.
- Persistencia mediante el guardado existente y preferencias anteriores compatibles.
  Si E/Q/C estaban ocupadas, la migración conserva esas asignaciones y busca teclas libres.

## Validación

**Godot 4.6.3, Linux: 31 suites / 526 comprobaciones y 37 scripts de juego compilados.**
Incluye el circuito anterior, carreras, premios únicos, economía, inspecciones,
tuning, controles, guardado, nuevas pasadas manuales y compatibilidad de archivos.

Comparación determinista del modelo de referencia, con igual auto y largada:

| Técnica | ET de 402,336 m |
| --- | ---: |
| Cambios en banda | 18,655 s |
| Cambios demasiado tempranos | 20,464 s |
| Sin subir de primera | 26,532 s |
| Motor/transmisión/gomas desgastados | 21,864 s |

El ensayo de escena 3D con la unidad usada del garaje completó una pasada física
de unos **20,87 s**, con aproximadamente **112,5 km/h de trampa**, seguida de frenado,
repetición y retorno al garaje. No se deriva la llegada de una simulación de resultado.
Estas cifras prueban diferencias de esta implementación; no son fichas reales de autos.

La comprobación gráfica produce **16 capturas de 1280×720** con Mesa/llvmpipe/Xvfb:
menús y vistas anteriores, preparación, árbol, pasada manual, auto cercano, ticket
de llegada y largada en falso. También comprueba pausa de reproducción de audio.
El piloto de ensayo solo se usa en tests/captura; el modo del jugador es manual.
El reloj de captura se acelera para terminar dentro del límite, por lo que esas
imágenes no son un benchmark ni se usan como comparación de récords.

Se corrigieron la normalización numérica de tickets al cargar JSON, la explicación
del embrague durante preparación y la limpieza del piloto de captura al salir.
Windows, mando físico, sensación de conducción humana y rendimiento en GPU real
siguen pendientes de prueba.

## Archivos y arquitectura

- `drag_vehicle_config.gd`, `manual_powertrain.gd`: datos y dinámica longitudinal.
- `drag_actor.gd`, `drag_strip.gd`, `drag_mode.gd`, `scenes/drag.tscn`: cuerpo físico,
  escenario y conexión de entrada, cámaras, cronometraje y sesión.
- `drag_run.gd`, `drag_records.gd`, `drag_garage_session.gd`: reglas, récords y uso persistente.
- `drag_hud.gd`, `engine_audio.gd`, `car_visual.gd`: presentación, telemetría y audio original.
- `main.gd`, `session.gd`, `career.gd`, `control_settings.gd`: integración y migraciones.
- Cuatro suites nuevas `test_drag_*.gd`; `drag_test_driver.gd` es el piloto de ensayo.
  Capturador, empaquetador, publicador y documentación se actualizan para esta entrega.

## Límites y continuación

Hay asistencia lateral; la física no es todavía un modelo completo de automóvil.
Embrague digital progresivo, temperaturas y neumáticos son simplificaciones.
El desgaste de embrague se agrupa con transmisión, sin una pieza independiente.
Las carrocerías y el sonido siguen siendo provisionales; no hay daño por impacto,
rivales físicos ni campeonato propio para el ¼ de milla. El guardado es manual.

Próximo incremento: ajustar largada y acople con conducción humana, incorporar
relaciones y preparación específicas en taller y mejorar modelos/audio del auto
inicial antes de ampliar el escenario. La expansión de circuitos grandes queda aplazada.

Rama: `feat/quarter-mile-manual`, sobre `feat/presentation-and-camera`. Se mantiene
`main` fuera de estos cambios hasta revisión y CI comprobables. La API de GitHub
ha devuelto Forbidden; no se confirman creación de PR ni comprobaciones remotas.
La distribución se publica aparte en `downloads/v0.13`.
