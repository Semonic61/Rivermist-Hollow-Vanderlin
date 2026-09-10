// Hunting & Tracking pack - the animal trail chain.
//
// Twilight Axis drove trail respawns from a dedicated SShunting subsystem. That is not allowed
// here ("Never add a new SS* subsystem in RMH" - ai_navigation/modular_guide.md), and it is not
// needed: each spawner schedules its own respawn timer. That also removes the global spawner list
// the subsystem kept, so there is no shared list to leak references into.
//
// Solo hunters only. The party/group-hunt machinery, purchasable hunting maps and the secret
// white-stag category from the original are deliberately left out of this first pass.

/// How long before a used-up trail head reappears where it started.
#define HUNTING_RESPAWN_MIN (4 MINUTES)
#define HUNTING_RESPAWN_MAX (8 MINUTES)
/// Hunting skill (0-6) needed before a trail reveals which category of game it belongs to.
#define HUNT_IDENTIFY_SKILL_REQ 4
/// How far apart consecutive signs sit, before per-skill scatter.
#define HUNT_STEP_DISTANCE 9

/// Groups of areas a single trail is allowed to wander between.
GLOBAL_LIST_INIT(hunting_area_groups, list(
	list(/area/outdoors/woods_safe),
	list(/area/outdoors/bog),
	list(/area/outdoors/mountains, /area/outdoors/mountains/decap),
))

/// Lazily built area type -> its group, so a trail does not walk out of its biome.
GLOBAL_LIST_EMPTY(hunting_area_lookup)

/proc/get_hunting_linked_areas(area_type)
	if(!length(GLOB.hunting_area_lookup))
		for(var/list/group as anything in GLOB.hunting_area_groups)
			for(var/grouped_area in group)
				GLOB.hunting_area_lookup[grouped_area] = group
	return GLOB.hunting_area_lookup[area_type] || list(area_type)

/obj/effect/hunting_track
	name = "disturbed earth"
	desc = "A mound of dirt and broken twigs. Something passed through here recently."
	icon = 'modular_rmh/icons/obj/hunting/animaltracks.dmi'
	icon_state = "hidden"
	anchored = TRUE
	// A fresh trail head is visible to everyone - that is how a hunt gets started at all. Only the
	// links a hunter uncovers afterwards go invisible and become personal to them, in
	// setup_hunter_visibility(). Getting this backwards makes the whole mechanic unreachable.
	invisibility = 0
	mouse_opacity = MOUSE_OPACITY_ICON
	resistance_flags = FIRE_PROOF | UNACIDABLE | ACID_PROOF
	/// How many signs of this chain have been read so far.
	var/trail_depth = 0
	/// How many turfs to try before giving up on a direction.
	var/max_search_attempts = 9
	/// Area types this chain may continue into.
	var/list/linked_areas = list()
	var/static/list/track_types = list("cervine", "small", "ursine", "canine", "suidae")
	/// Icon state locked in for the whole chain, so the trail looks consistent.
	var/locked_track_icon
	var/track_revealed = FALSE
	/// Weakref to the hunter working this chain.
	var/datum/weakref/hunter_ref
	/// What waits at the end.
	var/target_animal_type
	var/datum/hunting_category/hunt_category
	/// Signs to read before the quarry shows itself.
	var/max_trail_depth = 6
	var/min_trail_depth = 4
	var/track_dir
	var/image/hunter_image

/obj/effect/hunting_track/Initialize(mapload)
	. = ..()
	layer = HIGH_LANDMARK_LAYER
	pixel_x = rand(-8, 8)
	pixel_y = rand(-8, 8)

/obj/effect/hunting_track/Destroy()
	clear_hunter_image()
	hunter_ref = null
	hunt_category = null
	return ..()

/obj/effect/hunting_track/proc/clear_hunter_image()
	if(!hunter_image)
		return
	var/mob/living/hunter = hunter_ref?.resolve()
	if(hunter?.client)
		hunter.client.images -= hunter_image
	hunter_image = null

/// Makes this link visible to its hunter alone.
/obj/effect/hunting_track/proc/setup_hunter_visibility()
	var/mob/living/hunter = hunter_ref?.resolve()
	invisibility = INVISIBILITY_MAXIMUM
	if(!hunter?.client)
		hunter_ref = null
		return
	hunter_image = image(icon, src, icon_state, layer)
	hunter_image.color = color
	hunter_image.pixel_x = pixel_x
	hunter_image.pixel_y = pixel_y
	hunter.client.images += hunter_image

/obj/effect/hunting_track/get_mechanics_examine(mob/user)
	. = ..()
	. += span_info("A fresh mound starts a hunt - click it to read the signs. Stand back a tile first.")
	. += span_info("Each sign points at the next one, which only you can see. Follow enough of them to run down the quarry.")
	. += span_info("Higher Hunting skill reads signs faster, wanders less, needs fewer of them, and turns up rarer game.")
	. += span_info("Trail heads come back on their own after a while, where they first appeared.")

/obj/effect/hunting_track/examine(mob/user)
	. = ..()
	if(trail_depth > 0)
		. += span_notice("You are working this trail.")
	if(track_dir)
		. += span_notice("The tracks seem to be heading <b>[dir2text(track_dir)]</b>.")
	if(hunt_category && GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/misc/hunting) >= HUNT_IDENTIFY_SKILL_REQ)
		. += span_notice("You know these signs: <b>[hunt_category.name]</b>.")

/obj/effect/hunting_track/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(!isliving(user))
		return
	if(track_revealed)
		return
	var/mob/living/current_hunter = hunter_ref?.resolve()
	if(current_hunter && user != current_hunter)
		return // Someone else's chain. It is invisible to them anyway; this is the safety net.

	if(trail_depth == 0)
		var/datum/component/hunting_blocker/blocker = user.GetComponent(/datum/component/hunting_blocker)
		if(!blocker)
			blocker = user.AddComponent(/datum/component/hunting_blocker)
		if(!blocker.can_start_hunt())
			return

	if(get_dist(user, src) < 1)
		to_chat(user, span_warning("You are standing on top of it. Step back to see where the trail leads."))
		return

	user.changeNext_move(CLICK_CD_MELEE)
	to_chat(user, span_info("You begin reading the signs..."))

	var/skill = GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/misc/hunting)
	if(!do_after(user, max(1 SECONDS, 4 SECONDS - (skill * 4)), target = src))
		return
	if(track_revealed) // Re-check: do_after sleeps, someone else may have taken it.
		return

	if(!uncover_trail(user))
		to_chat(user, span_warning("The trail goes cold in the brush here."))
		return

	to_chat(user, span_nicegreen("The trail continues further ahead!"))
	track_revealed = TRUE
	if(user.mind)
		var/xp_mod = max(1 + ((GET_MOB_ATTRIBUTE_VALUE(user, STAT_INTELLIGENCE) - 10) / 10), 0.1)
		user.mind.add_sleep_experience(/datum/attribute/skill/misc/hunting, 6 * xp_mod)
	if(trail_depth == 0)
		var/datum/component/hunting_blocker/blocker = user.GetComponent(/datum/component/hunting_blocker)
		blocker?.register_hunt()
	fade_and_die(skill)

/obj/effect/hunting_track/proc/uncover_trail(mob/living/user)
	var/skill = GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/misc/hunting)
	hunter_ref = WEAKREF(user)

	var/base_dx = clamp(x - user.x, -1, 1)
	var/base_dy = clamp(y - user.y, -1, 1)
	if(!base_dx && !base_dy)
		base_dy = 1

	// Straight on first, then break left, then right.
	var/list/search_patterns = list(
		list(base_dx, base_dy),
		list(-base_dy, base_dx),
		list(base_dy, -base_dx),
	)

	var/deviation = clamp(5 - max(skill - 2, 0), 1, 5)

	for(var/list/pattern as anything in search_patterns)
		for(var/attempt in 1 to max_search_attempts)
			var/target_dist = HUNT_STEP_DISTANCE + rand(0, 2)
			var/turf/target_turf = locate(
				x + (pattern[1] * target_dist) + rand(-deviation, deviation),
				y + (pattern[2] * target_dist) + rand(-deviation, deviation),
				z,
			)
			if(!validate_turf(target_turf))
				continue

			if(trail_depth == 0)
				// Leave something behind that will regrow this trail head later.
				new /obj/effect/landmark/hunting_spawner(get_turf(src))
				if(!target_animal_type)
					initialize_hunt_chain(user)

			reveal_track(target_turf)

			if(trail_depth >= max_trail_depth)
				to_chat(user, span_boldwarning("You catch sight of your quarry in the distance!"))
				new /obj/effect/temp_visual/hunting_phantom(target_turf, target_animal_type)
				return TRUE

			var/obj/effect/hunting_track/next_trail = new(target_turf)
			next_trail.hunter_ref = hunter_ref
			next_trail.trail_depth = trail_depth + 1
			next_trail.max_trail_depth = max_trail_depth
			next_trail.target_animal_type = target_animal_type
			next_trail.hunt_category = hunt_category
			next_trail.locked_track_icon = locked_track_icon
			next_trail.linked_areas = linked_areas
			next_trail.color = "#ff9100"
			next_trail.setup_hunter_visibility()
			return TRUE
	return FALSE

/// Turns this link from a hidden mound into a visible print pointing at the next one.
/obj/effect/hunting_track/proc/reveal_track(turf/target_turf)
	if(!locked_track_icon)
		locked_track_icon = pick(track_types)
	clear_hunter_image()

	invisibility = 0
	icon_state = locked_track_icon
	name = "[icon_state] tracks"
	desc = "Fresh prints leading away into the wilderness."
	color = null
	track_dir = get_dir(src, target_turf)

/obj/effect/hunting_track/proc/validate_turf(turf/target_turf)
	if(!target_turf || target_turf.density)
		return FALSE
	if(target_turf.is_blocked_turf())
		return FALSE
	var/area/here = get_area(src)
	var/area/there = get_area(target_turf)
	if(!there)
		return FALSE
	return (there == here) || (there.type in linked_areas)

/obj/effect/hunting_track/proc/fade_and_die(skill = 0)
	addtimer(CALLBACK(src, PROC_REF(start_fade_animation)), 5 SECONDS + (skill * 2 SECONDS))

/obj/effect/hunting_track/proc/start_fade_animation()
	animate(src, alpha = 0, time = 2 SECONDS)
	QDEL_IN(src, 2 SECONDS)

/// Picks what this chain is a trail of, and how long it runs.
/obj/effect/hunting_track/proc/initialize_hunt_chain(mob/living/user)
	var/skill = GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/misc/hunting)
	var/area/here = get_area(src)
	linked_areas = get_hunting_linked_areas(here?.type)

	// Skilled hunters need fewer signs.
	max_trail_depth = clamp(max_trail_depth - max(skill - 3, 0), min_trail_depth, max_trail_depth)

	var/list/cat_weights = list()
	for(var/cat_type as anything in subtypesof(/datum/hunting_category))
		var/datum/hunting_category/category = new cat_type()
		if(!category.can_spawn_in_area(here))
			continue
		var/weight = category.skill_weights[clamp(skill + 1, 1, length(category.skill_weights))]
		var/area_bonus = category.get_area_bonus(here)
		if(area_bonus)
			weight *= (1 + (area_bonus / 100))
		if(weight > 0)
			cat_weights[category] = weight

	hunt_category = length(cat_weights) ? pickweight(cat_weights) : new /datum/hunting_category/low_tier()
	target_animal_type = pickweight(hunt_category.animals)
	locked_track_icon = hunt_category.preferred_tracks[target_animal_type] || pick(track_types)

/// Regrows a trail head where one was used up. Not for mapping - trails plant these themselves.
/obj/effect/landmark/hunting_spawner
	name = "hunting trail spawner"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x4"
	invisibility = INVISIBILITY_MAXIMUM
	anchored = TRUE

/obj/effect/landmark/hunting_spawner/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(respawn_trail)), rand(HUNTING_RESPAWN_MIN, HUNTING_RESPAWN_MAX))

/obj/effect/landmark/hunting_spawner/proc/respawn_trail()
	new /obj/effect/hunting_track(loc)
	qdel(src)

/// Keeps one hunter from carpeting the woods in fresh trail heads.
/datum/component/hunting_blocker
	var/last_hunt_start = 0
	var/hunt_cooldown = 90 SECONDS

/datum/component/hunting_blocker/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/hunting_blocker/proc/can_start_hunt()
	if(world.time < last_hunt_start + hunt_cooldown)
		to_chat(parent, span_warning("You've only just disturbed a fresh trail. Give it [DisplayTimeText(last_hunt_start + hunt_cooldown - world.time)] before scouting another."))
		return FALSE
	return TRUE

/datum/component/hunting_blocker/proc/register_hunt()
	last_hunt_start = world.time

#undef HUNTING_RESPAWN_MIN
#undef HUNTING_RESPAWN_MAX
#undef HUNT_IDENTIFY_SKILL_REQ
#undef HUNT_STEP_DISTANCE
