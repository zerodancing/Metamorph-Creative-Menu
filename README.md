<p align="center">
  <img src="assets/metamorph-creative-menu-banner.jpg" alt="Metamorph: Creative Menu" width="100%">
</p>

<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">
  A standalone creative toolkit for Noita — transformations, possession, spells, items, perks, effects, weather and World Rules.
</p>

<a id="languages"></a>

## Choose your language

| Language | Guide |
|---|---|
| English | [Open guide](#en) |
| Русский | [Открыть руководство](#ru) |
| Português (Brasil) | [Abrir guia](#pt-br) |
| Español | [Abrir guía](#es) |
| Deutsch | [Anleitung öffnen](#de) |
| Français | [Ouvrir le guide](#fr) |
| Italiano | [Apri la guida](#it) |
| Polski | [Otwórz instrukcję](#pl) |
| 简体中文 | [打开指南](#zh-cn) |
| 日本語 | [ガイドを開く](#ja) |
| 한국어 | [가이드 열기](#ko) |

## Download

| Package | Download |
|---|---|
| **Latest ready-to-install build** | **[⬇️ Download Metamorph-Creative-Menu.zip](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)** |
| Build page | [Latest ready-to-install build](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) |

> The ZIP already contains the complete `metamorph_creative_menu` folder, including the bundled NoitaPatcher runtime. Extract that folder directly into `Noita/mods/`.
>
> ZIP уже содержит готовую папку `metamorph_creative_menu`, включая встроенный NoitaPatcher. Её нужно распаковать прямо в `Noita/mods/`.

Correct final path:

```text
Noita/mods/metamorph_creative_menu/mod.xml
```

If you end up with `metamorph_creative_menu/metamorph_creative_menu/mod.xml`, the archive was extracted one folder too deep.

---

<a id="en"></a>

## English

### Installation

1. [Download the latest ready-to-install ZIP](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Close Noita before installing or updating the mod.
3. On Steam, open **Library → right-click Noita → Manage → Browse local files**.
4. Open the game's `mods` folder and copy the complete **`metamorph_creative_menu`** folder into it.
5. Verify that `Noita/mods/metamorph_creative_menu/mod.xml` exists. Do not rename the mod folder.
6. Start Noita, enable **Metamorph: Creative Menu**, allow **Unsafe mods / unrestricted API** when required, and restart Noita after enabling the mod.
7. Start a run and press **TAB**. If the menu opens, installation is complete.

**Updating:** close Noita, remove the old `metamorph_creative_menu` folder, then copy the new one into `mods`. Replacing the whole folder avoids stale files from older builds.

### Controls

- **TAB** — open or close the Creative Menu.
- **TAB while transformed** — return to the human player form.
- **G** by default — possess a supported creature under the cursor. The key can be changed in MCM settings.
- Most catalog entries expose different **LMB/RMB** actions; the exact action is shown in the UI.

### What MCM can do

- **Spells & wands** — search spells, replace a selected wand slot, delete a spell or drop it into the world.
- **Items** — spawn supported items, containers, liquids, wands, books, quest objects and more; MCM can also attempt direct inventory placement.
- **Perks** — spawn/apply perks and remove one or all tracked stacks while trying to restore only state owned by that perk.
- **Effects** — apply supported timed/status effects, choose duration where supported and remove editor-owned effects.
- **Creatures & forms** — spawn creatures or transform into supported creatures, objects and special forms.
- **Human recovery** — normal TAB return uses the native polymorph lifecycle, with serialized NoitaPatcher recovery available for hard fallback paths.
- **Death handoff** — supported transformed bodies can die while player authority is returned to the restored human body instead of immediately ending the run.
- **Possession** — take over a supported existing creature under the cursor rather than simply spawning a duplicate.
- **PLAYER companion** — spawn a player-like allied companion with copied presentation/inventory behavior and extended wand use when supported.
- **Search** — large catalogs can be searched by localized names, IDs and descriptions depending on the editor.
- **Weather** — control time of day, clouds, fog, wind, rain, lightning and presets; RELEASE stops MCM from holding the override.
- **World Rules** — reversible overrides for creature relations, gold lifetime, spell uses, fog of war, trick-kill systems, healing drops, friendly rats, gore, damage flash, stain shedding, gravity, physics damping, blood volume, kick force, joint strength and day-cycle speed.

<details>
<summary><strong>Transformations, compatibility and recovery</strong></summary>

MCM uses exact XML-path compatibility data and narrow safe-routing exceptions for entities that are known to be unsafe or unsuitable for direct native polymorph. Player-controlled forms try to retain useful native movement, attacks, visuals and physics while disabling AI that would fight player input. Complex bosses, scripted entities and physics objects can require dedicated adapters and may not reproduce every AI behavior exactly.

NoitaPatcher is used for hard recovery capabilities such as entity serialization/deserialization, player handoff and other extended runtime functions. This is why the complete standalone build requests unrestricted/unsafe mod access.

</details>

<details>
<summary><strong>Entangled Worlds multiplayer integration</strong></summary>

**Entangled Worlds is optional.** MCM is designed to work as a complete standalone single-player mod without EW.

When `quant.ew` is enabled, MCM activates experimental integration for shared items, perks, weather, World Rules, forms/possession, companion requests and related authority/synchronization behavior. Use the same MCM version on every peer. Multiplayer support is intentionally considered experimental because not every Noita/EW edge case can be guaranteed to synchronize perfectly.

</details>

### Requirements & third-party components

- **Noita** — required game, by Nolla Games.
- **NoitaPatcher** by dextercd — bundled with MCM and used for extended runtime/recovery functionality.
- **lbase64** by Ilya Kolbin — bundled local Base64 implementation.
- **Entangled Worlds / Noita Proxy** by IntQuant and contributors — optional multiplayer integration; not required for single player.

Exact upstream links, bundled paths and third-party license/status notes are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Troubleshooting

- **TAB does nothing:** verify the exact `mod.xml` path, make sure MCM is enabled, allow Unsafe mods/unrestricted API, then restart Noita.
- **Extended recovery or World Rules functionality is missing:** verify `metamorph_creative_menu/NoitaPatcher/noitapatcher.dll` is present and unrestricted API access is allowed.
- **A form fails to return correctly:** report the exact creature name/XML and whether normal TAB return or fatal-death return failed.
- **EW mismatch/desync:** verify that every peer uses the same MCM build and a compatible EW build.

### Links

- [Latest build](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build)
- [Report a bug](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)
- [Third-party notices](THIRD_PARTY_NOTICES.md)
- [Noita](https://noitagame.com/)
- [NoitaPatcher](https://github.com/dextercd/NoitaPatcher)
- [NoitaPatcher documentation](https://dexter.döpping.eu/NoitaPatcher/)
- [Entangled Worlds](https://github.com/IntQuant/noita_entangled_worlds)
- [lbase64](https://github.com/iskolbin/lbase64)

[↑ Back to language selection](#languages)

---

<a id="ru"></a>

## Русский

### Установка

1. [Скачайте готовый ZIP последней сборки](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Полностью закройте Noita перед установкой или обновлением.
3. В Steam откройте **Библиотека → ПКМ по Noita → Управление → Просмотреть локальные файлы**.
4. Откройте папку `mods` и скопируйте туда целиком папку **`metamorph_creative_menu`** из архива.
5. Проверьте, что существует файл `Noita/mods/metamorph_creative_menu/mod.xml`. Папку мода не переименовывайте.
6. Запустите Noita, включите **Metamorph: Creative Menu**, разрешите **Unsafe mods / unrestricted API**, если игра этого требует, и перезапустите Noita после включения мода.
7. Начните забег и нажмите **TAB**. Если меню открылось — установка закончена.

**Обновление:** закройте Noita, удалите старую папку `metamorph_creative_menu` и скопируйте новую. Полная замена папки не оставляет устаревшие файлы предыдущих версий.

### Управление

- **TAB** — открыть или закрыть Creative Menu.
- **TAB во время превращения** — вернуться в человеческую форму.
- **G** по умолчанию — занять тело поддерживаемого существа под курсором. Клавиша меняется в настройках MCM.
- У большинства элементов каталога **ЛКМ/ПКМ** выполняют разные действия; точная подсказка показывается в интерфейсе.

### Возможности MCM

- **Заклинания и посохи** — поиск заклинаний, замена выбранного слота, удаление или выбрасывание заклинания в мир.
- **Предметы** — создание предметов, контейнеров, жидкостей, посохов, книг, квестовых объектов и других поддерживаемых сущностей; возможна попытка сразу положить предмет в инвентарь.
- **Перки** — создание/применение перков и удаление одного или всех отслеживаемых уровней с восстановлением принадлежащего перку состояния.
- **Эффекты** — применение status/timed effects, выбор длительности и удаление состояния, созданного редактором.
- **Существа и формы** — создание мобов и превращение в поддерживаемых существ, объекты и специальные формы.
- **Возврат человека** — обычный TAB использует нативный lifecycle polymorph, а для аварийных сценариев доступно сериализованное восстановление через NoitaPatcher.
- **Death handoff** — смерть поддерживаемой формы может вернуть player authority восстановленному человеку вместо немедленного Game Over.
- **Possession** — занятие тела уже существующего поддерживаемого моба под курсором, а не простое создание копии.
- **Союзник PLAYER** — создание союзника, похожего на игрока, с копированием визуального/инвентарного состояния и расширенным использованием посоха при доступных возможностях runtime.
- **Поиск** — крупные каталоги ищут по локализованным именам, ID и описаниям в зависимости от вкладки.
- **Погода** — время суток, облака, туман, ветер, дождь, молнии и пресеты; RELEASE прекращает активное удержание погодных значений.
- **World Rules** — обратимые правила для отношений существ, времени жизни золота, использования заклинаний, fog of war, trick-kill механик, healing drops, friendly rats, gore, damage flash, stain shedding, гравитации, физического damping, объёма крови, силы пинка, прочности соединений и скорости цикла дня.

<details>
<summary><strong>Превращения, совместимость и восстановление</strong></summary>

MCM хранит совместимость по точным XML-путям и использует узкие safe-routing исключения для сущностей, которые опасно или бессмысленно превращать напрямую нативным polymorph. Управляемая игроком форма старается сохранить полезное движение, атаки, внешний вид и физику, отключая конфликтующий AI. Для сложных боссов, scripted-сущностей и physics-объектов могут использоваться отдельные адаптеры.

NoitaPatcher нужен для жёстких recovery-сценариев: сериализации/десериализации сущностей, player handoff и других расширенных runtime-возможностей. Поэтому полная standalone-сборка использует unrestricted/unsafe mod access.

</details>

<details>
<summary><strong>Интеграция с Entangled Worlds</strong></summary>

**Entangled Worlds не обязателен.** В одиночной игре MCM является полноценным standalone-модом.

При включённом `quant.ew` активируется экспериментальная синхронизация предметов, перков, погоды, World Rules, форм/possession, запросов companion и связанных authority-механизмов. На всех клиентах должна быть одна и та же версия MCM. Сетевая интеграция считается экспериментальной, потому что не все edge cases Noita/EW можно гарантированно синхронизировать.

</details>

### Требования и сторонние компоненты

- **Noita** — обязательная игра, Nolla Games.
- **NoitaPatcher** от dextercd — включён в MCM и используется для расширенного runtime и recovery.
- **lbase64** от Ilya Kolbin — локальная встроенная реализация Base64.
- **Entangled Worlds / Noita Proxy** от IntQuant и contributors — опциональная мультиплеерная интеграция, для одиночной игры не нужна.

Точные upstream-ссылки, пути встроенных компонентов и сведения об их лицензиях/статусе находятся в [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Если что-то не работает

- **TAB ничего не делает:** проверьте путь к `mod.xml`, включение MCM, Unsafe mods/unrestricted API и перезапустите Noita.
- **Нет расширенного recovery или части World Rules:** проверьте наличие `metamorph_creative_menu/NoitaPatcher/noitapatcher.dll` и доступ к unrestricted API.
- **Форма не возвращается правильно:** укажите точное имя/XML существа и уточните, сломался обычный возврат по TAB или возврат после смертельного урона.
- **EW desync:** убедитесь, что у всех участников одинаковая сборка MCM и совместимая версия EW.

### Ссылки

- [Последняя готовая сборка](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build)
- [Сообщить об ошибке](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)
- [Сторонние компоненты](THIRD_PARTY_NOTICES.md)
- [Noita](https://noitagame.com/)
- [NoitaPatcher](https://github.com/dextercd/NoitaPatcher)
- [Документация NoitaPatcher](https://dexter.döpping.eu/NoitaPatcher/)
- [Entangled Worlds](https://github.com/IntQuant/noita_entangled_worlds)
- [lbase64](https://github.com/iskolbin/lbase64)

[↑ К выбору языка](#languages)

---

<a id="pt-br"></a>

## Português (Brasil)

### Instalação

1. [Baixe o ZIP pronto para instalar](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Feche o Noita antes de instalar ou atualizar o mod.
3. No Steam: **Biblioteca → clique direito em Noita → Gerenciar → Explorar arquivos locais**.
4. Abra a pasta `mods` e copie para ela a pasta completa **`metamorph_creative_menu`**.
5. Confirme que existe `Noita/mods/metamorph_creative_menu/mod.xml`.
6. Inicie o Noita, ative **Metamorph: Creative Menu**, permita **Unsafe mods / unrestricted API** quando necessário e reinicie o jogo.
7. Entre em uma partida e pressione **TAB**.

### Controles

- **TAB** — abre/fecha o menu; durante uma transformação, retorna à forma humana.
- **G** por padrão — possui uma criatura compatível sob o cursor; a tecla pode ser alterada nas configurações.
- **LMB/RMB** — ações diferentes dependendo do item do catálogo; a interface mostra a ação exata.

### Recursos

MCM permite editar **magias e varinhas**, criar **itens e líquidos**, aplicar/remover **perks e efeitos**, criar criaturas, **transformar-se**, possuir criaturas existentes, recuperar a forma humana, fazer **death handoff**, criar um aliado `PLAYER`, pesquisar grandes catálogos, controlar **clima** e aplicar **World Rules reversíveis** para relações entre criaturas, ouro, usos de magia, fog of war, trick kills, drops de cura, gore, gravidade, física, sangue, força de chute, juntas e ciclo do dia.

<details><summary><strong>Standalone, recuperação e Entangled Worlds</strong></summary>

O modo single-player não exige Entangled Worlds. O MCM inclui NoitaPatcher para serialização/recuperação, player handoff e outras funções avançadas; por isso a versão completa requer acesso Unsafe/unrestricted. Com `quant.ew` ativo, o MCM habilita integração multiplayer experimental para itens, perks, clima, World Rules, formas/possession e companion. Todos os peers devem usar a mesma versão do MCM.

</details>

### Dependências e créditos

- **Noita** — Nolla Games.
- **NoitaPatcher** — dextercd, incluído.
- **lbase64** — Ilya Kolbin, incluído.
- **Entangled Worlds / Noita Proxy** — IntQuant e colaboradores, opcional.

Veja caminhos, links upstream e informações de licença em [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Problemas comuns

Se TAB não funcionar, verifique `Noita/mods/metamorph_creative_menu/mod.xml`, ative o mod, permita Unsafe/unrestricted API e reinicie o Noita. Para problemas de transformação, informe a criatura/XML exata. Para EW, confirme versões idênticas do MCM nos peers.

[Downloads](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) · [Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues) · [↑ Idiomas](#languages)

---

<a id="es"></a>

## Español

### Instalación

1. [Descarga el ZIP listo para instalar](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Cierra Noita antes de instalar o actualizar.
3. En Steam: **Biblioteca → clic derecho en Noita → Administrar → Ver archivos locales**.
4. Copia la carpeta completa **`metamorph_creative_menu`** dentro de `Noita/mods/`.
5. Comprueba que existe `Noita/mods/metamorph_creative_menu/mod.xml`.
6. Activa **Metamorph: Creative Menu**, permite **Unsafe mods / unrestricted API** cuando sea necesario y reinicia Noita.
7. Empieza una partida y pulsa **TAB**.

### Controles

- **TAB** — abre/cierra el menú; transformado, vuelve a la forma humana.
- **G** por defecto — posee una criatura compatible bajo el cursor.
- **LMB/RMB** — acciones diferentes según la entrada; la interfaz muestra la acción exacta.

### Funciones

MCM permite editar **hechizos y varitas**, crear **objetos y líquidos**, aplicar o quitar **perks y efectos**, crear criaturas, **transformarse**, poseer criaturas existentes, recuperar al jugador humano, realizar **death handoff**, crear un aliado `PLAYER`, buscar en catálogos, controlar el **clima** y aplicar **World Rules reversibles** para relaciones entre criaturas, oro, usos de hechizos, fog of war, trick kills, curación, gore, gravedad, física, sangre, fuerza de patada, uniones y ciclo diurno.

<details><summary><strong>Standalone, recuperación y Entangled Worlds</strong></summary>

Entangled Worlds no es necesario para un jugador. MCM incluye NoitaPatcher para serialización/recuperación, player handoff y funciones avanzadas, por lo que la versión completa requiere acceso Unsafe/unrestricted. Con `quant.ew` activo se habilita una integración multijugador experimental para objetos, perks, clima, World Rules, formas/possession y companion. Todos los peers deben usar la misma versión de MCM.

</details>

### Dependencias y créditos

- **Noita** — Nolla Games.
- **NoitaPatcher** — dextercd, incluido.
- **lbase64** — Ilya Kolbin, incluido.
- **Entangled Worlds / Noita Proxy** — IntQuant y colaboradores, opcional.

Consulta enlaces upstream y notas de licencia en [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Solución rápida

Si TAB no funciona, verifica la ruta de `mod.xml`, activa el mod, permite Unsafe/unrestricted API y reinicia Noita. Para errores de formas, informa la criatura/XML exacta. Para EW, verifica que todos usen la misma versión de MCM.

[Descargas](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) · [Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues) · [↑ Idiomas](#languages)

---

<a id="de"></a>

## Deutsch

### Installation

1. [Lade das installationsfertige ZIP herunter](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Beende Noita vor Installation oder Update vollständig.
3. In Steam: **Bibliothek → Rechtsklick auf Noita → Verwalten → Lokale Dateien durchsuchen**.
4. Kopiere den vollständigen Ordner **`metamorph_creative_menu`** nach `Noita/mods/`.
5. Prüfe, dass `Noita/mods/metamorph_creative_menu/mod.xml` existiert.
6. Aktiviere **Metamorph: Creative Menu**, erlaube **Unsafe mods / unrestricted API**, falls erforderlich, und starte Noita neu.
7. Starte einen Run und drücke **TAB**.

### Steuerung

- **TAB** — Menü öffnen/schließen; verwandelt: zur menschlichen Form zurückkehren.
- **G** standardmäßig — eine unterstützte Kreatur unter dem Cursor übernehmen.
- **LMB/RMB** — unterschiedliche Aktionen je Katalogeintrag; die UI zeigt die genaue Aktion.

### Funktionen

MCM kann **Zauber und Zauberstäbe** bearbeiten, **Items und Flüssigkeiten** erzeugen, **Perks und Effekte** anwenden/entfernen, Kreaturen spawnen, den Spieler **verwandeln**, existierende Kreaturen übernehmen, den Menschen wiederherstellen, **Death Handoff** durchführen, einen `PLAYER`-Begleiter erzeugen, Kataloge durchsuchen, **Wetter** steuern und **reversible World Rules** für Kreaturenbeziehungen, Gold, Zaubernutzungen, fog of war, trick kills, Heilungsdrops, Gore, Gravitation, Physik, Blut, Kick-Kraft, Gelenke und Tageszyklus anwenden.

<details><summary><strong>Standalone, Recovery und Entangled Worlds</strong></summary>

Entangled Worlds ist für Singleplayer nicht erforderlich. MCM enthält NoitaPatcher für Serialisierung/Recovery, Player Handoff und weitere erweiterte Funktionen; deshalb benötigt die Vollversion Unsafe/unrestricted API. Mit aktivem `quant.ew` wird eine experimentelle Multiplayer-Integration für Items, Perks, Wetter, World Rules, Formen/Possession und Companion aktiviert. Alle Peers sollten dieselbe MCM-Version verwenden.

</details>

### Abhängigkeiten & Credits

- **Noita** — Nolla Games.
- **NoitaPatcher** — dextercd, enthalten.
- **lbase64** — Ilya Kolbin, enthalten.
- **Entangled Worlds / Noita Proxy** — IntQuant und Mitwirkende, optional.

Upstream-Links und Lizenzhinweise: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Fehlerbehebung

Wenn TAB nicht funktioniert, prüfe den `mod.xml`-Pfad, aktiviere MCM, erlaube Unsafe/unrestricted API und starte Noita neu. Bei Formfehlern bitte die genaue Kreatur/XML nennen. Bei EW müssen alle Peers dieselbe MCM-Version verwenden.

[Downloads](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) · [Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues) · [↑ Sprachen](#languages)

---

<a id="fr"></a>

## Français

### Installation

1. [Téléchargez le ZIP prêt à installer](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Fermez complètement Noita avant l'installation ou la mise à jour.
3. Dans Steam : **Bibliothèque → clic droit sur Noita → Gérer → Parcourir les fichiers locaux**.
4. Copiez le dossier complet **`metamorph_creative_menu`** dans `Noita/mods/`.
5. Vérifiez que `Noita/mods/metamorph_creative_menu/mod.xml` existe.
6. Activez **Metamorph: Creative Menu**, autorisez **Unsafe mods / unrestricted API** si nécessaire puis redémarrez Noita.
7. Lancez une partie et appuyez sur **TAB**.

### Commandes

- **TAB** — ouvre/ferme le menu ; transformé, revient à la forme humaine.
- **G** par défaut — prend possession d'une créature compatible sous le curseur.
- **LMB/RMB** — actions différentes selon l'entrée ; l'interface affiche l'action exacte.

### Fonctionnalités

MCM permet de modifier **sorts et baguettes**, créer **objets et liquides**, appliquer/retirer **perks et effets**, faire apparaître des créatures, se **transformer**, posséder des créatures existantes, restaurer la forme humaine, effectuer le **death handoff**, créer un allié `PLAYER`, rechercher dans les catalogues, contrôler la **météo** et appliquer des **World Rules réversibles** concernant relations entre créatures, or, utilisations de sorts, fog of war, trick kills, soins, gore, gravité, physique, sang, puissance de coup de pied, articulations et cycle jour/nuit.

<details><summary><strong>Standalone, récupération et Entangled Worlds</strong></summary>

Entangled Worlds n'est pas requis en solo. MCM inclut NoitaPatcher pour la sérialisation/récupération, le player handoff et d'autres fonctions avancées ; la version complète nécessite donc Unsafe/unrestricted API. Avec `quant.ew`, une intégration multijoueur expérimentale est activée pour objets, perks, météo, World Rules, formes/possession et companion. Tous les peers doivent utiliser la même version de MCM.

</details>

### Dépendances & crédits

- **Noita** — Nolla Games.
- **NoitaPatcher** — dextercd, inclus.
- **lbase64** — Ilya Kolbin, inclus.
- **Entangled Worlds / Noita Proxy** — IntQuant et contributeurs, optionnel.

Liens upstream et informations de licence : [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Dépannage

Si TAB ne fonctionne pas, vérifiez le chemin de `mod.xml`, activez MCM, autorisez Unsafe/unrestricted API et redémarrez Noita. Pour un problème de forme, indiquez la créature/XML exacte. Avec EW, utilisez la même version de MCM sur tous les peers.

[Téléchargements](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) · [Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues) · [↑ Langues](#languages)

---

<a id="it"></a>

## Italiano

### Installazione

1. [Scarica lo ZIP pronto all'installazione](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Chiudi completamente Noita prima di installare o aggiornare.
3. Su Steam: **Libreria → clic destro su Noita → Gestisci → Sfoglia file locali**.
4. Copia l'intera cartella **`metamorph_creative_menu`** in `Noita/mods/`.
5. Verifica che esista `Noita/mods/metamorph_creative_menu/mod.xml`.
6. Attiva **Metamorph: Creative Menu**, consenti **Unsafe mods / unrestricted API** se richiesto e riavvia Noita.
7. Avvia una partita e premi **TAB**.

### Controlli

- **TAB** — apre/chiude il menu; durante una trasformazione torna alla forma umana.
- **G** per impostazione predefinita — possiede una creatura supportata sotto il cursore.
- **LMB/RMB** — azioni diverse a seconda della voce; l'interfaccia mostra l'azione esatta.

### Funzioni

MCM permette di modificare **incantesimi e bacchette**, creare **oggetti e liquidi**, applicare/rimuovere **perk ed effetti**, generare creature, **trasformarsi**, possedere creature esistenti, recuperare la forma umana, eseguire il **death handoff**, creare un alleato `PLAYER`, cercare nei cataloghi, controllare il **meteo** e applicare **World Rules reversibili** per relazioni tra creature, oro, usi degli incantesimi, fog of war, trick kill, cure, gore, gravità, fisica, sangue, forza del calcio, giunti e ciclo del giorno.

<details><summary><strong>Standalone, recovery ed Entangled Worlds</strong></summary>

Entangled Worlds non è necessario in single-player. MCM include NoitaPatcher per serializzazione/recovery, player handoff e altre funzioni avanzate; per questo la versione completa richiede Unsafe/unrestricted API. Con `quant.ew` attivo viene abilitata un'integrazione multiplayer sperimentale per oggetti, perk, meteo, World Rules, forme/possession e companion. Tutti i peer devono usare la stessa versione di MCM.

</details>

### Dipendenze e crediti

- **Noita** — Nolla Games.
- **NoitaPatcher** — dextercd, incluso.
- **lbase64** — Ilya Kolbin, incluso.
- **Entangled Worlds / Noita Proxy** — IntQuant e collaboratori, opzionale.

Link upstream e informazioni sulle licenze: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Risoluzione problemi

Se TAB non funziona, controlla il percorso di `mod.xml`, abilita MCM, consenti Unsafe/unrestricted API e riavvia Noita. Per problemi con le forme indica creatura/XML esatta. Con EW usa la stessa versione MCM su tutti i peer.

[Download](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) · [Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues) · [↑ Lingue](#languages)

---

<a id="pl"></a>

## Polski

### Instalacja

1. [Pobierz gotowy ZIP](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Zamknij Noitę przed instalacją lub aktualizacją.
3. Steam: **Biblioteka → prawy przycisk na Noita → Zarządzaj → Przeglądaj pliki lokalne**.
4. Skopiuj cały folder **`metamorph_creative_menu`** do `Noita/mods/`.
5. Sprawdź, czy istnieje `Noita/mods/metamorph_creative_menu/mod.xml`.
6. Włącz **Metamorph: Creative Menu**, zezwól na **Unsafe mods / unrestricted API**, jeśli jest to wymagane, i uruchom Noitę ponownie.
7. Rozpocznij grę i naciśnij **TAB**.

### Sterowanie

- **TAB** — otwiera/zamyka menu; podczas transformacji wraca do ludzkiej formy.
- **G** domyślnie — przejmuje wspieraną istotę pod kursorem.
- **LMB/RMB** — różne akcje zależnie od wpisu; interfejs pokazuje dokładne działanie.

### Możliwości

MCM pozwala edytować **zaklęcia i różdżki**, tworzyć **przedmioty i płyny**, nakładać/usuwać **perki i efekty**, tworzyć stworzenia, **transformować się**, przejmować istniejące stworzenia, odzyskiwać ludzką formę, wykonywać **death handoff**, tworzyć sojusznika `PLAYER`, przeszukiwać katalogi, kontrolować **pogodę** oraz stosować **odwracalne World Rules** dotyczące relacji stworzeń, złota, użyć zaklęć, fog of war, trick kills, leczenia, gore, grawitacji, fizyki, krwi, siły kopnięcia, połączeń i cyklu dnia.

<details><summary><strong>Standalone, recovery i Entangled Worlds</strong></summary>

Entangled Worlds nie jest wymagany w single-player. MCM zawiera NoitaPatcher do serializacji/recovery, player handoff i innych zaawansowanych funkcji, dlatego pełna wersja wymaga Unsafe/unrestricted API. Przy aktywnym `quant.ew` włącza się eksperymentalna integracja multiplayer dla przedmiotów, perków, pogody, World Rules, form/possession i companion. Wszyscy gracze powinni używać tej samej wersji MCM.

</details>

### Zależności i autorzy

- **Noita** — Nolla Games.
- **NoitaPatcher** — dextercd, dołączony.
- **lbase64** — Ilya Kolbin, dołączony.
- **Entangled Worlds / Noita Proxy** — IntQuant i współtwórcy, opcjonalny.

Linki upstream i informacje licencyjne: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Rozwiązywanie problemów

Jeśli TAB nie działa, sprawdź ścieżkę `mod.xml`, włącz MCM, zezwól na Unsafe/unrestricted API i uruchom Noitę ponownie. Przy błędzie formy podaj dokładną istotę/XML. Dla EW wszyscy powinni mieć tę samą wersję MCM.

[Pobieranie](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) · [Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues) · [↑ Języki](#languages)

---

<a id="zh-cn"></a>

## 简体中文

### 安装

1. [下载可直接安装的 ZIP](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)。
2. 安装或更新前完全关闭 Noita。
3. Steam：**库 → 右键 Noita → 管理 → 浏览本地文件**。
4. 将完整的 **`metamorph_creative_menu`** 文件夹复制到 `Noita/mods/`。
5. 确认 `Noita/mods/metamorph_creative_menu/mod.xml` 存在。
6. 启用 **Metamorph: Creative Menu**；需要时允许 **Unsafe mods / unrestricted API**，然后重启 Noita。
7. 进入游戏并按 **TAB**。

### 操作

- **TAB** — 打开/关闭菜单；变形状态下返回人类形态。
- **G**（默认）— 附身光标下的受支持生物。
- **LMB/RMB** — 根据目录项目执行不同操作；界面会显示具体动作。

### 功能

MCM 可以编辑**法术与法杖**、生成**物品和液体**、添加/移除**Perk 与效果**、生成生物、进行**变形**、附身已有生物、恢复人类形态、执行 **death handoff**、生成 `PLAYER` 盟友、搜索大型目录、控制**天气**，并提供可恢复的 **World Rules**，包括生物关系、金币、法术次数、fog of war、trick kill、治疗掉落、gore、重力、物理阻尼、血量、踢击力度、关节强度和昼夜循环等。

<details><summary><strong>独立模式、恢复与 Entangled Worlds</strong></summary>

单人模式不需要 Entangled Worlds。MCM 内置 NoitaPatcher，用于实体序列化/恢复、player handoff 和其他高级功能，因此完整版本需要 Unsafe/unrestricted API。启用 `quant.ew` 后，会开启针对物品、Perk、天气、World Rules、形态/附身和 companion 的实验性多人同步。所有玩家应使用相同版本的 MCM。

</details>

### 依赖与致谢

- **Noita** — Nolla Games。
- **NoitaPatcher** — dextercd，已内置。
- **lbase64** — Ilya Kolbin，已内置。
- **Entangled Worlds / Noita Proxy** — IntQuant 与贡献者，可选。

上游链接和许可状态见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

### 故障排除

如果 TAB 无响应，请检查 `mod.xml` 路径、确认 MCM 已启用、允许 Unsafe/unrestricted API，并重启 Noita。形态问题请报告准确的生物/XML。EW 问题请确保所有玩家使用同一 MCM 版本。

[下载](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) · [Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues) · [↑ 语言](#languages)

---

<a id="ja"></a>

## 日本語

### インストール

1. [インストール用 ZIP をダウンロード](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)します。
2. インストールまたは更新前に Noita を完全に終了します。
3. Steam：**ライブラリ → Noita を右クリック → 管理 → ローカルファイルを閲覧**。
4. **`metamorph_creative_menu`** フォルダ全体を `Noita/mods/` にコピーします。
5. `Noita/mods/metamorph_creative_menu/mod.xml` が存在することを確認します。
6. **Metamorph: Creative Menu** を有効化し、必要な場合は **Unsafe mods / unrestricted API** を許可して Noita を再起動します。
7. ゲームを開始して **TAB** を押します。

### 操作

- **TAB** — メニューを開閉。変身中は人間形態へ戻ります。
- **G**（デフォルト）— カーソル下の対応クリーチャーを possession します。
- **LMB/RMB** — カタログ項目ごとに異なる操作。正確な動作は UI に表示されます。

### 機能

MCM では**スペルとワンド**の編集、**アイテムと液体**の生成、**Perk とエフェクト**の適用/削除、クリーチャー生成、**変身**、既存クリーチャーの possession、人間形態の復元、**death handoff**、`PLAYER` 味方の生成、カタログ検索、**天候**制御、そしてクリーチャー関係・ゴールド・スペル使用回数・fog of war・trick kill・回復ドロップ・gore・重力・物理・血液量・キック力・ジョイント強度・昼夜サイクルなどの**可逆 World Rules**を利用できます。

<details><summary><strong>Standalone、Recovery、Entangled Worlds</strong></summary>

シングルプレイヤーでは Entangled Worlds は不要です。MCM には NoitaPatcher が同梱され、シリアライズ/復元、player handoff、その他の高度な機能に使われるため、完全版では Unsafe/unrestricted API が必要です。`quant.ew` が有効な場合、アイテム・Perk・天候・World Rules・形態/possession・companion の実験的マルチプレイヤー統合が有効になります。全 peer で同じ MCM バージョンを使用してください。

</details>

### 依存関係とクレジット

- **Noita** — Nolla Games。
- **NoitaPatcher** — dextercd、同梱。
- **lbase64** — Ilya Kolbin、同梱。
- **Entangled Worlds / Noita Proxy** — IntQuant と contributors、任意。

Upstream リンクとライセンス情報：[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

### トラブルシューティング

TAB が反応しない場合は `mod.xml` のパス、MCM の有効化、Unsafe/unrestricted API、Noita の再起動を確認してください。形態の不具合は正確なクリーチャー/XML を報告してください。EW では全 peer の MCM バージョンを揃えてください。

[Download](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) · [Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues) · [↑ 言語](#languages)

---

<a id="ko"></a>

## 한국어

### 설치

1. [바로 설치 가능한 ZIP을 다운로드](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)합니다.
2. 설치 또는 업데이트 전에 Noita를 완전히 종료합니다.
3. Steam: **라이브러리 → Noita 우클릭 → 관리 → 로컬 파일 찾아보기**.
4. **`metamorph_creative_menu`** 폴더 전체를 `Noita/mods/`에 복사합니다.
5. `Noita/mods/metamorph_creative_menu/mod.xml`이 존재하는지 확인합니다.
6. **Metamorph: Creative Menu**를 활성화하고 필요한 경우 **Unsafe mods / unrestricted API**를 허용한 뒤 Noita를 재시작합니다.
7. 게임을 시작하고 **TAB**을 누릅니다.

### 조작

- **TAB** — 메뉴 열기/닫기. 변신 상태에서는 인간 형태로 돌아갑니다.
- **G**(기본값) — 커서 아래의 지원되는 생물을 possession 합니다.
- **LMB/RMB** — 카탈로그 항목에 따라 다른 동작을 수행하며 UI에 정확한 동작이 표시됩니다.

### 기능

MCM은 **주문과 완드** 편집, **아이템과 액체** 생성, **Perk와 효과** 적용/제거, 생물 생성, **변신**, 기존 생물 possession, 인간 형태 복원, **death handoff**, `PLAYER` 동료 생성, 카탈로그 검색, **날씨** 제어 및 생물 관계·골드·주문 사용 횟수·fog of war·trick kill·회복 드롭·gore·중력·물리·혈액량·킥 힘·조인트 강도·낮/밤 주기 등을 다루는 **되돌릴 수 있는 World Rules**를 제공합니다.

<details><summary><strong>Standalone, 복구 및 Entangled Worlds</strong></summary>

싱글플레이에서는 Entangled Worlds가 필요하지 않습니다. MCM에는 직렬화/복구, player handoff 및 기타 고급 기능을 위한 NoitaPatcher가 포함되어 있어 전체 버전은 Unsafe/unrestricted API가 필요합니다. `quant.ew`가 활성화되면 아이템, Perk, 날씨, World Rules, 형태/possession, companion에 대한 실험적 멀티플레이 통합이 활성화됩니다. 모든 peer는 동일한 MCM 버전을 사용해야 합니다.

</details>

### 의존성 및 크레딧

- **Noita** — Nolla Games.
- **NoitaPatcher** — dextercd, 포함됨.
- **lbase64** — Ilya Kolbin, 포함됨.
- **Entangled Worlds / Noita Proxy** — IntQuant 및 contributors, 선택 사항.

Upstream 링크와 라이선스 정보는 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)를 참고하세요.

### 문제 해결

TAB이 작동하지 않으면 `mod.xml` 경로, MCM 활성화, Unsafe/unrestricted API 허용 여부를 확인하고 Noita를 재시작하세요. 형태 문제는 정확한 creature/XML을 보고해 주세요. EW에서는 모든 peer가 동일한 MCM 버전을 사용해야 합니다.

[Download](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) · [Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues) · [↑ 언어](#languages)

---

## For developers

The playable mod lives in `metamorph_creative_menu/`.

- Architecture/developer notes: `metamorph_creative_menu/README.txt`
- Regression suite: `metamorph_creative_menu/tests/`
- Test instructions: `metamorph_creative_menu/tests/TESTING.txt`
- Third-party notices: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)

The repository's automatic `latest-build` workflow packages the playable `metamorph_creative_menu` folder into a ready-to-install ZIP and updates the stable download URL above.
