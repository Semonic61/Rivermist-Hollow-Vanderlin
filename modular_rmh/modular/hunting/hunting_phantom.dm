// Hunting & Tracking pack - the shape in the brush at the end of a trail.
// A few seconds of warning before the quarry actually materializes, so the hunter can ready a bow
// or think better of it.

/obj/effect/temp_visual/hunting_phantom
	name = "approaching quarry"
	desc = "Something is moving in the brush..."
	icon_state = ""
	layer = MOB_LAYER
	plane = GAME_PLANE
	alpha = 50
	anchored = TRUE
	duration = 20 SECONDS
	mouse_opacity = MOUSE_OPACITY_ICON
	var/mob_type_to_spawn
	var/spawn_delay = 15 SECONDS

/obj/effect/temp_visual/hunting_phantom/Initialize(mapload, target_mob_path, custom_delay)
	. = ..()
	if(!ispath(target_mob_path, /mob/living))
		return INITIALIZE_HINT_QDEL
	if(custom_delay)
		spawn_delay = custom_delay

	mob_type_to_spawn = target_mob_path
	var/mob/living/path_cast = target_mob_path
	icon = initial(path_cast.icon)
	icon_state = initial(path_cast.icon_state)
	color = "#777777"

	animate(src, alpha = 200, time = spawn_delay, easing = EASE_IN)
	addtimer(CALLBACK(src, PROC_REF(finalize_spawn)), spawn_delay)

/obj/effect/temp_visual/hunting_phantom/proc/finalize_spawn()
	var/turf/spawn_turf = get_turf(src)
	if(spawn_turf)
		// Spawned with its own type's default faction on purpose: tagging it with an extra
		// faction string would change how it reads other mobs, and nothing here reads the tag.
		var/mob/living/real_mob = new mob_type_to_spawn(spawn_turf)
		spawn_turf.visible_message(span_boldwarning("[real_mob] breaks from the brush!"))
	qdel(src)
