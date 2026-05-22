# MindTamer MVP Checklist

Last updated: 2026-05-22

This checklist turns the project review into an execution plan we can work through together.
The goal is a beta-ready MVP where UX, data, and core game systems behave consistently.

## P0 Stabilization

- [x] Create a shared MVP checklist in the repo.
- [x] Fix pending pre-battle buffs so they are applied after the battle engine is initialized.
- [x] Route journal encounters into the live battle screen instead of the stub resolver flow.
- [x] Reconnect journal healing/reward hooks to the current Isar journal flow.
- [x] Update full-data export to use the current journal and mood stores.
- [ ] Remove or log silent failures in the highest-risk flows: battle start, journal save, notifications, asset lookup.
- [ ] Add a repo-local Flutter toolchain pin and a documented bootstrap command.
- [ ] Get `flutter analyze` clean enough to use as a gate.
- [ ] Get `flutter test` passing as a baseline gate.

## P1 Data Integrity

- [ ] Choose one canonical data path per feature and remove legacy duplicates.
- [ ] Journal: finish migration from legacy Hive journal models/repositories to Isar-only storage.
- [ ] Mood: decide whether legacy daily mood logs remain a feature or are fully replaced by mood snapshots.
- [ ] Inventory/equipment: document canonical schemas for items, crafted gear, quick slots, and sprite slots.
- [ ] Define a canonical naming lexicon for classes, gear sets, monsters, echoes, and generated item names.
- [ ] Rebalance monster lexicon element tagging so general or positive concepts do not collapse into `shadow` encounters.
- [ ] Define an explicit monster naming grammar and curated modifier/family vocabulary so generated names read intentionally instead of scrambled.
- [ ] Add explicit migrations instead of try/catch defaulting for evolving settings/data models.
- [ ] Audit all exports so they include current user-visible data only.
- [ ] Add recovery-safe behavior for missing or malformed persisted records.

## P1 Architecture Cleanup

- [ ] Standardize on one UI state-management approach across the app.
- [ ] Move direct Hive/Isar box reads out of widget trees and into repositories/services/providers.
- [ ] Extract a central `PlayerStatsService` for HP, max HP, level scaling, gear bonuses, sprite bonuses, and buffs.
- [ ] Extract a central `BattleFlowService` so encounter creation, battle start, battle resolution, rewards, and codex updates share one path.
- [ ] Break down oversized files:
- [ ] `lib/presentation/screens/character_hub_screen.dart`
- [ ] `lib/application/gameplay/battle_notifier.dart`
- [ ] `lib/presentation/screens/meds_screen.dart`
- [ ] `lib/presentation/screens/crafting_screen.dart`

## P2 UX and Product Hardening

- [ ] Replace global text scaling overrides with overflow-safe responsive layouts.
- [ ] Refactor settings UI to avoid mutating state during build and recreating controllers every frame.
- [ ] Review onboarding/setup wording for inclusivity and mental-health product sensitivity.
- [ ] Add empty states and recovery messaging for journal, battles, meds, and inventory.
- [ ] Add visible loading/error states for expensive image-generation/rendering flows.
- [ ] Ensure all primary screens work cleanly on small phones without text clipping.

## P2 Gameplay and Progression

- [ ] Unify player HP/stat calculations across hub, battle, rewards, and items.
- [ ] Audit battle difficulty math and tune for the three difficulty levels.
- [ ] Validate rewards pacing for journal, mood, meds, echoes, and summons.
- [ ] Make status effects and buffs explain themselves in UI.
- [ ] Replace remaining debug/beta-only flows with production behavior.
- [ ] Add guardrails against runaway encounter generation and reward inflation.

## P2 Tests and Tooling

- [ ] Add unit tests for journal repository/search/export behavior.
- [ ] Add unit tests for health rewards and pending buff application.
- [ ] Add unit tests for battle scaling and resolution.
- [ ] Add widget tests for setup, journal create/edit, mood record, and med logging.
- [ ] Add a smoke integration path for create profile -> journal -> battle -> reward.
- [ ] Expand README with setup, architecture, storage, and release notes.

## P3 Beta Readiness

- [ ] Create a manual QA checklist covering onboarding, data entry, battle flow, rewards, and export.
- [ ] Add privacy/data handling notes appropriate for a mental-health-adjacent app.
- [ ] Audit notifications on iOS and Android end to end.
- [ ] Clean asset clutter such as backup files and `.DS_Store` artifacts from tracked content.
- [ ] Prepare a beta test brief with known limitations and feedback prompts.

## Current Working Slice

These are the next tasks I recommend we tackle after the changes in this commit:

- [ ] Replace broad `catch (_) {}` blocks in battle/reward flows with targeted logging and safer fallbacks.
- [ ] Build a single player stats calculator and switch hub + rewards + battle to use it.
- [ ] Remove the remaining legacy journal repository path from the app.
- [ ] Refactor settings screen state so it is stable and testable.
- [ ] Add the first meaningful automated tests around the repaired journal/battle/reward loop.
