# System Map

Last validated 2026-11-16 against main: directory routes, subsystem owners, and the source-backed corrections below. See MAIN_PORT_STATUS.md for semantic limits.

## Repository Hotspots

Source: direct .dm includes in vanderlin.dme; regenerate with python -B ai_navigation/validate_navigation.py --inventory.

- `code/modules/`: `mob` (346), `spells` (200), `crafting` (183), `client` (178), `antagonists` (110), `clothing` (96), `mapping` (90), `admin` (83).
- `code/datums/`: `ai` (221), `components` (192), `sex` (125), `rts` (87), `armor` (51), `runeword` (43), `chimeric_organs` (42), `elements` (36).
- `modular_rmh/code/modules/`: `jobs` (161), `clothing` (56), `mob` (55), `antagonists` (45), `spells` (44), `client` (10), `surgery` (9), `food` (7).
- `modular_rmh/code/datums/`: `religion` (6), `ai` (5), `quirks` (5), `components` (4), `status_effects` (3), `stress` (2), `modular_rmh/code/datums/armor.dm` (1), `modular_rmh/code/datums/character_flaw.dm` (1).

The full type_tree.md remains the dated imported search aid. It was not regenerated or certified as a main inheritance model. Use type_index.md and actual parent_type/proc definitions. Old branch-size estimates were removed rather than relabeled as measured main data.

## Major Systems

### Master Controller and Round Flow

- Main type root(s): `/datum/controller/subsystem`
- Primary directories: `code/world.dm`, `code/controllers/**`
- Main controllers/subsystems: `Master`, `SSticker`, `SSatoms`, `SStimer`
- Notes: `/world` boots the game; `Master` discovers subsystem subtypes, sorts by `init_order`, and drives runlevels/tick budgets.

### DCS Components and Elements

- Main type root(s): `/datum/component`, `/datum/element`
- Primary directories: `code/datums/components/**`, `code/datums/elements/**`, `code/__DEFINES/dcs/**`, `code/__DEFINES/components.dm`
- Main controllers/subsystems: `SSdcs`
- Notes: Main composition/event system. Use signal_map.md for regenerated lexical counts; item/combat hooks also live in code/__DEFINES/components.dm.

### Antagonists and Hostile Role Systems

- Main type root(s): `/datum/antagonist`
- Primary directories: `code/modules/antagonists/**`, `code/modules/events/antagonist/**`, `code/datums/migrants/waves/antagonist/**`
- Main controllers/subsystems: `SSgamemode`, `SSevents`
- Notes: Direct antagonist datums coexist with storyteller-driven antagonist events and antag migrant waves.

### Storytellers, Round Events, and Omen Tracks

- Main type root(s): `/datum/storyteller`, `/datum/round_event_control`, `/datum/round_event`, `/datum/event_group`
- Primary directories: `code/datums/storytellers/**`, `code/datums/event_groups/**`, `code/modules/events/**`
- Main controllers/subsystems: `SSgamemode`, `SSevents`, `SSticker`
- Notes: Storytellers buy/select `round_event_control` instances; event groups provide cooldown/track grouping; antagonist events bridge directly into role systems.

### Status Effects, Actions, and Spell Trees

- Main type root(s): `/datum/status_effect`, `/datum/action`
- Primary directories: `code/datums/status_effects/**`, `code/modules/spells/**`, `modular_rmh/code/modules/spells/**`, `modular_rmh/code/datums/status_effects/**`
- Main controllers/subsystems: `SSstatusprocess`, `SSmagic`, `SSskills`
- Notes: Status effects are used across combat, spells, liquids, quirks, wounds, and modular packs.

### AI Controllers and Behavior Trees

- Main type root(s): `/datum/ai_controller`, `/datum/ai_behavior`
- Primary directories: `code/datums/ai/**`, `modular_rmh/code/datums/ai/**`, `modular_rmh/code/modules/mob/**`
- Main controllers/subsystems: `SSai_controllers`, `SSai_idle_controllers`, `SSai_behaviors`, `SSai_movement`, `SSidle_ai_behaviors`, `SSbasic_avoidance`, `SSaggro`
- Notes: AI is split into controllers, behaviors, planning subtrees, movement datums, and dedicated processing loops.

### Mobs, Jobs, Migrants, and Character Lifecycle

- Main type root(s): `/mob`, `/datum/migrant_wave`, `/datum/migrant_role`
- Primary directories: `code/modules/mob/**`, `code/modules/jobs/**`, `code/datums/migrants/**`, `modular_rmh/code/modules/jobs/**`, `modular_rmh/code/modules/mob/**`
- Main controllers/subsystems: `SSjob`, `SSmobs`, `SSmigrants`, `SSrole_class_handler`
- Notes: Core player/NPC logic lives in `mob/`; jobs and migrant waves define spawn-time role structure; RMH adds a large parallel job layer.

### RTS / Strategy Layer

- Main type root(s): `/datum/work_order`, `/datum/building_datum`
- Primary directories: `code/datums/rts/**`
- Main controllers/subsystems: `SSstrategy_master`
- Notes: Standalone strategy subsystem with work orders, building datums, worker minds, templates, and controller UI.

### Economy, Property, Merchants, and World Factions

- Main type root(s): `/datum/nation`, `/datum/world_faction`
- Primary directories: `code/modules/economy/**`, `code/controllers/subsystem/economy.dm`, `code/controllers/subsystem/treasury.dm`, `code/controllers/subsystem/property_management.dm`, `code/datums/world_factions/**`
- Main controllers/subsystems: `SSeconomy`, `SStreasury`, `SShousing`, `SSmerchant`
- Notes: Money/accounting, estate income, housing, trader flows, and factional world state are split across controllers and datums.

### Questing, Contracts, and Objective Tracking

- Main type root(s): `/datum/quest`, `/obj/item/paper/scroll/quest`, `/obj/item/quest_compass`, `/obj/structure/fake_machine/contractledger`
- Primary directories: `code/modules/questing/**`, `tgui/packages/tgui/interfaces/ContractLedger.tsx`, `tgui/packages/tgui/interfaces/ContractLedgerRu.tsx`, `tgui/packages/tgui/interfaces/ContractLedgerView.tsx`, `tgui/packages/tgui/interfaces/ContractLedger.i18n.en.ts`, `tgui/packages/tgui/interfaces/ContractLedger.i18n.ru.ts`, `modular_rmh/code/modules/client/preferred_language.dm`, `code/__DEFINES/quests.dm`, `code/modules/antagonists/villain/harlequinn/bounty.dm`
- Main controllers/subsystems: `SSprocessing`, `SStreasury`, `SSmapping`
- Notes: Contracts are issued and turned in through the ledger, objectives live on `/datum/quest` subtypes, the scroll is the player-facing contract record, and the compass is the live tracking surface. The ledger now opens separate EN/RU TGUI interfaces selected from `client.preferred_ui_language`, which is changed through the modular OOC verb in `modular_rmh/code/modules/client/preferred_language.dm`. Merchant/guild job gating lives in the modular RMH jobs branch.

### Crafting, Materials, Runewords, Farming, Fishing

- Main type root(s): `/datum/material`, `/datum/runeword`
- Primary directories: `code/modules/crafting/**`, `code/datums/materials/**`, `code/datums/quality/**`, `code/datums/runeword/**`, `code/modules/farming/**`, `code/modules/fishing/**`
- Main controllers/subsystems: `SSskills`, `SSfishing`, `SSanvil`, `SSenchantment`
- Notes: Progression logic concentrates in crafting/material datums plus module-sliced recipes and minigames.

### Skills, Dreams, and Experience

- Main type root(s): `/datum/attribute/skill` (legacy `/datum/skill` aliases still resolve)
- Primary directories: `code/datums/attributes/attributes/skills/**`, `code/datums/attributes/__holder.dm`, `code/datums/attributes/__legacy.dm`
- Main controllers/subsystems: `SSskills`
- Notes: Skills are attribute-backed progression datums with XP thresholds, dream unlock costs, and level-gated effects. Mobs store them through `mob.attributes` (`/datum/attribute_holder`), while legacy `/datum/skill` paths and rank helpers remain as compatibility shims. Job skill grants are in `modular_rmh/code/modules/jobs/**`. No per-tick processing — XP changes are event-driven via signal hooks.

### Questing and Contracts

- Main type root(s): `/datum/quest`, `/datum/component/quest_object`
- Primary directories: `code/modules/questing/**`
- Main controllers/subsystems: `SSquestboard` (shared pools), quest target components
- Notes: Quests are `/datum/quest` instances issued via the contract ledger (`/obj/structure/fake_machine/contractledger`). Quest targets get a `quest_object` component attached which hooks `COMSIG_MOB_DEATH` and examine signals. Main uses SSquestboard for generation, pruning and refill; target components handle reactions.

### Combat Intents and Clash System

- Main type root(s): `/datum/special_intent`
- Primary directories: `code/modules/combat/**`
- Main controllers/subsystems: `SSdcs`, combat chain (`code/_onclick/item_attack.dm`)
- Notes: `special_intent` provides AOE weapon abilities with tile coordinate patterns, pre/post sounds, and stamina costs. The clash system (`process_clash`) lives on `/mob/living` and resolves guard/riposte/disarm outcomes. Integrates into the standard hit chain — see `ai_navigation/combat_signal_map.md` for signal hooks.

### Culture and Character Background

- Main type root(s): `/datum/culture`
- Primary directories: `code/datums/culture/**`
- Main controllers/subsystems: none — loaded at spawn via `job/after_spawn()`
- Notes: Cultural background is a character-pref datum that contributes examine strings and spawn-time effects. Species-gated cultures check `pref_species` at selection. No runtime processing after spawn.

### Cooking and Food

- Main type root(s): `/obj/item/reagent_containers/food`
- Primary directories: `code/modules/cooking/**`, `code/modules/food_and_drinks/**`, `code/datums/brewing_recipes/**`
- Main controllers/subsystems: `SSskills`, `SSanvil` (slapcrafting chain)
- Notes: Cooking uses slapcrafting rather than menu-based recipes. Raw food base (`foodbase`) applies a debuff status effect when eaten uncooked. Teas and brews are in `code/modules/cooking/Teas_and_Brews.dm`. Reagent interactions route through `code/modules/reagents/**`.

### Rage System

- Main type root(s): `/datum/rage`
- Primary directories: `code/datums/rage/**`
- Main controllers/subsystems: `SSdcs` (signal-driven via `COMSIG_HUMAN_LIFE`; no dedicated SS*)
- Notes: Rage is a holder datum attached to a mob via `grant_to_holder()`. Ticks on `COMSIG_HUMAN_LIFE`, sends `COMSIG_RAGE_CHANGED`, `COMSIG_RAGE_BOTTOMED`, `COMSIG_RAGE_OVERRAGE`. Supports threshold-based ability tiers. HUD uses a bloodpool element. Werewolf antag is the primary real user — see `code/datums/rage/werewolf_rage.dm`.

### Faith, Gods, Mana, Quirks, Wounds

- Main type root(s): `/datum/faith`, `/datum/mana`, `/datum/quirk`, `/datum/wound`
- Primary directories: `code/datums/faith/**`, `code/datums/gods/**`, `code/datums/mana/**`, `code/datums/quirks/**`, `code/datums/wounds/**`
- Main controllers/subsystems: `SSskills`, `SSstatusprocess`, `SSmood`
- Notes: Character state is distributed across faith/devotion, mana, quirks, wounds, stress, rage, and organ systems.

### Mapping, Dungeons, Voyage, and Procedural Generation

- Main type root(s): `/datum/map_template`
- Primary directories: `_maps/**`, `code/modules/mapping/**`, `code/modules/procedural_mapping/**`, `modular_rmh/code/game/modules/mapgen/**`
- Main controllers/subsystems: `SSmapping`, `SSpocket_dimensions`, `SSminor_mapping`, `SSdungeon_generator`, `SSterrain_generation`, `SSpathfinder`
- Notes: Static DMM templates, procedural mapgen, dungeon placement, pocket-dimension reservations, and voyage terrain generation coexist.

### Pocket Dimensions and Spatial Reservations

- Main type root(s): `/datum/map_template/pocket`, `/datum/pocket_dimension`
- Primary directories: `code/modules/mapping/pocket_dimensions/**`, `code/controllers/subsystem/pocket_dimensions.dm`, `code/controllers/subsystem/mapping.dm`, `code/modules/admin/verbs/pocket_dimensions.dm`
- Main controllers/subsystems: `SSpocket_dimensions`, `SSmapping`, `SSlighting`
- Notes: `SSpocket_dimensions` rebuilds pocket template caches from `SSmapping.map_templates`, manages instance creation/wake/hibernate/collapse lifecycle, and relies on `SSmapping.RequestPocketBlockReservation(...)` plus lighting refreshes during activation. Admin debugging tools live under `code/modules/admin/verbs/pocket_dimensions.dm`.

### World Simulation: Liquids, Weather, Fire, Overlays

- Main type root(s): `/datum/liquid`, `/datum/weather_effect`
- Primary directories: `code/datums/liquids/**`, `code/datums/particle_weathers/**`, `code/controllers/subsystem/liquids.dm`, `code/controllers/subsystem/particle_weather*.dm`
- Main controllers/subsystems: `SSliquids`, `SSParticleWeather`, `SSoutdoor_effects`, `SSfire_burning`, `SSfire_spread`, `SSlighting`, `SSvis_overlays`
- Notes: High-frequency simulation cluster for environmental state and visual side effects.

### UI and Frontend Stack

- Main type root(s): `/datum/ui`, `/datum/tgui`
- Primary directories: `code/modules/tgui/**`, `code/modules/visual_ui/**`, `interface/**`, `tgui/packages/**`, `html/**`
- Main controllers/subsystems: `SStgui`, `SSvisual_ui`, `SSchat`
- Notes: DM-side browser UIs coexist with TypeScript `tgui` packages and custom BYOND interface verbs/menus.

### RMH Modular Extension Layer

- Main type root(s): multiple existing roots extended late in the include graph
- Primary directories: `modular_rmh/code/**`, `modular_rmh/modular/**`
- Main controllers/subsystems: uses the common scheduler; also declares SScontracts and SSrecipe_books in RMH
- Notes: Loaded late in the modular include cluster in `vanderlin.dme`, with small `modular_alizeria` and `modular_ratwood` slices landing immediately before RMH. Treat RMH as the dominant overlay layer rather than a separate architecture.

## Main-Specific Owners

- SSquestboard: code/controllers/subsystem/questboard.dm manages posting generation and pruning.
- SScontracts: modular_rmh/code/modules/antagonists/contracts/contract_subsystem.dm manages antagonist contract parties.
- SSrecipe_books: modular_rmh/code/modules/crafting/recipe_book_db.dm initializes the shared recipe database asset.
- SSlooting: code/modules/lootpanel/ss_looting.dm processes loot-panel image queues.
- SSrelations, SSrelics, SSprofiler, SStrackables, SSmeatvines, SSfake_world: see subsystem_map.md for declarations.

## High-Level Dependency Awareness

Use the regenerated subsystem and signal inventories, not the imported counts.
SEND_GLOBAL_SIGNAL uses SSdcs. Component callbacks and feature procs are not
automatically scheduled by SSdcs. RMH reuses the scheduler but can declare its
own subsystems; modular location alone does not imply local effect scope.
