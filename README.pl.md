<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [**Polski**](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">Kreatywne menu i zestaw narzędzi do Noity: zaklęcia, różdżki, przedmioty, materiały, perki, stworzenia, przemiany, efekty, teleportacja, pogoda, zasady świata i wiele więcej.</p>

<p align="center"><strong>Wersja 2.0.0</strong></p>

---

# Pobieranie

[**⬇️ Pobierz najnowszą wersję moda**](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)

Aktualna wersja: **2.0.0**

**Pełna wersja wymaga zezwolenia na niebezpieczne mody.**

[Strona najnowszej kompilacji](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build)

[Lista zmian w wersji 2.0.0](metamorph_creative_menu/CHANGELOG.txt)

# Spis treści

- [Instalacja](#instalacja)
- [Pełna wersja i wersja z Warsztatu Steam](#pełna-wersja-i-wersja-z-warsztatu-steam)
- [O modzie](#o-modzie)
- [Sterowanie i interfejs](#sterowanie-i-interfejs)
- [Zaklęcia](#zaklęcia)
- [Różdżki](#różdżki)
- [Przedmioty i ciecze](#przedmioty-i-ciecze)
- [Materiały](#materiały)
- [Perki](#perki)
- [Efekty](#efekty)
- [Stworzenia i przemiany](#stworzenia-i-przemiany)
- [Powrót po przemianie i śmierci formy](#powrót-po-przemianie-i-śmierci-formy)
- [Przejęcie kontroli nad stworzeniem](#przejęcie-kontroli-nad-stworzeniem)
- [Gracz](#gracz)
- [Pogoda i pora dnia](#pogoda-i-pora-dnia)
- [Zasady świata](#zasady-świata)
- [Teleportacja](#teleportacja)
- [Entangled Worlds](#entangled-worlds)
- [NoitaPatcher i niebezpieczne mody](#noitapatcher-i-niebezpieczne-mody)
- [Jeśli coś nie działa](#jeśli-coś-nie-działa)
- [Zgłaszanie błędu](#zgłaszanie-błędu)

# Instalacja

1. [Pobierz najnowszą wersję moda](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip).
2. Uruchom Noitę i w menu głównym otwórz sekcję **Mody**.
3. Kliknij **Otwórz folder modów**.
4. Przenieś folder `metamorph_creative_menu` z pobranego archiwum do otwartego folderu `mods`. Jeśli `metamorph_creative_menu` już tam istnieje, usuń stary folder i zastąp go nowym.
5. Zamknij folder modów.
6. W menu modów kliknij **Odśwież**. Na liście powinien pojawić się **Metamorph: Creative Menu**.
7. Kliknij **Niebezpieczne mody**, aż napis stanie się czerwony i będzie wyświetlane **Niebezpieczne mody: Dozwolone**.
8. Kliknij nazwę moda, aby została podświetlona i pojawiło się przed nią **[x]**. Oznacza to, że mod jest włączony.
9. Kliknij **Rozpocznij nową grę z aktywnymi modami**.
10. Wybierz tryb gry i graj.

# Pełna wersja i wersja z Warsztatu Steam

Kompilacja dostępna na tej stronie GitHub jest pełną wersją MCM. Zawiera NoitaPatcher i funkcje wymagające zezwolenia na niebezpieczne mody.

[Wersja z Warsztatu Steam](https://steamcommunity.com/sharedfiles/filedetails/?id=3785170245) jest instalowana osobno. Nie zawiera NoitaPatchera ani funkcji pełnej wersji, które wymagają dostępu dla niebezpiecznych modów.

Nie instaluj ani nie włączaj obu wersji jednocześnie.

# O modzie

**Metamorph: Creative Menu (MCM)** to kreatywne menu i zestaw narzędzi do Noity.

Łączy w jednym interfejsie pracę z zaklęciami, różdżkami, przedmiotami, materiałami, perkami, efektami, stworzeniami, przemianami, pogodą, globalnymi zasadami świata i teleportacją.

MCM nadaje się zarówno do swobodnej gry kreatywnej, jak i do eksperymentowania z mechanikami Noity. Wiele operacji nie polega na prostym utworzeniu nowej encji — uwzględniają one istniejący stan różdżki, przedmiotu, formy, perka lub świata.

**Entangled Worlds nie jest wymagany.** Bez niego MCM działa jako pełnoprawny mod dla jednego gracza. Po zainstalowaniu Entangled Worlds dostępne stają się dodatkowe eksperymentalne funkcje wieloosobowe.

# Sterowanie i interfejs

| Działanie | Klawisz |
| --- | --- |
| Otwórz / zamknij menu kreatywne | **F4 lub TAB** |
| Wróć do ludzkiej postaci | **TAB podczas przemiany** |
| Przejmij kontrolę nad stworzeniem | **G** |
| Rysuj wybranym materiałem | **Środkowy przycisk myszy** |

Panel MCM jest również dostępny przez zwykły interfejs ekwipunku.

Przypisania można zmienić w sekcji **STEROWANIE** albo w ustawieniach moda.

Podczas przypisywania klawisza:

- **DELETE / BACKSPACE** — wyczyść przypisanie;
- **ESC** — anuluj;
- **R** — przywróć domyślne przypisanie;
- **ZRESETUJ WSZYSTKO** — przywróć wszystkie domyślne przypisania po potwierdzeniu.

Jeśli to samo połączenie klawiszy jest przypisane do kilku działań, MCM pokazuje konflikt.

## Okno menu kreatywnego

Okno można:

- przesuwać;
- zmieniać jego szerokość i wysokość;
- zmieniać rozmiar, przeciągając krawędzie i narożniki;
- minimalizować;
- zamykać;
- przywracać do domyślnego położenia.

Rozmiar, położenie i ostatnio otwarta sekcja są zapisywane między uruchomieniami gry.

Duże katalogi korzystają z przewijania i automatycznie dopasowują się do bieżącego rozmiaru okna.

## Wyszukiwanie

Wyszukiwanie jest dostępne w katalogach:

- zaklęć;
- przedmiotów;
- materiałów;
- perków;
- stworzeń.

Może uwzględniać nie tylko wyświetlaną nazwę, lecz także nazwę angielską, klucz lokalizacji, identyfikator techniczny lub ścieżkę XML.

Wyszukiwanie nie rozróżnia wielkości liter i toleruje niewielkie literówki w odpowiednio długich słowach.

Interfejs MCM jest dostępny w 11 językach. W przypadku zwykłej zawartości gry w miarę możliwości używane są tłumaczenia samej Noity.

# Zaklęcia

Sekcja zaklęć pozwala pracować nie tylko z katalogiem, ale też z rzeczywistymi zaklęciami aktualnego gracza.

Jednocześnie dostępne są:

- miejsca aktywnej różdżki;
- **Zawsze rzucane**;
- ekwipunek zaklęć;
- katalog zaklęć.

## Szybka zamiana

Można wybrać konkretne miejsce różdżki i kliknąć LPM wybrane zaklęcie w katalogu. Zostanie ono umieszczone w wybranym miejscu.

## Przeciąganie

Istniejące zaklęcia można przenosić:

- między miejscami różdżki;
- do **Zawsze rzucane**;
- z **Zawsze rzucane** z powrotem do zwykłych miejsc;
- do konkretnych miejsc w ekwipunku zaklęć;
- z ekwipunku z powrotem na różdżkę;
- do świata gry;
- do kosza.

W przypadku istniejących kart MCM stara się przenosić samą encję gry, zamiast tworzyć nową kopię. Pozwala to zachować zmieniony stan karty, w tym stan dodany przez inne mody.

Oryginalne zaklęcie pozostaje na miejscu, dopóki nowe miejsce docelowe nie zostanie potwierdzone. Nieudana lub niedozwolona operacja nie powinna zniszczyć pierwotnej karty.

## Zawsze rzucane

Stałe zaklęcia mają własny obszar.

Przy przenoszeniu między zwykłymi miejscami a **Zawsze rzucane** uwzględniana jest pojemność różdżki, aby struktura zwykłych miejsc pozostała poprawna.

## Cofnij / Ponów

Dla wewnętrznych zmian różdżki dostępna jest ograniczona historia **COFNIJ / PONÓW**.

Dotyczy operacji, które można bezpiecznie odtworzyć na podstawie stanu samej różdżki.

Przeniesienie rzeczywistego zaklęcia do świata gry lub zwykłego ekwipunku nie zawsze można poprawnie cofnąć przez samo odtworzenie stanu, dlatego takie działania nie zawsze można cofnąć.

# Różdżki

MCM zawiera pełny edytor aktywnej różdżki.

Można zmieniać:

- liczbę miejsc;
- liczbę zaklęć na użycie;
- czas przeładowania;
- opóźnienie między użyciami;
- rozrzut;
- mnożnik prędkości pocisków;
- maksymalną manę;
- regenerację many;
- powrót odrzutu;
- poziom różdżki;
- losowanie;
- tryb **BEZ PRZEŁADOWANIA**.

Można również zmieniać wygląd i powiązane parametry:

- wyświetlaną nazwę;
- blokady;
- obraz różdżki;
- przesunięcie obrazu;
- punkt wystrzału.

Dostępny jest wizualny katalog wyglądu różdżek.

## Zapisane różdżki

Różdżkę można zapisać, a później ponownie użyć jej zapisanego stanu.

Zapisywane są:

- charakterystyki;
- mana;
- wygląd;
- zwykłe zaklęcia;
- **Zawsze rzucane**;
- rozmieszczenie kart;
- pozostałe użycia;
- stan zamrożenia kart.

Zapisane różdżki są dostępne między światami gry i po kolejnych uruchomieniach Noity.

### Zastosuj

**ZASTOSUJ** nakłada zapisany stan na różdżkę, którą gracz aktualnie trzyma.

### Kopia

**KOPIA** tworzy osobną kopię zapisanej różdżki.

Jeśli w szybkim ekwipunku jest odpowiednie wolne miejsce, nowa różdżka zostanie tam umieszczona. W przeciwnym razie pojawi się obok gracza w świecie gry.

Jeśli tworzenia nie da się poprawnie zakończyć, MCM stara się usunąć niedokończoną encję.

# Przedmioty i ciecze

## Przedmioty

**LPM** na wpisie katalogu tworzy jeden przedmiot obok gracza.

**PPM** próbuje przekazać przedmiot bezpośrednio do ekwipunku.

Przedmiot można także przeciągnąć:

- do odpowiedniego obszaru szybkiego ekwipunku;
- poza menu, do wybranego miejsca w świecie gry.

Jeśli kartę upuści się wewnątrz menu bez prawidłowego celu, operacja zostanie anulowana.

Katalog zawiera szablony, więc po utworzeniu przedmiotu jego wpis nie znika.

MCM uwzględnia zwykły podział szybkiego ekwipunku Noity na miejsca dla różdżek i przedmiotów i nie powinien bez powodu zastępować już znajdującego się tam przedmiotu.

## Ciecze

MCM potrafi tworzyć prawdziwe pojemniki gry z wybraną cieczą.

Utworzony pojemnik zachowuje się jak zwykły przedmiot Noity:

- można go przechowywać w ekwipunku;
- wyrzucić do świata;
- może się rozbić;
- rozlewa swoją zawartość;
- bierze udział w zwykłych reakcjach materiałów.

# Materiały

Katalog materiałów jest tworzony z substancji zarejestrowanych w bieżącej instancji Noity.

Obejmuje różne rodzaje materiałów, między innymi:

- ciecze;
- proszki;
- gazy;
- ogień;
- ciała stałe;
- materiały statyczne;
- materiały ze specjalnym sposobem wyświetlania.

Jeśli inny aktywny mod poprawnie doda własny materiał do Noity, może on również pojawić się w MCM.

## Rysowanie materiałami

1. Wybierz materiał.
2. Wybierz rozmiar pędzla.
3. Kliknij **ZACZNIJ MALOWAĆ**.
4. Zamknij ekwipunek.
5. Przytrzymaj przypisany przycisk rysowania w świecie gry.

Domyślnie używany jest **środkowy przycisk myszy**.

Otwarcie ekwipunku kończy tryb rysowania.

## Zachowanie materiałów

MCM tworzy prawdziwe materiały świata gry, a nie dekoracyjne cząsteczki.

Po umieszczeniu nadal podlegają zwykłej symulacji Noity:

- ciecze płyną;
- proszki osypują się;
- gazy się rozprzestrzeniają;
- ogień oddziałuje z otoczeniem;
- substancje wchodzą w reakcje;
- niestabilne materiały mogą zmieniać się w inne.

Dla różnych typów materiałów MCM używa odpowiednich metod umieszczania, w tym dodatkowych możliwości NoitaPatchera w przypadkach, których nie da się poprawnie obsłużyć zwykłymi środkami moda.

# Perki

## Tworzenie perka

**LPM** tworzy wybrany perk w świecie gry.

Można go podnieść tak samo jak zwykły perk Noity.

## Otrzymywanie perków

MCM pozwala otrzymać:

- 1 kopię;
- 10 kopii;
- 100 kopii.

Masowe otrzymywanie jest wykonywane stopniowo, aby nie przetwarzać dużej liczby ciężkich operacji w jednej klatce.

Interfejs pokazuje postęp zadania, a dalsze wykonywanie można anulować. Kopie pomyślnie otrzymane przed anulowaniem pozostają u gracza.

## Usuwanie perków

Bezpieczne usunięcie perka jest znacznie trudniejsze niż jego otrzymanie.

Niektóre perki zmieniają jednocześnie kilka systemów gry, tworzą encje lub uruchamiają efekty, dla których nie istnieje jeden uniwersalny sposób cofnięcia.

Dlatego MCM usuwa tylko te obsługiwane zmiany, dla których może wystarczająco niezawodnie wykonać operację odwrotną.

Mod stara się cofnąć dokładnie stan utworzony przez dane zastosowanie perka, bez niepotrzebnego resetowania innych efektów i parametrów gracza.

# Efekty

MCM pozwala stosować i usuwać obsługiwane:

- efekty gry;
- stany związane z materiałami.

Podczas usuwania mod stara się nie naruszać obcych stanów należących do perków lub innych systemów gry.

Pozwala to usuwać własne efekty MCM bez bezwarunkowego kasowania każdego podobnego stanu gracza.

# Stworzenia i przemiany

## Tworzenie stworzeń

**LPM** tworzy wybrane stworzenie obok gracza.

Kartę stworzenia można także przeciągnąć poza menu, aby utworzyć je w wybranym miejscu świata gry.

**PPM** na obsługiwanym wpisie próbuje przemienić bieżącego gracza w odpowiednią formę.

## Zgodność form

Stworzenia Noity bardzo różnią się budową wewnętrzną.

Dlatego MCM rozróżnia cele przemiany według dokładnych ścieżek XML i nie uznaje automatycznie wszystkich podobnych stworzeń za zamienne.

Podczas przemiany MCM wykorzystuje możliwości wybranej formy i w razie potrzeby stosuje osobne zasady zgodności dla konkretnych stworzeń.

# Powrót po przemianie i śmierci formy

Do ludzkiej postaci można wrócić przypisanym działaniem — domyślnie **TAB**.

MCM najpierw korzysta ze zwykłych mechanizmów kończenia przemiany w Noicie. W trudniejszych przypadkach dostępne jest dodatkowe odzyskiwanie z użyciem NoitaPatchera.

Mod obsługuje również wspierane sytuacje, w których tymczasowa forma otrzyma śmiertelne obrażenia.

W takich przypadkach MCM próbuje:

- zachować zwłoki martwej formy;
- przywrócić ludzkiego gracza;
- przywrócić sterowanie;
- zachować ekwipunek;
- odtworzyć stan związany z graczem.

Nie jest to absolutna nieśmiertelność. Nietypowe sposoby śmierci pochodzące z innych modów, niezgodne mody lub wewnętrzny błąd Noity mogą ominąć zwykły mechanizm odzyskiwania.

# Przejęcie kontroli nad stworzeniem

Oprócz wybierania formy z katalogu MCM potrafi przejąć kontrolę nad **stworzeniem, które już istnieje w świecie gry**.

Domyślnie używany jest klawisz **G**.

Najedź kursorem na odpowiedni cel i użyj przypisanego działania.

MCM sprawdza stworzenie, wykonuje przemianę w zgodną formę i dopiero po potwierdzonym sukcesie usuwa pierwotną encję ze świata.

Jeśli przemiana się nie powiedzie, pierwotne stworzenie nie powinno po prostu zniknąć.

Ta możliwość nie ogranicza się do statycznego katalogu MCM. Odpowiednie stworzenie dodane przez inny mod również może przejść sprawdzenie, chociaż nie można zagwarantować uniwersalnej zgodności z każdą zewnętrzną encją.

# Gracz

**GRACZ** to specjalny wpis w katalogu stworzeń.

Nie jest to zwykła forma do przemiany.

**LPM** tworzy oddzielną postać, dla której MCM próbuje skopiować:

- wygląd gracza;
- maksymalne zdrowie.

**PPM** na wpisie **GRACZ** nie przemienia zwykłego gracza w tę encję.

Jeśli gracz jest już w ludzkiej postaci, działanie nic nie robi. Jeśli gracz jest obecnie przemieniony w inne stworzenie, używany jest powrót do ludzkiej postaci.

# Pogoda i pora dnia

MCM pozwala zmieniać:

- porę dnia;
- ustawienia pogody;
- poszczególne obsługiwane parametry pogody.

Można zarówno ustawić potrzebny stan, jak i później zwolnić dany parametr spod kontroli MCM.

Na przykład po wymuszeniu określonej pory można ponownie przywrócić naturalny upływ czasu Noity.

# Zasady świata

Sekcja **ZASADY** służy do głębszych zmian zachowania świata gry.

W zależności od konkretnej zasady można sterować takimi parametrami jak:

- relacje między stworzeniami;
- złoto;
- używanie zaklęć;
- mgła wojny;
- nagrody za określone zabójstwa;
- lecznicze łupy;
- krew;
- grawitacja;
- zachowanie fizyczne;
- siła kopnięcia;
- połączenia fizyczne;
- cykl dnia i nocy;
- inne obsługiwane globalne parametry.

Najważniejszą cechą jest to, że zasady MCM są pomyślane jako **odwracalne zmiany**.

Dla obsługiwanych ustawień mod zapisuje stan początkowy i pozwala przywrócić parametry do ich normalnych wartości.

Jeśli używany jest mnożnik, nowa wartość jest obliczana względem stanu bazowego, zamiast w nieskończoność mnożyć już zmieniony wynik.

Operacje wymagające zmiany dużej liczby encji lub obiektów fizycznych są wykonywane stopniowo, aby nie próbować przetwarzać całego świata dokładnie w chwili kliknięcia przycisku.

# Teleportacja

MCM pozwala szybko przenosić się do przygotowanych miejsc w świecie gry, w tym do punktów:

- głównej trasy;
- Świętych Gór;
- dużych obszarów bocznych;
- innych obsługiwanych lokacji.

Przed teleportacją mod może wczytać obszar docelowy i próbuje znaleźć w pobliżu wolne miejsce, aby nie umieścić gracza bezpośrednio w litej ścianie lub innej przeszkodzie.

# Entangled Worlds

**Entangled Worlds / Noita Proxy jest opcjonalny.**

MCM działa w pełni w grze jednoosobowej bez niego.

Po zainstalowaniu Entangled Worlds włączane są dodatkowe eksperymentalne funkcje wieloosobowe.

Dla najlepszej zgodności zaleca się używanie tej samej wersji MCM przez wszystkich uczestników.

## Przedmioty, różdżki i zaklęcia

Tam, gdzie to możliwe, przedmioty w świecie i wyrzucone zaklęcia korzystają ze standardowych mechanizmów Entangled Worlds.

Zmiany ekwipunku również mogą być przekazywane przez Entangled Worlds.

## Perki

Perk utworzony przez MCM pozostaje prawdziwą encją gry i w miarę możliwości jest synchronizowany przez zwykły system przedmiotów świata Entangled Worlds.

## Materiały

Rysowanie materiałami ma eksperymentalną obsługę wieloosobową.

MCM synchronizuje zmienione obszary świata tak, aby rezultat mógł pojawić się u innych uczestników.

Aby działało to poprawnie, odpowiedni materiał musi istnieć również u drugiego gracza. Jeśli zestawy modów są różne, nie można zagwarantować identycznego wyświetlania wszystkich materiałów.

## Pogoda i zasady świata

Obsługiwane zmiany pogody i globalnych zasad mogą być synchronizowane przez Entangled Worlds.

## Przemiany i przejmowanie kontroli nad stworzeniami

Przemiany mają dodatkową obsługę podczas korzystania z Entangled Worlds.

Podczas przejmowania kontroli nad już istniejącym stworzeniem mod uwzględnia również jego stan sieciowy. Jeśli MCM nie może wystarczająco pewnie stwierdzić, że pierwotną encję można usunąć, woli ją pozostawić.

## Gracz

Tworzenie specjalnej encji **GRACZ** jest obsługiwane także w grze przez Entangled Worlds. W takim przypadku kopiuje ona kolory wyglądu osoby, która ją utworzyła.

## Teleportacja między graczami

Przy aktywnym Entangled Worlds w sekcji teleportacji wyświetlani są dostępni gracze.

**VAI** przenosi cię do wybranego gracza.

**PRZYWOŁAJ TUTAJ** wysyła wybranemu graczowi żądanie teleportacji do ciebie.

W obu przypadkach MCM próbuje użyć wolnego miejsca w pobliżu punktu docelowego.

## Ograniczenia

Obsługa Entangled Worlds pozostaje eksperymentalna.

**W grze wieloosobowej przemiana w dużych lub wieloczłonowych bossów może spowodować krytyczny spadek wydajności i praktycznie zepsuć bieżącą sesję gry.**

Pełna synchronizacja Noity jest niezwykle trudna, zwłaszcza gdy jednocześnie zmieniają się:

- pikselowy świat;
- materiały;
- obiekty fizyczne;
- złożone stworzenia i bossowie;
- zawartość innych modów.

Dlatego MCM nie gwarantuje idealnej synchronizacji każdego możliwego stanu.

# NoitaPatcher i niebezpieczne mody

Pełna wersja MCM zawiera **NoitaPatcher**.

Jest używany do możliwości, których nie da się uzyskać wyłącznie zwykłymi środkami modowania Noity, między innymi w części mechanizmów:

- odzyskiwania po złożonych przemianach;
- pracy z encjami gry;
- pracy ze światem gry;
- umieszczania niektórych materiałów;
- rozszerzonej zgodności.

Dlatego pełna wersja wymaga zezwolenia na **niebezpieczne mody**.

NoitaPatcher jest już zawarty w gotowej kompilacji MCM. Nie trzeba instalować go osobno.

# Jeśli coś nie działa

## MCM się nie ładuje

Upewnij się, że po rozpakowaniu istnieje:

```text
Noita/mods/metamorph_creative_menu/mod.xml
```

Sprawdź, czy:

- MCM jest włączony w menu **Mody**;
- przed jego nazwą widnieje **[x]**;
- **Niebezpieczne mody: Dozwolone**;
- gra została uruchomiona z aktywnymi modami.

## Nie działają funkcje korzystające z NoitaPatchera

Sprawdź, czy istnieje:

```text
metamorph_creative_menu/NoitaPatcher/noitapatcher.dll
```

i upewnij się, że **niebezpieczne mody** są dozwolone.

## Nie można wrócić z formy

Spróbuj przypisanego działania powrotu — domyślnie **TAB**.

Jeśli problem się powtarza, w zgłoszeniu warto podać:

- dokładną nazwę stworzenia;
- ścieżkę XML, jeśli jest znana;
- w jaki sposób uzyskano formę;
- czy działa zwykły powrót;
- czy problem występuje tylko po śmiertelnych obrażeniach;
- czy używany jest Entangled Worlds.

## Problemy z Entangled Worlds

Sprawdź:

- czy uczestnicy używają tej samej wersji MCM;
- czy wersje Entangled Worlds są zgodne;
- czy zestawy modów są takie same, jeśli problem dotyczy materiałów lub stworzeń z innych modów.

# Zgłaszanie błędu

[Utwórz zgłoszenie](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)

W przydatnym zgłoszeniu warto podać:

- wersję MCM;
- co dokładnie robiłeś;
- oczekiwany rezultat;
- rzeczywisty rezultat;
- nazwę stworzenia, przedmiotu, perka lub materiału;
- czy używany jest Entangled Worlds;
- inne mody, które mogą mieć związek z problemem;
- tekst błędu lub odpowiedni fragment dziennika;
- zrzut ekranu lub film, jeśli pomaga pokazać problem.

# Komponenty zewnętrzne

- **Noita** — Nolla Games.
- **NoitaPatcher** — dextercd, dołączony do pełnej wersji.
- **lbase64** — Ilya Kolbin, dołączony do MCM.
- **Entangled Worlds / Noita Proxy** — IntQuant i współtwórcy projektu; instalowany osobno i opcjonalny.

Szczegółowe informacje o projektach źródłowych i licencjach znajdują się w [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

---

**Metamorph: Creative Menu** to nieoficjalny mod użytkownika do Noity. Projekt nie jest powiązany z Nolla Games i nie jest oficjalnie wspieraną częścią gry.

[↑ Wróć do wyboru języka](#languages)
