/datum/preference/choiced/combat_music
	savefile_key = "combat_music"
	savefile_identifier = PREF_CHARACTER
	category = "character"
	can_randomize = FALSE
	should_update_preview = FALSE
	should_apply = FALSE

/datum/preference/choiced/combat_music/init_possible_values(datum/preferences/prefs)
	var/list/choices = list()
	for(var/music_type in GLOB.cmode_tracks_by_type)
		choices += music_type
	if(!length(choices))
		choices += /datum/combat_music/default
	return choices

/datum/preference/choiced/combat_music/create_default_value(datum/preferences/prefs)
	return /datum/combat_music/default

/datum/preference/choiced/combat_music/serialize(input)
	return ispath(input) ? "[input]" : "[/datum/combat_music/default]"

/datum/preference/choiced/combat_music/deserialize(input, datum/preferences/prefs)
	var/music_type = ispath(input) ? input : text2path(input)
	return sanitize_inlist(music_type, get_choices(prefs), create_default_value(prefs))
