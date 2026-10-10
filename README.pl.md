<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [**Polski**](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">Kreatywne menu i zestaw narzędzi sandbox dla Noita: zaklęcia, różdżki, przedmioty, materiały, perki, efekty, stworzenia, przemiany, przejmowanie stworzeń, teleportacja, pogoda, zasady świata, integracja multiplayer i narzędzia odzyskiwania.</p>

<p align="center"><strong>Twórca i maintainer: <a href="https://github.com/zerodancing">zerodancing</a></strong></p>

---

# Pobieranie

Do normalnej gry użyj gotowej do instalacji paczki:

[**⬇️ Pobierz najnowszy build**](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)

[Strona najnowszego buildu](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) · [Lista zmian](metamorph_creative_menu/CHANGELOG.txt)

Release GitHub jest tworzony automatycznie z pełnego drzewa deweloperskiego. Testy, narzędzia QA, diagnostyka, natywny kod źródłowy i narzędzia build pozostają w repozytorium, ale nie trafiają do archiwum dla graczy.

Samodzielny build z GitHub zawiera NoitaPatcher i natywne funkcje odzyskiwania, dlatego **Unsafe Mods musi być dozwolone**.

# Instalacja

1. Pobierz `Metamorph-Creative-Menu.zip` z linku powyżej.
2. Uruchom Noita i otwórz **Mods** w menu głównym.
3. Kliknij **Open mods folder**.
4. Wypakuj lub przenieś folder `metamorph_creative_menu` do folderu `mods`. Końcowa ścieżka musi bezpośrednio zawierać `metamorph_creative_menu/mod.xml`, bez dodatkowego katalogu z archiwum.
5. Jeśli starsza kopia jest już zainstalowana, zastąp cały folder `metamorph_creative_menu` zamiast łączyć stare i nowe pliki.
6. Wróć do Noita i odśwież listę modów.
7. Zezwól na **Unsafe Mods**.
8. Włącz **Metamorph: Creative Menu** i rozpocznij grę z aktywnymi modami.

Nie uruchamiaj jednocześnie samodzielnego buildu z GitHub i wersji Steam Workshop.

# Build standalone i Steam Workshop

Build dostępny w tym repozytorium GitHub jest pełną wersją standalone. Zawiera NoitaPatcher i funkcje wymagające nieograniczonego dostępu do mod API, w tym niskopoziomowe operacje na materiałach i natywne odzyskiwanie po Game Over.

[Build Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3785170245) instaluje się osobno. Nie zawiera natywnych komponentów wymaganych przez funkcje dostępne wyłącznie w buildzie standalone.

Oba buildy używają tej samej tożsamości moda. Jednoczesna instalacja może powodować zduplikowane lub konfliktujące pliki i nie jest obsługiwana.

# O modzie

**Metamorph: Creative Menu (MCM)** to kreatywne menu i zestaw narzędzi sandbox dla Noita.

Łączy narzędzia do:

- zaklęć i ekwipunku zaklęć;
- edycji różdżek i wielokrotnego używania presetów;
- przedmiotów i pojemników z cieczami;
- pełnego katalogu materiałów i malowania materiałami;
- perków i obsługiwanego usuwania perków;
- statusów i encji GameEffect;
- stworzeń, przemian i przejmowania stworzeń;
- pogody i czasu;
- globalnych zasad świata;
- teleportacji;
- opcjonalnej integracji z Entangled Worlds;
- odzyskiwania po przemianie, śmierci formy i Game Over.

MCM stara się działać na rzeczywistym stanie Noita zamiast zastępować wszystko dekoracyjnymi kopiami. Istniejące karty zaklęć są przenoszone jako encje, przekazywanie przedmiotów respektuje strukturę ekwipunku, zmiany różdżek korzystają z commit/rollback, materiały pozostają prawdziwymi symulowanymi materiałami, a odwracalne zasady świata zachowują wystarczająco dużo stanu początkowego, aby później przywrócić obsługiwane ustawienia.

Entangled Worlds jest opcjonalny. Bez niego MCM nadal działa jako pełny mod single-player.

# Sterowanie

Domyślne sterowanie:

| Akcja | Domyślne wejście |
| --- | --- |
| Otwórz / zamknij kreatywne menu | **F4** |
| Wróć do ludzkiej formy podczas przemiany | **TAB** |
| Przejmij stworzenie w świecie | **G** |
| Maluj wybranym materiałem | **Środkowy przycisk myszy** |

Panel kreatywny jest też dostępny przez normalny interfejs ekwipunku Noita.

Przypisania można zmieniać w sekcji **CONTROLS** MCM i ustawieniach moda Noita. Obsługiwane są klawisze, przyciski myszy oraz dokładne kombinacje **CTRL / SHIFT / ALT**.

Podczas przypisywania:

- **DELETE / BACKSPACE** usuwa przypisanie;
- **ESC** anuluje;
- **R** przywraca domyślne przypisanie danej akcji;
- **RESET ALL** po potwierdzeniu przywraca wszystkie domyślne przypisania.

Duplikaty przypisań nadal można edytować, ale MCM pokazuje konflikt zamiast po cichu zastępować inną akcję.

Można zmieniać akcje nawigacji menu, sekcji, powrotu z formy, przejmowania stworzeń, malowania materiałami, czyszczenia efektów, zwalniania pogody, resetu zasad świata i obsługiwanych akcji multiplayer.

# Okno Creative Menu

Bezpośredni panel kreatywny jest trwałym, skalowalnym oknem, a nie stałym overlayem debug.

Można go:

- przesuwać za pasek tytułu;
- skalować za krawędzie i rogi;
- minimalizować;
- zamykać;
- przywracać do domyślnego układu.

Pozycja, szerokość, wysokość i ostatnio otwarta sekcja są zapamiętywane pomiędzy uruchomieniami. Po zmianie rozdzielczości zapisane położenie jest ograniczane do widocznego obszaru GUI.

Listy i katalogi korzystają z mierzonych layoutów i kontenerów przewijania Noita. Zmiana rozmiaru okna natychmiast zmienia ilość widocznej treści, a tłumaczone etykiety mogą zawijać się na kilka linii bez nachodzenia na sąsiednie kontrolki. W wąskich układach kontrolki przechodzą do kolejnych wierszy zamiast rysować się jedna na drugiej.

Samo otwarcie lub najechanie kursorem na oddzielne okno nie wyłącza trwale gameplayu. Gdy kliknięcie, przeciąganie lub aktywne pole tekstowe mogłoby jednocześnie uruchomić akcję gracza, MCM tymczasowo blokuje odpowiednie sterowanie i później je przywraca.

# Wyszukiwanie i lokalizacja

Wyszukiwanie działa w głównych katalogach, w tym zaklęć, przedmiotów, materiałów, perków i stworzeń.

W zależności od wpisu może dopasować:

- nazwę w bieżącym języku interfejsu;
- nazwę angielską;
- klucz lokalizacji;
- identyfikator techniczny;
- ścieżkę XML.

Wyszukiwanie ignoruje wielkość liter, normalizuje typowe akcenty i separatory oraz toleruje niewielkie literówki w dłuższych zapytaniach.

Własny interfejs MCM jest zlokalizowany na:

- angielski;
- rosyjski;
- portugalski brazylijski;
- hiszpański;
- niemiecki;
- francuski;
- włoski;
- polski;
- chiński uproszczony;
- japoński;
- koreański.

Dla zwykłej zawartości Noita mod używa kluczy lokalizacji samej gry, gdy jest to możliwe, zamiast utrzymywać duplikaty nazw.

# Zaklęcia

Sekcja zaklęć pracuje zarówno z katalogiem, jak i z istniejącymi encjami zaklęć gracza.

Główny obszar zawiera:

- zwykłe sloty aktywnej różdżki;
- karty **ALWAYS CAST**;
- ekwipunek zaklęć gracza;
- przeszukiwalny katalog zaklęć.

## Szybka zamiana wybranego slotu

Krótki klik wybiera slot różdżki. Następnie krótki klik LMB na zaklęciu z katalogu zastępuje wybrany slot.

To szybka ścieżka zwykłej edycji. Precyzyjne przenoszenie korzysta z drag-and-drop.

## Transakcyjny drag-and-drop

Istniejące karty można przeciągać:

- między slotami różdżki;
- ze zwykłych slotów do **ALWAYS CAST**;
- z **ALWAYS CAST** z powrotem do zwykłych slotów;
- do dokładnego slotu ekwipunku zaklęć;
- z ekwipunku na różdżkę;
- do świata;
- do kosza, jeśli jest to obsługiwane.

Dla istniejącej karty MCM przenosi prawdziwą encję, kiedy to możliwe. Dzięki temu zmienny stan karty, pozostałe użycia i dane dodane przez inne mody nie są tracone tylko dlatego, że karta zmieniła położenie.

Źródło pozostaje nietknięte, dopóki transakcja celu nie zostanie zatwierdzona. Nieprawidłowy lub nieznany cel anuluje operację zamiast usuwać oryginalną kartę. Jedno zwolnienie myszy wykonuje najwyżej jedną zatwierdzoną operację.

Karty katalogu są szablonami i nigdy nie są zużywane przez przeciąganie.

## Always Cast

Karty Always Cast mają własny pasek. Promowanie, cofanie i zamiana uwzględniają efektywną pojemność zwykłych slotów, aby nie powstała nieprawidłowa struktura różdżki.

## Cofnij i ponów

Wewnętrzne zmiany różdżki mają ograniczoną historię **UNDO / REDO**.

Operacje przekazujące prawdziwą encję do świata lub innego ekwipunku nie zawsze mogą być bezpiecznie cofnięte na podstawie snapshotu różdżki, dlatego zewnętrzne handoffy nie są obiecywane jako zawsze odwracalne.

# Różdżki

Obszar różdżki edytuje różdżkę trzymaną aktualnie przez gracza.

Obsługiwane statystyki obejmują:

- pojemność / sloty;
- zaklęcia na strzał;
- czas ładowania;
- opóźnienie między strzałami;
- rozrzut;
- mnożnik prędkości pocisków;
- maksymalną manę;
- szybkość ładowania many;
- odzyskiwanie odrzutu;
- poziom różdżki;
- shuffle;
- zachowanie bez przeładowania.

MCM edytuje też wygląd i powiązane metadane:

- wyświetlaną nazwę;
- blokady różdżki i kart;
- ścieżkę sprite'a;
- przesunięcia sprite'a;
- pozycję strzału.

Wizualny katalog wyglądu korzysta z danych XML różdżek, gdy są dostępne.

## Presety różdżek

Różdżki można zapisywać jako trwałe nazwane presety i używać ich w kolejnych światach lub późniejszych sesjach Noita.

Preset może zachować:

- statystyki różdżki;
- wartości many;
- metadane wizualne;
- zwykłe karty;
- karty Always Cast;
- pozycje slotów;
- pozostałe użycia;
- zamrożony stan kart.

Każdy preset ma dwie osobne operacje:

- **APPLY** zapisuje blueprint na aktualnie trzymanej różdżce;
- **GET COPY** buduje nową różdżkę z tego samego blueprintu.

Kopia trafia do wolnego slotu różdżki w szybkim ekwipunku, jeśli to możliwe. Jeśli nie ma odpowiedniego slotu, ukończona różdżka pozostaje w świecie obok gracza.

Zastępowanie różdżek i ładowanie presetów korzysta z commit/rollback. Jeśli budowa lub umieszczenie się nie powiedzie, MCM próbuje usunąć niekompletne drzewo encji zamiast zostawić uszkodzoną częściową różdżkę.

# Przedmioty i ciecze

## Przedmioty

Krótki **LMB** na wpisie katalogu tworzy jeden obsługiwany przedmiot obok gracza.

**RMB** próbuje przekazać go do odpowiedniej części ekwipunku.

Wpisy katalogu można też przeciągać:

- na zgodny cel w szybkim ekwipunku;
- poza menu do dokładnej pozycji w świecie.

Upuszczenie karty wewnątrz menu bez prawidłowego celu anuluje operację. Karta katalogu jest tylko szablonem i pozostaje dostępna.

MCM respektuje normalny podział szybkiego ekwipunku Noita na sloty różdżek i przedmiotów. Nieudane wczytanie XML, wypełnienie cieczą, przekazanie do ekwipunku lub opcjonalny handoff multiplayer usuwa nową encję, jeśli jest to możliwe.

Niektóre prawdziwe przedmioty ekwipunku znajdują się w katalogach gry zorientowanych na stworzenia. MCM klasyfikuje znane przypadki po zachowaniu, zamiast zakładać, że sama nazwa folderu przesądza, czy coś jest przedmiotem czy stworzeniem.

## Ciecze

Wpisy cieczy tworzą prawdziwe wypełnione pojemniki Noita, a nie dekoracyjne obiekty interfejsu.

Taki pojemnik można nosić, rzucać, rozbić i wylać, a jego zawartość uczestniczy w normalnych reakcjach materiałów.

# Materiały

Sekcja Materials to narzędzie do malowania świata oparte na rzeczywistym rejestrze materiałów Noita.

Katalog jest tworzony z płynów, piasków / proszków, gazów, ognia, ciał stałych oraz powiązanych materiałów statycznych i efektowych zarejestrowanych przez engine. Materiały poprawnie dodane przez inne aktywne mody mogą więc pojawiać się automatycznie.

Odkrywanie materiałów i kosztowna walidacja są rozkładane na ograniczoną pracę zamiast skanować cały katalog w jednej klatce UI.

## Wygląd materiałów

Ciecze używają tej samej prezentacji wypełnionego pojemnika co sekcja przedmiotów.

Dla pozostałych materiałów MCM preferuje tekstury i dane tint z `materials.xml`, w tym definicje dziedziczone. Jeśli brak zdefiniowanej tekstury, fallback korzysta z prawdziwego koloru materiału w engine, a nie losowego koloru podglądu.

## Malowanie

1. Wybierz materiał.
2. Wybierz rozmiar pędzla.
3. Włącz tryb malowania.
4. Zamknij ekwipunek.
5. Przytrzymaj skonfigurowane wejście rysowania w świecie.

Otwarcie ekwipunku zatrzymuje aktywny tryb malowania.

Malowanie nie emituje tylko dekoracyjnych cząstek. MCM umieszcza prawdziwe komórki w świecie odpowiednią dla engine ścieżką. Dynamiczne materiały nadal podlegają symulacji Noita: ciecze płyną, proszki spadają, gazy się przemieszczają, ogień reaguje, a niestabilne substancje mogą zmieniać się przez reakcje materiałowe.

Różne klasy materiałów wymagają różnych strategii umieszczania. Build standalone może użyć bezpośredniego dostępu NoitaPatcher do siatki świata i małego fallbacku PixelScene w przypadkach, których Noita odmawia utworzyć bezpośrednio przy danej współrzędnej tekstury.

Kolejki pracy są ograniczone, aby trzymanie dużego pędzla nie wykonywało celowo nieograniczonej pracy w jednej klatce.

# Perki

## Tworzenie i otrzymywanie perków

**LMB** tworzy normalny pickup wybranego perka w świecie.

Akcja otrzymania może nadać perk pojedynczo albo seriami. Operacje seryjne są obsługiwane jako ograniczone joby zamiast zastosowania wszystkich kopii w jednej klatce UI.

Interfejs pokazuje postęp, a pozostałą pracę można anulować. Kopie już zatwierdzone przed anulowaniem pozostają zastosowane.

Każda przyznana kopia nadal przechodzi normalną ścieżkę stosowania perka zamiast bezpośrednio udawać stan końcowy.

## Usuwanie perków

Usunięcie perka jest znacznie trudniejsze niż jego przyznanie. Perki mogą zmieniać globals, komponenty, encje, statystyki gracza i długotrwałe mechaniki, a Noita nie oferuje jednej uniwersalnej operacji odwrotnej.

Dlatego MCM usuwa tylko stan, dla którego ma wystarczająco bezpieczną śledzoną odwrotność. Dziennik transakcji próbuje usunąć tylko stan należący do konkretnego zastosowania perka, bez resetowania niezależnego stanu gracza.

Jeśli czyszczenie jest częściowe lub nie da się udowodnić jego pełności, pozostaje traktowane jako nieukończone zamiast po cichu zgłaszane jako udane.

Perk z innego moda może dać się przyznać, ale niekoniecznie poprawnie usunąć.

# Efekty

Sekcja Effects stosuje i usuwa obsługiwane statusy materiałowe i encje GameEffect.

Usuwanie uwzględnia własność stanu, kiedy to możliwe. MCM nie usuwa bezmyślnie podobnych ukrytych efektów należących do perków, gry lub innego systemu.

Trwałe efekty utworzone przez MCM używają ograniczonego czyszczenia / wygasania, aby usunięcie jednego efektu MCM nie resetowało stanu innych systemów.

# Stworzenia

Katalog stworzeń zachowuje dokładne ścieżki XML zamiast łączyć wszystkie encje o podobnych nazwach.

Obsługiwane działania:

- **LMB** — tworzy wybraną zdefiniowaną encję obok gracza;
- przeciągnięcie poza menu — tworzy ją w potwierdzonej pozycji kursora świata;
- **RMB** — zmienia gracza w obsługiwaną formę;
- specjalny wpis **PLAYER** — tworzy lub przywraca stan gracza opisany niżej.

Upuszczenie przeciąganej karty z powrotem nad menu anuluje spawn w świecie.

Reguły zgodności dla niebezpiecznych lub nietypowych form opierają się na dokładnych ścieżkach. Sam znajomy fragment nazwy pliku nie sprawia, że encja jest automatycznie traktowana jak inna równoważna forma.

# Przemiany i powrót do ludzkiej formy

Grywalne formy zachowują użyteczny natywny ruch, ataki, wygląd i fizykę, gdy jest to praktyczne. Komponenty bezpośrednio konkurujące z wejściem gracza mogą być wyłączane lub dostosowywane, kiedy formą steruje gracz.

Niektóre złożone stworzenia wymagają dodatkowej logiki zgodności. Bossowie, skryptowe wrappery i mocno fizyczne encje nie muszą zachowywać się dokładnie jak ich oryginalne wersje sterowane przez AI, gdy służą jako forma gracza.

Skonfigurowana akcja powrotu — domyślnie **TAB** — najpierw używa normalnej ścieżki zakończenia przemiany. Jeśli to nie wystarcza, build standalone ma dodatkowe ścieżki odzyskiwania oparte na NoitaPatcher.

W obsługiwanych przypadkach śmiertelnego uszkodzenia MCM próbuje:

- pozostawić martwą tymczasową formę lub ciało w świecie, gdy jest to właściwe;
- przywrócić ludzką encję gracza;
- zwrócić authority i sterowanie;
- zachować ekwipunek;
- przywrócić istotny stan gracza.

To logika odzyskiwania, a nie absolutna nieśmiertelność. Zewnętrzny kill script, niezgodny stan engine lub crash procesu może ominąć obsługiwaną ścieżkę.

# Przejmowanie stworzeń

Przejmowanie pozwala sterować stworzeniem już istniejącym w świecie zamiast wybierać formę z katalogu.

Domyślny klawisz to **G**.

Wskaż odpowiednie stworzenie i użyj akcji przejęcia. MCM sprawdza cel, przygotowuje zgodne przejście i usuwa lub wycofuje oryginalną encję świata dopiero po potwierdzeniu nowego stanu sterowanego przez gracza.

Jeśli przejście się nie powiedzie, oryginalne stworzenie nie powinno po prostu zniknąć.

Funkcja nie ogranicza się do katalogu MCM. Zgodne stworzenie z innego moda może działać, ale uniwersalna zgodność ze wszystkimi encjami zewnętrznymi nie jest gwarantowana.

# Wpis Player

**PLAYER** jest specjalnym wpisem katalogu stworzeń, a nie zwykłym celem polymorph.

Jego akcja spawn tworzy osobną postać podobną do gracza i próbuje skopiować odpowiedni wygląd oraz informacje o maksymalnym zdrowiu.

Użycie akcji transformacji na **PLAYER** nie zamienia już ludzkiego gracza w duplikat. Jeśli gracz jest w innej formie, akcja służy do powrotu do postaci ludzkiej.

# Odzyskiwanie po Game Over w single-player

Build standalone dla single-player zawiera dodatkową ścieżkę odzyskiwania z normalnego ekranu Game Over Noita.

Gdy natywna integracja potrafi bezpiecznie rozpoznać wymagane struktury gry, MCM dodaje do interfejsu Game Over akcję **„I didn't die”**.

Podczas gry MCM utrzymuje aktualizowaną kopię stanu gracza. Uruchomienie odzyskiwania zgłasza prośbę przez zwykłą ścieżkę aktualizacji MCM, zamiast odbudowywać całego gracza bezpośrednio w handlerze kliknięcia UI.

Obsługiwane odzyskiwanie próbuje:

- przywrócić lub uzyskać żywą encję gracza;
- uczynić ją ponownie authoritative;
- wyczyścić stan Game Over engine;
- zwrócić sterowanie i używalny stan gracza;
- wykonać best-effort czyszczenie audio, muzyki i interfejsu Game Over;
- zapewnić krótkie okno ochronne po odzyskaniu.

Natywny helper działa fail-closed. Skanuje uruchomiony obsługiwany executable Noita w poszukiwaniu znanych struktur zamiast pisać pod jeden na stałe zakodowany adres. Jeśli po aktualizacji nie da się bezpiecznie zidentyfikować wymaganych struktur, opcjonalne odzyskiwanie nie jest używane zamiast zapisywać w niepewne miejsce.

# Pogoda i czas

MCM może kontrolować obsługiwany stan pogody i czasu, w tym presety i indywidualne parametry dostępne w bieżącej implementacji.

Wymuszony stan można później oddać normalnej kontroli gry. Na przykład po ustawieniu konkretnej pory MCM może zwolnić to ustawienie, aby naturalny przepływ czasu Noita został wznowiony.

Zmiany pogody są traktowane jako stan sterowany, a nie jednorazowe polecenia konsolowe.

# Zasady świata

Sekcja **RULES** zmienia obsługiwane globalne zachowanie gry.

Reguły obejmują między innymi:

- relacje między stworzeniami;
- zachowanie złota;
- używanie zaklęć;
- fog of war;
- wybrane nagrody za zabójstwa;
- dropy leczenia;
- zachowanie związane z krwią;
- grawitację;
- fizykę;
- siłę kopnięcia;
- połączenia fizyczne;
- cykl dnia i nocy;
- inne obsługiwane parametry globalne.

Głównym celem jest odwracalność.

Dla obsługiwanych reguł MCM zapisuje lub wyprowadza stan początkowy, aby można było później przywrócić ustawienie. Sterowanie mnożnikiem działa względem wartości pierwotnej, zamiast wielokrotnie mnożyć już zmieniony wynik.

Reguły wymagające dotknięcia wielu encji lub obiektów fizycznych korzystają z ograniczonej pracy rozłożonej na klatki zamiast próbować synchronicznie przepisać cały świat jednym kliknięciem.

# Teleportacja

Sekcja teleportacji oferuje przygotowane cele na świecie, w tym miejsca na głównej trasie, Holy Mountains, większe obszary boczne i inne obsługiwane lokacje.

Przed przeniesieniem gracza MCM może poprosić o załadowanie obszaru docelowego i szuka wolnego miejsca w pobliżu zamiast celowo umieszczać gracza w stałym terenie.

Teleportacja nadal zależy od tego, czy świat potrafi załadować i dostarczyć prawidłowe miejsce. Mocno zmodyfikowane światy mogą wymagać zachowania fallback.

# Entangled Worlds

**Entangled Worlds / Noita Proxy jest opcjonalny.** MCM działa bez niego.

Gdy EW jest obecny, MCM włącza dodatkowe funkcje świadome multiplayera. Wszyscy peerzy powinni korzystać ze zgodnych buildów MCM, jeśli opierają się na stanie synchronizowanym przez MCM.

## Authority i formy

Formy gracza wymagają specjalnej obsługi ownership, ponieważ przemieniony gracz nie powinien przypadkowo zostawiać drugiej sieciowej authority.

MCM koordynuje ownership, retirement i powrót do ludzkiej formy z EW, gdy jest to obsługiwane. Encje bossów i podobne do Kolmi mają dodatkową obsługę lifecycle, której celem jest unikanie zduplikowanych authority i starych kopii kontrolowanych przez sieć.

Zwykła ścieżka śmierci EW pozostaje odpowiedzialna za encje nierozpoznane jako stan formy należący do MCM.

## Przedmioty, różdżki i zaklęcia

Gdy to możliwe, MCM używa normalnych mechanizmów item / inventory EW zamiast tworzyć równoległy system transportu.

Zatwierdzone zmiany różdżek i ekwipunku zaklęć żądają odpowiedniego odświeżenia multiplayer, jeśli integracja jest dostępna. Przedmioty świata utworzone przez MCM mogą zostać przekazane do standardowej ścieżki world-item EW.

## Perki

Normalne pickupy perków mogą korzystać ze standardowej synchronizacji world-item EW. Własna obsługa stanu perków MCM koordynuje refresh i ograniczone operacje, aby akcje seryjne nie wykonywały kosztownego globalnego odświeżenia dla każdej kopii.

## Materiały

Malowanie materiałami ma dedykowaną ścieżkę zgodności, ponieważ zmiany komórek świata nie są normalnymi encjami przedmiotów.

MCM utrzymuje ograniczoną pracę malowania, rozdziela ją na granicach chunków i koordynuje wymagane kroki world-frame / persistence EW przed wypuszczeniem zsynchronizowanej konwersji. Nienaładowany chunk na krawędzi streamingu jest odkładany zamiast blokować cały aktywny ruch pędzla.

Celem jest umożliwienie pobliskim peerom EW zobaczenia obsługiwanego namalowanego stanu świata bez zdalnego odtwarzania zwykłej akcji UI MCM jako wywołania PixelScene opartego tylko na nazwie pliku.

Nadal obowiązują założenia EW dotyczące material id: gra odbierająca nie może poprawnie utworzyć materiału, którego nie ma w jej rejestrze albo którego registry engine jest niezgodne.

## Pogoda, przejmowanie i stan świata

Obsługiwany stan multiplayer MCM obejmuje również koordynację pogody, przejmowania oraz wybranych reguł / lifecycle. Kontrole authority zapobiegają sytuacji, w której dwóch peerów próbuje jednocześnie posiadać ten sam stan.

Wsparcie EW jest celowo konserwatywne. Gdy integracja nie może wykazać bezpiecznej ścieżki synchronizacji, MCM wybiera poprawne lokalne zachowanie zamiast udawać, że każda operacja single-player jest automatycznie bezpieczna w multiplayer.

# Zgodność i ograniczenia

Noita udostępnia wiele systemów przez luźno powiązane encje, XML, komponenty Lua i natywne zachowanie engine. MCM nie może więc zagwarantować uniwersalnej zgodności z każdą zmodyfikowaną encją ani przyszłą aktualizacją gry.

Ważne ograniczenia:

- możliwość stworzenia stworzenia nie oznacza, że jest bezpieczną formą gracza;
- możliwość przyznania perka nie oznacza istnienia niezawodnej operacji odwrotnej;
- zewnętrznych transferów zaklęć lub przedmiotów nie zawsze da się cofnąć z wewnętrznego snapshotu;
- zewnętrzne skrypty mogą ominąć obsługiwane ścieżki śmierci i odzyskiwania;
- natywne odzyskiwanie zależy od obsługiwanego zachowania executable Noita i wyłącza się fail-closed, jeśli potrzebnych struktur nie da się rozpoznać;
- Entangled Worlds nie może zsynchronizować materiału nieobecnego w rejestrze gry odbierającej;
- mocno zmienione ekwipunki, encje lub reguły świata mogą wymagać zgodności specyficznej dla konkretnego moda.

MCM próbuje zachować stan pierwotny i wycofywać nieudane mutacje, ale narzędzie sandbox modyfikujące żywy stan gry nie może zapewnić pełnej transakcyjności każdej kombinacji zewnętrznych modów.

# Zapisane dane

MCM zachowuje stan użytkownika, który powinien przeżyć kolejne uruchomienia, w tym obsługiwane ustawienia, przypisania, układ menu i presety różdżek.

Tożsamość moda pozostaje stabilna, więc normalne aktualizacje mogą zachować obsługiwane dane. Przy instalacji nowego buildu standalone nadal zaleca się zastąpić cały folder moda, ponieważ łączenie starych i nowych plików może pozostawić przestarzały runtime.

# Rozwiązywanie problemów

## Mod się nie pojawia

Sprawdź, czy ścieżka kończy się na:

`mods/metamorph_creative_menu/mod.xml`

Dodatkowy folder archiwum nad `metamorph_creative_menu` uniemożliwia Noita poprawne wykrycie moda.

## Funkcje natywne lub materiałowe nie działają

Sprawdź, czy **Unsafe Mods** jest dozwolone i czy zainstalowany jest build standalone GitHub bez mieszania plików Workshop.

## Menu się otwiera, ale uruchamia się również akcja w grze

Sprawdź konflikty własnych przypisań. MCM pokazuje duplikaty, ale pozwala je zachować, jeśli tego chcesz.

## Nie można bezpiecznie przemienić się w stworzenie

Nie każda spawnująca się encja XML jest obsługiwaną formą gracza. Dla stworzeń wymagających specjalnej obsługi istnieją reguły oparte na dokładnych ścieżkach.

## Nie można usunąć perka

Usuwanie jest dostępne tylko tam, gdzie MCM ma obsługiwaną operację odwrotną dla śledzonego stanu. To celowe — zgadywane czyszczenie może uszkodzić niezwiązany stan gracza.

## Multiplayer działa inaczej między peerami

Używaj zgodnych buildów MCM u wszystkich uczestników i zgodnego środowiska Noita / Entangled Worlds. MCM nie może naprawić niezgodnego rejestru materiałów ani dowolnych zmian sieciowych innych modów.

# Zgłaszanie błędów

Dobry raport powinien zawierać:

- co próbowałeś zrobić;
- dokładną sekcję i akcję MCM;
- czy problem występuje w single-player, Entangled Worlds czy obu;
- czy zainstalowany jest build standalone czy Workshop;
- czy aktywne są inne mody gameplay;
- pewne kroki reprodukcji;
- odpowiednie logi Noita / EW, jeśli są dostępne.

Przy problemach z przemianą, przejmowaniem, przedmiotem lub materiałem podaj dokładną encję lub materiał, jeśli to możliwe. Identyfikator techniczny jest często bardziej przydatny niż przetłumaczona nazwa wyświetlana.

# Repozytorium i źródła deweloperskie

Repozytorium celowo zawiera **pełne drzewo deweloperskie**, a nie to samo odchudzone archiwum pobierane przez graczy.

`metamorph_creative_menu/` zawiera kod runtime razem z:

- testami automatycznymi;
- narzędziami QA;
- diagnostyką;
- natywnym kodem źródłowym;
- narzędziami build;
- regułami czyszczenia release;
- dokumentacją deweloperską.

Te pliki są potrzebne do rozwoju i testów regresji, dlatego pozostają w source GitHub. Gotowy ZIP dla graczy jest generowany osobno i wyklucza zawartość tylko deweloperską.

Paczka gracza otrzymuje też czyszczenie specyficzne dla release, w tym minimalny player `README.txt`, podczas gdy drzewo source zachowuje dokumentację deweloperską.

# Testy

Automatyczny zestaw testów znajduje się w `metamorph_creative_menu/tests/` i łączy testy kontraktowe Python z mockami Lua.

Z root repozytorium workflow release uruchamia testy na pełnym zaimportowanym source przed opublikowaniem buildu dla graczy. `texlua` jest wymagane dla części mocków Lua.

Kontrole source hygiene chronią też pliki skierowane do produkcji i dokumentację przed resztkami historii rozwoju, starymi powierzchniami debug i przypadkowymi artefaktami procesu.

# Import source i proces release

Pełny source deweloperski może zostać zaimportowany z archiwum rodziny `Metamorph-Creative-Menu-v...zip`.

Workflow importu sprawdza strukturę, wymaga pełnych komponentów deweloperskich, uruchamia source hygiene i zestaw regresyjny przed commitowaniem zaimportowanego drzewa.

Archiwum w stylu ModWorkshop / player nie jest traktowane jako source deweloperski.

Publiczny release `latest-build` jest następnie tworzony z pełnego source przez oddzielny player-builder. Usuwa on QA, testy, diagnostykę, natywny kod źródłowy i inne payloady deweloperskie, stosuje reguły czyszczenia, waliduje wynikowe archiwum i dopiero wtedy aktualizuje stabilny asset do pobrania.

To rozdzielenie pozwala repozytorium pozostać pełną bazą do rozwoju, a normalnemu downloadowi gracza być małym i pozbawionym instrumentacji deweloperskiej.

# Komponenty zewnętrzne

Komponenty firm trzecich, dołączone zależności i projekty upstream są opisane w [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
