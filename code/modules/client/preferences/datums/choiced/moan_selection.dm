/datum/preference/choiced/moan_selection
	savefile_key = "moan_selection"
	savefile_identifier = PREF_CHARACTER
	category = "character"
	can_randomize = FALSE
	should_update_preview = FALSE
	should_apply = FALSE

/datum/preference/choiced/moan_selection/init_possible_values(datum/preferences/prefs)
	generate_selectable_moanpacks()
	var/list/choices = list(MOANPACK_TYPE_DEF)
	for(var/moan_name in GLOB.selectable_moanpacks)
		choices |= moan_name
	return choices

/datum/preference/choiced/moan_selection/create_default_value(datum/preferences/prefs)
	return MOANPACK_TYPE_DEF
