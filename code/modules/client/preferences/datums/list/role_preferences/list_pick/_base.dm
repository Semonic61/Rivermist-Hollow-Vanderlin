/datum/preference/list_type/role_setting/picker
	abstract_type = /datum/preference/list_type/role_setting/picker
	setting_kind = "picker"
	can_randomize = FALSE
	/// List of type paths to pick from
	var/list/picker_options = list()
	/// TRUE when picker options are literal strings rather than type paths.
	var/string = FALSE

/datum/preference/list_type/role_setting/picker/proc/build_lists()
	SHOULD_CALL_PARENT(FALSE)
	CRASH("picker list has no picker_options and no build_lists() override")

/datum/preference/list_type/role_setting/picker/is_valid(value, datum/preferences/prefs)
	if(!length(picker_options))
		build_lists()
	if(!islist(value))
		return FALSE
	for(var/entry in value)
		var/path = string ? entry : (ispath(entry) ? entry : text2path(entry))
		if(!path || !(path in picker_options))
			return FALSE
	return TRUE

/datum/preference/list_type/role_setting/picker/deserialize(input, datum/preferences/prefs)
	if(!length(picker_options))
		build_lists()
	if(!islist(input))
		return create_default_value(prefs)
	var/list/cleaned = list()
	for(var/entry in input)
		var/path = string ? entry : (ispath(entry) ? entry : text2path(entry))
		if(path && (path in picker_options))
			cleaned += "[path]"
	return cleaned

/datum/preference/list_type/role_setting/picker/proc/get_option_data()
	if(!length(picker_options))
		build_lists()
	var/list/result = list()
	for(var/path in picker_options)
		if(ispath(path, /atom/movable))
			var/atom/movable/option = path
			result += list(list(
				"value" = "[path]",
				"name" = initial(option.name),
				"icon" = initial(option.icon),
				"icon_state" = initial(option.icon_state),
				"is_path" = TRUE,
			))
		else if(ispath(path, /datum))
			var/datum/option = new path()
			var/option_name = option.vars["name"]
			if(!option_name)
				option_name = "[path]"
			result += list(list(
				"value" = "[path]",
				"name" = option_name,
				"is_path" = TRUE,
			))
			qdel(option)
		else
			result += list(list(
				"value" = "[path]",
				"name" = "[path]",
				"is_path" = FALSE,
			))
	return result
