# Historial de versiones

Cada versión tiene su propio commit y una etiqueta de git (por ejemplo `golpe-v2.3`).
Para abrir una versión vieja: `git checkout golpe-v1.0` y abre el `index.html` de ese juego.

---

## El Gran Golpe — `juegos/el-gran-golpe`

Atracos a bancos con una banda de ladrones, reloj de policía y una barra de nervios que puede quebrar al equipo.

| Versión | Etiqueta | Cambios |
|---|---|---|
| — | — | Francisco Hernandez (entre v2.7 y v2.10): Escondite a pantalla completa con barra lateral, panel de objetivos plegable bajo el header, fondo pixel art del escondite, música del menú y del golpe (con fundidos y silencio entre vueltas), miniaturas de bancos como imágenes, iconos en la pantalla inicial. |
| 2.10 | `golpe-v2.10` | Paso, formación y asegurar zona se desbloquean al completar un golpe en la Caja del Malecón y sirven en cualquier golpe. Tutorial guiado de cada función en el golpe siguiente; recuadro CÓMO FUNCIONA la primera vez en Reclutar, Trabajitos, Mercado e Inversiones. Tarjeta NUEVO fija hasta ENTENDIDO, una por golpe. Sobre la cabeza solo se ven las bajadas de nervios con su causa (▼ HERIDO -8); arreglado que el signo menos no se dibujaba. |
| 2.9 | `golpe-v2.9` | Don Ramiro vende cada golpe: el dato se suma a la deuda (Coral $2.500, Malecón $5.000, Reserva $12.000), deuda inicial $30.000, interés 5% semanal, límite $150.000. La deuda solo baja con golpes bien hechos. Nuevo ENCARGO DE DON RAMIRO (baja la deuda $2.500–$4.000, con riesgo). Planos del traslado a $60.000. Los marcadores verdes de las órdenes ya no se quedan pegados al planear o en pausa. |
| 2.8 | `golpe-v2.8` | Historias del golpe: cada golpe a los nervios muestra su número y su causa; a veces, al borde del quiebre, un miembro se crece (10 s imparable y rasgo permanente Héroe de la banda); MOMENTOS DEL GOLPE en el resultado; La Gaceta del Malecón con titular y fama (mejores reclutas). Desbloqueos progresivos: reclutar, trabajitos, fama, vigilancia, paso, equipo avanzado, asegurar zona y formaciones, inversiones; máximo 2 novedades por visita al escondite con tarjeta NUEVO. Ajuste: EL GRAN GOLPE pide 6 bolsas. Sobre el nuevo escondite de Francisco. |
| 2.7 | `golpe-v2.7` | Paso del equipo (SIGILO/NORMAL/RÁPIDO, tecla R), formaciones (cuña, línea, fila, compacta; tecla F), ASEGURAR ZONA en la rueda, TODOS A LA VAN y plazas fijas en la camioneta. Empleados y guardias ahora corren físicamente al panel y tardan 3 s en activarlo (antes los guardias la daban por radio a los 5 s desde cualquier lugar). La orden BÓVEDA ya no le quita el técnico al panel. Caja de objetivos fuera del mapa (siguiente paso, amenazas, objetivos, equipo). Tabla de equipo en el resultado. Inhibidor y chofer se gastan por golpe; los flashes propios ya no se suman al almacén. Ajuste: policía Malecón 3:00, Reserva 2:40; en EL GRAN GOLPE abrir la bóveda dispara la alarma (60 s). |
| 2.6 | `golpe-v2.6` | Arreglos: el panel de seguridad ya se puede cortar en todos los mapas (el técnico quedaba fuera de alcance); al mandar un grupo a la bóveda o al panel, el resto del grupo escolta al especialista; las órdenes muestran su ruta desde la planificación. Nuevo: botón ÚLTIMO GOLPE en el escondite (qué se perdió y a quién), REINICIAR GOLPE en la pausa (gratis antes de empezar; después cuenta como abandonar) y OTRO GOLPE AQUÍ en el resultado. |
| 2.5 | `golpe-v2.5` | Grupos y rutas en la misión: elegir varios (Shift+clic, botón + en la tarjeta o Shift+número), AGRUPAR/SEPARAR (J) para que caminen juntos al paso del más lento, BORRAR TRAMO (Z) y CANCELAR RUTA (X) en el panel y en la rueda de órdenes; paso nuevo en el tutorial. |
| 2.4 | `golpe-v2.4` | Balance anti-exploits: sistema de semanas (alquiler e intereses también en trabajitos y bajar el perfil; condenas en semanas), vigilancia por banco, huir sin botín no cuenta, desbloqueo con 2★ y mitad de bolsas, penalización por abandonar o recargar a medias, objetivo final con plazo de 30 semanas (deuda → Reserva 2★ → planos → EL GRAN GOLPE) y pantalla de victoria con rango. |
| 2.3 | `golpe-v2.3` | Tutorial guiado de 10 pasos la primera vez que juegas; se puede repetir desde MENÚ → TUTORIAL. |
| 2.2 | `golpe-v2.2` | Se quita la columna de botones. Eliges a una persona o a toda la banda y haces clic en el mapa: aparece una rueda con las órdenes que tienen sentido para lo que tocaste (suelo, puerta, bóveda, panel, bolsa, enemigo, compañero quebrado). Botones GO A/B y ¡HUIR! solo cuando hacen falta. |
| 2.1 | `golpe-v2.1` | Menú por pantallas: Escondite central, planificación en 4 pasos (banco → banda → equipo → confirmar) y Ajustes (pantalla completa, volumen, temblor, velocidad, Tiempo Halcón). |
| 2.0 | `golpe-v2.0` | Rehecho visual: resolución doble, pantalla completa, mapas 40×26 con calle, autos, árboles y mobiliario; luces de noche, personajes más detallados, marcadores de objetivos y lista de objetivos. |
| 1.2 | `golpe-v1.2` | Niveles 1–10, rasgos que mejoran o empeoran según lo vivido, secuelas de trauma, cárcel con fianza o condena de 5 golpes. |
| 1.1 | `golpe-v1.1` | Economía con grind: objetos de un solo uso que se pierden si fracasas, parte de la banda, alquiler, deuda con interés, trabajitos e inversiones permanentes. |
| 1.0 | `golpe-v1.0` | Primera versión: 3 bancos, especialistas, bóveda, panel de seguridad, civiles, policía por oleadas, nervios y quiebres, carrera con reclutas y mejoras. |

## Escuadrón Halcón — `juegos/escuadron-halcon`

Mando de un equipo táctico que asalta edificios.

| Versión | Etiqueta | Cambios |
|---|---|---|
| 1.2 | `halcon-v1.2` | Campaña roguelite con edificios generados, agentes con rasgos y muerte permanente; centro de mando (dron, cámaras, apagón, bloqueo de puertas); Tiempo Halcón; clic para caminar y joystick táctil. |
| 1.1 | `halcon-v1.1` | Modo Líder (controlas al líder) y órdenes rápidas DESPEJAR y TODOS. |
| 1.0 | `halcon-v1.0` | Primera versión: 3 misiones, rutas por agente, puertas, flashes y códigos A/B, niebla de guerra. |

## Bastión Arcano — `juegos/bastion-arcano`

| Versión | Etiqueta | Cambios |
|---|---|---|
| 1.0 | `bastion-v1.0` | Tower defense: 6 torres con 3 niveles, 8 tipos de enemigo con jefes, 3 mapas, 30 oleadas, combos y efectos. |

## Grutas Arcanas — `juegos/grutas-arcanas`

Mazmorra con física de arena que cae (estilo Noita) y hechizos.

| Versión | Etiqueta | Cambios |
|---|---|---|
| PC 1.1 | `grutas-pc-v1.1` | Mundos más grandes y fáciles de navegar, generación más suave, mejor iluminación. |
| PC 1.0 | `grutas-pc-v1.0` | Versión para PC con el mejor pixel art: texturas, luces de color, parallax. |
| Roblox 1.0 | `grutas-roblox-v1.0` | Port a Roblox estilo Minecraft (scripts de servidor y cliente). |
| Móvil 1.1 | `grutas-movil-v1.1` | 8 bits mejorado y 42 hechizos aleatorios. |
| Móvil 1.0 | `grutas-movil-v1.0` | Primera versión para teléfono. |

## Historia de un Crack — `juegos/historia-de-un-crack`

| Versión | Etiqueta | Cambios |
|---|---|---|
| 1.1 | `crack-v1.1` | Acabado visual estilo Hoop Land y ajustes de balance. |
| 1.0 | `crack-v1.0` | Carrera de futbolista con las mecánicas de PL Story 2, en 8 bits. |

## Mi Carrera Fútbol — `juegos/mi-carrera-futbol`

| Versión | Etiqueta | Cambios |
|---|---|---|
| 2.0 | `futbol-v2.0` | Versión 3D con mejor dibujo y movimiento. |
| 1.0 | `futbol-v1.0` | Modo MyPlayer en 8 bits. |

## Huerto del Valle — `juegos/huerto-del-valle`

| Versión | Etiqueta | Cambios |
|---|---|---|
| 1.0 | `huerto-v1.0` | Juego de granja estilo Stardew Valley. |
