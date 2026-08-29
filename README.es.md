<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">
  Un conjunto creativo para Noita: hechizos, varitas, objetos, materiales, ventajas, criaturas, efectos, teletransporte, clima y reglas del mundo.
</p>

<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [**Español**](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## Descargar

Versión actual: **2.0.0**

| Paquete | Descarga |
|---|---|
| **Última compilación lista para instalar** | **[⬇️ Descargar Metamorph-Creative-Menu.zip](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)** |
| Página de la compilación | [Última compilación lista para instalar](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) |

> El ZIP ya contiene la carpeta completa `metamorph_creative_menu`, incluido NoitaPatcher. Extrae esa carpeta directamente en `Noita/mods/`.

Ruta final correcta:

```text
Noita/mods/metamorph_creative_menu/mod.xml
```

Si terminas con `metamorph_creative_menu/metamorph_creative_menu/mod.xml`, el archivo se extrajo un nivel de carpeta demasiado profundo.

---

## Español

### Instalación

1. [Descarga el ZIP más reciente listo para instalar](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Cierra completamente Noita antes de instalar o actualizar el mod.
3. En Steam, abre **Biblioteca → clic derecho en Noita → Administrar → Ver archivos locales**.
4. Abre la carpeta `mods` del juego y copia dentro la carpeta completa **`metamorph_creative_menu`**.
5. Comprueba que existe `Noita/mods/metamorph_creative_menu/mod.xml`. No cambies el nombre de la carpeta del mod.
6. Inicia Noita, activa **Metamorph: Creative Menu**, permite **Unsafe mods / unrestricted API** cuando sea necesario y reinicia Noita después de activar el mod.
7. Empieza una partida y pulsa **TAB**. Si se abre el menú, la instalación ha terminado.

**Actualización:** cierra Noita, elimina la carpeta antigua `metamorph_creative_menu` y copia la nueva dentro de `mods`. Sustituir la carpeta completa evita que queden archivos obsoletos de versiones anteriores.

### Controles

- **F4 o TAB**: abrir o cerrar el Creative Menu.
- **TAB durante una transformación**: volver a la forma humana.
- **G** de forma predeterminada: tomar el control de una criatura compatible bajo el cursor.
- **Botón central del ratón**: dibujar con el material seleccionado.
- Las asignaciones pueden cambiarse en la sección CONTROLES o en la configuración del mod. Las acciones disponibles para clic izquierdo y derecho se muestran en la interfaz.

### Qué puede hacer MCM

- Obtener y colocar hechizos, y moverlos entre varitas, espacios de Lanzamiento Siempre, el inventario y el mundo.
- Editar estadísticas, apariencia y bloqueos de las varitas; guardar preajustes y crear copias.
- Generar objetos cerca del jugador o en una posición elegida del mundo y colocar objetos compatibles directamente en el inventario.
- Crear frascos con líquidos seleccionados.
- Seleccionar materiales y dibujarlos en el mundo.
- Generar, añadir y eliminar ventajas.
- Generar criaturas cerca del jugador o en una posición elegida del mundo.
- Transformarse en criaturas, tomar el control de criaturas existentes y volver a la forma humana.
- Generar una entidad PLAYER independiente.
- Aplicar y eliminar efectos del juego.
- Cambiar el clima, la hora del día, la gravedad y otras reglas del mundo.
- Teletransportarse a ubicaciones del juego.
- Con Entangled Worlds, teletransportarse a otros jugadores o traerlos hasta ti.
- Cambiar asignaciones de teclas y buscar en los catálogos de hechizos, objetos, materiales, ventajas y criaturas.
- Mover y cambiar el tamaño de la ventana del menú; su posición y tamaño se conservan entre ejecuciones del juego.

<details>
<summary><strong>Transformaciones, compatibilidad y recuperación</strong></summary>

MCM utiliza datos de compatibilidad por ruta XML exacta y excepciones limitadas de encaminamiento seguro para entidades que se sabe que son peligrosas o inadecuadas para una transformación nativa directa. Las formas controladas por el jugador intentan conservar el movimiento, los ataques, la apariencia y la física nativos que resulten útiles, mientras desactivan la inteligencia artificial que entraría en conflicto con el control del jugador. Los jefes complejos, las entidades con scripts propios y los objetos físicos pueden requerir adaptadores específicos y no siempre reproducen exactamente todo el comportamiento original de su inteligencia artificial.

NoitaPatcher se utiliza para mecanismos de recuperación de último recurso, como la serialización y deserialización de entidades, la transferencia de control de la entidad del jugador y otras funciones avanzadas durante la ejecución. Por ese motivo, la versión completa e independiente solicita acceso de mod sin restricciones.

</details>

<details>
<summary><strong>Integración multijugador con Entangled Worlds</strong></summary>

**Entangled Worlds es opcional.** MCM está diseñado para funcionar como un mod completo para un jugador sin EW.

Cuando `quant.ew` está activo, MCM habilita una integración experimental para objetos compartidos, ventajas, clima, reglas del mundo, formas y control de criaturas, solicitudes de compañero y comportamientos relacionados con autoridad y sincronización. Todos los participantes deben usar la misma versión de MCM. El soporte multijugador se considera experimental porque no todas las situaciones límite de Noita y EW pueden sincronizarse con garantías perfectas.

</details>

### Requisitos y componentes de terceros

- **Noita** — juego obligatorio, de Nolla Games.
- **NoitaPatcher** de dextercd — incluido con MCM y utilizado para funciones avanzadas y recuperación.
- **lbase64** de Ilya Kolbin — implementación local de Base64 incluida.
- **Entangled Worlds / Noita Proxy** de IntQuant y colaboradores — integración multijugador opcional; no es necesaria para un jugador.

Los enlaces exactos a los proyectos originales, las rutas de los componentes incluidos y las notas sobre licencias o estado están en [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Solución de problemas

- **TAB no hace nada:** comprueba la ruta exacta de `mod.xml`, asegúrate de que MCM está activado, permite Unsafe mods/unrestricted API y reinicia Noita.
- **Falta la recuperación avanzada o parte de las reglas del mundo:** comprueba que existe `metamorph_creative_menu/NoitaPatcher/noitapatcher.dll` y que el acceso unrestricted API está permitido.
- **Una forma no vuelve correctamente:** indica el nombre o XML exacto de la criatura y si falló el regreso normal con TAB o el regreso después de recibir daño mortal.
- **Desincronización con EW:** comprueba que todos usan la misma compilación de MCM y una versión compatible de EW.

### Enlaces

- [Última compilación](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build)
- [Informar de un error](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)
- [Componentes de terceros](THIRD_PARTY_NOTICES.md)
- [Noita](https://noitagame.com/)
- [NoitaPatcher](https://github.com/dextercd/NoitaPatcher)
- [Documentación de NoitaPatcher](https://dexter.döpping.eu/NoitaPatcher/)
- [Entangled Worlds](https://github.com/IntQuant/noita_entangled_worlds)
- [lbase64](https://github.com/iskolbin/lbase64)

[↑ Volver a la selección de idioma](#languages)

---

## Para desarrolladores

El mod jugable se encuentra en `metamorph_creative_menu/`.

- Notas de arquitectura y desarrollo: `metamorph_creative_menu/README.txt`
- Conjunto de pruebas de regresión: `metamorph_creative_menu/tests/`
- Instrucciones de pruebas: `metamorph_creative_menu/tests/TESTING.txt`
- Avisos de componentes de terceros: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)

El flujo automático `latest-build` del repositorio empaqueta la carpeta jugable `metamorph_creative_menu` en un ZIP listo para instalar y actualiza la dirección estable de descarga indicada arriba.