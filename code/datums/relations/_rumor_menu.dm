/datum/gossip_prefs
	var/mob/holder

/datum/gossip_prefs/New(mob/H)
	holder = H

/datum/gossip_prefs/Destroy()
	holder = null
	return ..()

/datum/gossip_prefs/ui_close(mob/user)
	qdel(src)

/datum/gossip_prefs/ui_state(mob/user)
	return GLOB.always_state

/datum/gossip_prefs/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new /datum/tgui(user, src, "GossipPrefs", "Gossip & Rumors")
		ui.open()

/datum/gossip_prefs/ui_data(mob/user)
	var/list/rumors = list()
	var/list/noble_gossip = list()

	if(user == holder && holder?.client?.prefs)
		var/list/r = holder.client.prefs.read_preference(/datum/preference/list_type/rumors)
		for(var/text in r)
			rumors += text
		var/list/ng = holder.client.prefs.read_preference(/datum/preference/list_type/noble_gossip)
		for(var/text in ng)
			noble_gossip += text

	return list(
		"rumors" = rumors,
		"noble_gossip" = noble_gossip,
		"max_rumors" = MAX_RUMORS,
		"max_noble_gossip" = MAX_NOBLE_GOSSIP,
		"max_gossip_length" = MAX_GOSSIP_LENGTH,
		"rival_count" = holder?.client?.prefs.read_preference(/datum/preference/numeric/rival_count),
		"rival_count_min" = /datum/preference/numeric/rival_count::minimum,
		"rival_count_max" = /datum/preference/numeric/rival_count::maximum,
	)

/datum/gossip_prefs/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return TRUE

	if(ui.user != holder || !holder?.client?.prefs)
		return FALSE
	var/datum/preferences/preferences = holder.client.prefs

	switch(action)
		if("add_rumor")
			var/text = clean_gossip_text(params["text"])
			if(!text)
				return FALSE
			var/list/current = preferences.read_preference(/datum/preference/list_type/rumors)
			if(!islist(current))
				current = list()
			else
				current = current.Copy()
			if(current.len >= MAX_RUMORS)
				return FALSE
			current += text
			preferences.write_preference(/datum/preference/list_type/rumors, current)
			preferences.save_character()
			return TRUE

		if("remove_rumor")
			var/idx = params["index"]
			if(!isnum(idx))
				return FALSE
			var/list/current = preferences.read_preference(/datum/preference/list_type/rumors)
			if(!islist(current))
				return FALSE
			current = current.Copy()
			if(idx < 1 || idx > current.len)
				return FALSE
			current.Cut(idx, idx + 1)
			preferences.write_preference(/datum/preference/list_type/rumors, current)
			preferences.save_character()
			return TRUE

		if("edit_rumor")
			var/idx = params["index"]
			var/text = clean_gossip_text(params["text"])
			if(!isnum(idx) || !text)
				return FALSE
			var/list/current = preferences.read_preference(/datum/preference/list_type/rumors)
			if(!islist(current))
				return FALSE
			current = current.Copy()
			if(idx < 1 || idx > current.len)
				return FALSE
			current[idx] = text
			preferences.write_preference(/datum/preference/list_type/rumors, current)
			preferences.save_character()
			return TRUE

		if("add_noble_gossip")
			var/text = clean_gossip_text(params["text"])
			if(!text)
				return FALSE
			var/list/current = preferences.read_preference(/datum/preference/list_type/noble_gossip)
			if(!islist(current))
				current = list()
			else
				current = current.Copy()
			if(current.len >= MAX_NOBLE_GOSSIP)
				return FALSE
			current += text
			preferences.write_preference(/datum/preference/list_type/noble_gossip, current)
			preferences.save_character()
			return TRUE

		if("remove_noble_gossip")
			var/idx = params["index"]
			if(!isnum(idx))
				return FALSE
			var/list/current = preferences.read_preference(/datum/preference/list_type/noble_gossip)
			if(!islist(current))
				return FALSE
			current = current.Copy()
			if(idx < 1 || idx > current.len)
				return FALSE
			current.Cut(idx, idx + 1)
			preferences.write_preference(/datum/preference/list_type/noble_gossip, current)
			preferences.save_character()
			return TRUE

		if("edit_noble_gossip")
			var/idx = params["index"]
			var/text = clean_gossip_text(params["text"])
			if(!isnum(idx) || !text)
				return FALSE
			var/list/current = preferences.read_preference(/datum/preference/list_type/noble_gossip)
			if(!islist(current))
				return FALSE
			current = current.Copy()
			if(idx < 1 || idx > current.len)
				return FALSE
			current[idx] = text
			preferences.write_preference(/datum/preference/list_type/noble_gossip, current)
			preferences.save_character()
			return TRUE

		if("set_rival_count")
			var/val = params["value"]
			if(!isnum(val))
				return FALSE
			val = round(val)
			if(val < /datum/preference/numeric/rival_count::minimum || val > /datum/preference/numeric/rival_count::maximum)
				return FALSE
			preferences.write_preference(/datum/preference/numeric/rival_count, val)
			preferences.save_character()
			return TRUE

/datum/gossip_prefs/proc/clean_gossip_text(value)
	if(!istext(value))
		return null
	var/cleaned = trim(sanitize_text(value))
	if(!length(cleaned) || length(cleaned) > MAX_GOSSIP_LENGTH)
		return null
	return cleaned

/datum/preferences/proc/open_gossip(mob/user)
	var/datum/gossip_prefs/gossip = new(user)
	gossip.ui_interact(user)
