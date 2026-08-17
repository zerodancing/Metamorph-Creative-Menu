# Metamorph: Creative Menu — Deutsch

[English](README.en.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es-ES.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## Über den Mod

**Metamorph: Creative Menu (MCM)** ist ein Creative-/Entwicklermenü für **Noita**. Es funktioniert eigenständig im Einzelspieler und bietet zusätzlich eine optionale experimentelle Kompatibilität mit **Entangled Worlds / Noita Proxy**.

MCM kann Zauberstäbe bearbeiten, Gegenstände erzeugen/aufnehmen, Perks und Effekte anwenden bzw. entfernen, den Spieler in Kreaturen verwandeln, eine existierende Kreatur unter dem Mauszeiger übernehmen, Wetter und Weltregeln ändern und einen spielerähnlichen Begleiter erzeugen.

## Voraussetzungen und Installation

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

## Steuerung

- **TAB** — Menü öffnen/schließen.
- **TAB in einer Form** — zur menschlichen Form zurückkehren.
- **G** standardmäßig — kompatible Kreatur unter dem Mauszeiger übernehmen; in den Einstellungen änderbar.
- LMB/RMB führen je nach Tab unterschiedliche, im UI angezeigte Aktionen aus.

## Funktionen

### Zauber
Zauberstab halten, Slot auswählen und einen Zauber aus dem durchsuchbaren Katalog wählen. Zauber können ersetzt, gelöscht oder in die Welt geworfen werden. Beim Ersetzen wird der neue Zauber geprüft, bevor der alte entfernt wird.

### Gegenstände
Kategorien: Behälter, Flüssigkeiten, Steine, Eier, Zauberstäbe, Bücher, Boni, Orbs, Questgegenstände und weitere.
- **LMB:** in der Nähe erzeugen.
- **RMB:** direkt in einen passenden Inventarslot aufnehmen.
- Bei vollem Inventar/fehlgeschlagenem Pickup bleibt der Gegenstand in der Welt.
- Gefüllte Flaschen/Behälter werden unterstützt.

### Perks
- **ADD:** LMB erzeugt den normalen Pickup, RMB wendet direkt an.
- **REMOVE:** LMB entfernt einen Stack, RMB versucht alle zu entfernen.
MCM verfolgt viele perk-eigene Änderungen, um Entitäten, Komponenten und Werte wiederherzustellen, ohne absichtlich fremde Zustände zu überschreiben. Bei fehlender sicherer Umkehrung wird eine riskante Entfernung eher abgelehnt.

### Suche
Große Kataloge können nach übersetztem Namen, ID und/oder Beschreibung durchsucht werden.

### Kreaturen, Objekte und Formen
- **LMB:** erzeugen.
- **RMB:** verwandeln.
- **TAB:** Mensch.

Kompatibilität wird pro exaktem XML-Pfad verwaltet. Einige bekannte gefährliche Placement-Wrapper verwenden nur für die Transformation ein sicheres kanonisches Ziel. Spielerformen versuchen native Angriffe, Bewegung, Darstellung und Physik zu erhalten, während konkurrierende KI deaktiviert wird. Komplexe Entitäten können approximative Spezialadapter verwenden.

### Menschliche Rückkehr und Tod einer Form
TAB verwendet zuerst Noitas nativen Polymorph-Lebenszyklus. Zusätzlich hält MCM über NoitaPatcher ein serialisiertes Backup des Menschen.

Bei tödlichem Schaden versucht **Death Handoff**, die Kreaturenform sterben zu lassen und die Spielerautorität auf den wiederhergestellten Menschen zu übertragen, damit der Tod der Form nicht automatisch den Run beendet.

### Besitzergreifung
Kompatible Kreatur anvisieren und **G** drücken. MCM nutzt eine kompatible Form des Ziels und entfernt/retired das ursprüngliche Ziel, statt nur eine Kopie daneben zu erzeugen.

### PLAYER-Begleiter
Der Eintrag `PLAYER` kann einen spielerähnlichen Verbündeten erzeugen. Mit passenden NoitaPatcher-Fähigkeiten kann der Begleiter den kopierten Zauberstab näher am echten Spieler verwenden.

### Effekte
Status-/Zeiteffekte anwenden, wenn möglich Dauer wählen und Effekte entfernen, wobei geschützte interne/Perk-Zustände möglichst unangetastet bleiben.

### Wetter
Zeit-Presets: Morgen, Tag, Abend, Nacht. Wetter: klar, bewölkt, neblig, Sturm. Advanced kontrolliert unterstützte Werte für Zeit, Wolken, Nebel, Wind, Windgeschwindigkeit, Regen und Blitze. **RELEASE** beendet das aktive Halten des Overrides.

### Weltregeln
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

## Einzelspieler und Entangled Worlds

**EW ist für Einzelspieler nicht erforderlich.** MCM enthält NoitaPatcher und einen lokalen Base64-Codec.

Mit aktivem `quant.ew` wird die experimentelle Integration für Weltgegenstände, Perks, Wetter, Regeln, Formen/Übernahme, Begleiter und Compatibility-Patches aktiviert. Eine bereits von EW bereitgestellte kompatible NoitaPatcher-API kann wiederverwendet werden.

Netzwerkunterstützung ist **experimentell/teilweise**. Host und Client sollen dieselben MCM-Benutzerrechte haben, aber nicht jeder Noita/EW-Sonderfall kann garantiert synchronisiert werden. Alle Spieler sollten dieselbe MCM-Version verwenden.

## Fehlerbehebung

- Menü fehlt: Pfad und Aktivierung prüfen.
- Erweiterte Funktionen fehlen: Unsafe mods aktivieren und `NoitaPatcher/noitapatcher.dll` prüfen.
- Defekte Form: exakten Namen/XML und Art des Rückkehrfehlers angeben.
- EW: MCM- und EW-Versionen angeben.

Fehler unter [GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues) melden.

## Abhängigkeiten und Credits

MCM enthält **NoitaPatcher** (dextercd) und **lbase64** (Ilya Kolbin) und integriert optional **Noita Entangled Worlds** (IntQuant und Contributors). Details: [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

## Links

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

## Entwicklung

Spielbarer Mod: `metamorph_creative_menu/`. Tests/Contracts: `metamorph_creative_menu/tests/`. Für den ursprünglichen MCM-Code wurde noch keine allgemeine Projektlizenz gewählt.
