# Flota Fiat y duelos entre modelos

Descripción preparada para revisión; la entrega confirma el resultado real de la creación por API.

Integra 125, Duna, Cronos, Siena, Punto, Regatta y 500 Sport como ofertas persistentes IDs 17–23. Conserva todos los autos/IDs anteriores y permite elegir un modelo rival distinto en duelos físicos, con masa, transmisión, tracción y ABS independientes. La réplica de IA no muta el auto del vendedor ni genera créditos. Inicio muestra coherentemente todos los modelos, incluido un auto antiguo ya poseído.

El 500 usa por instrucción del usuario la ficha Sport: 100 CV a 6.000 RPM, 13,1 kgf·m a 4.250 RPM, manual de seis marchas y sin turbo. La malla aportada tiene estética Abarth provisional; el Punto posterior usa un perfil 1.4 Fire estimado en lugar de confundirlo con el 2002 europeo del PDF. Las fuentes y límites se documentan.

Corrige el daño al motor según compartimento delantero/central/trasero y rechaza embragues no finitos/fuera de rango antes de alterar la caja. Los rigs nuevos subdividen sólo caras que cruzan contornos visuales; conservan superficie/UV y separan conteos fuente/render. Los originales se archivan intactos y las texturas derivadas se incluyen con importación explícita. El Gol conserva su GLB fuente con compresión de textura durante importación para respetar el límite de distribución.

Validación con Godot 4.6.3: 54 scripts, 59 suites y 1.761 verificaciones; 43 capturas reales a 1280×720. El paquete exige 36 verificaciones adicionales de recursos/carrera desde el PCK, arranque del mismo PCK con runtime Linux, importación fresca y CRC/SHA256. La entrega confirma el commit exacto de Actions y ambas descargas. Windows/mando físico requieren prueba en esos equipos.

Basada en feat/surface-contact-classic-fiats. Main estable; sin premios nuevos ni reinicio de partidas. Informe: godot/RELEASE-0.19.md.
