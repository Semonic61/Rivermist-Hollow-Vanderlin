/// Event-driven, glazed public decree reader; no per-tick processing or local copies.
/obj/structure/rmh_decree_board
	name = "decree board"
	desc = "A glazed, enchanted board displaying the ruler's current decrees."
	icon = 'modular_rmh/icons/obj/structures/laws_objs.dmi'
	icon_state = "decree_board_1"
	anchored = TRUE
	density = FALSE
	max_integrity = 200
	integrity_failure = 0.5
	break_sound = "glassbreak"
	attacked_sound = 'sound/combat/hits/onglass/glasshit.ogg'
	SET_BASE_PIXEL(0, 32)
	var/tmp/datum/rmh_law_documents/documents
	var/tmp/announcement_timer

/obj/structure/rmh_decree_board/Initialize(mapload)
	. = ..()
	documents = rmh_get_law_documents()
	RegisterSignal(documents, COMSIG_RMH_DECREES_CHANGED, PROC_REF(on_decrees_changed))
	RegisterSignal(documents, COMSIG_PARENT_QDELETING, PROC_REF(on_documents_deleted))
	update_appearance()
	schedule_announcement()

/obj/structure/rmh_decree_board/Destroy()
	if(documents)
		UnregisterSignal(documents, list(COMSIG_RMH_DECREES_CHANGED, COMSIG_PARENT_QDELETING))
	documents = null
	if(announcement_timer)
		deltimer(announcement_timer)
		announcement_timer = null
	return ..()

/obj/structure/rmh_decree_board/proc/on_decrees_changed(datum/source)
	SIGNAL_HANDLER
	update_appearance()
	SStgui.update_uis(src)

/obj/structure/rmh_decree_board/proc/on_documents_deleted(datum/source)
	SIGNAL_HANDLER
	documents = null
	if(announcement_timer)
		deltimer(announcement_timer)
		announcement_timer = null
	update_appearance()
	SStgui.close_uis(src)

/obj/structure/rmh_decree_board/proc/schedule_announcement()
	if(documents && !announcement_timer)
		announcement_timer = addtimer(CALLBACK(src, PROC_REF(announce_count)), 10 MINUTES, TIMER_STOPPABLE)

/obj/structure/rmh_decree_board/proc/count_message()
	var/count = length(documents?.decrees)
	if(!count)
		return null
	var/message = "Действующих указов: [count]."
	return obj_broken ? "Д-д-действующих у-указов: [count]... кх-х-х..." : message

/obj/structure/rmh_decree_board/proc/announce_count()
	announcement_timer = null
	var/message = count_message()
	if(message)
		Shake(1, 1, 25)
		// Temporary cue: see STAGE_F_REPORT.md before replacing the asset.
		playsound(src, RMH_LAW_SOUND_BOARD, 60, FALSE)
		say(message, spans = list("info"))
	schedule_announcement()

/obj/structure/rmh_decree_board/update_icon_state()
	. = ..()
	icon_state = obj_broken ? "decree_board_3" : (length(documents?.decrees) ? "decree_board_2" : "decree_board_1")

/obj/structure/rmh_decree_board/atom_break(damage_flag, silent)
	. = ..()
	update_appearance()
	SStgui.close_uis(src)

/obj/structure/rmh_decree_board/atom_fix()
	. = ..()
	update_appearance()

/obj/structure/rmh_decree_board/proc/can_read_decrees(mob/user)
	return documents && !obj_broken && user && in_range(user, src) && user.can_read(src, TRUE) \
		&& user.can_perform_action(src, NEED_LITERACY|FORBID_TELEKINESIS_REACH)

/obj/structure/rmh_decree_board/attack_hand(mob/user)
	. = ..()
	if(. || !can_read_decrees(user))
		return
	ui_interact(user)

/obj/structure/rmh_decree_board/ui_status(mob/user, datum/ui_state/state)
	if(!can_read_decrees(user))
		return UI_CLOSE
	return ..()

/obj/structure/rmh_decree_board/ui_interact(mob/user, datum/tgui/ui)
	if(!can_read_decrees(user))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RmhDecree", name)
		ui.set_autoupdate(FALSE)
		ui.open()

/obj/structure/rmh_decree_board/ui_data(mob/user)
	return list("language" = rmh_law_ui_language(user), "kind" = "board", "mode" = "read", "decrees" = can_read_decrees(user) ? documents.decrees : list())

/obj/structure/rmh_decree_board/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	..()
	// Reading/search/language are local; forged editing actions never reach THROAT.
	return FALSE

/// Shards inherit /glass, but are not repair panes.
/obj/structure/rmh_decree_board/proc/is_repair_glass(obj/item/material)
	if(!material || QDELETED(material))
		return FALSE
	if(material.type == /obj/item/natural/glass)
		return TRUE
	if(istype(material, /obj/item/natural/bundle/glass))
		var/obj/item/natural/bundle/glass/bundle = material
		return bundle.amount > 0
	return FALSE

/obj/structure/rmh_decree_board/proc/can_repair(mob/user, obj/item/material)
	return obj_broken && is_repair_glass(material) && user && user.is_holding(material) \
		&& in_range(user, src) && user.can_perform_action(src, NEED_DEXTERITY|FORBID_TELEKINESIS_REACH)

/obj/structure/rmh_decree_board/attackby(obj/item/material, mob/user, list/modifiers)
	if(!can_repair(user, material))
		return ..()
	to_chat(user, span_notice(rmh_law_feedback(user, "I begin replacing the board's broken glass.")))
	if(!do_after(user, 5 SECONDS, src) || QDELETED(src) || QDELETED(user) || !can_repair(user, material))
		return TRUE
	// No sleep between final checks, consumption and repair: concurrent repairs cost once.
	if(istype(material, /obj/item/natural/bundle/glass))
		var/obj/item/natural/bundle/glass/bundle = material
		bundle.amount--
		if(!bundle.amount)
			qdel(bundle)
		else
			bundle.update_bundle()
	else
		if(!user.temporarilyRemoveItemFromInventory(material))
			return TRUE
		qdel(material)
	atom_integrity = max_integrity
	atom_fix()
	var/turf/debris_turf = get_turf(user)
	new /obj/item/natural/glass/shard(debris_turf)
	new /obj/effect/decal/cleanable/debris/glass(debris_turf)
	playsound(src, 'sound/misc/glassknock.ogg', 50, TRUE)
	return TRUE

/// PNG artwork shared by the decree board and physical-poster reader.
/datum/asset/simple/rmh_decree_backgrounds
	assets = list(
		"rmh-decree-board-main.png" = 'modular_rmh/modular/law_documents/assets/decree_board_main.png',
		"rmh-decree-board-button.png" = 'modular_rmh/modular/law_documents/assets/decree_board_button.png',
		"rmh-decree-poster-main.png" = 'modular_rmh/modular/law_documents/assets/decree_poster_main.png',
		"rmh-decree-poster-button.png" = 'modular_rmh/modular/law_documents/assets/decree_poster_button.png',
	)

/obj/structure/rmh_decree_board/ui_assets(mob/user)
	. = ..()
	. += get_asset_datum(/datum/asset/simple/rmh_decree_backgrounds)

// --- posters.dm ---
#define RMH_POSTER_FORGE_DELAY (0.5 SECONDS)

/// Private physical snapshot: no publication subscriptions or round registry.
/obj/item/rmh_decree_poster
	name = "blank decree poster"
	desc = "A sheet of prepared parchment."
	icon = 'modular_rmh/icons/obj/structures/laws_objs.dmi'
	icon_state = "decree_poster_1"
	w_class = WEIGHT_CLASS_TINY
	max_integrity = 30
	resistance_flags = FLAMMABLE
	item_flags = NOBLUDGEON
	force = 0
	throwforce = 0
	var/list/snapshot
	var/damaged = FALSE
	var/content_revision = 0
	var/tmp/prompt_mode = "read"
	var/tmp/prompt_token = 0
	var/tmp/forging = FALSE
	var/tmp/datum/weakref/editor_ref
	var/tmp/datum/weakref/source_ref
	var/tmp/datum/weakref/tool_ref

/obj/item/rmh_decree_poster/update_icon_state()
	. = ..()
	icon_state = damaged ? "decree_poster_2" : (snapshot ? "decree_poster_3" : "decree_poster_1")

/obj/item/rmh_decree_poster/Destroy()
	snapshot = null
	editor_ref = null
	source_ref = null
	tool_ref = null
	return ..()

/obj/item/rmh_decree_poster/examine(mob/user)
	. = ..()
	if(damaged)
		. += span_notice(rmh_ui_text(user, "Края порваны, но надпись всё ещё читается.", "Its edges are torn, but the writing is still legible."))


/obj/item/rmh_decree_poster/proc/tear_edges()
	damaged = TRUE
	atom_integrity = min(atom_integrity, max_integrity / 2)
	update_appearance(UPDATE_ICON_STATE)

/obj/item/rmh_decree_poster/proc/copy_decree(list/entry)
	if(snapshot || !islist(entry) || !rmh_law_text(entry["text"], RMH_LAW_MAX_TEXT, FALSE))
		return FALSE
	var/english = isnull(entry["text_en"]) ? "" : entry["text_en"]
	if(!rmh_law_text(english, RMH_LAW_MAX_TEXT))
		return FALSE
	content_revision++
	snapshot = list("id" = "poster", "text" = entry["text"], "text_en" = english, "revision" = content_revision)
	refresh_title()
	desc = "A parchment bearing a copy of a decree."
	update_appearance(UPDATE_ICON_STATE)
	return TRUE

/// Only explicit physical forgery may replace a filled snapshot.
/obj/item/rmh_decree_poster/proc/replace_forgery(text, english, rank, expected_revision)
	if(!snapshot || expected_revision != content_revision || !rmh_law_text(text, RMH_LAW_MAX_TEXT, FALSE) || !rmh_law_text(english, RMH_LAW_MAX_TEXT))
		return FALSE
	content_revision++
	snapshot = list("id" = "poster", "text" = text, "text_en" = english, "revision" = content_revision, \
		"marks" = rmh_poster_marks(text, rank), "marks_en" = rmh_poster_marks(english, rank))
	refresh_title()
	return TRUE

/// Legacy get_skill_level returns ranks (0..6), not the attribute's 0..60 scale.
/proc/rmh_poster_marks(text, rank)
	var/chance = clamp((SKILL_RANK_EXPERT - rank) * 10, 0, 40)
	var/list/marks = list()
	var/count = length_char(text)
	marks.len = count
	if(!count)
		return marks
	for(var/index in 1 to count)
		var/letter = copytext_char(text, index, index + 1)
		marks[index] = uppertext(letter) != lowertext(letter) && prob(chance) ? pick(1, 2) : 0
	return marks

/obj/item/rmh_decree_poster/proc/can_handle(mob/user)
	if(!user)
		return FALSE
	var/atom/movable/host = ui_host(user)
	if(host != src)
		var/obj/structure/rmh_decree_poster/mount = host
		if(!istype(mount) || mount.poster != src || !isturf(mount.loc))
			return FALSE
	else if(!user.is_holding(src) && !isturf(loc))
		return FALSE
	// Adjacent does not recurse from an item through a structure container.
	return host.Adjacent(user) && user.can_perform_action(host, NEED_DEXTERITY|FORBID_TELEKINESIS_REACH)

/obj/item/rmh_decree_poster/proc/can_read_poster(mob/user)
	return can_handle(user) && user.can_read(ui_host(user), TRUE)

/obj/item/rmh_decree_poster/proc/copy_source()
	var/obj/structure/source = source_ref?.resolve()
	if(!istype(source) || source.obj_broken)
		return null
	if(istype(source, /obj/structure/rmh_scribe_stand))
		var/obj/structure/rmh_scribe_stand/stand = source
		return stand.documents
	if(istype(source, /obj/structure/rmh_decree_board))
		var/obj/structure/rmh_decree_board/board = source
		return board.documents
	return null

/obj/item/rmh_decree_poster/proc/can_copy(mob/user)
	var/obj/structure/source = source_ref?.resolve()
	return !snapshot && user?.is_holding(src) && can_read_poster(user) && source \
		&& source.Adjacent(user) && user.can_read(source, TRUE) && copy_source()

/obj/item/rmh_decree_poster/proc/can_forge(mob/user)
	var/obj/item/tattoo_machine/tool = tool_ref?.resolve()
	return snapshot && can_read_poster(user) && istype(tool) && user.is_holding(tool)

/obj/item/rmh_decree_poster/proc/reset_prompt()
	prompt_mode = "read"
	prompt_token++
	editor_ref = null
	source_ref = null
	tool_ref = null
	forging = FALSE

/obj/item/rmh_decree_poster/pre_attack(atom/target, mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(istype(target, /obj/structure/rmh_scribe_stand) || istype(target, /obj/structure/rmh_decree_board))
		if(snapshot || !user.is_holding(src) || !can_read_poster(user) || !target.Adjacent(user))
			return TRUE
		SStgui.close_uis(src)
		source_ref = WEAKREF(target)
		if(!can_copy(user))
			reset_prompt()
			return TRUE
		editor_ref = WEAKREF(user)
		prompt_mode = "copy"
		ui_interact(user)
		return TRUE
	if(iswallturf(target))
		mount_on_wall(user, target)
		return TRUE

/obj/item/rmh_decree_poster/attackby(obj/item/tool, mob/user, list/modifiers)
	if(istype(tool, /obj/item/tattoo_machine))
		begin_forgery(user, tool)
		return TRUE
	return ..()

/obj/item/rmh_decree_poster/proc/begin_forgery(mob/user, obj/item/tattoo_machine/tool)
	if(!snapshot || forging || !can_read_poster(user) || !user.is_holding(tool))
		return FALSE
	SStgui.close_uis(src)
	editor_ref = WEAKREF(user)
	tool_ref = WEAKREF(tool)
	prompt_mode = "forge"
	ui_interact(user)
	return TRUE

/obj/item/rmh_decree_poster/attack_self(mob/user, list/modifiers)
	. = ..()
	if(!. && snapshot)
		ui_interact(user)

/obj/item/rmh_decree_poster/ui_host(mob/user)
	if(istype(loc, /obj/structure/rmh_decree_poster))
		return loc
	return ..()

/obj/item/rmh_decree_poster/ui_status(mob/user, datum/ui_state/state)
	if(!can_read_poster(user))
		return UI_CLOSE
	if(editor_ref?.resolve() == user)
		if(prompt_mode == "copy" && !can_copy(user))
			return UI_CLOSE
		if(prompt_mode == "forge" && !can_forge(user))
			return UI_CLOSE
	if(istype(loc, /obj/structure/rmh_decree_poster))
		// The visible mount supplies the normal distance/status checks.
		return loc.ui_status(user, state)
	return ..()

/obj/item/rmh_decree_poster/ui_interact(mob/user, datum/tgui/ui)
	if(!can_read_poster(user))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RmhDecree", name)
		ui.set_autoupdate(FALSE)
		ui.open()

/obj/item/rmh_decree_poster/ui_close(mob/user)
	. = ..()
	if(editor_ref?.resolve() == user)
		reset_prompt()

/obj/item/rmh_decree_poster/ui_data(mob/user)
	if(!can_read_poster(user))
		return list("language" = rmh_law_ui_language(user), "kind" = "poster", "mode" = "read", "decrees" = list())
	var/mode = editor_ref?.resolve() == user ? prompt_mode : "read"
	var/datum/rmh_law_documents/store = mode == "copy" ? copy_source() : null
	return list("language" = rmh_law_ui_language(user), "kind" = "poster", "mode" = mode, "token" = prompt_token, "revision" = content_revision, \
		"epoch" = store?.epoch, "busy" = forging, \
		"decrees" = store ? store.decrees : (snapshot ? list(snapshot) : list()))

/obj/item/rmh_decree_poster/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = ui?.user
	if(!user || usr != user || state.can_use_topic(ui_host(user), user) != UI_INTERACTIVE \
		|| editor_ref?.resolve() != user || params["token"] != prompt_token || params["revision"] != content_revision || forging)
		return FALSE
	if(action == "copy" && prompt_mode == "copy" && can_copy(user))
		var/datum/rmh_law_documents/store = copy_source()
		if(params["epoch"] != store.epoch)
			return FALSE
		var/list/chosen
		for(var/list/entry as anything in store.decrees)
			if(entry["id"] == params["id"] && entry["revision"] == params["decree_revision"])
				chosen = entry
				break
		if(!chosen)
			to_chat(user, span_warning(rmh_law_feedback(user, "The decree changed or was revoked. Choose from the current list.")))
			SStgui.update_uis(src)
			return FALSE
		if(!copy_decree(chosen))
			to_chat(user, span_warning(rmh_law_feedback(user, "This decree exceeds the poster's text limit.")))
			return FALSE
		SStgui.close_uis(src)
		log_game("[key_name(user)] copied a decree onto [src] at [AREACOORD(src)].")
		ui_interact(user)
		return FALSE
	if(action == "forge" && prompt_mode == "forge" && can_forge(user))
		var/text = params["text"]
		var/english = params["text_en"]
		if(!rmh_law_text(text, RMH_LAW_MAX_TEXT, FALSE) || !rmh_law_text(english, RMH_LAW_MAX_TEXT))
			return FALSE
		var/token = prompt_token
		var/revision = content_revision
		var/atom/original_location = loc
		forging = TRUE
		SStgui.update_uis(src)
		var/completed = do_after(user, (length_char(text) + length_char(english)) * RMH_POSTER_FORGE_DELAY, ui_host(user))
		if(QDELETED(src))
			return FALSE
		if(token != prompt_token)
			return FALSE
		forging = FALSE
		if(!completed || QDELETED(user) || original_location != loc || !can_forge(user) || revision != content_revision)
			SStgui.update_uis(src)
			return FALSE
		if(!replace_forgery(text, english, user.get_skill_level(/datum/attribute/skill/misc/reading), revision))
			return FALSE
		log_game("[key_name(user)] forged [src] at [AREACOORD(src)].")
		SStgui.close_uis(src)
		ui_interact(user)
	return FALSE

/obj/item/rmh_decree_poster/proc/mount_on_wall(mob/user, turf/closed/wall/wall)
	if(!snapshot || forging || !user?.is_holding(src) || !can_handle(user) || !iswallturf(wall))
		return FALSE
	var/turf/floor = get_turf(user)
	if(user.loc != floor || !isopenturf(floor) || get_dist(floor, wall) != 1 || !(get_dir(floor, wall) in GLOB.cardinals))
		return FALSE
	for(var/obj/structure/rmh_decree_poster/other in floor)
		if(other.attached_wall == wall)
			to_chat(user, span_warning(rmh_law_feedback(user, "There is already a poster on this face of the wall.")))
			return FALSE
	SStgui.close_uis(src)
	var/obj/structure/rmh_decree_poster/mount = new(floor)
	if(!user.transferItemToLoc(src, mount))
		qdel(mount)
		return FALSE
	if(!mount.attach_poster(src, wall))
		forceMove(floor)
		user.put_in_hands(src)
		qdel(mount)
		return FALSE
	return TRUE

/// The mount owns the one sheet; removing it transfers that same sheet back.
/obj/structure/rmh_decree_poster
	name = "decree poster"
	desc = "A decree posted on the wall."
	icon = 'modular_rmh/icons/obj/structures/laws_objs.dmi'
	icon_state = "decree_poster_1"
	anchored = TRUE
	density = FALSE
	interaction_flags_atom = NONE
	resistance_flags = FLAMMABLE
	max_integrity = 30
	var/tmp/obj/item/rmh_decree_poster/poster
	var/tmp/turf/closed/wall/attached_wall


/obj/structure/rmh_decree_poster/update_icon_state()
	. = ..()
	icon_state = poster?.damaged ? "decree_poster_2" : "decree_poster_1"

/obj/structure/rmh_decree_poster/Initialize(mapload)
	. = ..()
	// Core steal_action only handles mobs. Intercept STEAL locally before that route.
	RegisterSignal(src, COMSIG_ATOM_CLICKEDON, PROC_REF(on_poster_click))

/obj/structure/rmh_decree_poster/proc/on_poster_click(datum/source, mob/living/user, list/modifiers)
	SIGNAL_HANDLER
	if(!isliving(user) || !LAZYACCESS(modifiers, MIDDLE_CLICK) || !istype(user.mmb_intent, INTENT_STEAL))
		return NONE
	if(user.next_move <= world.time)
		try_steal(user)
	return COMSIG_MOB_CANCEL_CLICKON

/obj/structure/rmh_decree_poster/proc/try_steal(mob/living/user)
	if(!poster || !isliving(user) || !user.Adjacent(src) || !user.can_perform_action(src, NEED_DEXTERITY|FORBID_TELEKINESIS_REACH))
		return FALSE
	var/tear = istype(user.rmb_intent, /datum/rmb_intent/strong)
	if(!tear && !istype(user.rmb_intent, /datum/rmb_intent/weak))
		return FALSE
	add_fingerprint(user)
	user.changeNext_move(CLICK_CD_MELEE)
	detach_poster(user, tear)
	return TRUE

/obj/structure/rmh_decree_poster/proc/attach_poster(obj/item/rmh_decree_poster/sheet, turf/closed/wall/wall)
	if(poster || !sheet?.snapshot || sheet.loc != src || !iswallturf(wall))
		return FALSE
	var/direction = get_dir(src, wall)
	if(get_dist(src, wall) != 1 || !(direction in GLOB.cardinals))
		return FALSE
	poster = sheet
	name = sheet.name
	attached_wall = wall
	dir = direction
	base_pixel_x = (direction == EAST ? 32 : (direction == WEST ? -32 : 0))
	base_pixel_y = (direction == NORTH ? 32 : (direction == SOUTH ? -32 : 0))
	pixel_x = base_pixel_x
	pixel_y = base_pixel_y
	RegisterSignal(sheet, COMSIG_PARENT_QDELETING, PROC_REF(on_sheet_deleted))
	RegisterSignal(sheet, COMSIG_MOVABLE_MOVED, PROC_REF(on_sheet_moved))
	RegisterSignal(wall, list(COMSIG_TURF_CHANGE, COMSIG_PARENT_QDELETING), PROC_REF(on_wall_changed))
	update_appearance(UPDATE_ICON_STATE)
	return TRUE

/obj/structure/rmh_decree_poster/Destroy()
	UnregisterSignal(src, COMSIG_ATOM_CLICKEDON)
	if(attached_wall)
		UnregisterSignal(attached_wall, list(COMSIG_TURF_CHANGE, COMSIG_PARENT_QDELETING))
	attached_wall = null
	if(poster)
		UnregisterSignal(poster, list(COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_MOVED))
		SStgui.close_uis(poster)
		QDEL_NULL(poster)
	return ..()

/obj/structure/rmh_decree_poster/proc/on_sheet_deleted(datum/source)
	SIGNAL_HANDLER
	poster = null
	qdel(src)

/obj/structure/rmh_decree_poster/proc/on_sheet_moved(datum/source)
	SIGNAL_HANDLER
	if(poster?.loc != src)
		if(poster)
			UnregisterSignal(poster, list(COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_MOVED))
		poster = null
		qdel(src)

/obj/structure/rmh_decree_poster/proc/on_wall_changed(datum/source)
	SIGNAL_HANDLER
	detach_poster()

/obj/structure/rmh_decree_poster/proc/detach_poster(mob/user, tear = FALSE)
	if(!poster)
		return null
	var/obj/item/rmh_decree_poster/sheet = poster
	poster = null
	UnregisterSignal(sheet, list(COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_MOVED))
	SStgui.close_uis(sheet)
	if(tear)
		sheet.tear_edges()
	sheet.forceMove(get_turf(src))
	if(user)
		user.put_in_hands(sheet)
	qdel(src)
	return sheet

/obj/structure/rmh_decree_poster/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(. || !poster || !isliving(user) || !user.Adjacent(src) || !user.can_perform_action(src, NEED_DEXTERITY|FORBID_TELEKINESIS_REACH))
		return
	if(istype(user.used_intent, INTENT_STEAL))
		try_steal(user)
		return TRUE
	poster.ui_interact(user)

/obj/structure/rmh_decree_poster/attackby(obj/item/tool, mob/user, list/modifiers)
	if(istype(tool, /obj/item/tattoo_machine) && poster)
		poster.begin_forgery(user, tool)
		return TRUE
	return ..()

/obj/structure/rmh_decree_poster/examine(mob/user)
	. = ..()
	if(poster?.damaged)
		. += span_notice(rmh_ui_text(user, "Края порваны.", "Its edges are torn."))

/datum/repeatable_crafting_recipe/reading/rmh_decree_poster
	name = "blank decree poster"
	output = /obj/item/rmh_decree_poster
	craft_time = 2 SECONDS
	subtypes_allowed = FALSE

/obj/item/rmh_decree_poster/ui_assets(mob/user)
	. = ..()
	. += get_asset_datum(/datum/asset/simple/rmh_decree_backgrounds)

#undef RMH_POSTER_FORGE_DELAY


/proc/rmh_decree_title(text)
	if(!istext(text) || !length(text))
		return ""
	return copytext_char(trim(splittext(text, "\n")[1]), 1, RMH_LAW_MAX_TITLE + 1)

/obj/item/rmh_decree_poster/proc/refresh_title()
	var/title = rmh_decree_title(snapshot ? snapshot["text"] : "")
	name = length(title) ? "Указ [html_encode(title)]" : "decree poster"
	if(istype(loc, /obj/structure/rmh_decree_poster))
		var/obj/structure/rmh_decree_poster/mount = loc
		if(mount.poster == src)
			mount.name = name

/obj/item/rmh_decree_poster/get_examine_name(mob/user, use_article = TRUE)
	if(!snapshot)
		return "<b>[rmh_ui_text(user, "Пустой постер для указа", "Blank decree poster")]</b>"
	var/text = rmh_law_ui_language(user) == "en" && length(trim(snapshot["text_en"])) ? snapshot["text_en"] : snapshot["text"]
	return "<b>[rmh_ui_text(user, "Указ", "Decree")] [html_encode(rmh_decree_title(text))]</b>"

/obj/structure/rmh_decree_poster/get_examine_name(mob/user, use_article = TRUE)
	return poster ? poster.get_examine_name(user, use_article) : ..()

/obj/item/rmh_decree_poster/get_mechanics_examine(mob/user)
	. = ..()
	if(!snapshot)
		. += rmh_ui_text(user, "Примените пустой лист к стенду писаря или исправной доске и выберите указ.", "Apply the blank sheet to a scribe's stand or intact decree board and choose a decree.")
		return
	. += rmh_poster_mechanics(user)

/obj/structure/rmh_decree_poster/get_mechanics_examine(mob/user)
	. = ..()
	. += rmh_poster_mechanics(user)

/proc/rmh_poster_mechanics(mob/user)
	return list(
		rmh_ui_text(user, "Нажмите на настенный постер или используйте лист в руке, чтобы прочесть указ.", "Click the mounted poster or use the sheet in hand to read the decree."),
		rmh_ui_text(user, "Примените заполненный лист к соседней стене, чтобы повесить его.", "Apply a filled sheet to a nearby wall to hang it."),
		rmh_ui_text(user, "STEAL + WEAK: аккуратно снять целым.", "STEAL + WEAK: remove the poster intact."),
		rmh_ui_text(user, "STEAL + STRONG: сорвать; края порвутся, текст останется читаемым.", "STEAL + STRONG: tear it down; damaged edges leave the text readable."),
		rmh_ui_text(user, "Тату-машинка переписывает только этот постер: 0,5 секунды на символ, качество зависит от навыка чтения.", "A tattoo machine rewrites only this poster: 0.5 seconds per character; reading skill determines the handwriting."),
	)


/obj/item/rmh_decree_poster/get_examine_desc(mob/user)
	return snapshot ? rmh_ui_text(user, "Пергамент с копией указа.", "A parchment bearing a copy of a decree.") : rmh_ui_text(user, "Подготовленный лист пергамента.", "A sheet of prepared parchment.")
