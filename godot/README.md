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
godot --headless --path godot --script res://tests/test_rivals.gd
```
Hay una pista 3D de prueba con gráficos geométricos y conducción arcade elemental; no reproduce la física de GT4 ni implementa IA de conducción. Los vehículos y precios son datos provisionales para probar la economía.

## Diseño
- Realismo equilibrado
- Economía muy exigente
- Carrera profesional estructurada: 5 eventos de simulación, licencias R/B/A, reputación y premios únicos
- Precios de mercado basados en condición, kilometraje y fallas (prototipo determinista)
- Tuning inicial: cinco mejoras, compatibilidad por salud, bonus de simulación y desgaste adicional
- Perfiles de pilotos rivales y clasificación simulada (v0.6); IA de conducción real pendiente

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

## Rivales v0.6
Cuatro rivales con perfiles de habilidad, agresividad y consistencia compiten en eventos simulados. Cada campeonato enfrenta al jugador con dos contrincantes; la posición depende de la condición del vehículo, las mejoras y los valores del perfil rival. El historial de enfrentamientos y el resultado por evento se conservan en la partida. No existe comportamiento autónomo en pista todavía. Los resultados son reproducibles, sin aleatoriedad oculta.

## Conducción 3D v0.7
La nueva opción **CONDUCIR 3D** aparece en el garaje al poseer un vehículo apto. Abre un circuito de prueba recto con un vehículo geométrico controlable mediante W/↑ (acelerar), S/↓ (frenar/reversa) y A/D o flechas (dirección); ESC o el botón VOLVER regresa al garaje sin perder la economía y carrera de la sesión. Los kilómetros enteros recorridos se transfieren al historial y al desgaste al volver; recorridos inferiores a un kilómetro no se acumulan de momento.

Esta es una **demostración de control y escena 3D**, no un simulador físico, ni un port del motor de GT4. No incluye rivales conducibles, circuitos reales, colisiones con otros vehículos ni representación de modelos de marcas comerciales. La conducción de prueba no otorga premios de carrera.

## Contrarreloj 3D v0.8
El garaje abre ahora un circuito cerrado original con ocho controles de paso y barreras con colisión. Las vueltas solo cuentan al atravesar todos los controles en orden y en el sentido indicado por el trazado. El HUD muestra la vuelta, los controles superados, el tiempo actual y la mejor vuelta de esta visita al circuito. Reiniciar con R invalida la vuelta actual y conserva la distancia recorrida y los resultados completados; no otorga créditos.

El estado del motor, los frenos y los neumáticos afecta a la conducción arcade. ECU y escape mejoran aceleración y velocidad máxima; frenos, neumáticos y suspensión mejoran frenada y respuesta de giro. Salir del asfalto limita la velocidad. ESPACIO frena sin pedir marcha atrás. Estas reglas son parámetros propios del prototipo: no proceden de la física original de GT4. Las carreras de la pestaña carrera siguen siendo simulaciones.

Pruebas adicionales:
```sh
godot --headless --path godot --script res://tests/test_time_trial.gd
godot --headless --path godot --script res://tests/test_handling.gd
godot --headless --path godot --script res://tests/test_driving.gd
```

El proyecto completo se validó con Godot 4.6.3 en Linux sin interfaz gráfica. El paquete Windows incluye el motor oficial con su SHA-512 comprobado; su ejecución en Windows requiere prueba en ese sistema.

La física arcade ahora está separada del montaje de escena: entradas progresivas, agarre lateral limitado, derrape recuperable, transferencia longitudinal simplificada y diferencias entre tracción delantera, trasera e integral. Dos recursos configurables definen las bases de los vehículos. La cámara sigue al auto con suavizado independiente; el HUD muestra RPM y marchas automáticas. El motor, frenos y neumáticos desgastados, y las mejoras instaladas, afectan al controlador.

Para ejecutar toda la validación: `bash tools/test_game.sh`. Arquitectura, limitaciones y prioridades de continuación en [DEVELOPMENT.md](DEVELOPMENT.md).

## Transmisión v0.8.1
Las RPM se calculan ahora a partir de velocidad, radio de rueda, relación de marcha y diferencial, con ralentí y límite configurables. Los cambios automáticos son secuenciales y tienen umbrales separados de subida/bajada e intervalo mínimo para evitar oscilaciones. La marcha atrás tiene su propia relación. Son parámetros provisionales del prototipo; la aceleración todavía usa el modelo arcade anterior, sin simulación completa de embrague o par motor.

Se inspeccionó el repositorio completo de investigación de GT4 y se registraron las fuentes concretas y sus límites en [REFERENCES.md](REFERENCES.md). No se importaron recursos comerciales. Validación de este incremento: 11 suites y 190 aserciones aprobadas con Godot 4.6.3 en Linux headless; Windows requiere prueba en ese sistema.
