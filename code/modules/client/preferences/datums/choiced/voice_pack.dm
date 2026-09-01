/datum/preference/choiced/voice_pack
	savefile_key = "voice_pack"
	savefile_identifier = PREF_CHARACTER
	category = "character"
	can_randomize = FALSE
	should_update_preview = FALSE
	should_apply = FALSE

/datum/preference/choiced/voice_pack/init_possible_values(datum/preferences/prefs)
	var/list/choices = list()
	for(var/voice_pack_name in GLOB.voice_packs_list)
		choices += voice_pack_name
	return choices

/datum/preference/choiced/voice_pack/create_default_value(datum/preferences/prefs)
	return VOICE_PACK_DEFAULT
