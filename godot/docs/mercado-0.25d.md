# Mercado realista sobre la 0.25, versión d (sin verificar en Godot)

Rebasado sobre el código real de la 0.25 (extraído del `.pck`); el parche aplicó sin conflictos. **No se ejecutó en Godot**: la lógica se calibró con un port numérico y se revisó a mano. Corré `tools/test_game.sh` antes de integrar. Reemplaza a `GT4-mercado-0_25c.zip` y a los anteriores.

## Datos incorporados del documento "Economía completa BA"
- **Costos de transferencia** (`market_fees.gd`): arancel DNRPA 1 %, sellos 3 %, verificación policial 55, informes 20, formulario 08 15 y gestoría opcional 90 (puntos medios de los rangos del documento). Una compra de ARS 8 M cuesta ~410 mil de transferencia, igual al ejemplo del documento. Si ya pediste el informe de dominio, no se vuelve a cobrar.
- **Tramos de estado** (`market_profiles.gd`, `market_pricing.gd`): para Fiat 133, 128, 125, Duna, Regatta, Punto, Uno Fire y Gol Power la referencia es el "buen estado" del documento y la curva de condición (0,62x en estado 50, 1,0x en 75, 1,32x en 100, más el premio por bajo kilometraje) reproduce los tres tramos (regular / buen estado / muy bueno) de los ocho modelos. Cronos y Siena usan la lista de 103 modelos; el resto conserva los precios del juego.
- **Liquidez**: Uno Fire y Gol Power alta; Punto, Cronos y Siena media; clásicos e importados baja. Los líquidos reciben más ofertas de particulares y las agencias pagan algo más; los clásicos venden más lento, pagan menos en agencia y tienen precios pedidos más volátiles.
- **Gastos de tener un auto** (`market_upkeep.gd`, cada 30 días de mercado, al usar "ESPERAR UN DÍA"): patente 2,5 % anual del valor (exenta a los 25 años), seguro mensual 40 a 120 según valor y VTV anual (105) desde los 3 años. Lo que el saldo no cubre nunca lo pierde: la patente impaga pasa a deuda que se descuenta al vender, el seguro impago se cuenta y una VTV impaga vence.
- **GNC** en autos de más de 12 años: -5 % en clásicos (a los coleccionistas no les gusta), +3 % en autos de uso diario.
- **Historial**: cada reparación documentada suma 1 % al valor de reventa (hasta 4 %) y los daños por choque lo bajan (hasta 12 %).
- **Ofertas originales**: las 23 ofertas iniciales se convierten en publicaciones de mercado (año, vendedor, papeles y precio de mercado) sin cambiar ID, modelo, kilometraje, estado ni fallas.

## Novedades de la versión d: financiación y cochera
- **Préstamos prendarios** (`market_loans.gd`): al comprar podés financiar en 12, 24 o 36 meses. El banco presta el 60 % del precio con calificación 50 (52 % con calificación 30, 75 % con calificación 88 o más) y cobra una tasa mensual de 3,0 / 3,4 / 3,8 % según el plazo, ajustada por la calificación. Pagás de entrada el resto del precio, los gastos de la compra y los del préstamo (1,5 % de comisión y 1 % de prenda sobre el capital). Con 10.000 de precio a 24 meses: se financian 6.000, la cuota es de 370 y los intereses suman 2.880 (48 % del capital).
- **Cuotas mensuales**: se cobran cada 30 días de mercado, antes de la patente y el seguro. Si no alcanza el saldo, la parte impaga queda en el préstamo con un recargo del 2 % de la cuota, la calificación baja 5 puntos y se bloquean nuevos préstamos. **Tres cuotas seguidas sin pagar y el banco secuestra el auto** (calificación -35). Pagar a tiempo suma 2 puntos; terminar el préstamo, 5; cancelarlo antes, 3.
- **Vender un auto financiado**: el préstamo se cancela con lo que paga el comprador. Si no alcanza y el saldo no cubre la diferencia, la venta se rechaza (el saldo nunca queda negativo). Se pueden tener como máximo 2 préstamos abiertos.
- **Cochera**: los dos primeros autos (por orden de compra) se guardan gratis; desde el tercero cada auto cuesta 55 por mes. Lo impago pasa a deuda del auto y se descuenta al venderlo.
- Todos los parámetros (tasas, porcentajes, límites) son del juego, **no ofertas bancarias reales**.
- Quedan fuera: la nafta del documento (a las distancias del juego cuesta centavos) y las cubiertas (el juego ya tiene su propio sistema de neumáticos).

## Refinamientos de la versión c
- **Reequilibrio verificado con una simulación de 20.000 operaciones por tipo de auto** (comprador que conoce el precio mínimo del vendedor, con trámites del documento). Con los recargos anteriores, comprar y revender sin mejorar el auto perdía de media un 11 % aun siendo cuidadoso (la mejor operación del 99 % rendía solo un 7 %): el comercio puro no tenía salida. Ajusté los vendedores (particulares piden 98-114 % del valor y aceptan bajar 6-16 %; agencias 105-115 % y bajan 2-6 %; apurados 80-96 % y bajan 4-10 %) y los compradores ofrecen entre 92 y 108 % del valor. Resultado: revender a ciegas a una agencia sigue perdiendo (~20 % de media), un comerciante cuidadoso que inspecciona y negocia queda cerca del equilibrio (media -2 %), el 10 % mejor gana ~10 % y el 1 % mejor ~23 %. Restaurar un auto agrega ~14 % por encima de eso. Una persona real no conoce el mínimo exacto, así que le rinde algo menos.
- **Tendencias de demanda por modelo**: cada modelo deriva 90-112 % alrededor del índice global (se guarda en `market["trends"]`) y el reporte diario muestra una noticia con el mayor movimiento ("Sube la demanda de Fiat 133 (+1,1 %)").
- **Corrección de interfaz**: el botón de garantía aparece mientras la garantía esté vigente, sin importar si el auto tiene averías (antes la presencia del botón delataba averías ocultas).

## Refinamientos de la versión b
Revisé el sistema buscando abusos y huecos y corregí lo siguiente:
- **Ofertas de compradores ancladas al valor real.** Antes ofrecían entre 82 y 97 % del precio pedido, así que publicando caro y esperando se vendía por encima del valor. Ahora ofrecen según lo que vale el auto (85 a 105 %) y nunca más del 97 % del pedido: un aviso inflado recibe pocas ofertas y ninguna por encima del valor.
- **Contraofertas que no delatan el piso del vendedor.** Antes la contraoferta caía justo sobre el precio mínimo. Ahora el vendedor cede menos en cada ronda (70 %, 45 % y 25 % de la diferencia, con una variación determinista de ±20 %).
- **Experiencia del comprador** (recomendación 8 del documento): cada compra o venta completada suma 0,4 puntos de flexibilidad en los vendedores, hasta 4 puntos. El contador `market["deals"]` se guarda en el reloj del mercado.
- **Odómetro adulterado**: 6 % de los particulares y 12 % de los apurados muestran menos kilómetros de los reales (nunca las agencias). La inspección lo revela y justifica una rebaja grande; si compras sin inspeccionar, te enterás después de pagar.
- **Service cada 10.000 km** (rango 80 a 200 del documento): un service vencido baja un 3 % el valor, y hacerlo cuenta como mantenimiento documentado en el historial (sube el valor de reventa).
- **Garantía de agencia de 30 días**: reparan sin cargo, una sola vez, las averías ocultas que aparezcan. Justifica el recargo de las agencias.
- **Guía de precios** en cada oferta: tramos regular / buen estado / muy bueno (los del documento para los ocho modelos prioritarios y derivados de la referencia para el resto), para negociar con información.

## Novedades de la versión anterior (por la 0.25)
- Los **36 autos** del juego tienen perfil de mercado: los 13 nuevos (Corsa, Amarok, Ranger, EcoSport, Corolla, Palio, Yaris, Ka, 208, Polo Classic, Virtus, Onix y Corolla Cross) toman su precio de la lista de modelos comunes (unidades de 5 a 10 años, referencia 2019). Corsa, Palio y Onix son de liquidez alta.
- **Los años de esos 13 modelos no figuran en ninguna fuente**: usan la ventana 2016-2021 de la lista y son provisionales. Los precios resultantes son bastante más altos que los del catálogo del juego (por ejemplo, la Amarok pasa de ~11 M a ~27 M de referencia).
- El mercado sostiene **48 ofertas** (36 originales más 12 extra rotativas).
- La Taos queda fuera: es solo de exhibición y nunca genera ofertas.
- La nueva física, la caja manual y el audio de las versiones 0.20 a 0.25 no se tocaron.

## Lo que ya traía la versión anterior
Inspección según el auto, informe de dominio, regateo con precio de reserva oculto, compra con trámites ocultos (deuda de patentes, prenda, falta de titularidad, VTV vencida), venta a agencia o publicada a particular, reparaciones proporcionales al valor, reloj de mercado con rotación de ofertas, rebajas semanales e índice de precios.

## Archivos
Nuevos: `market_profiles.gd`, `market_pricing.gd`, `market_fees.gd`, `market_listings.gd`, `market_negotiation.gd`, `market_deal.gd`, `market_state.gd`, `market_upkeep.gd` y `market_catalog.gd` (120 modelos de las listas, reservado para autos que todavía no existen en el juego). Modificados: `economy.gd` y `main.gd`. `mercado-0.25d.patch` es el diff de todo (`patch -p1` desde la carpeta que contiene `scripts/`).

## Decisiones y advertencias
- **Los precios cambian mucho respecto del catálogo del juego**: Uno Fire pasa de ~4,6 M a ~11 M, Gol Power de 5,9 M a 13,5 M y el 133 de 2,1 M a 4 M (los del documento). Con el saldo inicial de 12.000 unidades solo alcanza para un clásico, un importado barato o un Uno Fire/Gol en estado regular y negociando. Si querés más margen al empezar, subí el saldo inicial o ajustá `START_BALANCE`.
- Los precios del juego se siguen usando para los importados, el 147 Vivace, el 128 Súper Europa y el 500 Sport. Son provisionales.
- Los **años de referencia** de los modelos sin año firme son provisionales; solo ubican al auto en la curva de depreciación.
- Los gastos y las proporciones son aproximaciones de juego, no aranceles oficiales.
- Pruebas del repositorio que asuman que `buy` descuenta exactamente el precio, inspección fija de 200, reventa de 0,85 × precio o tarifas fijas de reparación van a fallar y hay que actualizarlas.

## Limitaciones
- Faltan por ahora: que la habilidad del jugador dependa de la reputación de la carrera y las ofertas de otras provincias.
- Interfaz mínima: `OptionButton` de ofertas y botones de publicación al valor, +10 % y +20 %.
- Sin garantía de agencias, estafas ni autos de otras provincias. El índice de precios es un paseo acotado, no inflación real.
- Los gastos solo corren cuando el jugador espera días; no hay otra fuente de tiempo en el juego.
- Servicio cada 10.000 km, cubiertas, nafta y cochera del documento quedan fuera por ahora.
