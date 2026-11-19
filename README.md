# Szczurołap (Ratcatcher)

Gra na PICO-8 o szczurołapie **Ulrichu** i jego psie **Bodo**, schodzących w coraz
głębsze podziemia miasta **Kesselburg** (low fantasy). Widok z góry, proceduralnie generowane poziomy,
światło jako kluczowa mechanika.

Kartridż: **`szczurolap.p8`** (gotowy do wgrania).

## Poziomy

1. **Piwnice Kesselburga** – nauka: gniazda, kaganki, olej.
2. **Kanały Fleetgraben** – woda spowalnia, pojawiają się zarażone (zielone) szczury.
3. **Groty przemytników z Wapping** – nieregularne groty, duże szczury, mniej zapalonych kaganków.
4. **Tunele szczuroludzi Unterhaus** – wąskie tunele, szczuroludzie rzucający strzałkami.
5. **Czeluści Höllenschlundu** – Grimbald, Król Szczurów, przyzywa kolejne szczury. Pokonaj go, by wygrać.

Nazwy własne są wzorowane na historycznych nazwach angielskich i niemieckich
(Fleet Ditch, Wapping, Höllenschlund, imiona Ulrich, Bodo, Grimbald).

## Mechaniki

- **Światło**: latarnia szczurołapa zużywa olej – im mniej oleju, tym mniejszy krąg
  światła. Szczurów w ciemności nie widać (czasem błysną tylko czerwone oczy).
  Butelki z olejem leżą w podziemiach.
- **Kaganki** na ścianach: podejdź, by zapalić (kosztuje 5 oleju). Oświetlają pokój na
  stałe, a szczury w ich świetle poruszają się wolniej.
- **Gniazda** wysyłają **fale szczurów**, gdy się zbliżysz. Zniszcz wszystkie, by
  otworzyć właz w dół (pojawi się żółty wskaźnik kierunku).
- **Szczury w zakamarkach** czają się w ciasnych wnękach i atakują z zaskoczenia.
  Wykrywa je pies (węch), szczeknięcie albo jasne światło latarni.
- **Pies** walczy sam, gryzie szczury i wywęszy ukryte. Gdy zostanie ranny, stań przy
  nim przez chwilę, żeby go podnieść. Mięso leczy szczurołapa i psa.
- **Wycie Bodo** (trzymany spust/bumper): pies staje i wyje, a szczury w promieniu ok. 5 kratek
  uciekają od niego (poza królem). Zużywa wytrzymałość psa (niebieski pasek pod ikoną
  psa). Po wyczerpaniu pies musi chwilę odpocząć.

## Sterowanie

| Przycisk | Akcja |
|---|---|
| lewy analog / krzyżak | ruch szczurołapa |
| **O** | cios pałką |
| **X** | przełącz: sterowanie psem / szczurołapem |
| **O** w trybie psa | szczeknięcie (odsłania ukryte szczury, ogłusza pobliskie) |
| prawy analog (zmapowany na kierunki gracza 2) | ruch psa w trybie psa |
| spust/bumper (zmapowany na O lub X gracza 2), trzymany | wycie Bodo |

Gdy sterujesz szczurołapem, Bodo działa sam: trzyma się blisko, atakuje szczury w pobliżu,
węszy ukryte i dogania pana, gdy zostanie w tyle. To gra jednoosobowa, a „gracz 2” to
tylko sposób, w jaki PICO-8 odczytuje dodatkowe przyciski.

Gra sama wykrywa, czy drugi analog działa. Jeśli wejście gracza 2 nigdy się nie pojawi,
w trybie psa **lewy analog steruje psem**, a szczurołap stoi w miejscu. Pies nie może
odejść dalej niż ok. 7 kratek od pana.

PICO-8 obsługuje tylko 6 przycisków na gracza i nie czyta analogów wprost. Analogi
działają jak krzyżak. Żeby prawy analog sterował psem, zmapuj go na kierunki
**gracza 2** (klawiatura: `S F E D`). Na muOS/Knulli/ROCKNIX robi się to w ustawieniach
sterowania emulatora/portu PICO-8 (gptokeyb lub mapowanie RetroArch dla portu 2).
Bez tego gra działa w trybie jednego analogu opisanym wyżej.

## Menu, język i trudność

W menu tytułowym strzałkami góra/dół wybierasz **start**, **język** (polski bez
ogonków / angielski) i **trudność** (łatwa domyślnie / normalna). Wybór zapisuje się
w pamięci kartridża.

Poziom łatwy daje wolniejsze szczury (×0.8), mniejsze fale, dłuższą nietykalność po
ciosie, wolniejsze zużycie oleju i rzadsze strzałki szczuroludzi.

## Spust / bumper i prawy analog

PICO-8 widzi tylko 6 przycisków na gracza (4 kierunki, O, X). Spusty, bumpery i prawy
analog działają tylko wtedy, gdy system lub port PICO-8 przypisze je do przycisków
**gracza 2** (np. przez gptokeyb jako klawisze `S F E D` dla kierunków oraz `Tab`/`Q`
dla O/X). Lewy analog zwykle działa jak krzyżak gracza 1.

W menu jest **test przycisków**. Pokazuje, które przyciski gracza 1 i 2 PICO-8 widzi,
pozycję myszy oraz wciśnięte klawisze (kody). Wyjście: O+X. Dzięki temu sprawdzisz na
konsoli, czy bumpery, spusty i prawy analog w ogóle docierają do gry.

## Wgranie na Anbernic RG35XX H

- **Oficjalne PICO-8** (stock OS, muOS, Knulli): skopiuj `szczurolap.p8` do folderu
  z grami PICO-8 na karcie SD (np. `Roms/PICO8`). Na stock OS drugi analog
  prawdopodobnie nie da się przypisać do gracza 2, więc gra użyje trybu jednego analogu.
- **Fake-08 / RetroArch** (stock OS, bez licencji PICO-8): ten sam plik do folderu
  `PICO8`/`PICO-8`. Fake-08 może nie obsłużyć dużego napisu w menu tytułowym.
  Sama gra używa standardowego API 0.2.x.

Wynik (rekord ubitych szczurów) zapisuje się przez `cartdata`.

## Budowanie i testy

Kod gry jest w `src/szczurolap.lua`, a grafika, flagi kafli, dźwięki i muzyka w
`tools/build.py`.

```sh
python3 tools/build.py          # składa szczurolap.p8
pip install lupa
python3 tools/check.py 10       # licznik tokenów + symulacja 10 gier z losowym wejściem
python3 tools/render.py shots   # podgląd klatek jako PNG (bez fontu PICO-8)
```

Kod jest pisany w zwykłej składni Lua (bez `+=`, `!=`), więc da się go uruchomić
w standardowym interpreterze z zaślepkami API.
