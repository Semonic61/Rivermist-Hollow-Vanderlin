/// Class builder: registry content, untrusted build data, budget repair and the active build per role.

/// Every entry has a unique non-empty id (they are save keys) and every item row points at a real item.
/datum/unit_test/class_builder_registry/Run()
	var/datum/class_builder_registry/registry = GLOB.class_builder
	registry.ensure_built()
	TEST_ASSERT(length(registry.entries), "The class builder should register entries")
	for(var/id in registry.entries)
		var/datum/class_builder_entry/entry = registry.entries[id]
		TEST_ASSERT(istext(id) && length(id), "[entry.type] has an empty id")
		TEST_ASSERT_EQUAL(entry.id, id, "[entry.type] is registered under a different id")
	for(var/list/row as anything in GLOB.class_builder_items)
		TEST_ASSERT(ispath(row["path"], /obj/item), "Item row [json_encode(row)] has no valid item path")
		for(var/slot in row["slots"])
			TEST_ASSERT(slot in GLOB.class_builder_slots, "Item row [row["path"]] uses unknown doll slot [slot]")
	for(var/datum/class_builder_entry/talent/talent as anything in registry.get_kind("talent"))
		TEST_ASSERT_NOTNULL(registry.get_entry(talent.direction, "direction"), "[talent.id] belongs to unknown direction [talent.direction]")
		for(var/required_id in talent.requires)
			TEST_ASSERT_NOTNULL(registry.get_entry(required_id, "talent"), "[talent.id] requires unknown talent [required_id]")
	for(var/datum/job/advclass/custom_class/role as anything in registry.get_roles())
		TEST_ASSERT_NOTNULL(SSjob.GetJobType(role.parent_role), "[role.type] has no parent role")

/// Garbage from an import or a damaged save is type-checked and capped before any rule runs.
/datum/unit_test/class_builder_untrusted_data/Run()
	var/datum/class_builder_build/build = new()
	TEST_ASSERT(!build.deserialize("not a list"), "Text must not deserialize")
	TEST_ASSERT(!build.deserialize(null), "Null must not deserialize")

	var/list/payload = GLOB.class_builder.get_static_payload()
	var/list/limits = payload["limits"]
	var/max_carried = limits["max_carried"]
	var/list/huge = list()
	for(var/i in 1 to max_carried + 20)
		huge += "item:rope"
	var/list/forged = list(
		"name" = "<b>Bold</b>\nname",
		"role" = "/datum/job/advclass/custom_class",
		"stats" = list("str" = "high", "per" = 99),
		"skills" = "everything",
		"talents" = list(5, list(), "tl_unit_test_missing"),
		"equipment" = list("head" = 7, "nowhere" = "item:rope"),
		"bag" = huge,
	)
	TEST_ASSERT(build.deserialize(forged), "A list should deserialize")
	TEST_ASSERT(!findtext(build.name, "<") && !findtext(build.name, "\n"), "Markup and line breaks must be stripped from the name")
	TEST_ASSERT(isnull(build.stats["str"]), "A text stat value must be dropped")
	TEST_ASSERT(!length(build.skills), "A non-list skill map must become empty")
	TEST_ASSERT_EQUAL(length(build.talents), 1, "Only text talent ids survive type checks")
	TEST_ASSERT(isnull(build.equipment["head"]), "A number is not an item id")
	TEST_ASSERT_EQUAL(length(build.bag), max_carried, "Carried lists are capped")
	TEST_ASSERT(!class_builder_valid_role_type(build.role_type), "The abstract custom class is not a role")

	build.role_type = /datum/job/advclass/custom_class/towner
	build.sanitize_entries()
	TEST_ASSERT(!length(build.talents), "Unknown talent ids are dropped")
	TEST_ASSERT(!("nowhere" in build.equipment), "Unknown doll slots are dropped")
	TEST_ASSERT_EQUAL(build.stats["per"], 13, "Stats are clamped to the stat maximum")

/// Over-budget sections are cleared, and what is left follows every rule.
/datum/unit_test/class_builder_enforce_budgets/Run()
	var/datum/class_builder_build/build = new(/datum/job/advclass/custom_class/towner)
	build.sanitize_entries()
	var/list/computed = build.compute(null)
	TEST_ASSERT(!length(computed["errors"]), "A fresh build should be valid")
	TEST_ASSERT_EQUAL(computed["stat_spent"], 0, "A fresh build spends no ability points")

	build.stats["str"] = 12
	computed = build.compute(null)
	TEST_ASSERT_EQUAL(computed["stat_spent"], 4, "Strength costs 2 per step above 10")

	for(var/stat_id in build.stats)
		build.stats[stat_id] = 13
	var/list/reset = build.enforce_budgets(null)
	TEST_ASSERT("stat_over" in reset, "Overspent abilities should be reported")
	computed = build.compute(null)
	TEST_ASSERT(!length(computed["errors"]), "The repaired build should be valid")

/// Each role keeps exactly one active build, and the spawn check reads it from the loaded slot.
/datum/unit_test/class_builder_active_build/Run()
	var/datum/class_builder_build/first = new(/datum/job/advclass/custom_class/towner)
	var/datum/class_builder_build/second = new(/datum/job/advclass/custom_class/towner)
	var/datum/class_builder_build/fighter = new(/datum/job/advclass/custom_class/adventurer/fighter)
	var/list/builds = list(first, second, fighter)

	class_builder_normalize_active(builds)
	TEST_ASSERT(first.spawn_active && !second.spawn_active, "Without a flag the first build of a role is active")
	TEST_ASSERT(fighter.spawn_active, "Every role with builds has an active one")

	second.spawn_active = TRUE
	first.spawn_active = FALSE
	class_builder_normalize_active(builds)
	TEST_ASSERT(second.spawn_active && !first.spawn_active, "A flagged build stays active")

	first.spawn_active = TRUE
	class_builder_normalize_active(builds)
	TEST_ASSERT(first.spawn_active && !second.spawn_active, "Two flags for one role keep only the first")

	var/datum/preferences/prefs = allocate(/datum/preferences)
	prefs.class_builder_builds = builds
	TEST_ASSERT_EQUAL(class_builder_active_build(prefs, /datum/job/advclass/custom_class/towner), first, "The spawn check returns the active build")
	TEST_ASSERT_NULL(class_builder_active_build(prefs, /datum/job/advclass/custom_class), "A role without builds has no active build")

	var/datum/class_builder_build/copied = first.copy()
	TEST_ASSERT(copied.spawn_active, "Copies keep the active flag")
	TEST_ASSERT(!("active" in first.serialize()), "Exported text does not carry the active flag")
