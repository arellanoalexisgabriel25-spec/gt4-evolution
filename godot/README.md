# GT4 Evolution · v0.14 / Tracción, pesos y mando

Prototipo independiente de automovilismo en Godot 4.6.3. El desarrollo se centra ahora en un **¼ de milla de 402,336 m**, con largada, cambios manuales, marcas y desgaste en un entorno original inspirado en el ambiente del autódromo Gálvez. Conserva mercado, garaje, taller, tuning y los modos anteriores. La investigación de GT4 se consulta como referencia; no se incluyen su ejecutable, modelos, texturas ni circuitos comerciales.

## Novedades v0.14

- El ¼ de milla calcula por separado la rotación, patinamiento, carga y temperatura de los ejes delantero y trasero. La transferencia de peso reduce la tracción delantera al acelerar y aumenta la carga trasera. FWD, RWD y AWD responden de forma diferente.
- Curvas de torque por RPM, carga progresiva del turbo, pérdidas de transmisión y frenado por torque en las ruedas. Salud, neumáticos, frenos, suspensión y mejoras existentes afectan el modelo. El control de tracción recorta motor; el ABS modula los frenos. Ambos se eligen en AJUSTES para el ¼ de milla; por defecto TCS está apagado y ABS encendido.
- **Pesos argentinos:** saldo, precios, reparaciones, premios y movimientos se expresan con `$` y `ARS`. El saldo inicial es **$ 12.000.000 ARS**. Cada unidad contable anterior representa $ 1.000 ARS; se conservan proporciones y partidas sin multiplicar otra vez al cargar. Son precios del juego, sin cotización real.
- **Música de menú:** Lezcano Alan — PERRA #Ritmomanijero, Prod Sketchy. Se incluye el MP3 original aportado y autorizado para redistribución por el usuario. Se reproduce en bucle, tiene volumen independiente en AJUSTES y se desvanece al entrar en pista. Créditos y alcance de derechos en [assets/audio/README.md](assets/audio/README.md).
- Mando para menús, compras, ajustes y pausa: stick/cruceta navega, A/Cruz confirma, B/Círculo vuelve y LB/RB cambia pestaña. Izquierda/derecha modifica opciones y volumen. **Select/Back** abre una pausa con Continuar, Recuperar y Volver al garaje. Desconectar el mando activo pausa la conducción y libera los gatillos.

Informe técnico, archivos y resultados: [RELEASE-0.14.md](RELEASE-0.14.md).

## Nuevo modo: ¼ de milla manual

Comprá un auto y elegí **GARAJE → ¼ DE MILLA / MANUAL**. También hay acceso desde Inicio cuando tenés un vehículo. La práctica no cobra inscripción ni paga premios; registra distancia, desgaste y mejor ticket por unidad.

1. El auto arranca en **N**. Mantené **C** (embrague), tocá **E** para primera y seguí sosteniendo C.
2. **Enter** arma el semáforo. Regulá W para preparar las RPM; probá primero una largada alrededor de 3000–4000 RPM.
3. Esperá el verde y soltá C para largar. El cronómetro distingue reacción y ET; salir antes invalida la marca.
4. Para subir marcha, soltá W, pisá C, tocá E, soltá C y volvé a acelerar. Q baja marcha. El indicador avisa al entrar en la zona de cambio, pero la operación la realiza el piloto.
5. La meta entrega ticket y frenado asistido en la escapatoria. **R** prepara otra pasada y conserva uso, desgaste y temperatura de la sesión. **Esc** vuelve al garaje; presioná **GUARDAR** para conservar progreso y récords.

Cambiar temprano lleva el motor a una zona de menor entrega; quedarse en el corte interrumpe la potencia. Un cambio sin embrague se rechaza y desgasta la transmisión. Una reducción excesiva puede llevar el motor a sobrerégimen; soltar el embrague a bajas RPM contra el freno puede calarlo. R permite recuperar y arrancar de nuevo. El modelo usa masa, par, relaciones, inercia de motor y ruedas, capacidad de embrague, resistencia aerodinámica, agarre y transferencia longitudinal de carga. Los parámetros de cada auto son **aproximaciones de desarrollo**, sin validación contra mediciones reales.

El HUD muestra RPM, marcha, torque de motor, potencia transmitida a las ruedas, pérdidas de embrague, carga de turbo, temperaturas de ambos ejes, tracción y ayudas. El ticket incluye ET, reacción, total, 60 pies, 1/8 de milla y velocidad media en los últimos 20,1168 m. El reloj parte cuando el auto libera el haz de salida tras 0,20 m de rollout; los tiempos de paso se interpolan entre cuadros físicos. Salirse del carril, saltarse la salida o una discontinuidad de posición invalida el intento.

El desgaste adicional del motor, transmisión/embrague, neumáticos y frenos se aplica al auto existente. Repetir, abandonar o volver a llamar la liquidación no lo borra ni lo duplica. El tuning existente modifica potencia y agarre. Las temperaturas son una aproximación de sesión; el guardado conserva salud y marcas, sin una simulación térmica persistente.

Las diez acciones de teclado se reasignan en AJUSTES. Las preferencias anteriores migran: si E, Q o C ya estaban ocupadas, se preserva la asignación anterior y se elige otra tecla libre para la nueva acción. Consultá AJUSTES para conocer tus teclas.

Mando en este modo: RT/R2 acelera, LT/L2 o B/Círculo frena, LB/L1 sostiene embrague, A/Cruz sube, Y/Triángulo baja, X/Cuadrado recupera, RB/R1 cambia cámara y R3 mira atrás. Inicio arma el árbol durante preparación y pausa/reanuda durante la pasada; Select/Back abre la pausa en cualquier momento. AJUSTES permite usar **LT/L2 como embrague analógico**: en ese modo B/Círculo frena, también si se mantiene el acelerador. LB sigue disponible. La opción solo afecta al ¼ de milla. El stick izquierdo conserva asistencia de dirección; el mando físico sigue pendiente de prueba.

El escenario se llama **Autódromo Sur**: tribuna, boxes, control, colores argentinos, semáforo y una escapatoria de más de 250 m. Es un diseño original inspirado en un ambiente de autódromo porteño; no es una reproducción exacta ni homologada del Gálvez. El sonido de motor es sintetizado y provisional. Las carrocerías incorporan bordes achaflanados, llantas, detalles de puertas, luces y matrícula originales; siguen siendo modelos geométricos de desarrollo.

## Probar el juego

En el paquete Windows, extraé **todo** el ZIP y abrí `JUGAR.cmd`. No requiere instalar Godot. El primer arranque importa el proyecto; si falla, `DIAGNOSTICO.cmd` genera registros. El ejecutable Windows todavía requiere prueba en ese sistema; la validación automatizada se realiza en Linux.

Con el proyecto fuente, abrí `project.godot` en Godot 4.6.3 y presioná F5.

1. Comprá un auto usado en CONCESIONARIO. Podés pagar una inspección para conocer desgaste y defectos ocultos.
2. En GARAJE, elegí CONTRARRELOJ 3D para practicar, o CARRERA LIBRE 3D para correr dos vueltas contra Nico Vega y Claire Moreau sin inscripción ni premios.
3. En MODO CARRERA, la **Copa de Debutantes** se disputa en pista. Cuesta $ 120.000 ARS; el resultado real paga $ 700.000 / $ 400.000 / $ 200.000 ARS según la llegada. Abandonar consume la inscripción y no otorga progreso. El premio solo se cobra una vez.
4. Regresá al garaje y presioná GUARDAR para conservar saldo, desgaste, carrera, rivalidades y mejores vueltas. CARGAR recupera la partida. El guardado sigue siendo manual.

El resto de los eventos de carrera continúa siendo **simulado**, indicado en sus botones. No se presentan como carreras 3D. La prueba de 10 km del garaje también es una simulación.

## Controles del circuito del club

| Acción | Teclas |
| --- | --- |
| Acelerar | W o ↑ |
| Frenar; marcha atrás al detenerse | S o ↓ |
| Dirección | A/D o ←/→ |
| Freno sin pedir marcha atrás | Espacio |
| Recuperar el auto en la salida | R |
| Pausar/reanudar todos los participantes y relojes | P |
| Cambiar entre seguimiento, cercana, capó y paragolpes | Tab |
| Mirar atrás mientras se mantiene presionada | Shift |
| Volver al garaje; abandonar si hay carrera en curso | Esc |

En **AJUSTES** podés reasignar las acciones a letras, números o Espacio. Las flechas siguen disponibles; Esc conserva su función de salida/cancelación. Se rechazan teclas duplicadas y combinaciones con modificadores. Restaurar controles recupera la configuración original. Estos ajustes se guardan automáticamente y no se pierden al iniciar una partida nueva; el progreso del juego sigue guardándose manualmente.

Con un mando compatible: stick izquierdo o cruceta para girar, RT/R2 para acelerar, LT/L2 para frenar proporcionalmente, B/Círculo para reversa, X/Cuadrado para recuperar e Inicio para pausar. Select/Back abre también la pausa, desde donde se puede volver al garaje. Se selecciona el mando al recibir una entrada significativa; la desconexión del mando activo pausa la sesión. La zona muerta del stick es ajustable entre 10% y 40%; los gatillos descartan el primer 4%. La validación usa eventos y muestras simuladas de mando; no se ha probado con hardware físico.

RB/R1 cambia de cámara, Y/Triángulo permite mirar atrás y el stick derecho mueve la vista. En AJUSTES se guardan la cámara inicial y la intensidad de dirección del teclado (40–100%, por defecto 80%); el mando conserva su rango completo. La entrada de dirección se vuelve más gradual a alta velocidad y el volante recupera el centro con mayor rapidez al soltarlo.

La recuperación conserva las vueltas ya completadas y la distancia realmente recorrida, pero invalida la vuelta en curso. En carrera añade tres segundos de detención mientras los rivales siguen. Salir del asfalto invalida la vuelta: hay que llegar de nuevo a meta para iniciar un intento válido, o recuperar con R. Todas las vueltas requieren ocho controles de paso en orden y sentido correcto.

## Qué incluye esta versión

- Circuito del club original y cerrado, con curvas suaves, asfalto, escapatorias, carteles y barreras con colisión.
- Vehículos físicos que comparten el controlador del jugador, con aceleración progresiva, adherencia lateral limitada, derrape recuperable y respuesta diferenciada por tracción, desgaste y mejoras.
- Transmisión configurable, RPM, curva de par normalizada y pérdida progresiva de empuje cerca de la velocidad máxima.
- Transferencia de carga entre ejes, frenado limitado por neumáticos y giro limitado por agarre. Delantera, trasera e integral conservan respuestas diferentes.
- Cuatro cámaras con retardo de orientación, distancia y campo visual que cambian con la velocidad, incluso al derrapar. El seguimiento conserva la distancia al trasladarse rápido y acorta su brazo ante paredes. Capó y paragolpes tienen planos de recorte cercanos; paragolpes oculta la carrocería propia.
- Inicio con mapa original de servicios, paneles plateados y azules, tipografía Barlow Condensed con licencia OFL y presentación 3D giratoria del auto. Concesionario en tarjetas, navegación lateral y garaje conservan las transacciones existentes.
- HUD compacto de velocidad, RPM, marcha, cronómetro, mejor vuelta, posiciones y cámara; minimapa del trazado real con jugador y rivales; ayuda extensa al detenerse o pausar. Autos procedurales con cristales, faros, ruedas animadas, dirección y movimiento de carrocería. Pista con cielo, sombras, materiales, tribuna y paisaje originales.
- IA reproducible que anticipa curvas, regula acelerador/freno, intenta adelantar por un carril libre y frena ante tráfico próximo. Habilidad, agresividad y consistencia cambian el ritmo y las pequeñas desviaciones de trayectoria. Es una primera IA de conducción; no un sistema avanzado de competición.
- Cuenta regresiva, posiciones en vivo, llegada real, resultados y abandonos. Los autos que llegan dejan de obstaculizar a quienes siguen compitiendo.
- Integración de Debutantes con inscripciones, premios únicos, reputación, licencias y memoria de enfrentamientos.
- Mejores vueltas por unidad de vehículo, guardadas con la carrera.
- Distancia fraccionaria persistente y desgaste también en recorridos menores a un kilómetro, incluso al abandonar.
- Carga JSON corregida y escritura mediante archivo temporal para conservar la partida anterior si el guardado falla. Partidas anteriores sin los campos opcionales nuevos siguen siendo compatibles; los eventos ya completados no vuelven a pagar.

## Límites actuales

La conducción del circuito sigue siendo arcade. El ¼ de milla añade un modelo longitudinal con embrague y cambios manuales, asistencia lateral y temperaturas simplificadas. Los vehículos son geométricos y el sonido sintetizado es provisional; faltan daños por impacto, modelos detallados y simulación completa de neumáticos y embrague. Las colisiones usan cuerpos de personaje, sin intercambio realista de impulsos. El ¼ de milla es una contrarreloj individual; no incluye todavía rivales físicos ni campeonatos propios. Se revisan capturas reales a 1280×720 con Mesa/llvmpipe en Linux; faltan conducción humana, Windows, mando físico y mediciones de rendimiento en GPU real.

## Desarrollo y pruebas

Desde la raíz del repositorio:

```sh
bash tools/test_game.sh
```

El runner importa el proyecto, comprueba todos los scripts con los autoloads activos, ejecuta cada suite con límite de tiempo y verifica el arranque. Usa directorios de datos temporales para no tocar partidas del jugador y rechaza errores del motor o scripts, aunque el proceso termine con código cero.

La validación incluye carreras completas con colisiones y controles de IA, pagos y abandonos, intento de premio duplicado, carga/escritura de JSON real, compatibilidad de partidas y récords. Arquitectura y decisiones: [DEVELOPMENT.md](DEVELOPMENT.md). Fuentes de investigación y límites: [REFERENCES.md](REFERENCES.md).

## Integración v0.11
Se integraron las modificaciones de dinámica y cámara aportadas en `files.zip`, preservando controles, carrera y partidas. Se añadió `speed()` al controlador, requerido por la nueva prueba, y se usa la velocidad total en el plano para que la cámara responda también durante un derrape lateral. El límite de frenado por neumáticos se aplica al freno y a los pedales de cambio de sentido; el frenado con S/B ya no se trata como propulsión sobre el eje motriz.

Los parámetros siguen siendo de balance arcade, no medidas extraídas de GT4. La validación se realiza con Godot 4.6.3, incluyendo carreras completas y la suite de dinámica; la sensación de conducción necesita prueba humana.

## Presentación v0.12

La estética toma como referencia los menús clásicos de automovilismo, usando gráficos y geometría originales. Las preferencias anteriores y las partidas siguen siendo compatibles. Regresar de la pista abre directamente el garaje y recuerda guardar; no cambia las reglas de premios ni el guardado manual.

Las pruebas cubren las vistas, dirección, preferencias, navegación, transacciones y HUD; también pasadas manuales completas, diferencias de cambio y desgaste, semáforo, reacción, parciales, marca única por intento y compatibilidad de guardado. v0.14 añade torque y ejes, frenado, moneda, música y navegación con eventos de mando. Para producir diecisiete capturas en un entorno con pantalla OpenGL:

```sh
LIBGL_ALWAYS_SOFTWARE=1 bash tools/capture_presentation.sh /ruta/absoluta/capturas
# En Linux sin escritorio, anteponer: xvfb-run -a env
```

Ejecutá el comando desde la raíz del repositorio. Los datos se aíslan en un directorio temporal. Las capturas muestran los menús, las cámaras, la parrilla del club y una pasada manual de ¼ de milla hasta el ticket, además de una largada en falso y la pausa con mando. Se comprueban reproducción real del MP3, transición a silencio en pista y pausa del audio de motor. El piloto de ensayo vive en `tests/`, no está activado en el modo del jugador. La captura acelera el reloj para terminar la pasada dentro del límite; no es una prueba de rendimiento ni una medición para comparar récords. GitHub Actions publica las imágenes como artefacto cuando finaliza la comprobación gráfica.
