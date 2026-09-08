/datum/family_middleware
	/// The player whose preferences we are editing.
	var/mob/owner
	/// Shortcut to owner's prefs datum.
	var/datum/preferences/prefs

/datum/family_middleware/New(datum/preferences/preferences, mob/user)
	owner = user
	prefs = preferences

/datum/family_middleware/Destroy()
	owner = null
	prefs = null
	return ..()

/datum/family_middleware/ui_close(mob/user)
	qdel(src)

/datum/family_middleware/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new /datum/tgui(user, src, "FamilyPrefs", "Family & Bonds")
		ui.open()

/datum/family_middleware/ui_state(mob/user)
	return GLOB.always_state

/datum/family_middleware/ui_data(mob/user)
	if(!prefs || user != owner || owner?.client?.prefs != prefs)
		return list()

	var/family_mode = prefs.read_preference(/datum/preference/choiced/family_mode)
	if(!family_mode)
		family_mode = FAMILY_NONE
	var/setspouse = prefs.read_preference(/datum/preference/text/setspouse)
	var/setchild = prefs.read_preference(/datum/preference/text/setchild)
	var/setparent = prefs.read_preference(/datum/preference/text/setparent)
	if(!istext(setspouse))
		setspouse = ""
	if(!istext(setchild))
		setchild = ""
	if(!istext(setparent))
		setparent = ""
	var/was_divorced = prefs.read_preference(/datum/preference/toggle/was_divorced)
	var/gender_pref = prefs.read_preference(/datum/preference/choiced/gender_choice)
	if(!gender_pref)
		gender_pref = ANY_GENDER
	var/same_species = prefs.read_preference(/datum/preference/toggle/same_species_family)
	var/wants_adoption = prefs.read_preference(/datum/preference/toggle/wants_adoption)
	var/list/acc_species = prefs.read_preference(/datum/preference/list_type/role_setting/picker/accepted_species)
	var/list/acc_faiths = prefs.read_preference(/datum/preference/list_type/role_setting/picker/accepted_patrons)
	var/list/job_filter = prefs.read_preference(/datum/preference/list_type/role_setting/picker/family_job_filler)
	if(!islist(acc_species))
		acc_species = list()
	if(!islist(acc_faiths))
		acc_faiths = list()
	if(!islist(job_filter))
		job_filter = list()

	var/list/ui_family_modes = list(
		list("key" = FAMILY_NONE, "label" = "None", "icon" = "ban", "desc" = "No family assignment. You arrive as a stranger."),
		list("key" = FAMILY_PARTIAL, "label" = "Partial", "icon" = "seedling", "desc" = "Join a compatible local house without requiring a spouse."),
		list("key" = FAMILY_NEWLYWED, "label" = "Newlywed", "icon" = "ring", "desc" = "Arrive paired with a compatible spouse."),
		list("key" = FAMILY_FULL, "label" = "Full", "icon" = "crown", "desc" = "Seek a spouse in a house or establish a new household.")
	)

	var/list/ui_gender_prefs = list(
		list("key" = ANY_GENDER, "label" = "Any", "icon" = "genderless"),
		list("key" = SAME_GENDER, "label" = "Same", "icon" = "venus-mars"),
		list("key" = DIFFERENT_GENDER, "label" = "Opposite", "icon" = "transgender")
	)

	var/list/all_species = list()
	for(var/id in GLOB.roundstart_species)
		var/st = GLOB.species_list[id]
		var/datum/species/S = new st()
		var/is_accessible = S.preference_accessible(prefs)
		var/species_name = S.name
		qdel(S)
		if(!is_accessible)
			continue
		all_species += list(list("name" = species_name, "path" = "[st]"))

	var/list/all_faiths = list()
	for(var/faith_type in GLOB.faith_list)
		var/datum/faith/F = GLOB.faith_list[faith_type]
		all_faiths += list(list("name" = F.name, "path" = "[faith_type]"))

	var/list/all_job_groups = list(
		list("label" = "Lords", "key" = "lords"),
		list("label" = "The Keep", "key" = "keep"),
		list("label" = "Town Hall", "key" = "townhall"),
		list("label" = "Town Watch", "key" = "townwatch"),
		list("label" = "Chapel", "key" = "chapel"),
		list("label" = "Scholars", "key" = "scholars"),
		list("label" = "Traders", "key" = "traders"),
		list("label" = "Tavern", "key" = "tavern"),
		list("label" = "Towners", "key" = "town"),
		list("label" = "Outsiders", "key" = "outsiders"),
		list("label" = "Adventurers", "key" = "adventurers"),
		list("label" = "Villains", "key" = "villains"),
	)


	return list(
		"family_mode" = family_mode,
		"setspouse" = setspouse,
		"setchild"  = setchild,
		"setparent" = setparent,
		"was_divorced" = was_divorced,
		"wants_adoption" = wants_adoption,
		"gender_choice" = gender_pref,
		"same_species_family" = same_species,
		"accepted_species" = acc_species,
		"accepted_patron_faiths" = acc_faiths,
		"family_job_filter" = job_filter,
		"all_species" = all_species,
		"all_faiths" = all_faiths,
		"all_job_groups" = all_job_groups,
		"ui_family_modes" = ui_family_modes,
		"ui_gender_prefs" = ui_gender_prefs
	)

/datum/family_middleware/ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!prefs)
		return FALSE
	if(ui.user != owner || owner?.client?.prefs != prefs)
		return FALSE

	switch(action)

		if("set_family_mode")
			var/mode = params["mode"]
			if(!(mode in list(FAMILY_NONE, FAMILY_PARTIAL, FAMILY_NEWLYWED, FAMILY_FULL)))
				return FALSE
			prefs.write_preference(/datum/preference/choiced/family_mode, mode)
			prefs.save_character()
			return TRUE

		if("edit_setspouse")
			var/new_name = tgui_input_text(
				owner,
				"Enter the exact character name of your designated spouse, or leave blank to clear.",
				"Designated Spouse",
				prefs.read_preference(/datum/preference/text/setspouse),
				MAX_NAME_LEN,
			)
			if(new_name == null)
				return FALSE
			prefs.write_preference(/datum/preference/text/setspouse, length(new_name) ? new_name : "")
			prefs.save_character()
			return TRUE

		if("clear_setspouse")
			prefs.write_preference(/datum/preference/text/setspouse, "")
			prefs.save_character()
			return TRUE

		if("toggle_divorced")
			var/current = prefs.read_preference(/datum/preference/toggle/was_divorced)
			prefs.write_preference(/datum/preference/toggle/was_divorced, !current)
			prefs.save_character()
			return TRUE

		if("toggle_adoption")
			var/current = prefs.read_preference(/datum/preference/toggle/wants_adoption)
			prefs.write_preference(/datum/preference/toggle/wants_adoption, !current)
			prefs.save_character()
			return TRUE

		if("set_gender_choice")
			var/choice = params["choice"]
			if(!(choice in list(ANY_GENDER, SAME_GENDER, DIFFERENT_GENDER)))
				return FALSE

			var/pronoun_pref = prefs.read_preference(/datum/preference/choiced/pronouns)
			if((pronoun_pref == THEY_THEM || pronoun_pref == IT_ITS) && choice != ANY_GENDER)
				to_chat(owner, span_warning("With neutral pronouns, you may only choose [ANY_GENDER]."))
				return FALSE

			prefs.write_preference(/datum/preference/choiced/gender_choice, choice)
			prefs.save_character()
			return TRUE

		if("toggle_same_species")
			var/current = prefs.read_preference(/datum/preference/toggle/same_species_family)
			prefs.write_preference(/datum/preference/toggle/same_species_family, !current)
			prefs.save_character()
			return TRUE

		if("toggle_accepted_species")
			var/path = params["path"]
			var/species_type = text2path(path)
			var/list/allowed_species = list()
			for(var/species_id in GLOB.roundstart_species)
				allowed_species |= GLOB.species_list[species_id]
			if(!species_type || !(species_type in allowed_species))
				return FALSE
			var/list/current = prefs.read_preference(/datum/preference/list_type/role_setting/picker/accepted_species)
			if(!islist(current))
				current = list()
			else
				current = current.Copy()
			if(path in current)
				current -= path
			else
				current += path
			prefs.write_preference(/datum/preference/list_type/role_setting/picker/accepted_species, current)
			prefs.save_character()
			return TRUE

		if("toggle_accepted_faith")
			var/path = params["path"]
			if(!path || !GLOB.faith_list[text2path(path)])
				return FALSE
			var/list/current = prefs.read_preference(/datum/preference/list_type/role_setting/picker/accepted_patrons)
			if(!islist(current))
				current = list()
			else
				current = current.Copy()
			if(path in current)
				current -= path
			else
				current += path
			prefs.write_preference(/datum/preference/list_type/role_setting/picker/accepted_patrons, current)
			prefs.save_character()
			return TRUE

		if("toggle_job_group")
			var/key = params["key"]
			if(!key)
				return FALSE
			var/list/valid_keys = list("lords", "keep", "townhall", "townwatch", "chapel", "scholars", "traders", "tavern", "town", "outsiders", "adventurers", "villains")
			if(!(key in valid_keys))
				return FALSE
			var/list/current = prefs.read_preference(/datum/preference/list_type/role_setting/picker/family_job_filler)
			if(!islist(current))
				current = list()
			else
				current = current.Copy()
			if(key in current)
				current -= key
			else
				current += key
			prefs.write_preference(/datum/preference/list_type/role_setting/picker/family_job_filler, current)
			prefs.save_character()
			return TRUE

		if("clear_all_filters")
			prefs.write_preference(/datum/preference/toggle/same_species_family, FALSE)
			prefs.write_preference(/datum/preference/list_type/role_setting/picker/accepted_species, list())
			prefs.write_preference(/datum/preference/list_type/role_setting/picker/accepted_patrons, list())
			prefs.write_preference(/datum/preference/list_type/role_setting/picker/family_job_filler, list())
			prefs.save_character()
			return TRUE

		if("edit_setchild")
			var/new_name = tgui_input_text(
				owner,
				"Enter the exact character name of your designated child, or leave blank to clear.",
				"Designated Child",
				prefs.read_preference(/datum/preference/text/setchild),
				MAX_NAME_LEN,
			)
			if(new_name == null)
				return FALSE
			prefs.write_preference(/datum/preference/text/setchild, length(new_name) ? new_name : "")
			prefs.save_character()
			return TRUE

		if("clear_setchild")
			prefs.write_preference(/datum/preference/text/setchild, "")
			prefs.save_character()
			return TRUE
		if("edit_setparent")
			var/new_name = tgui_input_text(
				owner,
				"Enter the exact character name of your designated parent, or leave blank to clear.",
				"Designated Parent",
				prefs.read_preference(/datum/preference/text/setparent),
				MAX_NAME_LEN,
			)
			if(new_name == null)
				return FALSE
			prefs.write_preference(/datum/preference/text/setparent, length(new_name) ? new_name : "")
			prefs.save_character()
			return TRUE

		if("clear_setparent")
			prefs.write_preference(/datum/preference/text/setparent, "")
			prefs.save_character()
			return TRUE

	return FALSE
