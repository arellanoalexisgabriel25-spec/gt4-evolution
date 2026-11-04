# Evaluación del paquete de daños y neumáticos 0.11d

**Decisión: aporta una mejora útil, con adaptación. No se aplica como reemplazo
completo del proyecto.** Los originales del ZIP se conservaron fuera del juego
para comparar. Antes de modificar código, las pruebas suministradas de neumáticos
(33) y daños (37) pasaron en Godot 4.6.3 sobre una copia aislada del proyecto.
Esa evidencia valida sus funciones puras; no demuestra integración en una escena.

## Adoptado

- `damage_model.gd`: distribución de impacto por zona, umbral para contactos
  pequeños, máximo por choque y agrupación de cuadros consecutivos. Si un cuadro
  posterior es más fuerte, se suma la diferencia. Liquidación e historial por unidad.
- `tire_model.gd`: compuestos, curvas de temperatura/desgaste, relajación térmica,
  límites y restauración validada. Se mantienen las funciones puras reutilizables.
- Pruebas originales correspondientes, adaptadas a los cambios de balance y
  complementadas por escenarios reales, persistencia y transacciones de taller.

## Adaptaciones necesarias

El archivo `drag_run.gd` suministrado necesita un diccionario de especificaciones
en su constructor, integra su propia distancia/velocidad y ofrece cambios
automáticos por defecto. Su rollout es 0,3048 m. El existente es un cronómetro
que recibe el movimiento medido del cuerpo 3D, con rollout 0,20 m y embrague
manual. Sus interfaces son incompatibles. Sustituirlo perdería la separación
entre física y cronometraje y alteraría los tickets existentes. Se conserva el actual.

`session_settlement.gd` cierra toda la sesión una sola vez. La sesión actual
liquida diferencias acumulativas al llegar, repetir y abandonar, incluso después
de una primera llegada. Se mantiene ese mecanismo y se incorpora daño pendiente
validado antes de mover distancia o salud. El ZIP no sobrescribe los adaptadores
ni las especificaciones ya utilizadas por el juego.

La aceleración del chasis no es una medición de calor de contacto: también incluye
frenado o choque. Cada eje recibe ahora la potencia real disipada por deslizamiento,
la carga, la fuerza y la velocidad. Se calcula temperatura y desgaste por separado.
La pérdida de dibujo se suma una vez al contador acumulativo; el multiplicador
de agarre térmico excluye otro descuento por ese mismo desgaste. Tampoco se
apila el bono antiguo de neumáticos con el pico del compuesto deportivo.

La calle comienza con agarre utilizable y una ventana de trabajo más baja que
los compuestos deportivos. El paquete original colocaba su óptimo en 80 °C y
reducía aproximadamente 35% el agarre a temperatura ambiente. La entrega usa
45 °C para calle, 65 °C para deportivos y 75 °C para slick. Son parámetros de
desarrollo, sin validación de laboratorio. Los slick dan ventaja preparados,
pero tienen peor agarre en frío y mayor desgaste. No hay un botón que añada
temperatura gratis: el contacto físico produce el calor durante la conducción.

El impacto se mide entre la velocidad solicitada **después** de propulsión/freno
y la velocidad resuelta por `move_and_slide()`, solo si existe contacto de pared.
El suelo, una frenada normal o la recuperación no se cuentan como choque.
El daño afecta inmediatamente al motor, transmisión, frenos, neumáticos, agarre
y respuesta de dirección; al liquidar se conserva en la salud existente.

Se rechazan direcciones no finitas y daño pendiente inválido antes de modificar
el garaje. El informe acumulativo de la visita se conserva tras liquidar; se
distingue del desgaste normal. Reparar en taller devuelve aptitud gradualmente.

Se omiten los ayudantes que aplicaban daño por permanecer en el limitador
electrónico o por una largada genérica. El limitador no equivale a sobrerégimen
mecánico; embrague, cambios fallidos y reducciones excesivas ya tienen su propio
desgaste en `manual_powertrain.gd`. Duplicarlos penalizaría dos veces la conducción.

## Alcance comprobado

Las pruebas nuevas atraviesan colisión real, pérdida inmediata de torque,
liquidación, repetición, JSON, reparación y botón real de montaje de neumáticos.
Los tres autos insignia completan pasadas con cuerpos físicos y vuelven al garaje.
El render muestra el Gol importado en movimiento y un impacto contra la barrera
existente de la escapatoria, además del informe de componentes afectados.

La nueva simulación térmica y los daños por impacto se activan en el **¼ de milla**.
El circuito anterior conserva su controlador; lee la salud persistente y el compuesto
para su agarre base, sin incorporar aquí un nuevo sistema de colisión o temperatura.
No hay deformación visual, choque por impulso realista ni datos de neumáticos medidos.
