/obj/item/clothing/cloak
	name = "cloak"
	icon = 'icons/roguetown/clothing/cloaks.dmi'
	mob_overlay_icon = 'icons/roguetown/clothing/onmob/cloaks.dmi'
	slot_flags = ITEM_SLOT_CLOAK | ITEM_SLOT_BACK_R
	desc = "A simple cloak covering the body."
	edelay_type = 1
	equip_delay_self = 10
	equip_sound = 'sound/foley/equip/cloak_equip.ogg'
	pickup_sound = 'sound/foley/equip/cloak_take_off.ogg'
	bloody_icon_state = "bodyblood"
	sewrepair = /datum/attribute/skill/misc/sewing/mending
	anvilrepair = null
	abstract_type = /obj/item/clothing/cloak
	smeltresult = /obj/item/fertilizer/ash
	flags_inv = HIDEBUTT

	grid_width = 64
	grid_height = 64
	item_weight = 350 GRAMS

	var/is_rain_protective = FALSE
	/// Whether this cloak creates internal storage during initialization.
	var/has_storage = FALSE
	/// The storage component used when has_storage is enabled.
	var/datum/component/storage/storage_component_path = /datum/component/storage/concrete/grid/cloak

/obj/item/clothing/cloak/Initialize(mapload, ...)
	. = ..()
	if(has_storage && storage_component_path)
		AddComponent(storage_component_path)

/obj/item/clothing/cloak/dropped(mob/living/carbon/human/user)
	..()
	if(QDELETED(src) || !has_storage)
		return
	var/datum/component/storage/storage = GetComponent(/datum/component/storage)
	if(!storage)
		return
	for(var/obj/item/stored_item in storage.contents())
		storage.remove_from_storage(stored_item, get_turf(src))
