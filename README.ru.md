<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">
  Творческий набор инструментов для Noita: заклинания, жезлы, предметы, материалы, перки, существа, эффекты, телепортация, погода и правила мира.
</p>

<a id="languages"></a>

[English](README.md) · [**Русский**](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## Скачать

Текущая версия: **2.0.0**

| Пакет | Ссылка |
|---|---|
| **Последняя готовая сборка** | **[⬇️ Скачать Metamorph-Creative-Menu.zip](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)** |
| Страница сборки | [Последняя готовая сборка](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) |

> ZIP уже содержит готовую папку `metamorph_creative_menu`, включая встроенный NoitaPatcher. Её нужно распаковать прямо в `Noita/mods/`.

Правильный итоговый путь:

```text
Noita/mods/metamorph_creative_menu/mod.xml
```

Если получился путь `metamorph_creative_menu/metamorph_creative_menu/mod.xml`, архив был распакован на один уровень глубже, чем нужно.

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

- **F4 или TAB**: открыть или закрыть Creative Menu.
- **TAB во время превращения**: вернуться в человеческую форму.
- **G** по умолчанию: взять под управление существо под курсором.
- **Средняя кнопка мыши**: рисовать выбранным материалом.
- Назначения можно изменить в разделе CONTROLS или в настройках мода. Доступные действия ЛКМ и ПКМ показываются в интерфейсе.

### Возможности MCM

- Получение и размещение заклинаний, а также их перенос между жезлом, постоянными заклинаниями, инвентарём и игровым миром.
- Изменение характеристик, внешнего вида и блокировок жезлов; сохранение жезлов и создание копий.
- Создание предметов рядом с игроком или в выбранной точке мира и добавление поддерживаемых предметов в инвентарь.
- Создание бутылок с выбранными жидкостями.
- Выбор материалов и рисование ими в игровом мире.
- Создание, добавление и удаление перков.
- Создание существ рядом с игроком или в выбранной точке мира.
- Превращение в существ, управление существами в мире и возврат в человеческую форму.
- Создание отдельной сущности PLAYER.
- Применение и удаление игровых эффектов.
- Изменение погоды, времени суток, гравитации и других правил мира.
- Телепортация в игровые локации.
- При использовании Entangled Worlds телепортация к игрокам и перемещение игроков к себе.
- Изменение назначений клавиш и поиск по каталогам заклинаний, предметов, материалов, перков и существ.
- Перемещение и изменение размера окна меню с сохранением положения между запусками игры.

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

## Для разработчиков

Игровой мод находится в папке `metamorph_creative_menu/`.

- Архитектура и заметки для разработчиков: `metamorph_creative_menu/README.txt`
- Набор регрессионных тестов: `metamorph_creative_menu/tests/`
- Инструкции по тестированию: `metamorph_creative_menu/tests/TESTING.txt`
- Сведения о сторонних компонентах: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)

Автоматический workflow `latest-build` упаковывает игровую папку `metamorph_creative_menu` в готовый к установке ZIP и обновляет стабильную ссылку на скачивание выше.