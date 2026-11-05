# Física longitudinal 0.23 / Implementación y límites

## Fuerzas en unidades SI

`driving_environment.gd` define g = 9,81 m/s² y aire seco ideal rho = p/(287,05·T).
El escenario usa 20°C, 101.325 Pa y viento cero como baseline de desarrollo;
no se atribuyen a una medición meteorológica del Gálvez. Masa incluye piloto 75 kg.

Los cuatro rayos leen normales del suelo real. Su plano medio define tangente,
g normal = −gravedad·normal y g longitudinal = gravedad·tangente. Se calculan
peso normal m·g·cos(theta), componente longitudinal y transferencia cuasiestática
por altura del CG/distancia entre ejes. El apoyo parcial no inventa carga en otro
eje. La rueda puede descargarse totalmente, sin el antiguo mínimo artificial.

La aerodinámica usa 0,5·rho·CdA·v_rel·abs(v_rel), con v_rel respecto del viento.
Un viento de cola suficientemente fuerte puede aportar trabajo, que se distingue
de las pérdidas. Rodadura usa cargas reales por eje y superficie. Su operador
opone movimiento o absorbe la fuerza disponible en reposo; no propulsa por sí solo.
Las velocidades y ruedas admiten signo, por lo que en N el auto puede retroceder
por gravedad. **No se ha implementado marcha R ni regreso manual completo**.

La trayectoria cinemática utiliza el plano del piso, y se mide desplazamiento
real. El movimiento de CharacterBody no añade su propia aceleración de pendiente.
Su velocidad vertical se reinicia al tocar suelo; usar ese vector incompleto
introducía sesgo de movimiento. Para avance se reproyecta desplazamiento; tras
un choque se usa velocidad resuelta, evitando volver a propulsar un auto detenido.
Se consultó el código oficial Godot 4.6.3 `scene/3d/physics/character_body_3d.cpp`
para verificar este contrato; no se incorpora ni modifica ese código.

## Energía, contacto y frenos

La integración usa subpasos hasta 480 Hz. El impulso de neumático se limita por
inercia de rueda y carrocería, incluyendo ambos ejes, para no invertir slip e
inyectar energía. El acople de embrague tiene capacidad y límite de sincronización.
Las pruebas de pasividad admiten sólo redondeo relativo de vectores float32.

La baja velocidad con una rueda bloqueada usa fricción estática/limitada por
freno y contacto. No hay parada por una velocidad fija ni freno de agarre infinito.
Una pendiente que excede el cono de fricción vence incluso un pedal sostenido.
La técnica FWD de acelerador y freno de mano sigue usando ruedas delanteras
motrices y freno trasero, con patinamiento y desgaste reales del modelo.

Cada eje acumula el trabajo rotacional que realmente retira el freno. Un modelo
termal de primer orden convierte joules a temperatura con capacidad J/K y
refrigeración por aire. La eficacia baja progresivamente entre 350°C y 700°C hasta
45%; son parámetros estimados, no curvas de una pastilla medida. La capacidad
4800/2600 J/K por eje se escala por masa de carrocería/1000. Recuperar mantiene
calor y desgaste; una retención estática sin trabajo no inventa calentamiento.

El ensayo genérico de 100–0 con frenos inicialmente a 20°C o 700°C mide la
consecuencia en distancia. No representa distancia certificada de un modelo.
La pausa muestra temperaturas, fuerzas, densidad, viento, gravedad y pendiente;
la pantalla de carrera conserva los instrumentos compactos.

## Corolla Cross CVT

`cvt_transmission.gd` modela una relación variable con velocidad de cambio finita,
engranaje de salida y un mapa hidrodinámico simplificado. El régimen objetivo
varía con acelerador; la relación cambia a través del rango permitido sin escribir
velocidad ni imponer un 0–100. D/N se selecciona detenido, sin embrague manual.
La preparación se sostiene con freno y conserva el largador automático.

El convertidor multiplica par a baja relación de velocidades, limitando potencia
saliente a la de la bomba. La diferencia se registra como pérdida/energía térmica.
Con velocidades próximas se utiliza el acople directo y hay retención al levantar.
Se comprueban distintos ratios de velocidad, neutral, lanzamiento, bloqueo y una
pasada física contra un Virtus manual.

Es una implementación original **aproximada**, no reproducción verificada de un
K120. Rango, engranaje, relación final, mapa, respuesta e inercia necesitan ficha
exacta. No hay sistema hidráulico, simulación de correa, presión o refrigeración
de fluido completa; no se representa una versión híbrida. La referencia elegida
es 2.0 nafta de 170 CV del compendio aportado, con el resto de parámetros estimados.

## Comparabilidad y fidelidad pendiente

Todas las fichas añaden `longitudinal_023` a su identificación de marcas. Config,
garaje y lectura del HUD usan la misma función. Se corrige que en 0.22 el tag de
los seis regionales estaba en config pero no llegaba al guardado del garaje.
Una marca anterior permanece histórica, y sólo el primer nuevo resultado válido
la archiva. No se reescriben sus tiempos ni se alteran créditos.

El conductor determinista de pruebas espera sincronización de la marcha anterior:
antes podía encadenar cambios con RPM todavía altas, confundiendo ese error de
técnica con prestaciones. El jugador conserva el control manual de sus cambios.

Sigue siendo un modelo **longitudinal de dos ejes**, con asistencia lateral y
cuerpos cinemáticos. Faltan cuatro ruedas independientes/diferenciales detallados,
suspensión con masas no suspendidas, neumático transitorio completo, elasticidad
de transmisión, intercambio de impulsos y deformación realista. La inclinación
rígida al plano medio no sustituye esa suspensión. Motor, calentamiento y daños
mantienen aproximaciones. La consistencia física comprobada no certifica fichas
de fábrica ni convierte el prototipo en un simulador hiperrealista completo.
