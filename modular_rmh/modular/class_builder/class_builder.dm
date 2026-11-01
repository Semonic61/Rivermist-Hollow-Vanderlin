// Class builder: player-made subclasses for every role that has subclasses.
// Mechanics follow Twilight Axis' TAT editor (point buy for stats, skill pools, directions with talent tiers,
// flaws that pay direction points, item budget), the editor layout follows Baldur's Gate 3 character creation.
// Builds are stored per character slot inside the server-side character savefile, loaded together with
// the character (like the Character Creator data) and only ever sent to their owner through the editor UI.
// Each role keeps one active build: the one its custom subclass spawns with.

#define CB_SAVE_KEY "class_builder_builds"
#define CB_SAVE_VERSION 1
#define CB_MAX_BUILDS 9
#define CB_NAME_MAX 32
#define CB_IMPORT_MAX 20000
#define CB_MAX_CARRIED 30
#define CB_MAX_MAP_KEYS 200

#define CB_STAT_BASE 10
#define CB_STAT_FLOOR 8
#define CB_SKILL_MAX_RANK 6
#define CB_DIRECTION_MAX 8

#define CB_POOL_COMBAT "combat"
#define CB_POOL_PEACEFUL "peaceful"
#define CB_POOL_ADVENTURE "adventure"

#define CB_KIND_BACKGROUND "background"
#define CB_KIND_STAT "stat"
#define CB_KIND_SKILL "skill"
#define CB_KIND_DIRECTION "direction"
#define CB_KIND_TALENT "talent"
#define CB_KIND_FLAW "flaw"
#define CB_KIND_ITEM "item"

#define CB_ZONE_BAG "bag"
#define CB_ZONE_STASH "stash"

GLOBAL_DATUM_INIT(class_builder, /datum/class_builder_registry, new)
GLOBAL_LIST_EMPTY(class_builder_editors)
/// Paper doll slots, named after /datum/outfit vars. Order matches the 3-column doll grid.
GLOBAL_LIST_INIT(class_builder_slots, list(
	"mask", "head", "mouth",
	"backr", "cloak", "backl",
	"neck", "armor", "wrists",
	"ring", "shirt", "gloves",
	"beltr", "belt", "beltl",
	"r_hand", "pants", "l_hand",
	"shoes",
))

// ---------------------------------------------------------------------------------------------
// Registry
// ---------------------------------------------------------------------------------------------

/datum/class_builder_registry
	var/built = FALSE
	/// id -> entry
	var/list/entries = list()
	/// kind -> sorted list of entries
	var/list/by_kind = list()
	/// Cached ui_static_data payload, identical for every player.
	var/list/static_payload

/datum/class_builder_registry/proc/ensure_built()
	if(built)
		return
	built = TRUE
	for(var/datum/class_builder_entry/entry_type as anything in subtypesof(/datum/class_builder_entry))
		if(IS_ABSTRACT(entry_type))
			continue
		register(new entry_type())
	register_skills()
	register_items()
	for(var/kind in by_kind)
		sortTim(by_kind[kind], GLOBAL_PROC_REF(cmp_class_builder_entry))

/datum/class_builder_registry/proc/register(datum/class_builder_entry/entry)
	if(!entry.id || !entry.kind)
		stack_trace("Class builder entry [entry.type] has no id or kind.")
		qdel(entry)
		return FALSE
	if(entries[entry.id])
		stack_trace("Class builder entry id '[entry.id]' is duplicated by [entry.type].")
		qdel(entry)
		return FALSE
	entries[entry.id] = entry
	if(!by_kind[entry.kind])
		by_kind[entry.kind] = list()
	by_kind[entry.kind] += entry
	return TRUE

/datum/class_builder_registry/proc/register_skills()
	for(var/branch in GLOB.class_builder_skill_branches)
		var/pool = GLOB.class_builder_skill_branches[branch]
		for(var/skill_type in subtypesof(branch))
			var/cap = GLOB.class_builder_skill_caps[skill_type]
			if(isnull(cap))
				cap = GLOB.class_builder_pool_caps[pool]
			if(!cap)
				continue
			register(new /datum/class_builder_entry/skill(skill_type, pool, cap))

/datum/class_builder_registry/proc/register_items()
	for(var/list/row as anything in GLOB.class_builder_items)
		if(!islist(row) || !ispath(row["path"], /obj/item))
			stack_trace("Class builder item row is malformed: [json_encode(row)]")
			continue
		register(new /datum/class_builder_entry/item(row))

/datum/class_builder_registry/proc/get_entry(id, kind)
	ensure_built()
	if(!istext(id))
		return null
	var/datum/class_builder_entry/entry = entries[id]
	if(!entry || (kind && entry.kind != kind))
		return null
	return entry

/datum/class_builder_registry/proc/get_kind(kind)
	ensure_built()
	return by_kind[kind] || list()

/datum/class_builder_registry/proc/get_roles()
	. = list()
	for(var/datum/job/advclass/custom_class/role_type as anything in subtypesof(/datum/job/advclass/custom_class))
		if(IS_ABSTRACT(role_type))
			continue
		var/datum/job/advclass/custom_class/role = SSjob.GetJobType(role_type)
		if(role)
			. += role

/datum/class_builder_registry/proc/get_static_payload()
	if(static_payload)
		return static_payload
	ensure_built()
	var/list/payload = list()
	for(var/kind in list(CB_KIND_BACKGROUND, CB_KIND_STAT, CB_KIND_SKILL, CB_KIND_DIRECTION, CB_KIND_TALENT, CB_KIND_FLAW, CB_KIND_ITEM))
		var/list/kind_payload = list()
		for(var/datum/class_builder_entry/entry as anything in get_kind(kind))
			kind_payload += list(entry.ui_payload())
		payload["[kind]s"] = kind_payload
	var/list/roles = list()
	for(var/datum/job/advclass/custom_class/role as anything in get_roles())
		roles += list(role.class_builder_payload())
	payload["roles"] = roles
	var/list/slots = list()
	for(var/slot in GLOB.class_builder_slots)
		slots += slot
	payload["doll_slots"] = slots
	payload["limits"] = list(
		"stat_base" = CB_STAT_BASE,
		"stat_floor" = CB_STAT_FLOOR,
		"skill_max_rank" = CB_SKILL_MAX_RANK,
		"max_builds" = CB_MAX_BUILDS,
		"name_max" = CB_NAME_MAX,
		"import_max" = CB_IMPORT_MAX,
		"max_carried" = CB_MAX_CARRIED,
	)
	static_payload = payload
	return static_payload

/proc/cmp_class_builder_entry(datum/class_builder_entry/a, datum/class_builder_entry/b)
	if(a.sort_order != b.sort_order)
		return a.sort_order - b.sort_order
	return sorttext(b.name, a.name)

// ---------------------------------------------------------------------------------------------
// Entries
// ---------------------------------------------------------------------------------------------

/datum/class_builder_entry
	abstract_type = /datum/class_builder_entry
	/// Stable save key. Never rename once players have builds using it.
	var/id
	var/kind
	var/name = "Unnamed"
	var/name_ru
	var/desc = ""
	var/desc_ru
	var/icon
	var/icon_state
	var/sort_order = 100
	/// Custom class types allowed to pick this entry. Null means every role.
	var/list/allowed_roles
	/// Ids of entries (any kind) that cannot be taken together with this one.
	var/list/excludes

/datum/class_builder_entry/proc/ui_payload()
	var/list/payload = list(
		"id" = id,
		"name" = name,
		"name_ru" = name_ru,
		"desc" = desc,
		"desc_ru" = desc_ru,
	)
	if(icon && icon_state)
		payload["icon"] = "[icon]"
		payload["icon_state"] = "[icon_state]"
	if(length(allowed_roles))
		var/list/role_paths = list()
		for(var/role_type in allowed_roles)
			role_paths += "[role_type]"
		payload["roles"] = role_paths
	if(length(excludes))
		payload["excludes"] = excludes.Copy()
	return payload

/// Null when the entry can be taken, otherwise list("code" = reason, "value" = detail) for the UI.
/datum/class_builder_entry/proc/get_block(datum/class_builder_build/build, list/state)
	if(length(allowed_roles) && !(build.role_type in allowed_roles))
		return list("code" = "role")
	for(var/excluded_id in excludes)
		if(build.has_entry(excluded_id))
			var/datum/class_builder_entry/other = GLOB.class_builder.get_entry(excluded_id)
			return list("code" = "excludes", "value" = other?.name || excluded_id)
	return null

/datum/class_builder_entry/proc/on_apply(mob/living/carbon/human/target, datum/class_builder_build/build)
	return

/datum/class_builder_entry/proc/grant_traits(mob/living/carbon/human/target, list/traits)
	for(var/trait in traits)
		ADD_TRAIT(target, trait, JOB_TRAIT)

/datum/class_builder_entry/proc/grant_spells(mob/living/carbon/human/target, list/spells, datum/source)
	for(var/spell_type in spells)
		target.add_spell(spell_type, source = source)

/datum/class_builder_entry/proc/trait_payload(list/traits)
	. = list()
	for(var/trait in traits)
		. += list(list("name" = "[trait]", "desc" = GLOB.roguetraits[trait]))

/datum/class_builder_entry/proc/skill_payload(list/skills)
	. = list()
	for(var/datum/attribute/skill/skill_type as anything in skills)
		. += list(list("name" = initial(skill_type.name), "rank" = skills[skill_type]))

/datum/class_builder_entry/stat
	abstract_type = /datum/class_builder_entry/stat
	kind = CB_KIND_STAT
	var/attribute_type
	var/cost = 1
	var/max_value = 13

/datum/class_builder_entry/stat/ui_payload()
	. = ..()
	.["cost"] = cost
	.["max"] = max_value

/datum/class_builder_entry/skill
	abstract_type = /datum/class_builder_entry/skill
	kind = CB_KIND_SKILL
	var/skill_type
	var/pool
	var/cap = 2
	var/cost = 1

/datum/class_builder_entry/skill/New(skill_type, pool, cap)
	. = ..()
	var/datum/attribute/skill/skill_path = skill_type
	src.skill_type = skill_type
	src.pool = pool
	src.cap = cap
	id = "skill:[replacetext("[skill_type]", "/datum/attribute/skill/", "")]"
	name = initial(skill_path.name) || id
	desc = initial(skill_path.desc)

/datum/class_builder_entry/skill/ui_payload()
	. = ..()
	.["pool"] = pool
	.["cap"] = cap
	.["cost"] = cost

/datum/class_builder_entry/direction
	abstract_type = /datum/class_builder_entry/direction
	kind = CB_KIND_DIRECTION
	var/color = "#c9a25f"
	var/max_level = CB_DIRECTION_MAX
	/// skill type -> ranks granted per invested level (fractions floor), e.g. Magic opens arcane skill.
	var/list/skill_per_level

/datum/class_builder_entry/direction/ui_payload()
	. = ..()
	.["color"] = color
	.["max"] = max_level

/datum/class_builder_entry/background
	abstract_type = /datum/class_builder_entry/background
	kind = CB_KIND_BACKGROUND
	/// skill type -> free ranks, on top of purchased ones.
	var/list/skills
	/// direction id -> free levels. Counts as level and talent points in that direction, not against the budget.
	var/list/direction_bonus
	var/list/traits
	var/list/languages

/datum/class_builder_entry/background/ui_payload()
	. = ..()
	.["skills"] = skill_payload(skills)
	.["directions"] = direction_bonus ? direction_bonus.Copy() : list()
	.["traits"] = trait_payload(traits)
	var/list/language_names = list()
	for(var/datum/language/language_type as anything in languages)
		language_names += initial(language_type.name)
	.["languages"] = language_names

/datum/class_builder_entry/background/on_apply(mob/living/carbon/human/target, datum/class_builder_build/build)
	grant_traits(target, traits)
	for(var/language_type in languages)
		if(!target.has_language(language_type))
			target.grant_language(language_type)

/datum/class_builder_entry/talent
	abstract_type = /datum/class_builder_entry/talent
	kind = CB_KIND_TALENT
	/// Direction id this talent belongs to; its level gates the tier and its points pay the cost.
	var/direction
	var/tier = 1
	var/cost = 1
	/// Shown on the Spells step instead of Talents.
	var/is_spell = FALSE
	var/list/traits
	var/list/spells
	/// skill type -> free ranks
	var/list/skills
	/// Patron types; empty means any patron.
	var/list/allowed_patrons
	/// Talent ids that must be taken first.
	var/list/requires

/datum/class_builder_entry/talent/ui_payload()
	. = ..()
	.["direction"] = direction
	.["tier"] = tier
	.["cost"] = cost
	.["is_spell"] = is_spell
	.["traits"] = trait_payload(traits)
	.["skills"] = skill_payload(skills)
	var/list/spell_names = list()
	for(var/datum/action/cooldown/spell/spell_type as anything in spells)
		spell_names += initial(spell_type.name)
	.["spells"] = spell_names
	var/list/patron_names = list()
	for(var/datum/patron/patron_type as anything in allowed_patrons)
		var/datum/patron/patron = GLOB.patron_list[patron_type]
		patron_names += patron?.display_name || patron?.name || "[patron_type]"
	.["patrons"] = patron_names
	.["requires"] = requires ? requires.Copy() : list()

/datum/class_builder_entry/talent/get_block(datum/class_builder_build/build, list/state)
	. = ..()
	if(.)
		return
	var/list/levels = state["direction_levels"]
	if(levels[direction] < tier)
		return list("code" = "tier", "value" = tier)
	if(length(allowed_patrons))
		var/datum/patron/patron = state["patron"]
		if(!(patron?.type in allowed_patrons))
			return list("code" = "patron")
	for(var/required_id in requires)
		if(!(required_id in build.talents))
			var/datum/class_builder_entry/required = GLOB.class_builder.get_entry(required_id)
			return list("code" = "requires", "value" = required?.name || required_id)
	return null

/datum/class_builder_entry/talent/on_apply(mob/living/carbon/human/target, datum/class_builder_build/build)
	grant_traits(target, traits)
	grant_spells(target, spells, build.get_role())

/datum/class_builder_entry/flaw
	abstract_type = /datum/class_builder_entry/flaw
	kind = CB_KIND_FLAW
	/// Direction points paid for taking this flaw.
	var/points = 1
	var/list/traits

/datum/class_builder_entry/flaw/ui_payload()
	. = ..()
	.["points"] = points
	.["traits"] = trait_payload(traits)

/datum/class_builder_entry/flaw/on_apply(mob/living/carbon/human/target, datum/class_builder_build/build)
	grant_traits(target, traits)

/datum/class_builder_entry/item
	abstract_type = /datum/class_builder_entry/item
	kind = CB_KIND_ITEM
	var/item_path
	var/cost = 0
	var/category = "misc"
	/// Paper doll slots this item may occupy. Empty means it can only be carried.
	var/list/slots
	var/required_skill
	var/required_rank = 0
	/// Talent id that unlocks the item.
	var/required_talent

/datum/class_builder_entry/item/New(list/row)
	. = ..()
	if(!islist(row))
		return
	item_path = row["path"]
	var/obj/item/item_type = item_path
	id = row["id"] || "item:[replacetext("[item_path]", "/obj/item/", "")]"
	name = row["name"] || initial(item_type.name)
	name_ru = row["name_ru"]
	desc = row["desc"] || initial(item_type.desc)
	desc_ru = row["desc_ru"]
	icon = initial(item_type.icon)
	icon_state = initial(item_type.icon_state)
	cost = isnum(row["cost"]) ? row["cost"] : 0
	category = row["category"] || category
	slots = row["slots"]
	required_skill = row["skill"]
	required_rank = row["rank"] || 0
	required_talent = row["talent"]
	allowed_roles = row["roles"]

/datum/class_builder_entry/item/ui_payload()
	. = ..()
	.["cost"] = cost
	.["category"] = category
	.["slots"] = slots ? slots.Copy() : list()
	if(required_skill)
		var/datum/attribute/skill/skill_type = required_skill
		.["required_skill"] = list("name" = initial(skill_type.name), "rank" = required_rank)
	if(required_talent)
		var/datum/class_builder_entry/talent = GLOB.class_builder.get_entry(required_talent)
		.["required_talent"] = talent?.name || required_talent

/datum/class_builder_entry/item/get_block(datum/class_builder_build/build, list/state)
	. = ..()
	if(.)
		return
	if(required_skill)
		var/list/final_skills = state["final_skill_types"]
		if(final_skills[required_skill] < required_rank)
			var/datum/attribute/skill/skill_type = required_skill
			return list("code" = "skill", "value" = "[initial(skill_type.name)] [required_rank]")
	if(required_talent && !(required_talent in build.talents))
		var/datum/class_builder_entry/talent = GLOB.class_builder.get_entry(required_talent)
		return list("code" = "talent", "value" = talent?.name || required_talent)
	return null

// ---------------------------------------------------------------------------------------------
// Build model
// ---------------------------------------------------------------------------------------------

/datum/class_builder_build
	var/name = "New Build"
	/// /datum/job/advclass/custom_class subtype this build spawns as.
	var/role_type
	/// Title shown instead of the role title, like TAT's "Pliant Class Name".
	var/class_title = ""
	var/background_id
	/// stat id -> value (CB_STAT_FLOOR..max)
	var/list/stats = list()
	/// skill id -> purchased rank
	var/list/skills = list()
	/// direction id -> invested points
	var/list/directions = list()
	var/list/talents = list()
	var/list/flaws = list()
	/// slot -> item id
	var/list/equipment = list()
	/// item ids carried in bags
	var/list/bag = list()
	/// item ids left in the stash (mind.special_items)
	var/list/stash = list()
	/// TRUE for the build its role spawns with. Kept in the character save, not in exported text.
	var/spawn_active = FALSE

/datum/class_builder_build/New(role_type)
	. = ..()
	src.role_type = role_type

/datum/class_builder_build/proc/get_role()
	var/datum/job/advclass/custom_class/role_path = role_type
	if(!ispath(role_path, /datum/job/advclass/custom_class) || IS_ABSTRACT(role_path))
		return null
	return SSjob.GetJobType(role_path)

/datum/class_builder_build/proc/has_entry(id)
	return id == background_id || (id in talents) || (id in flaws)

/datum/class_builder_build/proc/copy()
	var/datum/class_builder_build/duplicate = new()
	duplicate.deserialize(serialize())
	duplicate.spawn_active = spawn_active
	return duplicate

/datum/class_builder_build/proc/serialize()
	return list(
		"v" = CB_SAVE_VERSION,
		"name" = name,
		"role" = role_type ? "[role_type]" : null,
		"title" = class_title,
		"background" = background_id,
		"stats" = stats.Copy(),
		"skills" = skills.Copy(),
		"directions" = directions.Copy(),
		"talents" = talents.Copy(),
		"flaws" = flaws.Copy(),
		"equipment" = equipment.Copy(),
		"bag" = bag.Copy(),
		"stash" = stash.Copy(),
	)

/// Type-safe load from untrusted data (savefile or player import). Content checks happen in sanitize_entries().
/datum/class_builder_build/proc/deserialize(list/data)
	if(!islist(data))
		return FALSE
	name = class_builder_clean_text(data["name"]) || "Build"
	role_type = istext(data["role"]) ? text2path(data["role"]) : null
	class_title = class_builder_clean_text(data["title"]) || ""
	background_id = istext(data["background"]) ? data["background"] : null
	stats = class_builder_num_map(data["stats"])
	skills = class_builder_num_map(data["skills"])
	directions = class_builder_num_map(data["directions"])
	talents = class_builder_text_list(data["talents"], CB_MAX_MAP_KEYS)
	flaws = class_builder_text_list(data["flaws"], CB_MAX_MAP_KEYS)
	equipment = class_builder_text_map(data["equipment"])
	bag = class_builder_text_list(data["bag"], CB_MAX_CARRIED, TRUE)
	stash = class_builder_text_list(data["stash"], CB_MAX_CARRIED, TRUE)
	return TRUE

/// Drops unknown ids, clamps numbers and fills defaults. Budgets are checked by compute().
/datum/class_builder_build/proc/sanitize_entries()
	var/datum/class_builder_registry/registry = GLOB.class_builder
	var/datum/job/advclass/custom_class/role = get_role()

	if(background_id && !registry.get_entry(background_id, CB_KIND_BACKGROUND))
		background_id = null

	var/list/clean_stats = list()
	for(var/datum/class_builder_entry/stat/stat as anything in registry.get_kind(CB_KIND_STAT))
		var/value = stats[stat.id]
		clean_stats[stat.id] = isnum(value) ? clamp(round(value), CB_STAT_FLOOR, stat.max_value) : CB_STAT_BASE
	stats = clean_stats

	var/list/clean_skills = list()
	for(var/skill_id in skills)
		var/datum/class_builder_entry/skill/skill = registry.get_entry(skill_id, CB_KIND_SKILL)
		if(!skill)
			continue
		var/rank = clamp(round(skills[skill_id]), 0, skill.cap)
		if(rank)
			clean_skills[skill_id] = rank
	skills = clean_skills

	var/list/clean_directions = list()
	for(var/direction_id in directions)
		var/datum/class_builder_entry/direction/direction = registry.get_entry(direction_id, CB_KIND_DIRECTION)
		if(!direction)
			continue
		var/cap = role ? role.get_direction_cap(direction) : direction.max_level
		var/points = clamp(round(directions[direction_id]), 0, cap)
		if(points)
			clean_directions[direction_id] = points
	directions = clean_directions

	talents = class_builder_filter_ids(talents, CB_KIND_TALENT)
	flaws = class_builder_filter_ids(flaws, CB_KIND_FLAW)

	var/list/clean_equipment = list()
	for(var/slot in equipment)
		if(!(slot in GLOB.class_builder_slots))
			continue
		var/datum/class_builder_entry/item/item = registry.get_entry(equipment[slot], CB_KIND_ITEM)
		if(item && (slot in item.slots))
			clean_equipment[slot] = item.id
	equipment = clean_equipment

	bag = class_builder_filter_ids(bag, CB_KIND_ITEM, TRUE)
	stash = class_builder_filter_ids(stash, CB_KIND_ITEM, TRUE)

/datum/class_builder_build/proc/get_direction_levels()
	. = list()
	var/datum/class_builder_entry/background/background = GLOB.class_builder.get_entry(background_id, CB_KIND_BACKGROUND)
	for(var/datum/class_builder_entry/direction/direction as anything in GLOB.class_builder.get_kind(CB_KIND_DIRECTION))
		.[direction.id] = (directions[direction.id] || 0) + (LAZYACCESS(background?.direction_bonus, direction.id) || 0)

/// skill type -> final rank (purchased + background + talents + directions), capped.
/datum/class_builder_build/proc/get_final_skill_types(list/direction_levels)
	var/datum/class_builder_registry/registry = GLOB.class_builder
	var/list/ranks = list()
	for(var/skill_id in skills)
		var/datum/class_builder_entry/skill/skill = registry.get_entry(skill_id, CB_KIND_SKILL)
		if(skill)
			ranks[skill.skill_type] += skills[skill_id]
	var/datum/class_builder_entry/background/background = registry.get_entry(background_id, CB_KIND_BACKGROUND)
	for(var/skill_type in background?.skills)
		ranks[skill_type] += background.skills[skill_type]
	for(var/talent_id in talents)
		var/datum/class_builder_entry/talent/talent = registry.get_entry(talent_id, CB_KIND_TALENT)
		for(var/skill_type in talent?.skills)
			ranks[skill_type] += talent.skills[skill_type]
	for(var/datum/class_builder_entry/direction/direction as anything in registry.get_kind(CB_KIND_DIRECTION))
		for(var/skill_type in direction.skill_per_level)
			ranks[skill_type] += round(direction_levels[direction.id] * direction.skill_per_level[skill_type])
	for(var/skill_type in ranks)
		ranks[skill_type] = clamp(ranks[skill_type], 0, CB_SKILL_MAX_RANK)
	return ranks

/// Budgets, levels and every reason an entry is blocked. Used by the editor, saving and spawning.
/datum/class_builder_build/proc/compute(datum/patron/patron)
	var/datum/class_builder_registry/registry = GLOB.class_builder
	var/datum/job/advclass/custom_class/role = get_role()
	var/list/errors = list()
	var/list/result = list("errors" = errors)
	if(!role)
		errors += list(list("code" = "no_role"))
		return result

	var/stat_spent = 0
	for(var/datum/class_builder_entry/stat/stat as anything in registry.get_kind(CB_KIND_STAT))
		stat_spent += ((stats[stat.id] || CB_STAT_BASE) - CB_STAT_BASE) * stat.cost
	result["stat_spent"] = stat_spent
	result["stat_budget"] = role.cb_stat_points
	if(stat_spent > role.cb_stat_points)
		errors += list(list("code" = "stat_over"))

	var/list/skill_spent = list()
	for(var/pool in role.cb_skill_points)
		skill_spent[pool] = 0
	for(var/skill_id in skills)
		var/datum/class_builder_entry/skill/skill = registry.get_entry(skill_id, CB_KIND_SKILL)
		if(skill)
			skill_spent[skill.pool] += skills[skill_id] * skill.cost
	for(var/pool in skill_spent)
		if(skill_spent[pool] > (role.cb_skill_points[pool] || 0))
			errors += list(list("code" = "skill_over", "arg" = pool))
	result["skill_spent"] = skill_spent
	result["skill_budget"] = role.cb_skill_points.Copy()

	var/flaw_points = 0
	for(var/flaw_id in flaws)
		var/datum/class_builder_entry/flaw/flaw = registry.get_entry(flaw_id, CB_KIND_FLAW)
		flaw_points += flaw?.points
	var/direction_spent = 0
	for(var/direction_id in directions)
		direction_spent += directions[direction_id]
	result["direction_spent"] = direction_spent
	result["direction_budget"] = role.cb_direction_points + flaw_points
	result["flaw_points"] = flaw_points
	if(direction_spent > role.cb_direction_points + flaw_points)
		errors += list(list("code" = "direction_over"))
	if(length(flaws) > role.cb_max_flaws)
		errors += list(list("code" = "flaw_over"))
	result["flaw_count"] = length(flaws)
	result["flaw_max"] = role.cb_max_flaws

	var/list/direction_levels = get_direction_levels()
	var/list/direction_caps = list()
	for(var/datum/class_builder_entry/direction/direction as anything in registry.get_kind(CB_KIND_DIRECTION))
		direction_caps[direction.id] = role.get_direction_cap(direction)
	result["direction_levels"] = direction_levels
	result["direction_caps"] = direction_caps

	var/list/talent_spent = list()
	for(var/talent_id in talents)
		var/datum/class_builder_entry/talent/talent = registry.get_entry(talent_id, CB_KIND_TALENT)
		if(talent)
			talent_spent[talent.direction] += talent.cost
	for(var/direction_id in talent_spent)
		if(talent_spent[direction_id] > direction_levels[direction_id])
			errors += list(list("code" = "talent_over", "arg" = direction_id))
	result["talent_spent"] = talent_spent

	var/list/final_skill_types = get_final_skill_types(direction_levels)
	var/list/final_skills = list()
	for(var/datum/class_builder_entry/skill/skill as anything in registry.get_kind(CB_KIND_SKILL))
		if(final_skill_types[skill.skill_type])
			final_skills[skill.id] = final_skill_types[skill.skill_type]
	result["final_skills"] = final_skills

	var/item_spent = 0
	for(var/slot in equipment)
		var/datum/class_builder_entry/item/item = registry.get_entry(equipment[slot], CB_KIND_ITEM)
		item_spent += item?.cost
	for(var/item_id in bag + stash)
		var/datum/class_builder_entry/item/item = registry.get_entry(item_id, CB_KIND_ITEM)
		item_spent += item?.cost
	result["item_spent"] = item_spent
	result["item_budget"] = role.cb_item_points
	if(item_spent > role.cb_item_points)
		errors += list(list("code" = "item_over"))

	// Blocks for everything the UI can toggle; selected-but-blocked entries are errors.
	var/list/state = list(
		"direction_levels" = direction_levels,
		"final_skill_types" = final_skill_types,
		"patron" = patron,
	)
	var/list/blocked = list()
	var/list/selected_items = list()
	for(var/slot in equipment)
		selected_items[equipment[slot]] = TRUE
	for(var/item_id in bag + stash)
		selected_items[item_id] = TRUE
	for(var/kind in list(CB_KIND_BACKGROUND, CB_KIND_TALENT, CB_KIND_FLAW, CB_KIND_ITEM))
		for(var/datum/class_builder_entry/entry as anything in registry.get_kind(kind))
			var/list/block = entry.get_block(src, state)
			if(!block)
				continue
			blocked[entry.id] = block
			if(has_entry(entry.id) || selected_items[entry.id])
				errors += list(list("code" = "blocked", "arg" = entry.id))
	result["blocked"] = blocked
	return result

/// Resets every section that breaks the rules. Returns the error codes that forced a reset.
/datum/class_builder_build/proc/enforce_budgets(datum/patron/patron)
	. = list()
	for(var/pass in 1 to 4)
		var/list/computed = compute(patron)
		var/list/errors = computed["errors"]
		if(!length(errors))
			return
		for(var/list/error as anything in errors)
			. |= error["code"]
			switch(error["code"])
				if("no_role")
					return
				if("stat_over")
					stats = list()
				if("skill_over")
					for(var/skill_id in skills.Copy())
						var/datum/class_builder_entry/skill/skill = GLOB.class_builder.get_entry(skill_id, CB_KIND_SKILL)
						if(skill?.pool == error["arg"])
							skills -= skill_id
				if("direction_over", "flaw_over")
					directions = list()
					talents = list()
					flaws = list()
				if("talent_over")
					for(var/talent_id in talents.Copy())
						var/datum/class_builder_entry/talent/talent = GLOB.class_builder.get_entry(talent_id, CB_KIND_TALENT)
						if(talent?.direction == error["arg"])
							talents -= talent_id
				if("item_over")
					equipment = list()
					bag = list()
					stash = list()
				if("blocked")
					remove_entry(error["arg"])
		sanitize_entries()

/datum/class_builder_build/proc/remove_entry(id)
	if(background_id == id)
		background_id = null
	talents -= id
	flaws -= id
	bag -= id
	stash -= id
	for(var/slot in equipment.Copy())
		if(equipment[slot] == id)
			equipment -= slot

/datum/class_builder_build/proc/make_attribute_sheet()
	var/datum/class_builder_registry/registry = GLOB.class_builder
	var/datum/attribute_holder/sheet/job/sheet = new()
	sheet.raw_attribute_list = list()
	for(var/datum/class_builder_entry/stat/stat as anything in registry.get_kind(CB_KIND_STAT))
		var/delta = (stats[stat.id] || CB_STAT_BASE) - CB_STAT_BASE
		if(delta)
			sheet.raw_attribute_list[stat.attribute_type] = delta
	var/list/final_skill_types = get_final_skill_types(get_direction_levels())
	for(var/skill_type in final_skill_types)
		if(final_skill_types[skill_type])
			sheet.raw_attribute_list[skill_type] = final_skill_types[skill_type] * SKILL_LEVEL_NOVICE
	return sheet

/// Everything except stats/skills, which go through assign_attributes().
/datum/class_builder_build/proc/apply_to(mob/living/carbon/human/target)
	var/datum/class_builder_registry/registry = GLOB.class_builder
	var/datum/class_builder_entry/background/background = registry.get_entry(background_id, CB_KIND_BACKGROUND)
	background?.on_apply(target, src)
	for(var/talent_id in talents)
		var/datum/class_builder_entry/talent/talent = registry.get_entry(talent_id, CB_KIND_TALENT)
		talent?.on_apply(target, src)
	for(var/flaw_id in flaws)
		var/datum/class_builder_entry/flaw/flaw = registry.get_entry(flaw_id, CB_KIND_FLAW)
		flaw?.on_apply(target, src)
	equip(target)

/datum/class_builder_build/proc/equip(mob/living/carbon/human/target)
	var/datum/class_builder_registry/registry = GLOB.class_builder
	var/datum/job/advclass/custom_class/role = get_role()
	var/datum/outfit/class_builder/kit = new()
	for(var/slot in equipment)
		var/datum/class_builder_entry/item/item = registry.get_entry(equipment[slot], CB_KIND_ITEM)
		if(item && (slot in kit.vars))
			kit.vars[slot] = item.item_path
	for(var/slot in role?.cb_free_kit)
		if((slot in kit.vars) && !kit.vars[slot])
			kit.vars[slot] = role.cb_free_kit[slot]
	target.equipOutfit(kit)

	var/list/overflow = list()
	for(var/item_id in bag)
		var/datum/class_builder_entry/item/item = registry.get_entry(item_id, CB_KIND_ITEM)
		if(!item)
			continue
		var/obj/item/new_item = new item.item_path(target.drop_location())
		if(!kit.store_carried(target, new_item))
			qdel(new_item)
			overflow += item
	for(var/item_id in stash)
		var/datum/class_builder_entry/item/item = registry.get_entry(item_id, CB_KIND_ITEM)
		if(item)
			overflow += item
	for(var/datum/class_builder_entry/item/item as anything in overflow)
		stash_item(target, item)
	if(length(overflow))
		to_chat(target, span_notice("[length(overflow)] of my belongings wait for me in my stash."))
	qdel(kit)

/datum/class_builder_build/proc/stash_item(mob/living/carbon/human/target, datum/class_builder_entry/item/item)
	if(!target.mind)
		return
	var/key = item.name
	var/suffix = 1
	while(target.mind.special_items[key])
		suffix++
		key = "[item.name] ([suffix])"
	target.mind.special_items[key] = item.item_path

/datum/outfit/class_builder
	name = "Class Builder Kit"
	can_be_admin_equipped = FALSE

/datum/outfit/class_builder/proc/store_carried(mob/living/carbon/human/target, obj/item/new_item)
	for(var/slot_flag in list(ITEM_SLOT_BACK_L, ITEM_SLOT_BACK_R, ITEM_SLOT_BELT, ITEM_SLOT_NECK))
		var/obj/item/container = target.get_item_by_slot(slot_flag)
		if(container && attempt_insert_with_flipping(container, new_item, null, TRUE, FALSE))
			return TRUE
	return FALSE

// ---------------------------------------------------------------------------------------------
// Untrusted data helpers
// ---------------------------------------------------------------------------------------------

/proc/class_builder_clean_text(raw, max_len = CB_NAME_MAX)
	if(!istext(raw))
		return null
	var/static/regex/forbidden = regex(@"[<>\n\r\t]", "g")
	var/clean = trimtext(copytext_char(forbidden.Replace(raw, ""), 1, max_len + 1))
	return length(clean) ? clean : null

/proc/class_builder_num_map(list/raw)
	. = list()
	if(!islist(raw))
		return
	for(var/key in raw)
		if(length(.) >= CB_MAX_MAP_KEYS)
			return
		if(istext(key) && isnum(raw[key]))
			.[key] = raw[key]

/proc/class_builder_text_map(list/raw)
	. = list()
	if(!islist(raw))
		return
	for(var/key in raw)
		if(length(.) >= CB_MAX_MAP_KEYS)
			return
		if(istext(key) && istext(raw[key]))
			.[key] = raw[key]

/proc/class_builder_text_list(list/raw, max_len, allow_duplicates = FALSE)
	. = list()
	if(!islist(raw))
		return
	for(var/value in raw)
		if(length(.) >= max_len)
			return
		if(!istext(value))
			continue
		if(allow_duplicates)
			. += value
		else
			. |= value

/proc/class_builder_filter_ids(list/ids, kind, allow_duplicates = FALSE)
	. = list()
	for(var/id in ids)
		if(!GLOB.class_builder.get_entry(id, kind))
			continue
		if(allow_duplicates)
			. += id
		else
			. |= id

// ---------------------------------------------------------------------------------------------
// Storage: JSON in the character savefile, read once when the character slot loads
// ---------------------------------------------------------------------------------------------

/// Builds of the loaded character slot. Filled by load_character(), changed only by the editor.
/datum/preferences/var/list/class_builder_builds

/datum/preferences/load_character(slot)
	. = ..()
	class_builder_builds = list()
	if(!. || !path)
		return
	class_builder_builds = class_builder_read(src, default_slot)

/// Static check, so builds survive a character load that happens before SSjob is ready.
/proc/class_builder_valid_role_type(role_type)
	return ispath(role_type, /datum/job/advclass/custom_class) && !IS_ABSTRACT(role_type)

/proc/class_builder_read(datum/preferences/prefs, slot)
	. = list()
	if(!prefs?.path || !isnum(slot) || !fexists(prefs.path))
		return
	var/savefile/save = new /savefile(prefs.path)
	save.cd = "/character[slot]"
	var/raw
	save[CB_SAVE_KEY] >> raw
	if(!istext(raw) || !length(raw))
		return
	var/list/decoded = safe_json_decode(raw)
	if(!islist(decoded) || !islist(decoded["builds"]))
		return
	for(var/list/entry in decoded["builds"])
		if(length(.) >= CB_MAX_BUILDS)
			break
		var/datum/class_builder_build/build = new()
		if(!build.deserialize(entry) || !class_builder_valid_role_type(build.role_type))
			continue
		build.sanitize_entries()
		build.spawn_active = entry["active"] == TRUE
		. += build
	class_builder_normalize_active(.)

/// Writes to an explicit character slot: the editor may outlive a slot switch in the lobby.
/proc/class_builder_write(datum/preferences/prefs, list/builds, slot)
	if(!prefs?.path || !isnum(slot))
		return FALSE
	var/savefile/save = new /savefile(prefs.path)
	save.cd = "/character[slot]"
	var/list/payload = list()
	for(var/datum/class_builder_build/build as anything in builds)
		var/list/entry = build.serialize()
		if(build.spawn_active)
			entry["active"] = TRUE
		payload += list(entry)
	WRITE_FILE(save[CB_SAVE_KEY], json_encode(list("v" = CB_SAVE_VERSION, "builds" = payload)))
	return TRUE

/// One active build per role: the first flagged one, else the first build of that role.
/proc/class_builder_normalize_active(list/builds)
	var/list/active_by_role = list()
	for(var/datum/class_builder_build/build as anything in builds)
		var/role_key = "[build.role_type]"
		if(active_by_role[role_key])
			build.spawn_active = FALSE
		else if(build.spawn_active)
			active_by_role[role_key] = build
	for(var/datum/class_builder_build/build as anything in builds)
		var/role_key = "[build.role_type]"
		if(!active_by_role[role_key])
			build.spawn_active = TRUE
			active_by_role[role_key] = build

/// The build a custom class spawns with, from the loaded character slot. No savefile access.
/proc/class_builder_active_build(datum/preferences/prefs, role_type)
	for(var/datum/class_builder_build/build as anything in prefs?.class_builder_builds)
		if(build.spawn_active && build.role_type == role_type)
			return build
	return null

// ---------------------------------------------------------------------------------------------
// Roles: one custom subclass per parent role, configured by vars
// ---------------------------------------------------------------------------------------------

/datum/job/advclass/custom_class
	abstract_type = /datum/job/advclass/custom_class
	title = "Custom Class"
	tutorial = "A path of your own making, shaped in the class builder."
	outfit = null
	// Always listed in the subclass menu when the player has a build for this role.
	bypass_class_cat_limits = TRUE
	/// Parent /datum/job this subclass belongs to.
	var/parent_role
	/// UI grouping: "adventurer" or "town".
	var/cb_group = "adventurer"
	var/cb_stat_points = 7
	var/list/cb_skill_points = list(CB_POOL_COMBAT = 12, CB_POOL_PEACEFUL = 6, CB_POOL_ADVENTURE = 12)
	var/cb_direction_points = 10
	var/cb_item_points = 20
	var/cb_max_flaws = 3
	/// direction id -> max level for this role; missing ids use the direction's own max.
	var/list/cb_direction_caps
	/// doll slot -> item path given for free when the build leaves that slot empty.
	var/list/cb_free_kit
	/// mob REF -> build, alive only during after_spawn so assign_attributes() can read it.
	var/static/list/pending_builds = list()

/datum/job/advclass/custom_class/proc/get_direction_cap(datum/class_builder_entry/direction/direction)
	var/cap = LAZYACCESS(cb_direction_caps, direction.id)
	return isnull(cap) ? direction.max_level : min(cap, direction.max_level)

/datum/job/advclass/custom_class/proc/class_builder_payload()
	var/datum/job/parent = SSjob.GetJobType(parent_role)
	var/list/caps = list()
	for(var/datum/class_builder_entry/direction/direction as anything in GLOB.class_builder.get_kind(CB_KIND_DIRECTION))
		caps[direction.id] = get_direction_cap(direction)
	return list(
		"type" = "[type]",
		"title" = parent?.title || title,
		"group" = cb_group,
		"stat_points" = cb_stat_points,
		"skill_points" = cb_skill_points.Copy(),
		"direction_points" = cb_direction_points,
		"item_points" = cb_item_points,
		"max_flaws" = cb_max_flaws,
		"direction_caps" = caps,
		"free_kit" = free_kit_payload(),
	)

/// slot -> list(name, icon, icon_state) so the paper doll can show what fills empty slots.
/datum/job/advclass/custom_class/proc/free_kit_payload()
	. = list()
	for(var/slot in cb_free_kit)
		var/obj/item/item_type = cb_free_kit[slot]
		.[slot] = list(
			"name" = initial(item_type.name),
			"icon" = "[initial(item_type.icon)]",
			"icon_state" = "[initial(item_type.icon_state)]",
		)

/datum/job/advclass/custom_class/check_requirements(mob/living/carbon/human/to_check)
	. = ..()
	if(!.)
		return
	return !!class_builder_active_build(to_check.client?.prefs, type)

/// A copy of the role's active build with anything that breaks the current rules reset.
/// Without one (deleted after the class roll) the character still gets the role's free kit.
/datum/job/advclass/custom_class/proc/resolve_spawn_build(mob/living/carbon/human/spawned, client/player_client)
	var/datum/class_builder_build/active = class_builder_active_build(player_client?.prefs, type)
	if(!active)
		to_chat(spawned, span_warning("I have no active build for this path and arrive with only the basics."))
		return new /datum/class_builder_build(type)
	var/datum/class_builder_build/build = active.copy()
	var/list/reset = build.enforce_budgets(spawned.patron)
	if(length(reset))
		to_chat(spawned, span_warning("Part of my build no longer fits the current rules and was reset: [jointext(reset, ", ")]."))
	return build

/datum/job/advclass/custom_class/after_spawn(mob/living/carbon/human/spawned, client/player_client, clear_job_stats = TRUE)
	var/datum/class_builder_build/build = resolve_spawn_build(spawned, player_client)
	var/spawned_ref = REF(spawned)
	pending_builds[spawned_ref] = build
	. = ..()
	pending_builds -= spawned_ref
	if(QDELETED(spawned))
		return
	build.apply_to(spawned)

/// The parent after_spawn() resets title preferences first; the build's class name goes on top.
/datum/job/advclass/custom_class/apply_alt_title_preferences(mob/living/character, datum/preferences/preferences)
	. = ..()
	var/datum/class_builder_build/build = pending_builds[REF(character)]
	if(build?.class_title)
		character.job_title_override = build.class_title

/datum/job/advclass/custom_class/assign_attributes(mob/living/spawned, client/player_client)
	var/datum/class_builder_build/build = pending_builds[REF(spawned)]
	if(!build || !ishuman(spawned))
		return FALSE
	var/mob/living/carbon/human/spawned_human = spawned
	spawned_human.attributes?.add_sheet(build.make_attribute_sheet())
	return TRUE

// ---------------------------------------------------------------------------------------------
// Editor
// ---------------------------------------------------------------------------------------------

/// Opens the editor; with role_type it shows that role's active build unless edits are unsaved.
/proc/open_class_builder(mob/user, role_type)
	var/client/user_client = user?.client
	if(!user_client?.prefs?.path)
		return
	var/datum/class_builder_editor/editor = GLOB.class_builder_editors[user_client.ckey]
	if(!editor)
		editor = new(user_client)
	if(role_type)
		editor.focus_role(role_type)
	editor.ui_interact(user)

/// Interface name for the Character Creator language, so both windows switch together.
/proc/class_builder_interface(datum/preferences/prefs)
	return prefs?.character_creator_lang == "ru" ? "ClassBuilderRu" : "ClassBuilder"

/datum/class_builder_editor
	var/owner_ckey
	var/datum/preferences/prefs
	/// prefs.class_builder_builds at the last sync. Edited in place, so the spawn checks see every write.
	var/list/builds
	var/loaded_slot
	var/active_index = 0
	/// Working copy of builds[active_index]; saved explicitly.
	var/datum/class_builder_build/working
	var/dirty = FALSE
	var/export_text
	/// Last rejected action, list("code", "arg"), shown once.
	var/list/notice

/datum/class_builder_editor/New(client/user_client)
	. = ..()
	owner_ckey = user_client.ckey
	prefs = user_client.prefs
	GLOB.class_builder_editors[owner_ckey] = src
	reload()

/datum/class_builder_editor/Destroy()
	GLOB.class_builder_editors -= owner_ckey
	builds = null
	working = null
	prefs = null
	return ..()

/// TRUE after the lobby switched or reloaded the character: load_character() replaced the list.
/datum/class_builder_editor/proc/is_stale()
	return prefs.default_slot != loaded_slot || prefs.class_builder_builds != builds

/datum/class_builder_editor/proc/reload()
	if(!islist(prefs.class_builder_builds))
		prefs.class_builder_builds = list()
	builds = prefs.class_builder_builds
	loaded_slot = prefs.default_slot
	select(length(builds) ? 1 : 0)

/datum/class_builder_editor/proc/select(index)
	active_index = index
	var/datum/class_builder_build/source = index ? builds[index] : null
	working = source?.copy()
	dirty = FALSE
	export_text = null

/datum/class_builder_editor/proc/focus_role(role_type)
	if(is_stale())
		reload()
	if(dirty || (working?.role_type == role_type))
		return
	for(var/index in 1 to length(builds))
		var/datum/class_builder_build/build = builds[index]
		if(build.role_type == role_type && build.spawn_active)
			select(index)
			return

/// Follows a language switch in the Character Creator while the editor is open.
/datum/class_builder_editor/proc/sync_interface(mob/user)
	var/datum/tgui/ui = SStgui.get_open_ui(user, src)
	var/wanted = class_builder_interface(prefs)
	if(!ui || ui.interface == wanted)
		return
	ui.interface = wanted
	ui.send_full_update()

/datum/class_builder_editor/proc/get_patron()
	return prefs.read_preference(/datum/preference/choiced/patron)

/datum/class_builder_editor/proc/write_builds()
	class_builder_normalize_active(builds)
	if(!class_builder_write(prefs, builds, loaded_slot))
		notice = list("code" = "save_failed")
		return FALSE
	return TRUE

/// Accepts a mutated copy only if it adds no new rule violations.
/datum/class_builder_editor/proc/commit(datum/class_builder_build/trial)
	var/datum/patron/patron = get_patron()
	var/list/old_computed = working.compute(patron)
	var/list/new_computed = trial.compute(patron)
	var/list/old_codes = list()
	for(var/list/error as anything in old_computed["errors"])
		old_codes["[error["code"]]:[error["arg"]]"] = TRUE
	for(var/list/error as anything in new_computed["errors"])
		if(!old_codes["[error["code"]]:[error["arg"]]"])
			notice = error
			return FALSE
	working = trial
	dirty = TRUE
	return TRUE

/datum/class_builder_editor/proc/has_errors(datum/class_builder_build/build)
	var/list/computed = build.compute(get_patron())
	return length(computed["errors"]) > 0

/datum/class_builder_editor/ui_state(mob/user)
	return GLOB.always_state

/datum/class_builder_editor/ui_status(mob/user, datum/ui_state/state)
	if(user?.ckey != owner_ckey)
		return UI_CLOSE
	return ..()

/datum/class_builder_editor/ui_interact(mob/user, datum/tgui/ui)
	if(is_stale())
		reload()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, class_builder_interface(prefs))
		ui.open()

/datum/class_builder_editor/ui_close(mob/user)
	. = ..()
	qdel(src)

/datum/class_builder_editor/ui_static_data(mob/user)
	return GLOB.class_builder.get_static_payload()

/datum/class_builder_editor/ui_data(mob/user)
	var/list/data = list()
	var/datum/patron/patron = get_patron()
	data["character_name"] = prefs.read_preference(/datum/preference/text/real_name)
	data["species"] = prefs.pref_species?.name
	data["patron"] = patron ? (patron.display_name || patron.name) : null
	var/list/slot_list = list()
	for(var/index in 1 to length(builds))
		var/datum/class_builder_build/build = builds[index]
		var/datum/job/advclass/custom_class/role = build.get_role()
		var/datum/job/parent = role ? SSjob.GetJobType(role.parent_role) : null
		slot_list += list(list(
			"index" = index,
			"name" = build.name,
			"role" = "[build.role_type]",
			"role_title" = parent?.title || "?",
			"active" = build.spawn_active,
		))
	data["build_slots"] = slot_list
	data["active_index"] = active_index
	data["dirty"] = dirty
	data["build"] = working?.serialize()
	data["computed"] = working?.compute(patron)
	data["loadout"] = loadout_payload()
	data["export_text"] = export_text
	data["notice"] = notice
	notice = null
	return data

/// Donator loadout picks: always land in the stash on spawn through apply_loadouts().
/datum/class_builder_editor/proc/loadout_payload()
	. = list()
	for(var/index in 1 to 10)
		var/datum/loadout_item/loadout = prefs.vars["loadout[index]"]
		if(!istype(loadout) || !loadout.item_path)
			continue
		var/obj/item/item_type = loadout.item_path
		. += list(list(
			"name" = loadout.name || initial(item_type.name),
			"icon" = "[initial(item_type.icon)]",
			"icon_state" = "[initial(item_type.icon_state)]",
		))

/datum/class_builder_editor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(ui.user?.ckey != owner_ckey)
		return FALSE
	if(is_stale())
		reload()
		notice = list("code" = "slot_changed")
		return TRUE
	var/datum/class_builder_registry/registry = GLOB.class_builder
	switch(action)
		if("slot_select")
			var/index = text2num("[params["index"]]")
			if(!isnum(index) || index < 1 || index > length(builds))
				return FALSE
			select(index)
			return TRUE

		if("slot_new")
			if(length(builds) >= CB_MAX_BUILDS)
				notice = list("code" = "max_builds")
				return TRUE
			var/role_path = text2path("[params["role"]]")
			var/datum/class_builder_build/build = new(role_path)
			if(!build.get_role())
				return FALSE
			build.sanitize_entries()
			builds += build
			write_builds()
			select(length(builds))
			return TRUE

		if("slot_duplicate")
			if(!working)
				return FALSE
			if(length(builds) >= CB_MAX_BUILDS)
				notice = list("code" = "max_builds")
				return TRUE
			var/datum/class_builder_build/duplicate = working.copy()
			duplicate.name = class_builder_clean_text("[duplicate.name] II") || duplicate.name
			duplicate.spawn_active = FALSE
			if(has_errors(duplicate))
				notice = list("code" = "cannot_save")
				return TRUE
			builds += duplicate
			write_builds()
			select(length(builds))
			return TRUE

		if("slot_delete")
			if(!active_index)
				return FALSE
			builds.Cut(active_index, active_index + 1)
			write_builds()
			select(length(builds) ? 1 : 0)
			return TRUE

		if("slot_activate")
			if(!active_index)
				return FALSE
			var/datum/class_builder_build/chosen = builds[active_index]
			for(var/datum/class_builder_build/build as anything in builds)
				if(build.role_type == chosen.role_type)
					build.spawn_active = (build == chosen)
			if(write_builds())
				if(working)
					working.spawn_active = TRUE
				notice = list("code" = "activated", "arg" = chosen.name)
			return TRUE

		if("save")
			if(!working || !active_index)
				return FALSE
			if(has_errors(working))
				notice = list("code" = "cannot_save")
				return TRUE
			// The active flag belongs to the saved slot; an imported build arrives without it.
			var/datum/class_builder_build/previous = builds[active_index]
			var/datum/class_builder_build/saved = working.copy()
			saved.spawn_active = previous.spawn_active
			builds[active_index] = saved
			if(write_builds())
				working.spawn_active = saved.spawn_active
				dirty = FALSE
				notice = list("code" = "saved")
			return TRUE

		if("revert")
			select(active_index)
			return TRUE

		if("export")
			if(!working)
				return FALSE
			export_text = json_encode(working.serialize())
			return TRUE

		if("import")
			if(!working)
				return FALSE
			var/raw = params["text"]
			if(!istext(raw) || length(raw) > CB_IMPORT_MAX)
				notice = list("code" = "import_failed")
				return TRUE
			var/list/decoded
			try
				decoded = json_decode(raw)
			catch
				decoded = null
			var/datum/class_builder_build/imported = new()
			if(!imported.deserialize(decoded) || !imported.get_role())
				notice = list("code" = "import_failed")
				return TRUE
			imported.sanitize_entries()
			var/list/reset = imported.enforce_budgets(get_patron())
			working = imported
			dirty = TRUE
			export_text = null
			notice = length(reset) ? list("code" = "import_reset", "arg" = jointext(reset, ", ")) : list("code" = "imported")
			return TRUE

	if(!working)
		return FALSE
	var/datum/class_builder_build/trial = working.copy()

	switch(action)
		if("set_name")
			var/new_name = class_builder_clean_text(params["value"])
			if(!new_name)
				return FALSE
			trial.name = new_name
			return commit(trial)

		if("set_title")
			trial.class_title = class_builder_clean_text(params["value"]) || ""
			return commit(trial)

		if("set_role")
			trial.role_type = text2path("[params["role"]]")
			if(!trial.get_role())
				return FALSE
			trial.sanitize_entries()
			var/list/reset = trial.enforce_budgets(get_patron())
			working = trial
			dirty = TRUE
			if(length(reset))
				notice = list("code" = "role_reset", "arg" = jointext(reset, ", "))
			return TRUE

		if("set_background")
			var/background_id = params["id"]
			if(background_id && !registry.get_entry(background_id, CB_KIND_BACKGROUND))
				return FALSE
			trial.background_id = background_id || null
			return commit(trial)

		if("reset")
			switch(params["section"])
				if("stats")
					trial.stats = list()
				if("skills")
					trial.skills = list()
				if("directions")
					trial.directions = list()
					trial.talents = list()
				if("traits")
					trial.talents = list()
					trial.flaws = list()
				if("items")
					trial.equipment = list()
					trial.bag = list()
					trial.stash = list()
				if("all")
					trial = new(working.role_type)
					trial.name = working.name
				else
					return FALSE
			trial.sanitize_entries()
			working = trial
			dirty = TRUE
			return TRUE

		if("stat_adjust")
			var/datum/class_builder_entry/stat/stat = registry.get_entry(params["id"], CB_KIND_STAT)
			var/delta = text2num("[params["delta"]]")
			if(!stat || !(delta in list(-1, 1)))
				return FALSE
			var/value = (trial.stats[stat.id] || CB_STAT_BASE) + delta
			if(value < CB_STAT_FLOOR || value > stat.max_value)
				return FALSE
			trial.stats[stat.id] = value
			return commit(trial)

		if("skill_adjust")
			var/datum/class_builder_entry/skill/skill = registry.get_entry(params["id"], CB_KIND_SKILL)
			var/delta = text2num("[params["delta"]]")
			if(!skill || !(delta in list(-1, 1)))
				return FALSE
			var/rank = (trial.skills[skill.id] || 0) + delta
			if(rank < 0 || rank > skill.cap)
				return FALSE
			if(rank)
				trial.skills[skill.id] = rank
			else
				trial.skills -= skill.id
			return commit(trial)

		if("direction_adjust")
			var/datum/class_builder_entry/direction/direction = registry.get_entry(params["id"], CB_KIND_DIRECTION)
			var/delta = text2num("[params["delta"]]")
			if(!direction || !(delta in list(-1, 1)))
				return FALSE
			var/datum/job/advclass/custom_class/role = trial.get_role()
			var/points = (trial.directions[direction.id] || 0) + delta
			if(!role || points < 0 || points > role.get_direction_cap(direction))
				return FALSE
			if(points)
				trial.directions[direction.id] = points
			else
				trial.directions -= direction.id
			return commit(trial)

		if("talent_toggle")
			var/datum/class_builder_entry/talent/talent = registry.get_entry(params["id"], CB_KIND_TALENT)
			if(!talent)
				return FALSE
			if(talent.id in trial.talents)
				trial.talents -= talent.id
			else
				trial.talents += talent.id
			return commit(trial)

		if("flaw_toggle")
			var/datum/class_builder_entry/flaw/flaw = registry.get_entry(params["id"], CB_KIND_FLAW)
			if(!flaw)
				return FALSE
			if(flaw.id in trial.flaws)
				trial.flaws -= flaw.id
			else
				trial.flaws += flaw.id
			return commit(trial)

		if("equip")
			var/slot = params["slot"]
			if(!(slot in GLOB.class_builder_slots))
				return FALSE
			if(!params["id"])
				trial.equipment -= slot
				return commit(trial)
			var/datum/class_builder_entry/item/item = registry.get_entry(params["id"], CB_KIND_ITEM)
			if(!item || !(slot in item.slots))
				return FALSE
			trial.equipment[slot] = item.id
			return commit(trial)

		if("carry_add")
			var/datum/class_builder_entry/item/item = registry.get_entry(params["id"], CB_KIND_ITEM)
			var/zone = params["zone"]
			if(!item || !(zone in list(CB_ZONE_BAG, CB_ZONE_STASH)))
				return FALSE
			var/list/carried = zone == CB_ZONE_BAG ? trial.bag : trial.stash
			if(length(carried) >= CB_MAX_CARRIED)
				notice = list("code" = "max_carried")
				return TRUE
			carried += item.id
			return commit(trial)

		if("carry_remove", "carry_move")
			var/zone = params["zone"]
			var/index = text2num("[params["index"]]")
			if(!(zone in list(CB_ZONE_BAG, CB_ZONE_STASH)))
				return FALSE
			var/list/carried = zone == CB_ZONE_BAG ? trial.bag : trial.stash
			if(!isnum(index) || index < 1 || index > length(carried))
				return FALSE
			var/item_id = carried[index]
			carried.Cut(index, index + 1)
			if(action == "carry_move")
				var/list/target_list = zone == CB_ZONE_BAG ? trial.stash : trial.bag
				if(length(target_list) >= CB_MAX_CARRIED)
					notice = list("code" = "max_carried")
					return TRUE
				target_list += item_id
			return commit(trial)

	return FALSE

// ---------------------------------------------------------------------------------------------
// Character Creator: entry point, custom subclass marks, build status and the shared language
// ---------------------------------------------------------------------------------------------

/datum/preferences/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	var/mob/user = ui?.user || usr
	if(user?.client?.prefs != src)
		return
	switch(action)
		if("class_builder_open")
			var/role_type = text2path("[params?["role"]]")
			open_class_builder(user, class_builder_valid_role_type(role_type) ? role_type : null)
			return FALSE
		if("cc_set_lang")
			var/datum/class_builder_editor/editor = GLOB.class_builder_editors[user.ckey]
			editor?.sync_interface(user)

/// Custom subclasses are flagged so the sub-role step can offer the editor instead of a fixed kit.
/datum/preferences/character_creator_subclass_catalog()
	. = ..()
	for(var/job_title in .)
		for(var/list/entry as anything in .[job_title])
			if(class_builder_valid_role_type(text2path("[entry["id"]]")))
				entry["custom"] = TRUE

/datum/preferences/ui_data(mob/user)
	. = ..()
	if(!character_creator_active())
		return
	var/list/status = list()
	for(var/datum/class_builder_build/build as anything in class_builder_builds)
		var/role_key = "[build.role_type]"
		var/list/role_status = status[role_key]
		if(!role_status)
			role_status = list("count" = 0, "active" = null)
			status[role_key] = role_status
		role_status["count"] += 1
		if(build.spawn_active)
			role_status["active"] = build.name
	.["cc_class_builds"] = status
