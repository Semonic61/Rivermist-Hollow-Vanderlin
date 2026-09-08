/datum/preference/list_type/noble_gossip
	savefile_key = "character_noble_gossip"
	savefile_identifier = PREF_CHARACTER

/datum/preference/list_type/noble_gossip/is_valid(value, datum/preferences/prefs)
	if(!islist(value) || length(value) > MAX_NOBLE_GOSSIP)
		return FALSE
	for(var/entry in value)
		if(!istext(entry) || !length(trim(entry)) || length(entry) > MAX_GOSSIP_LENGTH)
			return FALSE
	return TRUE
