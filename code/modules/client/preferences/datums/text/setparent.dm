/datum/preference/text/setparent
	savefile_key = "setparent"
	savefile_identifier = PREF_CHARACTER
	category = "character"
	can_randomize = FALSE
	maximum_value_length = MAX_NAME_LEN

/datum/preference/text/setparent/create_default_value()
	return ""

/datum/preference/text/setparent/apply_to_human(mob/living/carbon/human/H, value, datum/preferences/prefs)
	H.setparent = value

/datum/preference/text/setparent/handle_link(datum/preferences/prefs, mob/user)
	var/new_parent = browser_input_text(user, "INPUT THE IDENTITY OF YOUR PARENT", "WHO YOU LOOK UP TO", prefs.read_preference(/datum/preference/text/setparent), MAX_NAME_LEN)
	if(new_parent)
		prefs.write_preference(/datum/preference/text/setparent, new_parent)
	else
		prefs.write_preference(/datum/preference/text/setparent, "")
