# Integración en desarrollo

Base: versión 0.25, b58ce0f. Origen: GT4-mercado-0_25d.zip aportado por el usuario.

Se aplicó el parche sin conflictos. Se conservan las fuentes originales del adjunto en /workspace/market-review.
Pruebas Godot 4.6.3: mercado 62, integración 68, préstamos 29: 159 comprobaciones aprobadas.
Se corrigió la prueba de precios para incluir GNC, volatilidad por liquidez y redondeo; ahora valida límites por vendedor.
La regresión completa se detuvo en test_controller_navigation: esperaba inspección fija de 200; el mercado nuevo calcula un costo variable. Requiere revisar las demás expectativas económicas antes de publicar.

No se modificó la transmisión: sus pruebas de entradas simultáneas pasan, pero el fallo reportado por el usuario no está reproducido ni resuelto en esta integración. Tampoco se hicieron cambios gráficos o sonoros todavía. No se generó una descarga nueva.

Actualización: se ajustaron las pruebas de economía, inspección, navegación y presentación a los costos nuevos. Los siete duelos físicos ampliados pasan (112 comprobaciones); las pruebas de cambios simultáneos con entradas simuladas pasan (21). Se añadieron reflectores laterales y ventanas luminosas mediante MultiMesh; falta revisión gráfica con pantalla. El fallo comunicado en dispositivos físicos aún no se ha reproducido.
