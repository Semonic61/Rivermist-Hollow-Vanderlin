/// Jdeer passengers sit higher without baking a translation into their posture transform.
/datum/component/riding/creature/human/update_rider_layer_and_offsets(dir, passindex, mob/living/rider, animate = FALSE)
	. = ..()
	var/mob/living/carbon/human/carrier = parent
	if(istype(carrier.get_bodypart(BODY_ZONE_TAUR), /obj/item/bodypart/taur/jdeer))
		var/list/current_offsets = rider.mob_offsets["jdeer_rider"]
		if(current_offsets?["y"] != 16)
			rider.set_mob_offsets("jdeer_rider", _y = 16)
	else if(rider.mob_offsets["jdeer_rider"])
		rider.reset_offsets("jdeer_rider")

/datum/component/riding/creature/human/restore_rider_layer_and_offsets(mob/living/buckled_mob)
	buckled_mob.reset_offsets("jdeer_rider")
	return ..()
