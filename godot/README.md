# GT4 Evolution · v0.25 / Pedales, largada y audio espacial

Prototipo independiente de automovilismo en Godot 4.6.3. El desarrollo se centra en un **¼ de milla de 402,336 m contra otro auto físico**, con largada, cambios manuales, marcas y desgaste en un entorno original inspirado en el ambiente del autódromo Gálvez. Conserva mercado, garaje, taller, tuning y los modos anteriores. La investigación de GT4 se consulta como referencia; no se incluyen su ejecutable, modelos, texturas ni circuitos comerciales.

## Novedades v0.25

En manual, la alineación deja de imponer embrague y freno después del calentamiento.
La reversa permite volver físicamente al haz; el rival alinea de forma independiente.
También se conserva control de pedales tras un llamado vencido, sin reabrir el intento.
Se corrige la pérdida de botones de mando entre observadores y se limpia la entrada
al perder foco. Las pruebas nuevas recorren la preparación completa de 25 segundos.

**Ctrl + RePág/AvPág** ofrece otra combinación de embrague/cambios con W mantenida.
C y E/Q siguen disponibles. **F3** muestra pedales recibidos y aplicados; la pausa
lo ofrece también con mando. La pasada normal conserva el centro libre.

Audio original por capas a 44,1 kHz, fuentes 3D por vehículo y perfiles de motor
diferenciados. Es síntesis provisional, sin grabaciones verificadas por modelo.
AJUSTES añade calidad 3D con MSAA apagado, 2× o 4×. El Taos aportado se suma como
exhibición optimizada hasta identificar su variante y transmisión para carreras.
[Correcciones y validación](RELEASE-0.25.md).

## Estado histórico: novedades v0.24

Caja manual separada del embrague: sincronización con tiempo y par finitos,
reversa real, acople progresivo, pérdida por patinamiento, temperatura y desgaste
persistente. El acelerador, freno y embrague son entradas independientes: se puede
cambiar con W+C+E/Q y hacer punta-tacón. Mal acople, cambios rechazados y
sobrerégimen tienen consecuencias; el limitador no protege una reducción forzada.

Manual total por defecto. **AJUSTES** permite embrague automático, semiautomática
y rev-matching opcionales. En N y detenido, **C+Q selecciona reversa; C+E primera**.
En CVT, Q/E recorren R/N/D sin embrague y con el auto detenido. Al verde se liberan
embrague y frenos para transmitir par; el HUD indica qué pedal impide largar.

Se añaden cabeceo de suspensión por muelle/amortiguador y diferenciales
abierto/LSD/bloqueado configurables, con agarre por rueda sobre superficies distintas.
Son modelos reducidos: todavía hay dos inercias de eje y no cuatro ruedas dinámicas.
La auditoría de las 26 fichas separa datos reportados de parámetros estimados,
sin ajustar cronómetros para reproducir una cifra de catálogo.

Showroom, iluminación nocturna, cámara e instrumental reciben ajustes visuales;
los datos técnicos extensos siguen en pausa. Las marcas de la nueva física usan
su propia revisión y las partidas previas se conservan.
[Entrega y validación](RELEASE-0.24.md) · [Arquitectura y código](MANUAL-TRANSMISSION-0.24.md)
· [Fichas y límites](CALIBRATION-0.24.md) · [Banco numérico](STOCK-BENCHMARK-0.24.md).

## Estado histórico: novedades v0.23

Gravedad común de 9,81 m/s², fuerzas tangenciales/normal según el suelo real,
retroceso en pendientes, resistencia con viento relativo/densidad atmosférica
y frenos que se calientan por energía disipada y pierden eficacia al sobrecalentar.
El contacto limita impulsos para impedir creación numérica de energía.
Collider, rayos y visual se alinean al plano medio; no es suspensión completa.

Se suman **Yaris sedán, Ka 3p, 208, Polo Classic, Virtus, Onix y Corolla Cross**.
El Cross incorpora una CVT original de relación continua, salida y convertidor
de par con pérdidas. **E selecciona D, Q selecciona N con el auto detenido;
freno sostenido para alinear y soltarlo al verde.** No requiere pedal de embrague.
LT frena incluso con la preferencia de embrague analógico para autos manuales.
Las fichas siguen provisionales. Hay 26 carrocerías aportadas y 36 ofertas.

La pausa añade fuerzas, condiciones y temperatura de frenos; el HUD en carrera
continúa compacto. Se conservan partidas y marcas históricas: la nueva dinámica
usa su propia serie de comparación. Las importaciones de modelos ocupan menos
eliminando datos que el rig no utiliza. [Alcance y pruebas](RELEASE-0.23.md) ·
[Física y límites](PHYSICS-0.23.md) · [Banco reproducible](STOCK-BENCHMARK-0.23.md).

## Estado histórico: novedades v0.22

¼ de milla nocturno original, alumbrado cálido, faros proyectados y reflejo rojo
de frenado. Dos instrumentos analógicos pequeños muestran velocidad y RPM
reales; el centro continúa libre durante la pasada. Las imágenes de GT4 se
usan como dirección visual; no se incorporan sus imágenes ni logotipos al juego.

Se suman **Corsa 5 puertas, Amarok, Ranger cabina simple, EcoSport, Corolla y
Palio 5 puertas** con modelos aportados optimizados. Hay 19 carrocerías importadas
y 29 ofertas contando los modelos geométricos anteriores. Las seis fichas nuevas
son variantes de desarrollo explícitas; no se certifican año, motor o prestaciones.
Pickups RWD, masas, curvas, inercias y respuesta turbo se configuran por separado.
Se conservan las partidas e IDs previos; las nuevas fichas tienen revisión propia
para sus marcas. [Alcance y validación](RELEASE-0.22.md).

**AJUSTES → MÚSICA DE MENÚ** permite elegir entre 13 temas, avanzar/retroceder,
activar aleatorio y ajustar volumen. Los temas nuevos son derivados Ogg livianos
de los MP3 autorizados; se preservan originales por separado.

## Estado histórico: novedades v0.21

Se aplica la línea de `GT4_UI_System.zip`: fondos oscuros, azul acero, bordes finos,
Barlow para interfaz y Roboto Mono para números. El tema compartido actualiza
Inicio, garaje, concesionario, taller, tuning, carrera, movimientos, ajustes, pausa
y HUD. La pasada conserva el centro despejado y los datos extensos en pausa.
Se comprueban distribuciones 16:9 y 16:10 sin perder funciones ni navegación con mando.
[Dirección visual](UI-VISUAL-SYSTEM.md).

El **147 Vivace 1.4 BIO 1997** usa ahora **63 CV, 10,4 kgfm y 807 kg**, de la referencia
aportada. Se añade explícitamente piloto 75 kg; el régimen de potencia 5500 RPM es
estimado, y la caja/aerodinámica necesitan contraste. La potencia/par de la curva
se comprueban sin forzar un ET o 0–100. Las marcas de la ficha anterior se conservan
como históricas, separadas de las nuevas, con carga de partidas previas.
[Revisión del PDF](TECHNICAL-REPORT-REVIEW-0.21.md) · [Banco numérico](STOCK-BENCHMARK-0.21.md).

El compendio agrupa otras variantes: se conservan la referencia específica del
Uno Fire 2014 y el 500 Sport de 100 CV. Los videos de YouTube devolvieron CONNECT 403;
no se afirma haberlos visto ni extraído maniobras de ellos.

## Estado histórico: novedades v0.20

Se incorporan **calentamiento previo y largador automático**. El art.11 aportado permite calentar desde la línea hacia delante, con rojo intermitente/amarillas de fondo; la luz azul termina esa fase y llama a alinear. La ventana de 25 s, los 30 s para prepararse y el sostén de 1,5 s son parámetros de juego, no duraciones oficiales. Enter ya no arma el semáforo.

**H/L3 acciona el freno de mano trasero**, reasignable en teclado. En los FWD se puede calentar con primera y ráfagas de acelerador+H: el calor y desgaste proceden del patinamiento físico. Puede avanzar; hay que frenar dentro de la zona. El asistente alinea y sostiene antes de cronometrar, conservando uso y temperatura; el regreso en reversa aún no está simulado. Primera y embrague sostenidos, con ambos autos listos, activan automáticamente el árbol.

Los cambios aceptan acelerador sostenido y una ventana de 0,10 s para la pulsación simultánea de embrague/cambio. Se mantiene el embrague obligatorio y el desgaste por cambiar mal. Durante la pasada desaparecen botones, ayuda y diagnóstico extenso; la pausa conserva esa información. La cámara vuelve progresivamente a tu auto cuando el rival se aleja.

Los seis modelos anteriores pasan a texturas externas 1024²/mipmaps como los siete nuevos, sin cambiar geometría ni UV. Sus recursos importados bajan 52,20→22,06 MB; es tamaño de recursos, no una medición de FPS. [Informe 0.20](RELEASE-0.20.md) · [Recursos](assets/cars/README.md).

## Estado histórico: novedades v0.19

Se integran **125, Duna, Cronos, Siena, Punto, Regatta y 500 Sport**. Son trece modelos aportados disponibles en Inicio y veintitrés ofertas con las anteriores; se conservan las unidades, IDs y partidas. El selector de Inicio permite recorrer la flota sin recortar el mapa. En el garaje se puede elegir **otro modelo como rival**, con configuración, masa y equipamiento independientes; la opción de mismo modelo sigue disponible para comparar pilotos.

Por indicación del usuario, el **500 utiliza la ficha Sport de 100 CV a 6.000 RPM, 13,1 kgf·m a 4.250 RPM y seis marchas**. El modelo aportado tiene aspecto Abarth: se conserva como representación visual provisional, sin asignarle potencia de Abarth. El Punto posterior/regional usa un perfil provisional 1.4 Fire; no se confunde con el europeo de 2002 descrito en el informe. Los datos no aportados siguen estimados.

Los daños directos al motor distinguen compartimentos delantero, central y trasero. Se conserva la severidad total, el guardado y la liquidación única: un 133 no recibe automáticamente el reparto de motor frontal del 125. Se corrige también la aceptación de valores de embrague no finitos al cambiar de marcha.

Los siete nuevos modelos tienen geometría y texturas optimizadas; los originales se preservan separados. Las PNG externas, mipmaps y compresión de importación se verifican dentro del paquete exportado. Se conserva el GLB original del Gol y se comprime su textura importada para mantener manejable la descarga. [Informe de esta entrega](RELEASE-0.19.md) · [Procedencia de modelos](assets/cars/README.md).

## Estado histórico: novedades v0.18

Se suman **Fiat 128 Súper Europa 1.5, Fiat 133 y Fiat 128 estándar** con los modelos aportados. Se eligen en Inicio y se compran en el concesionario. Los tres insignia siguen encabezando la gama; los IDs anteriores y las partidas se conservan. El 133 tiene motor/reparto trasero y tracción **RWD**, mientras ambos 128 son **FWD**. El Súper Europa usa los datos aportados de 82 CV a 5.600 RPM y 12 kgf·m a 3.000 RPM; el 133 y el 128 estándar toman las referencias de 34 y 55 CV del informe. Los parámetros no especificados permanecen estimados.

La pista consulta **cuatro apoyos reales** mediante raycasts. Sin suelo, las ruedas pueden girar y frenarse, pero no impulsan el auto ni generan desgaste de contacto. Asfalto, banquina pavimentada, tierra y pasto tienen agarre y rodadura diferentes; los bordes visuales y físicos usan las mismas dimensiones. Se limita inmediatamente la fuerza de neumático al agarre disponible y el calor de frenos sale de la energía rotacional realmente eliminada. El HUD indica la superficie y el apoyo de ruedas.

Los modelos nuevos conservan sus texturas y utilizan derivados de alrededor de 80.000 triángulos. La separación de ruedas incluye tapacubos claros y considera el contorno para preservar los guardabarros de carrocerías oscuras. El archivo original de cada aporte se mantiene separado y sin cambios.

**Windows ahora se distribuye como ejecutable y PCK exportados con Godot 4.6.3**, con las licencias correspondientes. Extraé todo el ZIP y abrí `JUGAR.cmd`; el editor ya no forma parte de esa descarga. El ZIP Proyecto conserva el código y recursos para Godot. [Informe técnico](RELEASE-0.18.md) · [Procedencia de los seis modelos](assets/cars/README.md).

## Estado histórico: novedades v0.17

**GARAJE → DUELO ¼ DE MILLA / FÁBRICA** permite elegir rival y clase antes de correr. Nico es técnico, Claire agresiva y Akira conservador. Por defecto se usa **Clase 1, piso de 18,00 s ET**; también podés elegir los demás pisos de ¼ del art. 21 del reglamento aportado, incluidos **4i y 5i**, o **LIBRE / PRIMERA LLEGADA** para correr sin piso. La opción LIBRE es una exhibición propia; no representa admisión a la clase oficial L1.

Ambos carriles tienen vehículo, semáforo y ticket independientes. Entre llegadas válidas gana el menor **RT + ET**, mientras que la caída de clase se evalúa sólo sobre **ET**. En el perfil de referencia argentino, un adelantamiento individual da la victoria al otro carril sin importar su ET, conforme al art. 12; dos adelantamientos o dos caídas no inventan un ganador. Esta ronda es una **exhibición sin inscripción, premios ni campeonato**. Las excepciones de finales, llaves, repechaje y trofeos están documentadas y no se presentan como sistemas ya implementados.

El duelo usa configuración de fábrica, neumáticos de calle y protocolo sin ayudas, conservando el estado mecánico de tu unidad. Es una restricción propia de Evolution: el reglamento técnico permite preparación mecánica en vehículos de «serie». El botón **¼ DE MILLA / MANUAL** conserva la práctica individual anterior y sus preparaciones. Pausa detiene ambos autos; R los vuelve a alinear manteniendo desgaste. Los récords de configuración de fábrica permanecen separados de los anteriores y el progreso sigue requiriendo **GUARDAR**.

Se incorporan los modelos aportados del **147 y del Uno**, con derivados de render optimizados a partir de originales de aproximadamente un millón de triángulos, preservando UV y materiales; el conteo final y la revisión gráfica se registran en el informe de entrega. Los originales se archivan por separado. El Gol mantiene su GLB aportado sin modificar. **El modelo del Uno recibido es de cinco puertas**, aunque la variante objetivo del catálogo sigue siendo Uno Fire de tres puertas: la diferencia visual permanece explícita y su corrección requiere un modelo adecuado.

El Uno se identifica como **Fire 1.3 8V de tres puertas, año 2014**. Su curva respeta los **68 CV a 5.250 RPM** y **11,3 kgf·m a 2.250 RPM** de la referencia de fabricante transcrita por el usuario. Los **13,2 s de 0–100 y 158 km/h** se registran como objetivos de contraste, sin imponerlos a la física. Los demás puntos de curva, masas, relaciones y prestaciones continúan siendo **estimaciones de desarrollo**. Los nuevos textos permiten transcribir reglas, pero no verifican datos de fabricante; no se obtuvieron fichas de V6 para calibrarlos. [Reglamentos, artículos y límites](REGULATIONS-REFERENCE.md) · [Fuentes de vehículos](STOCK-SOURCES.md) · [Revisión del PDF Fiat](FIAT-REPORT-REVIEW.md) · [Informe de entrega y estado de validación](RELEASE-0.21.md) · [Procedencia de modelos](assets/cars/README.md).

## Estado histórico: incorporado en v0.16

La v0.16 introdujo los dos autos físicos, IA por controles, reloj común, tickets independientes, pausa y recuperación compartidas. Su regla inicial era duelo directo sin categorías verificadas; v0.17 añade la selección de pisos y la excepción de adelantamiento del texto aportado. También corrigió torque neto, masa con piloto y pérdidas de transmisión en retención, y añadió ficha provisional y 0–100/potencia al eje. Sus benchmarks son resultados del modelo de esa versión, no mediciones de autos reales. [Informe histórico](RELEASE-0.16.md).

## Estado histórico: incorporado en v0.15

Los siguientes puntos describen la entrega 0.15. La importación pendiente del 147 y del Uno se resuelve en 0.17 con los nuevos ZIP; la limitación de cinco puertas del Uno se mantiene documentada arriba.

- **147 Vivace, Uno Fire de tres puertas y Gol Power de tres puertas** encabezan el concesionario y se eligen en Inicio con los botones 147 / UNO / GOL. Tienen precios, masas, torque, relaciones de caja y colisiones diferenciados. GARAJE → VER MODELO permite elegir la vista cuando tenés varios autos.
- El **Gol usa el GLB texturizado aportado por el usuario**, con ruedas delanteras/traseras animadas. El archivo original conserva sus 40.000 triángulos, UV y material. Los modelos adjuntos del 147 y del Uno aún requieren acceso: esos dos ZIP exceden 32 MiB y Drive está bloqueado por la red del entorno. Ambos usan por ahora carrocerías procedurales originales, además de sus configuraciones propias.
- **TALLER → MONTAR:** calle ($ 320.000 ARS), deportivos ($ 650.000 ARS) o slick ($ 1.400.000 ARS). El juego completo restaura salud de neumáticos y cobra una sola vez. La elección se guarda; los deportivos anteriores migran al compuesto correspondiente. Calle funciona desde frío; el slick exige preparación y se desgasta más.
- El ¼ de milla mide calor y desgaste de cada eje a partir del contacto y el deslizamiento. **Los choques reales causan daño mecánico**, reducen rendimiento y quedan en el historial y la salud del auto. Recuperar no repara; los daños se atienden en el taller. El ticket separa desgaste normal y daños por impacto.
- Se adoptaron y adaptaron los módulos útiles de Claude, conservando física, cronometraje y liquidación actuales. Evaluación: [INTEGRATION-CLAUDE-0.11d.md](INTEGRATION-CLAUDE-0.11d.md). No se añade daño duplicado por limitador o embrague.
- Las diez ofertas anteriores, sus IDs, partidas, récords, controles, ARS y música se conservan. Al abrir una partida anterior se añaden las ofertas insignia que falten, sin sobrescribir unidades ni repetir la migración.

Informe de la entrega: [RELEASE-0.15.md](RELEASE-0.15.md). Procedencia y límites de modelos: [assets/cars/README.md](assets/cars/README.md).

## Incorporado en v0.14

- El ¼ de milla calcula por separado la rotación, patinamiento, carga y temperatura de los ejes delantero y trasero. La transferencia de peso reduce la tracción delantera al acelerar y aumenta la carga trasera. FWD, RWD y AWD responden de forma diferente.
- Curvas de torque por RPM, carga progresiva del turbo, pérdidas de transmisión y frenado por torque en las ruedas. Salud, neumáticos, frenos, suspensión y mejoras existentes afectan el modelo. El control de tracción recorta motor; el ABS modula los frenos. Ambos se eligen en AJUSTES para el ¼ de milla; por defecto TCS está apagado y ABS encendido.
- **Pesos argentinos:** saldo, precios, reparaciones, premios y movimientos se expresan con `$` y `ARS`. El saldo inicial es **$ 12.000.000 ARS**. Cada unidad contable anterior representa $ 1.000 ARS; se conservan proporciones y partidas sin multiplicar otra vez al cargar. Son precios del juego, sin cotización real.
- **Música de menú:** Lezcano Alan — PERRA #Ritmomanijero, Prod Sketchy. Se incluye el MP3 original aportado y autorizado para redistribución por el usuario. Se reproduce en bucle, tiene volumen independiente en AJUSTES y se desvanece al entrar en pista. Créditos y alcance de derechos en [assets/audio/README.md](assets/audio/README.md).
- Mando para menús, compras, ajustes y pausa: stick/cruceta navega, A/Cruz confirma, B/Círculo vuelve y LB/RB cambia pestaña. Izquierda/derecha modifica opciones y volumen. **Select/Back** abre una pausa con Continuar, Recuperar y Volver al garaje. Desconectar el mando activo pausa la conducción y libera los gatillos.

Informe técnico, archivos y resultados: [RELEASE-0.14.md](RELEASE-0.14.md).

## Nuevo modo: ¼ de milla manual

Comprá un auto y elegí **GARAJE → ¼ DE MILLA / MANUAL**. También hay acceso desde Inicio cuando tenés un vehículo. La práctica no cobra inscripción ni paga premios; registra distancia, desgaste y mejor ticket por unidad.

1. El auto aparece en **N**, a 5 m delante de la línea. Tenés 25 s de calentamiento autorizado; es opcional.
2. Mantené **C**, tocá **E** para primera y prepará RPM con C. En FWD, soltá C con ráfagas **W+H**. H frena sólo atrás: el auto puede avanzar. Para detenerlo, **C+Espacio**. No excedas la zona 2,5–35 m.
3. La **luz azul** termina el calentamiento. El asistente frena/alinea y sostiene antes de cronometrar; mantené **primera+C**. Ambos listos durante 1,5 s activan el semáforo automáticamente, sin Enter. Hay 30 s para prepararse.
4. Prepará RPM; esperá verde y soltá C para largar. Para cambiar, **C+E/Q**; podés mantener W. Pasar de RPM y cambiar mal tiene consecuencias.
5. La meta entrega ticket y frenado asistido. **R** repite conservando uso, desgaste y temperatura. **P/Inicio/Select** pausa y muestra ayuda/telemetría completa; **Esc** vuelve al garaje. Presioná **GUARDAR** para conservar progreso.

Cambiar temprano lleva el motor a una zona de menor entrega; quedarse en el corte interrumpe la potencia. Un cambio sin embrague se rechaza y desgasta la transmisión. Una reducción excesiva puede llevar el motor a sobrerégimen; soltar el embrague a bajas RPM contra el freno puede calarlo. R permite recuperar y arrancar de nuevo después de un calado; una avería mecánica o un embrague agotado requiere taller. Detenido en N, C+Q engrana reversa con movimiento real. El modelo usa masa, par, relaciones, inercia de motor y ruedas, capacidad de embrague, resistencia aerodinámica, agarre y transferencia longitudinal de carga. Los parámetros de cada auto son **aproximaciones de desarrollo**, sin validación contra mediciones reales.

El HUD de pasada muestra velocidad, marcha, RPM, tiempos y rival. Al pausar se muestran torque, potencia, pérdidas de embrague, turbo, temperaturas, tracción y ayudas. El ticket incluye ET, reacción, total, 60 pies, 1/8 de milla y velocidad media en los últimos 20,1168 m. El reloj parte cuando el auto libera el haz de salida tras 0,20 m de rollout; los tiempos de paso se interpolan entre cuadros físicos. Salirse del carril, saltarse la salida o una discontinuidad de posición invalida el intento.

El desgaste adicional del motor, transmisión/embrague, neumáticos y frenos se aplica al auto existente. Repetir, abandonar o volver a llamar la liquidación no lo borra ni lo duplica. El tuning existente modifica potencia y agarre. Las temperaturas son una aproximación de sesión; el guardado conserva salud y marcas, sin una simulación térmica persistente.

Las once acciones de teclado se reasignan en AJUSTES. Las preferencias anteriores migran: si E, Q o C ya estaban ocupadas, se preserva la asignación anterior y se elige otra tecla libre para la nueva acción. Consultá AJUSTES para conocer tus teclas.

Mando en este modo: RT/R2 acelera, LT/L2 o B/Círculo frena, LB/L1 sostiene embrague, A/Cruz sube, Y/Triángulo baja, X/Cuadrado recupera, RB/R1 cambia cámara y R3 mira atrás. Inicio y Select/Back abren pausa en cualquier fase; L3 acciona el freno de mano trasero. AJUSTES permite usar **LT/L2 como embrague analógico**: en ese modo B/Círculo frena, también si se mantiene el acelerador. LB sigue disponible. La opción solo afecta al ¼ de milla. El stick izquierdo conserva asistencia de dirección; el mando físico sigue pendiente de prueba.

El escenario se llama **Autódromo Sur**: tribuna, boxes, control, colores argentinos, semáforo y una escapatoria de más de 250 m. Es un diseño original inspirado en un ambiente de autódromo porteño; no es una reproducción exacta ni homologada del Gálvez. El sonido de motor es sintetizado y provisional. Los veintiséis modelos aportados usan sus mallas adaptadas; los vehículos anteriores sin GLB conservan carrocerías procedurales. El Uno recibido tiene cinco puertas, frente a la variante objetivo de tres puertas.

## Probar el juego

En el paquete Windows, extraé **todo** el ZIP y abrí `JUGAR.cmd`. No requiere instalar Godot ni importar el proyecto al arrancar; si falla, `DIAGNOSTICO.cmd` genera registros. Conservá `GT4Evolution.pck` junto al ejecutable. El ejecutable Windows todavía requiere prueba en ese sistema; la validación automatizada se realiza en Linux.

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
- Inicio con mapa original de servicios, paneles oscuros y azul acero, tipografía Barlow/Roboto Mono con licencia OFL y presentación 3D giratoria del auto. Concesionario en tarjetas, navegación lateral y garaje conservan las transacciones existentes.
- HUD compacto de velocidad, RPM, marcha, cronómetro, mejor vuelta, posiciones y cámara; minimapa del trazado real con jugador y rivales; ayuda extensa al detenerse o pausar. Autos procedurales con cristales, faros, ruedas animadas, dirección y movimiento de carrocería. Pista con cielo, sombras, materiales, tribuna y paisaje originales.
- IA reproducible que anticipa curvas, regula acelerador/freno, intenta adelantar por un carril libre y frena ante tráfico próximo. Habilidad, agresividad y consistencia cambian el ritmo y las pequeñas desviaciones de trayectoria. Es una primera IA de conducción; no un sistema avanzado de competición.
- Cuenta regresiva, posiciones en vivo, llegada real, resultados y abandonos. Los autos que llegan dejan de obstaculizar a quienes siguen compitiendo.
- Integración de Debutantes con inscripciones, premios únicos, reputación, licencias y memoria de enfrentamientos.
- Mejores vueltas por unidad de vehículo, guardadas con la carrera.
- Distancia fraccionaria persistente y desgaste también en recorridos menores a un kilómetro, incluso al abandonar.
- Carga JSON corregida y escritura mediante archivo temporal para conservar la partida anterior si el guardado falla. Partidas anteriores sin los campos opcionales nuevos siguen siendo compatibles; los eventos ya completados no vuelven a pagar.

## Límites actuales

La conducción del circuito sigue siendo arcade. El ¼ de milla usa un modelo longitudinal con embrague, cambios manuales y daños mecánicos, asistencia lateral y temperaturas simplificadas. Hay duelos físicos y práctica individual; no hay campeonato de picadas, premios, llaves, finales ni verificación técnica homologada. Los pisos transcritos del reglamento no validan las prestaciones estimadas de los autos. El Uno aportado tiene cinco puertas, el catálogo apunta a tres; los GLB contienen detalles y luces horneados. No hay deformación visual ni simulación completa de neumáticos, suspensión, embrague o diferencial izquierda/derecha. Las colisiones usan cuerpos de personaje, sin intercambio realista de impulsos. Faltan conducción humana, Windows, mando físico y mediciones de rendimiento en GPU real. La evidencia y el estado de comprobación de esta versión se registran en [RELEASE-0.25.md](RELEASE-0.25.md).

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

Las pruebas cubren las vistas, dirección, preferencias, navegación, transacciones y HUD; también pasadas manuales completas, diferencias de cambio y desgaste, semáforo, reacción, parciales, marca única por intento y compatibilidad de guardado. v0.15 añade los tres autos, la migración de ofertas, el GLB, compuestos, montaje pagado, colisiones, daños y reparaciones. Para generar las capturas de presentación en un entorno con pantalla OpenGL:

```sh
LIBGL_ALWAYS_SOFTWARE=1 bash tools/capture_presentation.sh /ruta/absoluta/capturas
# En Linux sin escritorio, anteponer: xvfb-run -a env
```

Ejecutá el comando desde la raíz del repositorio. Los datos se aíslan en un directorio temporal. Las capturas muestran los menús, las cámaras, la parrilla del club y una pasada manual de ¼ de milla hasta el ticket, además de una largada en falso y la pausa con mando. Se comprueban reproducción real del MP3, transición a silencio en pista y pausa del audio de motor. El piloto de ensayo vive en `tests/`, no está activado en el modo del jugador. La captura acelera el reloj para terminar la pasada dentro del límite; no es una prueba de rendimiento ni una medición para comparar récords. GitHub Actions publica las imágenes como artefacto cuando finaliza la comprobación gráfica.
