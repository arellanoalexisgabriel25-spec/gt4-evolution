# GT4 Evolution 0.24 / Transmisión manual y chasis

La caja manual ahora distingue selección, sincronización y acople. El acelerador,
la palanca y los pedales son independientes: W+C+E/Q solicita un cambio sin
levantar el acelerador. El par vuelve a las ruedas mediante un embrague con
recorrido, temperatura y desgaste. Se conserva el juego existente y sus 26 modelos.

## Implementado

- `ManualGearbox`: relaciones firmadas, eje primario con inercia y par de
  sincronización, espera finita y objetivo móvil. Si no alcanza la tolerancia
  antes del máximo, rechaza el cambio a neutro con aviso y desgaste; no ajusta
  de golpe las RPM del motor. Cajas de cinco o seis marchas usan la misma lógica.
- Reversa con torque, giro de ruedas y movimiento real; interbloqueo frente a
  dirección opuesta. En manual detenido: C+Q desde N; C+E selecciona primera.
  El Corolla Cross también dispone de selector R/N/D y reversa por relación fija.
- `ManualClutch`: zona de mordida, capacidad finita, calor por trabajo de
  deslizamiento, refrigeración, fade y desgaste persistente de transmisión.
  Recuperar conserva temperatura y daño; un embrague agotado no transmite par
  y exige taller. También se verifica el calentamiento con refrigeración cero.
- El motor integra RPM por inercia/par, con curva neta y relaciones existentes.
  El corte de inyección no impide un sobrerégimen impuesto por las ruedas.
  Una reducción abusiva puede causar una falla mecánica que requiere reparación.
- Acoples perfectos, aceptables, bruscos o rechazados con indicación, sonido
  procedural y vibración solicitada al mando. El feedback observa la física.
- Manual total sin rev-matching por defecto. AJUSTES guarda embrague automático,
  semiautomática con descarga de par y rev-matching opcional. La asistencia
  acelera el motor físicamente; no fija las RPM ni evita una reducción destructiva.
- Acelerador, freno y embrague simultáneos, con punta-tacón posible. Lectura de
  tecla física además de InputMap, palanca sin repetición y ventana de 100 ms
  para el orden de llegada de embrague/cambio. Asignaciones anteriores compatibles.
- El largador continúa automático: calentamiento, llamado, alineación y árbol
  común contra otro vehículo. El manual debe soltar embrague y frenos al verde;
  el HUD explica qué pedal lo retiene. El embrague asistido sostiene y libera
  en las fases correspondientes, sin un botón que dispare la carrera.
- `SuspensionPitch`: cabeceo por muelle/amortiguador e inercia configurables,
  integración analítica y efecto del estado de suspensión. Alimenta transferencia
  transitoria de carga y movimiento visual sin inventar peso o propulsión.
- `AxleDifferential`: envolvente abierta, LSD con sesgo/precarga finitos o
  bloqueada, a partir de los cuatro contactos y sus superficies. La frenada
  conserva su capacidad independiente. Los autos base usan diferencial abierto.
- Parámetros de transmisión, embrague, suspensión y diferencial exportables y
  sobrescribibles por perfil. La escala provisional de suspensión depende de masa.
- Auditoría de las 26 fichas: procedencia, anclajes reportados y estimaciones
  explícitos; métricas cinemáticas por marcha. No se cambiaron par/potencia o
  relaciones sin nueva evidencia ni se impusieron tiempos de fabricante.
- Showroom con iluminación y encuadre según tamaño, profundidad del tema común,
  referencias nocturnas en pista agrupadas en MultiMesh, cabeceo visual y cámara
  alineada al suelo. El centro sigue despejado durante la pasada; pausa añade
  temperatura/estado del embrague, cabeceo y capacidad del diferencial.

## Correcciones comprobadas

El código 0.23 ya aceptaba W+C+E en la reproducción sintética. No se encontró
un bloqueo explícito por acelerador. Esta revisión endurece la lectura física,
el orden de eventos y el feedback de sincronización; la prueba completa verifica
W mantenida, E antes de C en el mismo frame, cambios en movimiento y largada real.
Eso no comprueba el rollover eléctrico de cada teclado; las teclas son reasignables.

Se corrigen un umbral de pedal fijo que ignoraba la configuración, un vencimiento
de sincronización que podía engranar sin igualar velocidades y su primera
corrección prematura ante recuperación de wheelspin. El sincronizador ahora
persigue el régimen cambiante hasta su plazo real. Se conserva la distinción
entre motor calado recuperable y avería que requiere taller.

## Validación

Godot 4.6.3: **70 scripts, 87 suites y 3.497 verificaciones aprobadas**, más
arranque sin errores. Se revisan **74 capturas 1280×720** de interfaz, modelos,
duelos, reversa, ayudas y telemetría. Las pruebas nuevas incluyen entrada de teclado
real inyectada, salida al verde,
reversa con movimiento CharacterBody, sincronización con objetivo móvil, caja de
seis marchas, signos de potencia, ayudas/JSON, calor/desgaste, suspensión pasiva
y diferencial con adherencia desigual. Se mantiene la batería anterior.

El [banco de 26 perfiles](STOCK-BENCHMARK-0.24.md) es numérico y reproducible,
no un ensayo de fabricante ni una grabación 3D. Las carreras se verifican además
con dos cuerpos físicos y distancia real de 402,336 m.

## Límites

El sincronizador es un eje equivalente; no hay un tren multicuerpo con todas
las reacciones de engranajes. Se mantienen dos inercias rotacionales de eje,
no cuatro ruedas independientes; el diferencial no calcula su calor interno.
El cabeceo no incluye cuatro suspensiones independientes, recorrido vertical,
antisquat, geometría lateral o deformación estructural. La transferencia reducida
no certifica un chasis real. Embrague/sincronizadores, relaciones, neumáticos,
aerodinámica y numerosas variantes siguen estimados. El Uno y el 500 aún difieren
de los 0–100 reportados. El regreso a línea sigue asistido.

Windows y un mando físico necesitan prueba en esos equipos; el entorno valida
Linux, recursos y el mismo PCK de Windows. No se afirma hiperrealismo completo.
Las imágenes comerciales de GT4 no forman parte del juego. La investigación
original permanece intacta, al igual que main y las partidas anteriores.

[Arquitectura, ecuaciones y API](MANUAL-TRANSMISSION-0.24.md) ·
[Fichas y evidencia](CALIBRATION-0.24.md).

Rama `feat/manual-transmission-chassis-realism`, basada en la entrega 0.23.
[Comparación preparada para PR](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/compare/feat/longitudinal-physics-road-loads...feat/manual-transmission-chassis-realism?expand=1).
La entrega informa si la API permite crear el PR; no confunde comparación con PR.

[Windows](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/raw/refs/heads/downloads/v0.24/GT4-Evolution-0.24-Windows.zip)
· [Proyecto Godot](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/raw/refs/heads/downloads/v0.24/GT4-Evolution-0.24-Proyecto.zip).
Extraé el ZIP Windows completo y ejecutá `JUGAR.cmd` o `GT4Evolution.exe`.

Próximo incremento: contrastar relaciones/masas de variantes exactas y pruebas
humanas de pedal/cambio; después evolucionar las ruedas y la suspensión con
reacciones completas, conservando balances de potencia y datos reproducibles.
