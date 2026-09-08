/// How many tiles away from a client ordinary mobs continue processing.
#define MOB_PROCESSING_TILE_RANGE 15

SUBSYSTEM_DEF(mobs)
	name = "Mobs"
	priority = FIRE_PRIORITY_MOBS
	flags = SS_KEEP_TIMING | SS_NO_INIT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	var/list/currentrun = list()
	var/static/list/clients_by_zlevel[][]
	var/static/list/dead_players_by_zlevel[][] = list(list())
	var/static/list/camera_players_by_zlevel[][] = list(list())
	var/static/list/mobs_by_zlevel[][] = list(list())
	var/static/list/cubemonkeys = list()
	var/datum/mob_affix_system/affix_system
	/// Z-levels whose mobs always process, regardless of client proximity.
	var/list/town_z = list()
	var/looked_for_town_z = FALSE

/datum/controller/subsystem/mobs/stat_entry()
	..("P:[GLOB.mob_living_list.len - SSmatthios_mobs.matthios_mobs.len - SSisland_mobs.island_mobs.len]")

/datum/controller/subsystem/mobs/proc/MaxZChanged()
	if (!islist(clients_by_zlevel))
		clients_by_zlevel = new /list(world.maxz,0)
		dead_players_by_zlevel = new /list(world.maxz,0)
		mobs_by_zlevel = new /list(world.maxz,0)
	while (clients_by_zlevel.len < world.maxz)
		clients_by_zlevel.len++
		clients_by_zlevel[clients_by_zlevel.len] = list()
		dead_players_by_zlevel.len++
		dead_players_by_zlevel[dead_players_by_zlevel.len] = list()
		camera_players_by_zlevel.len++
		camera_players_by_zlevel[camera_players_by_zlevel.len] = list()
		mobs_by_zlevel.len++
		mobs_by_zlevel[mobs_by_zlevel.len] = list()

/datum/controller/subsystem/mobs/proc/MaxZDec()
	if (!islist(clients_by_zlevel))
		clients_by_zlevel = new /list(world.maxz,0)
		dead_players_by_zlevel = new /list(world.maxz,0)
		camera_players_by_zlevel = new /list(world.maxz,0)
		mobs_by_zlevel = new /list(world.maxz,0)
	while (clients_by_zlevel.len > world.maxz)
		clients_by_zlevel.len--
		dead_players_by_zlevel.len--
		camera_players_by_zlevel.len--
		mobs_by_zlevel.len--

/datum/controller/subsystem/mobs/fire(resumed = 0)
	var/seconds = wait * 0.1

	if(!looked_for_town_z)
		town_z = SSmapping.levels_by_trait(ZTRAIT_TOWN)
		looked_for_town_z = TRUE
		// Controllers determine their initial status before this lazy map-trait cache exists.
		// Re-evaluate town controllers once so always-active levels cannot remain stuck OFF.
		for(var/z_index in town_z)
			if(z_index > GLOB.ai_controllers_by_zlevel.len)
				continue
			for(var/datum/ai_controller/controller as anything in GLOB.ai_controllers_by_zlevel[z_index])
				controller.reset_ai_status()

	if (!resumed)
		src.currentrun = build_currentrun()

	var/list/currentrun = src.currentrun
	var/times_fired = src.times_fired

	while(currentrun.len)
		var/mob/living/L = currentrun[currentrun.len]
		currentrun.len--

		if(!L || QDELETED(L))
			GLOB.mob_living_list.Remove(L)
			continue

		if(L.stat == DEAD)
			L.DeadLife(seconds, times_fired)
		else
			L.Life(seconds, times_fired)

		if (MC_TICK_CHECK)
			return

/// Builds the ordinary-mob processing list from clients, nearby spatial-grid cells, and always-active town levels.
/datum/controller/subsystem/mobs/proc/build_currentrun()
	. = list()
	var/list/seen_cells = list()
	for(var/z_index in 1 to clients_by_zlevel.len)
		if(z_index in town_z)
			continue
		var/list/clients_here = clients_by_zlevel[z_index]
		if(!length(clients_here))
			continue
		. |= clients_here
		for(var/mob/living/client_mob as anything in clients_here)
			var/turf/client_turf = get_turf(client_mob)
			if(!client_turf)
				continue
			for(var/datum/spatial_grid_cell/cell as anything in SSspatial_grid.get_cells_in_range(client_turf, MOB_PROCESSING_TILE_RANGE))
				if(seen_cells[cell])
					continue
				seen_cells[cell] = TRUE
				for(var/atom/hearable as anything in cell.hearing_contents)
					var/mob/living/nearby_mob = hearable
					if(!istype(nearby_mob) || nearby_mob.client)
						continue
					. |= nearby_mob

	for(var/z_index in town_z)
		if(z_index > mobs_by_zlevel.len)
			continue
		. |= mobs_by_zlevel[z_index]

	// These mobs have dedicated processing subsystems.
	. -= SSmatthios_mobs.matthios_mobs
	. -= SSisland_mobs.island_mobs

/datum/controller/subsystem/mobs/proc/enhance_mob(mob/living/mob, delve_level = 1)
	if(!affix_system)
		affix_system = new()
	affix_system.enhance_mob(mob, delve_level - 1)

/datum/controller/subsystem/mobs/proc/enhance_mob_elite(mob/living/mob, delve_level = 1, bonus_affixes = 0)
	if(!affix_system)
		affix_system = new()
	affix_system.enhance_mob(mob, max(0, delve_level - 1), bonus_affixes)

#undef MOB_PROCESSING_TILE_RANGE
