/datum/preference/list_type/role_setting/picker/family_job_filler
	savefile_key = "family_job_filter"
	savefile_identifier = PREF_CHARACTER
	category = "relations"
	can_randomize = FALSE
	setting_display_name = "Family Job Groups"
	max_lines = 10
	string = TRUE
	picker_options = list(
		"lords",
		"keep",
		"townhall",
		"townwatch",
		"chapel",
		"scholars",
		"traders",
		"tavern",
		"town",
		"outsiders",
		"adventurers",
		"villains",
	)
	is_role = FALSE
	should_apply = TRUE

/datum/preference/list_type/role_setting/picker/family_job_filler/create_default_value()
	return list()

/datum/preference/list_type/role_setting/picker/family_job_filler/apply_to_human(mob/living/carbon/human/H, value, datum/preferences/prefs)
	H.family_job_filter = value

/datum/preference/list_type/role_setting/picker/family_job_filler/handle_link(datum/preferences/prefs, mob/user)
	var/list/group_options = list(
		"Lords" = "lords",
		"The Keep" = "keep",
		"Town Hall" = "townhall",
		"Town Watch" = "townwatch",
		"Chapel" = "chapel",
		"Scholars" = "scholars",
		"Traders" = "traders",
		"Tavern" = "tavern",
		"Towners" = "town",
		"Outsiders" = "outsiders",
		"Adventurers" = "adventurers",
		"Villains" = "villains",
	)

	var/list/current = prefs.read_preference(/datum/preference/list_type/role_setting/picker/family_job_filler)
	var/result = browser_input_list(user, "TOGGLE FAMILY JOB GROUPS", "BIRDS OF A FEATHER", group_options, null)
	if(!result)
		return

	var/chosen = group_options[result]
	if(chosen in current)
		current -= chosen
		to_chat(user, span_notice("Removed [result] from family job groups."))
	else
		current += chosen
		to_chat(user, span_notice("Added [result] to family job groups."))

	prefs.write_preference(/datum/preference/list_type/role_setting/picker/family_job_filler, current)
