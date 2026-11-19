# Szczurołap (Ratcatcher)

Gra na PICO-8 o szczurołapie i jego psie, schodzących w coraz głębsze podziemia
wielkiego miasta low fantasy. Widok z góry, proceduralnie generowane poziomy,
światło jako kluczowa mechanika.

Kartridż: **`szczurolap.p8`** (gotowy do wgrania).

## Poziomy

1. **Piwnice** – nauka: gniazda, kaganki, olej.
2. **Kanały** – kanały wodne spowalniają, pojawiają się zarażone (zielone) szczury.
3. **Jaskinie przemytników** – nieregularne groty, duże szczury, mniej zapalonych kaganków.
4. **Tunele szczuroludzi** – wąskie tunele, szczuroludzie rzucający strzałkami.
5. **Czeluści** – Szczurzy Król przyzywający kolejne szczury. Pokonaj go, by wygrać.

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

## Sterowanie

| Przycisk | Akcja |
|---|---|
| lewy analog / krzyżak | ruch szczurołapa |
| **O** | cios pałką |
| **X** | przełącz: sterowanie psem / szczurołapem |
| **O** w trybie psa | szczeknięcie (odsłania ukryte szczury, ogłusza pobliskie) |
| prawy analog (= gracz 2) | ruch psa w trybie psa |
| O / X gracza 2 | szczeknięcie |

Gra sama wykrywa, czy drugi analog działa. Jeśli wejście gracza 2 nigdy się nie pojawi,
w trybie psa **lewy analog steruje psem**, a szczurołap stoi w miejscu. Pies nie może
odejść dalej niż ok. 7 kratek od pana.

PICO-8 obsługuje tylko 6 przycisków na gracza i nie czyta analogów wprost. Analogi
działają jak krzyżak. Żeby prawy analog sterował psem, zmapuj go na kierunki
**gracza 2** (klawiatura: `S F E D`). Na muOS/Knulli/ROCKNIX robi się to w ustawieniach
sterowania emulatora/portu PICO-8 (gptokeyb lub mapowanie RetroArch dla portu 2).
Bez tego gra działa w trybie jednego analogu opisanym wyżej.

## Wgranie na Anbernic RG35XX H

- **Oficjalne PICO-8** (np. muOS / Knulli z `pico8_64` w folderze BIOS): skopiuj
  `szczurolap.p8` do `ROMS/PICO8` (lub `roms/pico8`) na karcie SD.
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
