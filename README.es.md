<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [**Español**](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">Un menú creativo y conjunto de herramientas para Noita: hechizos, varitas, objetos, materiales, ventajas, criaturas, transformaciones, efectos, teletransporte, clima, reglas del mundo y mucho más.</p>

<p align="center"><strong>Versión 2.0.0</strong></p>

---

# Descargar

[**⬇️ Descargar la última versión del mod**](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)

Versión actual: **2.0.0**

**Para usar la versión completa es necesario permitir los mods inseguros.**

[Página de la compilación más reciente](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build)

[Lista de cambios de la versión 2.0.0](metamorph_creative_menu/CHANGELOG.txt)

# Contenido

- [Instalación](#instalación)
- [Versión completa y versión del Workshop de Steam](#versión-completa-y-versión-del-workshop-de-steam)
- [Acerca del mod](#acerca-del-mod)
- [Controles e interfaz](#controles-e-interfaz)
- [Hechizos](#hechizos)
- [Varitas](#varitas)
- [Objetos y líquidos](#objetos-y-líquidos)
- [Materiales](#materiales)
- [Ventajas](#ventajas)
- [Efectos](#efectos)
- [Criaturas y transformaciones](#criaturas-y-transformaciones)
- [Regreso tras una transformación y muerte de la forma](#regreso-tras-una-transformación-y-muerte-de-la-forma)
- [Control de criaturas](#control-de-criaturas)
- [Jugador](#jugador)
- [Clima y tiempo](#clima-y-tiempo)
- [Reglas del mundo](#reglas-del-mundo)
- [Teletransporte](#teletransporte)
- [Entangled Worlds](#entangled-worlds)
- [NoitaPatcher y mods inseguros](#noitapatcher-y-mods-inseguros)
- [Si algo no funciona](#si-algo-no-funciona)
- [Informar de un error](#informar-de-un-error)

# Instalación

1. [Descarga la última versión del mod](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Inicia Noita y abre **Mods** desde el menú principal.
3. Pulsa **Abrir carpeta de mods**.
4. Mueve la carpeta `metamorph_creative_menu` del archivo descargado a la carpeta `mods` que se ha abierto. Si `metamorph_creative_menu` ya existe allí, elimina la carpeta antigua y coloca la nueva en su lugar.
5. Cierra la carpeta de mods.
6. En el menú de mods, pulsa **Actualizar**. **Metamorph: Creative Menu** debería aparecer en la lista.
7. Pulsa **Mods inseguros** hasta que el texto se vuelva rojo y muestre **Mods inseguros: Permitidos**.
8. Pulsa el nombre del mod para que quede resaltado y aparezca **[x]** delante. Eso significa que el mod está activado.
9. Pulsa **Iniciar una nueva partida con los mods activos**.
10. Elige un modo de juego y juega.

# Versión completa y versión del Workshop de Steam

La compilación disponible en esta página de GitHub es la versión completa de MCM. Incluye NoitaPatcher y funciones que requieren permiso para usar mods inseguros.

La [versión del Workshop de Steam](https://steamcommunity.com/sharedfiles/filedetails/?id=3785170245) se instala por separado. No incluye NoitaPatcher ni las funciones de la versión completa que requieren acceso de mods inseguros.

No instales ni actives las dos versiones al mismo tiempo.

# Acerca del mod

**Metamorph: Creative Menu (MCM)** es un menú creativo y conjunto de herramientas para Noita.

Reúne en una sola interfaz herramientas para hechizos, varitas, objetos, materiales, ventajas, efectos, criaturas, transformaciones, clima, reglas globales del mundo y teletransporte.

MCM sirve tanto para jugar libremente en modo creativo como para experimentar con las mecánicas de Noita. Muchas operaciones no se realizan como una simple creación de una entidad nueva, sino que tienen en cuenta el estado ya existente de la varita, el objeto, la forma, la ventaja o el mundo.

**Entangled Worlds no es obligatorio.** Sin él, MCM funciona como un mod completo para un jugador. Si Entangled Worlds está instalado, se habilitan funciones multijugador experimentales adicionales.

# Controles e interfaz

| Acción | Tecla |
| --- | --- |
| Abrir / cerrar el menú creativo | **F4 o TAB** |
| Volver a la forma humana | **TAB durante una transformación** |
| Tomar el control de una criatura | **G** |
| Dibujar con el material seleccionado | **Botón central del ratón** |

El panel de MCM también está disponible desde la interfaz normal del inventario.

Las teclas se pueden cambiar en la sección **CONTROLES** o en la configuración del mod.

Al asignar una tecla:

- **DELETE / BACKSPACE** — borrar la asignación;
- **ESC** — cancelar;
- **R** — restaurar la asignación predeterminada;
- **RESTABLECER TODO** — restaurar todas las asignaciones predeterminadas después de confirmarlo.

Si la misma combinación se asigna a varias acciones, MCM muestra un conflicto.

## Ventana del menú creativo

La ventana se puede:

- mover;
- cambiar de tamaño tanto en anchura como en altura;
- redimensionar desde los bordes y las esquinas;
- minimizar;
- cerrar;
- devolver a su disposición predeterminada.

El tamaño, la posición y la última sección abierta se guardan entre ejecuciones del juego.

Los catálogos grandes usan desplazamiento y se adaptan automáticamente al tamaño actual de la ventana.

## Búsqueda

La búsqueda está disponible en los catálogos de:

- hechizos;
- objetos;
- materiales;
- ventajas;
- criaturas.

Puede tener en cuenta no solo el nombre mostrado, sino también el nombre en inglés, la clave de localización, el identificador técnico o la ruta XML.

La búsqueda no distingue entre mayúsculas y minúsculas y admite pequeños errores ortográficos en palabras suficientemente largas.

La interfaz de MCM está localizada a 11 idiomas. Para el contenido normal del juego se reutilizan, siempre que sea posible, las traducciones de Noita.

# Hechizos

La sección de hechizos permite trabajar no solo con el catálogo, sino también con los hechizos reales del jugador actual.

Están disponibles al mismo tiempo:

- las ranuras de la varita activa;
- **LANZAMIENTO SIEMPRE**;
- el inventario de hechizos;
- el catálogo de hechizos.

## Sustitución rápida

Puedes seleccionar una ranura concreta de la varita y hacer LMB en el hechizo que quieras del catálogo. El hechizo se colocará en la ranura seleccionada.

## Arrastrar y soltar

Los hechizos existentes se pueden mover:

- entre ranuras de la varita;
- a **LANZAMIENTO SIEMPRE**;
- desde **LANZAMIENTO SIEMPRE** de vuelta a las ranuras normales;
- a ranuras concretas del inventario de hechizos;
- desde el inventario de vuelta a la varita;
- al mundo del juego;
- a la papelera.

Con las cartas de hechizo existentes, MCM intenta mover la propia entidad del juego en vez de crear una copia nueva. Así puede conservar el estado modificado de la carta, incluido el añadido por otros mods.

El hechizo de origen permanece en su sitio hasta que se confirma el nuevo destino. Una operación fallida o no permitida no debería destruir la carta original.

## Lanzamiento siempre

Los hechizos permanentes tienen su propia zona.

Al mover hechizos entre las ranuras normales y **LANZAMIENTO SIEMPRE**, MCM tiene en cuenta la capacidad de la varita para mantener correcta la estructura de las ranuras normales.

## Deshacer / Rehacer

Para los cambios internos de la varita hay un historial limitado de **DESHACER / REHACER**.

Se aplica a operaciones que se pueden restaurar de forma segura a partir del estado de la propia varita.

Transferir un hechizo real al mundo exterior o al inventario normal del juego no siempre puede revertirse correctamente restaurando solo el estado de la varita, por lo que esas acciones no siempre se pueden deshacer.

# Varitas

MCM incluye un editor completo para la varita activa.

Se puede modificar:

- la cantidad de ranuras;
- los hechizos por lanzamiento;
- el tiempo de recarga;
- el retraso entre lanzamientos;
- la dispersión;
- el multiplicador de velocidad de los proyectiles;
- el máximo de maná;
- la recarga de maná;
- la recuperación del retroceso;
- el nivel de la varita;
- el modo de barajado;
- el modo sin recarga.

También se puede modificar la apariencia y parámetros relacionados:

- el nombre mostrado;
- los bloqueos;
- la imagen de la varita;
- el desplazamiento de la imagen;
- el punto de disparo.

Hay un catálogo visual de apariencias de varitas.

## Varitas guardadas

Se puede guardar una varita y reutilizar después su estado guardado.

Se guardan:

- las características;
- el maná;
- la apariencia;
- los hechizos normales;
- **LANZAMIENTO SIEMPRE**;
- la disposición de las cartas;
- los usos restantes;
- el estado congelado de las cartas.

Las varitas guardadas están disponibles entre distintos mundos y en futuras ejecuciones de Noita.

### Aplicar

**APLICAR** aplica el estado guardado a la varita que el jugador tiene en ese momento.

### Copia

**COPIA** crea una copia independiente de la varita guardada.

Si hay una ranura adecuada libre en el inventario rápido, la varita nueva se coloca allí. De lo contrario, se crea junto al jugador en el mundo del juego.

Si la creación no puede completarse correctamente, MCM intenta eliminar la entidad incompleta.

# Objetos y líquidos

## Objetos

**LMB** sobre una entrada del catálogo crea un objeto junto al jugador.

**RMB** intenta colocar el objeto directamente en el inventario.

También se puede arrastrar un objeto:

- a una zona compatible del inventario rápido;
- fuera del menú, a un punto elegido del mundo del juego.

Si la carta se suelta dentro del menú sin un destino válido, la operación se cancela.

El catálogo contiene plantillas, por lo que su entrada no desaparece después de crear un objeto.

MCM respeta la división normal del inventario rápido de Noita entre ranuras de varitas y de objetos, y no debería reemplazar sin motivo un objeto que ya esté allí.

## Líquidos

MCM puede crear recipientes reales del juego con el líquido elegido.

El recipiente creado se comporta como un objeto normal de Noita:

- se guarda en el inventario;
- se puede arrojar al mundo;
- puede romperse;
- derrama su contenido;
- participa en las reacciones normales entre materiales.

# Materiales

El catálogo de materiales se construye a partir de las sustancias registradas en la instancia actual de Noita.

Incluye distintos tipos de materiales, entre ellos:

- líquidos;
- polvos;
- gases;
- fuego;
- materiales sólidos;
- materiales estáticos;
- materiales con representación especial.

Si otro mod activo añade correctamente su propio material a Noita, también puede aparecer en MCM.

## Pintar con materiales

1. Elige un material.
2. Elige el tamaño del pincel.
3. Pulsa **EMPEZAR A PINTAR**.
4. Cierra el inventario.
5. Mantén pulsado el botón asignado para dibujar en el mundo del juego.

De forma predeterminada se usa el **botón central del ratón**.

Abrir el inventario detiene el modo de pintura.

## Comportamiento de los materiales

MCM crea materiales reales del mundo del juego, no partículas decorativas.

Después de colocarlos, siguen obedeciendo la simulación normal de Noita:

- los líquidos fluyen;
- los polvos caen;
- los gases se dispersan;
- el fuego interactúa con el entorno;
- las sustancias reaccionan entre sí;
- los materiales inestables pueden transformarse en otros.

Para distintos tipos de material, MCM emplea métodos de colocación adecuados, incluidas funciones adicionales de NoitaPatcher cuando las herramientas normales de los mods no bastan para hacerlo correctamente.

# Ventajas

## Crear una ventaja

**LMB** crea la ventaja seleccionada en el mundo del juego.

Se puede recoger igual que una ventaja normal de Noita.

## Obtener ventajas

MCM permite obtener:

- 1 copia;
- 10 copias;
- 100 copias.

La obtención masiva se procesa de forma gradual para no ejecutar muchas operaciones pesadas en un solo fotograma.

La interfaz muestra el progreso de la tarea y permite cancelar el trabajo restante. Las copias que ya se hayan obtenido correctamente permanecen con el jugador después de cancelar.

## Eliminar ventajas

Eliminar una ventaja de forma segura es mucho más difícil que obtenerla.

Algunas ventajas modifican varios sistemas del juego a la vez, crean entidades o activan efectos para los que no existe una única forma universal de deshacer los cambios.

Por eso MCM solo elimina los cambios compatibles para los que puede realizar una operación inversa con suficiente fiabilidad.

El mod intenta revertir únicamente el estado creado por esa aplicación concreta de la ventaja, sin restablecer innecesariamente otros efectos o parámetros del jugador.

# Efectos

MCM permite aplicar y eliminar elementos compatibles, como:

- efectos del juego;
- estados relacionados con materiales.

Al eliminarlos, el mod intenta no afectar a estados ajenos que pertenezcan a ventajas u otros sistemas del juego.

Esto permite limpiar los efectos propios de MCM sin borrar de forma indiscriminada todo estado similar del jugador.

# Criaturas y transformaciones

## Crear criaturas

**LMB** crea la criatura seleccionada junto al jugador.

También puedes arrastrar la carta de una criatura fuera del menú para crearla en el punto elegido del mundo del juego.

**RMB** sobre una entrada compatible intenta transformar al jugador actual en la forma correspondiente.

## Compatibilidad de las formas

Las criaturas de Noita son muy diferentes entre sí en su estructura interna.

Por eso MCM distingue los objetivos de transformación por rutas XML exactas y no considera automáticamente intercambiables a todas las criaturas parecidas.

Durante una transformación, MCM utiliza las capacidades de la forma elegida y, cuando hace falta, aplica reglas de compatibilidad específicas para determinadas criaturas.

# Regreso tras una transformación y muerte de la forma

Puedes volver a la forma humana con la acción asignada, **TAB de forma predeterminada**.

MCM utiliza primero los mecanismos normales de Noita para terminar una transformación. Para los casos más complejos hay recuperación adicional mediante NoitaPatcher.

El mod también gestiona situaciones compatibles en las que una forma temporal recibe daño letal.

En esos casos, MCM intenta:

- conservar el cadáver de la forma muerta;
- restaurar al jugador humano;
- devolver el control;
- conservar el inventario;
- restaurar el estado relacionado con el jugador.

Esto no supone inmortalidad absoluta. Formas de muerte inusuales provocadas por otros mods, mods incompatibles o un fallo interno de Noita pueden eludir el mecanismo normal de recuperación.

# Control de criaturas

Además de elegir una forma en el catálogo, MCM puede tomar el control de **una criatura que ya existe en el mundo del juego**.

La tecla predeterminada es **G**.

Coloca el cursor sobre un objetivo compatible y usa la acción asignada.

MCM comprueba la criatura, realiza la transformación a una forma compatible y solo retira la entidad original del mundo después de confirmar que la transformación se ha completado correctamente.

Si la transformación no llega a completarse, la criatura original no debería desaparecer sin más.

Esta función no está limitada al catálogo estático de MCM. Una criatura compatible añadida por otro mod también puede pasar la comprobación, aunque no se garantiza compatibilidad universal con cualquier entidad de terceros.

# Jugador

**JUGADOR** es una entrada especial del catálogo de criaturas.

No es una forma normal para transformarse en ella.

**LMB** crea un personaje independiente para el que MCM intenta copiar:

- la apariencia del jugador;
- la salud máxima.

**RMB** sobre la entrada **JUGADOR** no transforma al jugador normal en esa entidad.

Si el jugador ya está en forma humana, la acción no hace nada. Si el jugador está transformado en otra criatura, se usa el regreso a la forma humana.

# Clima y tiempo

MCM permite modificar:

- la hora del día;
- las configuraciones predefinidas de clima;
- parámetros meteorológicos compatibles por separado.

Puedes imponer el estado que quieras y, después, liberar el parámetro correspondiente del control de MCM.

Por ejemplo, después de fijar una hora de forma forzada se puede devolver a Noita el avance natural del tiempo.

# Reglas del mundo

La sección **REGLAS** permite realizar cambios más profundos en el comportamiento del mundo del juego.

Según la regla concreta, se pueden controlar parámetros como:

- las relaciones entre criaturas;
- el oro;
- el uso de hechizos;
- la niebla de guerra;
- las recompensas por determinados tipos de muerte;
- las apariciones de curación;
- la sangre;
- la gravedad;
- el comportamiento físico;
- la fuerza de la patada;
- las uniones físicas;
- el ciclo de día y noche;
- otros parámetros globales compatibles.

La característica principal es que las reglas de MCM están diseñadas como **cambios reversibles**.

Para los ajustes compatibles, el mod guarda el estado original y permite devolver los parámetros a su valor normal.

Cuando se utiliza un multiplicador, el valor nuevo se calcula respecto al estado base en vez de multiplicarse indefinidamente por un resultado ya modificado.

Las operaciones que necesitan modificar una gran cantidad de entidades u objetos físicos se procesan gradualmente, en lugar de intentar modificar todo el mundo justo al pulsar un botón.

# Teletransporte

MCM permite desplazarse rápidamente a destinos preparados del juego, incluidos puntos de:

- la ruta principal;
- las Montañas Sagradas;
- grandes zonas laterales;
- otras ubicaciones compatibles.

Antes del teletransporte, el mod puede cargar la zona de destino y procura encontrar espacio libre cerca para no colocar al jugador directamente dentro de una pared sólida u otro obstáculo.

# Entangled Worlds

**Entangled Worlds / Noita Proxy es opcional.**

MCM funciona por completo en una partida para un jugador sin él.

Cuando Entangled Worlds está instalado, se habilitan funciones multijugador experimentales adicionales.

Para conseguir la mejor compatibilidad, se recomienda utilizar la misma versión de MCM entre todos los participantes.

## Objetos, varitas y hechizos

Siempre que es posible, los objetos del mundo y los hechizos que se arrojan utilizan los mecanismos normales de Entangled Worlds.

Los cambios del inventario también pueden transmitirse mediante Entangled Worlds.

## Ventajas

Una ventaja creada por MCM sigue siendo una entidad real del juego y, siempre que es posible, se transmite mediante el sistema normal de objetos del mundo de Entangled Worlds.

## Materiales

La pintura con materiales tiene compatibilidad multijugador experimental.

MCM sincroniza las zonas del mundo afectadas para que el resultado pueda aparecer para los demás participantes.

Para que funcione correctamente, el material correspondiente debe existir también para el otro jugador. Si los conjuntos de mods son distintos, no se puede garantizar una representación idéntica de todos los materiales.

## Clima y reglas del mundo

Los cambios compatibles del clima y de las reglas globales pueden sincronizarse mediante Entangled Worlds.

## Transformaciones y control de criaturas

Las transformaciones tienen compatibilidad adicional cuando se utiliza Entangled Worlds.

Al tomar el control de una criatura que ya existe, el mod también tiene en cuenta su estado de red. Si MCM no puede determinar con suficiente seguridad que la entidad original se puede retirar, prefiere dejarla en el mundo.

## Jugador

La creación de la entidad especial **JUGADOR** también es compatible al jugar con Entangled Worlds. En ese caso copia los colores de la apariencia de quien la creó.

## Teletransporte entre jugadores

Cuando Entangled Worlds está activo, la sección de teletransporte muestra los jugadores disponibles.

**IR CON** te teletransporta junto al jugador seleccionado.

**TRAER AQUÍ** envía al jugador seleccionado una solicitud para teletransportarse hasta ti.

En ambos casos, MCM procura utilizar un espacio libre cerca del destino.

## Limitaciones

La compatibilidad con Entangled Worlds sigue siendo experimental.

**En una partida multijugador, transformarse en jefes grandes o formados por múltiples articulaciones puede provocar una caída crítica del rendimiento y llegar a inutilizar la sesión de juego actual.**

Noita es extremadamente difícil de sincronizar por completo, sobre todo cuando cambian al mismo tiempo:

- el mundo de píxeles;
- los materiales;
- los objetos físicos;
- criaturas y jefes complejos;
- el contenido de otros mods.

Por eso MCM no promete una sincronización perfecta de absolutamente todos los estados posibles.

# NoitaPatcher y mods inseguros

La versión completa de MCM incluye **NoitaPatcher**.

Se utiliza para funciones que no pueden implementarse suficientemente con las herramientas normales de modificación de Noita, en particular para parte de los mecanismos de:

- recuperación tras transformaciones complejas;
- trabajo con entidades del juego;
- trabajo con el mundo del juego;
- colocación de determinados materiales;
- compatibilidad ampliada.

Por eso la versión completa necesita que se permitan los **mods inseguros**.

NoitaPatcher ya está incluido en la compilación preparada de MCM. No es necesario instalarlo por separado.

# Si algo no funciona

## MCM no se carga

Comprueba que, después de extraer el archivo, exista:

```text
Noita/mods/metamorph_creative_menu/mod.xml
```

Comprueba que:

- MCM esté activado en el menú **Mods**;
- aparezca **[x]** junto a él;
- los **mods inseguros estén permitidos**;
- el juego se haya iniciado con los mods activos.

## No funcionan las funciones que usan NoitaPatcher

Comprueba que exista:

```text
metamorph_creative_menu/NoitaPatcher/noitapatcher.dll
```

y asegúrate de que los **mods inseguros** estén permitidos.

## No puedes volver desde una forma

Prueba la acción asignada para volver, **TAB de forma predeterminada**.

Si el problema vuelve a ocurrir, al informar de él conviene indicar:

- el nombre exacto de la criatura;
- la ruta XML, si se conoce;
- cómo se obtuvo la forma;
- si funciona el regreso normal;
- si el problema solo aparece después de recibir daño letal;
- si se está utilizando Entangled Worlds.

## Problemas con Entangled Worlds

Comprueba:

- que todos los participantes usen la misma versión de MCM;
- que las versiones de Entangled Worlds sean compatibles;
- que se utilice el mismo conjunto de mods si el problema afecta a materiales o criaturas de otros mods.

# Informar de un error

[Crear un Issue](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)

Para que el informe sea útil, conviene indicar:

- la versión de MCM;
- qué estabas haciendo exactamente;
- el resultado esperado;
- el resultado real;
- el nombre de la criatura, objeto, ventaja o material implicado;
- si se utiliza Entangled Worlds;
- otros mods que puedan estar relacionados con el problema;
- el texto del error o el fragmento correspondiente del registro;
- una captura de pantalla o vídeo, si ayuda a mostrar el problema.

# Componentes de terceros

- **Noita** — Nolla Games.
- **NoitaPatcher** — dextercd, incluido en la versión completa.
- **lbase64** — Ilya Kolbin, incluido en MCM.
- **Entangled Worlds / Noita Proxy** — IntQuant y colaboradores del proyecto; se instala por separado y es opcional.

Los datos detallados sobre los proyectos originales y sus licencias se encuentran en [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

---

**Metamorph: Creative Menu** es un mod no oficial creado por usuarios para Noita. El proyecto no está relacionado con Nolla Games ni forma parte oficial del juego.

[↑ Volver a la selección de idioma](#languages)