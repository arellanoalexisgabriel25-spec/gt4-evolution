# Banco de fábrica 0.22

Banco **numérico** reproducible del mismo motor/embrague/ejes; no es una ficha de
fabricante ni un replay 3D. Los duelos físicos se verifican por separado.
Piloto de 75 kg, hardware sano, calle 20°C, piso seco, 1,225 kg/m³, pasos 1/60 s,
90 s; cambios al 92% del limitador con 0,22 s de embrague. Largada a 3.400 RPM,
o 2.400 RPM en los dos turbodiésel de menos de 5.000 RPM de limitador.
0–100 cuenta desde superar 0,1 m/s. La velocidad a 90 s no es máxima certificada.

Reproducción desde el repositorio: `godot --headless --path godot --script "$PWD/tools/benchmark_stock.gd" -- /tmp/stock-022.json`.

| Modelo | Masa con piloto kg | Potencia de curva CV | ET s | 0–100 s | Velocidad a 90 s km/h |
| --- | ---: | ---: | ---: | ---: | ---: |
| Fiat 147 Vivace | 882 | 63.00 | 19.687 | 15.056 | 154.90 |
| Fiat Uno Fire 3 puertas | 985 | 68.00 | 19.796 | 15.301 | 158.40 |
| Volkswagen Gol Power 3 puertas | 1055 | 83.99 | 18.468 | 12.603 | 170.86 |
| Fiat 128 Súper Europa 1.5 | 925 | 82.00 | 18.603 | 12.661 | 170.36 |
| Fiat 133 | 755 | 34.00 | 24.530 | 28.683 | 120.13 |
| Fiat 128 estándar | 905 | 55.00 | 21.526 | 19.033 | 144.10 |
| Fiat 125 | 1095 | 90.00 | 19.360 | 13.927 | 171.91 |
| Fiat Duna | 1055 | 72.00 | 19.858 | 15.884 | 157.93 |
| Fiat Cronos | 1315 | 130.00 | 17.579 | 10.920 | 195.08 |
| Fiat Siena | 1125 | 103.00 | 17.751 | 11.359 | 183.28 |
| Fiat Punto | 1155 | 87.00 | 19.578 | 14.494 | 171.91 |
| Fiat Regatta | 1075 | 100.00 | 18.284 | 12.115 | 181.92 |
| Fiat 500 Sport | 1090 | 100.00 | 19.128 | 13.362 | 174.10 |
| Chevrolet Corsa 5 puertas | 1080 | 92.00 | 18.594 | 12.834 | 176.90 |
| Volkswagen Amarok | 1932 | 140.00 | 19.941 | 16.176 | 162.78 |
| Ford Ranger cabina simple | 1765 | 163.00 | 18.777 | 13.584 | 171.29 |
| Ford EcoSport | 1295 | 99.00 | 19.080 | 13.681 | 161.97 |
| Toyota Corolla | 1205 | 110.00 | 18.579 | 12.321 | 190.19 |
| Fiat Palio 5 puertas | 1030 | 72.00 | 19.840 | 15.234 | 161.00 |

El Uno sigue por encima de los 13,2 s del dato aportado; el 500, de los 10,5 s.
El Corsa provisional registra 12,834 s frente a los 12 s genéricos del compendio.
Estas diferencias permanecen visibles; no se falsean temporizadores ni se ajustan
resistencia/adhesión para imponer resultados. Las otras seis fichas nuevas son
hipótesis de variante, con relaciones, masa y otros parámetros estimados.
Los seis duelos físicos nuevos completan ambos carriles; sus ET pueden diferir
unas milésimas por el movimiento/corte de los haces y el protocolo de conducción.
