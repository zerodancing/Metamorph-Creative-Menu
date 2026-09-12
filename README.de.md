<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es.md) · [**Deutsch**](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">Ein Kreativmenü und Werkzeugpaket für Noita: Zauber, Zauberstäbe, Gegenstände, Materialien, Perks, Kreaturen, Verwandlungen, Effekte, Teleportation, Wetter, Weltregeln und vieles mehr.</p>

<p align="center"><strong>Version 2.0.0</strong></p>

---

# Herunterladen

[**⬇️ Neueste Version des Mods herunterladen**](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)

Aktuelle Version: **2.0.0**

**Für die Vollversion müssen unsichere Mods erlaubt sein.**

[Seite des neuesten Builds](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build)

[Änderungsliste für Version 2.0.0](metamorph_creative_menu/CHANGELOG.txt)

# Inhalt

- [Installation](#installation)
- [Vollversion und Steam-Workshop-Version](#vollversion-und-steam-workshop-version)
- [Über den Mod](#über-den-mod)
- [Steuerung und Oberfläche](#steuerung-und-oberfläche)
- [Zauber](#zauber)
- [Zauberstäbe](#zauberstäbe)
- [Gegenstände und Flüssigkeiten](#gegenstände-und-flüssigkeiten)
- [Materialien](#materialien)
- [Perks](#perks)
- [Effekte](#effekte)
- [Kreaturen und Verwandlungen](#kreaturen-und-verwandlungen)
- [Rückkehr nach einer Verwandlung und Tod der Form](#rückkehr-nach-einer-verwandlung-und-tod-der-form)
- [Kreaturen übernehmen](#kreaturen-übernehmen)
- [Spieler](#spieler)
- [Wetter und Zeit](#wetter-und-zeit)
- [Weltregeln](#weltregeln)
- [Teleportation](#teleportation)
- [Entangled Worlds](#entangled-worlds)
- [NoitaPatcher und unsichere Mods](#noitapatcher-und-unsichere-mods)
- [Wenn etwas nicht funktioniert](#wenn-etwas-nicht-funktioniert)
- [Fehler melden](#fehler-melden)

# Installation

1. [Lade die neueste Version des Mods herunter](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Starte Noita und öffne im Hauptmenü **Mods**.
3. Klicke auf **Mod-Ordner öffnen**.
4. Verschiebe den Ordner `metamorph_creative_menu` aus dem heruntergeladenen Archiv in den geöffneten Ordner `mods`. Falls `metamorph_creative_menu` dort bereits vorhanden ist, lösche den alten Ordner und ersetze ihn durch den neuen.
5. Schließe den Mod-Ordner.
6. Klicke im Mod-Menü auf **Aktualisieren**. **Metamorph: Creative Menu** sollte nun in der Liste erscheinen.
7. Klicke auf **Unsichere Mods**, bis der Text rot wird und **Unsichere Mods: Erlaubt** anzeigt.
8. Klicke auf den Namen des Mods, sodass er hervorgehoben wird und **[x]** davor erscheint. Das bedeutet, dass der Mod aktiviert ist.
9. Klicke auf **Neues Spiel mit aktiven Mods starten**.
10. Wähle einen Spielmodus und spiele.

# Vollversion und Steam-Workshop-Version

Der auf dieser GitHub-Seite verfügbare Build ist die Vollversion von MCM. Er enthält NoitaPatcher und Funktionen, für die unsichere Mods erlaubt sein müssen.

Die [Steam-Workshop-Version](https://steamcommunity.com/sharedfiles/filedetails/?id=3785170245) wird separat installiert. Sie enthält weder NoitaPatcher noch die Funktionen der Vollversion, die den Zugriff unsicherer Mods benötigen.

Installiere und aktiviere nicht beide Versionen gleichzeitig.

# Über den Mod

**Metamorph: Creative Menu (MCM)** ist ein Kreativmenü und Werkzeugpaket für Noita.

Es vereint Werkzeuge für Zauber, Zauberstäbe, Gegenstände, Materialien, Perks, Effekte, Kreaturen, Verwandlungen, Wetter, globale Weltregeln und Teleportation in einer Oberfläche.

MCM eignet sich sowohl für freies kreatives Spielen als auch zum Experimentieren mit den Mechaniken von Noita. Viele Vorgänge bestehen nicht einfach darin, eine neue Entität zu erzeugen, sondern berücksichtigen den bereits vorhandenen Zustand eines Zauberstabs, Gegenstands, einer Form, eines Perks oder der Welt.

**Entangled Worlds ist nicht erforderlich.** Ohne Entangled Worlds funktioniert MCM vollständig als Einzelspieler-Mod. Ist Entangled Worlds installiert, stehen zusätzliche experimentelle Mehrspielerfunktionen zur Verfügung.

# Steuerung und Oberfläche

| Aktion | Taste |
| --- | --- |
| Kreativmenü öffnen / schließen | **F4 oder TAB** |
| Zur Menschenform zurückkehren | **TAB während einer Verwandlung** |
| Eine Kreatur übernehmen | **G** |
| Mit dem ausgewählten Material malen | **Mittlere Maustaste** |

Das MCM-Fenster ist außerdem über die normale Inventaroberfläche verfügbar.

Tastenbelegungen können im Bereich **STEUERUNG** oder in den Mod-Einstellungen geändert werden.

Beim Zuweisen einer Taste:

- **DELETE / BACKSPACE** — Belegung löschen;
- **ESC** — abbrechen;
- **R** — Standardbelegung wiederherstellen;
- **ALLES ZURÜCKSETZEN** — nach Bestätigung alle Standardbelegungen wiederherstellen.

Wenn dieselbe Kombination mehreren Aktionen zugewiesen ist, zeigt MCM einen Konflikt an.

## Fenster des Kreativmenüs

Das Fenster kann:

- verschoben werden;
- in Breite und Höhe verändert werden;
- an Kanten und Ecken skaliert werden;
- minimiert werden;
- geschlossen werden;
- auf die Standardanordnung zurückgesetzt werden.

Größe, Position und der zuletzt geöffnete Bereich werden zwischen Spielstarts gespeichert.

Große Kataloge verwenden Bildlauf und passen sich automatisch an die aktuelle Fenstergröße an.

## Suche

Die Suche ist in folgenden Katalogen verfügbar:

- Zauber;
- Gegenstände;
- Materialien;
- Perks;
- Kreaturen.

Sie kann nicht nur den angezeigten Namen berücksichtigen, sondern auch den englischen Namen, den Lokalisierungsschlüssel, die technische Kennung oder den XML-Pfad.

Die Suche unterscheidet nicht zwischen Groß- und Kleinschreibung und toleriert kleine Tippfehler bei ausreichend langen Wörtern.

Die MCM-Oberfläche ist in 11 Sprachen lokalisiert. Für reguläre Spielinhalte werden nach Möglichkeit die Übersetzungen von Noita wiederverwendet.

# Zauber

Im Zauberbereich kann nicht nur mit dem Katalog, sondern auch mit den tatsächlichen Zaubern des aktuellen Spielers gearbeitet werden.

Gleichzeitig verfügbar sind:

- die Plätze des aktiven Zauberstabs;
- **IMMER WIRKEN**;
- das Zauberinventar;
- der Zauberkatalog.

## Schnelles Ersetzen

Du kannst einen bestimmten Platz des Zauberstabs auswählen und im Katalog mit LMB auf den gewünschten Zauber klicken. Der Zauber wird in den ausgewählten Platz eingesetzt.

## Ziehen und Ablegen

Vorhandene Zauber können verschoben werden:

- zwischen Zauberstabplätzen;
- nach **IMMER WIRKEN**;
- von **IMMER WIRKEN** zurück in normale Plätze;
- in bestimmte Plätze des Zauberinventars;
- aus dem Inventar zurück auf den Zauberstab;
- in die Spielwelt;
- in den Papierkorb.

Bei vorhandenen Zauberkarten versucht MCM, die tatsächliche Spielentität zu verschieben, statt eine neue Kopie zu erzeugen. Dadurch bleibt veränderter oder von anderen Mods hinzugefügter Zustand der Karte erhalten.

Der ursprüngliche Zauber bleibt an seinem Ort, bis das neue Ziel bestätigt wurde. Ein fehlgeschlagener oder unzulässiger Vorgang sollte die ursprüngliche Karte nicht zerstören.

## Immer wirken

Permanente Zauber haben einen eigenen Bereich.

Beim Verschieben zwischen normalen Plätzen und **IMMER WIRKEN** berücksichtigt MCM die Kapazität des Zauberstabs, damit die Struktur der normalen Plätze gültig bleibt.

## Rückgängig / Wiederholen

Für interne Änderungen am Zauberstab steht ein begrenzter Verlauf mit **RÜCKGÄNGIG / WIEDERHOLEN** zur Verfügung.

Er gilt für Vorgänge, die sich sicher aus dem Zustand des Zauberstabs selbst wiederherstellen lassen.

Die Übergabe eines tatsächlichen Zaubers an die Außenwelt oder an das normale Spielinventar lässt sich nicht immer korrekt allein durch Wiederherstellen des Zauberstabzustands rückgängig machen. Solche Aktionen können daher nicht immer rückgängig gemacht werden.

# Zauberstäbe

MCM enthält einen vollständigen Editor für den aktiven Zauberstab.

Verändert werden können:

- die Anzahl der Plätze;
- Zauber pro Schuss;
- die Aufladezeit;
- die Verzögerung zwischen Schüssen;
- die Streuung;
- der Geschwindigkeitsmultiplikator für Projektile;
- das maximale Mana;
- die Mana-Aufladung;
- die Rückstoß-Erholung;
- die Stufe des Zauberstabs;
- das Mischen;
- der Modus ohne Aufladen.

Auch Aussehen und zugehörige Parameter lassen sich ändern:

- der angezeigte Name;
- Sperren;
- das Bild des Zauberstabs;
- der Bildversatz;
- der Abschusspunkt.

Für das Aussehen von Zauberstäben steht ein visueller Katalog zur Verfügung.

## Gespeicherte Zauberstäbe

Ein Zauberstab kann gespeichert und sein gespeicherter Zustand später wiederverwendet werden.

Gespeichert werden:

- Werte;
- Mana;
- Aussehen;
- normale Zauber;
- **IMMER WIRKEN**;
- die Anordnung der Karten;
- verbleibende Anwendungen;
- der eingefrorene Zustand der Karten.

Gespeicherte Zauberstäbe stehen zwischen verschiedenen Welten und in späteren Noita-Sitzungen zur Verfügung.

### Anwenden

**ANWENDEN** überträgt den gespeicherten Zustand auf den Zauberstab, den der Spieler gerade besitzt.

### Kopie

**KOPIE** erstellt eine separate Kopie des gespeicherten Zauberstabs.

Wenn im Schnellinventar ein geeigneter Platz frei ist, wird der neue Zauberstab dort abgelegt. Andernfalls wird er neben dem Spieler in der Spielwelt erzeugt.

Wenn die Erstellung nicht korrekt abgeschlossen werden kann, versucht MCM, die unvollständige Entität zu entfernen.

# Gegenstände und Flüssigkeiten

## Gegenstände

**LMB** auf einen Katalogeintrag erzeugt einen Gegenstand neben dem Spieler.

**RMB** versucht, den Gegenstand direkt ins Inventar zu legen.

Ein Gegenstand kann außerdem gezogen werden:

- in einen passenden Bereich des Schnellinventars;
- aus dem Menü heraus an eine gewählte Stelle der Spielwelt.

Wird die Karte innerhalb des Menüs ohne gültiges Ziel losgelassen, wird der Vorgang abgebrochen.

Der Katalog enthält Vorlagen. Der Eintrag selbst verschwindet daher nach dem Erzeugen eines Gegenstands nicht.

MCM berücksichtigt die normale Aufteilung des Noita-Schnellinventars in Zauberstab- und Gegenstandsplätze und sollte einen bereits vorhandenen Gegenstand nicht ohne Grund ersetzen.

## Flüssigkeiten

MCM kann echte Spielbehälter mit der ausgewählten Flüssigkeit erzeugen.

Der erzeugte Behälter verhält sich wie ein normaler Gegenstand in Noita:

- er kann im Inventar aufbewahrt werden;
- in die Welt geworfen werden;
- zerbrechen;
- seinen Inhalt verschütten;
- an normalen Materialreaktionen teilnehmen.

# Materialien

Der Materialkatalog wird aus den Stoffen aufgebaut, die in der aktuellen Noita-Instanz registriert sind.

Er umfasst verschiedene Materialarten, darunter:

- Flüssigkeiten;
- Pulver;
- Gase;
- Feuer;
- feste Materialien;
- statische Materialien;
- Materialien mit besonderer Darstellung.

Wenn ein anderer aktiver Mod ein eigenes Material korrekt zu Noita hinzufügt, kann es ebenfalls in MCM erscheinen.

## Mit Materialien malen

1. Wähle ein Material.
2. Wähle die Pinselgröße.
3. Klicke auf **MALEN STARTEN**.
4. Schließe das Inventar.
5. Halte in der Spielwelt die zugewiesene Maltaste gedrückt.

Standardmäßig wird die **mittlere Maustaste** verwendet.

Das Öffnen des Inventars beendet den Malmodus.

## Verhalten der Materialien

MCM erzeugt echte Materialien der Spielwelt, keine dekorativen Partikel.

Nach dem Platzieren folgen sie weiterhin der normalen Simulation von Noita:

- Flüssigkeiten fließen;
- Pulver rieseln;
- Gase breiten sich aus;
- Feuer reagiert mit der Umgebung;
- Stoffe reagieren miteinander;
- instabile Materialien können sich in andere umwandeln.

Für unterschiedliche Materialarten verwendet MCM geeignete Platzierungsverfahren, einschließlich zusätzlicher NoitaPatcher-Funktionen für Fälle, die sich mit den normalen Mod-Werkzeugen nicht zuverlässig umsetzen lassen.

# Perks

## Einen Perk erzeugen

**LMB** erzeugt den ausgewählten Perk in der Spielwelt.

Er kann wie ein normaler Noita-Perk aufgenommen werden.

## Perks erhalten

MCM ermöglicht das Erhalten von:

- 1 Kopie;
- 10 Kopien;
- 100 Kopien.

Mehrfaches Erhalten wird schrittweise verarbeitet, damit nicht viele aufwendige Vorgänge in einem einzigen Frame ausgeführt werden.

Die Oberfläche zeigt den Fortschritt an, und die noch ausstehenden Schritte können abgebrochen werden. Bereits erfolgreich erhaltene Kopien bleiben beim Spieler.

## Perks entfernen

Einen Perk sicher zu entfernen ist deutlich schwieriger, als ihn zu erhalten.

Einige Perks verändern mehrere Spielsysteme gleichzeitig, erzeugen Entitäten oder starten Effekte, für die es keine einzige allgemeingültige Rückgängig-Funktion gibt.

Deshalb entfernt MCM nur unterstützte Änderungen, für die eine ausreichend zuverlässige Gegenoperation möglich ist.

Der Mod versucht, nur den Zustand rückgängig zu machen, der durch die jeweilige Anwendung des Perks erzeugt wurde, ohne andere Effekte oder Spielerwerte unnötig zurückzusetzen.

# Effekte

MCM kann unterstützte Elemente anwenden und entfernen, darunter:

- Spieleffekte;
- materialbezogene Zustände.

Beim Entfernen versucht der Mod, fremde Zustände nicht zu verändern, die zu Perks oder anderen Spielsystemen gehören.

So können MCM-eigene Effekte bereinigt werden, ohne pauschal jeden ähnlichen Zustand des Spielers zu löschen.

# Kreaturen und Verwandlungen

## Kreaturen erzeugen

**LMB** erzeugt die ausgewählte Kreatur neben dem Spieler.

Die Karte einer Kreatur kann außerdem aus dem Menü gezogen werden, um sie an einer gewählten Stelle der Spielwelt zu erzeugen.

**RMB** auf einen unterstützten Eintrag versucht, den aktuellen Spieler in die entsprechende Form zu verwandeln.

## Kompatibilität der Formen

Kreaturen in Noita unterscheiden sich intern sehr stark voneinander.

Deshalb unterscheidet MCM Verwandlungsziele anhand exakter XML-Pfade und behandelt ähnlich aussehende Kreaturen nicht automatisch als austauschbar.

Während einer Verwandlung nutzt MCM die Fähigkeiten der ausgewählten Form und wendet bei Bedarf besondere Kompatibilitätsregeln für einzelne Kreaturen an.

# Rückkehr nach einer Verwandlung und Tod der Form

Mit der zugewiesenen Aktion kannst du zur Menschenform zurückkehren — standardmäßig mit **TAB**.

MCM verwendet zunächst die normalen Noita-Mechanismen zum Beenden einer Verwandlung. Für schwierigere Fälle steht eine zusätzliche Wiederherstellung über NoitaPatcher zur Verfügung.

Der Mod behandelt außerdem unterstützte Situationen, in denen eine vorübergehende Form tödlichen Schaden erleidet.

In solchen Fällen versucht MCM:

- den Körper der gestorbenen Form zu erhalten;
- den menschlichen Spieler wiederherzustellen;
- die Steuerung zurückzugeben;
- das Inventar zu erhalten;
- spielerbezogenen Zustand wiederherzustellen.

Das ist keine absolute Unsterblichkeit. Ungewöhnliche Todesarten durch andere Mods, inkompatible Mods oder interne Noita-Fehler können den normalen Wiederherstellungsmechanismus umgehen.

# Kreaturen übernehmen

Neben der Auswahl einer Form aus dem Katalog kann MCM **eine Kreatur übernehmen, die bereits in der Spielwelt existiert**.

Standardmäßig wird die Taste **G** verwendet.

Bewege den Mauszeiger auf ein geeignetes Ziel und verwende die zugewiesene Aktion.

MCM prüft die Kreatur, führt die Verwandlung in eine kompatible Form aus und entfernt die ursprüngliche Entität erst dann aus der Welt, wenn der erfolgreiche Abschluss bestätigt wurde.

Falls die Verwandlung nicht zustande kommt, sollte die ursprüngliche Kreatur nicht einfach verschwinden.

Diese Funktion ist nicht auf den statischen MCM-Katalog beschränkt. Auch eine geeignete Kreatur aus einem anderen Mod kann die Prüfung bestehen, eine allgemeine Kompatibilität mit beliebigen Drittanbieter-Entitäten wird jedoch nicht garantiert.

# Spieler

**SPIELER** ist ein besonderer Eintrag im Kreaturenkatalog.

Es handelt sich nicht um eine normale Form, in die man sich verwandelt.

**LMB** erzeugt einen separaten Charakter, für den MCM zu kopieren versucht:

- das Aussehen des Spielers;
- die maximale Gesundheit.

**RMB** auf den Eintrag **SPIELER** verwandelt den normalen Spieler nicht in diese Entität.

Befindet sich der Spieler bereits in Menschenform, geschieht nichts. Ist der Spieler gerade in eine andere Kreatur verwandelt, wird die Rückkehr zur Menschenform verwendet.

# Wetter und Zeit

MCM kann Folgendes verändern:

- die Tageszeit;
- Wettervorgaben;
- einzelne unterstützte Wetterparameter.

Ein gewünschter Zustand kann gesetzt und der entsprechende Parameter später wieder aus der Kontrolle von MCM entlassen werden.

So lässt sich beispielsweise nach dem erzwungenen Setzen einer Tageszeit der natürliche Zeitablauf von Noita wiederherstellen.

# Weltregeln

Der Bereich **REGELN** ermöglicht tiefgreifendere Änderungen am Verhalten der Spielwelt.

Je nach Regel lassen sich beispielsweise folgende Parameter steuern:

- Beziehungen zwischen Kreaturen;
- Gold;
- Verwendung von Zaubern;
- Kriegsnebel;
- Belohnungen für bestimmte Arten von Tötungen;
- Heilungsabwürfe;
- Blut;
- Schwerkraft;
- physikalisches Verhalten;
- Trittkraft;
- physikalische Verbindungen;
- Tag-Nacht-Zyklus;
- weitere unterstützte globale Parameter.

Der wichtigste Punkt: MCM-Regeln sind als **umkehrbare Änderungen** ausgelegt.

Für unterstützte Einstellungen speichert der Mod den Ausgangszustand und erlaubt es, die Werte auf ihren normalen Zustand zurückzusetzen.

Wird ein Multiplikator verwendet, wird der neue Wert relativ zum Ausgangszustand berechnet, statt immer wieder auf ein bereits verändertes Ergebnis multipliziert zu werden.

Vorgänge, bei denen sehr viele Entitäten oder Physikobjekte verändert werden müssen, werden schrittweise abgearbeitet, statt beim Tastendruck die gesamte Welt auf einmal zu bearbeiten.

# Teleportation

MCM ermöglicht schnelles Reisen zu vorbereiteten Zielen im Spiel, darunter Punkte:

- entlang des Hauptwegs;
- in den Heiligen Bergen;
- in großen Seitengebieten;
- an weiteren unterstützten Orten.

Vor der Teleportation kann der Mod das Zielgebiet laden und versucht, in der Nähe einen freien Platz zu finden, damit der Spieler nicht direkt in einer festen Wand oder einem anderen Hindernis erscheint.

# Entangled Worlds

**Entangled Worlds / Noita Proxy ist optional.**

MCM funktioniert auch ohne Entangled Worlds vollständig im Einzelspieler.

Ist Entangled Worlds installiert, werden zusätzliche experimentelle Mehrspielerfunktionen aktiviert.

Für bestmögliche Kompatibilität wird empfohlen, dass alle Teilnehmer dieselbe MCM-Version verwenden.

## Gegenstände, Zauberstäbe und Zauber

Wo immer möglich verwenden Gegenstände in der Welt und abgelegte Zauber die normalen Mechanismen von Entangled Worlds.

Auch Inventaränderungen können über Entangled Worlds übertragen werden.

## Perks

Ein von MCM erzeugter Perk bleibt eine echte Spielentität und wird nach Möglichkeit über das normale Weltgegenstand-System von Entangled Worlds übertragen.

## Materialien

Das Malen mit Materialien bietet experimentelle Mehrspielerunterstützung.

MCM synchronisiert betroffene Bereiche der Welt, damit das Ergebnis auch bei anderen Teilnehmern erscheinen kann.

Damit dies korrekt funktioniert, muss das entsprechende Material auch beim anderen Spieler vorhanden sein. Wenn sich die verwendeten Mod-Sammlungen unterscheiden, kann keine identische Darstellung aller Materialien garantiert werden.

## Wetter und Weltregeln

Unterstützte Änderungen an Wetter und globalen Regeln können über Entangled Worlds synchronisiert werden.

## Verwandlungen und Übernahme von Kreaturen

Verwandlungen erhalten bei Verwendung von Entangled Worlds zusätzliche Unterstützung.

Beim Übernehmen einer bereits vorhandenen Kreatur berücksichtigt der Mod auch deren Netzwerkzustand. Wenn MCM nicht zuverlässig genug feststellen kann, dass die ursprüngliche Entität entfernt werden darf, lässt es sie lieber bestehen.

## Spieler

Die Erzeugung der besonderen Entität **SPIELER** wird auch mit Entangled Worlds unterstützt. In diesem Fall übernimmt sie die Farben des Aussehens der Person, die sie erzeugt hat.

## Teleportation zwischen Spielern

Wenn Entangled Worlds aktiv ist, werden im Teleportationsbereich die verfügbaren Spieler angezeigt.

**HINGEHEN** teleportiert dich zum ausgewählten Spieler.

**HIERHER HOLEN** sendet dem ausgewählten Spieler eine Anfrage, sich zu dir teleportieren zu lassen.

In beiden Fällen versucht MCM, einen freien Platz in der Nähe des Ziels zu verwenden.

## Einschränkungen

Die Unterstützung für Entangled Worlds bleibt experimentell.

**Im Mehrspielermodus kann die Verwandlung in große oder aus vielen Gelenken bestehende Bosse zu einem kritischen Leistungseinbruch führen und die aktuelle Spielsitzung praktisch unbrauchbar machen.**

Noita lässt sich äußerst schwer vollständig synchronisieren, besonders wenn sich gleichzeitig Folgendes verändert:

- die Pixelwelt;
- Materialien;
- Physikobjekte;
- komplexe Kreaturen und Bosse;
- Inhalte anderer Mods.

Deshalb verspricht MCM keine perfekte Synchronisierung jedes denkbaren Zustands.

# NoitaPatcher und unsichere Mods

Die Vollversion von MCM enthält **NoitaPatcher**.

Er wird für Funktionen verwendet, die sich mit den normalen Modding-Möglichkeiten von Noita nicht ausreichend umsetzen lassen, insbesondere für Teile der Mechanismen für:

- Wiederherstellung nach komplexen Verwandlungen;
- Arbeit mit Spielentitäten;
- Arbeit mit der Spielwelt;
- Platzierung bestimmter Materialien;
- erweiterte Kompatibilität.

Deshalb müssen für die Vollversion **unsichere Mods** erlaubt sein.

NoitaPatcher ist bereits im fertigen MCM-Build enthalten und muss nicht separat installiert werden.

# Wenn etwas nicht funktioniert

## MCM wird nicht geladen

Prüfe, ob nach dem Entpacken folgende Datei vorhanden ist:

```text
Noita/mods/metamorph_creative_menu/mod.xml
```

Prüfe außerdem, ob:

- MCM im Menü **Mods** aktiviert ist;
- **[x]** daneben angezeigt wird;
- **unsichere Mods erlaubt** sind;
- das Spiel mit aktiven Mods gestartet wurde.

## Funktionen mit NoitaPatcher funktionieren nicht

Prüfe, ob folgende Datei vorhanden ist:

```text
metamorph_creative_menu/NoitaPatcher/noitapatcher.dll
```

und stelle sicher, dass **unsichere Mods** erlaubt sind.

## Rückkehr aus einer Form funktioniert nicht

Versuche die zugewiesene Rückkehraktion — standardmäßig **TAB**.

Wenn das Problem erneut auftritt, sollten in einem Fehlerbericht möglichst folgende Angaben enthalten sein:

- der genaue Name der Kreatur;
- der XML-Pfad, falls bekannt;
- wie die Form erhalten wurde;
- ob die normale Rückkehr funktioniert;
- ob das Problem nur nach tödlichem Schaden auftritt;
- ob Entangled Worlds verwendet wird.

## Probleme mit Entangled Worlds

Prüfe:

- ob alle Teilnehmer dieselbe MCM-Version verwenden;
- ob die Entangled-Worlds-Versionen kompatibel sind;
- ob dieselbe Mod-Sammlung verwendet wird, wenn das Problem Materialien oder Kreaturen aus anderen Mods betrifft.

# Fehler melden

[Issue erstellen](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)

Für einen hilfreichen Bericht sollten möglichst folgende Angaben gemacht werden:

- die MCM-Version;
- was genau du getan hast;
- das erwartete Ergebnis;
- das tatsächliche Ergebnis;
- Name der betroffenen Kreatur, des Gegenstands, Perks oder Materials;
- ob Entangled Worlds verwendet wird;
- andere Mods, die mit dem Problem zusammenhängen könnten;
- Fehlermeldung oder entsprechender Ausschnitt aus dem Protokoll;
- Screenshot oder Video, wenn es das Problem besser zeigt.

# Drittanbieter-Komponenten

- **Noita** — Nolla Games.
- **NoitaPatcher** — dextercd, in der Vollversion enthalten.
- **lbase64** — Ilya Kolbin, in MCM enthalten.
- **Entangled Worlds / Noita Proxy** — IntQuant und weitere Mitwirkende; wird separat installiert und ist optional.

Ausführliche Angaben zu den ursprünglichen Projekten und ihren Lizenzen stehen in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

---

**Metamorph: Creative Menu** ist ein inoffizieller, von Nutzern erstellter Mod für Noita. Das Projekt steht in keiner Verbindung zu Nolla Games und ist kein offiziell unterstützter Bestandteil des Spiels.

[↑ Zur Sprachauswahl](#languages)