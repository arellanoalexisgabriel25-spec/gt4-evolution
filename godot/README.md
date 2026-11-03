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
```
No hay conducción 3D, física de GT4 ni IA avanzada en esta primera versión. Los vehículos y precios son datos provisionales para probar la economía.

## Diseño
- Realismo equilibrado
- Economía muy exigente
- Carrera profesional estructurada (pendiente)
- Precios de mercado basados en condición, kilometraje y fallas (prototipo determinista)
- Tuning profundo (pendiente)
- IA de rivales (pendiente)

Código en `scripts/economy.gd`; interfaz en `scripts/main.gd`.

## Mercado y restauración v0.3
Los 10 vehículos de prueba usan un generador determinista. Algunas unidades contienen defectos latentes en motor o frenos: esos defectos no se muestran antes de pagar una inspección (200 Cr.). Tras comprar el vehículo, el taller aplica un recargo de 900 Cr. para reparar el componente afectado, además del coste del desgaste habitual. Una reparación exitosa elimina el defecto.

El valor base de un vehículo se ajusta por kilometraje, condición mecánica y defectos. La reventa incluye descuentos adicionales y no asegura ganancias por restauración. **Estas cifras son parámetros de diseño, no precios reales.**

Las partidas anteriores sin el campo opcional `faults` siguen siendo compatibles. Se mantiene el esquema 1 de guardado; el contenido cargado se valida antes de aplicar cambios.
