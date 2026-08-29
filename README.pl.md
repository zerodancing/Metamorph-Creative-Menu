<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">
  Kreatywny zestaw narzędzi do Noity: zaklęcia, różdżki, przedmioty, materiały, perki, stworzenia, efekty, teleportacja, pogoda i zasady świata.
</p>

<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [**Polski**](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## Pobieranie

Aktualna wersja: **2.0.0**

| Pakiet | Pobieranie |
|---|---|
| **Najnowsza wersja gotowa do instalacji** | **[⬇️ Pobierz Metamorph-Creative-Menu.zip](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)** |
| Strona wersji | [Najnowsza wersja gotowa do instalacji](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) |

> ZIP zawiera już kompletny folder `metamorph_creative_menu`, łącznie z dołączonym NoitaPatcherem. Wypakuj ten folder bezpośrednio do `Noita/mods/`.

Prawidłowa ścieżka końcowa:

```text
Noita/mods/metamorph_creative_menu/mod.xml
```

Jeżeli otrzymasz `metamorph_creative_menu/metamorph_creative_menu/mod.xml`, archiwum zostało wypakowane o jeden poziom folderu za głęboko.

---

## Polski

### Instalacja

1. [Pobierz najnowszy ZIP gotowy do instalacji](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Całkowicie zamknij Noitę przed instalacją lub aktualizacją moda.
3. W Steam otwórz **Biblioteka → prawy przycisk na Noita → Zarządzaj → Przeglądaj pliki lokalne**.
4. Otwórz folder `mods` gry i skopiuj do niego cały folder **`metamorph_creative_menu`**.
5. Sprawdź, czy istnieje `Noita/mods/metamorph_creative_menu/mod.xml`. Nie zmieniaj nazwy folderu moda.
6. Uruchom Noitę, włącz **Metamorph: Creative Menu**, zezwól na **Unsafe mods / unrestricted API**, jeśli jest to wymagane, i uruchom Noitę ponownie po włączeniu moda.
7. Rozpocznij grę i naciśnij **TAB**. Jeśli menu się otworzy, instalacja jest zakończona.

**Aktualizacja:** zamknij Noitę, usuń stary folder `metamorph_creative_menu`, a następnie skopiuj nowy do `mods`. Pełna wymiana folderu zapobiega pozostawieniu przestarzałych plików z wcześniejszych wersji.

### Sterowanie

- **F4 lub TAB**: otwiera lub zamyka Creative Menu.
- **TAB podczas przemiany**: powrót do ludzkiej postaci.
- **G** domyślnie: przejęcie kontroli nad obsługiwaną istotą pod kursorem.
- **Środkowy przycisk myszy**: rysowanie wybranym materiałem.
- Przypisania można zmieniać w sekcji STEROWANIE lub w ustawieniach moda. Dostępne działania lewego i prawego przycisku myszy są pokazane w interfejsie.

### Co potrafi MCM

- Pobierać i umieszczać zaklęcia oraz przenosić je między różdżkami, miejscami Zawsze rzucane, ekwipunkiem i światem gry.
- Edytować statystyki, wygląd i blokady różdżek; zapisywać ustawienia różdżek i tworzyć kopie.
- Tworzyć przedmioty obok gracza lub w wybranym miejscu świata oraz umieszczać obsługiwane przedmioty bezpośrednio w ekwipunku.
- Tworzyć butelki z wybranymi cieczami.
- Wybierać materiały i rysować nimi w świecie.
- Tworzyć, dodawać i usuwać perki.
- Tworzyć stworzenia obok gracza lub w wybranym miejscu świata.
- Przemieniać się w stworzenia, przejmować kontrolę nad istniejącymi stworzeniami i wracać do ludzkiej postaci.
- Tworzyć osobną encję PLAYER.
- Nakładać i usuwać efekty gry.
- Zmieniać pogodę, porę dnia, grawitację i inne zasady świata.
- Teleportować się do miejsc w świecie gry.
- Z Entangled Worlds teleportować się do innych graczy lub sprowadzać ich do siebie.
- Zmieniać przypisania klawiszy i przeszukiwać katalogi zaklęć, przedmiotów, materiałów, perków i stworzeń.
- Przesuwać i zmieniać rozmiar okna menu; jego pozycja i rozmiar są zachowywane między uruchomieniami gry.

<details>
<summary><strong>Przemiany, zgodność i odzyskiwanie postaci</strong></summary>

MCM korzysta z danych zgodności opartych na dokładnych ścieżkach XML oraz z wąskich wyjątków bezpiecznego kierowania dla encji, o których wiadomo, że są niebezpieczne lub nieodpowiednie do bezpośredniej natywnej przemiany. Formy kontrolowane przez gracza próbują zachować przydatny natywny ruch, ataki, wygląd i fizykę, a jednocześnie wyłączają sztuczną inteligencję, która kolidowałaby ze sterowaniem gracza. Złożeni bossowie, silnie oskryptowane encje i obiekty fizyczne mogą wymagać osobnych adapterów i nie zawsze odwzorowują dokładnie każde zachowanie oryginalnej sztucznej inteligencji.

NoitaPatcher jest używany do mechanizmów awaryjnego odzyskiwania, między innymi serializacji i deserializacji encji, przekazywania kontroli nad encją gracza oraz innych zaawansowanych funkcji wykonywanych podczas gry. Z tego powodu pełna, samodzielna wersja wymaga dostępu moda bez ograniczeń.

</details>

<details>
<summary><strong>Integracja wieloosobowa z Entangled Worlds</strong></summary>

**Entangled Worlds jest opcjonalny.** MCM został zaprojektowany tak, aby działać jako pełny mod dla jednego gracza bez EW.

Gdy `quant.ew` jest aktywny, MCM włącza eksperymentalną integrację dla współdzielonych przedmiotów, perków, pogody, zasad świata, form i przejmowania stworzeń, żądań dotyczących towarzysza oraz powiązanych mechanizmów własności i synchronizacji. Wszyscy uczestnicy powinni używać tej samej wersji MCM. Obsługa wielu graczy jest celowo uznawana za eksperymentalną, ponieważ nie da się zagwarantować idealnej synchronizacji w każdej sytuacji brzegowej Noity i EW.

</details>

### Wymagania i komponenty zewnętrzne

- **Noita** — wymagana gra, autorstwa Nolla Games.
- **NoitaPatcher** autorstwa dextercd — dołączony do MCM i używany do zaawansowanych funkcji oraz odzyskiwania.
- **lbase64** autorstwa Ilya Kolbin — dołączona lokalna implementacja Base64.
- **Entangled Worlds / Noita Proxy** autorstwa IntQuant i współtwórców — opcjonalna integracja wieloosobowa; nie jest wymagana dla jednego gracza.

Dokładne linki do projektów źródłowych, ścieżki dołączonych komponentów oraz informacje o licencjach i ich stanie znajdują się w [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### Rozwiązywanie problemów

- **TAB nic nie robi:** sprawdź dokładną ścieżkę `mod.xml`, upewnij się, że MCM jest włączony, zezwól na Unsafe mods/unrestricted API i uruchom Noitę ponownie.
- **Brakuje rozszerzonego odzyskiwania lub części zasad świata:** sprawdź, czy istnieje `metamorph_creative_menu/NoitaPatcher/noitapatcher.dll` i czy dostęp unrestricted API jest dozwolony.
- **Forma nie wraca poprawnie:** podaj dokładną nazwę lub XML stworzenia i określ, czy nie zadziałał zwykły powrót przez TAB, czy powrót po śmiertelnych obrażeniach.
- **Rozbieżność synchronizacji EW:** sprawdź, czy wszyscy używają tej samej wersji MCM i zgodnej wersji EW.

### Linki

- [Najnowsza wersja](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build)
- [Zgłoś błąd](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)
- [Komponenty zewnętrzne](THIRD_PARTY_NOTICES.md)
- [Noita](https://noitagame.com/)
- [NoitaPatcher](https://github.com/dextercd/NoitaPatcher)
- [Dokumentacja NoitaPatcher](https://dexter.döpping.eu/NoitaPatcher/)
- [Entangled Worlds](https://github.com/IntQuant/noita_entangled_worlds)
- [lbase64](https://github.com/iskolbin/lbase64)

[↑ Wróć do wyboru języka](#languages)

---

## Dla deweloperów

Grywalny mod znajduje się w `metamorph_creative_menu/`.

- Informacje o architekturze i uwagi dla deweloperów: `metamorph_creative_menu/README.txt`
- Zestaw testów regresyjnych: `metamorph_creative_menu/tests/`
- Instrukcje uruchamiania testów: `metamorph_creative_menu/tests/TESTING.txt`
- Informacje o komponentach zewnętrznych: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)

Automatyczny proces `latest-build` w repozytorium pakuje grywalny folder `metamorph_creative_menu` do ZIP-a gotowego do instalacji i aktualizuje podany wyżej stały adres pobierania.