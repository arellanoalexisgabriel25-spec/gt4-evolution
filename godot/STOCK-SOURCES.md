# Referencias para autos de fábrica y carreras de dos carriles

Estado de investigación al 4 de noviembre de 2026. Este registro distingue
fuentes consultables, intentos bloqueados y parámetros de desarrollo. No hay
una validación de fabricante ni una homologación deportiva de esta entrega.

## Consulta web histórica anterior a 0.17

El usuario indicó <http://cuartodemilla.com.ar/> como referencia de la actividad
en Argentina. Se intentó acceder por la ruta de red configurada del entorno:

| Destino | Resultado observado |
| --- | --- |
| `http://cuartodemilla.com.ar/` | HTTP 403, cuerpo literal `Domain forbidden` |
| `https://cuartodemilla.com.ar/` | Proxy CONNECT 403; no se recibió contenido del sitio |
| `https://www.fiat.com.ar/` | Proxy CONNECT 403; no se recibió contenido del fabricante |
| `https://www.volkswagen.com.ar/` | Proxy CONNECT 403; no se recibió contenido del fabricante |

La política de salida es restringida y esos destinos no estaban habilitados en
la instantánea del ejecutor. No se desactivó el proxy ni se utilizó un servicio
de retransmisión. También se buscaron posibles documentos ya publicados en
repositorios públicos de GitHub; no se encontró documentación verificable de
estas variantes o del reglamento indicado. Los registros locales de los
intentos están en `/workspace/artifacts/quarter-mile-reference*`,
`fiat-reference.html` y `vw-reference.html` cuando la respuesta produjo archivo.

En esa investigación anterior a recibir los textos, **no se pudieron verificar** categorías, pisos de tiempo, tolerancias, caídas,
secuencia de semáforo, clasificación, reglamento vigente ni especificaciones
de fábrica a través de estas fuentes. Una categoría configurable del juego
debe identificarse como propia del juego hasta contrastarla con un reglamento
real fechado y sus posibles actualizaciones. No se atribuyen datos al sitio
solo porque su enlace esté registrado aquí.

Para continuar la consulta directa se requieren los dominios
`cuartodemilla.com.ar`, `www.cuartodemilla.com.ar`, `www.fiat.com.ar` y
`www.volkswagen.com.ar`, además de cualquier dominio documental al que realmente
redirijan. Las redirecciones adicionales deben identificarse al recibirlas,
sin suponer que esta lista es suficiente ni reemplazar otros permisos de red.

Desde 0.17 los textos completos aportados permiten transcribir los pisos y reglas
en [REGULATIONS-REFERENCE.md](REGULATIONS-REFERENCE.md). La descripción posterior
del Uno 2014 transcribe datos de fabricante y se registra al final de este documento.
Esos nuevos aportes no están sujetos al fallo de acceso web histórico.

## Identificación y trazabilidad de cada auto

Los nombres comerciales 147 Vivace, Uno Fire y Gol Power no determinan por sí
solos año, cilindrada, código de motor, combustible o transmisión. Para afirmar
que un perfil reproduce una unidad de fábrica hace falta una ficha que identifique:

- Mercado, año/modelo, versión y motor/transmisión concretos.
- Potencia neta al cigüeñal y su régimen; par máximo y su régimen.
- Masa en orden de marcha con definición de líquidos/combustible y equipamiento.
- Masa de conductor y carga añadida en el ensayo.
- Relaciones de todas las marchas y grupo final, medida de neumático y radio
  efectivo de rodadura, que difiere del radio geométrico descargado.
- Condiciones de cualquier ensayo 0–100 km/h, 400 m/402,336 m, velocidad máxima
  o frenado: terreno, temperatura, altitud, combustible, conductor, carga y método.

Una ficha publicada en un repositorio de terceros requiere atribución y contraste:
estar alojada en GitHub no la convierte en documentación oficial. Las cifras
anteriores de `car_catalog.gd` se declararon aproximaciones de desarrollo; sus
tiempos de ensayo del prototipo no son mediciones de vehículos reales.

## Coherencia física que sí puede verificarse sin esas fichas

- `P [kW] = T [N·m] × RPM / 9549,2966`. Las curvas deben respetar simultáneamente
  potencia y par; aumentar torque sin comprobar potencia cambia el auto completo.
- Un caballo métrico `CV = 735,49875 W`; un `hp` mecánico equivale aproximadamente
  a `745,69987 W`. No deben intercambiarse silenciosamente.
- La potencia del motor y la de rueda son magnitudes distintas. Las pérdidas de
  transmisión se aplican una vez; la energía de embrague y el crecimiento de RPM
  también consumen potencia durante un transitorio.
- La masa de un ensayo incluye conductor/carga y la resistencia aerodinámica
  depende de las condiciones. Un 0–100 calculado debe indicar esas condiciones.
- Una carrera entre dos vehículos debe distinguir reacción, tiempo de recorrido
  y llegada desde el verde. El ET más bajo no implica por sí solo cruzar primero.
  Esa distinción física no demuestra haber reproducido las infracciones o el
  sistema de clasificación particular de una organización.

Los ensayos deterministas del juego sirven para comprobar estas identidades,
regresiones y diferencias entre configuraciones. La calibración contra valores
de fábrica o pista real sigue pendiente mientras no haya fuentes contrastables.


## Referencia de fabricante aportada para Uno Fire 2014 (0.17)

El usuario identifica la variante argentina **Uno Fire 1.3 8V de tres puertas, año
2014**, primera generación con restyling regional de 2004 e importación brasileña.
Aclara que los datos proceden de informes de fabricantes; se registran como
transcripción aportada, sin afirmar que el entorno abrió el documento primario.

- Potencia: **68 CV a 5.250 RPM**; torque: **11,3 kgf·m a 2.250 RPM**, equivalente
  a **110,815145 N·m** (gravedad estándar 9,80665).
- Referencias declaradas: máxima **158 km/h**, **0–100 en 13,2 s** y cinco marchas.
- Sin ABS ni airbags. La configuración de fábrica del duelo mantiene ABS apagado.
- El perfil nuevo ancla la curva en ambos pares de torque/potencia y régimen;
  la interpolación, limitador, masa, caja/diferencial, radios y aerodinámica siguen
  estimados. No se inventan relaciones a partir del número de marchas.
- Los 13,2 s y 158 km/h son **objetivos de contraste**, no resultados simulados.
  El juego no impone una velocidad o aceleración para alcanzar esos números.
- Se preservan el nombre estable del catálogo, ID de unidad y partidas anteriores;
  la etiqueta de variante identifica 2014 en la ficha. El recurso 3D de cinco puertas
  sigue siendo provisional para esta variante.

El informe PDF aportado se revisó por separado en [FIAT-REPORT-REVIEW.md](FIAT-REPORT-REVIEW.md).
Su entrada Uno diésel no sustituye esta ficha Fire de nafta.
