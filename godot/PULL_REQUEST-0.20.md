# Preparación de picadas y largador automático

La largada deja de depender de Enter y pasa a una preparación controlada por el largador: calentamiento autorizado delante de línea, luz azul/alineación y semáforo automático cuando ambos autos están listos. Se preservan cronometraje independiente, RT+ET, desgaste, partidas y liquidación única. El asistente de alineación se declara expresamente; aún no hay regreso manual en reversa.

Añade freno de mano trasero H/L3 con migración de teclas, calentamiento por patinamiento físico y buffer de 0,10 s para embrague/cambio simultáneos sin obligar a soltar acelerador. No añade temperatura o potencia gratuita. Durante la pasada el HUD oculta ayuda, botones y diagnóstico; en pausa conserva telemetría y controles. La cámara enmarca ambos carriles al alinear y se centra progresivamente en el jugador al abrirse la distancia.

Reduce texturas de los seis modelos previos a 1024² externas/mipmaps conservando datos de geometría/UV/materiales. Recursos importados: 52,20→22,06 MB; no se presentan como una medida de FPS. Se mantienen los originales en referencias fuera del juego.

Los arts.10/11 del texto aportado sustentan control del largador, calentamiento delante de línea y luces. 25 s de calentamiento, 30 s de preparación, 1,5 s de listo y la zona 2,5–35 m son parámetros del juego, no duraciones/medidas oficiales. No se implementa el campeonato ni el régimen completo de apercibimientos.

Validación nativa: 55 scripts, 65 suites y 1.968 verificaciones aprobadas, más 46 capturas reales. El informe RELEASE-0.20.md y la entrega detallan resultados de batería nativa, capturas, proyecto recién extraído, PCK exportado, Actions del commit final y descargas HTTPS con SHA256/CRC. Windows/mando físico/GPU real siguen pendientes. Basada en feat/national-fleet-mechanical-refinements; main conservado.
