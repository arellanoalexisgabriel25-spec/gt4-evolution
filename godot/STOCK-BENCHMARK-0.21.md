# Banco numérico stock 0.21

Ejecutado con Godot 4.6.3, mismo motor/embrague/ejes del juego. No es una carrera
3D ni una medición de un auto real. Calle, asfalto seco plano con apoyo completo,
20°C iniciales, salud 100%, masa en vacío configurada más 75 kg, TCS apagado y ABS
según perfil. Conductor reproducible: objetivo 3400 RPM de largada, cambio al 92%
del limitador y 0,22 s de embrague. Se integra a 60 Hz durante 90 s.
0–100 se interpola desde 0,1 m/s; ET usa rollout 0,20 m y 402,336 m. La velocidad a 90 s
no se declara velocidad terminal certificada. El giro de potencia se estima cuando
la fuente no lo especifica. Carga, neumáticos, caja, clima y conductor importan.

| Auto | Masa de ensayo kg | CV calculados | ET s | 0–100 s | Velocidad a 90 s km/h |
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

El Uno conserva la referencia 13,2 s y 158 km/h; el 500, 10,5 s y 182 km/h.
Los valores de la tabla muestran que **la calibración completa no está lograda**.
No se corrige el cronómetro, velocidad, torque o masa para ocultar esa diferencia.
El ensayo numérico y los tickets de una escena física se identifican por separado.

Reproducción desde la raíz, con XDG aislado como en DEVELOPMENT.md:

```sh
godot --headless --fixed-fps 60 --path godot --script "$PWD/tools/benchmark_stock.gd" -- /ruta/stock-benchmarks.json
```

El JSON incluye protocolo, fuentes, parámetros estimados y cada ticket.
