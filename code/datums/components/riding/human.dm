
/// Piggybacks, fireman carries, and RMH's special human mounts.
/datum/component/riding/creature/human
	can_be_driven = FALSE
	riding_speed_multiplier = 1
	vehicle_move_delay = 4

/datum/component/riding/creature/human/Initialize(mob/living/riding_mob, force = FALSE, ride_check_flags = NONE)
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	var/mob/living/carbon/human/human_parent = parent
	// RMH's pony equipment explicitly allows the rider to steer.
	can_be_driven = HAS_TRAIT(human_parent, TRAIT_PONYGIRL_RIDEABLE)
	. = ..()
	human_parent.buckle_lying = (ride_check_flags & CARRIER_NEEDS_ARM) ? 90 : 0

/datum/component/riding/creature/human/handle_buckle(mob/living/rider)
	. = ..()
	var/mob/living/carbon/human/human_parent = parent
	var/carry_slowdown = HUMAN_CARRY_SLOWDOWN
	var/required_strength = 10
	if(human_parent.r_grab?.grabbed == rider)
		required_strength--
	if(human_parent.l_grab?.grabbed == rider)
		required_strength--
	if(GET_MOB_ATTRIBUTE_VALUE(human_parent, STAT_STRENGTH) < required_strength)
		carry_slowdown += 2
	human_parent.add_movespeed_modifier(MOVESPEED_ID_HUMAN_CARRYING, multiplicative_slowdown = carry_slowdown)
	if(ride_check_flags & RIDER_NEEDS_ARMS)
		ADD_TRAIT(rider, TRAIT_UNDENSE, REF(src))

/datum/component/riding/creature/human/handle_unbuckle(mob/living/rider)
	REMOVE_TRAIT(rider, TRAIT_UNDENSE, REF(src))
	. = ..()
	if(length(riders))
		return
	var/mob/living/carbon/human/human_parent = parent
	human_parent.remove_movespeed_modifier(MOVESPEED_ID_HUMAN_CARRYING)
	human_parent.buckle_lying = initial(human_parent.buckle_lying)

/datum/component/riding/creature/human/Destroy(force)
	var/mob/living/carbon/human/human_parent = parent
	. = ..()
	human_parent.remove_movespeed_modifier(MOVESPEED_ID_HUMAN_CARRYING)
	human_parent.buckle_lying = initial(human_parent.buckle_lying)

/datum/component/riding/creature/human/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, PROC_REF(on_host_unarmed_melee))
	RegisterSignal(parent, COMSIG_LIVING_SET_BODY_POSITION, PROC_REF(check_carrier_fall_over))

/datum/component/riding/creature/human/log_riding(mob/living/living_parent, mob/living/rider)
	if(!istype(living_parent) || !istype(rider))
		return

	if(ride_check_flags & RIDER_NEEDS_ARMS) // piggyback
		living_parent.log_message("started giving [rider] a piggyback ride.", LOG_GAME, color="pink")
		rider.log_message("started piggyback riding [living_parent].", LOG_GAME, color="pink")
	else if(ride_check_flags & CARRIER_NEEDS_ARM) // fireman
		living_parent.log_message("started fireman carrying [rider].", LOG_GAME, color="pink")
		rider.log_message("was fireman carried by [living_parent].", LOG_GAME, color="pink")

/// If the carrier shoves the person they're carrying, force the carried mob off
/datum/component/riding/creature/human/proc/on_host_unarmed_melee(mob/living/source, atom/target, proximity, modifiers)
	SIGNAL_HANDLER

	if(source.used_intent?.type == INTENT_DISARM && (target in riders))
		force_dismount(target)
		return COMPONENT_CANCEL_ATTACK_CHAIN
	return NONE

/// If the carrier gets knocked over, force the rider(s) off and see if someone got hurt
/datum/component/riding/creature/human/proc/check_carrier_fall_over(mob/living/carbon/human/human_parent, new_position)
	SIGNAL_HANDLER

	if(new_position != LYING_DOWN)
		return

	for(var/mob/living/rider as anything in riders.Copy())
		human_parent.unbuckle_mob(rider, force = TRUE)
		rider.Paralyze(1 SECONDS)
		rider.Knockdown(4 SECONDS)
		human_parent.visible_message(
			span_danger("[rider] topples off of [human_parent] as they both fall to the ground!"),
			span_warning("You fall to the ground, bringing [rider] with you!"),
			span_hear("You hear two consecutive thuds."),
			COMBAT_MESSAGE_RANGE,
			ignored_mobs = list(rider),
		)
		to_chat(rider, span_danger("[human_parent] falls to the ground, bringing you with [human_parent.p_them()]!"))

/datum/component/riding/creature/human/get_rider_offsets_and_layers(pass_index, mob/offsetter)
	var/mob/living/carbon/human/seat = parent
	if(can_be_driven && HAS_TRAIT(seat, TRAIT_PONYGIRL_RIDEABLE))
		return list(
			TEXT_NORTH = list(0, 6, ABOVE_MOB_LAYER),
			TEXT_SOUTH = list(0, 6, OBJ_LAYER),
			TEXT_EAST = list(-6, 4, ABOVE_MOB_LAYER),
			TEXT_WEST = list(6, 4, ABOVE_MOB_LAYER),
		)
	// fireman carry
	if(seat.buckle_lying)
		return list(
			TEXT_NORTH = list(0, 6, ABOVE_MOB_LAYER),
			TEXT_SOUTH = list(0, 6, OBJ_LAYER),
			TEXT_EAST =  list(0, 6, OBJ_LAYER),
			TEXT_WEST =  list(0, 6, OBJ_LAYER),
		)
	// piggyback
	return list(
		TEXT_NORTH = list( 0, 8, ABOVE_MOB_LAYER),
		TEXT_SOUTH = list( 0, 8, OBJ_LAYER),
		TEXT_EAST =  list(-6, 8, OBJ_LAYER),
		TEXT_WEST =  list( 6, 8, OBJ_LAYER),
	)

/datum/component/riding/creature/human/get_parent_offsets_and_layers()
	return list(
		TEXT_NORTH = list(0, 0),
		TEXT_SOUTH = list(0, 0),
		TEXT_EAST =  list(0, 0),
		TEXT_WEST =  list(0, 0),
	)

/datum/component/riding/creature/human/force_dismount(mob/living/rider, throw_range = 8, throw_speed = 3, gentle = FALSE)
	var/atom/movable/seat = parent
	seat.unbuckle_mob(rider, force = TRUE)
	rider.Paralyze(1 SECONDS)
	rider.Knockdown(4 SECONDS)
	rider.visible_message(
		span_warning("[seat] pushes [rider] off of [seat.p_them()]!"),
		span_warning("[seat] pushes you off of [seat.p_them()]!"),
	)
