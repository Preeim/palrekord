# PálRecord – Fiókkezelési Rendszer Specifikáció

Ez a dokumentum a **PálRecord** alkalmazás fiókkezelési (autentikációs és jogosultsági) rendszerének funkcionális és technikai specifikációját rögzíti **Rails 7.1 + MySQL** környezetre.

Kapcsolódó dokumentumok:
- [Adatstruktúra specifikáció](../Adatstruktúra/adatstruktura.md)
- [Látványtervek (Kezdőlap, Login, Register)](../Látványtervek/latvanyterv.md)

---

## 1. Technológiai alapok (Rails 7.1)

A fiókkezelés külső autentikációs keretrendszer (pl. Devise) nélkül, a **Rails 7.1 beépített eszközeivel** készül:

- **`bcrypt` + `has_secure_password`**: Biztonságos jelszó-hashelés a `users.password_digest` oszlopba.
- **`User.authenticate_by`**: Timing-attack ellen védett beléptetés `username` vagy `email` és `password` alapján.
- **`generates_token_for`**: Adatbázis-mező nélküli, kriptográfiailag aláírt, lejárati idővel rendelkező tokenek:
  - `:email_confirmation` (pl. 24 órás élettartam)
  - `:password_reset` (pl. 15 perces élettartam, amely a jelszó megváltozása után automatikusan érvénytelenedik)
- **Munkamenet (`Session` + `Current.user`)**: Cookie-alapú munkamenet (`session[:user_id]`), minden kérés elején ellenőrizve, hogy a felhasználó létezik-e és `is_active == true`.

---

## 2. Szerepkörök és jogosultsági mátrix

| Művelet | Vendég (nem belépett) | Tag (`TAG`) | Admin (`ADMIN`) |
| :--- | :---: | :---: | :---: |
| Kategóriák és ranglisták megtekintése | Konfigurálható (`public_leaderboards`) | Igen | Igen |
| Verifikációs anyagok megtekintése | Konfigurálható (`public_leaderboards`) | Igen | Igen |
| Saját profil szerkesztése / jelszócsere | Nem | Igen | Igen |
| Új rekord beküldése | Nem | Igen | Igen |
| Saját függőben lévő rekord szerkesztése / törlése | Nem | Igen (`PENDING` státuszig) | Igen |
| Új kategória létrehozása | Nem | Konfigurálható (`members_can_create_categories`) | Igen |
| Rekordok jóváhagyása / elutasítása / módosítása | Nem | Nem | Igen |
| Felhasználói fiókok, meghívókódok és beállítások kezelése | Nem | Nem | Igen |

---

## 3. Adatbázis-alapú rendszerbeállítások (`settings` tábla)

A fiókkezelés viselkedését az Admin felületről is kapcsolható, `settings` táblában tárolt beállítások szabályozzák:

| Kulcs (`key`) | Alapérték | Hatása a fiókkezelésre |
| :--- | :---: | :--- |
| `email_system` | `'false'` | `false`: nincs SMTP küldés, azonnali aktiválás, admin ad ideiglenes jelszót.<br>`true`: kötelező e-mail, megerősítő link regisztrációkor, önkiszolgáló jelszó-reset. |
| `require_invite_code` | `'true'` | `true`: regisztrációhoz érvényes meghívókód (`invite_codes`) kötelező.<br>`false`: bárki regisztrálhat meghívókód nélkül. |
| `public_leaderboards` | `'true'` | `true`: vendégek is láthatják a kezdőlapot és a ranglistákat.<br>`false`: minden oldal belépéshez kötött (átirányít a `/login` oldalra). |

---

## 4. Folyamatok részletes működése

### 4.1. Regisztráció (`/register`)

1. **Űrlap mezők:**
   - `username` (kötelező, 3–50 karakter, egyedi, automatikusan kisbetűsítve és trimmelve)
   - `display_name` (kötelező, 2–100 karakter)
   - `email` (kötelező ha `email_system = true`, egyébként opcionális; ha megadják, egyedi és érvényes formátumú; üresen `NULL`-ként mentődik)
   - `password` (kötelező, min. 8 karakter) + `password_confirmation`
   - `invite_code` (kötelező és megjelenik, ha `require_invite_code = true`)

2. **Validáció és mentés:**
   - Ha `require_invite_code = true`: az `InviteCode` rekordnak léteznie kell, `is_active == true`, `expires_at` nincs túllépve, és (`max_uses` `nil` vagy `uses_count < max_uses`). Sikeres regisztrációnál tranzakcióban nő a `uses_count` és rögzítődik a `users.invite_code_id`.
   - Az első regisztráló (ha még nincs más felhasználó, vagy `db/seeds.rb`-ből nincs admin) lehet `ADMIN`, minden további regisztráló `TAG` szerepkört kap.

3. **Aktiválás (`email_system` alapján):**
   - **`email_system = false`:** `confirmed_at = Time.current`, a felhasználó azonnal belép és a kezdőlapra jut.
   - **`email_system = true`:** `confirmed_at = nil`, a rendszer kiküldi a `:email_confirmation` tokent tartalmazó aktiváló e-mailt, és tájékoztatja a felhasználót.

---

### 4.2. Bejelentkezés (`/login`) és Kijelentkezés (`/logout`)

1. **Belépés (`SessionsController#create`):**
   - A felhasználó egyetlen mezőben adhatja meg a `username`-jét **vagy** az `email`-jét (`login` paraméter), valamint a `password`-öt.
   - A keresés normalizált (kisbetűs, trimmelt) érték alapján történik (`username` vagy nem-üres `email`).
   - **Ellenőrzések sikeres jelszóegyezés után:**
     - Ha `user.is_active == false`: belépés megtagadva (*„A fiókod fel van függesztve.”*).
     - Ha `email_system == true` és `user.confirmed_at.nil?`: belépés megtagadva (*„Kérjük, erősítsd meg az e-mail címed a belépés előtt.”*).
   - **Sikeres belépés:**
     - `session[:user_id] = user.id` (és `reset_session` a session fixation ellen).
     - `user.update_column(:last_login_at, Time.current)`.
     - Ha `user.must_change_password == true`: átirányítás a profil jelszócsere részére kötelező figyelmeztetéssel.

2. **Kijelentkezés (`SessionsController#destroy`):**
   - `reset_session`, átirányítás a főoldalra (`/`) vagy `/login`-ra.

---

### 4.3. Elfelejtett jelszó és Jelszó-visszaállítás

- **`email_system = false` esetén:**
  - A `/password_reset/new` oldal jelzi, hogy az e-mailes visszaállítás ki van kapcsolva, és az **Admintól** kell ideiglenes jelszót kérni.
  - Az Admin az Admin felületen beállít egy ideiglenes jelszót (amivel a `must_change_password = true` bekapcsolódik), majd a felhasználó belépés után rögtön újat ad meg.
- **`email_system = true` esetén:**
  - A felhasználó megadja az e-mail címét (`/password_reset/new`).
  - Ha létezik aktív felhasználó az adott e-maillel, kiküldésre kerül egy 15 percig érvényes `:password_reset` link (`/password_reset/edit?token=...`).
  - Az új jelszó mentésekor a `must_change_password` visszaáll `false`-ra, és a token érvényét veszti.

---

### 4.4. Saját Profil (`/profile`)

Bejelentkezett felhasználók (`Tag` és `Admin`) számára:
- **Adatok módosítása:** `display_name` és (opcionálisan) `email` módosítása.
- **Jelszócsere:** Jelenlegi jelszó + új jelszó + megerősítés megadása. (Ha sikeres, `must_change_password` `false`-ra áll.)
- **Saját rekordok:** A felhasználó által beküldött rekordok listája státuszokkal (`PENDING`, `APPROVED`, `REJECTED` és az elutasítás indoklása).

---

### 4.5. Adminisztrációs Fiókkezelés (`/admin/users` és `/admin/invite_codes`)

Kizárólag `role == 'ADMIN'` felhasználók érhetik el:

1. **Felhasználók kezelése:**
   - Lista az összes felhasználóról (`username`, `display_name`, `email`, `role`, `is_active`, `last_login_at`).
   - **Szerepkör váltás:** `TAG` ↔ `ADMIN` (védelem: az utolsó aktív Admin nem fokozhatja le saját magát).
   - **Tiltás / Felfüggesztés:** `is_active` kapcsolása (`true` ↔ `false`; saját magát nem tilthatja ki).
   - **Ideiglenes jelszó generálása:** Véletlenszerű jelszó beállítása + `must_change_password = true`, egyszeri megjelenítés az Adminnak másolásra.
   - **Fiók törlése:** Csak jóváhagyással (saját fiók nem törölhető innen).

2. **Meghívókódok kezelése:**
   - Új kód generálása opcionális `label`, `max_uses` és `expires_at` megadásával.
   - Meglévő kódok listázása (`uses_count / max_uses`), aktív/inaktív állapot kapcsolása, törlése.

---

## 5. Végpontok (Routes) áttekintése

```text
GET    /login                      -> sessions#new
POST   /login                      -> sessions#create
DELETE /logout                     -> sessions#destroy

GET    /register                   -> registrations#new
POST   /register                   -> registrations#create

GET    /email_confirmation         -> email_confirmations#show

GET    /password_reset/new         -> password_resets#new
POST   /password_reset             -> password_resets#create
GET    /password_reset/edit        -> password_resets#edit
PATCH  /password_reset             -> password_resets#update

GET    /profile                    -> profiles#show
PATCH  /profile                    -> profiles#update
PATCH  /profile/password           -> profiles#update_password

namespace :admin do
  resources :users, only: [:index, :update, :destroy] do
    post :reset_password, on: :member
  end
  resources :invite_codes, only: [:index, :create, :update, :destroy]
  resources :settings, only: [:index, :update]
end
```
