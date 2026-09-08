/datum/element/earhealing
	element_flags = ELEMENT_DETACH
	var/list/user_by_item = list()

/datum/element/earhealing/Attach(datum/target)
	. = ..()
	if(!isitem(target))
		return ELEMENT_INCOMPATIBLE

	RegisterSignal(target, list(COMSIG_ITEM_EQUIPPED, COMSIG_ITEM_DROPPED), PROC_REF(equippedChanged))

/datum/element/earhealing/Detach(datum/target)
	. = ..()
	UnregisterSignal(target, list(COMSIG_ITEM_EQUIPPED, COMSIG_ITEM_DROPPED))
	user_by_item -= target
	if(!length(user_by_item))
		STOP_PROCESSING(SSdcs, src)

/datum/element/earhealing/proc/equippedChanged(datum/source, mob/living/carbon/user, slot)
	SIGNAL_HANDLER
	if((slot & ITEM_SLOT_HEAD) && istype(user))
		if(!length(user_by_item))
			START_PROCESSING(SSdcs, src)
		user_by_item[source] = user
	else
		user_by_item -= source
		if(!length(user_by_item))
			STOP_PROCESSING(SSdcs, src)

/datum/element/earhealing/process(seconds_per_tick)
	for(var/obj/item/item as anything in user_by_item)
		var/mob/living/carbon/user = user_by_item[item]
		if(QDELETED(item) || QDELETED(user))
			user_by_item -= item
			continue
		var/obj/item/organ/ears/ears = user.getorganslot(ORGAN_SLOT_EARS)
		if(!ears || ears.is_failing() || IS_ROBOTIC_ORGAN(ears))
			continue
		ears.adjust_temporary_deafness(-0.5 SECONDS * seconds_per_tick)
		ears.applyOrganDamage(-0.025 * seconds_per_tick)
		CHECK_TICK
	if(!length(user_by_item))
		STOP_PROCESSING(SSdcs, src)
