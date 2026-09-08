/datum/preference/list_type/smallclothes_preferences
	savefile_key = "smallclothes_preferences"
	savefile_identifier = PREF_CHARACTER
	category = "character"
	should_update_preview = TRUE
	should_apply = FALSE

/datum/preference/list_type/smallclothes_preferences/create_default_value(datum/preferences/prefs)
	return list(
		SMALCLOTHES_RANDOM_PREFERENCES = FALSE,
		SMALCLOTHES_UNDIE_PREFERENCES = null,
		SMALCLOTHES_LEGWEAR_PREFERENCES = null,
		SMALCLOTHES_BRA_PREFERENCES = null,
		SMALCLOTHES_GARTER_PREFERENCES = null,
		SMALCLOTHES_UNDERSHIRT_PREFERENCES = null,
		SMALCLOTHES_ARMSLEEVE_PREFERENCES = null,
	)
