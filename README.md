# Juegos indie de Juan

Colección de juegos para el navegador. Cada juego es un solo archivo `index.html`: se abre con doble clic, sin instalar nada.

| Juego | Género | Carpeta | Versión |
|---|---|---|---|
| **El Gran Golpe** | Atracos tácticos con estado mental | `juegos/el-gran-golpe` | 2.3 |
| **Escuadrón Halcón** | Mando táctico / asaltos | `juegos/escuadron-halcon` | 1.2 |
| **Bastión Arcano** | Tower defense | `juegos/bastion-arcano` | 1.0 |
| **Grutas Arcanas** | Mazmorra con arena y hechizos | `juegos/grutas-arcanas` (pc, móvil, roblox) | PC 1.1 |
| **Historia de un Crack** | Carrera de futbolista | `juegos/historia-de-un-crack` | 1.1 |
| **Mi Carrera Fútbol** | Fútbol MyPlayer en 3D | `juegos/mi-carrera-futbol` | 2.0 |
| **Huerto del Valle** | Granja | `juegos/huerto-del-valle` | 1.0 |

El historial completo está en [CHANGELOG.md](CHANGELOG.md).

## Jugar

- **En tu computadora:** abre el `index.html` del juego en Chrome, Edge o Firefox.
- **En línea:** activa GitHub Pages (Settings → Pages → rama `main`, carpeta `/`). Cada juego queda en `https://TU-USUARIO.github.io/NOMBRE-DEL-REPO/juegos/CARPETA/`, y la portada en la raíz.

## Versiones

Cada versión tiene una etiqueta de git:

```bash
git tag                       # ver todas las versiones
git checkout golpe-v1.0       # volver a una versión vieja
git checkout main             # regresar a la última
```

## Roblox

Los scripts de `juegos/grutas-arcanas/roblox/` van en Roblox Studio:
- `GrutasServer.server.lua` → Script en **ServerScriptService**
- `GrutasCliente.client.lua` → LocalScript en **StarterPlayer → StarterPlayerScripts**
