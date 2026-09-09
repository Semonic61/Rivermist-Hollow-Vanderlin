// RMH - Клеймо: one permanent brand per limb, plus a temporary fiery handprint.
// General examine reports only where the mark is; inspect_limb reveals the text.

// A target counts as held still when unconscious, cuffed, buckled, or held in an
// aggressive grab by the person doing the work.
/proc/is_held_still(mob/living/carbon/patient, mob/living/user)
	if(patient.stat >= UNCONSCIOUS || patient.handcuffed || patient.buckled)
		return TRUE
	if(user && user.pulling == patient && user.grab_state >= GRAB_AGGRESSIVE)
		return TRUE
	return FALSE

/obj/item/bodypart
	/// Text burned into this limb. One brand per limb.
	var/brand_text
	/// Precise body zone the brand sits on, used for clothing coverage.
	var/brand_zone
	/// Precise body zone of a temporary fiery handprint.
	var/handprint_zone
	/// world.time the handprint fades at.
	var/handprint_expire = 0

/obj/item/bodypart/proc/zone_is_exposed(zone, mob/user)
	if(!owner || isobserver(user))
		return TRUE
	return get_location_accessible(owner, zone)

/obj/item/bodypart/proc/get_visible_brand_zone(mob/user)
	if(!brand_text || !zone_is_exposed(brand_zone, user))
		return null
	return brand_zone

/obj/item/bodypart/proc/get_visible_handprint_zone(mob/user)
	if(!handprint_zone)
		return null
	if(world.time >= handprint_expire)
		handprint_zone = null
		return null
	if(!zone_is_exposed(handprint_zone, user))
		return null
	return handprint_zone

/obj/item/bodypart/proc/set_handprint(zone, duration)
	handprint_zone = zone
	handprint_expire = world.time + duration

/obj/item/bodypart/proc/clear_brand()
	brand_text = null
	brand_zone = null

/obj/item/bodypart/inspect_limb(mob/user)
	. = ..()
	if(!islist(.))
		return
	var/brand_visible = get_visible_brand_zone(user)
	if(brand_visible)
		. += span_danger("Branded on the [parse_zone(brand_visible)]: <B>\"[uppertext(brand_text)]\"</B>")
	var/hand_visible = get_visible_handprint_zone(user)
	if(hand_visible)
		. += span_danger("A fiery handprint is seared across the [parse_zone(hand_visible)].")

/mob/living/carbon/get_examine_face(mob/user, list/P, list/examine_list)
	. = ..()
	if(!islist(.))
		return
	var/list/lines = list()
	var/handprint_seen = FALSE
	for(var/obj/item/bodypart/part as anything in bodyparts)
		var/brand_zone = part.get_visible_brand_zone(user)
		if(brand_zone)
			lines += span_danger("[capitalize(P[THEY])] [P[HAVE]] a brand burned onto [P[THEIR]] [parse_zone(brand_zone)].")
		if(!handprint_seen && part.get_visible_handprint_zone(user))
			handprint_seen = TRUE
	if(handprint_seen)
		lines += span_danger("There is a fiery handprint seared onto [P[THEM]].")
	if(length(lines))
		. = lines + .

// Only a legendary healer can burn a brand away.
/obj/item/weapon/surgery/cautery/attack(mob/living/target, mob/living/user, list/modifiers)
	if(!iscarbon(target) || !heated || !istype(user.a_intent, INTENT_USE))
		return ..()

	var/mob/living/carbon/patient = target
	var/obj/item/bodypart/limb = patient.get_bodypart(check_zone(user.zone_selected))
	if(!limb || !limb.brand_text)
		return ..()

	if(user.get_skill_level(/datum/skill/misc/medicine) < SKILL_RANK_LEGENDARY)
		to_chat(user, span_warning("Scarring like this is beyond my craft. Only a legendary healer could cut it away cleanly."))
		return

	if(!is_held_still(patient, user))
		to_chat(user, span_warning("[patient] needs to be held still for this."))
		return

	patient.visible_message(span_danger("[user] begins carefully burning the brand from [patient]'s [parse_zone(limb.brand_zone)]..."), \
		span_userdanger("[user] begins burning the brand from your [parse_zone(limb.brand_zone)]!"))

	if(!do_after(user, 15 SECONDS, patient))
		return
	if(QDELETED(patient) || QDELETED(limb) || !limb.brand_text)
		return

	limb.clear_brand()
	patient.apply_damage(10, BURN, limb.body_zone)
	patient.visible_message(span_notice("[user] burns the brand away, leaving only clean scar tissue."), \
		span_notice("The brand is gone. Only smooth scarring remains."))
