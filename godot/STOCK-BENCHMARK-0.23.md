# Banco reproducible 0.23

Banco numérico de motor, acoples y ejes; no es ensayo de fabricante ni replay 3D.
Pasos 1/60 s, 90 s, piloto 75 kg, piezas sanas/calle 20°C, asfalto seco, g 9,81,
aire 20°C/101.325 Pa (rho ≈1,204 kg/m³), viento cero. Largada objetivo 3400 RPM,
2400 en turbodiésel de limitador menor que 5000. El conductor cambia al 92% del
limitador con 0,22 s de embrague y espera sincronización; la CVT cambia relaciones
por su controlador. 0–100 empieza al superar 0,1 m/s. La velocidad a 90 s no es
máxima certificada. Frente a 0.22 cambia también el protocolo del conductor.

`godot --headless --path godot --script "$PWD/tools/benchmark_stock.gd" -- /tmp/stock-023.json`

| Modelo | Masa con piloto kg | CV de curva | ET s | 0–100 s | Velocidad a 90 s km/h |
| --- | ---: | ---: | ---: | ---: | ---: |
| Fiat 147 Vivace | 882 | 63.00 | 19.677 | 15.028 | 155.78 |
| Fiat Uno Fire 3 puertas | 985 | 68.00 | 19.788 | 15.274 | 159.33 |
| Volkswagen Gol Power 3 puertas | 1055 | 83.99 | 18.461 | 12.586 | 171.70 |
| Fiat 128 Súper Europa 1.5 | 925 | 82.00 | 18.595 | 12.643 | 171.44 |
| Fiat 133 | 755 | 34.00 | 24.519 | 28.559 | 121.13 |
| Fiat 128 estándar | 905 | 55.00 | 21.517 | 18.992 | 144.56 |
| Fiat 125 | 1095 | 90.00 | 19.352 | 13.909 | 172.92 |
| Fiat Duna | 1055 | 72.00 | 19.851 | 15.854 | 158.51 |
| Fiat Cronos | 1315 | 130.00 | 17.574 | 10.910 | 195.88 |
| Fiat Siena | 1125 | 103.00 | 17.744 | 11.346 | 184.37 |
| Fiat Punto | 1155 | 87.00 | 19.570 | 14.475 | 172.63 |
| Fiat Regatta | 1075 | 100.00 | 18.279 | 12.104 | 182.97 |
| Fiat 500 Sport | 1090 | 100.00 | 19.121 | 13.348 | 175.18 |
| Chevrolet Corsa 5 puertas | 1080 | 92.00 | 18.589 | 12.820 | 177.63 |
| Volkswagen Amarok | 1932 | 140.00 | 19.936 | 16.151 | 163.34 |
| Ford Ranger cabina simple | 1765 | 163.00 | 18.770 | 13.566 | 171.89 |
| Ford EcoSport | 1295 | 99.00 | 19.072 | 13.658 | 162.98 |
| Toyota Corolla | 1205 | 110.00 | 18.572 | 12.309 | 190.70 |
| Fiat Palio 5 puertas | 1030 | 72.00 | 19.833 | 15.210 | 161.69 |
| Toyota Yaris Sedán | 1125 | 106.00 | 18.351 | 12.122 | 187.34 |
| Ford Ka 3 puertas | 1005 | 60.00 | 20.837 | 17.845 | 151.42 |
| Peugeot 208 | 1125 | 115.00 | 18.071 | 11.668 | 187.71 |
| Volkswagen Polo Classic | 1115 | 100.00 | 18.504 | 12.589 | 179.39 |
| Volkswagen Virtus | 1265 | 110.00 | 18.537 | 12.607 | 185.42 |
| Chevrolet Onix | 1135 | 98.00 | 18.936 | 13.301 | 174.49 |
| Toyota Corolla Cross | 1525 | 170.00 | 16.805 | 9.615 | 187.26 |

Son resultados producidos por la simulación. El Uno y el 500 mantienen diferencias
frente a los 13,2 y 10,5 s de las referencias aportadas. Las relaciones, pérdidas,
neumáticos y el conductor deben contrastarse antes de hablar de fidelidad de cada
versión. No se fuerzan cronómetros ni potencias para ocultar esas diferencias.
La física de las carreras se valida por separado con ambos cuerpos en pista.
