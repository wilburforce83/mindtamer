# MindTamer – Codex Prompt Pack (Flutter + Flame)

Use this pack as your master prompt set for iterative generation. Copy sections into Codex in order. Keep the **Guardrails** at the top of every run.

---

## 0) Guardrails (ALWAYS include)
- **Project**: MindTamer – mental‑health companion with pixel‑art gamified loop, built in **Flutter + Flame**.
- **Non‑negotiables**: local‑only data, zero servers, privacy by default, pixel aesthetic, accessible UI, UK English.
- **Platforms**: Android + iOS. No web build needed for v1.
- **Persistence**: Hive (or Isar). All data stays on device. Versioned schema + migrations.
- **Monetisation**: Subscriptions via platform IAP: **£3.99/month, £34.99/year**, one‑time **7‑day trial**. Free tier = 1 class.
- **Safety disclaimer**: This is not medical advice; supportive tool only.
- **Architecture style**: Clean architecture (domain / application / presentation / data), Riverpod for state, GoRouter for nav.
- **Testing**: Unit + widget tests for critical flows; golden tests for UI states.
- **Lints/style**: `flutter_lints`, strong null‑safety, SOLID, small files, pure functions where possible.

---

## 1) Master System Prompt
“You are an expert Flutter + Flame engineer and product designer. You will output **production‑grade, runnable code** with:
1) clear file paths, 2) full imports, 3) minimal placeholders, 4) tests, and 5) TODOs for any external assets. Use Clean Architecture with Riverpod and GoRouter. Use Hive for storage (boxed models), in‑app purchases for subscriptions, and Flame for the battle scene. All data is local‑only with versioned migrations. Ensure **no blocking on main isolate** for heavy ops. Keep code modular. After each section, include a **‘Run/Verify’** checklist and **‘Next Prompt’** to continue.”

---

## 2) High‑Level Build Plan (paste as a single prompt)
- Scaffold repo
- Core packages: `flutter_riverpod`, `go_router`, `hive`, `hive_flutter`, `in_app_purchase`, `flame`, `csv`, `archive`, `path_provider`, `share_plus`, `flutter_local_notifications`, `permission_handler` (as needed), `intl`, `uuid`.
- Layers:
  - **domain**: entities, value objects, use cases
  - **data**: adapters, repositories, hive boxes, migrations
  - **application**: controllers/notifiers (Riverpod), services (charts, export)
  - **presentation**: screens, widgets, theming (pixel style), localization
  - **game**: Flame components, battle systems, assets
- Core features (MVP):
  1. Auth: **none** (local‑only). App lock optional via PIN.
  2. Journaling with tags + sentiment; links to daemons.
  3. Mood meters (0–100): battery, stress, focus, mood, sleep quality, social connection + up to 2 custom.
  4. Med tracking: plan, daily log, adherence heatmap.
  5. Charts (7/30/90d); retro pixel style.
  6. CSV export (journal, moods, med plan, med logs) zipped with `metadata.json`.
  7. Game loop: turn‑based daemon battles; buffs from journaling/meds/mood; XP + leveling with cadence: skills every other level up to L5, then every 5 levels; passive boost one level before skill.
  8. IAP subscriptions with 7‑day trial; free tier restriction to 1 class.

Deliver:
- Full folder tree with starter files
- Main models + Hive adapters
- Basic screens + navigation
- Dummy assets and pixel theme
- Unit/widget tests for storage + reducers

---

## 3) Repo Scaffolding Prompt
“Generate the complete Flutter project structure with these folders and placeholder files (list all files with contents):
```
lib/
  app.dart
  main.dart
  router.dart
  theme/
    pixel_theme.dart
  core/
    constants.dart
    utils/
      validators.dart
  data/
    hive/
      boxes.dart
      migrations/
        migration_001_init.dart
    models/
      journal_entry.dart
      mood_log.dart
      med_plan.dart
      med_log.dart
      achievement.dart
      player_profile.dart
      settings.dart
    repositories/
      journal_repository.dart
      mood_repository.dart
      medication_repository.dart
      export_repository.dart
      profile_repository.dart
  domain/
    entities/
      journal.dart
      mood.dart
      medication.dart
      progression.dart
    usecases/
      add_journal_entry.dart
      compute_buffs.dart
      record_med_intake.dart
      calculate_xp_gain.dart
  application/
    providers.dart
    journaling/
      journal_notifier.dart
    mood/
      mood_notifier.dart
    meds/
      med_notifier.dart
    gameplay/
      battle_notifier.dart
    export/
      export_notifier.dart
    iap/
      iap_notifier.dart
  presentation/
    widgets/
      pixel_button.dart
      pixel_slider.dart
      pixel_pillbox.dart
    screens/
      login_lite_lock_screen.dart
      dashboard_screen.dart
      journal_screen.dart
      mood_screen.dart
      meds_screen.dart
      charts_screen.dart
      battle_screen.dart
      settings_screen.dart
  game/
    battlefield.dart
    components/
      player_component.dart
      daemon_component.dart
      effect_component.dart
    systems/
      turn_system.dart
      damage_system.dart
      buff_system.dart
assets/
  images/ (TODO: add pixel sprites)
  fonts/ (TODO: add pixel font)
  data/
    tags_master.json
    enemies_master.json
```
Include: `pubspec.yaml` with all deps, Hive typeAdapters, Riverpod setup, and GoRouter routes. Add initial tests under `test/` for: journal repo save/load; mood log add/read; XP calc edge cases.”

---

## 4) Data Model & Hive Boxes Prompt
“Define Hive models + adapters for:
- JournalEntry {id, date, text, tags[], sentiment: enum, linkedEnemies[]}
- MoodLog {id, date, battery, stress, focus, mood, sleep, social, custom1?, custom2?}
- MedPlan {id, name, dose, scheduleTimes[], active: bool}
- MedLog {id, date, planId, taken: bool, time}
- Achievement {id, key, earnedAt}
- PlayerProfile {id, classKey, level, xp, unlockedSkills[], cosmetics[], titles[]}
- Settings {id, pinHash?, exportDir?, allowOsBackup: bool, theme: light/dark}

Include:
- Box names
- Migrations: v1 init (create boxes), v2 add PlayerProfile fields, v3 add custom meters
- Repository interfaces + implementations
- Sample fixtures for dev
- Unit tests for adapters + repos”

---

## 5) Journaling Module Prompt
“Implement Journaling:
- UI: `journal_screen.dart` with list + add entry modal, tag picker (from `tags_master.json`), sentiment selector (Positive/Negative/Mixed/Neutral), search/filter.
- Logic: `journal_notifier.dart` with CRUD; on save, compute enemy affinity tags for spawn weighting; trigger buffs/debuffs queue.
- Tests: create/save/filter entries; sentiment streak detector use‑case.”

---

## 6) Mood Tracking Module Prompt
“Implement Mood tracking (0–100) with default 6 meters + up to 2 custom:
- UI: `mood_screen.dart` with pixel sliders, ‘Daily Save/Lock’ that freezes values for the day.
- Data: prevent edits after lock; allow next‑day entries.
- Tests: lock behaviour, trend calc.”

---

## 7) Medication Module Prompt
“Implement Medication planner + logs:
- UI: pillbox grid (pixel style), plan editor, daily intake toggles, adherence heatmap (simple grid).
- Logic: reminders via local notifications (optional in v1 if time permits).
- Tests: adherence streak calculations, heatmap rendering logic.”

---

## 8) Charts Module Prompt
“Implement charts in a retro style (line for moods, bar for sentiment counts, heatmap for meds). Provide 7/30/90 filters, simple legends, and export screenshot to PNG (optional). No external chart libs if possible—compose with Flutter primitives for pixel look.”

---

## 9) CSV Export Prompt
“Implement full export:
- Create `/exports/` directory via `path_provider`.
- Generate CSVs: `journal.csv`, `moods.csv`, `med_plan.csv`, `med_logs.csv`.
- Create `metadata.json` with schema version + meter definitions.
- Zip into `mind_tamer_export_YYYYMMDD.zip` with `archive`.
- Share via `share_plus`.
- Tests: CSV headers; row counts; zip integrity.”

---

## 10) Game Loop & Flame Battle Scene Prompt
“Implement minimal viable turn‑based battle:
- Entities: Player, Daemon (HP, ATK, DEF, SPD, buffs[])
- Skills: basic attack; class‑flavoured skills; items (coffee, meditation bowl, acai berry, potion)
- Buffs: computed from journaling sentiment streaks, mood thresholds, med adherence streaks
- Flow: encounter -> turn order -> select skill/item -> damage/effect -> win/lose -> XP gain
- UI: pixel battlefield, animations placeholders; log panel
- Balance: deterministic formulas; unit tests for damage + XP; leveling cadence (to L5 then every 5 levels; passive boost before skill unlock)”

---

## 11) IAP Subscriptions Prompt
“Integrate `in_app_purchase` with 2 products: monthly and annual. Prices: £3.99/month, £34.99/year, 7‑day trial (platform configuration).
- Free tier gate: single class only; lock advanced charts; lock cosmetics.
- Store receipts saved locally; entitlement derivation on app start.
- Tests: mock store; entitlement transitions.”

---

## 12) Pixel Theme & Assets Prompt
“Create `pixel_theme.dart` with dark palette (very dark grey bg), large tap targets, high contrast. Provide placeholder pixel font references. Add TODOs for sprites: 32×32 and 64×64; create simple boxy placeholder assets and wire them in so the app runs.”

---

## 13) Settings, PIN Lock, and Privacy Prompt
“Implement Settings screen: toggle OS backup note, manage export dir, optional 4‑digit PIN app lock (local only). Include safety disclaimer page.”

---

## 14) Navigation & App Shell Prompt
“Wire GoRouter routes for all screens; bottom nav (Dashboard, Journal, Mood, Meds, Charts, Battle, Settings). Ensure deep links disabled for now. Add splash screen.”

---

## 15) QA & Runbook Prompt
“Provide:
- `RUN.md` with commands: `flutter pub get`, `flutter test`, `flutter run`.
- `TEST_PLAN.md` with critical user journeys.
- `ASSET_CHECKLIST.md` for sprites.
- CI example (GitHub Actions) running tests and `flutter analyze`.”

---

## 16) Acceptance Criteria (paste per module)
- **Persistence**: all create/read/update/delete flows survive restart.
- **Lock**: mood lock disables edits for that day.
- **Export**: produces a single zip with 4 CSVs + metadata.json.
- **Battle**: can start, take turns, end, and award XP; stats change with buffs.
- **IAP**: free tier limits enforced; upgrade toggles instantly.
- **Accessibility**: min 48dp targets; good contrast; scalable text.

---

## 17) Performance & Safety Prompt
“Ensure no jank: perform Hive ops off main isolate where needed, memoize heavy lists, lazy‑load long histories. Privacy text: no cloud; local‑only; export transparency.”

---

## 18) Backlog (post‑MVP)
- Achievements showcase + cosmetics shop (non‑pay cosmetic currency only)
- Journal‑triggered ‘closure battles’
- Encrypted backups to user‑chosen file (local) with password
- Optional platform achievements (opt‑in)
- On‑device analytics (basic counters) exported in CSV only

---

## 19) Kickoff Prompt (Use First)
“Using sections 0–4, generate the full Flutter project scaffold, with compilable code, all imports, adapters, Riverpod, GoRouter, and tests. Include `pubspec.yaml` and minimal placeholder assets so the app runs to a dashboard screen. Conclude with a ‘Run/Verify’ checklist.”

---

## 20) Iteration Loop Prompt (Use After Each Step)
“Review the current tree; if files are missing or imports broken, regenerate the minimal diffs to reach a green build. Then proceed to the next module prompt.”

