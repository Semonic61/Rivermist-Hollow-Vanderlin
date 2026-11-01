// Class builder content: roles, stats, skill rules, directions, backgrounds, talents, spells and flaws.
// Ids are save keys: renaming one silently drops it from existing builds.

// ---------------------------------------------------------------------------------------------
// Roles. Test set: Fighter and Towner. Budgets and direction caps per parent role,
// slot limits come from the parent role. cb_free_kit fills doll slots the build left empty.
// ---------------------------------------------------------------------------------------------

/datum/job/advclass/custom_class/adventurer
	abstract_type = /datum/job/advclass/custom_class/adventurer
	exp_types_granted = list(EXP_TYPE_ADVENTURER, EXP_TYPE_COMBAT)
	uses_parent_title = TRUE
	give_bank_account = TRUE
	cb_free_kit = list(
		"shirt" = /obj/item/clothing/shirt/undershirt/colored/random,
		"pants" = /obj/item/clothing/pants/tights/colored/random,
		"shoes" = /obj/item/clothing/shoes/boots,
		"belt" = /obj/item/storage/belt/leather/adventurers_subclasses,
		"backl" = /obj/item/storage/backpack/satchel,
		"beltl" = /obj/item/storage/belt/pouch/cloth/coins/poor,
	)

/datum/job/advclass/custom_class/adventurer/fighter
	title = "Custom Fighter"
	parent_role = /datum/job/adventurer_fighter
	category_tags = list(CAT_ADVENTURER_FIGHTER)
	cb_direction_caps = list("magic" = 0, "miracles" = 0)

/datum/job/advclass/custom_class/towner
	title = "Custom Towner"
	parent_role = /datum/job/towner
	category_tags = list(CAT_TOWNER)
	give_bank_account = 5
	cb_group = "town"
	cb_stat_points = 5
	cb_skill_points = list(CB_POOL_COMBAT = 4, CB_POOL_PEACEFUL = 14, CB_POOL_ADVENTURE = 8)
	cb_direction_points = 6
	cb_item_points = 10
	cb_direction_caps = list("melee" = 2, "ranged" = 2, "magic" = 0, "miracles" = 0)
	cb_free_kit = list(
		"shirt" = /obj/item/clothing/shirt/undershirt/colored/random,
		"pants" = /obj/item/clothing/pants/tights/colored/random,
		"shoes" = /obj/item/clothing/shoes/simpleshoes,
		"belt" = /obj/item/storage/belt/leather/rope,
		"backr" = /obj/item/storage/backpack/satchel/cloth,
		"beltl" = /obj/item/storage/belt/pouch/cloth/coins/poor,
	)

// ---------------------------------------------------------------------------------------------
// Stats (TAT model: base 10, refund floor 8, per-step cost)
// ---------------------------------------------------------------------------------------------

/datum/class_builder_entry/stat/strength
	id = "str"
	name = "Strength"
	name_ru = "Сила"
	attribute_type = STAT_STRENGTH
	cost = 2
	sort_order = 1

/datum/class_builder_entry/stat/perception
	id = "per"
	name = "Perception"
	name_ru = "Восприятие"
	attribute_type = STAT_PERCEPTION
	sort_order = 2

/datum/class_builder_entry/stat/intelligence
	id = "int"
	name = "Intellect"
	name_ru = "Интеллект"
	attribute_type = STAT_INTELLIGENCE
	sort_order = 3

/datum/class_builder_entry/stat/constitution
	id = "con"
	name = "Constitution"
	name_ru = "Телосложение"
	attribute_type = STAT_CONSTITUTION
	sort_order = 4

/datum/class_builder_entry/stat/endurance
	id = "end"
	name = "Endurance"
	name_ru = "Выносливость"
	attribute_type = STAT_ENDURANCE
	sort_order = 5

/datum/class_builder_entry/stat/speed
	id = "spd"
	name = "Speed"
	name_ru = "Скорость"
	attribute_type = STAT_SPEED
	cost = 2
	sort_order = 6

/datum/class_builder_entry/stat/fortune
	id = "for"
	name = "Fortune"
	name_ru = "Удача"
	attribute_type = STAT_FORTUNE
	cost = 0.5
	max_value = 16
	sort_order = 7

// ---------------------------------------------------------------------------------------------
// Skills. Every subtype of a listed branch becomes purchasable in that branch's pool.
// Magic skills are not bought: they come from directions.
// ---------------------------------------------------------------------------------------------

GLOBAL_LIST_INIT(class_builder_skill_branches, list(
	/datum/attribute/skill/combat = CB_POOL_COMBAT,
	/datum/attribute/skill/craft = CB_POOL_PEACEFUL,
	/datum/attribute/skill/labor = CB_POOL_PEACEFUL,
	/datum/attribute/skill/misc = CB_POOL_ADVENTURE,
))

/// Default purchase cap per pool.
GLOBAL_LIST_INIT(class_builder_pool_caps, list(
	CB_POOL_COMBAT = 3,
	CB_POOL_PEACEFUL = 2,
	CB_POOL_ADVENTURE = 4,
))

/// Per-skill cap overrides. 0 hides the skill from the builder.
GLOBAL_LIST_INIT(class_builder_skill_caps, list(
	/datum/attribute/skill/combat/bows = 2,
	/datum/attribute/skill/combat/crossbows = 2,
	/datum/attribute/skill/combat/firearms = 0,
	/datum/attribute/skill/craft/carpentry = 6,
	/datum/attribute/skill/craft/crafting = 6,
	/datum/attribute/skill/misc/athletics = 6,
	/datum/attribute/skill/misc/climbing = 6,
	/datum/attribute/skill/misc/reading = 6,
	/datum/attribute/skill/misc/music = 6,
))

// ---------------------------------------------------------------------------------------------
// Directions (TAT): invested points are both the level that opens talent tiers
// and the currency spent on talents of that direction.
// ---------------------------------------------------------------------------------------------

/datum/class_builder_entry/direction/melee
	id = "melee"
	name = "Melee"
	name_ru = "Ближний бой"
	color = "#c8785a"
	sort_order = 1

/datum/class_builder_entry/direction/ranged
	id = "ranged"
	name = "Ranged"
	name_ru = "Стрельба"
	color = "#a8b45a"
	sort_order = 2

/datum/class_builder_entry/direction/magic
	id = "magic"
	name = "Magic"
	name_ru = "Магия"
	color = "#8a7ad8"
	sort_order = 3
	skill_per_level = list(/datum/attribute/skill/magic/arcane = 0.5)

/datum/class_builder_entry/direction/miracles
	id = "miracles"
	name = "Miracles"
	name_ru = "Чудеса"
	color = "#e0c060"
	sort_order = 4
	skill_per_level = list(/datum/attribute/skill/magic/holy = 0.5)

/datum/class_builder_entry/direction/music
	id = "music"
	name = "Music"
	name_ru = "Музыка"
	color = "#d878b0"
	sort_order = 5

/datum/class_builder_entry/direction/skills
	id = "skills"
	name = "Skills"
	name_ru = "Умения"
	color = "#78a8d8"
	sort_order = 6

/datum/class_builder_entry/direction/survival
	id = "survival"
	name = "Survival"
	name_ru = "Выживание"
	color = "#78b878"
	sort_order = 7

// ---------------------------------------------------------------------------------------------
// Backgrounds (BG3 / D&D 5e), free skill ranks and direction levels
// ---------------------------------------------------------------------------------------------

/datum/class_builder_entry/background/acolyte
	id = "bg_acolyte"
	name = "Acolyte"
	name_ru = "Прислужник"
	desc = "You spent your youth in service to a temple, learning its rites and its scriptures."
	desc_ru = "Юность прошла в услужении храму: обряды, писания, тихие кельи."
	skills = list(/datum/attribute/skill/misc/reading = 1, /datum/attribute/skill/misc/medicine = 1)
	direction_bonus = list("miracles" = 1)

/datum/class_builder_entry/background/criminal
	id = "bg_criminal"
	name = "Criminal"
	name_ru = "Преступник"
	desc = "You know the underbelly of every town and the quickest way out of it."
	desc_ru = "Изнанку любого города вы знаете лучше, чем его площади, и всегда помните, где запасной выход."
	skills = list(/datum/attribute/skill/misc/lockpicking = 1, /datum/attribute/skill/misc/sneaking = 1)
	direction_bonus = list("skills" = 1)

/datum/class_builder_entry/background/folk_hero
	id = "bg_folk_hero"
	name = "Folk Hero"
	name_ru = "Народный герой"
	desc = "You stood up for common folk once, and they have not forgotten."
	desc_ru = "Однажды вы заступились за простой люд, и он этого не забыл."
	skills = list(/datum/attribute/skill/labor/farming = 1, /datum/attribute/skill/misc/athletics = 1)
	direction_bonus = list("survival" = 1)

/datum/class_builder_entry/background/sage
	id = "bg_sage"
	name = "Sage"
	name_ru = "Мудрец"
	desc = "Years among books taught you more than most learn in a lifetime."
	desc_ru = "Годы среди книг дали вам больше, чем иным даёт вся жизнь."
	skills = list(/datum/attribute/skill/misc/reading = 2)
	direction_bonus = list("magic" = 1)

/datum/class_builder_entry/background/soldier
	id = "bg_soldier"
	name = "Soldier"
	name_ru = "Солдат"
	desc = "You served in a company and still keep its drills in your bones."
	desc_ru = "Вы служили в отряде, и строевые приёмы до сих пор сидят в костях."
	skills = list(/datum/attribute/skill/combat/polearms = 1, /datum/attribute/skill/misc/athletics = 1)
	direction_bonus = list("melee" = 1)

/datum/class_builder_entry/background/outlander
	id = "bg_outlander"
	name = "Outlander"
	name_ru = "Чужеземец"
	desc = "You grew up far from towns, among wild beasts and wilder weather."
	desc_ru = "Вы выросли вдали от городов, среди диких зверей и дикой погоды."
	skills = list(/datum/attribute/skill/labor/butchering = 1, /datum/attribute/skill/misc/climbing = 1)
	direction_bonus = list("survival" = 1)

// ---------------------------------------------------------------------------------------------
// Talents. tier = required direction level, cost = direction points.
// ---------------------------------------------------------------------------------------------

/datum/class_builder_entry/talent/steelhearted
	id = "tl_steelhearted"
	name = "Steelhearted"
	name_ru = "Стальное сердце"
	desc = "Gore and dismemberment no longer sour your mood."
	desc_ru = "Кровь и отрубленные конечности больше не портят настроение."
	direction = "melee"
	tier = 1
	cost = 1
	traits = list(TRAIT_STEELHEARTED)

/datum/class_builder_entry/talent/expert_dodger
	id = "tl_expert_dodger"
	name = "Fast Reflexes"
	name_ru = "Быстрые рефлексы"
	direction = "melee"
	tier = 2
	cost = 2
	traits = list(TRAIT_DODGEEXPERT)

/datum/class_builder_entry/talent/mail_training
	id = "tl_mail_training"
	name = "Mail Training"
	name_ru = "Кольчужная выучка"
	direction = "melee"
	tier = 2
	cost = 2
	traits = list(TRAIT_MEDIUMARMOR)

/datum/class_builder_entry/talent/plate_training
	id = "tl_plate_training"
	name = "Plate Training"
	name_ru = "Латная выучка"
	direction = "melee"
	tier = 3
	cost = 3
	traits = list(TRAIT_HEAVYARMOR)
	requires = list("tl_mail_training")

/datum/class_builder_entry/talent/critical_resistance
	id = "tl_critical_resistance"
	name = "Critical Resistance"
	name_ru = "Стойкость к критам"
	direction = "melee"
	tier = 3
	cost = 3
	traits = list(TRAIT_CRITICAL_RESISTANCE)
	excludes = list("fl_critical_weakness")

/datum/class_builder_entry/talent/bardic_training
	id = "tl_bardic_training"
	name = "Bardic Training"
	name_ru = "Бардовская выучка"
	direction = "music"
	tier = 1
	cost = 1
	traits = list(TRAIT_BARDIC_TRAINING)
	skills = list(/datum/attribute/skill/misc/music = 1)

/datum/class_builder_entry/talent/appraiser
	id = "tl_appraiser"
	name = "Appraiser"
	name_ru = "Оценщик"
	desc = "You can tell what goods are worth at a glance."
	desc_ru = "Цену товара вы видите с первого взгляда."
	direction = "skills"
	tier = 1
	cost = 1
	traits = list(TRAIT_SEEPRICES)

/datum/class_builder_entry/talent/empath
	id = "tl_empath"
	name = "Empath"
	name_ru = "Эмпат"
	direction = "skills"
	tier = 2
	cost = 2
	traits = list(TRAIT_EMPATH)

/datum/class_builder_entry/talent/dead_nose
	id = "tl_dead_nose"
	name = "Dead Nose"
	name_ru = "Глухой нос"
	direction = "survival"
	tier = 1
	cost = 1
	traits = list(TRAIT_DEADNOSE)

/datum/class_builder_entry/talent/unleechable
	id = "tl_unleechable"
	name = "Unleechable"
	name_ru = "Невкусная кровь"
	direction = "survival"
	tier = 1
	cost = 1
	traits = list(TRAIT_LEECHIMMUNE)

// Spells: talents of the Magic and Miracles directions. More Magic invested means more spells to pick.

/datum/class_builder_entry/talent/spell_fireball
	id = "sp_fireball"
	name = "Fireball"
	name_ru = "Огненный шар"
	direction = "magic"
	tier = 2
	cost = 2
	is_spell = TRUE
	spells = list(/datum/action/cooldown/spell/projectile/fireball)

/datum/class_builder_entry/talent/spell_vicious_mockery
	id = "sp_vicious_mockery"
	name = "Vicious Mockery"
	name_ru = "Злая насмешка"
	direction = "music"
	tier = 1
	cost = 1
	is_spell = TRUE
	spells = list(/datum/action/cooldown/spell/vicious_mockery)

/datum/class_builder_entry/talent/spell_healing
	id = "sp_healing"
	name = "Healing"
	name_ru = "Исцеление"
	direction = "miracles"
	tier = 1
	cost = 1
	is_spell = TRUE
	spells = list(/datum/action/cooldown/spell/healing)

/datum/class_builder_entry/talent/spell_greater_healing
	id = "sp_greater_healing"
	name = "Greater Healing"
	name_ru = "Великое исцеление"
	direction = "miracles"
	tier = 3
	cost = 3
	is_spell = TRUE
	spells = list(/datum/action/cooldown/spell/healing/greater)
	allowed_patrons = list(/datum/patron/faerun/good_gods/Ilmater, /datum/patron/faerun/good_gods/Lathander)
	requires = list("sp_healing")

// ---------------------------------------------------------------------------------------------
// Flaws: pay direction points
// ---------------------------------------------------------------------------------------------

/datum/class_builder_entry/flaw/bad_mood
	id = "fl_bad_mood"
	name = "Bad Mood"
	name_ru = "Дурной нрав"
	points = 1
	traits = list(TRAIT_BAD_MOOD)

/datum/class_builder_entry/flaw/nude_sleeper
	id = "fl_nude_sleeper"
	name = "Nude Sleeper"
	name_ru = "Спит нагишом"
	points = 1
	traits = list(TRAIT_NUDE_SLEEPER)

/datum/class_builder_entry/flaw/mute
	id = "fl_mute"
	name = "Permanent Mute"
	name_ru = "Немота"
	points = 2
	traits = list(TRAIT_MUTE)
	excludes = list("tl_bardic_training", "sp_vicious_mockery")

/datum/class_builder_entry/flaw/critical_weakness
	id = "fl_critical_weakness"
	name = "Critical Weakness"
	name_ru = "Уязвимость к критам"
	points = 3
	traits = list(TRAIT_CRITICAL_WEAKNESS)
	excludes = list("tl_critical_resistance")

/datum/class_builder_entry/flaw/easy_dismember
	id = "fl_easy_dismember"
	name = "Easy Dismemberment"
	name_ru = "Хрупкие суставы"
	points = 3
	traits = list(TRAIT_EASYDISMEMBER)

/datum/class_builder_entry/flaw/nudist
	id = "fl_nudist"
	name = "Nudist"
	name_ru = "Нудист"
	points = 3
	traits = list(TRAIT_NUDIST)

/datum/class_builder_entry/flaw/pacifist
	id = "fl_pacifist"
	name = "Pacifist"
	name_ru = "Пацифист"
	points = 4
	traits = list(TRAIT_PACIFISM)
