# GT4 Evolution — Godot 4

Prototipo independiente de gestión de autos. La documentación de GT4 sirve como referencia, no se incluye el ejecutable ni recursos del juego original.

## Jugar
Abrí `project.godot` con **Godot 4.4** y ejecutá la escena principal (F5). Contiene mercado de 10 vehículos, compra y venta, taller, desgaste, inspecciones, defectos reparables, valoración por estado y kilometraje, registro de créditos y guardado.

## Pruebas
```sh
godot --headless --path godot --editor --quit
godot --headless --path godot --script res://tests/test_economy.gd
godot --headless --path godot --script res://tests/test_inspection.gd
godot --headless --path godot --script res://tests/test_market_restoration.gd
godot --headless --path godot --script res://tests/test_career.gd
godot --headless --path godot --script res://tests/test_tuning.gd
```
No hay conducción 3D, física de GT4 ni IA avanzada en esta primera versión. Los vehículos y precios son datos provisionales para probar la economía.

## Diseño
- Realismo equilibrado
- Economía muy exigente
- Carrera profesional estructurada: 5 eventos de simulación, licencias R/B/A, reputación y premios únicos
- Precios de mercado basados en condición, kilometraje y fallas (prototipo determinista)
- Tuning inicial: cinco mejoras, compatibilidad por salud, bonus de simulación y desgaste adicional
- IA de rivales (pendiente)

Código en `scripts/economy.gd`; interfaz en `scripts/main.gd`.

## Mercado y restauración v0.3
Los 10 vehículos de prueba usan un generador determinista. Algunas unidades contienen defectos latentes en motor o frenos: esos defectos no se muestran antes de pagar una inspección (200 Cr.). Tras comprar el vehículo, el taller aplica un recargo de 900 Cr. para reparar el componente afectado, además del coste del desgaste habitual. Una reparación exitosa elimina el defecto.

El valor base de un vehículo se ajusta por kilometraje, condición mecánica y defectos. La reventa incluye descuentos adicionales y no asegura ganancias por restauración. **Estas cifras son parámetros de diseño, no precios reales.**

Las partidas anteriores sin el campo opcional `faults` siguen siendo compatibles. Se mantiene el esquema 1 de guardado; el contenido cargado se valida antes de aplicar cambios.

## Carrera profesional v0.4
La nueva pestaña **MODO CARRERA** ofrece cinco eventos simulados y desbloqueos basados en resultados: dos eventos de iniciación desbloquean licencia B, dos eventos regionales desbloquean A y finalmente se accede a la copa nacional. Los eventos requieren vehículo propio, condición segura e inscripción pagada; la simulación consume kilometraje y produce desgaste. Los premios de cada evento solo pueden cobrarse una vez para evitar duplicación de créditos. **Aún no hay carreras 3D ni rivales controlados por IA.**

La partida se guarda con un contenedor v2 que combina economía y carrera; el cargador acepta también partidas antiguas con el estado económico v1. La carga construye estados temporales para no sustituir la partida actual si alguno es inválido.

## Tuning v0.5
La pestaña **TUNING** ofrece ECU, escape, suspensión, frenos y neumáticos. Cada mejora cuesta créditos y solo puede instalarse una vez; el componente correspondiente debe tener salud de al menos 40/100. Las mejoras aumentan la puntuación de simulación de carrera. ECU y escape aumentan el desgaste del motor. El tuning instalado se guarda por vehículo y se valida al cargar la partida, sin cambiar el formato v1 de la economía.

No hay modificaciones físicas de potencia, curva de par ni neumáticos renderizados hasta introducir una simulación de conducción; los bonos son reglas provisionales de balance económico y carrera.
