---
trigger: always_on
---

# AI Használat Dokumentálása (`docs/AI-Usage.md`)

Minden végrehajtott lépést és műveletet dokumentálj a `docs/AI-Usage.md` fájlban.

## Kötelező tartalom minden bejegyzésnél

Minden felhasználói kérés (művelet) végén adj hozzá egy új bejegyzést a `docs/AI-Usage.md` fájlhoz (ha még nem létezik, hozd létre), amely tartalmazza:

1. **Prompt**: Mi volt a felhasználó pontos kérése / promptja.
2. **Értelmezés**: A kérés rövid, tömör értelmezése.
3. **Elvégzett műveletek**: Mit csináltál a kérés teljesítése érdekében.
4. **Módosított fájlok**: Melyik fájlok változtak (létrehozott, módosított vagy törölt fájlok listája).

## Formátum

Használj áttekinthető Markdown formátumot (pl. időrendi sorrendben új szekcióként hozzáfűzve a fájl végére):

```markdown
## [Dátum / Időpont] – Rövid cím

- **Prompt:** ...
- **Értelmezés:** ...
- **Elvégzett műveletek:** ...
- **Módosított fájlok:**
  - `eleresi/ut/fajl1` (létrehozva / módosítva / törölve)
```
