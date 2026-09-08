/datum/preference/text/setchild
	savefile_key = "setchild"
	savefile_identifier = PREF_CHARACTER
	category = "character"
	can_randomize = FALSE
	maximum_value_length = MAX_NAME_LEN

/datum/preference/text/setchild/create_default_value()
	return ""

/datum/preference/text/setchild/apply_to_human(mob/living/carbon/human/H, value, datum/preferences/prefs)
	H.setchild = value

/datum/preference/text/setchild/handle_link(datum/preferences/prefs, mob/user)
	var/new_child = browser_input_text(user, "INPUT THE IDENTITY OF YOUR PROGENY", "RAISE THEM WELL", prefs.read_preference(/datum/preference/text/setchild), MAX_NAME_LEN)
	if(new_child)
		prefs.write_preference(/datum/preference/text/setchild, new_child)
	else
		prefs.write_preference(/datum/preference/text/setchild, "")
