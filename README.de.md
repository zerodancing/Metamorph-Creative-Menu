<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es.md) · [**Deutsch**](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">Ein Kreativmenü und Sandbox-Werkzeugpaket für Noita: Zauber, Zauberstäbe, Gegenstände, Materialien, Perks, Effekte, Kreaturen, Verwandlungen, Besitzergreifung, Teleportation, Wetter, Weltregeln, Mehrspieler-Integration und Wiederherstellungswerkzeuge.</p>

<p align="center"><strong>Ersteller und Maintainer: <a href="https://github.com/zerodancing">zerodancing</a></strong></p>

---

# Download

Für normales Spielen verwende den installationsfertigen Build:

[**⬇️ Aktuellen Build herunterladen**](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)

[Seite des aktuellen Builds](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) · [Changelog](metamorph_creative_menu/CHANGELOG.txt)

Der GitHub-Release wird automatisch aus dem vollständigen Entwicklungsbaum erzeugt. Tests, QA-Werkzeuge, Diagnostik, nativer Quellcode und Build-Werkzeuge bleiben im Repository, werden aber aus dem Spielerarchiv entfernt.

Der eigenständige GitHub-Build enthält NoitaPatcher und native Wiederherstellungsfunktionen. Daher müssen **Unsafe Mods erlaubt** sein.

# Installation

1. Lade `Metamorph-Creative-Menu.zip` über den Link oben herunter.
2. Starte Noita und öffne im Hauptmenü **Mods**.
3. Klicke auf **Open mods folder**.
4. Entpacke oder verschiebe den Ordner `metamorph_creative_menu` in den geöffneten `mods`-Ordner. Der endgültige Pfad muss direkt `metamorph_creative_menu/mod.xml` enthalten, ohne zusätzlichen Archiv-Unterordner.
5. Wenn bereits eine ältere Kopie vorhanden ist, ersetze den gesamten Ordner `metamorph_creative_menu`, statt alte und neue Dateien zusammenzuführen.
6. Kehre zu Noita zurück und aktualisiere die Mod-Liste.
7. Erlaube **Unsafe Mods**.
8. Aktiviere **Metamorph: Creative Menu** und starte ein Spiel mit aktiven Mods.

Aktiviere den eigenständigen GitHub-Build und die Steam-Workshop-Version nicht gleichzeitig.

# Eigenständiger Build und Steam Workshop

Der über dieses GitHub-Repository verteilte Build ist der vollständige Standalone-Build. Er enthält NoitaPatcher und Funktionen, die uneingeschränkten Mod-API-Zugriff benötigen, darunter Low-Level-Materialoperationen und native Game-Over-Wiederherstellung.

Der [Steam-Workshop-Build](https://steamcommunity.com/sharedfiles/filedetails/?id=3785170245) wird separat installiert. Er enthält nicht die nativen Komponenten, die für die nur im Standalone-Build verfügbaren Funktionen benötigt werden.

Beide Builds verwenden dieselbe Mod-Identität. Eine gleichzeitige Installation kann daher doppelte oder kollidierende Dateien erzeugen und wird nicht unterstützt.

# Über den Mod

**Metamorph: Creative Menu (MCM)** ist ein Kreativmenü und Sandbox-Werkzeugpaket für Noita.

Es bündelt Werkzeuge für:

- Zauber und Zauberinventare;
- Zauberstab-Bearbeitung und wiederverwendbare Presets;
- Gegenstände und Flüssigkeitsbehälter;
- den vollständigen Materialkatalog und Materialmalerei;
- Perks und unterstütztes Entfernen von Perks;
- Status-Effekte und GameEffect-Entitäten;
- Kreaturen, Verwandlungen und Besitzergreifung;
- Wetter und Zeit;
- globale Weltregeln;
- Teleportation;
- optionale Entangled-Worlds-Integration;
- Wiederherstellung nach Verwandlung, Formtod und Game Over.

MCM versucht, auf echtem Noita-Zustand zu arbeiten, statt alles durch dekorative Kopien zu ersetzen. Vorhandene Zauberkarten werden als Entitäten bewegt, Gegenstandsübergaben beachten die Inventarstruktur, Zauberstabänderungen nutzen Commit-/Rollback-Pfade, Materialien bleiben echte simulierte Materialien, und reversible Weltregeln bewahren genügend Ursprungszustand, um unterstützte Einstellungen später wiederherzustellen.

Entangled Worlds ist optional. Ohne EW bleibt MCM ein vollständiger Einzelspieler-Mod.

# Steuerung

Standardbelegung:

| Aktion | Standard |
| --- | --- |
| Kreativmenü öffnen / schließen | **F4** |
| Während einer Verwandlung zur Menschenform zurückkehren | **TAB** |
| Eine Kreatur in der Welt übernehmen | **G** |
| Mit dem ausgewählten Material malen | **Mittlere Maustaste** |

Das Kreativfenster ist auch über die normale Noita-Inventaroberfläche erreichbar.

Belegungen können im MCM-Bereich **CONTROLS** und in Noitas Mod-Einstellungen geändert werden. Tastaturtasten, Maustasten und exakte **CTRL / SHIFT / ALT**-Kombinationen werden unterstützt.

Während der Belegung:

- **DELETE / BACKSPACE** löscht die Belegung;
- **ESC** bricht ab;
- **R** stellt die Standardbelegung dieser Aktion wieder her;
- **RESET ALL** stellt nach Bestätigung alle Standardbelegungen wieder her.

Doppelte Belegungen bleiben editierbar, MCM zeigt den Konflikt jedoch an, statt eine andere Aktion still zu überschreiben.

Menünavigation, Bereiche, Rückkehr aus einer Form, Besitzergreifung, Materialmalerei, Effektbereinigung, Wetterfreigabe, Zurücksetzen von Weltregeln und unterstützte Mehrspieleraktionen können neu belegt werden.

# Creative-Menu-Fenster

Das direkte Kreativmenü ist ein persistentes, skalierbares Fenster und kein festes Debug-Overlay.

Es kann:

- über den Titel verschoben werden;
- an Kanten und Ecken skaliert werden;
- minimiert werden;
- geschlossen werden;
- auf das Standardlayout zurückgesetzt werden.

Position, Breite, Höhe und der zuletzt geöffnete Bereich werden zwischen Sitzungen gespeichert. Nach Auflösungsänderungen wird die gespeicherte Geometrie wieder in den sichtbaren GUI-Bereich geklemmt.

Listen und Kataloge verwenden vermessene Layouts und Noita-Scrollcontainer. Eine Größenänderung des Fensters verändert sofort die sichtbare Inhaltsmenge, und übersetzte Beschriftungen dürfen umbrechen, ohne benachbarte Bedienelemente zu überlagern. Schmale Layouts verteilen Controls auf zusätzliche Zeilen, statt sie übereinanderzuzeichnen.

Das bloße Öffnen oder Überfahren des abgelösten Fensters deaktiviert das Gameplay nicht dauerhaft. Wenn ein Klick, Drag oder fokussiertes Textfeld sonst gleichzeitig den Spieler auslösen würde, unterdrückt MCM die betroffenen Spielersteuerungen vorübergehend und stellt sie anschließend wieder her.

# Suche und Lokalisierung

Die Suche ist in den wichtigsten Katalogen verfügbar, darunter Zauber, Gegenstände, Materialien, Perks und Kreaturen.

Je nach Eintrag kann sie Folgendes durchsuchen:

- den Namen in der aktuellen Oberflächensprache;
- den englischen Namen;
- Lokalisierungsschlüssel;
- technische Kennungen;
- XML-Pfade.

Die Suche ignoriert Groß-/Kleinschreibung, normalisiert gängige Akzente und Trennzeichen und toleriert kleine Tippfehler in längeren Suchbegriffen.

Die eigene MCM-Oberfläche ist lokalisiert auf:

- Englisch;
- Russisch;
- Brasilianisches Portugiesisch;
- Spanisch;
- Deutsch;
- Französisch;
- Italienisch;
- Polnisch;
- Vereinfachtes Chinesisch;
- Japanisch;
- Koreanisch.

Für regulären Noita-Inhalt verwendet der Mod nach Möglichkeit die Lokalisierungsschlüssel des Spiels, statt doppelte Namenslisten zu pflegen.

# Zauber

Der Zauberbereich arbeitet sowohl mit dem Katalog als auch mit bereits vorhandenen Zauberentitäten des Spielers.

Der Hauptarbeitsbereich enthält:

- die normalen Slots des aktiven Zauberstabs;
- **ALWAYS CAST**-Karten;
- das Zauberinventar des Spielers;
- den durchsuchbaren Zauberkatalog.

## Schnelles Ersetzen des ausgewählten Slots

Ein kurzer Klick wählt einen Zauberstabslot. Danach ersetzt ein kurzer LMB-Klick auf einen Katalogzauber diesen Slot.

Dies ist der schnelle Weg für normale Bearbeitung. Präzises Verschieben erfolgt per Drag-and-drop.

## Transaktionales Drag-and-drop

Vorhandene Karten können verschoben werden:

- zwischen Zauberstabslots;
- von normalen Slots zu **ALWAYS CAST**;
- von **ALWAYS CAST** zurück zu normalen Slots;
- in einen exakten Zauberinventar-Slot;
- vom Inventar zurück auf den Zauberstab;
- in die Spielwelt;
- in den Papierkorb, sofern unterstützt.

Bei einer vorhandenen Karte verschiebt MCM nach Möglichkeit die echte Entität. Veränderlicher Zustand, verbleibende Verwendungen und von anderen Mods hinzugefügte Daten gehen daher nicht nur durch einen Positionswechsel verloren.

Die Quelle bleibt unverändert, bis die Zieltransaktion bestätigt wurde. Ungültige oder unbekannte Drop-Ziele brechen den Vorgang ab, statt die ursprüngliche Karte zu löschen. Eine Mausfreigabe führt höchstens eine bestätigte Operation aus.

Katalogkarten sind Vorlagen und werden beim Ziehen nie verbraucht.

## Always Cast

Always-Cast-Karten haben eine eigene Leiste. Promotion, Rückstufung und Tausch berücksichtigen die effektive Kapazität normaler Slots, damit keine ungültige Zauberstabstruktur entsteht.

## Rückgängig und Wiederholen

Interne Zauberstabänderungen besitzen eine begrenzte **UNDO / REDO**-Historie.

Vorgänge, die eine echte Entität in die Außenwelt oder in ein anderes Inventar übergeben, lassen sich nicht immer sicher aus einem Zauberstab-Snapshot zurückholen. Solche externen Übergaben werden daher nicht als universell rückgängig machbar versprochen.

# Zauberstäbe

Der Zauberstab-Arbeitsbereich bearbeitet den aktuell gehaltenen Zauberstab.

Unterstützte Werte umfassen:

- Kapazität / Slots;
- Zauber pro Schuss;
- Aufladezeit;
- Verzögerung zwischen Schüssen;
- Streuung;
- Geschwindigkeitsmultiplikator für Projektile;
- maximales Mana;
- Mana-Aufladung;
- Rückstoß-Erholung;
- Zauberstab-Level;
- Shuffle;
- Never-Reload-Verhalten.

MCM bearbeitet außerdem Darstellung und Metadaten:

- angezeigter Name;
- Sperren für Zauberstab und Karten;
- Sprite-Pfad;
- Sprite-Offsets;
- Schussposition.

Ein visueller Erscheinungskatalog folgt vorhandenen Zauberstab-XML-Daten, wenn verfügbar.

## Zauberstab-Presets

Zauberstäbe können als persistente benannte Presets gespeichert und in späteren Welten oder Noita-Sitzungen wiederverwendet werden.

Ein Preset kann speichern:

- Zauberstabwerte;
- Mana-Werte;
- visuelle Metadaten;
- normale Zauberkarten;
- Always-Cast-Karten;
- Slotpositionen;
- verbleibende Verwendungen;
- eingefrorenen Kartenstatus.

Jedes Preset bietet zwei getrennte Aktionen:

- **APPLY** schreibt den gespeicherten Blueprint auf den aktuell gehaltenen Zauberstab;
- **GET COPY** baut einen neuen Zauberstab aus demselben Blueprint.

Eine Kopie wird nach Möglichkeit in einen freien Zauberstabslot des Schnellinventars gelegt. Gibt es keinen geeigneten Slot, bleibt der fertig gebaute Zauberstab in der Welt beim Spieler.

Zauberstabersetzung und Preset-Laden nutzen Commit-/Rollback-Pfade. Wenn Konstruktion oder Platzierung nicht abgeschlossen werden können, versucht MCM den unvollständigen Entitätsbaum zu entfernen, statt einen defekten Teil-Zauberstab zurückzulassen.

# Gegenstände und Flüssigkeiten

## Gegenstände

Ein kurzer **LMB**-Klick auf einen Katalogeintrag erzeugt einen unterstützten Gegenstand in der Nähe des Spielers.

**RMB** versucht, ihn in den passenden Inventarbereich zu legen.

Katalogeinträge können außerdem gezogen werden:

- auf ein passendes Ziel im Schnellinventar;
- aus dem Menü hinaus an eine exakte Weltposition.

Wird eine Karte innerhalb des Menüs ohne gültiges Ziel losgelassen, wird der Vorgang abgebrochen. Die Katalogkarte ist nur eine Vorlage und bleibt verfügbar.

MCM respektiert Noitas normale Trennung des Schnellinventars in Zauberstab- und Gegenstandsslots. Ein fehlgeschlagenes XML-Laden, Befüllen mit Flüssigkeit, Inventar-Handoff oder optionaler Mehrspieler-Handoff entfernt die neu erzeugte Entität nach Möglichkeit wieder.

Einige echte Inventargegenstände liegen im Spiel in kreaturenorientierten Verzeichnissen. MCM klassifiziert bekannte Fälle nach Verhalten, statt aus dem Ordnernamen allein abzuleiten, ob etwas Gegenstand oder Kreatur ist.

## Flüssigkeiten

Flüssigkeitseinträge erzeugen echte gefüllte Noita-Behälter und keine dekorativen UI-Objekte.

Der resultierende Behälter kann getragen, fallen gelassen, zerbrochen und ausgeschüttet werden; sein Inhalt nimmt an normalen Materialreaktionen teil.

# Materialien

Der Materials-Bereich ist ein Weltmalwerkzeug auf Basis von Noitas echtem Materialregister.

Der Katalog wird aus registrierten Flüssigkeiten, Sanden / Pulvern, Gasen, Feuern, Feststoffen sowie verwandten statischen oder Effektmaterialien aufgebaut. Korrekt registrierte Materialien anderer aktiver Mods können deshalb automatisch erscheinen.

Materialerkennung und teure Validierung werden auf begrenzte Arbeit verteilt, statt den gesamten Katalog in einem einzigen UI-Frame zu scannen.

## Materialdarstellung

Flüssigkeiten verwenden dieselbe Darstellung gefüllter Behälter wie der Gegenstandsbereich.

Bei Nicht-Flüssigkeiten bevorzugt MCM definierte Texturen und Tint-Daten aus `materials.xml`, einschließlich geerbter Definitionen. Fehlt eine definierte Textur, basiert der Fallback auf der tatsächlichen Engine-Farbe des Materials und nicht auf einer willkürlichen Vorschaufarbe.

## Malen

1. Material auswählen.
2. Pinselgröße wählen.
3. Malmodus aktivieren.
4. Inventar schließen.
5. Die konfigurierte Mal-Eingabe in der Welt gedrückt halten.

Das Öffnen des Inventars beendet den aktiven Malmodus.

Malen erzeugt nicht nur dekorative Partikel. MCM setzt echte Zellen über einen zur Engine passenden Pfad in die Welt. Dynamische Materialien folgen weiterhin der Noita-Simulation: Flüssigkeiten fließen, Pulver fallen, Gase bewegen sich, Feuer reagiert und instabile Stoffe können sich durch Materialreaktionen verändern.

Unterschiedliche Materialklassen benötigen unterschiedliche Platzierungsstrategien. Der Standalone-Build kann NoitaPatchers direkten Weltgitterzugriff und einen kleinen PixelScene-Fallback für definierte Fälle verwenden, die Noita an einer bestimmten Texturkoordinate nicht direkt konstruieren kann.

Arbeitswarteschlangen sind begrenzt, damit ein großer gehaltenener Pinsel nicht absichtlich unbegrenzte Arbeit in einem einzigen Frame ausführt.

# Perks

## Perks erzeugen und erhalten

**LMB** erzeugt einen normalen Pickup des ausgewählten Perks in der Welt.

Die Take-Aktion kann den Perk einzeln oder in größeren Mengen gewähren. Massenaktionen werden als begrenzte Jobs verarbeitet, statt alle Kopien in einem einzigen UI-Frame anzuwenden.

Die Oberfläche zeigt den Fortschritt, und noch ausstehende Arbeit kann abgebrochen werden. Bereits bestätigte Kopien bleiben nach dem Abbruch erhalten.

Jede gewährte Kopie durchläuft weiterhin den normalen Perk-Anwendungspfad, statt den Endzustand direkt zu fälschen.

## Perks entfernen

Einen Perk zu entfernen ist wesentlich schwieriger, als ihn zu gewähren. Perks können Globals, Komponenten, Entitäten, Spielerwerte und lang laufende Mechaniken verändern; Noita bietet dafür keine universelle inverse Operation.

MCM entfernt deshalb nur Zustand, für den eine ausreichend sichere verfolgte Gegenoperation existiert. Das Transaktionsjournal versucht, nur Zustand dieser konkreten Perk-Anwendung zu entfernen, ohne unabhängigen Spielerzustand zurückzusetzen.

Wenn eine Bereinigung nur teilweise gelingt oder nicht als vollständig bewiesen werden kann, bleibt sie als unvollständig behandelt, statt still als erfolgreich zu gelten.

Ein Drittanbieter-Perk kann vergebbar sein, ohne korrekt entfernbar zu sein.

# Effekte

Der Effects-Bereich wendet unterstützte Materialstatus und GameEffect-Entitäten an und entfernt sie.

Die Entfernung berücksichtigt nach Möglichkeit Besitz. MCM löscht nicht wahllos ähnliche versteckte Effekte, die Perks, dem Spiel oder einem anderen System gehören.

Persistente von MCM erzeugte Effekte verwenden begrenzte Bereinigung / Ablaufbehandlung, damit das Entfernen eines MCM-Effekts keinen fremden Zustand zurücksetzt.

# Kreaturen

Der Kreaturenkatalog behält exakte XML-Pfade bei, statt alle ähnlich benannten Entitäten zusammenzuführen.

Unterstützte Interaktionen:

- **LMB** — erzeugt die ausgewählte definierte Entität beim Spieler;
- Drag aus dem Menü — erzeugt sie an der bestätigten Weltcursorposition;
- **RMB** — verwandelt den aktuellen Spieler in eine unterstützte Form;
- der spezielle Eintrag **PLAYER** — erzeugt oder stellt Spielerzustand wieder her, wie unten beschrieben.

Wird eine gezogene Karte wieder über dem Menü losgelassen, wird der Welt-Spawn abgebrochen.

Kompatibilitätsregeln für gefährliche oder ungewöhnliche Formen verwenden exakte Pfade. Ein Dateiname, der nur ein bekanntes Wort enthält, macht eine Entität nicht automatisch zu einer gleichwertigen Form.

# Verwandlungen und Rückkehr zur Menschenform

Spielbare Formen behalten nützliche native Bewegung, Angriffe, Darstellung und Physik, soweit praktikabel. Komponenten, die direkt mit Spielereingabe konkurrieren, können deaktiviert oder angepasst werden, solange die Form vom Spieler gesteuert wird.

Einige komplexe Kreaturen benötigen zusätzliche Kompatibilitätslogik. Bosse, skriptgesteuerte Wrapper und stark physikabhängige Entitäten müssen sich als Spielerform nicht exakt wie ihre KI-gesteuerte Originalversion verhalten.

Die konfigurierte Rückkehraktion — standardmäßig **TAB** — nutzt zuerst den normalen Pfad zum Beenden der Verwandlung. Reicht das nicht aus, besitzt der Standalone-Build zusätzliche NoitaPatcher-gestützte Wiederherstellungspfade.

Bei unterstützten Fällen tödlichen Schadens versucht MCM:

- die tote temporäre Form bzw. Leiche in der Welt zu belassen, wenn passend;
- eine menschliche Spielerentität wiederherzustellen;
- Authority und Steuerung zurückzugeben;
- das Inventar zu bewahren;
- relevanten Spielerzustand wiederherzustellen.

Das ist Wiederherstellungslogik, keine absolute Unsterblichkeit. Ein Drittanbieter-Kill-Script, inkompatibler Engine-Zustand oder Prozessabsturz kann den unterstützten Handoff umgehen.

# Besitzergreifung

Besitzergreifung steuert eine bereits in der Welt existierende Kreatur, statt eine Form aus dem Katalog zu wählen.

Die Standardtaste ist **G**.

Ziele auf eine geeignete Kreatur und benutze die Besitzergreifungsaktion. MCM prüft das Ziel, bereitet eine kompatible Formtransaktion vor und entfernt bzw. retired die ursprüngliche Weltentität erst, nachdem der neue spielergesteuerte Zustand bestätigt wurde.

Scheitert der Übergang, sollte die ursprüngliche Kreatur nicht einfach verschwinden.

Die Funktion ist nicht auf MCMs eingebauten Katalog begrenzt. Eine kompatible Kreatur eines anderen Mods kann funktionieren, universelle Kompatibilität mit allen Drittanbieterentitäten wird jedoch nicht garantiert.

# Player-Eintrag

**PLAYER** ist ein spezieller Eintrag im Kreaturenkatalog und kein normaler Polymorph-Zieltyp.

Seine Spawn-Aktion erzeugt einen getrennten spielerähnlichen Charakter und versucht geeignete Darstellung sowie Informationen zur maximalen Gesundheit zu kopieren.

Die Transformationsaktion auf **PLAYER** verwandelt einen bereits menschlichen Spieler nicht in ein Duplikat. Befindet sich der Spieler in einer anderen Form, dient die Aktion als Rückkehr zur Menschenform.

# Game-Over-Wiederherstellung im Einzelspieler

Der Standalone-Einzelspieler-Build enthält einen zusätzlichen Wiederherstellungspfad für Noitas normalen Game-Over-Bildschirm.

Wenn die native Integration die benötigten Spielstrukturen sicher erkennen kann, fügt MCM dem Game-Over-Interface die Aktion **„I didn't die“** hinzu.

MCM hält während des Spiels eine fortlaufend aktualisierte Spieler-Sicherung. Das Auslösen der Wiederherstellung fordert die Wiederherstellung über MCMs normalen Update-Pfad an, statt den kompletten Spieler direkt im UI-Klickhandler neu aufzubauen.

Eine unterstützte Wiederherstellung versucht:

- eine lebende Spielerentität wiederherzustellen oder zu erhalten;
- sie wieder authoritative zu machen;
- den Game-Over-Zustand der Engine zu löschen;
- Steuerung und nutzbaren Spielerzustand zurückzugeben;
- Game-Over-Audio, Musik und UI bestmöglich zu bereinigen;
- nach der Wiederherstellung ein kurzes Schutzfenster zu geben.

Der native Helper ist fail-closed ausgelegt. Er sucht im laufenden unterstützten Noita-Executable nach bekannten Strukturen, statt dauerhaft auf eine einzige hart codierte Adresse zu schreiben. Können die erwarteten Strukturen nach einem Spielupdate nicht sicher erkannt werden, wird die optionale Wiederherstellung nicht benutzt, statt an eine unsichere Adresse zu schreiben.

# Wetter und Zeit

MCM kann unterstützten Wetter- und Zeitstatus steuern, einschließlich Presets und einzelner Parameter der aktuellen Implementierung.

Erzwungener Zustand kann später wieder an die normale Spielsteuerung freigegeben werden. Nach dem Erzwingen einer Tageszeit kann MCM beispielsweise diese Einstellung wieder loslassen, damit Noitas natürlicher Zeitfluss weiterläuft.

Wetteränderungen werden als zustandsbehaftete Steuerung behandelt und nicht als einmalige Einweg-Konsolenbefehle.

# Weltregeln

Der Bereich **RULES** verändert unterstütztes globales Spielverhalten.

Regeln decken unter anderem ab:

- Beziehungen zwischen Kreaturen;
- Goldverhalten;
- Zaubernutzung;
- Fog of War;
- ausgewählte Kill-Belohnungen;
- Heilungsdrops;
- blutbezogenes Verhalten;
- Gravitation;
- Physik;
- Trittstärke;
- Physikgelenke;
- Tag-Nacht-Zyklus;
- weitere unterstützte globale Parameter.

Das wichtigste Ziel ist Reversibilität.

Für unterstützte Regeln zeichnet MCM den Ursprungszustand auf oder leitet ihn ab, damit die Einstellung später zurückgesetzt werden kann. Multiplikator-Regler werden relativ zum Ursprungswert angewandt und nicht wiederholt auf bereits veränderte Ergebnisse multipliziert.

Regeln, die viele Entitäten oder Physikobjekte anfassen müssen, nutzen begrenzte Update-Arbeit über mehrere Frames, statt die gesamte Welt synchron durch einen einzigen Menüklick umzuschreiben.

# Teleportation

Der Teleportbereich bietet vorbereitete Ziele in der Welt, darunter Punkte auf der Hauptroute, Holy Mountains, größere Nebenbereiche und weitere unterstützte Orte.

Vor dem Versetzen kann MCM das Laden des Zielgebiets anfordern und sucht nutzbaren freien Raum in der Nähe, statt den Spieler absichtlich direkt in festes Terrain zu setzen.

Teleportation hängt weiterhin davon ab, dass die Welt laden und ein gültiges Ziel bereitstellen kann. Stark modifizierte Welten können Fallback-Verhalten benötigen.

# Entangled Worlds

**Entangled Worlds / Noita Proxy ist optional.** MCM funktioniert ohne EW.

Wenn EW vorhanden ist, aktiviert MCM zusätzliche mehrspielerbewusste Funktionen. Alle Peers sollten kompatible MCM-Builds verwenden, wenn sie auf MCM-spezifisch synchronisierten Zustand angewiesen sind.

## Authority und Formen

Spielerformen benötigen spezielle Ownership-Behandlung, weil ein verwandelter Spieler nicht versehentlich eine zweite Netzwerk-Authority hinterlassen darf.

MCM koordiniert Ownership, Retirement und Rückkehr zur Menschenform mit EW, soweit unterstützt. Boss- und Kolmi-artige Entitäten besitzen zusätzliche Lifecycle-Behandlung, die doppelte Authorities und veraltete netzwerkgesteuerte Kopien vermeiden soll.

Der normale EW-Todespfad bleibt für Entitäten zuständig, die nicht als MCM-eigener Formzustand erkannt werden.

## Gegenstände, Zauberstäbe und Zauber

Wo möglich nutzt MCM EWs normale Item-/Inventarmechanismen, statt ein paralleles Transportsystem zu erfinden.

Bestätigte Zauberstab- und Zauberinventaränderungen fordern die passende Multiplayer-Aktualisierung an, wenn die Integration verfügbar ist. Von MCM erzeugte Weltgegenstände können an EWs normalen World-Item-Pfad übergeben werden.

## Perks

Normale Perk-Pickups können EWs normale World-Item-Synchronisation verwenden. MCMs eigene Perk-Zustandslogik koordiniert Refresh und begrenzte Operationen, damit Massenaktionen nicht für jede Kopie einen teuren globalen Refresh auslösen.

## Materialien

Materialmalerei besitzt einen eigenen Kompatibilitätspfad, weil Weltzellenänderungen keine normalen Item-Entitäten sind.

MCM hält Malarbeit begrenzt, trennt Arbeit an Chunk-Grenzen und koordiniert erforderliche EW-World-Frame-/Persistenzschritte, bevor synchronisierte Konvertierungsarbeit freigegeben wird. Ein noch nicht geladener Streaming-Rand-Chunk wird verschoben, statt den gesamten aktuellen Pinselstrich zu blockieren.

Das Ziel ist, dass nahe EW-Peers unterstützten gemalten Weltzustand sehen können, ohne die normale MCM-UI-Aktion remote als rein dateinamenbasierten PixelScene-Aufruf nachzuspielen.

Dabei gelten weiterhin EWs Material-ID-Annahmen: Ein empfangendes Spiel kann kein Material korrekt erzeugen, das dort nicht existiert oder dessen Engine-Materialregister inkompatibel ist.

## Wetter, Besitzergreifung und Weltzustand

Unterstützter MCM-Multiplayerzustand umfasst außerdem Koordination für Wetter, Besitzergreifung und ausgewähltes Weltregel-/Lifecycle-Verhalten. Authority-Prüfungen verhindern, dass zwei Peers gleichzeitig Besitzer desselben Zustands werden.

EW-Unterstützung ist absichtlich konservativ. Wenn die Integration keinen sicheren Synchronisationspfad beweisen kann, bevorzugt MCM korrektes lokales Verhalten, statt jede Einzelspieleroperation fälschlich als automatisch mehrspielersicher darzustellen.

# Kompatibilität und Einschränkungen

Noita stellt viele Systeme über lose gekoppelte Entitäten, XML, Lua-Komponenten und natives Engine-Verhalten bereit. MCM kann deshalb keine universelle Kompatibilität mit jeder modifizierten Entität oder jedem zukünftigen Spielupdate garantieren.

Wichtige Einschränkungen:

- Eine Kreatur kann spawnbar sein, ohne eine sichere Spielerform zu sein.
- Ein Perk kann vergebbar sein, ohne eine zuverlässige inverse Operation zu besitzen.
- Externe Zauber- oder Gegenstandsübergaben lassen sich nicht immer aus einem internen Snapshot rückgängig machen.
- Drittanbieter-Skripte können unterstützte Todes- und Wiederherstellungspfade umgehen.
- Native Wiederherstellungsfunktionen hängen von unterstütztem Noita-Executable-Verhalten ab und deaktivieren sich fail-closed, wenn benötigte Strukturen nicht sicher erkennbar sind.
- Entangled Worlds kann kein Material synchronisieren, das im Register des empfangenden Spiels fehlt.
- Stark modifizierte Inventare, Entitäten oder Weltregeln können mod-spezifische Kompatibilitätsarbeit benötigen.

MCM versucht Ursprungszustand zu bewahren und fehlgeschlagene Mutationen zurückzurollen, aber ein Sandbox-Werkzeug, das live Spielzustand verändert, kann nicht jede Drittanbieter-Mod-Kombination vollständig transaktional machen.

# Gespeicherte Daten

MCM speichert benutzerbezogenen Zustand, der Sitzungen überdauern soll, darunter unterstützte Einstellungen, Tastenbelegungen, Menü-Layout und Zauberstab-Presets.

Die Mod-Identität bleibt stabil, damit normale Updates unterstützte gespeicherte Daten behalten. Beim Installieren eines neuen Standalone-Builds wird trotzdem empfohlen, den ganzen Mod-Ordner zu ersetzen, da das Zusammenführen alter und neuer Dateien veraltete Runtime-Dateien hinterlassen kann.

# Fehlerbehebung

## Der Mod erscheint nicht

Prüfe, ob der Pfad so endet:

`mods/metamorph_creative_menu/mod.xml`

Ein zusätzlicher Archivordner oberhalb von `metamorph_creative_menu` verhindert, dass Noita den Mod korrekt erkennt.

## Native oder Materialfunktionen funktionieren nicht

Prüfe, ob **Unsafe Mods** erlaubt sind und der Standalone-GitHub-Build installiert ist, ohne Dateien mit dem Workshop-Build zu mischen.

## Das Menü öffnet sich, aber gleichzeitig löst eine Spielaktion aus

Prüfe benutzerdefinierte Belegungen auf Konflikte. MCM zeigt doppelte Belegungen an, erlaubt aber bewusst, sie beizubehalten.

## Eine Kreatur lässt sich nicht sicher verwandeln

Nicht jede spawnfähige XML-Entität ist eine unterstützte Spielerform. Für Kreaturen mit Spezialbehandlung existieren Regeln nach exaktem Pfad.

## Ein Perk lässt sich nicht entfernen

Entfernung wird nur angeboten, wenn MCM eine unterstützte inverse Operation für den verfolgten Zustand besitzt. Das ist absichtlich so; geratenes Cleanup kann fremden Spielerzustand beschädigen.

## Multiplayer verhält sich zwischen Peers unterschiedlich

Verwende auf allen Teilnehmern kompatible MCM-Builds und eine kompatible Noita-/Entangled-Worlds-Umgebung. MCM kann kein inkompatibles Materialregister oder beliebige Netzwerkänderungen anderer Mods reparieren.

# Fehler melden

Ein nützlicher Bugreport sollte enthalten:

- was du tun wolltest;
- den exakten MCM-Bereich und die Aktion;
- ob das Problem im Einzelspieler, mit Entangled Worlds oder in beiden Fällen auftritt;
- ob Standalone- oder Workshop-Build installiert ist;
- ob weitere Gameplay-Mods aktiv sind;
- zuverlässige Reproduktionsschritte;
- relevante Noita-/EW-Logs, wenn vorhanden.

Bei Problemen mit Verwandlung, Besitzergreifung, Gegenständen oder Materialien gib nach Möglichkeit die exakte Entität bzw. das Material an. Technische Kennungen sind oft hilfreicher als ein übersetzter Anzeigename.

# Repository und Entwicklungsquelle

Das Repository enthält absichtlich den **vollständigen Entwicklungsbaum** und nicht dasselbe reduzierte Archiv, das Spieler herunterladen.

`metamorph_creative_menu/` enthält Runtime-Code zusammen mit:

- automatisierten Tests;
- QA-Werkzeugen;
- Diagnostik;
- nativem Quellcode;
- Build-Werkzeugen;
- Release-Cleanup-Regeln;
- Entwicklungsdokumentation.

Diese Dateien sind für Entwicklung und Regressionstests nützlich und bleiben daher im GitHub-Source. Das installationsfertige Spieler-ZIP wird separat erzeugt und schließt entwicklungsbezogenen Inhalt aus.

Das Spielerpaket erhält außerdem release-spezifische Bereinigung einschließlich des minimalen Player-`README.txt`, während der Source-Baum seine Entwicklungsdokumentation behält.

# Tests

Die automatisierte Testsuite liegt unter `metamorph_creative_menu/tests/` und kombiniert Python-Contract-Checks mit Lua-Mocktests.

Vom Repository-Root aus führt der Release-Workflow die Suite gegen den vollständig importierten Source aus, bevor ein Spieler-Build veröffentlicht wird. Für die Lua-Mocktests wird `texlua` benötigt.

Source-Hygiene-Prüfungen schützen außerdem produktionsnahe Dateien und Dokumentation vor Resten der Entwicklungshistorie, veralteten Debug-Oberflächen und versehentlichen Prozessartefakten.

# Source-Archiv-Import und Release-Prozess

Vollständiger Entwicklungs-Source kann aus einem Archiv der Familie `Metamorph-Creative-Menu-v...zip` importiert werden.

Der Import-Workflow prüft die Archivstruktur, verlangt die vollständigen Entwicklungsbestandteile, führt Source-Hygiene und Regressionstests aus und committet erst danach den importierten Baum.

Ein ModWorkshop-/Spieler-Archiv wird nicht als Entwicklungsquelle behandelt.

Der öffentliche `latest-build`-Release wird anschließend durch einen getrennten Player-Builder aus dem vollständigen Source erzeugt. Dieser entfernt QA, Tests, Diagnostik, nativen Quellcode und andere rein entwicklungsbezogene Inhalte, wendet Release-Cleanup-Regeln an, validiert das Ergebnis und aktualisiert erst danach das stabile Download-Asset.

Diese Trennung hält das Repository vollständig für Entwicklung nutzbar und den normalen Spielerdownload gleichzeitig klein und frei von Entwicklungsinstrumentierung.

# Drittanbieter-Komponenten

Drittanbieter-Komponenten, gebündelte Abhängigkeiten und Upstream-Projekte sind in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) dokumentiert.
