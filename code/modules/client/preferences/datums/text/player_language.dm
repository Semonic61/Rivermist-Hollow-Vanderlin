/datum/preference/text/player_language
	savefile_key = "player_language"
	savefile_identifier = PREF_PLAYER
	category = "character_ooc"
	maximum_value_length = 4
	can_randomize = FALSE
	should_update_preview = FALSE

/datum/preference/text/player_language/create_default_value(datum/preferences/prefs)
	return "RU"

/datum/preference/text/player_language/deserialize(input, datum/preferences/prefs)
	var/language = uppertext(trim(..()))
	return length(language) ? language : create_default_value(prefs)
