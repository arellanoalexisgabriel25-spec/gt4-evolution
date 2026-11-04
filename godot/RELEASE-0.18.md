# GT4 Evolution 0.18 / Clásicos argentinos y contacto físico

Se integran tres modelos aportados y se corrigen errores medidos de contacto, cambio de superficie y calor de frenado. La conducción sigue siendo un modelo longitudinal con asistencia lateral, colisión simple y parámetros parcialmente estimados; no se presenta como una simulación completa ni una réplica homologada del Gálvez.

## Autos y progresión

| ID nuevo | Vehículo | Tracción | Referencia aportada |
| --- | --- | --- | --- |
| 14 | Fiat 128 Súper Europa 1.5 | Delantera | Informe Fiat: 82 CV DIN a 5.600 RPM, 12 kgf·m a 3.000 RPM, cinco marchas |
| 15 | Fiat 133 | Trasera, reparto trasero | Informe Fiat: 843 cm³, 34 CV, 680 kg |
| 16 | Fiat 128 estándar | Delantera | Informe Fiat y modelo identificado por usuario: 1.116 cm³, 55 CV, 830 kg |

Se conservan IDs 1–13, los tres insignia, precios anteriores, saldo, propiedad, salud, mejoras e historial. La migración añade ofertas que faltan y evita sobrescribir IDs ocupados. Inicio incorpora botones para los clásicos y el garaje permite correrlos con las reglas de clase existentes. La selección individual continúa siendo práctica y los duelos continúan siendo exhibiciones sin cargos ni premios.

Los datos de fabricante transcritos por el usuario se mantienen identificados. Masa del Súper Europa, regímenes no publicados, torque de las versiones sin dato y relaciones/diferenciales son estimaciones de desarrollo. Los nuevos modelos no justifican asignarles una variante mecánica sólo por apariencia.

## Física y entorno implementados

- Cuatro raycasts de apoyo por auto, con detección independiente de ruedas delanteras/traseras y exclusión de otros vehículos. Una pared vertical no sirve de suelo.
- En el aire no hay fuerza de neumático ni desgaste/calor de contacto. El motor y las ruedas conservan inercia; el freno puede disipar esa energía y el aire enfría los neumáticos. La rodadura desaparece; la resistencia aerodinámica y gravedad 9,81 m/s² continúan.
- Superficies secas separadas de asfalto, banquina pavimentada, tierra y pasto. Los mismos límites generan la geometría visible y clasifican cada apoyo real. Las mezclas se calculan por eje sin trasladar artificialmente carga del eje sin apoyo.
- Límite inmediato de fuerza ±μN después de la relajación del neumático. Se elimina el exceso de agarre transitorio al entrar en superficie de menor adherencia.
- Calor de frenos calculado por energía rotacional realmente eliminada, incluso al detener una rueda en un paso. La corrección alimenta el desgaste existente sin añadir daños ficticios.
- El auto debe apoyar las cuatro ruedas para armar la largada. Recuperar requiere asentarse de nuevo y conserva el uso mecánico.
- Entradas no finitas o de tipo inválido se rechazan antes de mutar posición, dirección, desgaste o telemetría. El HUD informa superficie y número de ruedas apoyadas.

La auditoría previa reprodujo tres errores: un auto sin suelo aceleraba de 10 a 12,714 m/s en 1 s; tras una reducción de agarre quedaban 4.453 N/eje frente a 1.962 N disponibles; una frenada disipaba 3,199855 J pero registraba 0,030161 J. Las nuevas pruebas reproducen y comprueban la corrección de esos casos. Estos números son de fixtures de prueba, no ensayos de autos reales.

## Modelos y presentación

Los tres originales se conservan fuera del proyecto. Sus derivados tienen 79.998/79.998/79.996 triángulos y conservan los bytes de textura originales. Los anteriores 147/Uno/Gol permanecen intactos. Se revisa la separación geométrica de las ruedas para incluir tapacubos claros y mantener fijos los guardabarros oscuros. La procedencia y hashes están en [assets/cars/README.md](assets/cars/README.md).

El Uno conserva la limitación visual de cinco puertas frente al objetivo mecánico de tres. No hay deformación visual de carrocería, diferenciación completa de neumáticos izquierdo/derecho, diferencial abierto/bloqueado ni suspensión resuelta por masas y muelles. Los coeficientes de superficie y el alcance de raycasts son configuraciones del juego, sin medición de la pista real.

## Distribución

Se reemplaza el editor portátil del ZIP Windows por el ejecutable oficial exportado de Godot 4.6.3 y un PCK. Las plantillas se descargan del lanzamiento oficial y se verifica su SHA512 completo; el ejecutable se compara con la plantilla. Se incluyen MIT/COPYRIGHT de Godot, tipografía y procedencia de recursos. `JUGAR.cmd` arranca el juego sin importar el proyecto ni instalar el editor.

La validación compara el ZIP Proyecto con las fuentes, comprueba el contenido del PCK contra el manifiesto y utiliza un runtime Linux oficial con el mismo PCK. Eso no equivale a ejecutar Windows ni un mando físico. El ZIP fuente sigue pudiendo abrirse en Godot 4.6.3. No se distribuyen recursos comerciales originales de GT4.

## Archivos principales modificados

| Área | Archivos |
| --- | --- |
| Física y entorno | `track_surface.gd`, `drag_actor.gd`, `manual_powertrain.gd`, `axle_traction.gd`, `tire_model.gd`, `drag_strip.gd` |
| Vehículos y persistencia | `car_catalog.gd`, `stock_vehicle_specs.gd`, `handling.gd`, `drag_vehicle_config.gd`, `economy.gd` |
| Visuales e interfaz | `imported_car.gd`, tres GLB nuevos, `main.gd`, `drag_hud.gd`, `drag_mode.gd` |
| Pruebas nuevas | `test_classic_fiats.gd`, `test_classic_runs.gd`, `test_classic_visuals.gd`, `test_axle_contact.gd`, `test_track_contact.gd` |
| Entrega | `export_presets.cfg`, `package_game.py`, `release_artifacts.py`, `validate_export.gd`, `publish_downloads.py`, herramientas de captura y documentación |

## Validación y revisión

Godot **4.6.3** en Linux: **53 scripts, 52 suites y 1.333 verificaciones aprobadas**. Importación y arranque sin errores. Se prueban los tres duelos clásicos completos, migraciones, límites de agarre, energía de frenado, contacto real, rechazo de entradas inválidas y regresión de economía, partidas, daños, controles y modos anteriores.

Se revisaron **33 capturas reales de 1280×720**, incluidos los seis modelos y el duelo de tracción trasera del 133. Las pruebas específicas de visuales conservan todos los triángulos, incluyen tapacubos claros y comprueban la animación. Un fallo de presentación inicial, al añadir otra fila de modelos, recortaba el mapa; se corrigió con una única fila de seis opciones y se verificó su encuadre. La recuperación de las pruebas se adaptó para esperar el nuevo asentamiento físico antes de armar.

El empaquetado exige SHA512 de las plantillas oficiales, igualdad del ejecutable, integridad de todas las entradas del PCK y scripts de juego byte a byte. También ejecuta el runtime Linux con el mismo PCK y **22 comprobaciones adicionales**, cargando los seis autos y completando un duelo del 133. La publicación comprueba el commit y manifiesto exactos, CRC/SHA256 de ambos ZIP y los archivos fuente del proyecto. Antes de entregar se verifica la importación del proyecto recién extraído y la descarga HTTPS completa. El resultado de Actions y los enlaces verificados se consignan en la entrega.

Windows, mando físico y GPU real no se ejecutan en este entorno. Las capturas por software no son un benchmark de rendimiento.

Rama: [`feat/surface-contact-classic-fiats`](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/tree/feat/surface-contact-classic-fiats). Base: 0.17. `main` se conserva estable. [Comparación preparada para PR](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/compare/feat/argentine-rules-flagship-models...feat/surface-contact-classic-fiats?expand=1) · [Descripción](PULL_REQUEST-0.18.md). La creación por API se intenta durante la entrega y no se informa un PR creado sin confirmación de GitHub.

Descargas separadas: [Windows](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/raw/refs/heads/downloads/v0.18/GT4-Evolution-0.18-Windows.zip) · [Proyecto Godot](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/raw/refs/heads/downloads/v0.18/GT4-Evolution-0.18-Proyecto.zip). Sus hashes acompañan los ZIP. La rama de distribución identifica el commit fuente y sólo se publica tras validación.

Próximo incremento: calibrar masa, caja y lanzamiento con fichas completas; mejorar dinámica lateral/diferencial y ampliar el entorno de preparación sin confundir el modo de fábrica con la categoría oficial Serie.
