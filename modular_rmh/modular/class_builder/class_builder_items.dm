// Class builder item pool, grouped by category. One row per item:
//   "path"     item type (required)
//   "cost"     item points, fractional allowed
//   "slots"    paper doll slots it can occupy (see GLOB.class_builder_slots); omit for carry-only items
//   "category" UI group
//   "skill" + "rank"  final skill rank needed to pick it
//   "talent"   talent id needed to pick it
//   "roles"    custom class types allowed; omit for every role
//   "id", "name", "name_ru", "desc", "desc_ru" optional overrides
// Ids default to the item path without /obj/item/ and become save keys.

GLOBAL_LIST_INIT(class_builder_items, list(
	// Head
	list("path" = /obj/item/clothing/head/bardhat, "cost" = 0.5, "slots" = list("head"), "category" = "head"),
	list("path" = /obj/item/clothing/head/helmet/skullcap, "cost" = 1, "slots" = list("head"), "category" = "head"),

	// Neck
	list("path" = /obj/item/clothing/neck/coif, "cost" = 1, "slots" = list("neck"), "category" = "neck"),
	list("path" = /obj/item/storage/belt/pouch/cloth/coins/poor, "cost" = 1, "slots" = list("neck", "beltl", "beltr"), "category" = "neck"),

	// Cloaks
	list("path" = /obj/item/clothing/cloak/raincloak/colored/blue, "cost" = 0, "slots" = list("cloak"), "category" = "cloak"),

	// Armor
	list("path" = /obj/item/clothing/armor/leather/vest, "cost" = 1, "slots" = list("armor"), "category" = "armor"),
	list("path" = /obj/item/clothing/armor/gambeson, "cost" = 2, "slots" = list("armor", "shirt"), "category" = "armor"),
	list("path" = /obj/item/clothing/armor/chainmail, "cost" = 4, "slots" = list("armor"), "category" = "armor", "talent" = "tl_mail_training"),
	list("path" = /obj/item/clothing/armor/plate, "cost" = 9, "slots" = list("armor"), "category" = "armor", "talent" = "tl_plate_training"),

	// Clothing
	list("path" = /obj/item/clothing/shirt/tunic/noblecoat, "cost" = 2, "slots" = list("shirt"), "category" = "clothing"),
	list("path" = /obj/item/clothing/pants/tights/colored/random, "cost" = 0, "slots" = list("pants"), "category" = "clothing"),
	list("path" = /obj/item/clothing/gloves/leather, "cost" = 0.5, "slots" = list("gloves"), "category" = "clothing"),
	list("path" = /obj/item/clothing/shoes/boots, "cost" = 0, "slots" = list("shoes"), "category" = "clothing"),

	// Bags and belts
	list("path" = /obj/item/storage/backpack/satchel, "cost" = 0, "slots" = list("backl", "backr"), "category" = "storage"),
	list("path" = /obj/item/storage/belt/leather/adventurers_subclasses, "cost" = 0, "slots" = list("belt"), "category" = "storage"),
	list("path" = /obj/item/storage/belt/pouch/cloth, "cost" = 0, "slots" = list("beltl", "beltr", "neck"), "category" = "storage"),

	// Weapons
	list("path" = /obj/item/weapon/knife/dagger/steel/special, "cost" = 1, "slots" = list("beltl", "beltr", "r_hand", "l_hand"), "category" = "weapons"),
	list("path" = /obj/item/weapon/sword/short, "cost" = 2, "slots" = list("beltl", "beltr", "r_hand", "l_hand"), "category" = "weapons", "skill" = /datum/attribute/skill/combat/swords, "rank" = 1),
	list("path" = /obj/item/weapon/sword/arming, "cost" = 3, "slots" = list("beltl", "beltr", "r_hand", "l_hand"), "category" = "weapons", "skill" = /datum/attribute/skill/combat/swords, "rank" = 2),
	list("path" = /obj/item/weapon/shield/wood, "cost" = 2, "slots" = list("backl", "backr", "r_hand", "l_hand"), "category" = "weapons", "skill" = /datum/attribute/skill/combat/shields, "rank" = 1),
	list("path" = /obj/item/weapon/scabbard/sword, "cost" = 0, "slots" = list("beltl", "beltr"), "category" = "weapons"),

	// Supplies (carry-only)
	list("path" = /obj/item/flint, "cost" = 0, "category" = "supplies"),
	list("path" = /obj/item/flashlight/flare/torch, "cost" = 0, "slots" = list("r_hand", "l_hand"), "category" = "supplies"),
	list("path" = /obj/item/reagent_containers/glass/bottle/waterskin, "cost" = 0.5, "category" = "supplies"),
	list("path" = /obj/item/rope, "cost" = 0.5, "category" = "supplies"),
))

