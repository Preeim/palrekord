---
trigger: always_on
---

# Adatstruktúra és Látványtervek Szinkronban Tartása

Minden olyan változtatásnál, amely érinti az alkalmazás **adatstruktúráját** vagy **felhasználói felületét / látványterveit**, kötelező a kapcsolódó dokumentációt és vizuális terveket is azonnal frissíteni ugyanabban a feladatban.

## 1. Adatstruktúra-változások (`docs/Adatstruktúra/`)

Ha egy módosítás érinti az adatbázis-sémát (`db/migrate/`, `db/schema.rb`), a modellek mezőit/kapcsolatait, az indexeket vagy a rendszerbeállítási (`settings`) kulcsokat, akkor **kötelező frissíteni**:

1. **`docs/Adatstruktúra/adatstruktura.md`:**
   - Az entitás-kapcsolati Mermaid diagram (`erDiagram`).
   - Az érintett táblák oszlop-, típus-, alapérték-, index- és kapcsolati táblázatai, illetve új tábla esetén az új alfejezet.
   - A `settings` tábla alapértelmezett kulcsainak listája, ha új beállítási kulcs kerül be vagy módosul.
2. **`docs/Adatstruktúra/er_diagram.svg`:**
   - Az új vagy módosított táblák, oszlopok, indexek és idegenkulcs-/intervallum-kapcsolatok vizuális feltüntetése.

## 2. Látványterv- és UI-változások (`docs/Látványtervek/` és funkciós SVG-k)

Ha egy módosítás érinti az oldalak elrendezését, navigációját, nézeteit (`app/views/`), stílusát (`app/assets/stylesheets/`) vagy új vizuális elemet vezet be/módosít a képernyőkön, akkor **kötelező frissíteni**:

1. **`docs/Látványtervek/latvanyterv.md`:**
   - Az elrendezési irányelvek, az érintett képernyők leírása és képhivatkozásai (illetve új nézet esetén új fejezet hozzáadása).
2. **Érintett SVG látványtervek:**
   - A megfelelő alap látványtervek (`docs/Látványtervek/kezdolap.svg`, `docs/Látványtervek/login.svg`, `docs/Látványtervek/register.svg`) és/vagy az adott funkcióhoz tartozó vizuális tervek (pl. `docs/Új Funkciók/.../*.svg`) frissítése a tényleges képernyőnek megfelelően.

## 3. Kötelező jelölés és ellenőrzés

- **Változások megjelölése:** Minden új vagy módosított elemet egyértelműen jelölni kell a dokumentációban (pl. `🆕 [ÚJ – Funkció neve]` a Markdown fájlokban, és `[ÚJ]` / vizuális kiemelés az SVG rajzokban).
- **Csak valós állapot dokumentálása:** Csak olyan táblákat, oszlopokat, indexeket és UI-elemeket szabad rögzíteni, amelyek ténylegesen szerepelnek a sémában vagy a nézetekben (ha valami tervezett, azt külön jelölni kell).
- **SVG ellenőrzés:** Minden módosított `.svg` fájl mentése után ellenőrizni kell az érvényes XML-szerkezetet.
