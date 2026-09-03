/obj/machinery/light/fueled/smelter
	icon = 'icons/roguetown/misc/forge.dmi'
	name = "stone furnace"
	desc = "A stone furnace, weathered by time and heat."
	icon_state = "cavesmelter0"
	base_state = "cavesmelter"
	anchored = TRUE
	density = TRUE
	climbable = TRUE
	climb_time = 0
	climb_offset = 10
	on = TRUE
	temperature_change = 80
	var/list/ore = list()
	var/maxore = 1
	var/cooking = 0
	var/actively_smelting = FALSE // Are we currently smelting?
	var/max_crucible_temperature = 1850
	fueluse = 30 MINUTES
	crossfire = FALSE

/obj/machinery/light/fueled/smelter/examine(mob/user, params)
	. = ..()
	. += span_info("It can hold up to <b>[maxore] items</b>.")
	if(length(ore) && Adjacent(user))
		. += span_notice("Peeking inside, you can see:")
		for(var/obj/item/item as anything in ore)
			. += span_info("- [item]")

/obj/machinery/light/fueled/smelter/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(istype(tool, /obj/item/weapon/tongs))
		var/obj/item/weapon/tongs/tongs = tool
		if(tongs.held_item)
			try_add_item(tongs.held_item, user, tongs)
		else
			try_retrieve_item(user, tongs)
		return ITEM_INTERACT_SUCCESS

	if(tool.firefuel)
		if(tgui_alert(user, "Fuel \the [name] with [tool]?", "VANDERLIN", list("Fuel", "Smelt")) == "Fuel")
			return NONE

	if(try_add_item(tool, user))
		return ITEM_INTERACT_SUCCESS

	return NONE

/obj/machinery/light/fueled/smelter/proc/try_retrieve_item(mob/living/user, obj/item/weapon/tongs/tongs_used)
	if(actively_smelting)
		to_chat(user, span_warning("[src] is currently smelting. Wait for it to finish, or douse it with water first."))
		return FALSE

	for(var/obj/item/storage/crucible/crucible in contents)
		if(!tongs_used || tongs_used.held_item)
			break
		user.visible_message("[user] starts removing a crucible from [src].", "You start removing a crucible from [src].")
		if(!do_after(user, 1.5 SECONDS, src))
			return FALSE
		tongs_used.set_held_item(crucible)
		if(on)
			tongs_used.heat_held_item(source = "smelter", duration = 20 SECONDS, incoming = 150, max_heat = max_crucible_temperature)
		return TRUE

	if(!length(ore))
		return FALSE
	if(on && !tongs_used)
		to_chat(user, span_warning("It's too hot to retrieve items with your hands."))
		return FALSE
	if(tongs_used?.held_item)
		return FALSE

	var/obj/item/retrieved_item = ore[ore.len]
	ore -= retrieved_item
	if(tongs_used)
		tongs_used.set_held_item(retrieved_item)
		if(on)
			tongs_used.heat_held_item(source = "smelter", duration = 20 SECONDS, incoming = 150, max_heat = max_crucible_temperature)
			if(istype(tongs_used, /obj/item/weapon/tongs/stone))
				tongs_used.take_damage(1, BRUTE, BCLASS_BLUNT)
	else
		user.put_in_hands(retrieved_item)

	user.visible_message(span_info("[user] retrieves [retrieved_item] from [src]."))
	if(user.mind && retrieved_item.smeltresult && !istype(retrieved_item, /obj/item/ore) && retrieved_item.smelted)
		var/boon = user.get_learning_boon(/datum/attribute/skill/craft/smelting)
		var/experience = GET_MOB_ATTRIBUTE_VALUE(user, STAT_INTELLIGENCE) * 2
		if(experience > 0)
			user.adjust_experience(/datum/attribute/skill/craft/smelting, experience * boon, FALSE)
			SEND_SIGNAL(user, COMSIG_ITEM_SMELTED)
	return TRUE

/obj/machinery/light/fueled/smelter/proc/try_add_item(obj/item/smelting_item, mob/living/user, obj/item/weapon/tongs/tongs_used)
	if(istype(smelting_item, /obj/item/storage/crucible))
		for(var/obj/item/storage/crucible/existing_crucible in contents)
			to_chat(user, span_warning("[src] cannot hold another crucible."))
			return FALSE
		if(tongs_used)
			tongs_used.set_held_item(null)
		else if(!user.temporarilyRemoveItemFromInventory(smelting_item))
			return FALSE
		smelting_item.forceMove(src)
		user.visible_message("[user] loads [smelting_item] into [src].", "You load [smelting_item] into [src].")
		return TRUE

	if(!smelting_item.smeltresult)
		return FALSE
	if(length(ore) >= maxore)
		to_chat(user, span_warning("[src] is full."))
		return FALSE
	if(tongs_used)
		tongs_used.set_held_item(null)
	else if(!user.temporarilyRemoveItemFromInventory(smelting_item))
		return FALSE

	smelting_item.forceMove(src)
	ore += smelting_item
	if(!user.mind)
		ore[smelting_item] = SMELTERY_LEVEL_SPOIL
	else
		var/smelter_exp = GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/craft/smelting)
		if(smelter_exp < 6)
			ore[smelting_item] = floor(rand(smelter_exp * 15, max(63, smelter_exp * 25)) / 25)
		else
			ore[smelting_item] = floor(min(3, smelter_exp))
	user.visible_message(span_warning("[user] puts something in [src]."))
	cooking = 0
	return TRUE

// Gaining experience from just retrieving bars with your hands would be a hard-to-patch exploit.
/obj/machinery/light/fueled/smelter/attack_hand(mob/user, list/modifiers)
	if(try_retrieve_item(user))
		return TRUE
	return ..()


/obj/machinery/light/fueled/smelter/process()
	..()
	if(maxore > 1)
		return
	if(!on)
		return
	if(!length(ore))
		return
	if(cooking < 20)
		cooking++
		playsound(src,'sound/misc/smelter_sound.ogg', 50, FALSE)
		actively_smelting = TRUE
		return
	if(cooking == 20)
		for(var/obj/item/I in ore)
			if(I.smeltresult)
				var/obj/item/R = new I.smeltresult(src, ore[I])
				ore -= I
				ore += R
				qdel(I)
		playsound(src,'sound/misc/smelter_fin.ogg', 100, FALSE)
		visible_message(span_notice("[src] finished smelting."))
		cooking = 21
		actively_smelting = FALSE

/obj/machinery/light/fueled/smelter/burn_out()
	cooking = 0
	actively_smelting = FALSE
	..()

/obj/machinery/light/fueled/smelter/great
	icon = 'icons/roguetown/misc/forge.dmi'
	name = "great furnace"
	desc = "The pinnacle of dwarven engineering and the miracle of Malum's blessed fire crystal, allowing for greater alloys to be made."
	icon_state = "smelter0"
	base_state = "smelter"
	anchored = TRUE
	density = TRUE
	maxore = 4
	fueluse = 5 MINUTES
	climbable = FALSE
	max_crucible_temperature = 2000

/obj/machinery/light/fueled/smelter/great/process()
	..()
	if(on)
		if(ore.len)
			if(cooking < 30)
				cooking++
				playsound(src,'sound/misc/smelter_sound.ogg', 50, FALSE)
				actively_smelting = TRUE
			else
				if(cooking == 30)
					var/alloy //moving each alloy to it's own var allows for possible additions later
					var/steelalloy
					var/bronzealloy
					var/blacksteelalloy

					for(var/obj/item/I in ore)
						if(I.smeltresult == /obj/item/ore/coal)
							steelalloy = steelalloy + 1
						if(I.smeltresult == /obj/item/ingot/iron)
							steelalloy = steelalloy + 2
						if(I.smeltresult == /obj/item/ingot/tin)
							bronzealloy = bronzealloy + 1
						if(I.smeltresult == /obj/item/ingot/copper)
							bronzealloy = bronzealloy + 2
						if(I.smeltresult == /obj/item/ingot/silver)
							blacksteelalloy = blacksteelalloy + 1
						if(I.smeltresult == /obj/item/ingot/steel)
							blacksteelalloy = blacksteelalloy + 2

					if(steelalloy == 7)
						maxore = 3
						alloy = /obj/item/ingot/steel_slag
					else if(bronzealloy == 7)
						alloy = /obj/item/ingot/bronze
					else if(blacksteelalloy == 7)
						alloy = /obj/item/ingot/blacksteel
						maxore = 2
					else
						alloy = null
					if(alloy)
						// The smelting quality of all ores added together, divided by the number of ores, and then rounded to the lowest integer (this isn't done until after the for loop)
						var/floor_mean_quality = SMELTERY_LEVEL_SPOIL
						var/ore_deleted = 0
						for(var/obj/item/I in ore)
							floor_mean_quality += ore[I]
							ore_deleted += 1
							ore -= I
							qdel(I)
						floor_mean_quality = floor(floor_mean_quality/ore_deleted)
						for(var/i in 1 to maxore)
							var/obj/item/R = new alloy(src, floor_mean_quality)
							if(alloy == /obj/item/ingot/blacksteel)
								record_round_statistic(STATS_BLACKSTEEL_SMELTED)
							ore += R
					else
						for(var/obj/item/I in ore)
							if(I.smeltresult)
								var/obj/item/R = new I.smeltresult(src, ore[I])
								ore -= I
								ore += R
								qdel(I)
					maxore = initial(maxore)
					playsound(src,'sound/misc/smelter_fin.ogg', 100, FALSE)
					visible_message("<span class='notice'>\The [src] finished smelting.</span>")
					cooking = 31
					actively_smelting = FALSE
