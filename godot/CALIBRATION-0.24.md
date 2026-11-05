# Fichas y métricas de fábrica — revisión 0.24

Esta revisión audita las 26 fichas asociadas a los modelos aportados. Conserva
los valores físicos existentes: los documentos disponibles no justifican
reemplazar relaciones de caja, diferencial, masa o resistencia al avance con
otros valores. No se ajustaron fuerzas para obtener un tiempo de ¼ de milla.
La calibración del rendimiento real sigue pendiente de mediciones comparables.

## Evidencia y límites

Las fuentes conservadas son `Informe de Modelos Fiat.pdf`, el compendio
`Informe Técnico Automotriz Completo.pdf` y la transcripción del usuario para
el Uno Fire 3 puertas 2014. Cada referencia a los PDF incluye página y SHA-256.
Son documentos secundarios aportados por el usuario; no se comprobó su
contenido contra las hojas primarias de cada fabricante. El juego conserva
`manufacturer_verified = false`.

Se mantienen los anclajes ya incorporados: Vivace 63 CV, 10,4 kgf·m y 807 kg;
Uno 68 CV a 5250 rpm y 11,3 kgf·m a 2250 rpm; Súper Europa 82 CV a 5600 rpm y
12 kgf·m a 3000 rpm; 500 Sport 100 CV a 6000 rpm y 13,1 kgf·m a 4250 rpm.
La conversión es **1 kgf·m = 9,80665 N·m**, sin confundir CV métricos con hp.
El 500 mantiene la ficha de 100 CV solicitada aunque el modelo visual lleve
carrocería Abarth.

La auditoría agrega como objetivos documentados los pares que sí aparecen en
el compendio y ya coincidían con el código: Corsa 1.6 MPFI 138 N·m, Amarok
2.0 TDI 140 CV 340 N·m, EcoSport Rocam 150 N·m, Peugeot 208 EC5 150 N·m y
Virtus MSI 155 N·m. Esto no identifica el año, acabado o motor del escaneo:
`variant_mapping` continúa estimado. La masa de 1020 kg del Fiat 125 también
se registra como dato reportado; la convención de combustible y fluidos sigue
desconocida.

No se transfieren fichas entre generaciones o motores distintos: Gol Trend a
Gol Power, Punto europeo al regional, Ka SEL al Endura, Yaris 2022 al sedán
antiguo, Polo MSI al Classic, Onix Ecotec al SPE/4 ni Palio Weekend al hatch.
Los 470 N·m indicados para Ranger 3.2 tampoco se asignan al 3.0 del juego.
Las masas agrupadas o aproximadas del compendio no sustituyen masas de otra
variante. Las curvas entre puntos de referencia son interpolaciones estimadas,
no ensayos de dinamómetro.

## Magnitudes que siguen estimadas

Los PDF no aportan relaciones individuales de marcha, marcha atrás o grupo
final. Sus valores configurados y el nuevo valor común de reversa siguen
estimados, al igual que el radio de rodadura cargado, corte de RPM, CdA,
coeficiente de rodadura, pérdidas, inercias y capacidad del embrague. Los
parámetros de cabeceo de suspensión y diferencial también son estimaciones;
la potencia y la carrocería no certifican muelles, amortiguadores ni un LSD.

Las listas `estimated_fields` ahora incluyen los campos omitidos del Uno y
Gol, y la potencia provisional del Punto. `reported_fields` enumera únicamente
anclajes numéricos presentes en las referencias de esa ficha. Que una magnitud
sea reportada no convierte el resto del vehículo en una ficha homologada.

## Métricas reproducibles de transmisión

`stock_vehicle_specs.gd` expone funciones de cinemática con unidades SI:

```
RPM_motor = velocidad_m_s / radio_m × relación_marcha × grupo_final × 60 / (2π)
velocidad_m_s = RPM_motor × 2π / 60 × radio_m / (relación_marcha × grupo_final)
```

Las velocidades y relaciones son firmadas: la marcha atrás tiene relación
negativa; velocidad negativa por relación negativa produce RPM positivas.
Se rechazan radios o grupos finales no positivos, relaciones nulas y entradas
no finitas. La relación nula representa neutral sin conexión cinemática.

`metrics()` entrega km/h por 1000 rpm, velocidad geométrica al corte por
marcha y velocidad inversa por 1000 rpm. **La velocidad al corte no predice
velocidad máxima**: no considera potencia disponible, resistencia aerodinámica,
pendiente, deslizamiento de neumáticos ni embrague. En el Corolla Cross la
lista identifica exclusivamente el engranaje de salida y entrega aparte el
intervalo estimado del variador CVT.

Estas métricas permiten detectar errores de unidades, signos o escalas antes
de comparar ensayos. Para validar 0–100, 60 pies, ET y velocidad de salida
faltan relaciones verificadas, masa de ensayo, tamaño y radio de rodadura del
neumático, estado térmico, protocolo de cambio y condiciones de superficie.
Los tiempos oficiales reportados se conservan como referencias, sin afirmar
que la simulación ya los reproduce.

## Comprobación

`tests/test_specification_calibration.gd` cubre los 26 perfiles, procedencia y
estimaciones, conversiones RPM/velocidad firmadas, neutral, entradas inválidas,
distinción de CVT y los anclajes añadidos. Se complementa con las pruebas
existentes de referencia técnica y flotas nacional, regional y ampliada.
