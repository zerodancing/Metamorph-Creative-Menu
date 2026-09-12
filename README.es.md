<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [**Español**](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">Un menú creativo y conjunto de herramientas sandbox para Noita: hechizos, varitas, objetos, materiales, perks, efectos, criaturas, transformaciones, posesión, teletransporte, clima, reglas del mundo, integración multijugador y herramientas de recuperación.</p>

<p align="center"><strong>Creador y mantenedor: <a href="https://github.com/zerodancing">zerodancing</a></strong></p>

---

# Descargar

Para jugar normalmente, usa la compilación lista para instalar:

[**⬇️ Descargar la compilación más reciente**](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)

[Página de la compilación más reciente](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) · [Registro de cambios](metamorph_creative_menu/CHANGELOG.txt)

La release de GitHub se genera automáticamente a partir del árbol completo de desarrollo. Las pruebas, herramientas de QA, diagnósticos, código fuente nativo y herramientas de build permanecen en el repositorio, pero se excluyen del archivo para jugadores.

La compilación standalone de GitHub incluye NoitaPatcher y soporte nativo de recuperación, por lo que **Unsafe Mods debe estar permitido**.

# Instalación

1. Descarga `Metamorph-Creative-Menu.zip` desde el enlace anterior.
2. Inicia Noita y abre **Mods** desde el menú principal.
3. Pulsa **Open mods folder**.
4. Extrae o mueve la carpeta `metamorph_creative_menu` a la carpeta `mods`. La ruta final debe contener directamente `metamorph_creative_menu/mod.xml`, sin una carpeta extra del archivo comprimido.
5. Si ya hay una copia antigua, sustituye toda la carpeta `metamorph_creative_menu` en lugar de mezclar archivos antiguos y nuevos.
6. Vuelve a Noita y actualiza la lista de mods.
7. Permite **Unsafe Mods**.
8. Activa **Metamorph: Creative Menu** e inicia una partida con los mods activos.

No actives al mismo tiempo la compilación standalone de GitHub y la versión de Steam Workshop.

# Compilación standalone y Steam Workshop

La compilación distribuida en este repositorio de GitHub es la compilación standalone completa. Incluye NoitaPatcher y funciones que requieren acceso sin restricciones a la API de mods, incluidas operaciones de bajo nivel con materiales y recuperación nativa tras Game Over.

La [compilación de Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3785170245) se instala por separado. No incluye los componentes nativos necesarios para las funciones exclusivas de la compilación standalone.

Ambas compilaciones usan la misma identidad de mod. Instalarlas simultáneamente puede producir archivos duplicados o en conflicto y no está soportado.

# Acerca del mod

**Metamorph: Creative Menu (MCM)** es un menú creativo y toolkit sandbox para Noita.

Reúne herramientas para:

- hechizos e inventario de hechizos;
- edición de varitas y presets reutilizables;
- objetos y recipientes con líquidos;
- catálogo completo de materiales y pintura de materiales;
- perks y eliminación soportada de perks;
- estados y entidades GameEffect;
- criaturas, transformaciones y posesión;
- clima y hora;
- reglas globales del mundo;
- teletransporte;
- integración opcional con Entangled Worlds;
- recuperación tras transformaciones, muerte de formas y Game Over.

MCM intenta trabajar con el estado real de Noita en vez de sustituirlo todo por copias decorativas. Las cartas de hechizo existentes se mueven como entidades, la entrega de objetos respeta la estructura del inventario, los cambios de varita usan rutas de commit/rollback, los materiales siguen siendo materiales reales simulados y las reglas reversibles conservan suficiente estado original para restaurar después los ajustes soportados.

Entangled Worlds es opcional. Sin él, MCM sigue siendo un mod completo para un jugador.

# Controles

Controles predeterminados:

| Acción | Entrada predeterminada |
| --- | --- |
| Abrir / cerrar el menú creativo | **F4** |
| Volver a forma humana durante una transformación | **TAB** |
| Poseer una criatura del mundo | **G** |
| Dibujar con el material seleccionado | **Botón central del ratón** |

El panel creativo también está disponible a través de la interfaz normal del inventario de Noita.

Las asignaciones pueden cambiarse en la sección **CONTROLS** de MCM y en los ajustes de mod de Noita. Se admiten teclas, botones del ratón y combinaciones exactas con **CTRL / SHIFT / ALT**.

Durante la captura de una asignación:

- **DELETE / BACKSPACE** borra la asignación;
- **ESC** cancela;
- **R** restaura la entrada predeterminada de esa acción;
- **RESET ALL** restaura todas las asignaciones predeterminadas tras confirmación.

Las asignaciones duplicadas siguen siendo editables, pero MCM muestra el conflicto en vez de sustituir silenciosamente otra acción.

Se pueden reasignar acciones de navegación del menú, secciones, retorno de forma, posesión, pintura de materiales, limpieza de efectos, liberación del clima, reinicio de reglas del mundo y acciones multijugador soportadas.

# Ventana de Creative Menu

El panel creativo directo es una ventana persistente y redimensionable, no un overlay de depuración fijo.

Se puede:

- mover por el título;
- redimensionar desde bordes y esquinas;
- minimizar;
- cerrar;
- restaurar al diseño predeterminado.

Su posición, anchura, altura y última sección abierta se recuerdan entre ejecuciones. Tras cambios de resolución, la geometría guardada se ajusta para seguir dentro del área visible de la interfaz.

Las listas y catálogos usan diseños medidos y contenedores de scroll de Noita. Redimensionar la ventana cambia inmediatamente cuánto contenido es visible, y las etiquetas traducidas pueden ocupar varias líneas sin solaparse con controles vecinos. En diseños estrechos, los controles pasan a filas adicionales en lugar de dibujarse unos encima de otros.

Abrir o simplemente pasar el cursor sobre el menú separado no desactiva permanentemente el gameplay. Cuando un clic, arrastre o campo de texto enfocado también podría activar al jugador, MCM suprime temporalmente los controles relevantes y los restaura después.

# Búsqueda y localización

La búsqueda está disponible en los catálogos principales, incluidos hechizos, objetos, materiales, perks y criaturas.

Según la entrada, puede coincidir con:

- el nombre en el idioma actual de la interfaz;
- el nombre en inglés;
- claves de localización;
- identificadores técnicos;
- rutas XML.

La búsqueda no distingue mayúsculas y minúsculas, normaliza acentos y separadores comunes y tolera pequeños errores tipográficos en consultas largas.

La interfaz propia de MCM está localizada en:

- inglés;
- ruso;
- portugués brasileño;
- español;
- alemán;
- francés;
- italiano;
- polaco;
- chino simplificado;
- japonés;
- coreano.

Para contenido normal de Noita, el mod reutiliza las claves de localización del propio juego siempre que sea posible, en lugar de mantener nombres duplicados.

# Hechizos

La sección de hechizos trabaja tanto con el catálogo como con las entidades de hechizo ya existentes del jugador.

El área principal contiene:

- los slots normales de la varita activa;
- las cartas **ALWAYS CAST**;
- el inventario de hechizos del jugador;
- el catálogo de hechizos con búsqueda.

## Sustitución rápida del slot seleccionado

Un clic corto selecciona un slot de la varita. Después, un clic corto con LMB en un hechizo del catálogo sustituye ese slot.

Es la ruta rápida para edición normal. El movimiento preciso usa drag-and-drop.

## Drag-and-drop transaccional

Las cartas existentes pueden arrastrarse:

- entre slots de la varita;
- de slots normales a **ALWAYS CAST**;
- de **ALWAYS CAST** a slots normales;
- a un slot exacto del inventario de hechizos;
- del inventario de vuelta a la varita;
- al mundo;
- a la papelera cuando esté soportado.

Para una carta existente, MCM mueve la entidad real siempre que sea posible. Así, el estado mutable, los usos restantes y los datos añadidos por otros mods no se pierden solo porque la carta cambie de ubicación.

El origen permanece intacto hasta que la transacción de destino se confirma. Los destinos inválidos o desconocidos cancelan la operación en lugar de borrar la carta original. Una sola liberación del ratón realiza como máximo una operación confirmada.

Las cartas del catálogo son plantillas y nunca se consumen al arrastrar.

## Always Cast

Las cartas Always Cast tienen su propia franja. Promoción, degradación e intercambio tienen en cuenta la capacidad efectiva de slots normales para evitar una estructura inválida de varita.

## Deshacer y rehacer

Las mutaciones internas de la varita tienen un historial limitado de **UNDO / REDO**.

Las operaciones que entregan una entidad real al mundo exterior o a otro inventario no siempre pueden revertirse con seguridad desde un snapshot de la varita, por lo que esas transferencias externas no se prometen como universalmente reversibles.

# Varitas

El área de varita edita la varita que el jugador sostiene actualmente.

Las estadísticas soportadas incluyen:

- capacidad / slots;
- hechizos por lanzamiento;
- tiempo de recarga;
- retraso entre lanzamientos;
- dispersión;
- multiplicador de velocidad de proyectil;
- mana máxima;
- velocidad de recarga de mana;
- recuperación de retroceso;
- nivel de la varita;
- shuffle;
- comportamiento sin recarga.

MCM también edita presentación y metadatos relacionados:

- nombre mostrado;
- bloqueos de varita y cartas;
- ruta del sprite;
- offsets del sprite;
- posición de disparo.

Un catálogo visual de apariencias sigue los datos de XML de varitas cuando están disponibles.

## Presets de varita

Las varitas pueden guardarse como presets persistentes con nombre y reutilizarse en otros mundos o futuras sesiones de Noita.

Un preset puede conservar:

- estadísticas de la varita;
- valores de mana;
- metadatos visuales;
- cartas normales;
- cartas Always Cast;
- posiciones de slots;
- usos restantes;
- estado congelado de las cartas.

Cada preset tiene dos operaciones distintas:

- **APPLY** escribe el blueprint guardado en la varita que sostiene el jugador;
- **GET COPY** construye una nueva varita con el mismo blueprint.

La copia se coloca en un slot libre de varita del inventario rápido cuando es posible. Si no hay un slot apropiado, la varita terminada se deja en el mundo cerca del jugador.

La sustitución de varitas y carga de presets usan rutas de commit/rollback. Si la construcción o colocación no puede completarse, MCM intenta eliminar el árbol de entidad incompleto en vez de dejar una varita parcial rota.

# Objetos y líquidos

## Objetos

Un clic corto con **LMB** en una entrada del catálogo crea un objeto soportado cerca del jugador.

**RMB** intenta entregar el objeto al área apropiada del inventario.

Las entradas del catálogo también pueden arrastrarse:

- a un destino compatible del inventario rápido;
- fuera del menú a una posición exacta del mundo.

Soltar una carta dentro del menú sin un destino válido cancela la operación. La carta del catálogo es solo una plantilla y permanece disponible.

MCM respeta la separación normal del inventario rápido de Noita entre slots de varita y slots de objeto. Un fallo al cargar XML, llenar un líquido, entregar al inventario o realizar una transferencia multijugador opcional elimina la nueva entidad cuando es posible.

Algunos objetos reales de inventario viven en directorios del juego orientados a criaturas. MCM clasifica los casos conocidos por su comportamiento en vez de asumir que el nombre de una carpeta por sí solo determina si algo es objeto o criatura.

## Líquidos

Las entradas de líquidos crean recipientes reales de Noita ya llenos, no objetos decorativos de la interfaz.

El recipiente resultante puede llevarse, soltarse, romperse y derramar su contenido, que participa en las reacciones normales de materiales.

# Materiales

La sección Materials es una herramienta de pintura del mundo basada en el registro real de materiales de Noita.

El catálogo se construye a partir de líquidos, arenas / polvos, gases, fuegos, sólidos y materiales estáticos o de efectos registrados por el engine. Los materiales añadidos correctamente por otros mods activos pueden aparecer automáticamente.

El descubrimiento de materiales y la validación costosa se reparten en trabajo limitado en vez de recorrer todo el catálogo en un solo frame de UI.

## Presentación de materiales

Los líquidos usan la misma presentación de recipiente lleno que la sección de objetos.

Para materiales no líquidos, MCM prefiere texturas y tint definidos en `materials.xml`, incluidas definiciones heredadas. Si no hay textura definida, el fallback se deriva del color real del material en el engine, no de un color de preview arbitrario.

## Pintura

1. Selecciona un material.
2. Selecciona el tamaño del pincel.
3. Activa el modo de pintura.
4. Cierra el inventario.
5. Mantén pulsada la entrada configurada de dibujo en el mundo.

Abrir el inventario detiene el modo de pintura activo.

La pintura no emite simplemente partículas decorativas. MCM coloca celdas reales en el mundo mediante una ruta apropiada para el engine. Los materiales dinámicos siguen la simulación normal de Noita: los líquidos fluyen, los polvos caen, los gases se mueven, el fuego reacciona y las sustancias inestables pueden transformarse mediante reacciones de materiales.

Distintas clases de material requieren estrategias de colocación diferentes. La compilación standalone puede usar acceso directo de NoitaPatcher a la cuadrícula del mundo y un pequeño fallback de PixelScene para casos definidos que Noita se niega a construir directamente en una coordenada concreta de textura.

Las colas están limitadas para que mantener un pincel grande no ejecute deliberadamente una cantidad ilimitada de trabajo en un solo frame.

# Perks

## Crear y recibir perks

**LMB** crea un pickup normal del perk seleccionado en el mundo.

La acción de recibir puede conceder el perk de forma individual o en lote. Las operaciones por lotes se procesan como jobs limitados en vez de aplicar todas las copias en un único frame de UI.

La interfaz muestra el progreso y el trabajo todavía pendiente puede cancelarse. Las copias ya confirmadas antes de la cancelación permanecen aplicadas.

Cada copia concedida sigue usando la ruta normal de aplicación del perk en vez de falsificar directamente el estado final.

## Eliminar perks

Eliminar un perk es mucho más complicado que concederlo. Los perks pueden modificar globals, componentes, entidades, estadísticas del jugador y mecánicas de larga duración, y Noita no ofrece una operación inversa universal.

Por eso MCM solo elimina estado para el que dispone de una inversa rastreada suficientemente segura. El journal de la transacción intenta quitar solo el estado perteneciente a esa aplicación del perk sin resetear estado no relacionado del jugador.

Si una limpieza es parcial o no puede demostrarse completa, sigue tratándose como incompleta en lugar de declararse silenciosamente exitosa.

Un perk de terceros puede poder concederse sin ser eliminable de forma correcta.

# Efectos

La sección Effects aplica y elimina estados de material y entidades GameEffect soportados.

La eliminación tiene en cuenta la propiedad cuando es posible. MCM evita borrar indiscriminadamente efectos ocultos similares que pertenecen a perks, al juego o a otro sistema.

Los efectos persistentes creados por MCM usan limpieza / expiración limitada para que quitar un efecto de MCM no resetee estado ajeno.

# Criaturas

El catálogo de criaturas conserva rutas XML exactas en vez de fusionar todas las entidades con nombres parecidos.

Interacciones soportadas:

- **LMB** — crea la entidad definida seleccionada cerca del jugador;
- arrastrar fuera del menú — crea en la posición confirmada del cursor del mundo;
- **RMB** — transforma al jugador actual en una forma soportada;
- entrada especial **PLAYER** — crea o restaura estado de jugador como se describe abajo.

Soltar una carta arrastrada de vuelta sobre el menú cancela la creación en el mundo.

Las reglas de compatibilidad para formas peligrosas o inusuales usan rutas exactas. Que un nombre de archivo contenga una palabra familiar no hace que la entidad se trate automáticamente como otra forma equivalente.

# Transformaciones y regreso a forma humana

Las formas jugables conservan movimiento nativo útil, ataques, presentación y física cuando resulta práctico. Los componentes que compiten directamente con la entrada del jugador pueden desactivarse o adaptarse mientras la forma está controlada por el jugador.

Algunas criaturas complejas requieren lógica adicional. Bosses, wrappers con scripts y entidades muy dependientes de física no están garantizados a comportarse exactamente como sus versiones controladas por IA cuando se usan como forma del jugador.

La acción configurada de regreso — **TAB por defecto** — usa primero la ruta normal de finalización de transformación. Cuando eso no basta, la compilación standalone dispone de rutas adicionales de restauración mediante NoitaPatcher.

En casos soportados de daño fatal, MCM intenta:

- dejar la forma temporal muerta o cadáver en el mundo cuando corresponda;
- restaurar una entidad humana del jugador;
- devolver authority y controles;
- conservar el inventario;
- restaurar estado relevante del jugador.

Esto es lógica de recuperación, no inmortalidad absoluta. Un kill script de terceros, un estado incompatible del engine o un crash del proceso puede saltarse el handoff soportado.

# Posesión

La posesión controla una criatura que ya existe en el mundo en lugar de elegir una forma desde el catálogo.

La entrada predeterminada es **G**.

Apunta a una criatura adecuada y usa la acción de posesión. MCM valida el objetivo, prepara una transición compatible y elimina o retira la entidad original del mundo solo después de confirmar el nuevo estado controlado por el jugador.

Si la transición falla, la criatura original no debería simplemente desaparecer.

La posesión no se limita al catálogo interno de MCM. Una criatura compatible creada por otro mod puede funcionar, pero no se garantiza compatibilidad universal con todas las entidades de terceros.

# Entrada Player

**PLAYER** es una entrada especial del catálogo de criaturas, no un objetivo normal de polymorph.

Su acción de creación genera un personaje separado similar al jugador e intenta copiar presentación apropiada e información de salud máxima.

Usar la acción de transformación en **PLAYER** no convierte a un jugador ya humano en un duplicado. Si el jugador está en otra forma, la acción sirve para volver a forma humana.

# Recuperación de Game Over en un jugador

La compilación standalone para un jugador incluye una ruta adicional de recuperación para la pantalla estándar de Game Over de Noita.

Cuando la integración nativa puede identificar con seguridad las estructuras necesarias del juego, MCM añade una acción **“I didn't die”** a la interfaz de Game Over.

MCM mantiene una copia rotativa del estado del jugador mientras la partida está en curso. Activar la recuperación solicita la restauración a través de la ruta normal de actualización de MCM en vez de reconstruir todo el jugador directamente desde el handler del clic de UI.

Una recuperación soportada intenta:

- restaurar u obtener una entidad de jugador viva;
- volver a hacerla authoritative;
- limpiar el estado Game Over del engine;
- devolver controles y estado utilizable del jugador;
- hacer limpieza best-effort del audio, música e interfaz de Game Over;
- proporcionar una breve ventana de protección después de la restauración.

El helper nativo está diseñado para fallar de forma segura. Escanea el ejecutable soportado de Noita en ejecución buscando estructuras conocidas en vez de escribir en una única dirección permanentemente codificada. Si las estructuras esperadas no pueden identificarse con seguridad después de una actualización, la recuperación opcional no se usa en vez de escribir en una ubicación incierta.

# Clima y hora

MCM puede controlar estado soportado de clima y hora, incluidos presets y parámetros individuales expuestos por la implementación actual.

Un estado forzado puede liberarse después para devolver el control normal al juego. Por ejemplo, tras fijar una hora concreta, MCM puede dejar de poseer ese ajuste para que continúe el ciclo natural de Noita.

Los cambios de clima se tratan como estado controlado, no como comandos de consola de una sola dirección.

# Reglas del mundo

La sección **RULES** cambia comportamiento global soportado del juego.

Las reglas cubren áreas como:

- relaciones entre criaturas;
- comportamiento del oro;
- uso de hechizos;
- fog of war;
- determinadas recompensas por muertes;
- drops de curación;
- comportamiento de sangre;
- gravedad;
- física;
- fuerza de patada;
- juntas físicas;
- ciclo día/noche;
- otros parámetros globales soportados.

El objetivo principal es la reversibilidad.

Para reglas soportadas, MCM registra o deriva el estado original para poder restaurarlo después. Los controles multiplicadores se aplican respecto al valor original en vez de multiplicar repetidamente un resultado ya modificado.

Las reglas que necesitan tocar muchas entidades u objetos físicos usan trabajo limitado a lo largo de frames en vez de intentar reescribir todo el mundo sincrónicamente con un clic.

# Teletransporte

La sección de teletransporte ofrece destinos preparados por el mundo, incluidos puntos de la ruta principal, Holy Mountains, grandes áreas laterales y otros lugares soportados.

Antes de mover al jugador, MCM puede solicitar la carga del área de destino y busca espacio utilizable cercano en vez de colocar al jugador deliberadamente dentro de terreno sólido.

El teletransporte sigue dependiendo de que el mundo pueda cargar y proporcionar un destino válido. Los mundos muy modificados pueden requerir comportamiento de fallback.

# Entangled Worlds

**Entangled Worlds / Noita Proxy es opcional.** MCM funciona sin él.

Cuando EW está presente, MCM activa comportamiento adicional consciente de multijugador. Todos los peers deberían usar compilaciones compatibles de MCM al depender de estado sincronizado específico de MCM.

## Authority y formas

Las formas de jugador requieren manejo especial de ownership porque un jugador transformado no debe dejar accidentalmente una segunda authority de red.

MCM coordina ownership, retirement y retorno a forma humana con EW donde está soportado. Entidades de boss y tipo Kolmi tienen tratamiento adicional de lifecycle destinado a evitar authorities duplicadas y copias antiguas controladas por red.

La ruta normal de muerte de EW sigue a cargo de entidades que no se reconocen como estado de forma perteneciente a MCM.

## Objetos, varitas y hechizos

Cuando es posible, MCM usa los mecanismos normales de objetos / inventario de EW en vez de inventar un sistema de transporte paralelo.

Las mutaciones confirmadas de varita e inventario de hechizos solicitan el refresh multijugador adecuado cuando la integración está disponible. Los objetos creados por MCM en el mundo pueden entregarse a la ruta estándar de world items de EW.

## Perks

Los pickups normales de perks pueden usar la sincronización estándar de world items de EW. El manejo de estado de perks de MCM coordina refresh y operaciones limitadas para que las acciones en lote no intenten emitir un refresh global costoso por cada copia.

## Materiales

La pintura de materiales tiene una ruta especial de compatibilidad porque los cambios de celdas del mundo no son entidades de objeto normales.

MCM mantiene el trabajo de pintura limitado, separa el trabajo en fronteras de chunks y coordina pasos necesarios de world-frame / persistencia de EW antes de liberar trabajo de conversión sincronizada. Un chunk de borde todavía no cargado se aplaza en vez de bloquear todo el trazo activo.

El objetivo es que peers cercanos puedan observar el estado pintado soportado sin tener que reproducir remotamente la acción normal de UI de MCM como una llamada PixelScene basada solo en filename.

Esto sigue heredando las suposiciones de material id de EW: un juego receptor no puede crear correctamente un material que no exista allí o cuyo registro de materiales del engine sea incompatible.

## Clima, posesión y estado del mundo

El estado multijugador soportado de MCM también incluye coordinación para clima, posesión y determinado comportamiento de reglas / lifecycle. Las comprobaciones de authority evitan que dos peers intenten poseer el mismo estado a la vez.

El soporte de EW es deliberadamente conservador. Cuando la integración no puede demostrar una ruta sincronizada segura, MCM prefiere el comportamiento local soportado en vez de fingir que toda operación de un jugador es automáticamente segura en multijugador.

# Compatibilidad y limitaciones

Noita expone muchos sistemas mediante entidades débilmente acopladas, XML, componentes Lua y comportamiento nativo del engine. Por ello MCM no puede prometer compatibilidad universal con todas las entidades modificadas ni con todas las futuras actualizaciones del juego.

Limitaciones importantes:

- que una criatura pueda crearse no significa que sea una forma de jugador segura;
- que un perk pueda concederse no significa que tenga una inversa fiable;
- las transferencias externas de hechizos u objetos no siempre pueden deshacerse desde un snapshot interno;
- scripts de terceros pueden saltarse rutas soportadas de muerte y recuperación;
- las funciones nativas de recuperación dependen de comportamiento soportado del ejecutable de Noita y fallan de forma segura si las estructuras necesarias no pueden identificarse;
- Entangled Worlds no puede sincronizar un material ausente del registro del juego receptor;
- inventarios, entidades o reglas muy modificadas pueden necesitar compatibilidad específica con ese mod.

MCM intenta preservar estado original y revertir mutaciones fallidas, pero una herramienta sandbox que modifica estado vivo del juego no puede hacer totalmente transaccional cualquier combinación de mods de terceros.

# Datos guardados

MCM persiste estado de usuario que debe sobrevivir entre ejecuciones, incluidos ajustes soportados, asignaciones, diseño del menú y presets de varita.

La identidad del mod permanece estable para que las actualizaciones normales conserven datos soportados. Aun así, se recomienda sustituir toda la carpeta del mod al instalar una nueva compilación standalone, porque mezclar archivos antiguos y nuevos puede dejar runtime obsoleto.

# Solución de problemas

## El mod no aparece

Comprueba que la estructura termina en:

`mods/metamorph_creative_menu/mod.xml`

Una carpeta extra por encima de `metamorph_creative_menu` impide que Noita vea el mod correctamente.

## Las funciones nativas o de materiales no funcionan

Comprueba que **Unsafe Mods** está permitido y que instalaste la compilación standalone de GitHub sin mezclar archivos de Workshop.

## El menú se abre pero también se dispara una acción del juego

Revisa conflictos en las asignaciones personalizadas. MCM muestra duplicados, pero permite mantenerlos si así lo deseas.

## Una criatura no puede transformarse de forma segura

No toda entidad XML que puede crearse es una forma de jugador soportada. Existen reglas por ruta exacta para criaturas que necesitan tratamiento especial.

## Un perk no puede eliminarse

La eliminación solo se ofrece donde MCM tiene una operación inversa soportada para el estado rastreado. Es intencional: adivinar una limpieza puede dañar estado no relacionado del jugador.

## El multijugador se comporta distinto entre peers

Usa compilaciones compatibles de MCM en todos los participantes y mantén un entorno compatible de Noita / Entangled Worlds. MCM no puede corregir un registro de materiales incompatible ni modificaciones de red arbitrarias de otros mods.

# Informar de errores

Un informe útil debería incluir:

- qué intentabas hacer;
- la sección y acción exactas de MCM;
- si ocurre en un jugador, Entangled Worlds o ambos;
- si está instalada la compilación standalone o Workshop;
- si hay otros mods de gameplay activos;
- pasos fiables para reproducirlo;
- logs relevantes de Noita / EW cuando estén disponibles.

Para problemas de transformación, posesión, objetos o materiales, incluye la entidad o material exacto cuando sea posible. Los identificadores técnicos suelen ser más útiles que un nombre mostrado traducido.

# Repositorio y fuente de desarrollo

El repositorio contiene intencionadamente el **árbol completo de desarrollo**, no el mismo archivo reducido que descargan los jugadores.

`metamorph_creative_menu/` contiene código runtime junto con:

- pruebas automatizadas;
- herramientas de QA;
- diagnósticos;
- código fuente nativo;
- herramientas de build;
- reglas de limpieza de release;
- documentación de desarrollo.

Estos archivos son útiles para desarrollo y pruebas de regresión, por lo que permanecen en el source de GitHub. El ZIP listo para jugadores se genera por separado y excluye contenido exclusivo de desarrollo.

El paquete de jugador también recibe limpieza específica de release, incluido el `README.txt` mínimo del paquete, mientras que el árbol source mantiene su documentación de desarrollo.

# Pruebas

La suite automatizada está en `metamorph_creative_menu/tests/` y combina verificaciones de contrato en Python con mocks Lua.

Desde la raíz del repositorio, el workflow de release ejecuta la suite contra el source completo importado antes de publicar la compilación para jugadores. `texlua` es necesario para la parte de mocks Lua.

Las comprobaciones de source hygiene también protegen los archivos orientados a producción y la documentación contra residuos del historial de desarrollo, superficies de debug obsoletas y artefactos accidentales del proceso.

# Importación del source y proceso de release

El source completo de desarrollo puede importarse desde un archivo de la familia `Metamorph-Creative-Menu-v...zip`.

El workflow de importación verifica la estructura, exige los componentes completos de desarrollo, ejecuta source hygiene y la suite de regresión antes de hacer commit del árbol importado.

Un archivo de estilo ModWorkshop / player no se trata como source de desarrollo.

La release pública `latest-build` se produce después desde el source completo mediante un builder separado. Este elimina QA, tests, diagnósticos, código fuente nativo y otro payload exclusivo de desarrollo, aplica reglas de limpieza, valida el archivo resultante y solo entonces actualiza el asset estable de descarga.

Esta separación permite que el repositorio siga siendo útil para desarrollo mientras la descarga normal del jugador permanece pequeña y libre de instrumentación de desarrollo.

# Componentes de terceros

Los componentes de terceros, dependencias incluidas y proyectos upstream están documentados en [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
