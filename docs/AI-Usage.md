# AI Usage Log

Ez a fájl az AI asszisztenssel végzett műveleteket és változtatásokat dokumentálja.

## 2026-11-13 19:29 – AI-Usage dokumentálási szabály létrehozása

- **Prompt:** Írj egy rule -t amiben ezt kötöd ki magadnak: Minden lépést dokumentálj a docs/AI-Usage.md be minden műveletnél jegyezd le hogy mi volt a prompt, annak értelmezését röviden, mit csináltál, és melyik fájlok változtak.
- **Értelmezés:** Olyan állandó munkaterületi szabály (rule) létrehozása, amely kötelezővé teszi minden lépés naplózását a `docs/AI-Usage.md` fájlba a prompt, a rövid értelmezés, az elvégzett műveletek és a módosított fájlok megjelölésével.
- **Elvégzett műveletek:**
  - Ellenőriztem a projekt könyvtárstruktúráját és az Antigravity rule konvenciókat.
  - Létrehoztam a `.agents/rules/ai-usage.md` szabályfájlt `trigger: always_on` beállítással.
  - Létrehoztam a `docs/AI-Usage.md` naplófájlt az első bejegyzéssel.
- **Módosított fájlok:**
  - `.agents/rules/ai-usage.md` (létrehozva)
  - `docs/AI-Usage.md` (létrehozva)

## 2026-11-13 19:38 – Specifikációk elemzése és megvalósítási terv készítése

- **Prompt:** Olvasd el a docs mappában lévő specifikációkat és csinálj egy tervet a megvalósításukhoz. Bontsd lépésekre.
- **Értelmezés:** A `docs/` mappában található adatstruktúra, fiókkezelési és látványterv specifikációk átolvasása, majd ezek alapján egy részletes, lépésekre (fázisokra) bontott megvalósítási terv összeállítása a Rails 7.1 + MySQL alkalmazáshoz.
- **Elvégzett műveletek:**
  - Átolvastam a `docs/Adatstruktúra/adatstruktura.md`, `docs/Fiókkezelés/fiokkezeles.md` és `docs/Látványtervek/latvanyterv.md` specifikációkat, valamint az SVG látványterveket (`kezdolap.svg`, `login.svg`, `register.svg`, `er_diagram.svg`).
  - Áttekintettem a meglévő Rails 7.1 projektstruktúrát (`Gemfile`, `config/routes.rb`, `config/database.yml`, `db/seeds.rb`, `app/`).
  - Összeállítottam a 8 fázisból álló, lépésekre bontott megvalósítási tervet.
  - Dokumentáltam a műveletet a `docs/AI-Usage.md` fájlban.
- **Módosított fájlok:**
  - `docs/AI-Usage.md` (módosítva)

## 2026-11-13 19:55 – PálRecord alkalmazás teljes megvalósítása a specifikációk alapján

- **Prompt:** Jóváhagyom a tervet, mehet!
- **Értelmezés:** A jóváhagyott 8 fázisú terv alapján a teljes Rails 7.1 + MySQL PálRecord alkalmazás (függőségek, adatbázis-migrációk, modellek, seed adatok, fiókkezelés, versenyszámok és rekordbeküldés, admin felület, minimalista nézetek és tesztek) elkészítése.
- **Elvégzett műveletek:**
  - Engedélyeztem a `bcrypt` gemet a `Gemfile` és `Gemfile.lock` fájlokban, valamint beállítottam a mailer `default_url_options` értékeket a környezeti konfigurációkban.
  - Létrehoztam az 5 adatbázis-migrációt (`settings`, `users` + `invite_codes`, `categories`, `records`, `attachments`) és a `db/schema.rb` fájlt.
  - Elkészítettem a modelleket (`Current`, `Setting`, `User`, `InviteCode`, `Category`, `Record`, `Attachment`) és a `db/seeds.rb` alapadatokat.
  - Megvalósítottam az útvonalakat (`config/routes.rb`), a `UserMailer`-t, az autentikációs/profil/kategória/rekord/melléklet controllereket, valamint az `Admin` névtér controllereit.
  - Elkészítettem a minimalista CSS stílusrendszert (`application.css`), a közös layoutot és az összes nézetet a látványtervek alapján.
  - Megírtam a modell- és integrációs teszteket (`test/models/`, `test/integration/`), valamint naplóztam a műveletet a `docs/AI-Usage.md` fájlban. (Megjegyzés: lokális Ruby/MySQL CLI nem állt rendelkezésre ezen a Windows munkaállomáson, így a migrációk és tesztek futtatása a célkörnyezetben szükséges.)
- **Módosított fájlok:**
  - `Gemfile` (módosítva)
  - `Gemfile.lock` (módosítva)
  - `config/routes.rb` (módosítva)
  - `config/environments/development.rb` (módosítva)
  - `config/environments/production.rb` (módosítva)
  - `config/environments/test.rb` (módosítva)
  - `db/seeds.rb` (módosítva)
  - `db/schema.rb` (létrehozva)
  - `db/migrate/20261113194501_create_settings.rb` (létrehozva)
  - `db/migrate/20261113194502_create_users_and_invite_codes.rb` (létrehozva)
  - `db/migrate/20261113194503_create_categories.rb` (létrehozva)
  - `db/migrate/20261113194504_create_records.rb` (létrehozva)
  - `db/migrate/20261113194505_create_attachments.rb` (létrehozva)
  - `app/models/current.rb` (létrehozva)
  - `app/models/setting.rb` (létrehozva)
  - `app/models/user.rb` (létrehozva)
  - `app/models/invite_code.rb` (létrehozva)
  - `app/models/category.rb` (létrehozva)
  - `app/models/record.rb` (létrehozva)
  - `app/models/attachment.rb` (létrehozva)
  - `app/controllers/application_controller.rb` (módosítva)
  - `app/controllers/sessions_controller.rb` (létrehozva)
  - `app/controllers/registrations_controller.rb` (létrehozva)
  - `app/controllers/email_confirmations_controller.rb` (létrehozva)
  - `app/controllers/password_resets_controller.rb` (létrehozva)
  - `app/controllers/profiles_controller.rb` (létrehozva)
  - `app/controllers/categories_controller.rb` (létrehozva)
  - `app/controllers/records_controller.rb` (létrehozva)
  - `app/controllers/attachments_controller.rb` (létrehozva)
  - `app/controllers/admin/base_controller.rb` (létrehozva)
  - `app/controllers/admin/users_controller.rb` (létrehozva)
  - `app/controllers/admin/invite_codes_controller.rb` (létrehozva)
  - `app/controllers/admin/settings_controller.rb` (létrehozva)
  - `app/controllers/admin/records_controller.rb` (létrehozva)
  - `app/mailers/user_mailer.rb` (létrehozva)
  - `app/helpers/application_helper.rb` (módosítva)
  - `app/assets/stylesheets/application.css` (módosítva)
  - `app/views/layouts/application.html.erb` (módosítva)
  - `app/views/user_mailer/email_confirmation.html.erb` (létrehozva)
  - `app/views/user_mailer/email_confirmation.text.erb` (létrehozva)
  - `app/views/user_mailer/password_reset.html.erb` (létrehozva)
  - `app/views/user_mailer/password_reset.text.erb` (létrehozva)
  - `app/views/categories/index.html.erb` (létrehozva)
  - `app/views/categories/show.html.erb` (létrehozva)
  - `app/views/categories/_form.html.erb` (létrehozva)
  - `app/views/categories/new.html.erb` (létrehozva)
  - `app/views/categories/edit.html.erb` (létrehozva)
  - `app/views/sessions/new.html.erb` (létrehozva)
  - `app/views/registrations/new.html.erb` (létrehozva)
  - `app/views/password_resets/new.html.erb` (létrehozva)
  - `app/views/password_resets/edit.html.erb` (létrehozva)
  - `app/views/profiles/show.html.erb` (létrehozva)
  - `app/views/records/_form.html.erb` (létrehozva)
  - `app/views/records/new.html.erb` (létrehozva)
  - `app/views/records/edit.html.erb` (létrehozva)
  - `app/views/admin/_nav.html.erb` (létrehozva)
  - `app/views/admin/records/index.html.erb` (létrehozva)
  - `app/views/admin/users/index.html.erb` (létrehozva)
  - `app/views/admin/invite_codes/index.html.erb` (létrehozva)
  - `app/views/admin/settings/index.html.erb` (létrehozva)
  - `test/models/record_test.rb` (létrehozva)
  - `test/models/user_test.rb` (létrehozva)
  - `test/integration/authentication_flow_test.rb` (létrehozva)
  - `docs/AI-Usage.md` (módosítva)

## 2026-11-13 21:14 – Fontosabb létrehozott fájlok működésének bemutatása

- **Prompt:** Magyarázd el fontosabb létrehozott fájlok működését.
- **Értelmezés:** A PálRecord alkalmazás legfontosabb újonnan létrehozott és módosított fájljainak (modellek, controllerek, útvonalak, adatbázis-séma, nézetek) működésének és felelősségi köreinek közérthető elmagyarázása.
- **Elvégzett műveletek:**
  - Összefoglaltam a kulcsfontosságú fájlok felépítését és együttműködését (adatmodell, fiókkezelés, rekordok/verifikációk és adminisztráció).
  - Dokumentáltam a műveletet a `docs/AI-Usage.md` fájlban.
- **Módosított fájlok:**
  - `docs/AI-Usage.md` (módosítva)

## 2026-11-14 13:44 – Pontrendszer specifikáció és vizuális illusztrációk készítése

- **Prompt:** Tervezzünk egy pontrendszert a weboldalhoz (`/plan`, `/grill-me`), logaritmikus pontszámítással, majd készítsük el a pontrendszer specifikációt egy új `"Új Funkciók/Pontrendszer"` mappába vizuális illusztrációkkal (kezdőlapon oldalsó leaderboard, pontok kijelzése).
- **Értelmezés:** Interaktív tervezés után a véglegesített logaritmikus, résztvevő-arányos, örökös élő és szezonális versenyeket, valamint havi kategória-létrehozási kvótát magában foglaló pontrendszer dokumentálása a `docs/Új Funkciók/Pontrendszer/` mappában, minimalista SVG látványtervekkel kiegészítve.
- **Elvégzett műveletek:**
  - Interaktív kérdés-válasz során rögzítettem a pontrendszer szabályait: csak helyezési pontok, résztvevő-arányos logaritmikus képlet (`N=12` esetén `12, 8, 6, 5, ...`), `N=1` esetén 1 pont, holtversenyben a korábbi feltöltés nyer, havi kategória-létrehozási kvóta (`monthly_category_limit`), örökös élő ranglista + admin által indított szezonális versenyek.
  - Létrehoztam a `docs/Új Funkciók/Pontrendszer/kezdolap_leaderboard.svg` vizuális tervet (fejléc pontkijelzés, kétoszlopos kezdőlap kategóriákkal és oldalsó Örökös/Szezonális Leaderboarddal).
  - Létrehoztam a `docs/Új Funkciók/Pontrendszer/kategoria_es_profil_pontok.svg` vizuális tervet (kategória ranglista pontokkal, holtverseny- és saját kísérlet kezeléssel, valamint a profiloldal pont-összesítőivel).
  - Elkészítettem a `docs/Új Funkciók/Pontrendszer/pontrendszer.md` specifikációt a matematikai képlettel, adatbázis-tervvel (`seasons` tábla, `settings` bővítés) és számítási architektúrával (`LeaderboardCalculator`).
  - Dokumentáltam a műveletet a `docs/AI-Usage.md` fájlban.
- **Módosított fájlok:**
  - `docs/Új Funkciók/Pontrendszer/pontrendszer.md` (létrehozva)
  - `docs/Új Funkciók/Pontrendszer/kezdolap_leaderboard.svg` (létrehozva)
  - `docs/Új Funkciók/Pontrendszer/kategoria_es_profil_pontok.svg` (létrehozva)
  - `docs/AI-Usage.md` (módosítva)

## 2026-11-14 13:44 – Pontrendszer specifikáció és vizuális illusztrációk készítése

- **Prompt:** Tervezzünk egy pontrendszert a weboldalhoz (`/plan`, `/grill-me`), logaritmikus pontszámítással, majd készítsük el a pontrendszer specifikációt egy új `"Új Funkciók/Pontrendszer"` mappába vizuális illusztrációkkal (kezdőlapon oldalsó leaderboard, pontok kijelzése).
- **Értelmezés:** Interaktív tervezés után a véglegesített logaritmikus, résztvevő-arányos, örökös élő és szezonális versenyeket, valamint havi kategória-létrehozási kvótát magában foglaló pontrendszer dokumentálása a `docs/Új Funkciók/Pontrendszer/` mappában, minimalista SVG látványtervekkel kiegészítve.
- **Elvégzett műveletek:**
  - Interaktív kérdés-válasz során rögzítettem a pontrendszer szabályait: csak helyezési pontok, résztvevő-arányos logaritmikus képlet (`N=12` esetén `12, 8, 6, 5, ...`), `N=1` esetén 1 pont, holtversenyben a korábbi feltöltés nyer, havi kategória-létrehozási kvóta (`monthly_category_limit`), örökös élő ranglista + admin által indított szezonális versenyek.
  - Létrehoztam a `docs/Új Funkciók/Pontrendszer/kezdolap_leaderboard.svg` vizuális tervet (fejléc pontkijelzés, kétoszlopos kezdőlap kategóriákkal és oldalsó Örökös/Szezonális Leaderboarddal).
  - Létrehoztam a `docs/Új Funkciók/Pontrendszer/kategoria_es_profil_pontok.svg` vizuális tervet (kategória ranglista pontokkal, holtverseny- és saját kísérlet kezeléssel, valamint a profiloldal pont-összesítőivel).
  - Elkészítettem a `docs/Új Funkciók/Pontrendszer/pontrendszer.md` specifikációt a matematikai képlettel, adatbázis-tervvel (`seasons` tábla, `settings` bővítés) és számítási architektúrával (`LeaderboardCalculator`).
  - Dokumentáltam a műveletet a `docs/AI-Usage.md` fájlban.
- **Módosított fájlok:**
  - `docs/Új Funkciók/Pontrendszer/pontrendszer.md` (létrehozva)
  - `docs/Új Funkciók/Pontrendszer/kezdolap_leaderboard.svg` (létrehozva)
  - `docs/Új Funkciók/Pontrendszer/kategoria_es_profil_pontok.svg` (létrehozva)
  - `docs/AI-Usage.md` (módosítva)


## 2026-11-14 14:02 – Pontrendszer, szezonális versenyek és havi kategória-kvóta megvalósítása

- **Prompt:** `/goal Hajtsd végre a Pontrendszer mappában lévő specifikációk alapján az új funkciót.`
- **Értelmezés:** A `docs/Új Funkciók/Pontrendszer/pontrendszer.md` specifikáció, valamint a `kezdolap_leaderboard.svg` és `kategoria_es_profil_pontok.svg` látványtervek alapján a teljes közösségi pontrendszer (logaritmikus pontszámítás, Örökös Élő és Szezonális ranglista, havi kategória-létrehozási kvóta, Admin szezonkezelés, `Rails.cache` alapú gyorsítótárazás és UI nézetek) implementálása.
- **Elvégzett műveletek:**
  - Létrehoztam a `seasons` adatbázistábla migrációját (`20261114140001_create_seasons.rb`) és frissítettem a `db/schema.rb` fájlt.
  - Elkészítettem a `LeaderboardCalculator` service-t (`app/services/leaderboard_calculator.rb`) a logaritmikus pontképlettel, egyéni legjobb szűréssel, `created_at` alapú holtverseny-kezeléssel, inaktív tagok és archivált kategóriák kizárásával, Örökös Élő és Szezonális összesítéssel, valamint verziókulcsos `Rails.cache` gyorsítótárazással.
  - Létrehoztam a `Season` modellt (`app/models/season.rb`) és a `LeaderboardCacheInvalidatable` concern-t (`app/models/concerns/leaderboard_cache_invalidatable.rb`), továbbá frissítettem a `Setting` (`monthly_category_limit`), `User` (kvótaszámítás), `Category` (kvótavalidáció, `created_at` alapú rangsorolás, szezon-illesztés) és `Record` modelleket.
  - Bővítettem az útvonalakat (`config/routes.rb`), létrehoztam az `Admin::SeasonsController`-t, valamint frissítettem az `ApplicationController`, `CategoriesController`, `ProfilesController` és `Admin::SettingsController` osztályokat.
  - Elkészítettem és frissítettem a nézeteket és a CSS-t (`application.css`): fejléc pontkijelzés, kétoszlopos kezdőlap Örökös/Szezonális Leaderboard sávval és kvótajelzéssel, kategória ranglista helyezési pontokkal és másodlagos kísérletekkel, profiloldali 3 összefoglaló kártya és tételes pontlebontás, valamint az Admin Szezonok és Beállítások felület.
  - Frissítettem a `db/seeds.rb` minta szezonnal, valamint frissítettem és létrehoztam a modell-, service- és integrációs teszteket (`record_test.rb`, `season_test.rb`, `leaderboard_calculator_test.rb`, `points_and_seasons_flow_test.rb`). (Megjegyzés: lokális Ruby/MySQL CLI továbbra sem érhető el ezen a Windows munkaállomáson, így a migrációk és tesztek futtatása a célkörnyezetben / CI-ban történik.)
- **Módosított fájlok:**
  - `db/migrate/20261114140001_create_seasons.rb` (létrehozva)
  - `db/schema.rb` (módosítva)
  - `db/seeds.rb` (módosítva)
  - `app/services/leaderboard_calculator.rb` (létrehozva)
  - `app/models/concerns/leaderboard_cache_invalidatable.rb` (létrehozva)
  - `app/models/season.rb` (létrehozva)
  - `app/models/setting.rb` (módosítva)
  - `app/models/user.rb` (módosítva)
  - `app/models/category.rb` (módosítva)
  - `app/models/record.rb` (módosítva)
  - `config/routes.rb` (módosítva)
  - `app/controllers/application_controller.rb` (módosítva)
  - `app/controllers/categories_controller.rb` (módosítva)
  - `app/controllers/profiles_controller.rb` (módosítva)
  - `app/controllers/admin/seasons_controller.rb` (létrehozva)
  - `app/controllers/admin/settings_controller.rb` (módosítva)
  - `app/helpers/application_helper.rb` (módosítva)
  - `app/views/layouts/application.html.erb` (módosítva)
  - `app/views/categories/index.html.erb` (módosítva)
  - `app/views/categories/new.html.erb` (módosítva)
  - `app/views/categories/_form.html.erb` (módosítva)
  - `app/views/categories/show.html.erb` (módosítva)
  - `app/views/profiles/show.html.erb` (módosítva)
  - `app/views/admin/_nav.html.erb` (módosítva)
  - `app/views/admin/seasons/_form.html.erb` (létrehozva)
  - `app/views/admin/seasons/index.html.erb` (létrehozva)
  - `app/views/admin/seasons/edit.html.erb` (létrehozva)
  - `app/views/admin/settings/index.html.erb` (módosítva)
  - `app/assets/stylesheets/application.css` (módosítva)
  - `test/models/record_test.rb` (módosítva)
  - `test/models/season_test.rb` (létrehozva)
  - `test/services/leaderboard_calculator_test.rb` (létrehozva)
  - `test/integration/points_and_seasons_flow_test.rb` (létrehozva)
  - `docs/AI-Usage.md` (módosítva)

## 2026-11-14 14:06 – CI teszthiba javítása (archivált kategória rekord létrehozása a tesztben)

- **Prompt:** CI hiba (`LeaderboardCalculatorTest#test_computes_overall_and_seasonal_leaderboards,_tie-breakers,_and_excludes_archived_categories` -> `ActiveRecord::RecordInvalid: Validation failed: Category archivált, új rekord nem küldhető be ebbe a versenyszámba`)
- **Értelmezés:** A `Record` modell helyesen tiltja új rekord létrehozását már archivált kategóriába, ezért a `LeaderboardCalculatorTest` tesztesetében a kategóriát aktívként kell létrehozni, felvinni a rekordot, majd utána archiválni a kategóriát.
- **Elvégzett műveletek:**
  - Módosítottam a `test/services/leaderboard_calculator_test.rb` fájlt úgy, hogy az `archived_cat` először aktívként jöjjön létre, a `Record.create!` után kapja meg az `is_archived: true` állapotot.
  - Dokumentáltam a javítást a `docs/AI-Usage.md` fájlban.
- **Módosított fájlok:**
  - `test/services/leaderboard_calculator_test.rb` (módosítva)
  - `docs/AI-Usage.md` (módosítva)

## 2026-11-14 21:52 – Projektet lefedő tesztek és tesztelési dokumentáció készítése

- **Prompt:** Tervezzünk sokféle tesztet az egész projektet lefedve, szedjük össze az eddig megvalósított teszteket típusra rendezve, majd készítsünk dokumentációt és teszteket erről.
- **Értelmezés:** A meglévő 19 teszteset típus szerinti rendszerezése, a hiányzó modellek (`Setting`, `InviteCode`, `Category`, `Attachment`, valamint `User`/`Record` kiegészítések), a `UserMailer`, az `ApplicationHelper`, a jogosultsági/biztonsági és e-mail/melléklet integrációs tesztek, valamint a Capybara (`:rack_test`) UI rendszerteszt megírása és dokumentálása a `docs/Tesztelés/tesztelesi_terv.md` fájlban.
- **Elvégzett műveletek:**
  - Áttekintettem a teljes kódbázist és a meglévő 6 tesztfájl (19 teszteset) tartalmát.
  - Létrehoztam az új modell teszteket (`setting_test.rb`, `invite_code_test.rb`, `category_test.rb`, `attachment_test.rb`), és bővítettem a `user_test.rb` és `record_test.rb` fájlokat.
  - Létrehoztam a mailer (`user_mailer_test.rb`) és helper (`application_helper_test.rb`) teszteket.
  - Létrehoztam a jogosultsági/biztonsági (`security_and_authorization_test.rb`) és az e-mail/fájlfeltöltési (`email_system_and_attachments_flow_test.rb`) integrációs teszteket.
  - Átállítottam a `test/application_system_test_case.rb` meghajtót `:rack_test`-re, és elkészítettem a `user_journey_system_test.rb` UI folyamattesztet.
  - Elkészítettem a típus szerint rendszerezett teljes tesztelési specifikációt a `docs/Tesztelés/tesztelesi_terv.md` fájlban.
  - Naplóztam a lépést a `docs/AI-Usage.md` fájlban. (Megjegyzés: ezen a Windows munkaállomáson nincs telepített Ruby/MySQL CLI, így a tesztek tényleges futtatása a célkörnyezetben szükséges.)
- **Módosított fájlok:**
  - `test/models/setting_test.rb` (létrehozva)
  - `test/models/invite_code_test.rb` (létrehozva)
  - `test/models/category_test.rb` (létrehozva)
  - `test/models/attachment_test.rb` (létrehozva)
  - `test/models/user_test.rb` (módosítva)
  - `test/models/record_test.rb` (módosítva)
  - `test/mailers/user_mailer_test.rb` (létrehozva)
  - `test/helpers/application_helper_test.rb` (létrehozva)
  - `test/integration/security_and_authorization_test.rb` (létrehozva)
  - `test/integration/email_system_and_attachments_flow_test.rb` (létrehozva)
  - `test/application_system_test_case.rb` (módosítva)
  - `test/system/user_journey_system_test.rb` (létrehozva)
  - `docs/Tesztelés/tesztelesi_terv.md` (létrehozva)
  - `docs/AI-Usage.md` (módosítva)

## 2026-11-14 21:57 – URL-kódolt token kinyerés javítása a mailer és e-mail integrációs tesztekben

- **Prompt:** A CI futtatás (`bin/rails test`) 50 tesztből 48 sikeres és 2 sikertelen esetet jelzett (`UserMailerTest#test_password_reset_sends_reset_link_with_valid_token` és `EmailSystemAndAttachmentsFlowTest#test_email_system=true_allows_self-service_password_reset_and_invalidates_used_token`).
- **Értelmezés:** A `generate_token_for(:password_reset)` Base64 paddinget (`=`) tartalmazó tokent állított elő, amelyet az URL helper `%3D`-re kódolt; a tesztek `CGI.unescape` nélkül nyerték ki a levélből, ezért a token-ellenőrzés elbukott (illetve duplán URL-kódolódott `%253D`-re).
- **Elvégzett műveletek:**
  - A `test/mailers/user_mailer_test.rb` fájlban hozzáadtam az `extract_token` segédmetódust `email.text_part.decoded` + `CGI.unescape` használatával.
  - A `test/integration/email_system_and_attachments_flow_test.rb` fájlban hozzáadtam az `extract_token_from_mail` segédmetódust `mail.text_part.decoded` + `CGI.unescape` használatával.
  - Naplóztam a javítást a `docs/AI-Usage.md` fájlban.
- **Módosított fájlok:**
  - `test/mailers/user_mailer_test.rb` (módosítva)
  - `test/integration/email_system_and_attachments_flow_test.rb` (módosítva)
  - `docs/AI-Usage.md` (módosítva)
