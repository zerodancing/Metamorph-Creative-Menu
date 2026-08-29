<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">
  Ein Kreativwerkzeug für Noita: Zauber, Zauberstäbe, Gegenstände, Materialien, Perks, Kreaturen, Effekte, Teleportation, Wetter und Weltregeln.
</p>

<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es.md) · [**Deutsch**](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## Download

Aktuelle Version: **2.0.0**

| Paket | Download |
|---|---|
| **Neueste installationsfertige Version** | **[⬇️ Metamorph-Creative-Menu.zip herunterladen](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)** |
| Versionsseite | [Neueste installationsfertige Version](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) |

> Das ZIP enthält bereits den vollständigen Ordner `metamorph_creative_menu` einschließlich des mitgelieferten NoitaPatcher. Entpacke diesen Ordner direkt nach `Noita/mods/`.

Korrekter Zielpfad:

```text
Noita/mods/metamorph_creative_menu/mod.xml
```

Wenn du bei `metamorph_creative_menu/metamorph_creative_menu/mod.xml` landest, wurde das Archiv eine Ordnerebene zu tief entpackt.

---

## Deutsch

### Installation

1. [Lade das neueste installationsfertige ZIP herunter](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Beende Noita vor der Installation oder Aktualisierung vollständig.
3. Öffne in Steam **Bibliothek → Rechtsklick auf Noita → Verwalten → Lokale Dateien durchsuchen**.
4. Öffne den Ordner `mods` des Spiels und kopiere den vollständigen Ordner **`metamorph_creative_menu`** hinein.
5. Prüfe, ob `Noita/mods/metamorph_creative_menu/mod.xml` vorhanden ist. Benenne den Mod-Ordner nicht um.
6. Starte Noita, aktiviere **Metamorph: Creative Menu**, erlaube bei Bedarf **Unsafe mods / unrestricted API** und starte Noita nach der Aktivierung neu.
7. Starte einen Run und drücke **TAB**. Wenn das Menü erscheint, ist die Installation abgeschlossen.

**Aktualisierung:** Beende Noita, lösche den alten Ordner `metamorph_creative_menu` und kopiere den neuen nach `mods`. Das vollständige Ersetzen verhindert, dass veraltete Dateien früherer Versionen zurückbleiben.

### Steuerung

- **F4 oder TAB**: Creative Menu öffnen oder schließen.
- **TAB während einer Verwandlung**: zur menschlichen Form zurückkehren.
- **G** standardmäßig: die Kontrolle über eine unterstützte Kreatur unter dem Cursor übernehmen.
- **Mittlere Maustaste**: mit dem ausgewählten Material zeichnen.
- Tastenbelegungen können im Bereich STEUERUNG oder in den Mod-Einstellungen geändert werden. Die verfügbaren Aktionen für linke und rechte Maustaste werden in der Oberfläche angezeigt.

### Was MCM kann

- Zauber aufnehmen und platzieren sowie zwischen Zauberstäben, Immer-Wirken-Plätzen, Inventar und Spielwelt verschieben.
- Werte, Aussehen und Sperren von Zauberstäben bearbeiten; Vorlagen speichern und Kopien erstellen.
- Gegenstände in der Nähe des Spielers oder an einer gewählten Weltposition erzeugen und unterstützte Gegenstände direkt ins Inventar legen.
- Flaschen mit ausgewählten Flüssigkeiten erstellen.
- Materialien auswählen und in die Spielwelt zeichnen.
- Perks erzeugen, hinzufügen und entfernen.
- Kreaturen in der Nähe des Spielers oder an einer gewählten Weltposition erzeugen.
- Sich in Kreaturen verwandeln, die Kontrolle über vorhandene Kreaturen übernehmen und zur menschlichen Form zurückkehren.
- Eine separate PLAYER-Entität erzeugen.
- Spieleffekte anwenden und entfernen.
- Wetter, Tageszeit, Gravitation und andere Weltregeln ändern.
- Zu Orten in der Spielwelt teleportieren.
- Mit Entangled Worlds zu anderen Spielern teleportieren oder sie zu dir holen.
- Tastenbelegungen ändern und die Kataloge für Zauber, Gegenstände, Materialien, Perks und Kreaturen durchsuchen.
- Das Menüfenster verschieben und skalieren; Position und Größe bleiben zwischen Spielstarts erhalten.

<details>
<summary><strong>Verwandlungen, Kompatibilität und Wiederherstellung</strong></summary>

MCM verwendet Kompatibilitätsdaten anhand exakter XML-Pfade und eng begrenzte sichere Ausnahmen für Entitäten, die für eine direkte native Verwandlung als gefährlich oder ungeeignet bekannt sind. Vom Spieler kontrollierte Formen versuchen nützliche native Bewegung, Angriffe, Darstellung und Physik beizubehalten, während KI-Komponenten deaktiviert werden, die mit der Spielereingabe konkurrieren würden. Komplexe Bosse, stark geskriptete Entitäten und Physikobjekte können eigene Adapter benötigen und bilden nicht immer jedes ursprüngliche KI-Verhalten exakt nach.

NoitaPatcher wird für robuste Wiederherstellungsmechanismen verwendet, darunter Serialisierung und Deserialisierung von Entitäten, die Übergabe der Spielerentität sowie weitere erweiterte Laufzeitfunktionen. Deshalb fordert die vollständige eigenständige Version uneingeschränkten Mod-Zugriff an.

</details>

<details>
<summary><strong>Mehrspieler-Integration mit Entangled Worlds</strong></summary>

**Entangled Worlds ist optional.** MCM ist so ausgelegt, dass es im Einzelspieler vollständig ohne EW funktioniert.

Wenn `quant.ew` aktiv ist, schaltet MCM eine experimentelle Integration für gemeinsam behandelte Gegenstände, Perks, Wetter, Weltregeln, Formen und Kreaturenkontrolle, Begleiteranfragen sowie zugehörige Autoritäts- und Synchronisationsabläufe frei. Alle Teilnehmer sollten dieselbe MCM-Version verwenden. Der Mehrspielermodus gilt bewusst als experimentell, weil sich nicht jeder Sonderfall von Noita und EW garantiert perfekt synchronisieren lässt.

</details>

### Voraussetzungen und Drittanbieter-Komponenten

- **Noita** — erforderliches Spiel von Nolla Games.
- **NoitaPatcher** von dextercd — in MCM enthalten und für erweiterte Laufzeit- und Wiederherstellungsfunktionen genutzt.
- **lbase64** von Ilya Kolbin — mitgelieferte lokale Base64-Implementierung.
- **Entangled Worlds / Noita Proxy** von IntQuant und Mitwirkenden — optionale Mehrspieler-Integration; für Einzelspieler nicht erforderlich.

Exakte Upstream-Links, Pfade der enthaltenen Komponenten sowie Hinweise zu Lizenz und Status stehen in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Fehlerbehebung

- **TAB bewirkt nichts:** Prüfe den genauen Pfad zu `mod.xml`, ob MCM aktiviert ist, erlaube Unsafe mods/unrestricted API und starte Noita neu.
- **Erweiterte Wiederherstellung oder Teile der Weltregeln fehlen:** Prüfe, ob `metamorph_creative_menu/NoitaPatcher/noitapatcher.dll` vorhanden ist und unrestricted API erlaubt wurde.
- **Eine Form kehrt nicht korrekt zurück:** Melde den genauen Kreaturennamen beziehungsweise XML-Pfad und ob die normale Rückkehr mit TAB oder die Rückkehr nach tödlichem Schaden fehlgeschlagen ist.
- **EW ist nicht synchron:** Prüfe, ob alle dieselbe MCM-Version und eine kompatible EW-Version verwenden.

### Links

- [Neueste Version](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build)
- [Fehler melden](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)
- [Drittanbieter-Hinweise](THIRD_PARTY_NOTICES.md)
- [Noita](https://noitagame.com/)
- [NoitaPatcher](https://github.com/dextercd/NoitaPatcher)
- [NoitaPatcher-Dokumentation](https://dexter.döpping.eu/NoitaPatcher/)
- [Entangled Worlds](https://github.com/IntQuant/noita_entangled_worlds)
- [lbase64](https://github.com/iskolbin/lbase64)

[↑ Zur Sprachauswahl](#languages)

---

## Für Entwickler

Der spielbare Mod befindet sich in `metamorph_creative_menu/`.

- Architektur- und Entwicklerhinweise: `metamorph_creative_menu/README.txt`
- Regressionstest-Suite: `metamorph_creative_menu/tests/`
- Testanleitung: `metamorph_creative_menu/tests/TESTING.txt`
- Drittanbieter-Hinweise: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)

Der automatische `latest-build`-Workflow des Repositories verpackt den spielbaren Ordner `metamorph_creative_menu` in ein installationsfertiges ZIP und aktualisiert die oben angegebene stabile Download-Adresse.