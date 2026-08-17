# Metamorph: Creative Menu

<a id="languages"></a>

## Choose your language

| Language | Open guide |
|---|---|
| English | [English](#en) |
| Русский | [Русский](#ru) |
| Português (Brasil) | [Português (Brasil)](#pt-br) |
| Español | [Español](#es) |
| Deutsch | [Deutsch](#de) |
| Français | [Français](#fr) |
| Italiano | [Italiano](#it) |
| Polski | [Polski](#pl) |
| 简体中文 | [简体中文](#zh-cn) |
| 日本語 | [日本語](#ja) |
| 한국어 | [한국어](#ko) |

## Download / Скачать

| Build / Сборка | Download / Скачать |
|---|---|
| **Ready-to-install / Готовая версия** | **[⬇️ Download ZIP / Скачать ZIP](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)** |
| Build page / Страница сборки | [Open / Открыть](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) |

> The ZIP already contains the `metamorph_creative_menu` folder. Extract/copy that folder directly into `Noita/mods/`.  
> ZIP уже содержит папку `metamorph_creative_menu`. Распакуйте/скопируйте её прямо в `Noita/mods/`.

> Choose your language above. The first section in every language is **Installation**, with the exact folder path, the required **Unsafe mods** setting, and a final TAB check.

### Folder check before starting Noita

The final installation must contain:

```text
Noita/
└─ mods/
   └─ metamorph_creative_menu/
      ├─ mod.xml
      ├─ init.lua
      ├─ mod_id.txt
      ├─ NoitaPatcher/
      └─ files/
```

If you see `metamorph_creative_menu/metamorph_creative_menu/mod.xml`, the archive was extracted one folder too deep.

---

<a id="en"></a>

## English

### Installation — step by step

1. Open the [Releases page](https://github.com/zerodancing/Metamorph-Creative-Menu/releases). Open the newest release and download the MCM `.zip` file from **Assets**. If a packaged release is not available yet, use **Code → Download ZIP** and find the `metamorph_creative_menu` folder inside the downloaded archive.
2. **Close Noita completely** before installing or updating the mod.
3. Find your Noita installation folder. On Steam: **Library → right-click Noita → Manage → Browse local files**. If you use another installation, open the folder that contains the Noita executable.
4. Open the `mods` folder inside the Noita folder. If `mods` does not exist, create it.
5. Extract the download. Copy the whole folder named **`metamorph_creative_menu`** into `Noita/mods/`. Do not rename that folder.
6. Check the final path. This file must exist directly here:

   `Noita/mods/metamorph_creative_menu/mod.xml`

   Correct: `Noita/mods/metamorph_creative_menu/mod.xml`  
   Wrong: `Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Start Noita and open **Mods**. Enable **Unsafe mods / unrestricted API**. MCM bundles NoitaPatcher, and the full recovery, entity-serialization, player-authority and MagicNumbers functionality needs this permission.
8. Enable **Metamorph: Creative Menu**. If Noita offers **Restart with enabled mods active**, use it; otherwise restart the game after enabling the mod.
9. Start or continue a run and press **TAB**. If the Creative Menu opens, installation is complete. While transformed, TAB is also the normal return-to-human control. The default possession key is **G** and can be changed in the mod settings.
10. If TAB does nothing, check these three things first: the `mod.xml` path from step 6, **Unsafe mods** is enabled, and Noita was restarted after enabling MCM.

**Updating MCM:** close Noita, remove the old `metamorph_creative_menu` folder, then copy the new folder into `mods`. Replacing the whole folder avoids stale files from older versions.

**Entangled Worlds is optional.** Single-player MCM does not require it. For multiplayer, use the same MCM version on every peer and enable the compatible Entangled Worlds setup separately.

### Requirements

- A working copy of Noita.
- The folder `metamorph_creative_menu` installed under `Noita/mods/`.
- **Unsafe mods / unrestricted API enabled** in Noita. This is required by the bundled native **NoitaPatcher** extension used by MCM's extended functionality.
- Entangled Worlds is **optional**. It is not required for normal single-player use.

### About

**Metamorph: Creative Menu (MCM)** is a creative/developer menu for **Noita**. It is designed to work as a complete standalone single-player mod while also providing optional experimental compatibility with **Entangled Worlds / Noita Proxy**.

MCM lets you edit wands, spawn or take items, apply and remove perks/effects, transform into creatures, possess an existing creature under the cursor, change weather, override world rules and spawn a player-like companion. The project also contains extensive recovery, ownership and regression-test systems because many Noita operations are destructive or engine-dependent.

### Controls

- **TAB** — open/close the Creative Menu.
- **TAB while transformed** — request a return to the normal human player form.
- **G** by default — possess/transform into a supported creature under the cursor. The key can be rebound in MCM settings.
- Most catalog tiles use **LMB** and **RMB** for two different actions; the exact action is shown in the UI.

### Features

#### Spells / wand editing

Hold a wand, select a wand slot and choose any supported spell from the searchable categorized catalog. MCM can replace the selected spell, delete it, or drop the spell entity into the world. Replacement is handled transactionally so the old spell is not removed until the new spell has been attached and verified.

#### Items

The Items tab provides searchable categories for containers, liquids, stones, eggs, wands, books, bonuses, orbs, quest items and other supported entities.

- **LMB:** spawn the item near the player.
- **RMB:** try to place the item directly into a suitable inventory slot.
- If inventory pickup fails or the correct slot is full, MCM keeps the item in the world instead of silently destroying or replacing another item.
- Liquid/container entries can create filled flasks and related containers.

#### Perks

- **ADD mode:** LMB spawns a normal perk pickup; RMB applies it directly.
- **REMOVE mode:** LMB removes one stack; RMB attempts to remove all stacks.
- MCM tracks many changes made by perks so removal can restore owned components, entities, values and global state without intentionally overwriting unrelated changes from other systems.
- Some externally obtained or unusual perks may not have a perfectly safe inverse. In that case MCM prefers refusing an unsafe removal over blindly deleting unrelated state.

#### Search

Large catalogs include search. Search may match translated names, IDs and descriptions, depending on the tab.

#### Creatures, objects and forms

The MOBS catalog includes creatures and supported object/projectile-style entries.

- **LMB:** spawn the selected entry in the world.
- **RMB:** transform the player into it.
- **TAB:** return to the human form.

MCM uses exact-path compatibility data rather than broad filename blacklists. Some crash-prone placement-wrapper XMLs are routed to a known safe canonical target for transformation while still spawning the authored wrapper normally.

Player-controlled forms try to preserve useful native movement, attacks, presentation and physics while disabling AI that would fight the player's controls. Complex creatures may use specialized adapters and therefore can be approximate rather than frame-perfect copies of their original AI behavior.

#### Human return and form death

A normal TAB return first uses Noita's native polymorph lifecycle. MCM also keeps a serialized human backup through NoitaPatcher for hard recovery paths.

When a supported transformed body receives fatal damage, MCM attempts a **death handoff**: the current creature form is allowed to die while player authority is transferred back to the restored human body, preventing the creature body's death from automatically ending the player's run.

Because this touches engine death/polymorph order, unusual scripted deaths can still be creature-specific edge cases; report reproducible failures.

#### Possession

Aim at a supported existing creature and press the configured possession key (**G** by default). MCM transforms the player using the target's authored/compatible form and retires the original target so the action behaves like taking over that creature rather than merely creating a duplicate next to it.

#### PLAYER companion

The `PLAYER` entry can spawn a player-like allied companion. MCM can clone player presentation/inventory information and, when the required NoitaPatcher capability is available, can use the copied wand more like an actual player. Multiplayer authority is routed through the EW integration when EW is active.

#### Effects

Apply supported status/timed effects to the current player, choose duration where supported, and remove effects through the editor. MCM tries to distinguish editor-owned state from unrelated perk/internal effects so a bulk removal does not intentionally destroy protected game state.

#### Weather

Weather provides presets and advanced editing.

Time presets:
- morning
- day
- evening
- night

Weather presets:
- clear
- cloudy
- foggy
- storm

Advanced controls include supported WorldState values such as time of day, cloud cover, fog, wind, wind speed, rain and lightning-related behavior. **RELEASE** stops MCM from actively holding its weather override.

#### World Rules

World Rules are designed as **reversible overrides**, not permanent edits. `NATIVE`/RESET restores the baseline that MCM captured for values it owns. Persistent recovery records are used for critical rules so an interrupted session can restore recorded native values before accepting new overrides.

Current rule set:

- CREATURE RELATIONS
- GOLD NEVER EXPIRES
- UNLIMITED SPELL USES
- REVEAL FOG OF WAR
- TRICK-KILL BLOOD MONEY
- HEALING DROP CHANCE
- FRIENDLY RATS
- GORE AMOUNT
- TRICK-KILL GOLD
- DAMAGE FLASH
- STAIN SHEDDING
- WORLD GRAVITY
- PHYSICS DAMPING
- BLOOD VOLUME
- KICK FORCE
- JOINT STRENGTH
- DAY CYCLE SPEED

Physics rules affect loaded/nearby runtime physics rather than magically rewriting every unloaded entity in the infinite world. Heavy scans are deferred to world update rather than performed directly inside GUI clicks.

### Standalone mode and Entangled Worlds

**MCM does not require Entangled Worlds for single player.** The repository contains its own NoitaPatcher loader/DLL and local Base64 codec.

When `quant.ew` is enabled, MCM activates an experimental integration layer for shared world items, perks, weather, World Rules, forms/possession, companion requests and compatibility/resilience behavior. If EW already provides a compatible NoitaPatcher API, MCM can reuse it.

Network support is intentionally described as **experimental/partial**: host and client are intended to have equal user-facing Creative Menu rights, but not every Noita/EW edge case can be guaranteed synchronized.

For multiplayer, all peers should use the same MCM build and a compatible EW build.

### Compatibility and safety

- Some Noita entities can crash native polymorph at engine level; Lua `pcall` cannot catch a hard native crash.
- MCM therefore uses exact XML-path compatibility policy, static structure checks, native polymorph signals, logged review results and a small number of narrow safe-routing exceptions.
- Do not interpret every catalog entry as guaranteed perfect player control. Exotic bosses, physics-driven objects and scripted entities can need dedicated adapters.
- Release mode has `dev_mode = 0`; tests and QA tools are kept in the repository for development and regression checking.

### Troubleshooting

**Menu does not open:** verify the folder is exactly `Noita/mods/metamorph_creative_menu/` and the mod is enabled.

**Extended form recovery / World Rules capabilities are missing:** verify Unsafe mods / unrestricted API is enabled and the bundled `NoitaPatcher/noitapatcher.dll` is present.

**A transformed form does not return correctly:** include the exact creature XML/name and describe whether TAB return or fatal-death return failed.

**EW mismatch/desync:** confirm every peer uses the same MCM version and a compatible Entangled Worlds version.

### Bug reports

Please use [GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues). Include:
- MCM version/commit;
- Noita version/build;
- whether Entangled Worlds was enabled and its version;
- single-player or multiplayer;
- exact entity/perk/effect/rule involved;
- reproducible steps;
- relevant logs/diagnostics if available.

### Third-party components and credits

MCM bundles **NoitaPatcher** by dextercd and **lbase64** by Ilya Kolbin. It optionally integrates with **Noita Entangled Worlds** by IntQuant and contributors. Exact bundled paths, purposes, upstream links and license/status information are documented in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Links

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

### Developers

The playable mod is in `metamorph_creative_menu/`. Automated regression mocks, architecture contracts and behavior-coverage checks are in `metamorph_creative_menu/tests/`; see `metamorph_creative_menu/tests/TESTING.txt`.

No top-level license for MCM's original code has been selected yet. Third-party components retain their own terms.

[↑ Back to language selection](#languages)

---

<a id="ru"></a>

## Русский

### Установка — по шагам

1. Откройте [страницу Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases). Откройте самый новый релиз и в разделе **Assets** скачайте `.zip` с MCM. Если готового релиза пока нет, используйте **Code → Download ZIP** и найдите внутри архива папку `metamorph_creative_menu`.
2. **Полностью закройте Noita** перед первой установкой или обновлением мода.
3. Найдите папку игры. В Steam: **Библиотека → ПКМ по Noita → Управление → Просмотреть локальные файлы**. Для другой установки просто откройте папку, в которой находится исполняемый файл Noita.
4. В папке Noita откройте папку `mods`. Если её нет — создайте её.
5. Распакуйте скачанный архив. Скопируйте целиком папку **`metamorph_creative_menu`** в `Noita/mods/`. Не переименовывайте эту папку.
6. Обязательно проверьте итоговый путь. Файл должен находиться прямо здесь:

   `Noita/mods/metamorph_creative_menu/mod.xml`

   Правильно: `Noita/mods/metamorph_creative_menu/mod.xml`  
   Неправильно: `Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Запустите Noita и откройте **Mods / Моды**. Включите **Unsafe mods / unrestricted API**. MCM поставляется со своей копией NoitaPatcher, и полный набор функций восстановления, сериализации сущностей, переключения игрока и MagicNumbers требует этого разрешения.
8. Включите **Metamorph: Creative Menu**. Если Noita показывает кнопку **Restart with enabled mods active**, нажмите её; иначе перезапустите игру после включения мода.
9. Начните или продолжите забег и нажмите **TAB**. Если открылось Creative Menu — установка завершена. Во время превращения TAB также используется для обычного возврата в человеческое тело. Клавиша possession по умолчанию — **G**, её можно изменить в настройках мода.
10. Если TAB ничего не делает, сначала проверьте три вещи: путь к `mod.xml` из шага 6, включён ли **Unsafe mods**, и перезапускалась ли Noita после включения MCM.

**Обновление MCM:** закройте Noita, удалите старую папку `metamorph_creative_menu`, затем скопируйте новую папку в `mods`. Полная замена папки не оставляет старые файлы от предыдущих версий.

**Entangled Worlds не обязателен.** Для одиночной игры MCM работает без него. Для сетевой игры используйте одинаковую версию MCM у всех участников и отдельно установите совместимую версию Entangled Worlds.

### Требования

- Установленная Noita.
- Папка `metamorph_creative_menu` внутри `Noita/mods/`.
- В Noita должна быть включена опция **Unsafe mods / unrestricted API**. Она нужна встроенному native-расширению **NoitaPatcher**, которое обеспечивает расширенные возможности MCM.
- Entangled Worlds **не обязателен** для обычной одиночной игры.

### О моде

**Metamorph: Creative Menu (MCM)** — creative/developer-меню для **Noita**. Мод рассчитан на полноценную самостоятельную работу в одиночной игре и при этом содержит опциональную экспериментальную совместимость с **Entangled Worlds / Noita Proxy**.

MCM позволяет редактировать посохи, создавать и получать предметы, применять и удалять перки и эффекты, превращаться в существ, занимать тело уже существующего моба под курсором, менять погоду и правила мира, а также создавать союзника в виде игрока. В проекте много механизмов восстановления, ownership и регрессионных тестов, потому что ряд операций Noita разрушительны или зависят от внутренних особенностей движка.

### Управление

- **TAB** — открыть/закрыть Creative Menu.
- **TAB во время превращения** — вернуть обычное человеческое тело.
- **G** по умолчанию — занять тело/превратиться в поддерживаемого моба под курсором. Клавишу можно поменять в настройках MCM.
- У большинства плиток каталога **ЛКМ** и **ПКМ** выполняют разные действия; точная подсказка показывается в интерфейсе.

### Возможности

#### Заклинания и редактирование посоха

Возьмите посох в руку, выберите слот и выберите любое поддерживаемое заклинание из категорий или через поиск. MCM умеет заменить заклинание в выбранном слоте, удалить его или выбросить в мир. Замена выполняется транзакционно: старое заклинание не удаляется, пока новое не присоединено к посоху и не проверено.

#### Предметы

Вкладка Items содержит категории контейнеров, жидкостей, камней, яиц, посохов, книг, бонусов, сфер, квестовых и других поддерживаемых предметов.

- **ЛКМ:** создать предмет рядом с игроком.
- **ПКМ:** попытаться сразу положить его в подходящий слот инвентаря.
- Если подходящий слот занят или pickup не удался, MCM оставляет предмет в мире вместо того, чтобы молча уничтожить его или заменить другой предмет.
- Для жидкостей и контейнеров доступны заполненные фляги и связанные варианты.

#### Перки

- Режим **ADD:** ЛКМ создаёт обычный объект перка; ПКМ применяет перк напрямую.
- Режим **REMOVE:** ЛКМ снимает один уровень; ПКМ пытается снять все уровни.
- MCM отслеживает многие изменения, созданные перками, чтобы при удалении восстановить принадлежащие перку компоненты, сущности, значения и глобальное состояние, не перетирая намеренно изменения других систем.
- Для некоторых внешних или необычных перков идеального безопасного inverse может не быть. В таком случае MCM предпочитает отказаться от опасного удаления, а не удалить чужие компоненты наугад.

#### Поиск

В крупных каталогах есть поиск по переведённому имени, ID и/или описанию в зависимости от вкладки.

#### Мобы, объекты и формы

Каталог MOBS содержит существ, а также поддерживаемые объектные/снарядные формы.

- **ЛКМ:** создать выбранную сущность в мире.
- **ПКМ:** превратить в неё игрока.
- **TAB:** вернуться в человеческую форму.

Совместимость хранится по точному XML-пути, а не по широким blacklist-фрагментам имени. Для нескольких известных crash-prone placement-wrapper XML transform узко перенаправляется на безопасную canonical base-сущность, при этом обычный spawn всё равно создаёт исходный authored wrapper.

Управляемая игроком форма старается сохранить полезные нативные атаки, движение, внешний вид и физику, отключая AI, который конфликтовал бы с управлением игрока. Сложные существа могут использовать специальные адаптеры, поэтому их поведение иногда является приближением, а не точной копией оригинального AI.

#### Возврат человека и смерть формы

Обычный возврат по TAB сначала использует нативный lifecycle polymorph Noita. Дополнительно MCM сохраняет сериализованный backup человека через NoitaPatcher для жёсткого аварийного восстановления.

При смертельном уроне поддерживаемой форме MCM пытается выполнить **death handoff**: текущее тело моба умирает, а player authority передаётся восстановленному человеческому телу. Таким образом смерть формы не должна автоматически завершать весь забег игрока.

Поскольку этот механизм зависит от порядка внутренних death/polymorph callback Noita, необычные scripted-death сущности всё ещё могут иметь отдельные edge cases — их лучше сообщать с точным названием/XML.

#### Possession — захват моба под курсором

Наведите курсор на поддерживаемого моба и нажмите настроенную клавишу (**G** по умолчанию). MCM превращает игрока в совместимую форму этой сущности и выводит исходную цель из мира, чтобы действие было похоже именно на занятие её тела, а не на создание дубликата рядом.

#### Союзник PLAYER

Пункт `PLAYER` может создавать союзника, похожего на игрока. MCM копирует нужное визуальное/инвентарное состояние и при доступной возможности NoitaPatcher может использовать скопированный посох ближе к настоящему поведению игрока. В EW сетевой authority проходит через интеграционный слой.

#### Эффекты

Можно применять поддерживаемые status/timed effects к текущему игроку, выбирать длительность там, где она поддерживается, и удалять эффекты редактором. MCM старается отличать собственное состояние редактора от защищённых внутренних/perk-эффектов.

#### Погода

Есть быстрые пресеты и расширенная настройка.

Время:
- утро;
- день;
- вечер;
- ночь.

Погода:
- ясно;
- облачно;
- туман;
- шторм.

Advanced-режим позволяет менять поддерживаемые значения времени суток, облачности, тумана, ветра, скорости ветра, дождя и молний. **RELEASE** прекращает активное удержание погодного override со стороны MCM.

#### Правила мира

World Rules — это **обратимые overrides**, а не безвозвратное редактирование сейва. `NATIVE`/RESET возвращает baseline, который MCM зафиксировал для принадлежащих ему значений. Для критичных правил сохраняется recovery-состояние, чтобы после прерванной сессии сначала вернуть записанный native baseline.

Текущий набор правил:

- ОТНОШЕНИЯ СУЩЕСТВ
- ЗОЛОТО НЕ ИСЧЕЗАЕТ
- БЕСКОНЕЧНЫЕ ЗАРЯДЫ
- ОТКРЫТЬ ТУМАН ВОЙНЫ
- КРОВАВЫЕ ДЕНЬГИ ЗА ТРЮКИ
- ЛЕЧАЩИЕ ДРОПЫ
- ДРУЖЕЛЮБНЫЕ КРЫСЫ
- КОЛИЧЕСТВО КРОВИ
- ЗОЛОТО ЗА ТРЮКИ
- ВСПЫШКА УРОНА
- СБРАСЫВАНИЕ ПЯТЕН
- ГРАВИТАЦИЯ МИРА
- ФИЗИЧЕСКОЕ ЗАТУХАНИЕ
- ОБЪЁМ КРОВИ
- СИЛА ПИНКА
- ПРОЧНОСТЬ СОЕДИНЕНИЙ
- СКОРОСТЬ СУТОК

Правила физики применяются к загруженным/близким runtime-объектам и не пытаются мгновенно переписать абсолютно все выгруженные сущности бесконечного мира. Тяжёлые сканирования выполняются в world update, а не непосредственно при клике GUI.

### Одиночная игра и Entangled Worlds

**Для одиночной игры Entangled Worlds не нужен.** В репозитории лежат собственная копия NoitaPatcher и локальный Base64-кодек.

Если включён `quant.ew`, MCM активирует экспериментальный слой совместимости для общих предметов, перков, погоды, World Rules, форм/possession, companion-запросов и специальных compatibility patches. Если EW уже опубликовал совместимый API NoitaPatcher, MCM может переиспользовать его.

Сетевая поддержка намеренно помечена как **частичная/экспериментальная**: по пользовательскому контракту хост и клиент должны иметь одинаковые права MCM, но невозможно гарантировать идеальную синхронизацию всех крайних случаев Noita/EW.

В сетевой игре всем участникам желательно использовать одну и ту же сборку MCM и совместимую версию EW.

### Совместимость и безопасность

- Некоторые сущности Noita способны вызвать native crash при polymorph; такой crash нельзя поймать Lua `pcall`.
- Поэтому MCM использует exact-path policy, статический анализ XML, сигналы native polymorph, review/log и узкие исключения safe-routing.
- Не каждая сущность каталога гарантирует абсолютно идеальное управление. Необычные боссы, physics-объекты и scripted entities могут требовать отдельных адаптеров.
- В release-режиме `dev_mode = 0`; тесты и QA-файлы остаются в репозитории для разработки.

### Если что-то не работает

**TAB не открывает меню:** проверьте точный путь `Noita/mods/metamorph_creative_menu/` и что мод включён.

**Нет жёсткого возврата формы или части World Rules:** проверьте, что включены Unsafe mods / unrestricted API и существует `NoitaPatcher/noitapatcher.dll`.

**Конкретная форма не возвращает человека:** укажите точную сущность/XML и отдельно напишите, сломался обычный TAB или возврат после смерти формы.

**Проблемы в EW:** у всех игроков должны совпадать версии MCM; также укажите версию Entangled Worlds.

### Отчёты об ошибках

Используйте [GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues). Желательно приложить:
- версию/commit MCM;
- версию Noita;
- включён ли Entangled Worlds и его версию;
- одиночную или сетевую игру;
- точный моб/перк/эффект/правило;
- пошаговое воспроизведение;
- логи/diagnostics, если они есть.

### Сторонние компоненты и благодарности

MCM включает **NoitaPatcher** от dextercd и **lbase64** от Ilya Kolbin. Опционально мод интегрируется с **Noita Entangled Worlds** от IntQuant и contributors. Точные пути файлов, назначение, ссылки и информация о лицензиях/статусе находятся в [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Ссылки

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

### Для разработчиков

Играбельный мод находится в `metamorph_creative_menu/`. Regression mocks, architecture contracts и проверки покрытия поведения лежат в `metamorph_creative_menu/tests/`; см. `metamorph_creative_menu/tests/TESTING.txt`.

Общая лицензия на оригинальный код MCM пока не выбрана. Сторонние компоненты сохраняют свои исходные условия.

[↑ Back to language selection](#languages)

---

<a id="pt-br"></a>

## Português (Brasil)

### Instalação — passo a passo

1. Abra a [página de Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases). Abra a versão mais recente e baixe o `.zip` do MCM em **Assets**. Se ainda não houver um pacote de release, use **Code → Download ZIP** e localize a pasta `metamorph_creative_menu` dentro do arquivo baixado.
2. **Feche completamente o Noita** antes de instalar ou atualizar o mod.
3. Localize a pasta de instalação do Noita. No Steam: **Biblioteca → clique com o botão direito em Noita → Gerenciar → Explorar arquivos locais**. Em outra instalação, abra a pasta que contém o executável do Noita.
4. Abra a pasta `mods` dentro da pasta do Noita. Se ela não existir, crie-a.
5. Extraia o download. Copie a pasta inteira **`metamorph_creative_menu`** para `Noita/mods/`. Não renomeie essa pasta.
6. Confira o caminho final. Este arquivo precisa existir exatamente aqui:

   `Noita/mods/metamorph_creative_menu/mod.xml`

   Correto: `Noita/mods/metamorph_creative_menu/mod.xml`  
   Errado: `Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Inicie o Noita e abra **Mods**. Ative **Unsafe mods / unrestricted API**. O MCM inclui o NoitaPatcher e os recursos completos de recuperação, serialização de entidades, autoridade do jogador e MagicNumbers precisam dessa permissão.
8. Ative **Metamorph: Creative Menu**. Se o Noita mostrar **Restart with enabled mods active**, use essa opção; caso contrário, reinicie o jogo depois de ativar o mod.
9. Inicie ou continue uma partida e pressione **TAB**. Se o Creative Menu abrir, a instalação terminou. Enquanto transformado, TAB também é o comando normal para voltar à forma humana. A tecla padrão de possessão é **G** e pode ser alterada nas configurações do mod.
10. Se TAB não fizer nada, confira primeiro: o caminho do `mod.xml` no passo 6, se **Unsafe mods** está ativado e se o Noita foi reiniciado depois de ativar o MCM.

**Para atualizar:** feche o Noita, remova a pasta antiga `metamorph_creative_menu` e copie a nova pasta para `mods`. Substituir a pasta inteira evita arquivos antigos sobrando.

**Entangled Worlds é opcional.** O MCM funciona sozinho no modo single-player. Para multiplayer, use a mesma versão do MCM em todos os jogadores e configure separadamente uma versão compatível do Entangled Worlds.

### Requisitos e instalação

- Noita instalado.
- A pasta `metamorph_creative_menu` dentro de `Noita/mods/`.
- Ative **Unsafe mods / unrestricted API** no menu de mods. O NoitaPatcher incluído precisa dessa permissão.
- Entangled Worlds é **opcional**.

Instalação:
1. Baixe uma versão em [Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases) ou baixe/clone o repositório.
2. Copie `metamorph_creative_menu` para `Noita/mods/`.
3. Confirme que existe `Noita/mods/metamorph_creative_menu/mod.xml`.
4. Ative Unsafe mods e depois Metamorph: Creative Menu.

Não renomeie a pasta interna do mod.

### Sobre o mod

**Metamorph: Creative Menu (MCM)** é um menu criativo/de desenvolvimento para **Noita**. Ele foi feito para funcionar de forma independente no modo solo e também oferece compatibilidade experimental opcional com **Entangled Worlds / Noita Proxy**.

O MCM permite editar varinhas, gerar ou receber itens, aplicar e remover vantagens e efeitos, transformar-se em criaturas, possuir uma criatura existente sob o cursor, controlar clima e regras do mundo e gerar um companheiro semelhante ao jogador.

### Recursos

#### Feitiços
Com uma varinha na mão, selecione um slot e escolha um feitiço no catálogo pesquisável. É possível substituir, excluir ou soltar feitiços. A substituição só remove o feitiço antigo depois que o novo foi anexado e verificado.

#### Itens
Categorias incluem recipientes, líquidos, pedras, ovos, varinhas, livros, bônus, orbes, itens de missão e outros.
- **LMB:** gera perto do jogador.
- **RMB:** tenta colocar diretamente no inventário.
- Se o inventário estiver cheio ou o pickup falhar, o item permanece no mundo.
- Há frascos e recipientes preenchidos com líquidos compatíveis.

#### Vantagens
- **ADD:** LMB gera o pickup; RMB aplica diretamente.
- **REMOVE:** LMB remove uma unidade; RMB tenta remover todas.
O MCM registra muitas alterações de vantagens para reverter entidades, componentes e valores pertencentes à vantagem sem sobrescrever deliberadamente alterações de outros sistemas. Quando não há inversão segura, o mod prefere recusar uma remoção perigosa.

#### Busca
Catálogos grandes possuem busca por nome traduzido, ID e/ou descrição.

#### Criaturas, objetos e formas
- **LMB:** gera a entidade.
- **RMB:** transforma o jogador.
- **TAB:** volta ao humano.

A segurança de transformação é armazenada por caminho XML exato. Alguns wrappers conhecidos por serem perigosos usam um alvo canônico seguro somente para transformação. Formas controladas pelo jogador preservam, quando possível, ataques, movimento, aparência e física úteis, enquanto desativam IA conflitante. Criaturas muito complexas podem usar adaptadores aproximados.

#### Retorno humano e morte da forma
O retorno normal por TAB usa primeiro o ciclo nativo de polymorph de Noita. O MCM também mantém um backup serializado do humano por meio do NoitaPatcher.

Em dano fatal, o MCM tenta fazer **death handoff**: a forma atual morre, mas a autoridade do jogador é transferida de volta para o humano restaurado, evitando que a morte do corpo transformado termine automaticamente a partida.

#### Possessão
Aponte para uma criatura compatível e pressione **G** (padrão). O MCM usa a forma compatível do alvo e retira o alvo original do mundo para evitar uma simples duplicação.

#### Companheiro PLAYER
A entrada `PLAYER` pode criar um aliado semelhante ao jogador. Quando as capacidades necessárias do NoitaPatcher estão disponíveis, o companheiro pode usar a varinha copiada de forma mais próxima do jogador real.

#### Efeitos
Aplique efeitos de status/temporários, escolha duração quando suportada e remova efeitos pelo editor, preservando quando possível efeitos internos/perks que não pertencem ao editor.

#### Clima
Predefinições de horário: manhã, dia, tarde/noite inicial e noite. Predefinições de clima: limpo, nublado, neblina e tempestade. O modo avançado controla valores suportados de horário, nuvens, neblina, vento, velocidade do vento, chuva e relâmpagos. **RELEASE** para de manter o override ativo.

#### Regras do mundo
As regras são **overrides reversíveis**. `NATIVE`/RESET restaura o baseline que o MCM capturou para os valores que controla. Há recuperação persistente para regras críticas.

Regras atuais:

- RELAÇÕES DAS CRIATURAS
- OURO NÃO DESAPARECE
- USOS ILIMITADOS
- REVELAR MAPA
- DINHEIRO DE SANGUE POR TRUQUES
- CHANCE DE CURA
- RATOS AMIGÁVEIS
- QUANTIDADE DE SANGUE
- OURO POR TRUQUES
- FLASH DE DANO
- PERDA DE MANCHAS
- GRAVIDADE DO MUNDO
- AMORTECIMENTO FÍSICO
- VOLUME DE SANGUE
- FORÇA DO CHUTE
- FORÇA DAS JUNTAS
- VELOCIDADE DO DIA

Regras de física atuam sobre corpos/entidades carregados ou próximos, não sobre todas as entidades descarregadas do mundo infinito de uma só vez.

### Solo e Entangled Worlds

**Entangled Worlds não é necessário para jogar solo.** O MCM inclui sua própria cópia do NoitaPatcher e codec Base64 local.

Com `quant.ew` ativo, o MCM habilita integração experimental para itens do mundo, perks, clima, regras, formas/possessão, companions e patches de compatibilidade. Se o EW já publicou uma API NoitaPatcher compatível, o MCM pode reutilizá-la.

A compatibilidade multiplayer é **experimental/parcial**. Host e cliente devem ter os mesmos direitos de uso do menu, mas nem todo caso extremo de Noita/EW pode ser garantido. Todos os peers devem usar a mesma versão do MCM.

### Solução de problemas

- Menu não abre: confira `Noita/mods/metamorph_creative_menu/` e se o mod está habilitado.
- Recursos avançados ausentes: ative Unsafe mods e confira `NoitaPatcher/noitapatcher.dll`.
- Problema em uma forma: informe o XML/nome exato e se falhou TAB ou retorno após morte.
- EW: informe versões de MCM e Entangled Worlds.

Relate bugs em [GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues) com versão, passos e logs quando disponíveis.

### Dependências e créditos

O MCM inclui **NoitaPatcher** (dextercd) e **lbase64** (Ilya Kolbin) e integra opcionalmente com **Noita Entangled Worlds** (IntQuant e contribuidores). Detalhes completos: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Links

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

### Desenvolvimento

O mod jogável está em `metamorph_creative_menu/`; testes e contratos ficam em `metamorph_creative_menu/tests/`. Ainda não foi escolhida uma licença geral para o código original do MCM; componentes de terceiros mantêm seus próprios termos.

[↑ Back to language selection](#languages)

---

<a id="es"></a>

## Español

### Instalación — paso a paso

1. Abre la [página de Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases). Abre la versión más reciente y descarga el `.zip` de MCM desde **Assets**. Si todavía no hay un paquete de release, usa **Code → Download ZIP** y busca la carpeta `metamorph_creative_menu` dentro del archivo descargado.
2. **Cierra Noita por completo** antes de instalar o actualizar el mod.
3. Localiza la carpeta de instalación de Noita. En Steam: **Biblioteca → clic derecho en Noita → Administrar → Ver archivos locales**. En otra instalación, abre la carpeta que contiene el ejecutable de Noita.
4. Abre la carpeta `mods` dentro de Noita. Si no existe, créala.
5. Extrae la descarga. Copia la carpeta completa **`metamorph_creative_menu`** a `Noita/mods/`. No cambies el nombre de esa carpeta.
6. Comprueba la ruta final. Este archivo debe existir exactamente aquí:

   `Noita/mods/metamorph_creative_menu/mod.xml`

   Correcto: `Noita/mods/metamorph_creative_menu/mod.xml`  
   Incorrecto: `Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Inicia Noita y abre **Mods**. Activa **Unsafe mods / unrestricted API**. MCM incluye NoitaPatcher y las funciones completas de recuperación, serialización de entidades, autoridad del jugador y MagicNumbers necesitan este permiso.
8. Activa **Metamorph: Creative Menu**. Si Noita muestra **Restart with enabled mods active**, úsalo; si no, reinicia el juego después de activar el mod.
9. Inicia o continúa una partida y pulsa **TAB**. Si se abre Creative Menu, la instalación está terminada. Mientras estás transformado, TAB también sirve para volver normalmente a la forma humana. La tecla de posesión predeterminada es **G** y puede cambiarse en los ajustes del mod.
10. Si TAB no hace nada, revisa primero estas tres cosas: la ruta de `mod.xml` del paso 6, que **Unsafe mods** esté activado y que Noita se haya reiniciado después de activar MCM.

**Para actualizar MCM:** cierra Noita, elimina la carpeta antigua `metamorph_creative_menu` y copia la nueva carpeta en `mods`. Reemplazar la carpeta completa evita archivos obsoletos.

**Entangled Worlds es opcional.** MCM funciona solo en un jugador. Para multijugador, usa la misma versión de MCM en todos los jugadores e instala por separado una versión compatible de Entangled Worlds.

### Requisitos e instalación

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

### Acerca del mod

**Metamorph: Creative Menu (MCM)** es un menú creativo/de desarrollo para **Noita**. Funciona de forma independiente en un jugador y añade compatibilidad experimental opcional con **Entangled Worlds / Noita Proxy**.

Permite editar varitas, generar o recibir objetos, aplicar y retirar ventajas y efectos, transformarse en criaturas, poseer una criatura existente bajo el cursor, modificar el clima y las reglas del mundo y crear un compañero parecido al jugador.

### Funciones

#### Hechizos
Con una varita equipada, selecciona una ranura y un hechizo del catálogo con categorías y búsqueda. Puedes sustituir, borrar o soltar hechizos. La sustitución verifica el hechizo nuevo antes de eliminar el anterior.

#### Objetos
Incluye recipientes, líquidos, piedras, huevos, varitas, libros, bonificaciones, orbes, objetos de misión y más.
- **LMB:** generar cerca.
- **RMB:** intentar colocar directamente en el inventario.
- Si no hay espacio o falla el pickup, el objeto queda en el mundo.
- Incluye frascos/recipientes llenos compatibles.

#### Ventajas
- **ADD:** LMB genera el pickup; RMB aplica directamente.
- **REMOVE:** LMB quita una acumulación; RMB intenta quitar todas.
MCM registra muchas modificaciones de perks para restaurar entidades, componentes y valores propios sin sobrescribir intencionadamente cambios externos. Si no existe una inversa segura, prefiere rechazar una eliminación peligrosa.

#### Búsqueda
Los catálogos grandes permiten buscar por nombre traducido, ID y/o descripción.

#### Criaturas, objetos y formas
- **LMB:** generar.
- **RMB:** transformar.
- **TAB:** volver a humano.

La compatibilidad se registra por ruta XML exacta. Algunos wrappers peligrosos conocidos usan un objetivo canónico seguro únicamente para transformar. Las formas intentan conservar ataques, movimiento, presentación y física útiles mientras desactivan IA que competiría con el jugador. Entidades complejas pueden ser aproximadas.

#### Retorno humano y muerte de la forma
TAB usa primero el ciclo nativo de polymorph. MCM mantiene además un backup humano serializado con NoitaPatcher.

Ante daño mortal, **death handoff** intenta dejar morir el cuerpo de criatura y transferir la autoridad del jugador al humano restaurado para que la muerte de la forma no termine automáticamente la partida.

#### Posesión
Apunta a una criatura compatible y pulsa **G** (predeterminado). MCM adopta una forma compatible con esa criatura y retira el objetivo original para evitar crear simplemente un duplicado.

#### Compañero PLAYER
La entrada `PLAYER` crea un aliado similar al jugador. Con las capacidades necesarias de NoitaPatcher puede usar la varita copiada de manera más cercana a un jugador real.

#### Efectos
Aplica efectos de estado/temporales, elige duración cuando sea compatible y elimina efectos intentando conservar estados internos/perks ajenos al editor.

#### Clima
Presets de hora: mañana, día, tarde y noche. Presets: despejado, nublado, niebla y tormenta. El modo avanzado controla hora, nubes, niebla, viento, velocidad del viento, lluvia y rayos compatibles. **RELEASE** deja de mantener el override.

#### Reglas del mundo
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

### Un jugador y Entangled Worlds

**Entangled Worlds no es necesario para un jugador.** MCM incluye NoitaPatcher y un códec Base64 propio.

Con `quant.ew` activo se habilita integración experimental para objetos, perks, clima, reglas, formas/posesión, compañeros y parches de compatibilidad. Si EW ya publica una API NoitaPatcher compatible, MCM puede reutilizarla.

La compatibilidad de red es **experimental/parcial**. Host y cliente deben tener los mismos derechos de usuario en el menú, pero no se garantiza cada caso extremo de Noita/EW. Todos los jugadores deberían usar la misma versión de MCM.

### Problemas y reportes

- Si no abre el menú, verifica la carpeta y que el mod esté activado.
- Si faltan funciones avanzadas, activa Unsafe mods y comprueba `NoitaPatcher/noitapatcher.dll`.
- Para una forma rota, indica el nombre/XML exacto y si falló TAB o el retorno tras muerte.
- Para EW, indica versiones de ambos mods.

Informa errores en [GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues) con versión, pasos y logs.

### Dependencias y créditos

MCM incluye **NoitaPatcher** (dextercd) y **lbase64** (Ilya Kolbin), e integra opcionalmente **Noita Entangled Worlds** (IntQuant y colaboradores). Detalles: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Enlaces

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

### Desarrollo

El mod jugable está en `metamorph_creative_menu/`; las pruebas y contratos están en `metamorph_creative_menu/tests/`. Todavía no se ha elegido una licencia general para el código original de MCM.

[↑ Back to language selection](#languages)

---

<a id="de"></a>

## Deutsch

### Installation — Schritt für Schritt

1. Öffne die [Releases-Seite](https://github.com/zerodancing/Metamorph-Creative-Menu/releases). Öffne das neueste Release und lade die MCM-`.zip` unter **Assets** herunter. Falls noch kein fertiges Release-Paket vorhanden ist, nutze **Code → Download ZIP** und suche darin den Ordner `metamorph_creative_menu`.
2. **Beende Noita vollständig**, bevor du den Mod installierst oder aktualisierst.
3. Finde deinen Noita-Installationsordner. In Steam: **Bibliothek → Rechtsklick auf Noita → Verwalten → Lokale Dateien durchsuchen**. Bei einer anderen Installation öffne den Ordner mit der Noita-Programmdatei.
4. Öffne im Noita-Ordner den Ordner `mods`. Falls er nicht existiert, erstelle ihn.
5. Entpacke den Download. Kopiere den vollständigen Ordner **`metamorph_creative_menu`** nach `Noita/mods/`. Benenne diesen Ordner nicht um.
6. Prüfe den endgültigen Pfad. Diese Datei muss genau hier liegen:

   `Noita/mods/metamorph_creative_menu/mod.xml`

   Richtig: `Noita/mods/metamorph_creative_menu/mod.xml`  
   Falsch: `Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Starte Noita und öffne **Mods**. Aktiviere **Unsafe mods / unrestricted API**. MCM bringt NoitaPatcher mit; die vollständigen Recovery-, Entity-Serialisierungs-, Player-Authority- und MagicNumbers-Funktionen benötigen diese Berechtigung.
8. Aktiviere **Metamorph: Creative Menu**. Falls Noita **Restart with enabled mods active** anbietet, nutze diese Option; andernfalls starte das Spiel nach dem Aktivieren neu.
9. Starte oder lade einen Run und drücke **TAB**. Wenn das Creative Menu erscheint, ist die Installation abgeschlossen. Während einer Verwandlung ist TAB auch die normale Rückkehr zur menschlichen Form. Die Standardtaste für Possession ist **G** und kann in den Mod-Einstellungen geändert werden.
10. Falls TAB nichts tut, prüfe zuerst: den `mod.xml`-Pfad aus Schritt 6, ob **Unsafe mods** aktiviert ist und ob Noita nach dem Aktivieren von MCM neu gestartet wurde.

**MCM aktualisieren:** Noita schließen, den alten Ordner `metamorph_creative_menu` entfernen und danach den neuen Ordner nach `mods` kopieren. So bleiben keine veralteten Dateien zurück.

**Entangled Worlds ist optional.** Im Einzelspieler benötigt MCM EW nicht. Für Multiplayer sollte auf allen Peers dieselbe MCM-Version laufen; eine kompatible Entangled-Worlds-Version wird separat eingerichtet.

### Voraussetzungen und Installation

- Installiertes Noita.
- Ordner `metamorph_creative_menu` unter `Noita/mods/`.
- **Unsafe mods / unrestricted API** muss aktiviert sein. Der mitgelieferte native **NoitaPatcher** benötigt diesen Zugriff.
- Entangled Worlds ist **optional**.

Installation:
1. Build unter [Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases) herunterladen oder Repository klonen/herunterladen.
2. `metamorph_creative_menu` vollständig nach `Noita/mods/` kopieren.
3. `Noita/mods/metamorph_creative_menu/mod.xml` muss existieren.
4. Unsafe mods und danach Metamorph: Creative Menu aktivieren.

Den internen Modordner nicht umbenennen.

### Über den Mod

**Metamorph: Creative Menu (MCM)** ist ein Creative-/Entwicklermenü für **Noita**. Es funktioniert eigenständig im Einzelspieler und bietet zusätzlich eine optionale experimentelle Kompatibilität mit **Entangled Worlds / Noita Proxy**.

MCM kann Zauberstäbe bearbeiten, Gegenstände erzeugen/aufnehmen, Perks und Effekte anwenden bzw. entfernen, den Spieler in Kreaturen verwandeln, eine existierende Kreatur unter dem Mauszeiger übernehmen, Wetter und Weltregeln ändern und einen spielerähnlichen Begleiter erzeugen.

### Funktionen

#### Zauber
Zauberstab halten, Slot auswählen und einen Zauber aus dem durchsuchbaren Katalog wählen. Zauber können ersetzt, gelöscht oder in die Welt geworfen werden. Beim Ersetzen wird der neue Zauber geprüft, bevor der alte entfernt wird.

#### Gegenstände
Kategorien: Behälter, Flüssigkeiten, Steine, Eier, Zauberstäbe, Bücher, Boni, Orbs, Questgegenstände und weitere.
- **LMB:** in der Nähe erzeugen.
- **RMB:** direkt in einen passenden Inventarslot aufnehmen.
- Bei vollem Inventar/fehlgeschlagenem Pickup bleibt der Gegenstand in der Welt.
- Gefüllte Flaschen/Behälter werden unterstützt.

#### Perks
- **ADD:** LMB erzeugt den normalen Pickup, RMB wendet direkt an.
- **REMOVE:** LMB entfernt einen Stack, RMB versucht alle zu entfernen.
MCM verfolgt viele perk-eigene Änderungen, um Entitäten, Komponenten und Werte wiederherzustellen, ohne absichtlich fremde Zustände zu überschreiben. Bei fehlender sicherer Umkehrung wird eine riskante Entfernung eher abgelehnt.

#### Suche
Große Kataloge können nach übersetztem Namen, ID und/oder Beschreibung durchsucht werden.

#### Kreaturen, Objekte und Formen
- **LMB:** erzeugen.
- **RMB:** verwandeln.
- **TAB:** Mensch.

Kompatibilität wird pro exaktem XML-Pfad verwaltet. Einige bekannte gefährliche Placement-Wrapper verwenden nur für die Transformation ein sicheres kanonisches Ziel. Spielerformen versuchen native Angriffe, Bewegung, Darstellung und Physik zu erhalten, während konkurrierende KI deaktiviert wird. Komplexe Entitäten können approximative Spezialadapter verwenden.

#### Menschliche Rückkehr und Tod einer Form
TAB verwendet zuerst Noitas nativen Polymorph-Lebenszyklus. Zusätzlich hält MCM über NoitaPatcher ein serialisiertes Backup des Menschen.

Bei tödlichem Schaden versucht **Death Handoff**, die Kreaturenform sterben zu lassen und die Spielerautorität auf den wiederhergestellten Menschen zu übertragen, damit der Tod der Form nicht automatisch den Run beendet.

#### Besitzergreifung
Kompatible Kreatur anvisieren und **G** drücken. MCM nutzt eine kompatible Form des Ziels und entfernt/retired das ursprüngliche Ziel, statt nur eine Kopie daneben zu erzeugen.

#### PLAYER-Begleiter
Der Eintrag `PLAYER` kann einen spielerähnlichen Verbündeten erzeugen. Mit passenden NoitaPatcher-Fähigkeiten kann der Begleiter den kopierten Zauberstab näher am echten Spieler verwenden.

#### Effekte
Status-/Zeiteffekte anwenden, wenn möglich Dauer wählen und Effekte entfernen, wobei geschützte interne/Perk-Zustände möglichst unangetastet bleiben.

#### Wetter
Zeit-Presets: Morgen, Tag, Abend, Nacht. Wetter: klar, bewölkt, neblig, Sturm. Advanced kontrolliert unterstützte Werte für Zeit, Wolken, Nebel, Wind, Windgeschwindigkeit, Regen und Blitze. **RELEASE** beendet das aktive Halten des Overrides.

#### Weltregeln
World Rules sind **reversible Overrides**. `NATIVE`/RESET stellt den von MCM erfassten Baseline-Zustand wieder her; kritische Regeln besitzen persistente Recovery-Daten.

Aktuelle Regeln:

- KREATUREN-BEZIEHUNGEN
- GOLD VERSCHWINDET NICHT
- UNBEGRENZTE ZAUBER
- KARTE AUFDECKEN
- BLUTGELD FÜR TRICK-KILLS
- HEIL-DROP-CHANCE
- FREUNDLICHE RATTEN
- BLUTMENGE
- TRICK-KILL-GOLD
- SCHADENSBLITZ
- FLECKENABWURF
- WELTGRAVITATION
- PHYSIK-DÄMPFUNG
- BLUTVOLUMEN
- TRITTKRAFT
- GELENKSTÄRKE
- TAGESZYKLUS

Physikregeln betreffen geladene/nahe Entitäten und Physikkörper, nicht sofort alle entladenen Objekte der gesamten Welt.

### Einzelspieler und Entangled Worlds

**EW ist für Einzelspieler nicht erforderlich.** MCM enthält NoitaPatcher und einen lokalen Base64-Codec.

Mit aktivem `quant.ew` wird die experimentelle Integration für Weltgegenstände, Perks, Wetter, Regeln, Formen/Übernahme, Begleiter und Compatibility-Patches aktiviert. Eine bereits von EW bereitgestellte kompatible NoitaPatcher-API kann wiederverwendet werden.

Netzwerkunterstützung ist **experimentell/teilweise**. Host und Client sollen dieselben MCM-Benutzerrechte haben, aber nicht jeder Noita/EW-Sonderfall kann garantiert synchronisiert werden. Alle Spieler sollten dieselbe MCM-Version verwenden.

### Fehlerbehebung

- Menü fehlt: Pfad und Aktivierung prüfen.
- Erweiterte Funktionen fehlen: Unsafe mods aktivieren und `NoitaPatcher/noitapatcher.dll` prüfen.
- Defekte Form: exakten Namen/XML und Art des Rückkehrfehlers angeben.
- EW: MCM- und EW-Versionen angeben.

Fehler unter [GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues) melden.

### Abhängigkeiten und Credits

MCM enthält **NoitaPatcher** (dextercd) und **lbase64** (Ilya Kolbin) und integriert optional **Noita Entangled Worlds** (IntQuant und Contributors). Details: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Links

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

### Entwicklung

Spielbarer Mod: `metamorph_creative_menu/`. Tests/Contracts: `metamorph_creative_menu/tests/`. Für den ursprünglichen MCM-Code wurde noch keine allgemeine Projektlizenz gewählt.

[↑ Back to language selection](#languages)

---

<a id="fr"></a>

## Français

### Installation — étape par étape

1. Ouvrez la [page Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases). Ouvrez la version la plus récente et téléchargez le `.zip` de MCM dans **Assets**. Si aucun paquet de release n’est encore disponible, utilisez **Code → Download ZIP** puis trouvez le dossier `metamorph_creative_menu` dans l’archive téléchargée.
2. **Fermez complètement Noita** avant d’installer ou de mettre à jour le mod.
3. Trouvez le dossier d’installation de Noita. Dans Steam : **Bibliothèque → clic droit sur Noita → Gérer → Parcourir les fichiers locaux**. Pour une autre installation, ouvrez le dossier contenant l’exécutable de Noita.
4. Ouvrez le dossier `mods` dans le dossier de Noita. S’il n’existe pas, créez-le.
5. Extrayez l’archive. Copiez le dossier complet **`metamorph_creative_menu`** dans `Noita/mods/`. Ne renommez pas ce dossier.
6. Vérifiez le chemin final. Ce fichier doit se trouver exactement ici :

   `Noita/mods/metamorph_creative_menu/mod.xml`

   Correct : `Noita/mods/metamorph_creative_menu/mod.xml`  
   Incorrect : `Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Lancez Noita et ouvrez **Mods**. Activez **Unsafe mods / unrestricted API**. MCM inclut NoitaPatcher et les fonctions complètes de récupération, sérialisation des entités, autorité du joueur et MagicNumbers ont besoin de cette permission.
8. Activez **Metamorph: Creative Menu**. Si Noita propose **Restart with enabled mods active**, utilisez cette option ; sinon redémarrez le jeu après avoir activé le mod.
9. Lancez ou continuez une partie et appuyez sur **TAB**. Si le Creative Menu s’ouvre, l’installation est terminée. Pendant une transformation, TAB sert aussi à revenir normalement à la forme humaine. La touche de possession par défaut est **G** et peut être modifiée dans les paramètres du mod.
10. Si TAB ne fait rien, vérifiez d’abord : le chemin de `mod.xml` de l’étape 6, que **Unsafe mods** est activé et que Noita a été redémarré après l’activation de MCM.

**Mise à jour de MCM :** fermez Noita, supprimez l’ancien dossier `metamorph_creative_menu`, puis copiez le nouveau dossier dans `mods`. Remplacer entièrement le dossier évite de conserver des fichiers obsolètes.

**Entangled Worlds est facultatif.** MCM fonctionne seul en solo. En multijoueur, utilisez la même version de MCM sur tous les joueurs et installez séparément une version compatible d’Entangled Worlds.

### Prérequis et installation

- Noita installé.
- Le dossier `metamorph_creative_menu` dans `Noita/mods/`.
- Activez **Unsafe mods / unrestricted API** : le NoitaPatcher natif inclus en a besoin.
- Entangled Worlds est **optionnel**.

1. Téléchargez une build via [Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases) ou clonez/téléchargez le dépôt.
2. Copiez `metamorph_creative_menu` dans `Noita/mods/`.
3. Vérifiez `Noita/mods/metamorph_creative_menu/mod.xml`.
4. Activez Unsafe mods puis Metamorph: Creative Menu.

Ne renommez pas le dossier interne.

### À propos

**Metamorph: Creative Menu (MCM)** est un menu créatif/de développement pour **Noita**. Il fonctionne de façon autonome en solo et propose une compatibilité expérimentale optionnelle avec **Entangled Worlds / Noita Proxy**.

Il permet de modifier les baguettes, créer ou prendre des objets, appliquer/retirer des atouts et effets, se transformer en créatures, posséder une créature existante sous le curseur, modifier la météo et les règles du monde et créer un compagnon ressemblant au joueur.

### Fonctionnalités

#### Sorts
Tenez une baguette, choisissez un emplacement et un sort dans le catalogue avec recherche/catégories. Vous pouvez remplacer, supprimer ou jeter un sort. Le remplacement vérifie d'abord le nouveau sort avant de supprimer l'ancien.

#### Objets
Conteneurs, liquides, pierres, œufs, baguettes, livres, bonus, orbes, objets de quête, etc.
- **LMB:** créer à proximité.
- **RMB:** essayer de placer directement dans l'inventaire.
- Si le pickup échoue ou si l'inventaire est plein, l'objet reste dans le monde.
- Les flacons/conteneurs remplis sont pris en charge.

#### Atouts
- **ADD:** LMB crée le pickup, RMB applique directement.
- **REMOVE:** LMB retire une pile, RMB tente de tout retirer.
MCM suit de nombreuses modifications appartenant aux perks pour restaurer entités, composants et valeurs sans écraser volontairement les changements externes. Sans inverse sûre, une suppression dangereuse peut être refusée.

#### Recherche
Les grands catalogues peuvent rechercher le nom traduit, l'ID et/ou la description.

#### Créatures, objets et formes
- **LMB:** créer.
- **RMB:** transformer.
- **TAB:** humain.

La compatibilité est enregistrée par chemin XML exact. Quelques wrappers connus comme dangereux utilisent uniquement pour la transformation une cible canonique sûre. Les formes joueur essaient de conserver attaques, déplacement, apparence et physique utiles tout en désactivant l'IA concurrente. Les entités complexes peuvent utiliser des adaptateurs approximatifs.

#### Retour humain et mort de la forme
TAB utilise d'abord le cycle polymorph natif de Noita. MCM conserve aussi une sauvegarde humaine sérialisée grâce à NoitaPatcher.

En cas de dégâts mortels, **death handoff** tente de laisser mourir le corps de créature tout en transférant l'autorité du joueur vers le corps humain restauré, afin que la mort de la forme ne termine pas automatiquement la partie.

#### Possession
Visez une créature compatible et appuyez sur **G**. MCM adopte une forme compatible de la cible puis retire la cible originale pour éviter un simple doublon.

#### Compagnon PLAYER
L'entrée `PLAYER` crée un allié semblable au joueur. Avec les capacités NoitaPatcher nécessaires, il peut utiliser la baguette copiée d'une façon plus proche d'un vrai joueur.

#### Effets
Appliquez des effets de statut/temporaires, choisissez la durée quand possible et retirez-les tout en essayant de préserver les états internes/perks qui n'appartiennent pas à l'éditeur.

#### Météo
Heures: matin, jour, soir, nuit. Presets: clair, nuageux, brumeux, tempête. Le mode avancé modifie les valeurs prises en charge de l'heure, nuages, brouillard, vent, vitesse du vent, pluie et éclairs. **RELEASE** cesse de maintenir l'override.

#### Règles du monde
Ce sont des **overrides réversibles**. `NATIVE`/RESET restaure le baseline capturé par MCM; les règles critiques disposent de recovery persistant.

Règles actuelles:

- RELATIONS DES CRÉATURES
- OR PERMANENT
- SORTS ILLIMITÉS
- RÉVÉLER LA CARTE
- ARGENT DE SANG DES TRICK KILLS
- CHANCE DE SOIN
- RATS AMICAUX
- QUANTITÉ DE SANG
- OR DES TRICK KILLS
- FLASH DE DÉGÂTS
- PERTE DES TACHES
- GRAVITÉ DU MONDE
- AMORTISSEMENT PHYSIQUE
- VOLUME DE SANG
- FORCE DU COUP DE PIED
- SOLIDITÉ DES JOINTS
- VITESSE DU CYCLE JOUR

Les règles de physique visent les entités/corps chargés ou proches, pas instantanément tout le monde déchargé.

### Solo et Entangled Worlds

**Entangled Worlds n'est pas requis en solo.** MCM inclut NoitaPatcher et un codec Base64 local.

Avec `quant.ew`, MCM active une intégration expérimentale pour objets, perks, météo, règles, formes/possession, compagnons et patches de compatibilité. Si EW publie déjà une API NoitaPatcher compatible, MCM peut la réutiliser.

Le multijoueur reste **expérimental/partiel**. Hôte et client doivent avoir les mêmes droits utilisateur MCM, mais tous les cas limites Noita/EW ne peuvent pas être garantis. Utilisez la même version MCM sur tous les pairs.

### Dépannage et rapports

- Menu absent: vérifiez le chemin et l'activation du mod.
- Fonctions avancées absentes: activez Unsafe mods et vérifiez `NoitaPatcher/noitapatcher.dll`.
- Forme problématique: indiquez le nom/XML exact et si TAB ou le retour après mort a échoué.
- EW: indiquez les versions MCM et EW.

Rapports: [GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues).

### Dépendances et crédits

MCM inclut **NoitaPatcher** (dextercd) et **lbase64** (Ilya Kolbin), avec intégration optionnelle de **Noita Entangled Worlds** (IntQuant et contributeurs). Voir [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Liens

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

### Développement

Mod jouable: `metamorph_creative_menu/`. Tests et contrats: `metamorph_creative_menu/tests/`. Aucune licence globale n'a encore été choisie pour le code original MCM.

[↑ Back to language selection](#languages)

---

<a id="it"></a>

## Italiano

### Installazione — passo per passo

1. Apri la [pagina Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases). Apri la versione più recente e scarica il `.zip` di MCM da **Assets**. Se non è ancora disponibile un pacchetto release, usa **Code → Download ZIP** e trova la cartella `metamorph_creative_menu` nell’archivio scaricato.
2. **Chiudi completamente Noita** prima di installare o aggiornare il mod.
3. Trova la cartella di installazione di Noita. Su Steam: **Libreria → clic destro su Noita → Gestisci → Sfoglia file locali**. Per un’altra installazione, apri la cartella che contiene l’eseguibile di Noita.
4. Apri la cartella `mods` nella cartella di Noita. Se non esiste, creala.
5. Estrai il download. Copia l’intera cartella **`metamorph_creative_menu`** in `Noita/mods/`. Non rinominare questa cartella.
6. Controlla il percorso finale. Questo file deve esistere esattamente qui:

   `Noita/mods/metamorph_creative_menu/mod.xml`

   Corretto: `Noita/mods/metamorph_creative_menu/mod.xml`  
   Errato: `Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Avvia Noita e apri **Mods**. Abilita **Unsafe mods / unrestricted API**. MCM include NoitaPatcher e le funzioni complete di recovery, serializzazione delle entità, player authority e MagicNumbers richiedono questo permesso.
8. Abilita **Metamorph: Creative Menu**. Se Noita mostra **Restart with enabled mods active**, usa quell’opzione; altrimenti riavvia il gioco dopo aver abilitato il mod.
9. Avvia o continua una partita e premi **TAB**. Se si apre il Creative Menu, l’installazione è completata. Durante una trasformazione, TAB serve anche per tornare normalmente alla forma umana. Il tasto predefinito per la possessione è **G** e può essere modificato nelle impostazioni del mod.
10. Se TAB non fa nulla, controlla prima: il percorso di `mod.xml` del punto 6, che **Unsafe mods** sia abilitato e che Noita sia stato riavviato dopo aver attivato MCM.

**Aggiornamento di MCM:** chiudi Noita, elimina la vecchia cartella `metamorph_creative_menu`, quindi copia la nuova cartella in `mods`. Sostituire l’intera cartella evita di lasciare file obsoleti.

**Entangled Worlds è opzionale.** MCM funziona autonomamente in single-player. Per il multiplayer, usa la stessa versione di MCM su tutti i giocatori e configura separatamente una versione compatibile di Entangled Worlds.

### Requisiti e installazione

- Noita installato.
- `metamorph_creative_menu` dentro `Noita/mods/`.
- Attivare **Unsafe mods / unrestricted API**: il NoitaPatcher nativo incluso lo richiede.
- Entangled Worlds è **opzionale**.

1. Scarica una build da [Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases) oppure scarica/clona il repository.
2. Copia `metamorph_creative_menu` in `Noita/mods/`.
3. Verifica `Noita/mods/metamorph_creative_menu/mod.xml`.
4. Attiva Unsafe mods e poi Metamorph: Creative Menu.

Non rinominare la cartella interna.

### Informazioni

**Metamorph: Creative Menu (MCM)** è un menu creativo/di sviluppo per **Noita**. Funziona autonomamente in giocatore singolo e offre compatibilità sperimentale opzionale con **Entangled Worlds / Noita Proxy**.

Permette di modificare bacchette, generare o prendere oggetti, applicare/rimuovere vantaggi ed effetti, trasformarsi in creature, possedere una creatura esistente sotto il cursore, cambiare meteo e regole del mondo e creare un compagno simile al giocatore.

### Funzioni

#### Incantesimi
Impugna una bacchetta, scegli uno slot e un incantesimo dal catalogo con ricerca/categorie. Puoi sostituire, eliminare o lasciare cadere incantesimi. La sostituzione verifica il nuovo incantesimo prima di eliminare quello vecchio.

#### Oggetti
Contenitori, liquidi, pietre, uova, bacchette, libri, bonus, sfere, oggetti quest e altro.
- **LMB:** genera vicino.
- **RMB:** prova ad aggiungere direttamente all'inventario.
- Se non c'è spazio o il pickup fallisce, l'oggetto resta nel mondo.
- Sono supportate fiaschette/contenitori riempiti.

#### Vantaggi
- **ADD:** LMB genera il pickup; RMB applica direttamente.
- **REMOVE:** LMB rimuove uno stack; RMB tenta di rimuoverli tutti.
MCM registra molte modifiche appartenenti ai perk per ripristinare entità, componenti e valori senza sovrascrivere volutamente stato esterno. Se non esiste un inverse sicuro, può rifiutare una rimozione rischiosa.

#### Ricerca
I cataloghi grandi possono cercare nome tradotto, ID e/o descrizione.

#### Creature, oggetti e forme
- **LMB:** genera.
- **RMB:** trasforma.
- **TAB:** umano.

La compatibilità è registrata per percorso XML esatto. Alcuni wrapper noti come pericolosi usano un target canonico sicuro solo durante la trasformazione. Le forme tentano di mantenere attacchi, movimento, presentazione e fisica utili disattivando l'IA che competerebbe col giocatore. Entità complesse possono essere approssimate da adapter speciali.

#### Ritorno umano e morte della forma
TAB usa prima il lifecycle polymorph nativo di Noita. MCM conserva anche un backup umano serializzato tramite NoitaPatcher.

Con danno fatale, **death handoff** prova a lasciare morire la forma-creatura trasferendo l'autorità del giocatore al corpo umano ripristinato, evitando che la morte della forma termini automaticamente la run.

#### Possessione
Punta una creatura compatibile e premi **G**. MCM adotta una forma compatibile con il target e ritira l'entità originale per evitare un semplice duplicato.

#### Compagno PLAYER
La voce `PLAYER` può generare un alleato simile al giocatore. Con le capacità NoitaPatcher necessarie può usare la bacchetta copiata in modo più simile a un giocatore reale.

#### Effetti
Applica effetti status/temporanei, scegli durata quando supportata e rimuovi effetti cercando di conservare stati interni/perk non appartenenti all'editor.

#### Meteo
Preset orario: mattino, giorno, sera, notte. Preset meteo: sereno, nuvoloso, nebbia, tempesta. Advanced controlla valori supportati di ora, nuvole, nebbia, vento, velocità vento, pioggia e fulmini. **RELEASE** smette di mantenere l'override.

#### Regole del mondo
Sono **override reversibili**. `NATIVE`/RESET ripristina il baseline catturato da MCM; le regole critiche usano recovery persistente.

Regole attuali:

- RELAZIONI CREATURE
- ORO PERMANENTE
- USI ILLIMITATI
- RIVELA MAPPA
- DENARO DI SANGUE DAI TRICK KILL
- PROBABILITÀ CURA
- RATTI AMICHEVOLI
- QUANTITÀ DI SANGUE
- ORO DA TRICK KILL
- LAMPO DANNO
- PERDITA MACCHIE
- GRAVITÀ DEL MONDO
- SMORZAMENTO FISICO
- VOLUME DEL SANGUE
- FORZA DEL CALCIO
- FORZA DEI GIUNTI
- VELOCITÀ DEL GIORNO

Le regole fisiche agiscono su entità/corpi caricati o vicini, non istantaneamente su tutto il mondo non caricato.

### Singolo ed Entangled Worlds

**EW non è richiesto in giocatore singolo.** MCM include NoitaPatcher e un codec Base64 locale.

Con `quant.ew` attivo viene abilitata l'integrazione sperimentale per oggetti, perk, meteo, regole, forme/possessione, compagni e compatibility patch. Se EW pubblica già un'API NoitaPatcher compatibile, MCM può riutilizzarla.

Il multiplayer è **sperimentale/parziale**. Host e client dovrebbero avere gli stessi diritti MCM, ma non ogni edge case Noita/EW è garantito. Tutti i peer dovrebbero usare la stessa versione MCM.

### Problemi e segnalazioni

- Menu assente: verifica percorso e mod attivo.
- Funzioni avanzate mancanti: abilita Unsafe mods e controlla `NoitaPatcher/noitapatcher.dll`.
- Forma problematica: indica nome/XML e se fallisce TAB o ritorno dopo morte.
- EW: indica versioni MCM ed EW.

Segnala su [GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues).

### Dipendenze e crediti

MCM include **NoitaPatcher** (dextercd) e **lbase64** (Ilya Kolbin) e integra opzionalmente **Noita Entangled Worlds** (IntQuant e contributor). Dettagli: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Link

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

### Sviluppo

Mod giocabile: `metamorph_creative_menu/`. Test e contratti: `metamorph_creative_menu/tests/`. Non è ancora stata scelta una licenza generale per il codice originale MCM.

[↑ Back to language selection](#languages)

---

<a id="pl"></a>

## Polski

### Instalacja — krok po kroku

1. Otwórz [stronę Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases). Otwórz najnowsze wydanie i pobierz plik `.zip` MCM z sekcji **Assets**. Jeżeli nie ma jeszcze gotowego pakietu wydania, użyj **Code → Download ZIP** i znajdź folder `metamorph_creative_menu` wewnątrz pobranego archiwum.
2. **Całkowicie zamknij Noitę** przed instalacją lub aktualizacją moda.
3. Znajdź folder instalacyjny Noity. W Steam: **Biblioteka → prawy przycisk na Noita → Zarządzaj → Przeglądaj pliki lokalne**. Przy innej instalacji otwórz folder zawierający plik wykonywalny Noity.
4. Otwórz folder `mods` w katalogu Noity. Jeśli go nie ma, utwórz go.
5. Rozpakuj pobrany plik. Skopiuj cały folder **`metamorph_creative_menu`** do `Noita/mods/`. Nie zmieniaj nazwy tego folderu.
6. Sprawdź końcową ścieżkę. Ten plik musi znajdować się dokładnie tutaj:

   `Noita/mods/metamorph_creative_menu/mod.xml`

   Poprawnie: `Noita/mods/metamorph_creative_menu/mod.xml`  
   Błędnie: `Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Uruchom Noitę i otwórz **Mods**. Włącz **Unsafe mods / unrestricted API**. MCM zawiera NoitaPatcher, a pełne funkcje odzyskiwania, serializacji encji, kontroli gracza i MagicNumbers wymagają tego uprawnienia.
8. Włącz **Metamorph: Creative Menu**. Jeśli Noita pokaże **Restart with enabled mods active**, użyj tej opcji; w przeciwnym razie uruchom grę ponownie po włączeniu moda.
9. Rozpocznij lub kontynuuj rozgrywkę i naciśnij **TAB**. Jeśli otworzy się Creative Menu, instalacja jest zakończona. Podczas transformacji TAB służy również do normalnego powrotu do ludzkiej formy. Domyślny klawisz przejęcia to **G** i można go zmienić w ustawieniach moda.
10. Jeśli TAB nic nie robi, najpierw sprawdź: ścieżkę `mod.xml` z kroku 6, czy **Unsafe mods** jest włączone i czy Noita została ponownie uruchomiona po aktywowaniu MCM.

**Aktualizacja MCM:** zamknij Noitę, usuń stary folder `metamorph_creative_menu`, a następnie skopiuj nowy folder do `mods`. Pełna wymiana folderu zapobiega pozostawieniu starych plików.

**Entangled Worlds jest opcjonalny.** MCM działa samodzielnie w trybie single-player. W multiplayerze wszyscy gracze powinni używać tej samej wersji MCM, a zgodną wersję Entangled Worlds należy skonfigurować osobno.

### Wymagania i instalacja

- Zainstalowana Noita.
- `metamorph_creative_menu` w `Noita/mods/`.
- Włącz **Unsafe mods / unrestricted API** — dołączony natywny NoitaPatcher tego wymaga.
- Entangled Worlds jest **opcjonalny**.

1. Pobierz build z [Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases) albo pobierz/sklonuj repozytorium.
2. Skopiuj `metamorph_creative_menu` do `Noita/mods/`.
3. Sprawdź `Noita/mods/metamorph_creative_menu/mod.xml`.
4. Włącz Unsafe mods, a następnie Metamorph: Creative Menu.

Nie zmieniaj nazwy wewnętrznego folderu.

### O modzie

**Metamorph: Creative Menu (MCM)** to kreatywne/deweloperskie menu dla **Noita**. Działa samodzielnie w trybie jednoosobowym i oferuje opcjonalną eksperymentalną kompatybilność z **Entangled Worlds / Noita Proxy**.

Pozwala edytować różdżki, tworzyć lub odbierać przedmioty, nakładać i usuwać perki/efekty, przemieniać się w stworzenia, przejmować istniejącego moba pod kursorem, zmieniać pogodę i zasady świata oraz tworzyć sojusznika podobnego do gracza.

### Funkcje

#### Czary
Trzymaj różdżkę, wybierz slot i czar z katalogu z kategoriami/wyszukiwaniem. Można zastępować, usuwać i wyrzucać czary. Stary czar jest usuwany dopiero po sprawdzeniu nowego.

#### Przedmioty
Kontenery, ciecze, kamienie, jaja, różdżki, książki, bonusy, orby, przedmioty questowe i inne.
- **LPM:** utwórz obok.
- **PPM:** spróbuj dodać bezpośrednio do ekwipunku.
- Gdy brak miejsca lub pickup się nie uda, przedmiot zostaje w świecie.
- Obsługiwane są napełnione butelki/kontenery.

#### Perki
- **ADD:** LPM tworzy pickup; PPM stosuje perk bezpośrednio.
- **REMOVE:** LPM usuwa jeden stack; PPM próbuje usunąć wszystkie.
MCM śledzi wiele zmian należących do perka, aby odtworzyć jego encje, komponenty i wartości bez celowego nadpisywania zmian innych systemów. Bez bezpiecznego inverse ryzykowne usunięcie może zostać odrzucone.

#### Wyszukiwanie
Duże katalogi można przeszukiwać po przetłumaczonej nazwie, ID i/lub opisie.

#### Stworzenia, obiekty i formy
- **LPM:** spawn.
- **PPM:** transformacja.
- **TAB:** człowiek.

Kompatybilność jest przechowywana według dokładnej ścieżki XML. Wybrane niebezpieczne wrappery używają bezpiecznego celu kanonicznego tylko do transformacji. Formy gracza próbują zachować użyteczne ataki, ruch, wygląd i fizykę, wyłączając konkurującą AI. Złożone encje mogą używać przybliżonych adapterów.

#### Powrót i śmierć formy
TAB najpierw wykorzystuje natywny lifecycle polymorph Noita. MCM przechowuje też serializowany backup człowieka dzięki NoitaPatcher.

Przy śmiertelnych obrażeniach **death handoff** próbuje pozwolić umrzeć ciału stwora, ale przekazać kontrolę odtworzonemu człowiekowi, aby śmierć formy nie kończyła automatycznie runu.

#### Przejęcie
Wyceluj w kompatybilnego stwora i naciśnij **G**. MCM wykorzystuje kompatybilną formę celu i usuwa/wycofuje oryginalny cel, aby nie tworzyć zwykłego duplikatu.

#### Towarzysz PLAYER
Wpis `PLAYER` tworzy sojusznika podobnego do gracza. Z odpowiednimi możliwościami NoitaPatcher może używać skopiowanej różdżki bardziej jak prawdziwy gracz.

#### Efekty
Nakładaj statusy/efekty czasowe, wybieraj czas trwania tam, gdzie jest obsługiwany, i usuwaj efekty z zachowaniem chronionych stanów wewnętrznych/perków, gdy to możliwe.

#### Pogoda
Pory: rano, dzień, wieczór, noc. Presety: czysto, pochmurno, mgła, burza. Advanced steruje obsługiwanymi wartościami czasu, chmur, mgły, wiatru, prędkości wiatru, deszczu i błyskawic. **RELEASE** przestaje utrzymywać override.

#### Zasady świata
To **odwracalne override'y**. `NATIVE`/RESET przywraca baseline zapisany przez MCM; krytyczne zasady mają trwałe dane recovery.

Aktualne zasady:

- RELACJE STWORZEŃ
- ZŁOTO NIE ZNIKA
- NIELIMITOWANE UŻYCIA
- ODKRYJ MAPĘ
- KRWAWE PIENIĄDZE ZA TRICK KILLE
- SZANSA NA LECZENIE
- PRZYJAZNE SZCZURY
- ILOŚĆ KRWI
- ZŁOTO ZA TRICK KILLE
- BŁYSK OBRAŻEŃ
- ZRZUCANIE PLAM
- GRAWITACJA ŚWIATA
- TŁUMIENIE FIZYKI
- ILOŚĆ KRWI
- SIŁA KOPNIĘCIA
- SIŁA POŁĄCZEŃ
- SZYBKOŚĆ DOBY

Zasady fizyki dotyczą załadowanych/bliskich encji i ciał, a nie natychmiast wszystkich niezaładowanych obiektów świata.

### Solo i Entangled Worlds

**EW nie jest potrzebny w solo.** MCM zawiera NoitaPatcher i lokalny kodek Base64.

Po włączeniu `quant.ew` aktywuje się eksperymentalna integracja przedmiotów, perków, pogody, zasad, form/przejęcia, companionów i patchy kompatybilności. Jeśli EW już udostępnia zgodne API NoitaPatcher, MCM może je wykorzystać.

Multiplayer jest **eksperymentalny/częściowy**. Host i klient mają mieć te same prawa MCM, ale nie każdy edge case Noita/EW jest gwarantowany. Wszyscy powinni używać tej samej wersji MCM.

### Problemy i raporty

- Brak menu: sprawdź ścieżkę i aktywację.
- Brak funkcji rozszerzonych: włącz Unsafe mods i sprawdź `NoitaPatcher/noitapatcher.dll`.
- Problem z formą: podaj dokładną nazwę/XML i rodzaj nieudanego powrotu.
- EW: podaj wersje MCM i EW.

Błędy: [GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues).

### Zależności i podziękowania

MCM zawiera **NoitaPatcher** (dextercd) i **lbase64** (Ilya Kolbin), a opcjonalnie integruje **Noita Entangled Worlds** (IntQuant i współtwórcy). Szczegóły: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Linki

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

### Rozwój

Grywalny mod: `metamorph_creative_menu/`. Testy i kontrakty: `metamorph_creative_menu/tests/`. Nie wybrano jeszcze ogólnej licencji dla oryginalnego kodu MCM.

[↑ Back to language selection](#languages)

---

<a id="zh-cn"></a>

## 简体中文

### 安装 — 逐步说明

1. 打开 [Releases 页面](https://github.com/zerodancing/Metamorph-Creative-Menu/releases)。进入最新版本，在 **Assets** 中下载 MCM 的 `.zip` 文件。如果暂时没有打包好的 Release，请使用 **Code → Download ZIP**，然后在下载的压缩包中找到 `metamorph_creative_menu` 文件夹。
2. 安装或更新模组前，**请完全关闭 Noita**。
3. 找到 Noita 的安装目录。Steam：**库 → 右键 Noita → 管理 → 浏览本地文件**。如果使用其他安装方式，请打开包含 Noita 可执行文件的目录。
4. 在 Noita 目录中打开 `mods` 文件夹。如果没有该文件夹，请创建它。
5. 解压下载文件。将完整的 **`metamorph_creative_menu`** 文件夹复制到 `Noita/mods/`。不要重命名这个文件夹。
6. 检查最终路径。下面这个文件必须直接存在：

   `Noita/mods/metamorph_creative_menu/mod.xml`

   正确：`Noita/mods/metamorph_creative_menu/mod.xml`  
   错误：`Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. 启动 Noita 并打开 **Mods**。启用 **Unsafe mods / unrestricted API**。MCM 自带 NoitaPatcher，完整的恢复、实体序列化、玩家控制权切换和 MagicNumbers 功能需要此权限。
8. 启用 **Metamorph: Creative Menu**。如果 Noita 显示 **Restart with enabled mods active**，请选择它；否则在启用模组后重新启动游戏。
9. 开始或继续一次游戏并按 **TAB**。如果 Creative Menu 打开，说明安装成功。变形状态下，TAB 也用于正常返回人类形态。默认的附身按键是 **G**，可在模组设置中修改。
10. 如果按 TAB 没有反应，请先检查三项：第 6 步中的 `mod.xml` 路径、是否启用了 **Unsafe mods**、以及启用 MCM 后是否重启了 Noita。

**更新 MCM：**关闭 Noita，删除旧的 `metamorph_creative_menu` 文件夹，然后把新文件夹复制到 `mods`。完整替换可以避免残留旧版本文件。

**Entangled Worlds 是可选的。** 单人游戏不需要 EW。多人游戏时，请确保所有玩家使用相同版本的 MCM，并单独安装兼容版本的 Entangled Worlds。

### 要求与安装

- 已安装 Noita。
- 将 `metamorph_creative_menu` 放到 `Noita/mods/`。
- 在 Noita 模组菜单中启用 **Unsafe mods / unrestricted API**。MCM 内置的原生 **NoitaPatcher** 扩展需要该权限。
- Entangled Worlds **不是单人模式的必需依赖**。

安装步骤：
1. 从 [Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases) 下载构建，或下载/克隆本仓库。
2. 将整个 `metamorph_creative_menu` 复制到 `Noita/mods/`。
3. 确认存在 `Noita/mods/metamorph_creative_menu/mod.xml`。
4. 启用 Unsafe mods，然后启用 Metamorph: Creative Menu。

不要重命名模组内部文件夹。

### 简介

**Metamorph: Creative Menu (MCM)** 是 **Noita** 的创意/开发者菜单。它可在单人游戏中独立运行，同时提供可选的、实验性的 **Entangled Worlds / Noita Proxy** 兼容层。

MCM 可以编辑法杖、生成或直接获得物品、添加/移除天赋与效果、变形成生物、占据鼠标指向的现有生物、控制天气与世界规则，并生成类似玩家的友方同伴。

### 功能

#### 法术/法杖编辑
手持法杖，选择槽位，再从支持分类与搜索的目录中选择法术。可替换、删除或把法术丢到世界中。替换操作会先确认新法术已正确附加，再删除旧法术。

#### 物品
支持容器、液体、石头、蛋、法杖、书、奖励、宝珠、任务物品等。
- **左键：** 在附近生成。
- **右键：** 尝试直接放入合适的背包槽位。
- 背包满或拾取失败时，物品会保留在世界中。
- 支持装有液体的烧瓶/容器。

#### 天赋
- **ADD：** 左键生成普通天赋拾取物；右键直接应用。
- **REMOVE：** 左键移除一层；右键尝试全部移除。
MCM 会记录许多属于天赋的实体、组件和值，以便安全逆转，并尽量不覆盖其他模组/系统的变化。若无法确定安全逆操作，MCM 宁可拒绝危险移除。

#### 搜索
大型目录支持按本地化名称、ID 和/或描述搜索。

#### 生物、对象与形态
- **左键：** 生成。
- **右键：** 变形。
- **TAB：** 返回人类。

兼容性按精确 XML 路径记录，而不是用宽泛文件名黑名单。少量已知危险的 placement wrapper 仅在变形时会路由到安全 canonical target。玩家形态会尽量保留可用的原生攻击、移动、外观和物理，同时关闭与玩家控制冲突的 AI。复杂实体可能使用近似适配器。

#### 人类恢复与形态死亡
普通 TAB 返回首先使用 Noita 原生 polymorph 生命周期。MCM 还通过 NoitaPatcher 保存序列化的人类备份。

受到致命伤害时，**death handoff** 会尝试让当前生物身体正常死亡，同时把玩家控制权交还给恢复的人类身体，从而避免“形态死亡 = 整个 run 结束”。

#### 占据
瞄准兼容生物并按 **G**。MCM 使用该目标的兼容形态，并退役/移除原目标，避免仅在旁边生成一个复制体。

#### PLAYER 同伴
`PLAYER` 项目可生成类似玩家的友军。具备所需 NoitaPatcher 功能时，同伴可以更接近真实玩家地使用复制的法杖。

#### 效果
可应用状态/限时效果，在支持时选择持续时间，并通过编辑器移除效果，同时尽量保留不属于编辑器的内部/天赋状态。

#### 天气
时间预设：早晨、白天、傍晚、夜晚。天气预设：晴朗、多云、雾、暴风雨。高级模式可修改受支持的时间、云量、雾、风、风速、雨和雷电参数。**RELEASE** 会停止 MCM 持续维持天气 override。

#### 世界规则
世界规则是**可逆 override**。`NATIVE`/RESET 会恢复 MCM 捕获的原始 baseline；关键规则使用持久 recovery 记录。

当前规则：

- 生物关系
- 金币不消失
- 无限法术次数
- 揭开战争迷雾
- 花式击杀血钱
- 治疗掉落几率
- 友好老鼠
- 血腥程度
- 花式击杀金币
- 受伤闪光
- 污渍脱落
- 世界重力
- 物理阻尼
- 血液量
- 踢击力量
- 关节强度
- 昼夜循环速度

物理规则作用于已加载/附近的实体与物理体，并不会瞬间修改整个无限世界中尚未加载的所有对象。

### 单人与 Entangled Worlds

**单人模式不需要 Entangled Worlds。** MCM 自带 NoitaPatcher 和本地 Base64 编解码器。

启用 `quant.ew` 后，会开启实验性的物品、天赋、天气、世界规则、形态/占据、同伴与兼容修补同步层。如果 EW 已发布兼容的 NoitaPatcher API，MCM 可以复用它。

多人支持仍为**实验/部分支持**。目标是 host 与 client 拥有相同的 MCM 用户权限，但无法保证所有 Noita/EW 极端情况。所有玩家应使用相同 MCM 版本。

### 故障排除与反馈

- 菜单打不开：检查路径和模组是否启用。
- 缺少高级功能：启用 Unsafe mods，并确认 `NoitaPatcher/noitapatcher.dll` 存在。
- 某个形态有问题：提供准确名称/XML，并说明是 TAB 返回还是死亡返回失败。
- EW 问题：提供 MCM 与 EW 版本。

请在 [GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues) 提交问题，并附上版本、复现步骤和可用日志。

### 第三方依赖与致谢

MCM 内含 **NoitaPatcher**（dextercd）和 **lbase64**（Ilya Kolbin），并可选集成 **Noita Entangled Worlds**（IntQuant 与贡献者）。完整路径、用途和许可证/状态说明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

### 链接

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

### 开发

可玩的模组目录为 `metamorph_creative_menu/`；测试与架构/行为契约在 `metamorph_creative_menu/tests/`。MCM 原创代码目前尚未选择仓库级统一许可证。

[↑ Back to language selection](#languages)

---

<a id="ja"></a>

## 日本語

### インストール — 手順

1. [Releases ページ](https://github.com/zerodancing/Metamorph-Creative-Menu/releases)を開きます。最新リリースを開き、**Assets** から MCM の `.zip` をダウンロードしてください。まだパッケージ済みリリースがない場合は **Code → Download ZIP** を使い、ダウンロードしたアーカイブ内の `metamorph_creative_menu` フォルダーを探します。
2. インストールまたは更新の前に、**Noita を完全に終了**してください。
3. Noita のインストールフォルダーを開きます。Steam では **ライブラリ → Noita を右クリック → 管理 → ローカルファイルを閲覧**。それ以外のインストールでは Noita の実行ファイルがあるフォルダーを開きます。
4. Noita フォルダー内の `mods` を開きます。存在しない場合は作成してください。
5. ダウンロードしたファイルを展開し、**`metamorph_creative_menu`** フォルダー全体を `Noita/mods/` にコピーします。このフォルダー名は変更しないでください。
6. 最終パスを確認します。次のファイルが直接存在している必要があります：

   `Noita/mods/metamorph_creative_menu/mod.xml`

   正しい例：`Noita/mods/metamorph_creative_menu/mod.xml`  
   間違い：`Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Noita を起動して **Mods** を開き、**Unsafe mods / unrestricted API** を有効にします。MCM には NoitaPatcher が同梱されており、完全な復旧、エンティティのシリアライズ、プレイヤー権限切り替え、MagicNumbers 機能にこの許可が必要です。
8. **Metamorph: Creative Menu** を有効にします。Noita に **Restart with enabled mods active** が表示された場合はそれを使用し、表示されない場合も有効化後にゲームを再起動してください。
9. ランを開始または再開して **TAB** を押します。Creative Menu が開けばインストール成功です。変身中の TAB は通常の人間形態への復帰にも使います。Possession の初期キーは **G** で、Mod 設定から変更できます。
10. TAB を押しても何も起きない場合は、まず第 6 手順の `mod.xml` パス、**Unsafe mods** が有効か、MCM 有効化後に Noita を再起動したかを確認してください。

**MCM の更新：**Noita を終了し、古い `metamorph_creative_menu` フォルダーを削除してから、新しいフォルダーを `mods` にコピーしてください。フォルダー全体を置き換えることで古いファイルの残留を防げます。

**Entangled Worlds は任意です。** シングルプレイでは EW は不要です。マルチプレイでは全プレイヤーが同じ MCM バージョンを使用し、対応する Entangled Worlds を別途導入してください。

### 必要条件とインストール

- Noita。
- `Noita/mods/` 内の `metamorph_creative_menu` フォルダ。
- Noita の Mod 設定で **Unsafe mods / unrestricted API** を有効にしてください。同梱のネイティブ **NoitaPatcher** が必要とします。
- Entangled Worlds は**任意**です。

1. [Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases) からビルドを取得するか、リポジトリをダウンロード/cloneします。
2. `metamorph_creative_menu` を `Noita/mods/` にコピーします。
3. `Noita/mods/metamorph_creative_menu/mod.xml` が存在することを確認します。
4. Unsafe mods と Metamorph: Creative Menu を有効化します。

内部フォルダ名は変更しないでください。

### 概要

**Metamorph: Creative Menu (MCM)** は **Noita** 用のクリエイティブ/開発者メニューです。シングルプレイでは単独で動作し、任意で **Entangled Worlds / Noita Proxy** との実験的互換機能も提供します。

杖の編集、アイテム生成/取得、パークと効果の付与・削除、クリーチャーへの変身、カーソル下の既存クリーチャーの乗っ取り、天候・ワールドルール変更、プレイヤー風の仲間生成などができます。

### 機能

#### 呪文/杖編集
杖を持ち、スロットを選び、検索・カテゴリ対応の一覧から呪文を選択します。置換、削除、ワールドへのドロップが可能です。置換では新しい呪文を確認してから古い呪文を削除します。

#### アイテム
ボトル/容器、液体、石、卵、杖、本、ボーナス、オーブ、クエストアイテムなど。
- **LMB:** 近くに生成。
- **RMB:** 適切なインベントリスロットへ直接追加を試行。
- 空きがない/取得失敗時はアイテムをワールドに残します。
- 液体入りフラスコ等も対応します。

#### パーク
- **ADD:** LMB で通常 pickup を生成、RMB で直接取得。
- **REMOVE:** LMB で1スタック削除、RMB ですべて削除を試行。
MCM はパーク所有の多くの変更を追跡し、他システムの状態を意図的に上書きせず、エンティティ/コンポーネント/値を戻そうとします。安全な逆操作がない場合は危険な削除を拒否することがあります。

#### 検索
大きなカタログでは翻訳名、ID、説明などで検索できます。

#### クリーチャー、オブジェクト、形態
- **LMB:** 生成。
- **RMB:** 変身。
- **TAB:** 人間へ戻る。

互換性は正確な XML パス単位で管理されます。既知の危険な placement wrapper の一部は、変身時のみ安全な canonical target にルーティングされます。プレイヤー形態は有用なネイティブ攻撃、移動、見た目、物理をできるだけ維持し、操作と競合する AI を無効化します。複雑なエンティティは近似 adapter を使う場合があります。

#### 人間への復帰と形態の死亡
通常の TAB 復帰はまず Noita のネイティブ polymorph lifecycle を使います。さらに MCM は NoitaPatcher で人間のシリアライズ済みバックアップを保持します。

致命傷では **death handoff** を試み、クリーチャー身体は死亡させつつ、プレイヤー権限を復元した人間へ戻し、形態の死だけで run 全体が終わらないようにします。

#### Possession
対応クリーチャーにカーソルを合わせ **G**。MCM は対象に対応する形態を使用し、元の対象を retire/削除して単純な複製を避けます。

#### PLAYER 仲間
`PLAYER` 項目からプレイヤー風の味方を生成できます。必要な NoitaPatcher 機能があれば、コピーした杖をより実際のプレイヤーに近い形で使用できます。

#### 効果
ステータス/時間制効果を付与し、対応していれば時間を選択し、内部/perk 状態を可能な限り保護しながら削除できます。

#### 天候
時間プリセット: 朝、昼、夕方、夜。天候: 晴れ、曇り、霧、嵐。Advanced では時間、雲、霧、風、風速、雨、雷関連の対応値を変更できます。**RELEASE** で MCM の override 維持を停止します。

#### ワールドルール
ルールは**可逆 override**です。`NATIVE`/RESET は MCM が記録した baseline を戻し、重要なルールは永続 recovery 情報を持ちます。

現在のルール:

- クリーチャー関係
- 金塊が消えない
- 呪文使用回数無制限
- マップを開く
- トリックキル血金
- 回復ドロップ率
- 友好的なネズミ
- 流血量
- トリックキル金額
- ダメージフラッシュ
- 汚れの脱落
- ワールド重力
- 物理減衰
- 血液量
- キック力
- ジョイント強度
- 昼夜サイクル速度

物理ルールはロード済み/近くのエンティティや物理ボディに作用し、無限ワールド全体の未ロード対象を一瞬で書き換えるものではありません。

### シングルプレイと Entangled Worlds

**シングルプレイに EW は不要です。** MCM は NoitaPatcher とローカル Base64 codec を同梱しています。

`quant.ew` が有効なら、ワールドアイテム、パーク、天候、ルール、形態/possess、仲間、互換 patch の実験的連携が有効になります。EW が互換 NoitaPatcher API をすでに公開している場合、MCM はそれを再利用できます。

マルチプレイ対応は**実験的/部分的**です。host と client は同じ MCM 操作権を持つ方針ですが、すべての Noita/EW edge case を保証するものではありません。全 peer で同じ MCM バージョンを使ってください。

### トラブルと報告

- メニューが出ない: パスと Mod 有効化を確認。
- 拡張機能がない: Unsafe mods と `NoitaPatcher/noitapatcher.dll` を確認。
- 形態の問題: 正確な名前/XML と TAB/死亡復帰のどちらが失敗したかを記載。
- EW: MCM と EW のバージョンを記載。

[GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues) へ再現手順とログを投稿してください。

### 依存関係とクレジット

MCM は **NoitaPatcher** (dextercd) と **lbase64** (Ilya Kolbin) を同梱し、任意で **Noita Entangled Worlds** (IntQuant と contributors) と連携します。詳細は [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

### リンク

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

### 開発

プレイ可能な Mod は `metamorph_creative_menu/`、テスト/contract は `metamorph_creative_menu/tests/` にあります。MCM オリジナルコードのリポジトリ全体ライセンスはまだ選択されていません。

[↑ Back to language selection](#languages)

---

<a id="ko"></a>

## 한국어

### 설치 — 단계별 안내

1. [Releases 페이지](https://github.com/zerodancing/Metamorph-Creative-Menu/releases)를 엽니다. 가장 최신 릴리스를 열고 **Assets**에서 MCM `.zip` 파일을 다운로드하세요. 아직 패키지 릴리스가 없다면 **Code → Download ZIP**을 사용한 뒤 압축 파일 안에서 `metamorph_creative_menu` 폴더를 찾으세요.
2. 모드를 설치하거나 업데이트하기 전에 **Noita를 완전히 종료**하세요.
3. Noita 설치 폴더를 찾습니다. Steam에서는 **라이브러리 → Noita 우클릭 → 관리 → 로컬 파일 보기**를 사용하세요. 다른 설치 방식이라면 Noita 실행 파일이 있는 폴더를 여세요.
4. Noita 폴더 안의 `mods` 폴더를 엽니다. 없다면 새로 만드세요.
5. 다운로드한 파일의 압축을 풉니다. **`metamorph_creative_menu`** 폴더 전체를 `Noita/mods/` 안에 복사하세요. 이 폴더 이름을 바꾸지 마세요.
6. 최종 경로를 확인하세요. 아래 파일이 정확히 이 위치에 있어야 합니다:

   `Noita/mods/metamorph_creative_menu/mod.xml`

   올바름: `Noita/mods/metamorph_creative_menu/mod.xml`  
   잘못됨: `Noita/mods/metamorph_creative_menu/metamorph_creative_menu/mod.xml`
7. Noita를 실행하고 **Mods**를 엽니다. **Unsafe mods / unrestricted API**를 활성화하세요. MCM에는 NoitaPatcher가 포함되어 있으며 전체 복구, 엔티티 직렬화, 플레이어 권한 전환 및 MagicNumbers 기능에 이 권한이 필요합니다.
8. **Metamorph: Creative Menu**를 활성화하세요. Noita에 **Restart with enabled mods active**가 표시되면 사용하고, 그렇지 않더라도 모드를 활성화한 뒤 게임을 다시 시작하세요.
9. 게임을 시작하거나 이어서 **TAB**을 누르세요. Creative Menu가 열리면 설치가 완료된 것입니다. 변신 중 TAB은 정상적으로 인간 형태로 돌아가는 키이기도 합니다. 기본 possession 키는 **G**이며 모드 설정에서 변경할 수 있습니다.
10. TAB을 눌러도 아무 반응이 없다면 먼저 세 가지를 확인하세요: 6단계의 `mod.xml` 경로, **Unsafe mods** 활성화 여부, MCM 활성화 후 Noita를 재시작했는지 여부입니다.

**MCM 업데이트:** Noita를 종료하고 기존 `metamorph_creative_menu` 폴더를 삭제한 뒤 새 폴더를 `mods`에 복사하세요. 폴더 전체를 교체하면 이전 버전 파일이 남는 것을 방지할 수 있습니다.

**Entangled Worlds는 선택 사항입니다.** 싱글플레이에서는 EW가 필요하지 않습니다. 멀티플레이에서는 모든 플레이어가 같은 MCM 버전을 사용하고 호환되는 Entangled Worlds를 별도로 설치하세요.

### 요구 사항 및 설치

- Noita.
- `Noita/mods/` 안의 `metamorph_creative_menu` 폴더.
- Noita 모드 메뉴에서 **Unsafe mods / unrestricted API**를 켜야 합니다. 포함된 네이티브 **NoitaPatcher**가 이 권한을 사용합니다.
- Entangled Worlds는 **선택 사항**입니다.

1. [Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases)에서 빌드를 받거나 저장소를 다운로드/clone합니다.
2. `metamorph_creative_menu` 전체를 `Noita/mods/`에 복사합니다.
3. `Noita/mods/metamorph_creative_menu/mod.xml`이 있는지 확인합니다.
4. Unsafe mods를 켠 뒤 Metamorph: Creative Menu를 활성화합니다.

내부 모드 폴더 이름은 바꾸지 마세요.

### 소개

**Metamorph: Creative Menu (MCM)** 는 **Noita**용 크리에이티브/개발자 메뉴입니다. 싱글플레이에서는 독립적으로 동작하며, 선택적으로 **Entangled Worlds / Noita Proxy**와의 실험적 호환 기능을 제공합니다.

완드 편집, 아이템 생성/획득, 퍽과 효과 적용/제거, 생물 변신, 커서 아래의 기존 생물 점유, 날씨와 월드 규칙 변경, 플레이어와 비슷한 동료 생성 등을 지원합니다.

### 기능

#### 주문/완드 편집
완드를 들고 슬롯을 선택한 뒤 검색/카테고리 목록에서 주문을 고릅니다. 교체, 삭제, 월드에 드롭할 수 있습니다. 교체 시 새 주문이 정상적으로 부착되었는지 확인한 뒤 기존 주문을 제거합니다.

#### 아이템
용기, 액체, 돌, 알, 완드, 책, 보너스, 오브, 퀘스트 아이템 등.
- **좌클릭:** 근처 생성.
- **우클릭:** 적절한 인벤토리 슬롯에 직접 넣기 시도.
- 공간 부족/픽업 실패 시 아이템을 월드에 남깁니다.
- 액체가 채워진 플라스크/용기도 지원합니다.

#### 퍽
- **ADD:** 좌클릭은 일반 pickup 생성, 우클릭은 직접 적용.
- **REMOVE:** 좌클릭은 1스택 제거, 우클릭은 전체 제거 시도.
MCM은 퍽이 만든 여러 변경을 추적해 다른 시스템의 상태를 의도적으로 덮어쓰지 않으면서 엔티티/컴포넌트/값을 되돌리려 합니다. 안전한 역연산이 없으면 위험한 제거를 거부할 수 있습니다.

#### 검색
큰 카탈로그는 번역된 이름, ID 및/또는 설명으로 검색할 수 있습니다.

#### 생물, 오브젝트, 형태
- **좌클릭:** 생성.
- **우클릭:** 변신.
- **TAB:** 인간.

호환성은 정확한 XML 경로 기준으로 관리됩니다. 일부 알려진 위험 placement wrapper는 변신할 때만 안전한 canonical target으로 라우팅됩니다. 플레이어 형태는 가능한 한 유용한 네이티브 공격, 이동, 외형, 물리를 유지하고 플레이어 조작과 충돌하는 AI를 끕니다. 복잡한 엔티티는 근사 adapter를 사용할 수 있습니다.

#### 인간 복귀와 형태 사망
일반 TAB 복귀는 먼저 Noita의 네이티브 polymorph lifecycle을 사용합니다. 또한 MCM은 NoitaPatcher를 통해 인간의 직렬화 백업을 유지합니다.

치명적 피해 시 **death handoff**를 시도하여 현재 생물 몸은 죽게 두고 플레이어 권한은 복원된 인간에게 넘깁니다. 따라서 변신 몸의 죽음이 자동으로 run 전체 종료로 이어지지 않도록 합니다.

#### 점유(Possession)
호환 생물을 가리키고 **G**를 누릅니다. MCM은 해당 대상의 호환 형태를 사용하고 원래 대상을 retire/제거하여 단순 복제 생성을 피합니다.

#### PLAYER 동료
`PLAYER` 항목에서 플레이어와 비슷한 아군을 만들 수 있습니다. 필요한 NoitaPatcher 기능이 있으면 복사한 완드를 실제 플레이어에 더 가깝게 사용할 수 있습니다.

#### 효과
상태/시간제 효과를 적용하고 지원되는 경우 지속시간을 고르며, 에디터 소유가 아닌 내부/퍽 상태를 가능한 한 보존하면서 제거합니다.

#### 날씨
시간 프리셋: 아침, 낮, 저녁, 밤. 날씨: 맑음, 흐림, 안개, 폭풍. Advanced 모드는 시간, 구름, 안개, 바람, 풍속, 비, 번개 관련 지원 값을 조절합니다. **RELEASE**는 MCM이 override를 계속 유지하는 것을 중단합니다.

#### 월드 규칙
규칙은 **되돌릴 수 있는 override**입니다. `NATIVE`/RESET은 MCM이 기록한 baseline을 복구하며, 중요한 규칙은 영구 recovery 데이터를 사용합니다.

현재 규칙:

- 생물 관계
- 금이 사라지지 않음
- 주문 사용 횟수 무제한
- 전장의 안개 해제
- 트릭 킬 피의 돈
- 회복 드롭 확률
- 우호적인 쥐
- 유혈량
- 트릭 킬 골드
- 피해 플래시
- 얼룩 제거
- 세계 중력
- 물리 감쇠
- 피의 양
- 발차기 힘
- 관절 강도
- 낮밤 주기 속도

물리 규칙은 로드되었거나 가까운 엔티티/물리 바디에 적용되며, 무한 월드의 모든 비로드 대상을 즉시 수정하지는 않습니다.

### 싱글플레이와 Entangled Worlds

**싱글플레이에는 EW가 필요하지 않습니다.** MCM은 자체 NoitaPatcher와 로컬 Base64 codec을 포함합니다.

`quant.ew` 활성 시 월드 아이템, 퍽, 날씨, 규칙, 형태/점유, 동료, 호환 patch의 실험적 통합이 켜집니다. EW가 이미 호환 NoitaPatcher API를 제공하면 MCM이 재사용할 수 있습니다.

멀티플레이 지원은 **실험적/부분적**입니다. host와 client가 같은 MCM 사용자 권한을 갖는 것이 목표지만 모든 Noita/EW edge case를 보장하지 않습니다. 모든 peer는 같은 MCM 버전을 사용하세요.

### 문제 해결 및 버그 제보

- 메뉴가 안 열림: 경로와 모드 활성화를 확인.
- 확장 기능이 없음: Unsafe mods 및 `NoitaPatcher/noitapatcher.dll` 확인.
- 특정 형태 문제: 정확한 이름/XML과 TAB 복귀/사망 복귀 중 무엇이 실패했는지 기록.
- EW 문제: MCM/EW 버전을 함께 기록.

[GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)에 재현 단계와 로그를 올려 주세요.

### 외부 구성 요소 및 크레딧

MCM은 **NoitaPatcher**(dextercd), **lbase64**(Ilya Kolbin)을 포함하며 선택적으로 **Noita Entangled Worlds**(IntQuant 및 기여자)와 연동합니다. 자세한 경로/용도/라이선스 상태는 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)를 참조하세요.

### 링크

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

### 개발

플레이 가능한 모드는 `metamorph_creative_menu/`, 테스트/contract는 `metamorph_creative_menu/tests/`에 있습니다. MCM 자체 코드에 대한 저장소 전체 라이선스는 아직 선택되지 않았습니다.

[↑ Back to language selection](#languages)

---
