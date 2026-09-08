/datum/preference/numeric/defeat_damage_threshold
	savefile_key = "defeat_damage_threshold"
	savefile_identifier = PREF_CHARACTER
	category = "character"
	minimum = 100
	maximum = 300
	step = 50
	can_randomize = FALSE
	should_update_preview = FALSE

/datum/preference/numeric/defeat_damage_threshold/create_default_value(datum/preferences/prefs)
	return DEFEAT_DAMAGE_THRESHOLD_DEFAULT

/datum/preference/numeric/defeat_damage_threshold/deserialize(input, datum/preferences/prefs)
	return sanitize_defeat_damage_threshold(input)

/datum/preference/numeric/defeat_damage_threshold/is_valid(value, datum/preferences/prefs)
	return value in list(100, 150, 200, 250, 300)

/datum/preference/numeric/defeat_damage_threshold/apply_to_human(mob/living/carbon/human/human, value, datum/preferences/prefs)
	human.defeat_damage_threshold = value
