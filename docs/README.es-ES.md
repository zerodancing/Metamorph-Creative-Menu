# Metamorph: Creative Menu — Español

[English](README.en.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es-ES.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## Acerca del mod

**Metamorph: Creative Menu (MCM)** es un menú creativo/de desarrollo para **Noita**. Funciona de forma independiente en un jugador y añade compatibilidad experimental opcional con **Entangled Worlds / Noita Proxy**.

Permite editar varitas, generar o recibir objetos, aplicar y retirar ventajas y efectos, transformarse en criaturas, poseer una criatura existente bajo el cursor, modificar el clima y las reglas del mundo y crear un compañero parecido al jugador.

## Requisitos e instalación

- Noita instalado.
- `metamorph_creative_menu` dentro de `Noita/mods/`.
- Activa **Unsafe mods / unrestricted API**. El NoitaPatcher incluido necesita este acceso.
- Entangled Worlds es **opcional**.

Pasos:
1. Descarga una compilación desde [Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases) o descarga/clona el repositorio.
2. Copia la carpeta completa a `Noita/mods/`.
3. Comprueba `Noita/mods/metamorph_creative_menu/mod.xml`.
4. Activa Unsafe mods y después Metamorph: Creative Menu.

No cambies el nombre interno de la carpeta.

## Controles

- **TAB** — abre/cierra el menú.
- **TAB transformado** — vuelve a la forma humana.
- **G** por defecto — posee/se transforma en la criatura compatible bajo el cursor; se puede reasignar.
- LMB/RMB cambian según la pestaña; la interfaz indica la acción.

## Funciones

### Hechizos
Con una varita equipada, selecciona una ranura y un hechizo del catálogo con categorías y búsqueda. Puedes sustituir, borrar o soltar hechizos. La sustitución verifica el hechizo nuevo antes de eliminar el anterior.

### Objetos
Incluye recipientes, líquidos, piedras, huevos, varitas, libros, bonificaciones, orbes, objetos de misión y más.
- **LMB:** generar cerca.
- **RMB:** intentar colocar directamente en el inventario.
- Si no hay espacio o falla el pickup, el objeto queda en el mundo.
- Incluye frascos/recipientes llenos compatibles.

### Ventajas
- **ADD:** LMB genera el pickup; RMB aplica directamente.
- **REMOVE:** LMB quita una acumulación; RMB intenta quitar todas.
MCM registra muchas modificaciones de perks para restaurar entidades, componentes y valores propios sin sobrescribir intencionadamente cambios externos. Si no existe una inversa segura, prefiere rechazar una eliminación peligrosa.

### Búsqueda
Los catálogos grandes permiten buscar por nombre traducido, ID y/o descripción.

### Criaturas, objetos y formas
- **LMB:** generar.
- **RMB:** transformar.
- **TAB:** volver a humano.

La compatibilidad se registra por ruta XML exacta. Algunos wrappers peligrosos conocidos usan un objetivo canónico seguro únicamente para transformar. Las formas intentan conservar ataques, movimiento, presentación y física útiles mientras desactivan IA que competiría con el jugador. Entidades complejas pueden ser aproximadas.

### Retorno humano y muerte de la forma
TAB usa primero el ciclo nativo de polymorph. MCM mantiene además un backup humano serializado con NoitaPatcher.

Ante daño mortal, **death handoff** intenta dejar morir el cuerpo de criatura y transferir la autoridad del jugador al humano restaurado para que la muerte de la forma no termine automáticamente la partida.

### Posesión
Apunta a una criatura compatible y pulsa **G** (predeterminado). MCM adopta una forma compatible con esa criatura y retira el objetivo original para evitar crear simplemente un duplicado.

### Compañero PLAYER
La entrada `PLAYER` crea un aliado similar al jugador. Con las capacidades necesarias de NoitaPatcher puede usar la varita copiada de manera más cercana a un jugador real.

### Efectos
Aplica efectos de estado/temporales, elige duración cuando sea compatible y elimina efectos intentando conservar estados internos/perks ajenos al editor.

### Clima
Presets de hora: mañana, día, tarde y noche. Presets: despejado, nublado, niebla y tormenta. El modo avanzado controla hora, nubes, niebla, viento, velocidad del viento, lluvia y rayos compatibles. **RELEASE** deja de mantener el override.

### Reglas del mundo
Son **overrides reversibles**. `NATIVE`/RESET restaura el baseline capturado por MCM. Las reglas críticas usan recuperación persistente.

Reglas actuales:

- RELACIONES DE CRIATURAS
- EL ORO NO DESAPARECE
- USOS ILIMITADOS
- REVELAR MAPA
- DINERO DE SANGRE POR TRUCOS
- PROB. DE CURACIÓN
- RATAS AMISTOSAS
- CANTIDAD DE SANGRE
- ORO POR TRUCOS
- DESTELLO DE DAÑO
- PÉRDIDA DE MANCHAS
- GRAVEDAD DEL MUNDO
- AMORTIGUACIÓN FÍSICA
- VOLUMEN DE SANGRE
- FUERZA DE PATADA
- RESISTENCIA DE UNIONES
- VELOCIDAD DEL DÍA

Las reglas físicas actúan sobre entidades/cuerpos cargados o cercanos, no sobre todo el mundo descargado de forma instantánea.

## Un jugador y Entangled Worlds

**Entangled Worlds no es necesario para un jugador.** MCM incluye NoitaPatcher y un códec Base64 propio.

Con `quant.ew` activo se habilita integración experimental para objetos, perks, clima, reglas, formas/posesión, compañeros y parches de compatibilidad. Si EW ya publica una API NoitaPatcher compatible, MCM puede reutilizarla.

La compatibilidad de red es **experimental/parcial**. Host y cliente deben tener los mismos derechos de usuario en el menú, pero no se garantiza cada caso extremo de Noita/EW. Todos los jugadores deberían usar la misma versión de MCM.

## Problemas y reportes

- Si no abre el menú, verifica la carpeta y que el mod esté activado.
- Si faltan funciones avanzadas, activa Unsafe mods y comprueba `NoitaPatcher/noitapatcher.dll`.
- Para una forma rota, indica el nombre/XML exacto y si falló TAB o el retorno tras muerte.
- Para EW, indica versiones de ambos mods.

Informa errores en [GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues) con versión, pasos y logs.

## Dependencias y créditos

MCM incluye **NoitaPatcher** (dextercd) y **lbase64** (Ilya Kolbin), e integra opcionalmente **Noita Entangled Worlds** (IntQuant y colaboradores). Detalles: [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

## Enlaces

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

## Desarrollo

El mod jugable está en `metamorph_creative_menu/`; las pruebas y contratos están en `metamorph_creative_menu/tests/`. Todavía no se ha elegido una licencia general para el código original de MCM.
