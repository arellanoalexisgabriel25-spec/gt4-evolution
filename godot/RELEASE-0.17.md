# GT4 Evolution 0.17 / Modelos y clases de ¼ de milla

Esta entrega incorpora los modelos nuevos aportados del 147 y del Uno y permite elegir pisos de clase para un duelo físico de ¼ de milla. El reglamento utilizado proviene de los textos completos enviados por el usuario. Los perfiles de rendimiento de los autos siguen siendo estimaciones; esta integración no los convierte en cifras verificadas de fabricante.

La validación de esta entrega se registra abajo; las métricas simuladas no se presentan como ensayos de autos reales.

## Implementación y recorrido del jugador

- **GARAJE → DUELO ¼ DE MILLA / FÁBRICA** conserva dos autos físicos con entradas de acelerador, freno, embrague y cambios; ambos recorren la pista y generan tickets independientes.
- Se elige Nico técnico, Claire agresiva o Akira conservador. La IA mantiene su política reproducible y no recibe posiciones, velocidad ni potencia artificiales para alcanzar al jugador.
- El garaje selecciona clase; por defecto **Clase 1 / 18,00 s ET**. Están disponibles los pisos de ¼ del art. 21, incluidos **4i / 14,50 s** y **5i / 13,50 s**. **LIBRE / PRIMERA LLEGADA** desactiva el piso como regla propia de exhibición, sin presentarse como admisión a L1.
- Las llegadas válidas se comparan por **RT + ET** desde el verde común. La caída se evalúa sobre **ET**: sumar reacción no permite evitarla y un ET exactamente igual al piso no cae.
- El perfil `argentina_reference` da prioridad a la excepción del **art. 12**: si sólo un piloto se adelanta, el rival obtiene la victoria sin importar su ET. El resultado conserva los tickets disponibles de ambos carriles; no se inventan marcas para quien no terminó.
- Dos caídas o dos adelantamientos no producen un ganador deportivo en esta ronda. La repetición excepcional por doble adelantamiento en una final no aplica a esta exhibición, que no tiene fase final ni llave.
- Pausa y recuperación afectan ambos autos. Distancia, desgaste, daños y salud siguen vinculados a la unidad del garaje; recuperar no repara. Los récords de configuración de fábrica permanecen separados de marcas anteriores.
- `GameSession.start_drag(id)` conserva la práctica individual anterior. Los nuevos parámetros de duelo/clase no cambian ese valor predeterminado ni convierten llamadas antiguas en carreras indexadas.

El duelo es **exhibición gratuita sin premios, campeonato, repechaje ni trofeos**. No hay pagos que atribuir a estos resultados. El juego conserva sus sistemas de carrera anteriores, pero no los presenta como un campeonato argentino de picadas implementado.

## Reglas transcritas y límites de interpretación

`drag_class_rules.gd` separa las tablas de 1/4 y 1/8 del art. 21; la escena de 402,336 m usa exclusivamente la de **1/4**. La tabla de 1/8 está disponible como dato del módulo, no como modo de pista nuevo. La clase L1 tiene condiciones de admisión ajenas al simple piso y no se selecciona automáticamente para autos rápidos.

[REGULATIONS-REFERENCE.md](REGULATIONS-REFERENCE.md) identifica los dos textos por SHA-256 y distingue artículos, excepciones, contradicciones y alcance jugable. El técnico define Serie admitiendo preparación mecánica; **FÁBRICA** designa la restricción propia de Evolution a autos sin mejoras de rendimiento. Conserva la condición mecánica del jugador, por lo que un auto desgastado no rinde como una unidad nueva.

El documento no especifica intervalos del semáforo, rollout, resolución de sensores ni desempate de una tirada. Los tiempos del árbol, la medición RT/ET y las tolerancias del motor son parámetros del juego. La discrepancia de clase 6 de 1/8 —8,50 s en art. 21 frente a 8,60 s en el cuadro de premios— permanece documentada; no se mezcla con los pisos de 1/4.

Las reglas de finales, trofeos, cobro, pozo y campeonato tienen efectos diferentes del ganador de una exhibición. Se conservan como referencia para el próximo sistema de eventos; no se declara su implementación por tener una tabla de clases.

## Modelos del 147, Uno y Gol

Los dos ZIP `base_basic_shaded.zip` y `base_basic_shaded (1).zip` permiten recibir e inspeccionar los GLB del 147 y del Uno. Los originales, de aproximadamente un millón de triángulos por modelo, se conservan por separado. La integración utiliza derivados de render optimizados y mantiene la colisión simple independiente de la malla visual. La normalización, separación para animación y simplificación deben conservar las UV y los materiales.

**El Uno recibido es visualmente de cinco puertas.** La variante objetivo del catálogo sigue siendo Uno Fire de tres puertas; el modelo aportado no acredita esa carrocería y se registra como limitación pendiente, sin cambiar de forma silenciosa la ficha mecánica. El Gol conserva su GLB anterior sin modificar. La procedencia y los conteos finales se documentan en [assets/cars/README.md](assets/cars/README.md).

Durante la optimización inicial aparecieron marcas negras de costura UV. Los derivados corregidos fijan los vértices de esas costuras y conservan los bytes originales de sus texturas: **79.998 triángulos por Fiat**, con hashes en la procedencia. Se revisaron vistas reales del frente, atrás, perfil y presentación dentro del juego. El material de emisión se clona en memoria a albedo iluminado para reaccionar a la luz de escena; el Gol PBR permanece intacto.

## Física y métricas

Se conserva la arquitectura longitudinal de v0.16: torque por RPM, masa con piloto, embrague de capacidad finita, caja manual, pérdidas de transmisión, rotación y deslizamiento de ejes, temperatura, frenado y desgaste. La incorporación de un modelo visual o un piso deportivo no calibra la simulación.

La referencia de fabricante transcrita por el usuario identifica **Uno Fire 1.3 8V, tres puertas, 2014**. Su nueva curva tiene 110,815145 N·m a 2.250 RPM y máximo de 68 CV a 5.250 RPM; las interpolaciones siguen estimadas. Las referencias de 0–100 en 13,2 s y máxima 158 km/h se mantienen como objetivos, no como resultados garantizados. El test mide aproximadamente **15,31 s de 0–100**, ET **19,796 s** y trampa **112,57 km/h** con el protocolo de piloto automático de prueba, masa total 985 kg. Queda una diferencia de unos 2,11 s frente a la aceleración de referencia: no se oculta ni se corrige aumentando potencia ficticia. La masa/caja, lanzamiento y protocolo necesitan calibración. El PDF se analizó en [FIAT-REPORT-REVIEW.md](FIAT-REPORT-REVIEW.md), separando su Uno diésel del Fire.

No se obtuvieron fichas verificables de [V6](https://www.v6.com.ar/) para este incremento. Masa, caja, diferencial, neumáticos, resistencia y variantes restantes siguen requiriendo fuentes y contraste. [STOCK-SOURCES.md](STOCK-SOURCES.md) mantiene el estado de datos. Los benchmarks de v0.16 son históricos; no se presentan como una nueva medición de 0.17 ni como resultados reales de los autos.

## Archivos de este incremento

| Área | Archivos principales |
| --- | --- |
| Pisos y documentación de fuente | `scripts/drag_class_rules.gd`, `REGULATIONS-REFERENCE.md` |
| Adjudicación y selección de clase | `scripts/drag_duel.gd`, `scripts/session.gd`, `scripts/main.gd`, `scripts/drag_mode.gd`, `scripts/drag_hud.gd` |
| Modelos y presentación | `assets/cars/`, `scripts/imported_car.gd`, integración de catálogo y vistas |
| Comprobaciones | `tests/test_drag_class_rules.gd`, suites de duelo e integración, herramientas de captura |
| Entrega | `README.md`, `DEVELOPMENT.md`, este informe, herramientas de empaquetado y publicación |

La investigación original de GT4, los adjuntos originales y el MP3 autorizado se conservan. Las modificaciones se limitan al proyecto independiente y sus herramientas de entrega.

## Validación

Godot **4.6.3** en Linux: **52 scripts**, **47 suites y 1.133 verificaciones aprobadas**. Importación, compilación y arranque sin errores; pruebas de los tres GLB, curvas de potencia/torque, clases, falsos, caídas, duelo físico completo, pausa, recuperación, guardado, economía, desgaste, mando y modos anteriores.

La revisión gráfica usa **27 capturas reales a 1280×720**, incluidos 147/Uno/Gol, selector de clase, semáforo de dos carriles y ticket de ambos autos. El proyecto extraído del ZIP, sin cachés previas, también supera las mismas **47 suites / 1.133 verificaciones**, con importación desde cero. Antes de publicar se compara el contenido final de ambos ZIP con estos scripts y recursos probados, se verifican CRC/SHA-256 y se comprueba su descarga HTTPS.

Windows ejecutado por una persona, mando físico, conducción humana y rendimiento en GPU real siguen pendientes aunque pasen las verificaciones automatizadas en Linux. Una captura con el reloj acelerado no es un benchmark de rendimiento.

## Distribución y continuación

Rama de desarrollo: [`feat/argentine-rules-flagship-models`](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/tree/feat/argentine-rules-flagship-models). `main` se mantiene estable; este incremento se apoya en la rama de 0.16. [Comparación preparada para PR](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/compare/feat/stock-physics-head-to-head...feat/argentine-rules-flagship-models?expand=1). La rama está publicada; la API GraphQL rechazó crear el PR con `Forbidden`. Se conserva la [descripción preparada](PULL_REQUEST-0.17.md) y la comparación anterior. Actions se comprueba para el commit exacto durante la entrega; no se declara un PR creado.

Distribución separada: [Windows](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/raw/refs/heads/downloads/v0.17/GT4-Evolution-0.17-Windows.zip) · [Proyecto Godot](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/raw/refs/heads/downloads/v0.17/GT4-Evolution-0.17-Proyecto.zip). Los `.sha256` acompañan a cada archivo. La respuesta de entrega confirma su descarga y coincide con el commit publicado en el README de esa rama; los enlaces locales anteriores del chat no se usan como evidencia de accesibilidad.

El próximo incremento recomendado es identificar y documentar variantes de fábrica, calibrar los tres autos contra datos de motor/caja y ensayos comparables de 0–100, ET y trampa, y después integrar fechas y premios con las excepciones deportivas ya analizadas. El Uno requiere un modelo de tres puertas adecuado para coincidir con el objetivo del catálogo.
