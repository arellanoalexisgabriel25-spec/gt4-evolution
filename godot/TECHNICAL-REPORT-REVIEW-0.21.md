# Revisión del compendio técnico 0.21

Se leyeron las cinco páginas de `Informe Técnico Automotriz Completo.pdf`.
SHA256 `4aeb432f9ca26c72e09f39742fc1421921c5536286d9de40fac88a633934f1f0`.
Es una compilación aportada por el usuario, con tablas de varios años y versiones.
No incluye una ficha primaria identificable para cada celda. Se registra su
procedencia; no se convierte automáticamente en una homologación de fabricante.

| Auto del juego | Fila del compendio | Decisión aplicada |
| --- | --- | --- |
| 147 Vivace | 1997, 1.4 BIO 1372 cc, 63 CV, 10,4 kgm, 807 kg, 3742 mm, MT5 | Se adopta esa variante. Torque SI 101,98916 Nm; el PDF Fiat anterior aporta 3000 RPM de par. Régimen de potencia 5500 RPM estimado, explícito. Masa se asume en vacío: convención de combustible/líquidos aún sin verificar. |
| Uno Fire 2014 | Agrupa diésel 2000 y Fire 70 CV, 870–900 kg | Se conserva la referencia específica previa: 68 CV/5250 y 11,3 kgm/2250, sin ABS. La fila diésel no cambia su motor. |
| Gol Power 3 puertas | Gol GL/GLD y Gol Trend | No son la misma identificación: no se asignan sus 90/101 CV ni 1160 kg al Power. |
| 125 | 1.6 Twin Cam, 90 CV, 1020 kg, MT5 | Coincide con referencias ya usadas; no aporta curva ni relaciones exactas. |
| 128 estándar / Súper Europa | 1.1 55 CV /1.5 82 CV a 5600, 830–900 kg, MT4–5 | Se mantienen variantes separadas y la referencia específica previa del Súper Europa. Un intervalo agrupado no elige una caja o masa por sí solo. |
| 133 | 843 cc, 34 CV, 680 kg, MT4, 120 km/h, cuatro tambores | Confirma referencias previas. No hay datos de torque/RPM ni frenado para calibrar un modelo térmico de tambores. |
| Duna | 1.7 diésel, 72 CV, ~980 kg | Se mantiene la referencia previa; faltan curva, grupo y protocolo. |
| Cronos | 1.3/1.8, MT/AT, 1170–1220 kg | No se elige una masa/relación de transmisión sin año, motor y equipamiento de la unidad. |
| Siena / Grand Siena | 1.4/1.8, 1100–1125 kg | Se registra el intervalo, sin confundir carrocerías y motores ni reemplazar silenciosamente la estimación actual. |
| Regatta | 1.6 100 CV, 900–950 kg | El intervalo se conserva como candidato; sigue pendiente identificar variante y convención de masa. |
| 500 Sport | 1.4 100 CV/6000, 13,1 kgm, MT6, ~950 kg | Se conserva la ficha Sport indicada por el usuario y la masa de desarrollo 1015 kg. La aproximación ~950 no se utiliza para forzar un 0–100 de 10,5 s. La malla Abarth sigue provisional. |
| Punto | No hay una entrada específica | Se mantiene el perfil regional 1.4 estimado, sin copiar datos de Argo u otro Fiat. |

Las restantes marcas/modelos se conservan como referencia futura; no se añaden
vehículos sin catálogo, identificación, modelo y pruebas. `N/D` no significa
cero torque. PBV (por ejemplo Iveco) no es masa en vacío. No se intercambian CV,
hp, kgf·m y Nm ni se inventan relaciones a partir del número de marchas.

La nota aerodinámica es general. Cd y área deben multiplicarse, y el radio de
rodadura no se deduce de una llanta sin su neumático/carga. La banda de Crr
0,008–0,010 se conserva como referencia; no sustituye automáticamente el 0,014
actual sin un protocolo. El banco de 90 s sirve para observar diferencias y errores,
no para imponer máximas/tiempos de fabricante.

## Marca de referencia y partidas

El 147 cambia de curva/masa y usa revisión `vivace_14_bio_1997_021`. El HUD consulta
la mejor marca de esa revisión. Las anteriores siguen visibles como históricas,
y se archivan al primer nuevo resultado válido. Las nuevas marcas no se comparan
con otra ficha ni borran las anteriores. Los campos de historial son opcionales
al cargar partidas previas. Se conservan propiedad, IDs, saldo y desgaste.

## Referencias audiovisuales

Se intentaron los enlaces proporcionados del canal Comunidad de las Picadas y
`https://www.youtube.com/live/mzLhNHNwW-I?si=johvTkew3f5pTJJz` mediante el proxy
configurado. Ambos devolvieron CONNECT 403. No se recibieron imágenes ni audio,
no se vio el video y no se extraen tiempos, maniobras o infracciones de él.
Se conserva la secuencia basada en los textos reglamentarios ya aportados.
