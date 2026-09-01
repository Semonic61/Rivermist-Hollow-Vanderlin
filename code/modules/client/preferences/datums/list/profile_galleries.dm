/datum/preference/list_type/profile_gallery
	abstract_type = /datum/preference/list_type/profile_gallery
	savefile_identifier = PREF_CHARACTER
	category = "character_ooc"
	should_update_preview = FALSE
	var/nsfw = FALSE

/datum/preference/list_type/profile_gallery/deserialize(list/input, datum/preferences/prefs)
	var/list/loaded = ..()
	var/list/cleaned = list()
	for(var/link in loaded)
		if(length(cleaned) >= 3)
			break
		var/valid = nsfw ? prefs.is_valid_nsfw_headshot_link(null, link, TRUE) : prefs.is_valid_headshot_link(null, link, TRUE)
		if(valid)
			cleaned += link
	return cleaned

/datum/preference/list_type/profile_gallery/images
	savefile_key = "img_gallery"
	nsfw = FALSE

/datum/preference/list_type/profile_gallery/images/apply_to_human(mob/living/carbon/human/human, list/value, datum/preferences/prefs)
	human.img_gallery = value.Copy()

/datum/preference/list_type/profile_gallery/nsfw_images
	savefile_key = "nsfw_img_gallery"
	nsfw = TRUE

/datum/preference/list_type/profile_gallery/nsfw_images/apply_to_human(mob/living/carbon/human/human, list/value, datum/preferences/prefs)
	human.nsfw_img_gallery = value.Copy()
