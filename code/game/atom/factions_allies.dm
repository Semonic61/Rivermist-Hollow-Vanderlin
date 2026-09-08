/atom/movable
	/// Shared, cached faction strings. Never mutate this list; use the faction setters.
	VAR_PROTECTED/list/faction
	/// Per-atom dynamic allies (usually reference strings, including the mob itself).
	var/list/allies

/// Compare static factions and dynamic allies. Exact matching requires equal sets.
/proc/faction_check(list/faction_A, list/faction_B, list/allies_A, list/allies_B, exact_match = FALSE)
	return FAST_FACTION_CHECK(faction_A, faction_B, allies_A, allies_B, exact_match)

/atom/movable/proc/faction_check_atom(atom/movable/target, exact_match = FALSE)
	if(!target)
		return FALSE
	if(!exact_match)
		return FAST_FACTION_CHECK(faction, target.faction, allies, target.allies, FALSE)

	var/list/source_allies = LAZYCOPY(allies)
	var/list/target_allies = LAZYCOPY(target.allies)
	// A mob's own identity must not prevent an otherwise exact faction match.
	if(!(REF(src) in target_allies))
		source_allies -= REF(src)
	if(!(REF(target) in source_allies))
		target_allies -= REF(target)
	return FAST_FACTION_CHECK(faction, target.faction, source_allies, target_allies, TRUE)

/mob/faction_check_atom(atom/movable/target, exact_match = FALSE)
	. = ..()
	if(. || exact_match || !ismob(target))
		return .
	// RMH also recognizes legacy name-based allegiances.
	return has_faction(target.name) || has_ally(target.name)

/// Replace allies without sharing a mutable list with the caller.
/atom/movable/proc/set_allies(list/ally_list)
	if(!islist(ally_list) && !isnull(ally_list))
		stack_trace("set_allies requires a list; use add_ally for a single ally.")
		return FALSE
	allies = LAZYLEN(ally_list) ? ally_list.Copy() : null
	return TRUE

/// Adds an ally, or a list of reference strings. Atoms are converted to references.
/atom/movable/proc/add_ally(ally_or_allies)
	if(isnull(ally_or_allies))
		return FALSE
	var/old_length = LAZYLEN(allies)
	if(isatom(ally_or_allies))
		ally_or_allies = REF(ally_or_allies)
	LAZYOR(allies, ally_or_allies)
	return LAZYLEN(allies) != old_length

/atom/movable/proc/remove_ally(ally_or_allies)
	var/old_length = LAZYLEN(allies)
	if(!old_length)
		return FALSE
	if(isatom(ally_or_allies))
		ally_or_allies = REF(ally_or_allies)
	LAZYREMOVE(allies, ally_or_allies)
	return LAZYLEN(allies) != old_length

/atom/movable/proc/has_ally(ally_or_allies, match_all = FALSE)
	if(islist(ally_or_allies))
		var/matches = LAZYLEN(allies & ally_or_allies)
		return match_all ? matches == length(ally_or_allies) : matches > 0
	if(isatom(ally_or_allies))
		ally_or_allies = REF(ally_or_allies)
	return !isnull(ally_or_allies) && (ally_or_allies in allies)

/// Read-only view. Use set_faction/add_faction/remove_faction for changes.
/atom/movable/proc/get_faction()
	return faction

/atom/movable/proc/set_faction(list/factions)
	if(factions == faction)
		return TRUE
	if(!islist(factions) && !isnull(factions))
		stack_trace("set_faction requires a list; use add_faction for a single faction.")
		return FALSE
	// Use a structured key: joining with "-" aliases different faction names.
	var/static/list/faction_lists = list()
	if(!LAZYLEN(factions))
		faction = null
	else
		var/cache_key = json_encode(factions)
		faction = faction_lists[cache_key]
		if(!faction)
			faction = faction_lists[cache_key] = factions.Copy()
	return TRUE

/atom/movable/proc/add_faction(faction_or_factions)
	if(isnull(faction_or_factions))
		return FALSE
	var/list/faction_copy = LAZYCOPY(faction)
	LAZYOR(faction_copy, faction_or_factions)
	if(LAZYLEN(faction_copy) == LAZYLEN(faction))
		return FALSE
	set_faction(faction_copy)
	return TRUE

/atom/movable/proc/remove_faction(faction_or_factions)
	if(!LAZYLEN(faction))
		return FALSE
	var/list/faction_copy = faction.Copy()
	LAZYREMOVE(faction_copy, faction_or_factions)
	if(LAZYLEN(faction_copy) == length(faction))
		return FALSE
	set_faction(faction_copy)
	return TRUE

/atom/movable/proc/has_faction(faction_or_factions, match_all = FALSE)
	if(islist(faction_or_factions))
		var/matches = LAZYLEN(faction & faction_or_factions)
		return match_all ? matches == length(faction_or_factions) : matches > 0
	return !isnull(faction_or_factions) && (faction_or_factions in faction)

/atom/movable/proc/has_faction_or_allies(faction_or_factions, list/allies_list, match_all = FALSE)
	if(match_all)
		return (isnull(faction_or_factions) || has_faction(faction_or_factions, TRUE)) && (isnull(allies_list) || has_ally(allies_list, TRUE))
	return has_faction(faction_or_factions) || has_ally(allies_list)

/atom/movable/proc/edit_faction(mob/user)
	var/prompt = tgui_alert(user, "Would you like to Add or Remove faction?", "Add/Remove?", list("Add", "Remove"))
	if(QDELETED(src) || QDELETED(user) || isnull(prompt))
		return FALSE
	if(prompt == "Add")
		var/new_faction = tgui_input_text(user, "Enter a faction name to add.", "Add Faction", max_length = MAX_NAME_LEN)
		if(QDELETED(src) || QDELETED(user) || !length(new_faction))
			return FALSE
		return add_faction(new_faction)

	var/list/current_factions = LAZYCOPY(faction)
	if(!LAZYLEN(current_factions))
		to_chat(user, span_warning("[src] has no factions left to remove!"))
		return FALSE
	sortList(current_factions, GLOBAL_PROC_REF(cmp_text_asc))
	var/old_faction = tgui_input_list(user, "Select a faction to remove.", "Remove faction", current_factions)
	if(QDELETED(src) || QDELETED(user) || isnull(old_faction))
		return FALSE
	return remove_faction(old_faction)

/atom/movable/proc/faction_to_text()
	var/list/factions_printout = list()
	for(var/faction_string in faction)
		factions_printout += "\n[faction_string]"
	return jointext(factions_printout, "")
