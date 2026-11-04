# GT4 Evolution 0.16 / Duelos de serie y auditoría física

El acceso principal al ¼ de milla abre una carrera contra otro auto físico. Se conserva la práctica individual. Las especificaciones se separan de la presentación y se corrigen torque, masa y transmisión. **Las cifras de fabricante y el reglamento argentino no están verificados**: los sitios solicitados están bloqueados por la red. No se inventan categorías oficiales.

## Implementado

- Dos autos físicos y cronometraje interpolado por carril. La IA usa el mismo motor, embrague y caja, accionando controles; nunca altera posición, velocidad ni potencia para alcanzar al jugador.
- Ganador por **RT + ET** desde el verde común. Falsos, fuera de carril y timeout invalidan; dos inválidos no producen ganador. Empate hasta 1 ms como resolución propia del prototipo.
- Nico técnico, Claire agresiva y Akira conservador, elegibles en el garaje; reacción, largada, dosificación y cambios diferenciados y reproducibles.
- Señales independientes en el árbol: el falso de uno no apaga el verde del otro. Pausa detiene los dos autos/relojes y R reinicia ambos, conservando desgaste.
- Seguimiento de cámara que encuadra los carriles cuando están próximos. HUD con distancia relativa y RT/ET del rival, ticket con ambas llegadas.
- Serie sin upgrades, compuestos deportivos ni ayudas del protocolo; conserva la salud y las piezas del garaje. Rival equivalente en buen estado. Exhibición sin inscripción ni premios. Práctica anterior conserva preparaciones.
- Récords de serie persistentes separados de marcas anteriores/preparadas. Campos nuevos opcionales; no se reescriben los tickets antiguos.

## Física y métricas

- Masa base más piloto explícito de 75 kg. Definición de combustible y variante exacta pendientes de fuente.
- Torque neto de cigüeñal sin segundo descuento de fricción a plena carga. Frenado de motor al levantar y cortar combustible.
- Eficiencia según dirección del flujo: en retención las ruedas ceden más potencia de la que recibe el motor; se evita generar energía.
- Potencia desde Nm × RPM × 2π / 60, kW/CV/hp y máximo analítico de la curva. Potencia de motor, eje y contacto diferenciadas; la fuerza por velocidad del chasis ya no se etiqueta como potencia al eje.
- Trabajo de motor y pérdidas de embrague/transmisión/neumáticos/frenos/carretera en joules, con pruebas de disipación. No comparar energía a través de una recuperación, que es intervención externa.
- 0–100 sobre velocidad del cuerpo con cruces interpolados, comienzo al superar 0,1 m/s y limpieza al armar: una espera/movimiento de staging no contamina la pasada.
- Ficha provisional visible con masa y potencia calculadas. `stock_vehicle_specs.gd` marca `development_estimate`, variantes pendientes y fuentes vacías; no presenta un dinamómetro real.

## Resultados del modelo, no de autos reales

Protocolo saludable, calle, serie, piloto75 kg y misma técnica reproducible:

| Perfil provisional | Masa ensayo | CV derivados | 0–100 ensayo | ET | Trampa |
| --- | ---: | ---: | ---: | ---: | ---: |
| 147 Vivace | 915 kg | 65,78 | 14,392 s | 19,334 s | 114,32 km/h |
| Uno Fire 3 puertas | 985 kg | 65,20 | 15,483 s | 19,871 s | 112,12 km/h |
| Gol Power 3 puertas | 1055 kg | 83,99 | 12,605 s | 18,468 s | 119,95 km/h |

Estas mediciones hacen auditable la simulación; **no prueban coincidencia con rendimiento de fábrica**. Motor/año/mercado, curvas, relaciones y resistencia necesitan verificación y calibración externa. [STOCK-SOURCES.md](STOCK-SOURCES.md) registra los bloqueos y requisitos. Los dominios oficiales quedaron guardados en el borrador de red, preservando Drive; todavía requieren aplicarse al entorno.

## Validación y archivos

Pruebas nativas de juez (llegada, falso, empate, timeout), IA reproducible, unidades/torque/potencia/masa/retención, dos carreras físicas completas incluyendo falsa, pausa, luces por carril, transacciones y JSON de récords. Se conserva toda la regresión anterior. El capturador produce27 PNG reales incluyendo staging, conducción y resultado del duelo. Cuenta final y CI se informan con evidencia de la entrega.

Nuevos: `stock_vehicle_specs.gd`, `drag_duel.gd`, `drag_rival_driver.gd` y cuatro suites. Modificados: configuración/motor/transmisión, actor/escena/HUD/cámara/árbol, sesión/carrera/garaje y herramientas de captura/distribución. Investigación original de GT4, GLB y MP3 aportados permanecen intactos.

## Límites y continuación

Reglamento/categorías y prestaciones reales pendientes de acceso. Duelo directo propio de serie, física longitudinal aproximada y asistencia lateral; sin diferencial izquierda/derecha, suspensión completa o deformación. Modelos adjuntos147/Uno aún pendientes, con gráficos provisionales. Windows, mando físico, conducción humana y rendimiento GPU requieren prueba.

Siguiente paso: acceder a fuentes, identificar variantes, reemplazar estimaciones por fichas/curvas verificadas y contrastar 0–100, ET y trampa en condiciones comparables antes de desarrollar preparaciones.

Rama `feat/stock-physics-head-to-head`; distribución separada `downloads/v0.16`. Main se conserva estable.
