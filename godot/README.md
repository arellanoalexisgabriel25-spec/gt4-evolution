# GT4 Evolution — Godot 4

Prototipo independiente de gestión de autos. La documentación de GT4 sirve como referencia, no se incluye el ejecutable ni recursos del juego original.

## Jugar
Abrí `project.godot` con **Godot 4.4** y ejecutá la escena principal (F5). Contiene mercado de 10 vehículos, compra y venta, taller, desgaste, registro de créditos y guardado.

## Pruebas
```sh
godot --headless --path godot --editor --quit
godot --headless --path godot --script res://tests/test_economy.gd
```
No hay conducción 3D, física de GT4 ni IA avanzada en esta primera versión. Los vehículos y precios son datos provisionales para probar la economía.

## Diseño
- Realismo equilibrado
- Economía muy exigente
- Carrera profesional estructurada (pendiente)
- Tuning profundo y mercado dinámico (pendientes)
- IA de rivales (pendiente)

Código en `scripts/economy.gd`; interfaz en `scripts/main.gd`.
