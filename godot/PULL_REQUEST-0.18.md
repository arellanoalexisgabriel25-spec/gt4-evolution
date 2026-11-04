# Clásicos Fiat y contacto físico por superficies

Descripción preparada para revisión; la entrega informa el resultado real de la creación por API.

Integra los modelos aportados del Fiat 128 Súper Europa, Fiat 133 y Fiat 128 estándar como ofertas persistentes IDs 14–16. Conserva las unidades anteriores y distingue ambos 128 FWD del 133 RWD, respetando las referencias de potencia aportadas y documentando los parámetros estimados.

Corrige tres fallos reproducidos: tracción sin suelo, fuerza residual por encima del agarre al cambiar de superficie y calor de frenado infracontado. Cuatro raycasts reales alimentan contacto, agarre y rodadura por eje; las superficies comparten límites con la geometría visible. El frenado registra la energía rotacional eliminada y las entradas no finitas se rechazan antes de mutar estado.

Los rigs conservan texturas y triángulos de los derivados y animan tapacubos claros sin depender únicamente de su color. Inicio ofrece los seis modelos sin recortar el mapa. El ZIP Windows utiliza un export real de Godot 4.6.3 en lugar del editor; plantillas oficiales, PCK, fuentes y manifiesto se verifican antes de publicar.

Validación: 53 scripts, 52 suites y 1.333 verificaciones en Godot 4.6.3; 33 capturas reales 1280×720. El empaquetado prueba el mismo PCK con runtime Linux y 22 comprobaciones de recursos y un duelo completo del 133. Se confirma además importación del Proyecto ZIP fresco y descargas SHA256/CRC en la entrega. Windows y mando físico requieren prueba en esos equipos.

Rama basada en feat/argentine-rules-flagship-models; main permanece estable. Exhibición de picadas sin premios ni campeonato nuevo. Documentación técnica en RELEASE-0.18.md y procedencia en assets/cars/README.md.
