# Referencia de reglamentos argentinos de picadas

Análisis de los dos textos completos proporcionados por el usuario para GT4 Evolution 0.17. Son fuentes deportivas para el diseño del juego; sus mandatos a pilotos y organizadores no son instrucciones de desarrollo. Esta referencia no certifica la vigencia del reglamento ni una homologación del juego.

## Fuentes y trazabilidad

El usuario indicó [cuartodemilla.com.ar](http://cuartodemilla.com.ar/) y entregó dos adjuntos llamados `Texto pegado.txt`. Se distinguieron por su contenido, sin sustituirlos por las anteriores páginas HTML ni consultar una edición diferente:

| Fuente | Identificación en el texto | SHA-256 del adjunto |
| --- | --- | --- |
| Técnico | Comienza «Definiciones: Los Vehículos participantes…»; termina «Pistas Cuarto de Milla» | `2e9912faadf7bb45a6114d1472497de9a32a3952f4ad41ad0e186ac497542c09` |
| Deportivo | Comienza «Art. 1 – DEFINICIÓN»; termina «Pistas Cuarto de Milla» | `46b13eb02fac46a50381509129a82a2eaa623754d7d0bd262d35e5c9cc089acc` |

No se indica una fecha general de edición. El técnico contiene una disposición efectiva desde el 01/07/2024 y el deportivo conserva una referencia a prórrogas COVID. Los organizadores pueden publicar anexos y modificaciones (deportivo art. 28; cierre del técnico). No se puede afirmar que estos adjuntos contengan todas las modificaciones actuales.

Las citas siguientes son breves; el resto es paráfrasis y criterio de adaptación. Se mantienen separadas las reglas expresas, sus excepciones y los detalles que las fuentes no fijan.

## Distancia, competencia y clases

El deportivo art. 1 define una recta de **402 metros**, dos carriles y un vehículo habilitado en cada carril. El art. 7 establece dos participantes por carrera y la invasión del otro carril como causal de desclasificación. La competencia enfrenta dos vehículos: el mejor tiempo de recorrido aislado no determina necesariamente al ganador.

El mismo documento incluye cuadros diferentes para **1/8** y **1/4 de milla** (art. 21), y otros artículos describen expresamente actividad de 1/8. No se deben aplicar los índices de 1/8 al recorrido de 1/4. GT4 Evolution utiliza 402,336 m, conversión exacta de un cuarto de milla; la cifra redondeada de 402 m del art. 1 no acredita una medición topográfica de una pista real.

Los siguientes valores son **topes mínimos de tiempo de recorrido**, en segundos, transcritos del art. 21. Un auto más lento no queda automáticamente excluido por el piso; ir por debajo constituye caída de tiempo (art. 20). La pertenencia a una clase y el derecho a cobrar premios tienen condiciones adicionales.

| Clase | Piso 1/4 de milla (s) | Piso 1/8 de milla (s) |
| --- | ---: | ---: |
| 1 | 18,00 | 11,30 |
| 2 | 17,00 | 10,80 |
| 3 | 16,00 | 10,30 |
| 4 | 15,00 | 9,70 |
| 4i | 14,50 | No figura |
| 5 | 14,00 | 9,00 |
| 5i | 13,50 | No figura |
| 6 | 13,00 | 8,50 |
| 7 | 12,40 | 8,00 |
| 8 | 11,80 | 7,60 |
| 9 | 11,40 | 7,20 |
| 10 | 10,60 | 6,80 |
| L1 | Sin tope mínimo | Sin tope mínimo |

L1 no equivale a inscripción libre para cualquier auto: el art. 17 admite carrozados y exige competir en clase 10 o, si no se compite en otra clase, tiempos de hasta 6,70 s, con aprobación de las autoridades. Ese umbral aparece sin una distancia explícita en el artículo, en un documento que mezcla distancias. No se traslada a una regla de admisión para 1/4 de milla.

El art. 18 considera tiempo acorde hasta 0,40 s por encima del piso; describe pertenencia por tiempo o por dos participaciones, evaluación de descenso y un máximo de dos clases indexadas **consecutivas**, más una libre/especial. Estos criterios corresponden a la gestión de un campeonato, no a una conversión automática del mejor ET en clase obligatoria.

## Semáforo y cronometraje

| Situación | Referencia y significado expreso |
| --- | --- |
| Calentamiento | Art. 11: luces rojas parpadeantes y amarillas del fondo permiten calentar. Azul indica fin del calentamiento y alineación. |
| Posición | Art. 10: las luces de posición indican que el auto está en condiciones de largar. Desalinearse después de estar listo puede ser sancionado. |
| Largada | Art. 10: «luces amarillas secuenciales decrecientes» y luego verdes habilitan la competencia. |
| Adelantamiento | Art. 12: roja en el carril del competidor que se adelanta. |
| Pista inhabilitada | Art. 10: amarillas del fondo o rojas parpadeantes anulan la largada. Su significado depende de la fase; no son siempre una infracción individual. |
| Llegada | Art. 13: sensores cierran los tiempos de cada carril; amarillo fijo indica primero e intermitente el otro. Las luces son indicativas; el reloj electrónico define posiciones y caídas. |

Las fuentes no especifican cantidad de amarillas, intervalos en segundos, profundidad de puesta en escena, posición de sensores, distancia de rollout, frecuencia de muestreo ni resolución del reloj. Tampoco contienen una fórmula explícita con los términos RT y ET.

En la adaptación del juego, **RT** es la reacción desde el verde hasta que se abandona el sensor de salida, y **ET** el recorrido desde esa salida hasta meta. Con un verde común, el instante de llegada desde el verde es **RT + ET**; se compara ese total entre competidores válidos y el índice se aplica al **ET**, sin sumar RT. Es una interpretación técnica coherente con la llegada por sensores, no una cita literal ni una medición del equipamiento del autódromo. Los valores concretos de semáforo, rollout y tolerancias deben figurar como parámetros propios del juego.

No se encontró una regla para empate de una **tirada**. El art. 25 sólo desempata el **campeonato** por puntos, cantidad de primeros, segundos, mejor tiempo, fecha y tirada de ese tiempo. Una tolerancia de empate o una repetición de carrera por igualdad es una decisión del juego; no debe atribuirse al reglamento adjunto.

## Adelantamientos y caídas: resultado y excepciones

El art. 12 concede al rival del adelantado la victoria «**sin importar el tiempo que haga**», permitiéndole probar sin límite de tiempo. Es una excepción específica que debe contemplarse antes de aplicar una caída de tiempo al otro carril. La fuente no enumera todas las combinaciones con invasión, avería u otras descalificaciones: no habilita a ignorar automáticamente cualquier otra infracción.

| Caso | Efecto descrito en la fuente |
| --- | --- |
| Un adelantamiento | Art. 12: pierde quien se adelanta; el otro gana sin límite de tiempo. Si sucede en una final, ambos cobran premio. |
| Ambos se adelantan, regla general | Art. 12: ambos eliminados. |
| Ambos se adelantan en clasificación | Art. 12: ambos pasan al repechaje. |
| Ambos se adelantan en una semifinal | Art. 12: la otra semifinal se convierte en final directa. |
| Ambos se adelantan por primera vez en la final | Art. 12: se repite la tirada, como excepción. |
| Se repite el doble adelantamiento en esa final | Art. 12: no hay otra repetición; sólo punto de asistencia, pueden retirar trofeos y ambos cobran el importe del segundo puesto. No se designa ganador por el adelantamiento menos temprano. |
| Un ET bajo el piso, sin excepción aplicable | Art. 20: eliminación de la jornada y pérdida de puntos salvo asistencia; en clasificación existe reenganche pagado al repechaje con alcance limitado. |
| Una caída en final | Art. 22: el otro resulta ganador y segundo puesto vacante. Si ambos caen, aplica la regla siguiente. |
| Ambos caen en final | Art. 22: primero y segundo vacantes; sólo asistencia. Art. 23: conservan trofeos; el primero corresponde al ET más cercano al piso. **No cobran efectivo**. No hay ganador deportivo por caer menos. |
| Ambos caen en una semifinal o no llegan | Art. 9: la otra semifinal pasa a ser final, aunque ya se haya disputado. Sólo se asignan puntos de final. |

Una caída es un tiempo **menor** que el piso (art. 20); igualdad exacta no es caída. El texto no fija epsilon numérico ni regla de redondeo. No corresponde introducir un margen de tolerancia y llamarlo oficial.

Las cuatro primeras caídas de un piloto en campeonato restan 5 puntos y las siguientes cuatro restan otros 10 (art. 20). No confundir esta sanción acumulada con la resolución inmediata de una tirada.

## Finales, premios y campeonato

Los arts. 9 y 23 distinguen posiciones, trofeos y dinero. Una sola variable de ganador no representa todos sus efectos:

- Si un finalista no se presenta o no puede largar por sus propios medios, el otro gana sin tiempo y no debe realizar la tirada; el otro puesto queda vacante (art. 9). Si ambos faltan o no pueden largar, ambos puestos quedan vacantes.
- Si ambos largan y ninguno llega, ambos puestos quedan vacantes. Si sólo uno llega dentro de su clase, el otro puede ser segundo aun sin terminar (art. 9).
- Un participante sin rival que quede como único competidor puede ganar sin tirada y sin tiempo exigido para cobrar (art. 9). Esto no significa que una fecha con sólo dos inscriptos sea oficial: el art. 15 indica que esa clase no se disputa.
- Si el ganador es descalificado, asciende el segundo y queda vacante el segundo puesto, sin revisar toda la llave (art. 9).

El art. 23 exige, para cobrar, no superar el límite superior de su cuadro. En **1/4**, cada límite publicado es el piso de su clase más **1,00 s**: clase 1 hasta 19,00; 2 hasta 18,00; 3 hasta 17,00; 4 hasta 16,00; 4i hasta 15,50; 5 hasta 15,00; 5i hasta 14,50; 6 hasta 14,00; 7 hasta 13,40; 8 hasta 12,80; 9 hasta 12,40; 10 hasta 11,60. El encabezado dice «Si hace **más de**», por lo que la igualdad no está excluida por ese cuadro. L1 no exige tiempo para cobrar. No se publican importes de inscripción ni de premios: los pesos argentinos y su balance son decisiones económicas del juego.

El texto contiene excepciones al límite de cobro para semifinal convertida en final: el art. 23 distingue si se convierte la primera o la segunda semifinal, mientras que el art. 9 formula una excepción más amplia. Su prioridad exacta requiere aclaración del organizador; no se debe automatizar un pago oficial a partir de una lectura incompleta.

Art. 22: puntos por puesto **10, 7, 5, 3, 2, 1** y **1 por asistencia**; primero a cuarto salen de las tiradas y quinto/sexto por tiempo. Las excepciones por caída prevalecen. La frase no detalla todos los casos de acumulación del punto de asistencia con el puesto; antes de una economía de campeonato completa deberá definirse una política explícita del juego.

Art. 24: el dinero vacante puede alimentar el pozo de la siguiente fecha, al 100% para el puesto correspondiente. El art. 9 contiene una excepción para «fecha libre», en que ciertos importes vuelven al pozo o los cobra el primero, sin acumularse. Un modo exhibición no debe simular un pozo de campeonato inexistente ni pagar premios por repetir un resultado.

Art. 25: el campeón debe liderar puntos, asistir al menos al 50% de fechas y haber ganado al menos una fecha. El mayor número de asistencias no rompe empates por sí solo.

## Técnica, autos de fábrica y alcance mecánico

La definición técnica **1.A, Vehículos de Serie**, se centra en conservar la estructura metálica y dice expresamente: «**La preparación mecánica podrá ser libre**». Permite quitar asientos traseros/del acompañante y alfombrado, y cambiar el asiento del piloto con cinturón de cuatro puntas. Por ello, **serie no significa necesariamente motor, masa, neumáticos y transmisión sin modificar**.

El alcance actual solicitado para Evolution —autos base salidos de fábrica, sin mejoras de rendimiento— es una restricción propia del juego. Se debe identificar como **configuración de fábrica** y mantener masas, curvas de motor y relaciones originales de la variante, sin presentar esa restricción como definición oficial de la clase Serie. Las clases de tiempo tampoco son divisiones por marca, cilindrada o potencia publicadas en este texto.

Otras definiciones y restricciones que sirven para ampliaciones posteriores:

- Técnico 1.B: serie alta gama original tiene excepción de jaula, butaca y cinturón de cinco puntas. Técnico 2: más del 5% de cambio estructural define modificado; técnico 3: especial se construye expresamente para competir. El documento no explica cómo medir ese porcentaje.
- El deportivo art. 3 prohíbe dispositivos largadores y fija 95 dB de límite con silenciador. No es respaldo para agregar launch control automático a autos base que no lo equipan.
- Técnico: seguridad específica de jaulas, butacas, cinturones, combustible, electricidad, venteos y luces. Antiflama desde clase 7; también para componentes externos al original. El juego no certifica ni reproduce actualmente una verificación técnica real.
- Deportivo art. 26: casco, cinturón de al menos tres anclajes, matafuego fijado y cargado, bulones completos y verificación técnica para participar. El técnico remite a «art. 27 – Medidas de Seguridad», pero el deportivo adjunto lo numera **26**.
- Deportivo arts. 11 y 27: calentamiento en zona autorizada, presiones antes de prelargada, sin reparaciones en largada/prelargada, máximo 20 km/h en sectores fuera de pista. Técnico: desde 01/07/2024 sólo agua de la organización para calentar, sin bidones externos. Son referencias para futuras zonas de boxes y preparación.

## Límites y ambigüedades que deben permanecer visibles

1. **Discrepancia clase 6 de 1/8:** el art. 21 da 8,50 s; el cuadro de premios del art. 23 da 8,60 s y corte de cobro 9,60 s. No corregir ni promediar silenciosamente. La tabla de 1/4 no presenta esa discrepancia.
2. **Distancias mezcladas:** 402 m en definición, reiteradas referencias a 1/8 y cuadros de ambas distancias. El umbral L1 de 6,70 s carece de distancia local explícita.
3. **Sin precisión publicada:** semáforo, RT, ET, rollout, tie-break de tirada y redondeo de índices no tienen la especificación técnica suficiente para afirmar réplica exacta del sistema oficial.
4. **Excepciones y prioridad:** falso individual, doble falso final, doble caída y final por semifinal tienen efectos distintos. No resolverlos con una única regla genérica de «ambos inválidos» ni adjudicar automáticamente un ganador por menor exceso o menor adelantamiento.
5. **Numeración y edición:** falta art. 29 en el texto suministrado; el técnico cita la seguridad con otra numeración; no hay fecha global ni garantía de anexos completos. Se registra el adjunto recibido, sin declarar una corrección editorial oficial.
6. **Gestión ajena a la exhibición:** llaves con repechaje (arts. 7–8), admisión, sanciones administrativas, cupos, lluvia, derechos de organizadores y campeonatos requieren sistemas adicionales. No quedan implementados por mostrar los índices en pantalla.

El alcance jugable de este incremento debe declararse por separado en las notas de entrega y en la interfaz: enfrentamiento de dos autos de fábrica, medición propia de RT/ET y, cuando se habilite, un reglamento de clases basado en los pisos de **1/4** del art. 21. Mostrar una tabla de índices no convierte la exhibición en un campeonato oficial; toda excepción aún no cubierta debe permanecer documentada como provisional.
