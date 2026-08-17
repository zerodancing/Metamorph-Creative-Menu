# Metamorph: Creative Menu — Polski

[English](README.en.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es-ES.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## O modzie

**Metamorph: Creative Menu (MCM)** to kreatywne/deweloperskie menu dla **Noita**. Działa samodzielnie w trybie jednoosobowym i oferuje opcjonalną eksperymentalną kompatybilność z **Entangled Worlds / Noita Proxy**.

Pozwala edytować różdżki, tworzyć lub odbierać przedmioty, nakładać i usuwać perki/efekty, przemieniać się w stworzenia, przejmować istniejącego moba pod kursorem, zmieniać pogodę i zasady świata oraz tworzyć sojusznika podobnego do gracza.

## Wymagania i instalacja

- Zainstalowana Noita.
- `metamorph_creative_menu` w `Noita/mods/`.
- Włącz **Unsafe mods / unrestricted API** — dołączony natywny NoitaPatcher tego wymaga.
- Entangled Worlds jest **opcjonalny**.

1. Pobierz build z [Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases) albo pobierz/sklonuj repozytorium.
2. Skopiuj `metamorph_creative_menu` do `Noita/mods/`.
3. Sprawdź `Noita/mods/metamorph_creative_menu/mod.xml`.
4. Włącz Unsafe mods, a następnie Metamorph: Creative Menu.

Nie zmieniaj nazwy wewnętrznego folderu.

## Sterowanie

- **TAB** — otwiera/zamyka menu.
- **TAB podczas przemiany** — powrót do człowieka.
- **G** domyślnie — przejęcie/przemiana w kompatybilnego stwora pod kursorem; klawisz można zmienić.
- LPM/PPM mają różne akcje zależnie od zakładki i są opisane w UI.

## Funkcje

### Czary
Trzymaj różdżkę, wybierz slot i czar z katalogu z kategoriami/wyszukiwaniem. Można zastępować, usuwać i wyrzucać czary. Stary czar jest usuwany dopiero po sprawdzeniu nowego.

### Przedmioty
Kontenery, ciecze, kamienie, jaja, różdżki, książki, bonusy, orby, przedmioty questowe i inne.
- **LPM:** utwórz obok.
- **PPM:** spróbuj dodać bezpośrednio do ekwipunku.
- Gdy brak miejsca lub pickup się nie uda, przedmiot zostaje w świecie.
- Obsługiwane są napełnione butelki/kontenery.

### Perki
- **ADD:** LPM tworzy pickup; PPM stosuje perk bezpośrednio.
- **REMOVE:** LPM usuwa jeden stack; PPM próbuje usunąć wszystkie.
MCM śledzi wiele zmian należących do perka, aby odtworzyć jego encje, komponenty i wartości bez celowego nadpisywania zmian innych systemów. Bez bezpiecznego inverse ryzykowne usunięcie może zostać odrzucone.

### Wyszukiwanie
Duże katalogi można przeszukiwać po przetłumaczonej nazwie, ID i/lub opisie.

### Stworzenia, obiekty i formy
- **LPM:** spawn.
- **PPM:** transformacja.
- **TAB:** człowiek.

Kompatybilność jest przechowywana według dokładnej ścieżki XML. Wybrane niebezpieczne wrappery używają bezpiecznego celu kanonicznego tylko do transformacji. Formy gracza próbują zachować użyteczne ataki, ruch, wygląd i fizykę, wyłączając konkurującą AI. Złożone encje mogą używać przybliżonych adapterów.

### Powrót i śmierć formy
TAB najpierw wykorzystuje natywny lifecycle polymorph Noita. MCM przechowuje też serializowany backup człowieka dzięki NoitaPatcher.

Przy śmiertelnych obrażeniach **death handoff** próbuje pozwolić umrzeć ciału stwora, ale przekazać kontrolę odtworzonemu człowiekowi, aby śmierć formy nie kończyła automatycznie runu.

### Przejęcie
Wyceluj w kompatybilnego stwora i naciśnij **G**. MCM wykorzystuje kompatybilną formę celu i usuwa/wycofuje oryginalny cel, aby nie tworzyć zwykłego duplikatu.

### Towarzysz PLAYER
Wpis `PLAYER` tworzy sojusznika podobnego do gracza. Z odpowiednimi możliwościami NoitaPatcher może używać skopiowanej różdżki bardziej jak prawdziwy gracz.

### Efekty
Nakładaj statusy/efekty czasowe, wybieraj czas trwania tam, gdzie jest obsługiwany, i usuwaj efekty z zachowaniem chronionych stanów wewnętrznych/perków, gdy to możliwe.

### Pogoda
Pory: rano, dzień, wieczór, noc. Presety: czysto, pochmurno, mgła, burza. Advanced steruje obsługiwanymi wartościami czasu, chmur, mgły, wiatru, prędkości wiatru, deszczu i błyskawic. **RELEASE** przestaje utrzymywać override.

### Zasady świata
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

## Solo i Entangled Worlds

**EW nie jest potrzebny w solo.** MCM zawiera NoitaPatcher i lokalny kodek Base64.

Po włączeniu `quant.ew` aktywuje się eksperymentalna integracja przedmiotów, perków, pogody, zasad, form/przejęcia, companionów i patchy kompatybilności. Jeśli EW już udostępnia zgodne API NoitaPatcher, MCM może je wykorzystać.

Multiplayer jest **eksperymentalny/częściowy**. Host i klient mają mieć te same prawa MCM, ale nie każdy edge case Noita/EW jest gwarantowany. Wszyscy powinni używać tej samej wersji MCM.

## Problemy i raporty

- Brak menu: sprawdź ścieżkę i aktywację.
- Brak funkcji rozszerzonych: włącz Unsafe mods i sprawdź `NoitaPatcher/noitapatcher.dll`.
- Problem z formą: podaj dokładną nazwę/XML i rodzaj nieudanego powrotu.
- EW: podaj wersje MCM i EW.

Błędy: [GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues).

## Zależności i podziękowania

MCM zawiera **NoitaPatcher** (dextercd) i **lbase64** (Ilya Kolbin), a opcjonalnie integruje **Noita Entangled Worlds** (IntQuant i współtwórcy). Szczegóły: [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

## Linki

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

## Rozwój

Grywalny mod: `metamorph_creative_menu/`. Testy i kontrakty: `metamorph_creative_menu/tests/`. Nie wybrano jeszcze ogólnej licencji dla oryginalnego kodu MCM.
