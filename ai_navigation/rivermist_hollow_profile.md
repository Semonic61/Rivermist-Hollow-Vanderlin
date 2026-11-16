# Rivermist Hollow Repository Profile

Last statically validated **2026-11-16** against main commit
b1b55fefc102b1432aa3d5c78ce3b4fa70759aa6. Checked source contracts, include order,
build configuration, and source links; no compiler or running world was used.
See [MAIN_PORT_STATUS.md](MAIN_PORT_STATUS.md) for provenance and audit limits.
This is the fork-fact reference for the
[rivermist-hollow skill](../.agents/skills/rivermist-hollow/SKILL.md).

## Identity and applicability

- [README.md](../README.md) identifies **Rivermist Hollow**, a Noctra/Vanderlin
  fork. The project is [vanderlin.dme](../vanderlin.dme); the main extension
  directory is [modular_rmh/](../modular_rmh/).
- This profile applies to that combination of repository identity, project,
  and extension layer. It does not describe upstream Vanderlin or every fork
  with a `vanderlin.dme`. In particular, do not assume a `modular_abel` layout
  or aggregator registration from another Vanderlin profile.
- All paths below are relative to this repository. No fixed checkout location
  or user skill installation is required.
- The entrypoints remain [AGENTS.md](../AGENTS.md),
  [ai_navigation/AGENTS.md](AGENTS.md), and [router.md](router.md). This profile
  supplements them and the universal skills; it does not replace them.
- Verification here does not establish runtime behavior, map correctness,
  installed tool versions, or a successful build. Recheck referenced source
  before relying on a literal identifier or changing an affected contract.

## DM registration and include order

Source: [vanderlin.dme](../vanderlin.dme), especially the includes containing
`modular_alizeria`, `modular_ratwood`, and `modular_rmh`.

- RMH DM files are registered directly with explicit `#include` entries in the
  `.dme`. A file being present on disk does not make it part of the build.
  Preserve the surrounding registration convention when an authorized task
  adds a file; do not invent an aggregator layer.
- The main code is followed by a small `modular_alizeria` / `modular_ratwood`
  cluster, then the RMH block. This makes RMH the main late extension layer.
- The RMH block starts with `modular_rmh/code/tweaks.dm`, followed by local `_DEFINES` and
  other RMH files; it also includes `dndmagic` and `modular` files directly.
  Check the exact order for the dependency being changed. A macro declared
  late in this block cannot supply an earlier preprocessor use.
- A new include or include-order change is a build-graph change. Evaluate it
  against the user's authorized scope and [human_checking.md](human_checking.md).
  The presence of a modular directory is not permission to reorder bootstrap.

Main's [root instructions](../AGENTS.md) require
[sort_includes.py](../tools/ticked_file_enforcement/sort_includes.py) after changes
inside the include blocks. Its read-only --check mode confirms both the project
and unit-test include lists are in CI order at this snapshot. Do not reorder
includes by an assumed modular hierarchy instead of the actual sorting contract.

## Inheritance and effective behavior

- Search the original type or proc in `code/`, then all relevant RMH
  declarations on that branch. Distinguish a new subtype from reopening an
  existing type path. Inspect explicit `parent_type` declarations where present,
  signatures, arguments, return values, and the include order of proc bodies
  before reasoning about `..()`.
- Concrete example: core [/obj/item/Initialize(mapload)](../code/game/objects/items.dm)
  also has a later declaration in [RMH tweaks](../modular_rmh/code/tweaks.dm).
  The RMH body calls `. = ..()` and then `apply_item_scaling()`. A modular file
  can therefore affect the shared item family; it is not an isolated type.
- A narrower example is [adventurer_fighter.dm](../modular_rmh/code/modules/jobs/job_types/adventurers/adventurer_fighter.dm),
  which declares `/datum/job/adventurer_fighter` and its `after_spawn` override.
  Compare it with the `/datum/job` contract in [the core job definition](../code/modules/jobs/job_types/_job.dm)
  rather than copying another fork's job signature.
- Lifecycle setup is driven by [SSatoms](../code/controllers/subsystem/atoms.dm)
  and the core [/atom initialization contract](../code/game/atom/atoms.dm).
  Apply the universal DM skill's lifecycle rules to these local definitions;
  do not convert unrelated construction code while adding content.
- The local [processing subsystem](../code/controllers/subsystem/processing/_processing.dm)
  calls `thing.process(wait * 0.1)` and declares `/datum/proc/process(delta_time)`.
  That argument is the configured interval in seconds, not a measurement of
  elapsed wall time. The base proc returns `PROCESS_KILL`; a processing override
  must not add a parent call mechanically. Check the actual caller for other
  processing families.

- Main's [base Destroy](../code/datums/datum.dm) is marked SHOULD_CALL_PARENT(TRUE).
  It clears tag/weakref state, active timers, components, and signal references,
  then returns QDEL_HINT_QUEUE. Follow the actual child/parent cleanup contract;
  qdel is not a promise that every external reference immediately became null.
- [DCS helpers](../code/__DEFINES/dcs/helpers.dm) dispatch SEND_GLOBAL_SIGNAL on
  SSdcs. This differs from the imported guide's GLOB registration advice.

## Modular placement

Use [modular_guide.md](modular_guide.md) for the detailed directory map and
placement rules. The current main branches are:

| Location | Role |
|---|---|
| [modular_rmh/code/modules/](../modular_rmh/code/modules/) | Feature-specific jobs, spells, clothing, mobs, and other extensions |
| [modular_rmh/code/datums/](../modular_rmh/code/datums/) | RMH datums, components, status effects, religion, and supporting state |
| [modular_rmh/modular/](../modular_rmh/modular/) | Self-contained feature packs |
| [modular_rmh/dndmagic/](../modular_rmh/dndmagic/) | A separate, explicitly included DM directory |
| [modular_rmh/code/tweaks.dm](../modular_rmh/code/tweaks.dm) | Existing targeted overrides, including shared-type behavior |

Main already declares SScontracts in
[contract_subsystem.dm](../modular_rmh/code/modules/antagonists/contracts/contract_subsystem.dm)
and SSrecipe_books in [recipe_book_db.dm](../modular_rmh/code/modules/crafting/recipe_book_db.dm).
These share the core scheduler but are not declared in the core controller directory.

Prefer the narrowest existing host and extension point that fits the task.
Location is not a risk classification: common roots and frequent hooks have a
wide effect even when declared in RMH. The modular guide requires approval for
new RMH subsystems and discourages dependencies between standalone packs;
apply it together with [human_checking.md](human_checking.md) and the user's
existing authorization. Use `tgstation-modular-content` for new placement
decisions and `byond-ss13-coding` for implementation, without copying their
general rules into this profile.

## Formatting and diagnostics configuration

- [.editorconfig](../.editorconfig) specifies tabs and CRLF for DM, plus final
  newlines and removal of trailing whitespace. Preserve unrelated formatting.
- [SpacemanDMM.toml](../SpacemanDMM.toml) targets `vanderlin.dme`, enables
  DreamChecker in the language server, and disallows relative type and proc
  definitions. Its `redefined_proc` diagnostic is off: absence of that diagnostic
  does not prove a type branch has only one implementation.
- Security, lifecycle, signal, and performance guidance belongs to the universal
  skills, applied to real local definitions. Navigation summaries are not a
  substitute for inspecting those definitions.

## Build and verification

Sources: [BUILD.cmd](../BUILD.cmd), [build.bat](../tools/build/build.bat),
[build.ts](../tools/build/build.ts), and [dependencies.sh](../dependencies.sh).

- `BUILD.cmd` invokes the repository build wrapper. For an agent shell, run
  `.\tools\build\build.bat build` from the repository root. The wrapper runs build.ts; BuildTarget depends on TguiTarget and DmTarget.
  Main's local DmTarget also waits for TGUI (except its CI mode), tracks the packed
  TGUI bundles, and removes an outdated RSC before DreamMaker so those assets
  are repacked. This is source behavior, not a successfully executed build.
- `DmTarget` invokes DreamMaker for `vanderlin.dme`. Dependency pins currently
  include BYOND **516.1687**, rust-g **3.9.0**, Bun **1.3.5**, and SpacemanDMM
  **suite-1.11**. Read the live dependency file before a toolchain change;
  these pins do not attest to the locally installed versions.
- **Incremental-build limitation:** `DmTarget.inputs` includes RMH `code`,
  `icons`, `sound`, and `modular` paths, but does not separately cover
  `modular_rmh/dndmagic/**`. After changes there, verify that DreamMaker really
  ran; an `up to date` skip is not evidence that those changes compiled. Use a
  supported forced rebuild when necessary after inspecting the build tooling.
  Other late include roots (modular_alizeria and modular_ratwood) also have no explicit input glob in this target. This profile records the source-level gaps; no incremental rebuild experiment or build-script change was made.
- The build file also defines test/server targets that start DreamDaemon.
  A normal build does not require starting a world. Runtime verification needs
  the authorization described by the universal skill and the current task.

After DM source or `.dme` edits, [AGENTS.md](../AGENTS.md) requires **both** the
repository BYOND build and the diagnostic check:

```powershell
python tools/dm_diagnostics.py
```

Use `--json` for full diagnostic objects and related locations. As documented in
[dm_diagnostics.md](../tools/dm_diagnostics.md), this reads saved files through
the installed language server with this checkout's DreamChecker configuration.
Exit codes are **0** for no errors (warnings/hints may remain), **1** for errors,
and **2** for a failed check or timeout. Retrieve diagnostics directly, fix new
errors introduced by the task, and report failures honestly. Documentation-only
changes do not trigger the DM-edit requirement.

## Refresh boundary

Recheck this profile when the project name, include structure, extension roots,
processing contracts, build targets, dependency pins, or diagnostic tooling
change. Use [update_policy.md](update_policy.md) for a navigation refresh.
Keep fork facts here and universal invariants in the installed universal skills.
Do not treat this inspection as validation of the whole navigation base.
