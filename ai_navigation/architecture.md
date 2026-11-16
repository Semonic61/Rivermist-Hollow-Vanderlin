# Architecture Overview

Last validated 2026-11-16 against `origin/main` at `b1b55fefc102b1432aa3d5c78ce3b4fa70759aa6`.
Scope: static composition, declaration ownership, and the source paths below; not a running-world test.
See [MAIN_PORT_STATUS.md](MAIN_PORT_STATUS.md) for the complete audit boundary.

## Composition Model

[vanderlin.dme](../vanderlin.dme) explicitly includes the DM files in a linear graph.
Core maps/templates, world, defines, helpers, globals, controllers, datums, modules,
game types and interface code precede small `modular_alizeria` / `modular_ratwood`
blocks and the main `modular_rmh` block. RMH files are directly registered in the
project, including `modular_rmh/dndmagic` and standalone packs under `modular_rmh/modular`.
The root [AGENTS.md](../AGENTS.md) requires the include sorter after an include change.

A late declaration can reopen a common type, not just add an isolated subtype.
Compare [core item Initialize](../code/game/objects/items.dm) with
[RMH tweaks](../modular_rmh/code/tweaks.dm); inspect all proc bodies, include order,
explicit `parent_type`, arguments, and `..()` before changing an override.

## Runtime Backbone

- [code/world.dm](../code/world.dm) defines the world, including `fps = 20` and
  `view = "15x15"`. These are source settings, not measurements of a running server.
- [master.dm](../code/controllers/master.dm) discovers subsystem subtypes and schedules them.
  [subsystem.dm](../code/controllers/subsystem.dm) supplies init order, waits,
  priorities, flags, runlevels, and sleeping/resuming states.
- [MC.dm](../code/__DEFINES/MC.dm) expands subsystem macros into SS globals and types.
  [subsystem_map.md](subsystem_map.md) indexes **139** declarations in directly
  included DM files, including declarations outside the controller directory.
- [SSatoms](../code/controllers/subsystem/atoms.dm) coordinates initialization and
  late loaders. Late initialization requires `INITIALIZE_HINT_LATELOAD`; it is
  deferred for mapload and called inline for non-mapload initialization.
- [datum.dm](../code/datums/datum.dm) owns base `Destroy()` cleanup;
  [garbage.dm](../code/controllers/subsystem/garbage.dm) owns queued deletion.
  A queued deletion is not a guarantee that all references already became null.
- [processing/_processing.dm](../code/controllers/subsystem/processing/_processing.dm)
  calls `process(wait * 0.1)`, in seconds. Its base `process(delta_time)` returns
  `PROCESS_KILL`; inspect each processing family's caller before adding parent calls.
- [DCS helpers](../code/__DEFINES/dcs/helpers.dm) route `SEND_GLOBAL_SIGNAL` to
  **SSdcs**, not GLOB. Ordinary signal callbacks run on the signaled datum's path.

## Domain Layers

| Location | Role |
|---|---|
| `code/__DEFINES`, `code/__HELPERS`, `code/_globalvars` | Macros, common procs, shared state |
| `code/controllers` | Bootstrap, scheduling, configuration, most subsystems |
| `code/datums` | Reusable state, components, elements, status effects, AI |
| `code/modules`, `code/game` | Feature systems and concrete game types |
| `_maps`, `code/modules/mapping`, `code/modules/procedural_mapping` | Static templates and procedural placement |
| `interface`, `code/modules/tgui`, `tgui/packages` | BYOND interface, DM UI backend, TypeScript frontend |
| `modular_rmh/code`, `modular_rmh/modular`, `modular_rmh/dndmagic` | RMH extensions and feature packs |
| `config`, `SQL`, `tools` | Configuration, schemas, developer tools |

## Runtime Ownership Quick Reference

Owners below are declaration/entrypoint routes, not a claim that one SS owns every
synchronous proc in that domain. Counts and macro-expanded types are in the subsystem index.

| Domain | Primary owner or hook host | Key files |
|---|---|---|
| Global signals | `SSdcs` | `code/__DEFINES/dcs/helpers.dm`, `code/controllers/subsystem/dcs.dm` |
| Combat | synchronous item/mob hooks | `code/_onclick/item_attack.dm`, `code/_onclick/other_mobs.dm` |
| Movement | `SSmovement`, `SSmove_manager` | `code/controllers/subsystem/movement/**` |
| Spells and effects | `SSmagic`, `SSstatusprocess` | `code/modules/spells/**`, `code/datums/status_effects/**` |
| AI | `SSai_controllers`, `SSai_behaviors`, `SSai_movement` | `code/datums/ai/**` |
| Jobs and migrants | `SSjob`, `SSmigrants`, `SSrole_class_handler` | `code/modules/jobs/**`, `code/datums/migrants/**` |
| Events | `SSgamemode`, `SSevents` | `code/modules/antagonists/**`, `code/modules/events/**` |
| Economy and housing | `SSeconomy`, `SShousing`, `SStreasury` | `code/modules/economy/**`, `code/controllers/subsystem/property_management.dm` |
| Quest pool | `SSquestboard` | `code/controllers/subsystem/questboard.dm`, `code/modules/questing/**` |
| Antagonist contracts | `SScontracts` | `modular_rmh/code/modules/antagonists/contracts/contract_subsystem.dm` |
| Recipe book cache/assets | `SSrecipe_books` | `modular_rmh/code/modules/crafting/recipe_book_db.dm` |
| Loot images | `SSlooting` | `code/modules/lootpanel/ss_looting.dm` |
| Mapping and pockets | `SSmapping`, `SSpocket_dimensions`, `SSdungeon_generator` | `code/modules/mapping/pocket_dimensions/**`, `code/controllers/subsystem/pocket_dimensions.dm` |
| Other main additions | `SSrelations`, `SSrelics`, `SSprofiler`, `SStrackables`, `SSmeatvines`, `SSfake_world` | see `ai_navigation/subsystem_map.md` for exact source files |
| Overlays and lighting | `SSoverlays`, `SSvis_overlays`, `SSlighting` | `code/controllers/subsystem/overlays.dm`, `code/controllers/subsystem/lighting.dm` |
| UI | `SStgui`, `SSvisual_ui` | `code/modules/tgui/**`, `tgui/packages/**` |
| Cleanup | `SSgarbage` | `code/controllers/subsystem/garbage.dm` |

## Build Boundary

[build.ts](../tools/build/build.ts) builds TGUI and DM; local DmTarget also waits
for TGUI and repacks an outdated RSC when packed bundles are newer. The separate
`dndmagic` directory is still absent from DmTarget's explicit input globs.
See [the repository profile](rivermist_hollow_profile.md) for commands and diagnostics.
Universal BYOND semantics and engineering guidance belong to the installed skills;
this document does not claim engine timing or client performance was measured.
