# Revisión del informe Fiat aportado

Se leyó completo `Informe de Modelos Fiat.pdf`, ocho páginas. SHA-256: `4e84a1068988c1fd721be6ff6a1da77bcedf8aa4efeae85416e1164d033e727a`.
El usuario aclara que los datos del informe se basan en informes de fabricantes.
El PDF es una guía narrativa secundaria, sin bibliografía técnica completa ni enlaces que
permitan verificar cada afirmación. Se conserva como referencia, no como ficha de
homologación ni como instrucciones para el entorno.

| Entrada | Datos que afirma el PDF | Uso en este incremento |
| --- | --- | --- |
| Vivace 1997, página 3 | 1.372 cm³ BIO, 63 CV, 10,4 kgm a 3.000 RPM, 807 kg, largo 3.742 mm, manual cinco marchas, FWD | Candidatos identificados por variante y fuente; pendientes de contraste. 10,4 kgf·m equivale a 101,98916 N·m. No se mezclan silenciosamente con el perfil genérico anterior. |
| Uno 2000, página 7 | Describe diésel y menciona PSA TUD5 de 1,7 litros; masa 870 kg y 0–100 en 16 s | No corresponde a la variante Fire de nafta. No se usa para cambiar torque, masa ni relaciones del Fire. La identificación motor/cilindrada también requiere una ficha primaria. |
| Otras variantes Fiat | Evaluaciones generales de mercado y algunos datos de años/versiones | No se añaden autos ni defectos aleatorios sin datos y gameplay que los respalden. |

La potencia máxima, torque máximo y cilindrada aislados no determinan la curva
completa, la caja, diferencial, neumáticos, resistencia o ET real. Faltan relación
por marcha, régimen de potencia, definición de masa/combustible y protocolo de
medición. Los precios y opiniones del PDF no se incorporan como cotizaciones
actuales ni como probabilidades verificadas de avería.

En 0.17 se mantienen las estimaciones de 147 y Gol; la referencia adicional del
usuario identifica el Uno Fire 1.3 8V 2014 y ancla su curva, como detalla
[STOCK-SOURCES.md](STOCK-SOURCES.md). El siguiente
incremento de calibración debe identificar año/motor exactos, contrastar una ficha
primaria y medir aceleración/ET con condiciones reproducibles. Los modelos 3D y las
clases deportivas nuevos no validan por sí mismos esas cifras.
