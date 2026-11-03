# GT4 Evolution · v0.11

Prototipo independiente de automovilismo en Godot 4.6.3: mercado de diez autos usados, inspecciones, taller, tuning, carrera profesional y conducción arcade 3D. La investigación de GT4 se consulta como referencia; no se incluyen su ejecutable, modelos, texturas ni circuitos comerciales.

## Probar el juego

En el paquete Windows, extraé **todo** el ZIP y abrí `JUGAR.cmd`. No requiere instalar Godot. El primer arranque importa el proyecto; si falla, `DIAGNOSTICO.cmd` genera registros. El ejecutable Windows todavía requiere prueba en ese sistema; la validación automatizada se realiza en Linux.

Con el proyecto fuente, abrí `project.godot` en Godot 4.6.3 y presioná F5.

1. Comprá un auto usado en CONCESIONARIO. Podés pagar una inspección para conocer desgaste y defectos ocultos.
2. En GARAJE, elegí CONTRARRELOJ 3D para practicar, o CARRERA LIBRE 3D para correr dos vueltas contra Nico Vega y Claire Moreau sin inscripción ni premios.
3. En MODO CARRERA, la **Copa de Debutantes** ahora se disputa en pista. Cuesta 120 Cr.; el resultado real paga 700 / 400 / 200 Cr. según la llegada. Abandonar consume la inscripción y no otorga progreso. El premio solo se cobra una vez.
4. Regresá al garaje y presioná GUARDAR para conservar créditos, desgaste, carrera, rivalidades y mejores vueltas. CARGAR recupera la partida. El guardado sigue siendo manual.

El resto de los eventos de carrera continúa siendo **simulado**, indicado en sus botones. No se presentan como carreras 3D. La prueba de 10 km del garaje también es una simulación.

## Controles

| Acción | Teclas |
| --- | --- |
| Acelerar | W o ↑ |
| Frenar; marcha atrás al detenerse | S o ↓ |
| Dirección | A/D o ←/→ |
| Freno sin pedir marcha atrás | Espacio |
| Recuperar el auto en la salida | R |
| Pausar/reanudar todos los participantes y relojes | P |
| Volver al garaje; abandonar si hay carrera en curso | Esc |

En **AJUSTES** podés reasignar las siete acciones a letras, números o Espacio. Las flechas siguen disponibles; Esc conserva su función de salida/cancelación. Se rechazan teclas duplicadas y combinaciones con modificadores. Restaurar controles recupera la configuración original. Estos ajustes se guardan automáticamente y no se pierden al iniciar una partida nueva; el progreso del juego sigue guardándose manualmente.

Con un mando compatible: stick izquierdo o cruceta para girar, RT/R2 para acelerar, LT/L2 para frenar proporcionalmente, B/Círculo para reversa, X/Cuadrado para recuperar e Inicio para pausar. Se usa el primer mando conectado; permite conexión/desconexión durante la sesión. La zona muerta es ajustable entre 10% y 40%. En esta versión, volver al garaje requiere Esc o el botón en pantalla. La validación usa eventos y muestras simuladas de mando; no se ha probado con hardware físico.

La recuperación conserva las vueltas ya completadas y la distancia realmente recorrida, pero invalida la vuelta en curso. En carrera añade tres segundos de detención mientras los rivales siguen. Salir del asfalto invalida la vuelta: hay que llegar de nuevo a meta para iniciar un intento válido, o recuperar con R. Todas las vueltas requieren ocho controles de paso en orden y sentido correcto.

## Qué incluye esta versión

- Circuito del club original y cerrado, con curvas suaves, asfalto, escapatorias, carteles y barreras con colisión.
- Vehículos físicos que comparten el controlador del jugador, con aceleración progresiva, adherencia lateral limitada, derrape recuperable y respuesta diferenciada por tracción, desgaste y mejoras.
- Transmisión configurable, RPM, curva de par normalizada y pérdida progresiva de empuje cerca de la velocidad máxima.
- Transferencia de carga entre ejes, frenado limitado por neumáticos y giro limitado por agarre. Delantera, trasera e integral conservan respuestas diferentes.
- Cámara con retardo de orientación, distancia y campo visual que cambian con la velocidad, incluso al derrapar.
- IA reproducible que anticipa curvas, regula acelerador/freno, intenta adelantar por un carril libre y frena ante tráfico próximo. Habilidad, agresividad y consistencia cambian el ritmo y las pequeñas desviaciones de trayectoria. Es una primera IA de conducción; no un sistema avanzado de competición.
- Cuenta regresiva, posiciones en vivo, llegada real, resultados y abandonos. Los autos que llegan dejan de obstaculizar a quienes siguen compitiendo.
- Integración de Debutantes con inscripciones, premios únicos, reputación, licencias y memoria de enfrentamientos.
- Mejores vueltas por unidad de vehículo, guardadas con la carrera.
- Distancia fraccionaria persistente y desgaste también en recorridos menores a un kilómetro, incluso al abandonar.
- Carga JSON corregida y escritura mediante archivo temporal para conservar la partida anterior si el guardado falla. Partidas anteriores sin los campos opcionales nuevos siguen siendo compatibles; los eventos ya completados no vuelven a pagar.

## Límites actuales

La conducción es un modelo arcade provisional, no la física original de GT4. Los vehículos son geométricos; no hay modelos comerciales, sonido de motor, daños por impacto, simulación completa de neumáticos o embrague, ni circuitos adicionales. Las colisiones usan cuerpos de personaje, sin intercambio realista de impulsos. El desgaste se liquida al volver al garaje; no hay averías nuevas durante una vuelta. La IA usa seguimiento de trayectoria y selección simple de carril, con recuperación explícita si queda bloqueada. El guardado y la presentación gráfica deben seguir probándose en equipos reales.

## Desarrollo y pruebas

Desde la raíz del repositorio:

```sh
bash tools/test_game.sh
```

El runner importa el proyecto, comprueba todos los scripts con los autoloads activos, ejecuta cada suite con límite de tiempo y verifica el arranque. Usa directorios de datos temporales para no tocar partidas del jugador y rechaza errores del motor o scripts, aunque el proceso termine con código cero.

La validación incluye carreras completas con colisiones y controles de IA, pagos y abandonos, intento de premio duplicado, carga/escritura de JSON real, compatibilidad de partidas y récords. Arquitectura y decisiones: [DEVELOPMENT.md](DEVELOPMENT.md). Fuentes de investigación y límites: [REFERENCES.md](REFERENCES.md).

## Integración v0.11
Se integraron las modificaciones de dinámica y cámara aportadas en `files.zip`, preservando controles, carrera y partidas. Se añadió `speed()` al controlador, requerido por la nueva prueba, y se usa la velocidad total en el plano para que la cámara responda también durante un derrape lateral. El límite de frenado por neumáticos se aplica al freno y a los pedales de cambio de sentido; el frenado con S/B ya no se trata como propulsión sobre el eje motriz.

Los parámetros siguen siendo de balance arcade, no medidas extraídas de GT4. La validación se realiza con Godot 4.6.3, incluyendo carreras completas y la nueva suite de dinámica; el ajuste visual y la sensación de conducción necesitan prueba en el equipo del jugador.
