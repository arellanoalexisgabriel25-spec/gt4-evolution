# GT4 Evolution 0.12

Esta versión mejora presentación, cámaras y respuesta de dirección sobre el
prototipo existente y sobre la dinámica aportada en `files.zip` para 0.11.

## Implementado

- Inicio con mapa navegable de servicios, paneles plateados, azul oscuro,
  acentos rojos y tipografía Barlow Condensed. Concesionario en tarjetas y
  presentación 3D del auto en inicio/garaje. Los ocho servicios siguen disponibles.
- Cuatro vistas: seguimiento, cercana, capó y paragolpes. Tab/RB cambia la vista;
  Shift/Y mira atrás y el stick derecho permite mirar alrededor, también en pausa.
  El brazo evita paredes y el seguimiento ya no acumula distancia al avanzar rápido.
- Dirección progresiva configurable, entrada más suave a alta velocidad y retorno
  más rápido al centro. Intensidad de teclado ajustable sin reducir el rango del mando.
- HUD compacto con telemetría real, vueltas, tiempos, clasificación, ayuda contextual
  y minimapa del circuito con posiciones físicas de jugador y rivales.
- Carrocerías procedurales propias, cristales, llantas, ruedas que giran y orientan,
  luces de freno y movimiento de carrocería. Cielo, iluminación, sombras, asfalto,
  césped, tribuna, pinos, paisaje y cartel originales.
- Preferencias anteriores compatibles; cámara inicial y dirección persisten por
  separado de la partida. Volver de la pista abre el garaje. Licencia en cabecera
  actualizada y reloj corregido al redondear sobre un cambio de minuto.

## Archivos y módulos

- `scripts/main.gd`, `racing_theme.gd`, `city_map.gd`: menús y navegación.
- `scripts/car_visual.gd`, `car_preview.gd`, `vehicle_actor.gd`: presentación del auto.
- `scripts/chase_camera.gd`, `control_settings.gd`: vistas, mirada y preferencias.
- `scripts/vehicle_physics.gd`, `vehicle_config.gd`: respuesta de dirección independiente.
- `scripts/race_hud.gd`, `track_map.gd`, `driving.gd`, `circuit_view.gd`, `session.gd`:
  HUD, circuito y conexión con la sesión existente.
- `assets/fonts/`: fuente OFL, licencia y procedencia verificable.
- `tests/test_camera_modes.gd`, `test_steering_response.gd`, `test_presentation.gd` y
  ampliaciones de pruebas de controles/conducción: nueva cobertura.
- `tools/capture_presentation.*`, empaquetador, publicador y workflow de pruebas:
  capturas reales, inclusión de fuente/licencia y distribución verificable.

## Comprobado

Godot 4.6.3 en Linux: **27 suites y 444 comprobaciones**, importación, compilación
de los 27 scripts de juego y arranque. Incluye carreras físicas completas de dos
vueltas con barreras y sin recuperación, economía, premios únicos, guardado/carga,
preferencias antiguas/nuevas, cuatro cámaras, obstáculo físico, seguimiento a
velocidad, dirección, navegación y transacciones desde el nuevo menú.

Se renderizaron y revisaron capturas reales de menús y vistas a **1280×720** con
Mesa/llvmpipe en Xvfb, corrigiendo recorte del mapa, anclajes del HUD, cartel
excesivo e iluminación demasiado intensa. El script captura diez imágenes y
rechaza errores del motor. La preparación gráfica se probó también iniciando
y cerrando un servidor Xvfb independiente.

La API de GitHub responde `Forbidden` en este entorno: no se confirma CI remoto
ni creación de PR. Se conserva `main` y se entrega la rama de desarrollo para revisión.

## Sigue siendo provisional

La conducción continúa siendo arcade y las carrocerías son geométricas; no hay
modelos comerciales, audio de motor, daños por impacto ni neumáticos completos.
Faltan prueba humana del manejo, ejecución en Windows, mando físico y rendimiento
en GPU real. Debutantes conserva su carrera física; los demás eventos continúan
marcados como simulados. El guardado del progreso sigue siendo manual.

Próximo incremento: ajustar el manejo con experiencia del jugador, mejorar sonido
y trazado, y ampliar las carreras físicas conservando las garantías económicas.

El código está en `feat/presentation-and-camera`, basado en
`feat/integrate-driving-dynamics`. Las descargas y capturas se publican por separado
en `downloads/v0.12`; esa rama de distribución no se integra en `main`.
