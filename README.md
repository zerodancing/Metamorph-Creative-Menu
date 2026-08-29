<a id="languages"></a>

[**English**](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">A creative menu and toolkit for Noita: spells, wands, items, materials, perks, creatures, transformations, effects, teleportation, weather, world rules and much more.</p>

<p align="center"><strong>Version 2.0.0</strong></p>

---

# Download

[**⬇️ Download the latest version of the mod**](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)

Current version: **2.0.0**

**The full version requires Unsafe Mods to be allowed.**

[Latest build page](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build)

[Version 2.0.0 changelog](metamorph_creative_menu/CHANGELOG.txt)

# Contents

- [Installation](#installation)
- [Full version and Steam Workshop version](#full-version-and-steam-workshop-version)
- [About the mod](#about-the-mod)
- [Controls and interface](#controls-and-interface)
- [Spells](#spells)
- [Wands](#wands)
- [Items and liquids](#items-and-liquids)
- [Materials](#materials)
- [Perks](#perks)
- [Effects](#effects)
- [Creatures and transformations](#creatures-and-transformations)
- [Returning after a transformation and form death](#returning-after-a-transformation-and-form-death)
- [Possessing a creature](#possessing-a-creature)
- [Player](#player)
- [Weather and time](#weather-and-time)
- [World rules](#world-rules)
- [Teleportation](#teleportation)
- [Entangled Worlds](#entangled-worlds)
- [NoitaPatcher and Unsafe Mods](#noitapatcher-and-unsafe-mods)
- [Troubleshooting](#troubleshooting)
- [Report a bug](#report-a-bug)

# Installation

1. [Download the latest version of the mod](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Launch Noita and open **Mods** from the main menu.
3. Click **Open mods folder**.
4. Move the `metamorph_creative_menu` folder from the downloaded archive into the opened `mods` folder. If `metamorph_creative_menu` is already there, delete the old folder and replace it with the new one.
5. Close the mods folder.
6. In the Mods menu, click **Refresh**. **Metamorph: Creative Menu** should appear in the list.
7. Click **Unsafe Mods** until the text turns red and reads **Unsafe Mods: Allowed**.
8. Click the mod name so that it becomes highlighted and **[x]** appears before it. This means the mod is enabled.
9. Click **Start a new game with active mods**.
10. Choose a game mode and play.

# Full version and Steam Workshop version

The build available on this GitHub page is the full version of MCM. It includes NoitaPatcher and features that require Unsafe Mods permission.

The [Steam Workshop version](https://steamcommunity.com/sharedfiles/filedetails/?id=3785170245) is installed separately. It does not include NoitaPatcher or the full-version features that require Unsafe Mods access.

Do not install and enable both versions at the same time.

# About the mod

**Metamorph: Creative Menu (MCM)** is a creative menu and toolkit for Noita.

It brings spells, wands, items, materials, perks, effects, creatures, transformations, weather, global world rules and teleportation together in one interface.

MCM is suitable both for free-form creative play and for experimenting with Noita's mechanics. Many operations are not handled as simple spawning: they take the existing state of a wand, item, form, perk or world into account.

**Entangled Worlds is not required.** Without it, MCM works as a complete single-player mod. When Entangled Worlds is installed, additional experimental multiplayer features become available.

# Controls and interface

| Action | Key |
| --- | --- |
| Open / close creative menu | **F4 or TAB** |
| Return to human form | **TAB while transformed** |
| Possess a creature | **G** |
| Paint with the selected material | **Middle mouse button** |

The MCM panel is also available through the regular inventory interface.

Bindings can be changed in **CONTROLS** or in the mod settings.

While assigning a binding:

- **DELETE / BACKSPACE** — clear the binding;
- **ESC** — cancel;
- **R** — restore the default binding;
- **RESET ALL** — restore all default bindings after confirmation.

If the same binding is assigned to multiple actions, MCM shows a conflict.

## Creative Menu window

The window can be:

- moved;
- resized horizontally and vertically;
- resized from its edges and corners;
- minimized;
- closed;
- restored to its default layout.

Its size, position and last open section are saved between game launches.

Large catalogs use scrolling and automatically adapt to the current window size.

## Search

Search is available in the catalogs for:

- spells;
- items;
- materials;
- perks;
- creatures.

It can use not only the displayed name, but also the English name, localization key, technical identifier or XML path.

Search is case-insensitive and tolerates small spelling mistakes in sufficiently long words.

The MCM interface is localized into 11 languages. For regular game content, Noita's own translations are reused whenever possible.

# Spells

The spell section lets you work not only with the catalog, but also with the player's existing spells.

At the same time, it shows:

- the active wand slots;
- **ALWAYS CAST**;
- the spell inventory;
- the spell catalog.

## Quick replacement

Select a specific wand slot, then LMB-click the desired spell in the catalog. It will be placed into the selected slot.

## Drag and drop

Existing spells can be moved:

- between wand slots;
- into **ALWAYS CAST**;
- from **ALWAYS CAST** back into ordinary slots;
- into specific spell-inventory slots;
- from the inventory back onto the wand;
- into the game world;
- into the trash.

For existing cards, MCM tries to move the actual game entity instead of creating a new copy. This preserves card state that may have been modified by the game or another mod.

The source spell remains in place until the destination is confirmed. A failed or invalid operation should not destroy the original card.

## Always Cast

Permanent spells have their own **ALWAYS CAST** area.

When moving spells between ordinary slots and **ALWAYS CAST**, wand capacity is taken into account so the ordinary slot structure remains valid.

## Undo / Redo

A limited **UNDO / REDO** history is available for internal wand changes.

It applies to operations that can safely be restored from the wand's own state.

Moving an actual spell entity into the world or the regular game inventory cannot always be reversed by restoring a single state snapshot, so those actions cannot always be undone.

# Wands

MCM includes a full editor for the active wand.

You can change:

- **SLOTS**;
- **SPELLS/CAST**;
- **RECHARGE**;
- **CAST DELAY**;
- **SPREAD**;
- **SPEED**;
- **MANA MAX**;
- **MANA CHARGE**;
- **RECOIL REC.**;
- **LEVEL**;
- **SHUFFLE**;
- **NO RELOAD**.

You can also change appearance-related settings:

- the displayed name;
- locks;
- the wand image;
- image offsets;
- the firing point.

A visual catalog of wand appearances is also available.

## Wand presets

A wand can be saved and its stored state used later.

The saved state includes:

- stats;
- mana;
- appearance;
- ordinary spells;
- **ALWAYS CAST**;
- card positions;
- remaining uses;
- frozen card state.

Saved wands remain available across game worlds and later Noita launches.

### Apply

**APPLY** applies the saved state to the wand currently held by the player.

### Get copy

**GET COPY** creates a separate copy of the saved wand.

If a suitable quick-inventory slot is free, the new wand is placed there. Otherwise it is created near the player in the game world.

If creation cannot be completed correctly, MCM attempts to remove the incomplete entity.

# Items and liquids

## Items

**LMB** on a catalog entry creates one item near the player.

**RMB** attempts to place the item directly into the inventory.

An item can also be dragged:

- into a suitable quick-inventory area;
- outside the menu to a selected point in the game world.

If the card is released inside the menu without a valid destination, the operation is canceled.

Catalog entries are templates, so the entry itself does not disappear after an item is created.

MCM respects Noita's normal division of the quick inventory into wand and item slots and should not replace an existing item without a reason.

## Liquids

MCM can create real in-game containers filled with a selected liquid.

The created container behaves like a normal Noita item:

- it can be stored in the inventory;
- dropped into the world;
- broken;
- spill its contents;
- participate in normal material reactions.

# Materials

The material catalog is built from substances registered in the current Noita instance.

It includes different material types, such as:

- liquids;
- powders;
- gases;
- fire;
- solid materials;
- static materials;
- materials with special rendering.

If another active mod correctly adds its own material to Noita, it can also appear in MCM.

## Painting with materials

1. Select a material.
2. Select the brush size.
3. Click **START PAINTING**.
4. Close the inventory.
5. Hold the assigned painting button in the game world.

The default is the **middle mouse button**.

Opening the inventory stops painting mode.

## Material behavior

MCM creates real materials in the game world rather than decorative particles.

After being placed, they continue to follow Noita's normal simulation:

- liquids flow;
- powders fall;
- gases spread;
- fire interacts with the environment;
- substances react with one another;
- unstable materials can transform into other materials.

For different material types, MCM uses appropriate placement methods, including additional NoitaPatcher capabilities for cases that cannot be handled correctly with ordinary modding tools.

# Perks

## Spawning a perk

**LMB** creates the selected perk in the game world.

It can be picked up like a normal Noita perk.

## Receiving perks

MCM can grant the selected perk:

- 1 time;
- 10 times;
- 100 times.

Bulk granting is processed gradually so a large number of applications are not performed in a single frame.

The interface shows progress, and further processing can be canceled. Copies that were already granted before cancellation remain on the player.

## Removing perks

Safely removing a perk is much more complicated than granting it.

Some perks modify several game systems at once, create entities or start effects for which there is no single universal undo operation.

MCM therefore removes only supported changes for which it can perform a sufficiently reliable reverse operation.

The mod tries to reverse the state created by that specific perk application without unnecessarily resetting other effects or player state.

# Effects

MCM can apply and remove supported:

- game effects;
- material-related statuses.

When removing them, the mod tries not to affect unrelated states owned by perks or other game systems.

This allows MCM-owned effects to be cleared without indiscriminately deleting every similar state on the player.

# Creatures and transformations

## Spawning creatures

**LMB** creates the selected creature near the player.

A creature card can also be dragged outside the menu to create it at a selected point in the game world.

**RMB** on a supported entry attempts to transform the current player into the corresponding form.

## Form compatibility

Noita creatures differ greatly in their internal structure.

MCM therefore distinguishes transformation targets by exact XML path and does not automatically treat all similarly named entities as interchangeable.

During a transformation, MCM uses the capabilities of the selected form and applies separate compatibility rules for specific creatures when needed.

# Returning after a transformation and form death

You can return to human form with the assigned action — **TAB by default**.

MCM first uses Noita's normal transformation-ending mechanisms. For more difficult cases, additional restoration through NoitaPatcher is available.

The mod also handles supported situations where a temporary form takes fatal damage.

In those cases, MCM attempts to:

- leave the dead form's corpse behind;
- restore the human player;
- return control;
- preserve the inventory;
- restore relevant player state.

This is not absolute immortality. Unusual third-party death methods, incompatible mods or an internal Noita failure can bypass the normal recovery mechanism.

# Possessing a creature

Besides choosing a form from the catalog, MCM can take control of a **creature that already exists in the game world**.

The default key is **G**.

Point at a suitable target and use the assigned action.

MCM checks the creature, transforms the player into a compatible form and only removes the original entity after the transition has been confirmed successful.

If the transformation does not succeed, the original creature should not simply disappear.

This feature is not limited to MCM's static catalog. A suitable creature added by another mod can also pass the check, although universal compatibility with every third-party entity is not guaranteed.

# Player

**PLAYER** is a special entry in the creature catalog.

It is not a normal transformation form.

**LMB** creates a separate character for which MCM attempts to copy:

- the player's appearance;
- maximum health.

**RMB** on **PLAYER** does not transform a human player into this entity.

If the player is already in human form, the action does nothing. If the player is currently transformed into another creature, it returns them to human form.

# Weather and time

MCM can change:

- time of day;
- weather presets;
- individual supported weather parameters.

A state can be set and later released from MCM control.

For example, after forcing a specific time, you can return control to Noita so the natural flow of time resumes.

# World rules

The **RULES** section is intended for deeper changes to the behavior of the game world.

Depending on the specific rule, it can control parameters such as:

- creature relationships;
- gold;
- spell use;
- fog of war;
- rewards for particular types of kills;
- healing drops;
- blood;
- gravity;
- physics behavior;
- kick force;
- physics joints;
- the day-night cycle;
- other supported global parameters.

The main feature is that MCM rules are designed as **reversible changes**.

For supported settings, the mod keeps the original state and allows the values to be returned to normal.

When a rule uses a multiplier, the new value is calculated relative to the original state instead of repeatedly multiplying an already modified result.

Operations that need to modify many entities or physics objects are processed gradually rather than trying to update the entire world directly from a single menu click.

# Teleportation

MCM can quickly move the player to prepared world destinations, including locations along:

- the main route;
- Holy Mountains;
- major side areas;
- other supported locations.

Before teleporting, the mod can load the destination area and tries to find nearby free space instead of placing the player directly inside a solid wall or other obstacle.

# Entangled Worlds

**Entangled Worlds / Noita Proxy is optional.**

MCM works fully in single-player without it.

When Entangled Worlds is installed, additional experimental multiplayer features are enabled.

For the best compatibility, all participants should use the same version of MCM.

## Items, wands and spells

Where possible, world items and dropped spells use the standard Entangled Worlds mechanisms.

Inventory changes can also be transferred through Entangled Worlds.

## Perks

A perk spawned by MCM remains a real game entity and, where possible, is transferred through Entangled Worlds' normal world-item system.

## Materials

Material painting has experimental multiplayer support.

MCM synchronizes affected areas of the world so the result can appear for other participants.

For this to work correctly, the corresponding material must also exist for the other player. If mod sets differ, identical material rendering cannot be guaranteed.

## Weather and world rules

Supported weather and global rule changes can be synchronized through Entangled Worlds.

## Transformations and creature possession

Transformations have additional support when Entangled Worlds is used.

When possessing an existing creature, the mod also takes the target's network state into account. If MCM cannot determine reliably enough that the original entity can be removed, it prefers to leave it in place.

## Player

Creating the special **PLAYER** entity is also supported when playing through Entangled Worlds. In that case, it copies the skin colors of the player who created it.

## Teleporting between players

When Entangled Worlds is active, available network players appear in the **TELEPORTATION** section.

**GO TO** moves you to the selected player.

**BRING HERE** sends the selected player a request to move to you.

In both cases, MCM tries to use free space near the destination.

## Limitations

Entangled Worlds support remains experimental.

**In multiplayer, transforming into large or multi-jointed bosses can cause a critical performance drop and effectively break the current game session.**

Noita is extremely difficult to synchronize completely, especially when several of these are changing at the same time:

- the pixel world;
- materials;
- physics objects;
- complex creatures and bosses;
- content from other mods.

MCM therefore does not promise perfect synchronization of every possible state.

# NoitaPatcher and Unsafe Mods

The full version of MCM includes **NoitaPatcher**.

It is used for capabilities that are not available through Noita's ordinary modding tools, including parts of:

- recovery after complex transformations;
- working with game entities;
- working with the game world;
- placing certain materials;
- extended compatibility.

The full version therefore requires **Unsafe Mods** to be allowed.

NoitaPatcher is already included in the ready-to-install MCM build. It does not need to be installed separately.

# Troubleshooting

## MCM does not load

Make sure the following file exists after extraction:

```text
Noita/mods/metamorph_creative_menu/mod.xml

```

Check that:

- MCM is enabled in **Mods**;
- **[x]** appears next to it;
- **Unsafe Mods: Allowed** is enabled;
- the game was started with active mods.

## NoitaPatcher-dependent features do not work

Check that this file exists:

```text
metamorph_creative_menu/NoitaPatcher/noitapatcher.dll

```

and make sure **Unsafe Mods** are allowed.

## Cannot return from a form

Try the assigned return action — **TAB by default**.

If the problem happens again, a useful bug report should include:

- the exact creature name;
- the XML path, if known;
- how the form was obtained;
- whether normal return works;
- whether the problem happens only after fatal damage;
- whether Entangled Worlds is being used.

## Entangled Worlds problems

Check:

- that all participants use the same MCM version;
- that the Entangled Worlds versions are compatible;
- that everyone has the same relevant mods if the problem involves materials or creatures from other mods.

# Report a bug

[Create an Issue](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)

For a useful report, please include:

- the MCM version;
- what you were doing;
- the expected result;
- the actual result;
- the name of the creature, item, perk or material involved;
- whether Entangled Worlds is being used;
- other mods that may be related to the problem;
- the error text or relevant log excerpt;
- a screenshot or video if it helps demonstrate the problem.

# Third-party components

- **Noita** — Nolla Games.
- **NoitaPatcher** — dextercd, included in the full version.
- **lbase64** — Ilya Kolbin, included in MCM.
- **Entangled Worlds / Noita Proxy** — IntQuant and project contributors, installed separately and optional.

Detailed information about upstream projects and licenses is available in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

---

**Metamorph: Creative Menu** is an unofficial user-created mod for Noita. The project is not affiliated with Nolla Games and is not an officially supported part of the game.

[↑ Back to language selection](#languages)
