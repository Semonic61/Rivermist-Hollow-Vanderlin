# Modular RMH Guide

Placement and source-path validation: 2026-11-16 against main. No content-pack runtime testing ran.

`modular_rmh/` is the dominant late-included overlay layer. It extends the core codebase without replacing it.

## What "Late-Included" Means

`modular_rmh` is included near the end of `vanderlin.dme`, after a small late cluster from `modular_alizeria` and `modular_ratwood`. This means:

- it can subtype any core type and override procs
- it can add new subtypes to existing branches
- directory placement does not authorize changing the build graph; follow the include sorter required by root AGENTS.md
- Master and the scheduler are shared; RMH can also declare SS globals. Main already has SScontracts and SSrecipe_books in RMH (see subsystem_map.md).

**Rule for agents:** find the core type first in `code/`, then check `modular_rmh` for descendants or behavior overrides on the same branch.

In practice, `modular_rmh` is still the main late extension layer you should check after `code/`; the small pre-RMH modular slices do not change that navigation rule.

## Directory Map

| Path | What lives here |
|---|---|
| `modular_rmh/code/modules/jobs/**` | RMH-specific jobs, roles, subclasses |
| `modular_rmh/code/modules/clothing/**` | Clothing, wearables, appearance extensions |
| `modular_rmh/code/modules/spells/**` | RMH spells and abilities |
| `modular_rmh/code/modules/mob/**` | Mob subtypes, AI overlays, mob behavior extensions |
| `modular_rmh/code/modules/mapping/**` | RMH map templates and worldgen hooks |
| `modular_rmh/code/modules/farming/**` | Farming content extensions |
| `modular_rmh/code/modules/food/**` | Food and consumable content |
| `modular_rmh/code/modules/homestead/**` | Homestead/settlement content |
| `modular_rmh/code/modules/reagents/**` | Reagent extensions |
| `modular_rmh/code/modules/surgery/**` | Surgery extensions |
| `modular_rmh/code/modules/artifacts/**` | Artifact content |
| `modular_rmh/code/modules/client/**` | Client-side overlays and verbs |
| `modular_rmh/code/datums/ai/**` | AI controller extensions, horny-AI overlays |
| `modular_rmh/code/datums/components/**` | RMH-specific components |
| `modular_rmh/code/datums/status_effects/**` | RMH status effect subtypes |
| `modular_rmh/code/datums/religion/**` | Religion, faith, god datums |
| `modular_rmh/code/datums/stress/**` | Stress system datums |
| `modular_rmh/code/datums/sexcon/**` | Sex/ERP datums |
| `modular_rmh/code/datums/character_flaw.dm` | Character flaw datum |
| `modular_rmh/code/datums/combat_music.dm` | Combat music datum |
| `modular_rmh/code/datums/reflection.dm` | Reflection datum |
| `modular_rmh/code/tweaks.dm` | Small targeted overrides and patches |
| `modular_rmh/modular/fluids/**` | Fluid system self-contained pack |
| `modular_rmh/modular/ceramics/**` | Ceramics content pack |
| `modular_rmh/modular/comfy/**` | Comfort/cozy content pack |
| `modular_rmh/modular/piercing/**` | Piercing content pack |
| `modular_rmh/modular/loot/**` | Loot tables and drop content |
| `modular_rmh/modular/bush/**` | Character/body-hair customization |
| `modular_rmh/modular/resurrection_rune/**` | Resurrection rune mechanic |
| `modular_rmh/modular/selectable_moanpacks/**` | Selectable moan/sound packs |
| `modular_rmh/modular/helpers/**` | Shared helpers for modular packs |

## Where New RMH Code Belongs

| Adding... | Put it in |
|---|---|
| New job or role subclass | `modular_rmh/code/modules/jobs/` |
| New spell or ability | `modular_rmh/code/modules/spells/` |
| New mob subtype or behavior | `modular_rmh/code/modules/mob/` |
| New clothing or wearable | `modular_rmh/code/modules/clothing/` |
| New status effect | `modular_rmh/code/datums/status_effects/` |
| New component (RMH-only) | `modular_rmh/code/datums/components/` |
| New religion/faith content | `modular_rmh/code/datums/religion/` |
| Self-contained mechanic pack | `modular_rmh/modular/<pack_name>/` |
| Small targeted core patch | `modular_rmh/code/tweaks.dm` |

## Key Rules

- **Never duplicate a core type.** Subtype or override it.
- **Never add a new `SS*` subsystem in RMH** unless explicitly approved — subsystems are owned by core.
- **Clothing and appearance changes are the hottest overlay path** in RMH. Per-equip or per-tick `overlays +=` across many player mobs causes network floods. See `ai_navigation/visuals_guide.md` and `ai_navigation/performance_gotchas.md` §7.
- **After any RMH edit, verify the core branch still behaves correctly** — inspect all same-path proc bodies and include order rather than assuming a modular file is an isolated replacement.
- Self-contained packs in `modular_rmh/modular/` should not depend on each other.

## Navigation Rule

When any task touches a system that has both core and RMH code:

1. Find and read the core path first.
2. Then check `modular_rmh` for the same type branch.
3. If RMH extends it, the RMH file is the effective runtime behavior.

Main registration: direct project includes, including dndmagic. The main build also handles TGUI/RSC repacking; see rivermist_hollow_profile.md.
