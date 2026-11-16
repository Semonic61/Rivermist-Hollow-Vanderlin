# Main Navigation Audit Status

**Status:** main-specific static routing/inventory revalidation and focused source-contract review completed.
This is not certification of all gameplay behavior or the entire imported prose.

- Audited source: main commit b1b55fefc102b1432aa3d5c78ce3b4fa70759aa6.
- Checked on: 2026-11-16.
- Audit branch: docs/revalidate-navigation-main. Publication requires separate user authorization and does not expand the validated scope.
- Original import: PR #2 copied navigation and the local skill from Map-again
  commit 4b394d3fd8b964445fbe7b0caf9b69461988d283 onto main base
  efebebda520623c364c245a15194d787cf2fc000. That provenance is retained; this audit
  reads the current main snapshot rather than borrowing Map-again definitions.

## Coverage in update_policy Order

| Stage | Actually checked / updated |
|---|---|
| 1. Repository shape | Direct DM registration, late modular roots, world/controller ownership, core/RMH override example, local include-sort contract. |
| 2. Runtime owners | Regenerated every directly included subsystem macro declaration, its SS name, macro family, expanded type, and source file; included declarations outside the controller directory. |
| 3. Type routing | Checked type_index routes; split pocket dimension files and added main contract-party, loot-panel, relic and quest anchors. Full type_tree.md deliberately retained its original date/content. |
| 4. Routing | Checked router targets, all entrypoint Open first paths, system-map paths and the named SS owners; added actual quest, contract, recipe and loot owners. |
| 5. Lifecycle/handoffs | Read SSatoms and atom Initialize, base Destroy/queued cleanup, generic process(delta_time), and selected quest/cache handoffs. No world was booted. |
| 6. Signals/contracts | Regenerated definition locations and lexical totals; checked named COMSIG definitions; corrected SSdcs as the global hub and the held-item melee route. Read the base spell chain and movement anchors, not every override/payload. |
| 7. Workflow/helpers | Checked root instructions, local formatting/linter config, build/dependency/diagnostic scripts, TGUI route/import/locale/tooling anchors, and CI job definitions. Corrected unsupported engine/performance shortcuts without claiming new measurements. |

Static scope: **4993** direct project includes, **4992** DM files,
**691** RMH includes, **139** subsystem declarations,
and **780** distinct COMSIG macro names (including return flags).
Conditional compilation is not evaluated. Token counts are lexical and can include
definitions/comments; they are not executed-call or active-instance counts.

## Corrected Stale Facts and Evidence

| Imported fact | Main evidence and correction |
|---|---|
| 129 subsystems, all under controller roots | 139 declarations. SScontracts and SSrecipe_books are in RMH; SStrackables, SSmeatvines, SSfake_world and SSlooting also live outside the controller directory. See subsystem_map.md. |
| Quests have no dedicated owner | code/controllers/subsystem/questboard.dm defines SSquestboard for generation/prune/refill pools. Quest target components remain a separate reaction path. |
| All SS declarations are core-owned | modular_rmh/code/modules/antagonists/contracts/contract_subsystem.dm and modular_rmh/code/modules/crafting/recipe_book_db.dm declare their own SS globals using the shared scheduler. |
| Global signals register on GLOB | code/__DEFINES/dcs/helpers.dm defines SEND_GLOBAL_SIGNAL through SEND_SIGNAL(SSdcs, ...). |
| Pocket definitions are a single mapping file | They now live in code/modules/mapping/pocket_dimensions/, including _pocket_map_template.dm and pocket_dimension.dm. |
| Every non-mapload new atom gets LateInitialize | code/controllers/subsystem/atoms.dm only calls it when Initialize returns INITIALIZE_HINT_LATELOAD; the mapload argument selects queued vs inline behavior. |
| qdel means every reference became null | code/datums/datum.dm cleans timers/components/signals and returns QDEL_HINT_QUEUE; queued reclamation is not completed hard deletion. |
| attack_self starts the melee chain | code/_onclick/item_attack.dm has a separate activation proc; melee_attack_chain starts with target.base_item_interaction and has secondary/cancellation branches. |
| Old TGUI component directory, routes.ts, Jest/webpack workflow | Main uses tgui-core/components, routes.tsx, Bun tests, and Rspack; see tgui_guide.md. |
| Build only has independent TGUI/DM targets | Local DmTarget depends on TGUI, tracks packed bundles, and repacks a stale RSC in tools/build/build.ts. |
| Fixed engine caps / callback timing folklore | Unsupported 16-bit/view/sleep/input claims removed from engine_limits.md; local settings are source-backed and other invariants defer to the universal skills. |

## Reproducible Checks

Run from the repository root; these commands are read-only:

- python -B ai_navigation/validate_navigation.py
- python -B ai_navigation/validate_navigation.py --inventory
- python -B tools/ticked_file_enforcement/sort_includes.py --check
- git diff --check

The controller skill's validate_semantic_base.py was also run in strict mode.
It reports no missing paths and no unresolved bare filenames after disambiguation.

Validation at this snapshot:
- 97 relative Markdown links, 46 router targets and 57 Open first targets checked.
- 139 source SS declarations match the full subsystem index.
- Every SS owner in architecture.md has a real declaration.
- All literal COMSIG names in the four signal maps have a source definition.
- Project and unit-test include order checks pass.
- No build, DM diagnostics, frontend tests, integration tests, or runtime profiling ran.

## Remaining Limits / Follow-up

- type_tree.md is still the imported generated snapshot, not an updated main
  hierarchy. Search actual definitions and explicit parent_type before trusting it.
  A full compiler-resolved inheritance or override audit was not performed.
- The signal maps retain selected payload/return-value notes. Existence and selected
  base chains were checked; every listener, argument position, asynchronous path,
  cancellation branch, and per-feature override was not semantically proved.
- Rendering/GAGS/plane recipes, numeric performance claims in legacy examples,
  map correctness, UI behavior, accessibility/localization completeness, and
  complete AI/combat/round/economy scenarios remain unexercised. Path checks do
  not imply behavioral validation. Original dates in untouched prose remain.
- The build input list still omits explicit dndmagic and other late include-root
  globs; no incremental build experiment or tooling change was made.
- Dependency pins were checked, not the installed toolchain or server config.
  UI payload security and every illustrative handbook snippet were not tested.
- No workspace registry outside the allowed directories was changed. This file
  records the local drift/follow-up backlog within the user's authorized scope.

## Modified Files

This audit changes only ai_navigation/** and the local skill. The main worktree's
maps/index are outside the audit worktree. The list below includes this report and
the read-only validator. Publication is a separately authorized step; it does not certify additional source contracts or runtime behavior.

- `.agents/skills/rivermist-hollow/SKILL.md`
- `ai_navigation/AGENTS.md`
- `ai_navigation/DEVELOPER_GUIDE.md`
- `ai_navigation/MAIN_PORT_STATUS.md`
- `ai_navigation/architecture.md`
- `ai_navigation/coding_standards.md`
- `ai_navigation/combat_signal_map.md`
- `ai_navigation/core_procs.md`
- `ai_navigation/debug_routes.md`
- `ai_navigation/engine_limits.md`
- `ai_navigation/entrypoints.md`
- `ai_navigation/icon_rendering.md`
- `ai_navigation/modular_guide.md`
- `ai_navigation/movement_signal_map.md`
- `ai_navigation/performance_gotchas.md`
- `ai_navigation/rivermist_hollow_profile.md`
- `ai_navigation/router.md`
- `ai_navigation/runtime_errors.md`
- `ai_navigation/runtime_flow.md`
- `ai_navigation/signal_map.md`
- `ai_navigation/spell_signal_map.md`
- `ai_navigation/subsystem_map.md`
- `ai_navigation/system_dependencies.md`
- `ai_navigation/system_map.md`
- `ai_navigation/tgui_guide.md`
- `ai_navigation/type_index.md`
- `ai_navigation/update_policy.md`
- `ai_navigation/validate_navigation.py`
- `ai_navigation/visuals_guide.md`
