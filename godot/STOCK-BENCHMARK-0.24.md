# Banco reproducible 0.24

Banco numérico del mismo tren longitudinal, sin escena 3D ni ensayo de fabricante.
Pasos 1/60 s durante 90 s; piloto 75 kg, unidades sanas de fábrica, neumáticos
de calle inicialmente a 20°C y asfalto seco plano. Gravedad 9,81 m/s²; aire a
20°C y 101.325 Pa (1,204 kg/m³), viento cero. No se alteran fuerzas ni tiempos
para alcanzar una cifra de catálogo.

Conductor determinista: objetivo de largada 3400 RPM (2400 en turbodiésel con
corte menor que 5000), reacción 0,12 s y cambios al 92% del corte. Mantiene el
embrague al menos 0,22 s y espera la sincronización real de la caja antes de
acoplar; luego espera un error de régimen menor que 12% del corte antes de otro
cambio. La CVT usa su variador/convertidor. 0–100 comienza al superar 0,1 m/s.
La velocidad a 90 s es una observación del banco, no máxima certificada.

```sh
godot --headless --path godot --script "$PWD/tools/benchmark_stock.gd" -- /tmp/stock-024.json
```

| Modelo | Masa con piloto kg | CV de curva | ET s | 0–100 s | Velocidad a 90 s km/h |
| --- | ---: | ---: | ---: | ---: | ---: |
| Fiat 147 Vivace | 882 | 63.00 | 19.760 | 15.157 | 155.77 |
| Fiat Uno Fire 3 puertas | 985 | 68.00 | 19.872 | 15.400 | 159.32 |
| Volkswagen Gol Power 3 puertas | 1055 | 83.99 | 18.552 | 12.728 | 171.69 |
| Fiat 128 Súper Europa 1.5 | 925 | 82.00 | 18.669 | 12.772 | 171.43 |
| Fiat 133 | 755 | 34.00 | 24.531 | 28.582 | 121.13 |
| Fiat 128 estándar | 905 | 55.00 | 21.581 | 19.105 | 144.56 |
| Fiat 125 | 1095 | 90.00 | 19.441 | 14.069 | 172.89 |
| Fiat Duna | 1055 | 72.00 | 19.884 | 15.896 | 158.51 |
| Fiat Cronos | 1315 | 130.00 | 17.687 | 11.086 | 195.87 |
| Fiat Siena | 1125 | 103.00 | 17.841 | 11.507 | 184.35 |
| Fiat Punto | 1155 | 87.00 | 19.676 | 14.642 | 172.61 |
| Fiat Regatta | 1075 | 100.00 | 18.362 | 12.251 | 182.95 |
| Fiat 500 Sport | 1090 | 100.00 | 19.220 | 13.518 | 175.17 |
| Chevrolet Corsa 5 puertas | 1080 | 92.00 | 18.687 | 12.986 | 177.62 |
| Volkswagen Amarok | 1932 | 140.00 | 19.952 | 16.181 | 163.34 |
| Ford Ranger cabina simple | 1765 | 163.00 | 18.770 | 13.574 | 171.89 |
| Ford EcoSport | 1295 | 99.00 | 19.209 | 13.882 | 162.96 |
| Toyota Corolla | 1205 | 110.00 | 18.647 | 12.431 | 190.69 |
| Fiat Palio 5 puertas | 1030 | 72.00 | 19.918 | 15.335 | 161.69 |
| Toyota Yaris Sedán | 1125 | 106.00 | 18.470 | 12.304 | 187.33 |
| Ford Ka 3 puertas | 1005 | 60.00 | 20.921 | 17.971 | 151.41 |
| Peugeot 208 | 1125 | 115.00 | 18.185 | 11.849 | 187.69 |
| Volkswagen Polo Classic | 1115 | 100.00 | 18.597 | 12.732 | 179.39 |
| Volkswagen Virtus | 1265 | 110.00 | 18.674 | 12.828 | 185.38 |
| Chevrolet Onix | 1135 | 98.00 | 19.042 | 13.472 | 174.49 |
| Toyota Corolla Cross | 1525 | 170.00 | 16.810 | 9.615 | 187.26 |

Los 26 perfiles completaron el banco y alcanzaron 100 km/h. Son resultados de
la simulación con este conductor. El Uno conserva una diferencia frente a los
13,2 s reportados y el 500 frente a los 10,5 s de su referencia; no se ocultan
alterando potencia o cronómetros. Las relaciones, pérdidas, inercias, neumáticos
y protocolo de ensayo requieren datos verificables antes de certificar fidelidad.

Respecto a 0.23 cambia el sincronizador, su tiempo efectivo, el acople y el
cabeceo. Las marcas de física anterior siguen históricas. Se prueban por separado
los duelos con ambos cuerpos, las colisiones y el cronometraje sobre distancia
real. [Arquitectura](MANUAL-TRANSMISSION-0.24.md) · [Fichas](CALIBRATION-0.24.md).
