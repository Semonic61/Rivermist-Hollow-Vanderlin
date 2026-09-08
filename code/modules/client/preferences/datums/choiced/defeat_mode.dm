/datum/preference/choiced/defeat_mode
	savefile_key = "defeat_mode"
	savefile_identifier = PREF_CHARACTER
	category = "character"
	can_randomize = FALSE
	should_update_preview = FALSE

/datum/preference/choiced/defeat_mode/init_possible_values(datum/preferences/prefs)
	return list(DEFEAT_MODE_KO_RUNE, DEFEAT_MODE_KO_ONLY, DEFEAT_MODE_NO_RETURN)

/datum/preference/choiced/defeat_mode/create_default_value(datum/preferences/prefs)
	return DEFEAT_MODE_DEFAULT

/datum/preference/choiced/defeat_mode/deserialize(input, datum/preferences/prefs)
	return sanitize_defeat_mode(input)

/datum/preference/choiced/defeat_mode/apply_to_human(mob/living/carbon/human/human, value, datum/preferences/prefs)
	human.defeat_mode = value
