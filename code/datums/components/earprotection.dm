/// Adds its protection value to a wearer's natural ear protection.
/datum/component/wearertargeting/earprotection
	signals = list(COMSIG_LIVING_GET_EAR_PROTECTION)
	mobtype = /mob/living/carbon
	proctype = PROC_REF(reducebang)
	valid_slots = list(ITEM_SLOT_HEAD)
	var/protection_amount = EAR_PROTECTION_NORMAL

/datum/component/wearertargeting/earprotection/Initialize(protection_amount = EAR_PROTECTION_NORMAL)
	. = ..()
	src.protection_amount = protection_amount

/datum/component/wearertargeting/earprotection/proc/reducebang(datum/source, list/reflist)
	SIGNAL_HANDLER
	reflist[EAR_PROTECTION_ARG] += protection_amount
