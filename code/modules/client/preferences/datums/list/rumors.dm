/datum/preference/list_type/rumors
	savefile_key = "character_rumors"
	savefile_identifier = PREF_CHARACTER

/datum/preference/list_type/rumors/is_valid(value, datum/preferences/prefs)
	if(!islist(value) || length(value) > MAX_RUMORS)
		return FALSE
	for(var/entry in value)
		if(!istext(entry) || !length(trim(entry)) || length(entry) > MAX_GOSSIP_LENGTH)
			return FALSE
	return TRUE
