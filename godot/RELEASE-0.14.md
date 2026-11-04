# GT4 Evolution 0.14 / Tracción, pesos y mando

El ¼ de milla recibe un modelo longitudinal de dos ejes, con torque y frenos
más coherentes. Se integran el MP3 aportado por el usuario, pesos argentinos
y navegación con mando sobre el juego existente. Se conservan mercado, taller,
tuning, carrera, circuito anterior, partidas e investigación original de GT4.

## Implementado

- Rotación, patinamiento, fuerza y temperatura independientes por eje. Carga
  delantera/trasera con transferencia longitudinal, sensibilidad a carga y salud
  de neumáticos; adherencia que cae progresivamente después de su pico.
  FWD, RWD y reparto AWD utilizan sus ejes correspondientes.
- Torque interpolado por RPM, curvas diferenciadas, respuesta de turbo bajo carga
  y pérdida de presión al levantar. Pérdidas de transmisión por tipo de tracción.
  Se mantienen inercia, embrague finito, cambios manuales, calado y sobrerégimen.
- Frenos mediante torque de rueda, reparto delantero/trasero y condición mecánica.
  ABS opcional que modula bloqueo, TCS opcional que recorta motor sin sumar agarre.
  Neumáticos, suspensión, ECU, escape y frenos del garaje afectan los parámetros.
  Las ruedas delanteras/traseras se animan con su propia velocidad.
- HUD con torque de motor, potencia en rueda, pérdidas de embrague, turbo,
  temperaturas por eje, tracción y estado de ayudas. Por defecto: TCS apagado,
  ABS encendido. Estas ayudas se configuran para el ¼ de milla.
- Todos los importes visibles en **pesos argentinos (ARS)**. Saldo inicial:
  **$ 12.000.000 ARS**. Una unidad contable histórica representa $ 1.000 ARS;
  se mantienen las proporciones y el historial sin multiplicar saldos al cargar.
  Las partidas antiguas migran sin perder dinero; metadatos incompatibles se rechazan.
  Son valores de balance del juego, sin equivalencia con un mercado real.
- Música de menú: **Lezcano Alan — PERRA #Ritmomanijero, Prod Sketchy**, MP3
  original de unos 129 s, autorizado expresamente para redistribución por el usuario.
  Bucle, volumen independiente guardado y transición al entrar/salir de pista.
  La música mantiene sus derechos propios; ver `assets/audio/README.md`.
- Mando en menús: stick/cruceta, A confirma, B vuelve y LB/RB cambia pestaña;
  izquierda/derecha ajusta opciones y volumen. La confirmación mantenida no duplica
  compras. Select/Back abre una pausa navegable con recuperación y salida al garaje.
- Embrague analógico LT/L2 opcional; B/Círculo frena de forma independiente del
  acelerador. El modo anterior LB embrague/LT freno sigue disponible. Desconectar
  el mando activo pausa el juego y libera gatillos; se puede seguir con teclado.

## Pruebas y resultados

**Godot 4.6.3, Linux: 35 suites, 593 comprobaciones, 44 scripts compilados.**
`bash tools/test_game.sh` terminó con código cero y sin errores de motor/script.
Incluye las regresiones anteriores de economía, carreras completas, premios únicos,
guardado y desgaste. Las cuatro suites nuevas suman 67 comprobaciones:

| Suite | Comprobaciones |
| --- | ---: |
| `test_axle_torque.gd` | 18 |
| `test_money_ars.gd` | 15 |
| `test_menu_music.gd` | 12 |
| `test_controller_navigation.gd` | 22 |

Con igual torque y transferencia de carga hacia atrás, el ensayo aislado produjo
**3100 N FWD / 4728 N RWD / 6667 N AWD**. Frenando desde 108 km/h, el mismo
modelo necesitó **47,53 m con neumáticos sanos y 62,58 m con desgaste**.
Las pruebas también comprueban disipación de energía en neutral, carga total
conservada, frenos desgastados, turbo transitorio y TCS sin aumento artificial de grip.

La pasada determinista de referencia midió **18,643 s** cambiando en banda,
**20,626 s** cambiando temprano, **26,493 s** sin subir marcha y **21,851 s**
con mecánica desgastada. La integración 3D con la unidad usada del garaje cruzó
físicamente la meta en unos **20,87 s**, a **113,3 km/h de trampa**, frenó,
repitió y volvió al garaje conservando desgaste. Son resultados del prototipo,
sin calibración contra mediciones reales de esos vehículos.

El capturador gráfico produce **17 PNG reales de 1280×720** mediante
Mesa/llvmpipe/Xvfb. Incluye menú en ARS, ajustes, cámaras, largada, pasada, ticket,
salida en falso y pausa con mando. Comprueba reproducción real y bucle del MP3,
silencio de música en pista y pausa del sonido de motor. Se revisaron composición,
legibilidad y contraste. El reloj de captura se acelera; no mide rendimiento.

El paquete incluye el runtime Windows oficial y su licencia, con comprobación
SHA-512 del archivo de origen. La validación funcional se realiza en Linux.
No se ha probado un mando físico ni ejecutado el juego en Windows.

## Correcciones durante la integración

- Eliminar el frenado artificial adicional sobre el chasis: ahora la desaceleración
  procede de contacto de neumáticos y torque de frenos.
- Evitar fuerzas de relajación que entreguen energía al invertirse el deslizamiento.
- Cargar el MP3 en tiempo de ejecución después de la importación, conservando
  el mismo reproductor al cambiar pestañas y regresar al garaje.
- Consumir entradas de mando antes de cambiar escena para evitar acceso a un
  viewport ya separado; liberar el foco al cerrar pausa y rechazar confirmaciones repetidas.
- Corregir el contraste del botón enfocado en la pausa y mantener las pruebas
  económicas al reemplazar mensajes/importes de la moneda anterior.

## Archivos principales

- Nuevos: `axle_traction.gd`, `engine_torque.gd`, `money.gd`, `controller_state.gd`,
  `menu_controller.gd`, `pause_menu.gd`, `menu_music.gd`, `assets/audio/` y las cuatro suites.
- Dinámica/presentación: `manual_powertrain.gd`, `drag_vehicle_config.gd`,
  `drag_actor.gd`, `drag_mode.gd`, `drag_hud.gd`, `car_visual.gd`, `racing_theme.gd`.
- Integración: `control_settings.gd`, `session.gd`, `main.gd`, `driving.gd`,
  `economy.gd`, `career.gd`, `tuning.gd`; ajustes de aserciones de texto existentes.
- Distribución: capturador, empaquetador, publicador, README y DEVELOPMENT.
  Los originales de investigación y el código de decompilación quedan preservados.

## Límites y siguiente incremento

La dirección del ¼ de milla conserva asistencia lateral. No hay diferencial entre
ruedas izquierda/derecha ni suspensión completa, daños por impacto o neumáticos
calibrados. Las temperaturas son aproximaciones de sesión y el embrague desgasta
la transmisión agrupada. Modelos geométricos y audio de motor siguen provisionales.
La práctica individual no otorga premios ni incorpora rivales físicos de drag.
El circuito anterior conserva su controlador arcade. El guardado sigue siendo manual.

Siguiente incremento: prueba humana de largada, dosificación de embrague y cambios;
preparación de relaciones/neumáticos en taller y mejoras visuales del auto inicial.
Se mantiene el entorno pequeño antes de ampliar circuitos.

Rama: `feat/traction-ars-controller-audio`, sobre `feat/quarter-mile-manual`.
Distribución independiente: `downloads/v0.14`. `main` permanece estable.
El estado de CI y la disponibilidad de PR se informan con evidencia remota;
la validación local por sí sola no los establece.
