# Línea visual 0.21

Referencia: `GT4_UI_System.zip`, aportada por el usuario. SHA256 `02823eda0c0ef04a698463f72b5531b2a9b243595d44cba71e608c9583bc4ea7`.
Contiene guías Markdown de dirección artística, paleta, tipografías y componentes;
se adapta al juego existente. Los originales quedan fuera del paquete jugable.

`racing_theme.gd` concentra fondo #0F1419, panel #1A2129, elevado #232B35,
borde #2E3845, acento #3A7CA5, hover #5BA3D0, selección #7EC8E3,
texto #E8EEF2 y secundario #8A97A3. Los bordes son finos y las tarjetas tienen
radios discretos; foco visible para teclado/mando. Verde/ámbar/rojo se reservan
para estados. Los instrumentos usan fondos oscuros translúcidos.

Se aplican Barlow Regular/SemiBold y Roboto Mono a los números de velocidad,
RPM, marcha, tiempos y saldo. Licencias SIL OFL y hashes en assets/fonts/README.md.
Se conservan datos, contratos de controles y lógica de todos los servicios.

Inicio, concesionario, garaje, taller, tuning, carrera, movimientos, ajustes,
pausa y HUD reciben el tema compartido. El mapa original y la plataforma de
exhibición adoptan fondos oscuros. No hay nuevas imágenes comerciales de GT4,
fuentes propietarias ni una dependencia externa de interfaz.

El HUD conserva su distribución compacta de 0.20. Diagnóstico y ayuda extensa
siguen en pausa; la preparación muestra sólo lo necesario antes del árbol.
Los resultados conservan ET, reacción y total medidos. Se comprueban límites
reales de controles a 1280×720 y 1280×800.

La adaptación no añade animaciones de rebote, blur, nuevas pantallas ficticias
o componentes que sustituyan los sistemas existentes. Próximo pulido visual:
transiciones sutiles y materiales/rigs de las carrocerías provisionales.
