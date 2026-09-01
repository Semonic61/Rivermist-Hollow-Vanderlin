/datum/preference/choiced/taur_type
	savefile_key = "taur_type"
	savefile_identifier = PREF_CHARACTER
	category = "character"
	dynamic = TRUE
	allows_nulls = TRUE
	can_randomize = FALSE
	should_apply = FALSE

/datum/preference/choiced/taur_type/init_possible_values(datum/preferences/prefs)
	var/list/choices = list(null)
	for(var/taur_type in prefs?.pref_species?.get_taur_list())
		choices += taur_type
	return choices

/datum/preference/choiced/taur_type/create_default_value(datum/preferences/prefs)
	if(prefs.pref_species?.forced_taur && length(prefs.pref_species.allowed_taur_types))
		return pick(prefs.pref_species.allowed_taur_types)
	return null

/datum/preference/choiced/taur_type/serialize(input)
	return ispath(input) ? "[input]" : null

/datum/preference/choiced/taur_type/deserialize(input, datum/preferences/prefs)
	if(isnull(input) || input == "")
		return null
	var/taur_type = ispath(input) ? input : text2path(input)
	return (taur_type in get_choices(prefs)) ? taur_type : create_default_value(prefs)

/datum/preference/choiced/taur_type/is_valid(value, datum/preferences/prefs)
	return isnull(value) || (value in get_choices(prefs))
