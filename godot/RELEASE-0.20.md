# GT4 Evolution 0.20 / Preparación y largador automático

La pasada deja de depender de una orden de Enter. Se permite calentar físicamente antes del llamado, se corrigen los cambios simultáneos con acelerador y el HUD deja más pista visible. Se conservan las trece carrocerías aportadas, la ficha Sport del 500, las partidas y los modos anteriores.

## Implementación real

- `drag_start_procedure.gd` separa calentamiento, llamado/alineación, sostén continuo de ambos listos y pedido único de semáforo. Pausa detiene el reloj; llamado vencido cancela sin inventar ET, ganador o premios.
- Se inicia a +5 m delante de la línea, con una zona propia de 2,5–35 m. Al llamado, una asistencia explícita frena, alinea y sostiene antes de armar los cronómetros. Preserva temperatura, desgaste y distancia recorrida; la relocalización no suma kilómetros. Sólo se reinicia la métrica de aceleración. El regreso manual en reversa no está implementado.
- Primera y embrague del jugador, ambos autos detenidos sobre sus posiciones, apoyo real y salud apta son requisitos para iniciar. Enter no inicia y Start/Select pausa; el largador arma automáticamente los dos carriles. Soltar antes del verde conserva el falso de largada y las reglas de adjudicación anteriores.
- El freno de mano H/L3 actúa sobre el eje trasero y no es liberado por ABS. Se combina con acelerador y embrague en el modelo existente. No se añade potencia, temperatura gratuita ni inmovilización artificial para el burnout.
- La solicitud de cambio admite 0,10 s de diferencia entre eventos de embrague y palanca. Se puede mantener acelerador; el embrague sigue siendo obligatorio, el intento sin él desgasta, y limitador/sobrerégimen siguen físicos. La API estricta de cambio usada por IA permanece compatible.
- La cámara encuadra ambos carriles al alinear y vuelve progresivamente al jugador al abrirse una diferencia de 2–12m. Un rival distante no estira el brazo de seguimiento ni ocupa el primer plano.
- Durante la pasada se ocultan botones, ayuda permanente, preparación y diagnóstico extenso. Quedan instrumentos compactos, tiempos, rival y feedback transitorio. La pausa muestra telemetría completa y controles; el resultado espera a que ambos carriles se resuelvan.

## Referencia reglamentaria y decisiones de juego

El texto deportivo aportado, SHA256 `46b13eb02fac46a50381509129a82a2eaa623754d7d0bd262d35e5c9cc089acc`, art.11 autoriza calentamiento con rojo intermitente/amarillas de fondo y lo termina con azul. Exige hacerlo desde la línea hacia delante y prohíbe detrás. El art.10 asigna la largada al largador. Las luces del escenario reflejan esas fases.

**25 s de calentamiento, 30 s de preparación y 1,5 s de ambos listos son tiempos configurables del juego**, no duraciones publicadas por la organización. Los 60 s de presentación tardía no se convierten en un tiempo universal de burnout. La zona 35 m pertenece a Autódromo Sur, no a los límites del puente/cono de pistas oficiales. Fuera de zona se cancela esta preparación; el régimen completo de apercibimientos, segunda expulsión, admisión y campeonato sigue pendiente. [Fuente y alcance](REGULATIONS-REFERENCE.md).

## Calentamiento comprobado

Ensayo reproducible con unidades sanas de fábrica, asfalto seco y sin TCS: primera, 1,5 s al 75% con embrague pisado/H; después 5 s a pleno con embrague liberado/H.

| Auto | Avance durante 5 s | Temperatura delantera final | Trasera final |
| --- | ---: | ---: | ---: |
| 147 Vivace | 16,35 m | 52,44°C | 35,28°C |
| Uno Fire | 16,77 m | 46,62°C | 36,67°C |
| 500 Sport | 18,77 m | 49,58°C | 39,40°C |

No es un burnout estacionario. La técnica puede avanzar y exige parar dentro de la zona. Calentar es opcional; la goma de calle no se beneficia de sobrecalentarla. En aire o con embrague abierto no se fabrica calor de contacto; el ensayo comprueba límites de potencia, desgaste y consistencia térmica 60/120Hz. El protocolo no acredita prestaciones de fabricante ni convierte el modelo longitudinal en simulación completa.

## Eficiencia de modelos

Seis modelos anteriores usan texturas externas de 1024² y mipmaps, igualando la preparación de los siete nuevos. El Gol mantiene color, normal y metallic/roughness; el normal se renormaliza tras filtrar. Posiciones, normales de malla, UV e índices permanecen byteidénticos. Se conserva respaldo de fuentes fuera del juego; no se distribuyen duplicados innecesarios.

Los seis autos pasan de 45.659.228 a 24.473.780 bytes GLB+PNG (**−46,4%**). Sus escenas/texturas importadas pasan de 52.199.882 a 22.058.753 bytes (**−57,7%**). Son tamaños de recursos, no mediciones de FPS o memoria máxima. Se compararon 18 vistas antes y 18 después, además de 175 verificaciones visuales. Persisten irregularidades de escaneo y defectos previos de segmentación en Uno/Gol a grandes giros. [Procedencia y hashes](assets/cars/README.md).

## Validación y entrega

**Godot 4.6.3: 55 scripts, 65 suites y 1.968 verificaciones aprobadas**, sin errores de scripts/arranque. Las 46 capturas reales incluyen calentamiento, llamado azul, pasada despejada y diagnóstico en pausa. La entrega confirma exportación, proyecto fresco, Actions y descargas del commit final. El empaquetado comprueba las fuentes, el ejecutable oficial y todas las entradas del PCK; ejecuta el mismo paquete con runtime Linux y 37 verificaciones de modelos/carrera. El proyecto se reimporta y prueba recién extraído. Ambas descargas deben validarse completamente por HTTPS con SHA256/CRC antes de compartirlas.

Windows, mando físico y GPU real requieren prueba en esos equipos. No se modificó la ficha Sport de 100 CV/13,1 kgfm/seis marchas del 500 ni se le atribuyó potencia Abarth; las prestaciones aún necesitan calibración. Tampoco se implementó deformación estructural, neumático volumétrico o una caja con reversa.

Archivos principales: `drag_start_procedure.gd`, `drag_mode.gd`, `drag_strip.gd`, `drag_hud.gd`, `chase_camera.gd`, `manual_powertrain.gd`, `axle_traction.gd`, `drag_actor.gd`, `control_settings.gd`, recursos de seis autos y `optimize_runtime_textures.py`, más pruebas/capturas/exportación y documentación.

Rama [`feat/drag-preparation-driver-controls`](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/tree/feat/drag-preparation-driver-controls), basada en 0.19. [Comparación preparada para PR](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/compare/feat/national-fleet-mechanical-refinements...feat/drag-preparation-driver-controls?expand=1). Main conserva su estado hasta revisión e integración.

[Windows](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/raw/refs/heads/downloads/v0.20/GT4-Evolution-0.20-Windows.zip) · [Proyecto Godot](https://github.com/arellanoalexisgabriel25-spec/gt4-evolution/raw/refs/heads/downloads/v0.20/GT4-Evolution-0.20-Proyecto.zip).

Próximo incremento: regreso manual en reversa y alineación sin asistente, mejorar rig de Uno/Gol y calibrar prestaciones contra fichas exactas.
