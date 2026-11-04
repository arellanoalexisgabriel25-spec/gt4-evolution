# GT4 Evolution 0.15 / Autos insignia, daños y neumáticos

El Gol Power aportado se incorpora al juego. El 147 Vivace y el Uno Fire de tres
puertas reciben configuraciones propias y protagonismo junto con el Gol; sus dos
modelos adjuntos siguen pendientes de acceso y usan gráficos procedurales provisionales.
Se revisó el paquete de Claude y se integraron sus módulos útiles sobre la física actual.

## Implementado realmente

- Tres ofertas insignia al principio del concesionario, selector 147 / UNO / GOL
  en Inicio y selección de vista con VER MODELO en el garaje. Masas, torque,
  relaciones de caja, distancias entre ejes y volúmenes de colisión diferenciados.
- Gol Power texturizado desde el GLB del usuario, sin modificar el archivo original.
  Se normaliza escala/orientación al instanciar; conserva **40.000 triángulos**, UV
  y material PBR. Las cuatro ruedas se separan para animación de giro y dirección.
  El refinamiento por textura evita arrastrar guardabarros pintados con las ruedas.
- Modelos del 147 y Uno: **todavía no importados**. Los ZIP `7c067c33…` y
  `f39891b4…` exceden 32 MiB. El usuario facilitó Drive, pero el proxy respondió
  CONNECT 403; los dominios están en el borrador y requieren aplicarse a la red.
  Las carrocerías visibles de esos dos autos son originales provisionales.
- Neumáticos de calle, deportivos y slick en el taller: $ 320.000, $ 650.000 y
  $ 1.400.000 ARS por juego. Montaje con validación, débito único, salud nueva,
  historial y guardado. Una confirmación repetida no compra el mismo juego nuevo.
- Temperatura y dibujo por eje, alimentados por potencia disipada en contacto.
  Calle conserva agarre desde frío; los slick rinden mejor preparados y se gastan
  más. No se duplica el efecto de desgaste ni el bono del antiguo upgrade de gomas.
- Daños por impactos físicos en el ¼ de milla: por zona y componentes, con límite
  y agrupación de cuadros del mismo choque. Se reduce rendimiento inmediatamente,
  luego salud y valor de reventa a través de los sistemas existentes. El ticket
  diferencia daño por impacto y desgaste normal. Repetir no borra ni duplica daños.
- Reparaciones existentes recuperan aptitud. Un auto no apto no puede armar otra
  pasada; sigue siendo posible regresar al taller. Salud, distancia y resultados
  sobreviven a JSON real y al guardado manual.
- Partidas y diez ofertas anteriores conservadas. La migración de ofertas es
  idempotente y no sobrescribe un ID ocupado. ARS, música y mando siguen integrados.

## Decisión sobre el archivo de Claude

**Sí aporta una mejora, con adaptación.** Sus pruebas originales de neumáticos
(33) y daños (37) pasaron antes de modificarlo, en una copia aislada con Godot.
Se adoptaron esos módulos y sus pruebas, con temperatura/contacto por eje y
validaciones adicionales. No se reemplazan cronómetro, árbol, especificaciones
ni liquidación: el ZIP usa otro constructor, integra distancia propia, habilita
cambios automáticos por defecto y cambia rollout. Su cierre único de sesión
tampoco cubre nuestras liquidaciones acumulativas de llegada/repetición/salida.

Se omitió penalizar el limitador electrónico como si fuera sobrerégimen mecánico
y sumar un segundo daño genérico por largada. El modelo actual ya contabiliza
embrague, cambios fallidos y reducciones excesivas. Evaluación completa:
[INTEGRATION-CLAUDE-0.11d.md](INTEGRATION-CLAUDE-0.11d.md).

## Pruebas

**Godot 4.6.3 en Linux: 41 suites / 742 comprobaciones, 48 scripts compilados.**
La suite completa finalizó con código cero y sin errores de motor o script.
El runner estricto importa recursos, compila los scripts,
ejecuta todas las suites con datos aislados y exige ausencia de errores de motor
y script, además de comprobar arranque. El informe de entrega identifica el
resultado final y CI; los resultados locales no sustituyen la comprobación remota.

Las seis suites nuevas cubren modelo/taller de neumáticos, daños, colisión real,
migración/catálogo/GLB y pasadas físicas de los tres autos. Se mantienen las
regresiones de economía, carrera, rivales, cámara, mando, música y guardado.
El capturador genera **24 PNG de 1280×720** con Mesa/llvmpipe/Xvfb y comprueba
reproducción de música, silencio en pista, pausa y una largada manual real del Gol.

Pasadas completas con salud 100, usando el mismo piloto de ensayo manual y
**movimiento real del cuerpo 3D**:

| Auto | ET aproximado |
| --- | ---: |
| Fiat 147 Vivace | 20,415 s |
| Fiat Uno Fire 3 puertas | 21,030 s |
| Volkswagen Gol Power 3 puertas | 19,149 s |

Cada pasada verifica staging, meta, ticket para la unidad correcta, ausencia
de daños inventados, frenado seguro, fondos sin premio y retorno al garaje.
Estas cifras prueban diferencias del prototipo; no son registros de autos reales.
Las capturas aceleran el reloj y no sirven para comparar ET ni medir rendimiento.

## Archivos y problemas corregidos

- Nuevos: `car_catalog.gd`, `imported_car.gd`, `assets/cars/`, `tire_model.gd`,
  `damage_model.gd` y seis suites de prueba.
- Modificados: `economy.gd`, `tuning.gd`, `handling.gd`, `drag_vehicle_config.gd`,
  `axle_traction.gd`, `manual_powertrain.gd`, `drag_actor.gd`, `drag_garage_session.gd`,
  `drag_mode.gd`, `drag_hud.gd`, `car_visual.gd`, `vehicle_actor.gd`, `main.gd`, `session.gd`.
- Adaptadas las comprobaciones de cantidad/selección de ofertas y de configuración
  de neumáticos; el conjunto original de transacciones sigue comprobándose.
- Capturador, empaquetador y publicador incluyen nuevas vistas y el GLB.
  Documentación de procedencia y evaluación añadidas. Originales de GT4 preservados.
- Correcciones: guardabarros que podían girar con las ruedas, pivotes que causaban
  oscilación visual, texto enfocado del menú, servicios recortados por la nueva
  presentación, cabecera de daños separada del desgaste y rechazo atómico de NaN.

## Límites y continuación

Falta importar e inspeccionar los modelos adjuntos del 147 y del Uno cuando
Drive resulte accesible. El Gol conserva el detalle y las luces horneados del
archivo; no hay deformación visual. Los daños y el modelo térmico nuevo se activan
en el ¼ de milla. El circuito anterior mantiene su controlador arcade. Hay asistencia
lateral, temperaturas y parámetros aproximados; no se simulan suspensión completa,
diferenciales izquierda/derecha o choques por intercambio realista de impulsos.
Windows, conducción humana, mando físico y rendimiento GPU siguen pendientes.

Siguiente incremento: completar los dos modelos pendientes, revisar con conducción
humana el acople/temperatura y ampliar la preparación de relaciones en taller.
Se conserva el entorno pequeño y las garantías de guardado/economía.

Rama: `feat/flagship-cars-tires-damage`, sobre `feat/traction-ars-controller-audio`.
Distribución: `downloads/v0.15`; `main` se conserva estable.
