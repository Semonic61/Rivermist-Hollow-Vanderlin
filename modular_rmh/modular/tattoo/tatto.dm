/**
 * ## Hand-poked tattoo system
 *
 * Self-applied tattoos written by the player: either lettering ("ACAB") or a
 * described design (a wolf's head). Stored on the bodypart, shown on examine,
 * saved between rounds, faded by water and scrubbed off by soap.
 *
 * Deliberately separate from GLOB.body_markings ("Markings" in the character
 * creator), which is premade sprite patterns rather than player-written text.
 *
 * Everything lives in one file so the defines below can never desync from the
 * code that uses them through include ordering. They are #undef'd at the end.
 */

/// Freshly applied tattoo - crisp, full detail
#define TATTOO_STATE_FRESH 1
/// Tattoo has been partly washed away - patchy, faded, harder to read
#define TATTOO_STATE_FADED 2

/// How many tattoos can be stacked on a single zone before it's "full"
#define MAXIMUM_TATTOOS_PER_ZONE 3

/// Tattoo is rendered as a quoted piece of lettering, e.g. "ACAB"
#define TATTOO_STYLE_LETTERING "lettering"
/// Tattoo is rendered as an unquoted description of a design, e.g. a wolf's head
#define TATTOO_STYLE_DESIGN "design"

/// Max characters allowed per tattoo entry
#define TATTOO_TEXT_MAX_LENGTH 150

/// Movespeed modifier id for the pain of getting hand-poked
#define MOVESPEED_ID_TATTOO_PAIN "tattoo_pain"

/*
 * GLOBALS
 */

/// Icons shown in the tattoo needle's zone-select radial menu
GLOBAL_LIST_INIT(tattoo_radial_icons, list(
	BODY_ZONE_HEAD = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "head"),
	BODY_ZONE_CHEST = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "chest"),
	BODY_ZONE_L_ARM = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "l_arm"),
	BODY_ZONE_R_ARM = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "r_arm"),
	BODY_ZONE_L_LEG = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "l_leg"),
	BODY_ZONE_R_LEG = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "r_leg"),
	BODY_ZONE_PRECISE_L_HAND = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "l_arm"),
	BODY_ZONE_PRECISE_R_HAND = image(icon = 'icons/mob/screen_gen.dmi', icon_state = "r_arm"),
))

/// Human-readable names for tattoo zones, used in chat messages and examine text
GLOBAL_LIST_INIT(tattoo_zone_names, list(
	BODY_ZONE_HEAD = "head",
	BODY_ZONE_CHEST = "chest",
	BODY_ZONE_L_ARM = "left arm",
	BODY_ZONE_R_ARM = "right arm",
	BODY_ZONE_L_LEG = "left leg",
	BODY_ZONE_R_LEG = "right leg",
	BODY_ZONE_PRECISE_L_HAND = "left hand",
	BODY_ZONE_PRECISE_R_HAND = "right hand",
))

/// Natural pigments a tattoo needle can be inked with (name = hex colour).
/// Deliberately no modern inks - soot, ash, ochre clay, madder root and woad.
GLOBAL_LIST_INIT(tattoo_ink_colors, list(
	"Charcoal Black" = "#2B2B2B",
	"Soot Grey" = "#4A4A4A",
	"Ash Grey" = "#8A8A8A",
	"Ochre Brown" = "#7A4A2B",
	"Madder Red" = "#7C1F1F",
	"Woad Blue" = "#2B3F6E",
))

/*
 * BODYPART STORAGE
 *
 * Each entry is an assoc list:
 *   list("zone" = BODY_ZONE_*, "text" = "...", "style" = TATTOO_STYLE_*, "color" = "#hex", "state" = TATTOO_STATE_*)
 * The entry carries its own zone because precise zones (hands) are NOT separate
 * bodyparts - BODY_ZONE_PRECISE_L_HAND is a subtarget of the arm - so one
 * bodypart can hold entries for several tattoo zones at once.
 * Plain nested lists (not a datum) because savefiles serialize them natively.
 */

/obj/item/bodypart
	/// List of tattoo entries on this bodypart. See the header above for the format.
	var/list/tattoos

/// Returns a deep copy of a tattoo entry, so mutating the copy never touches the original.
/proc/copy_tattoo_entry(list/entry)
	return list(
		"zone" = entry["zone"],
		"text" = entry["text"],
		"style" = entry["style"],
		"color" = entry["color"],
		"state" = entry["state"],
	)

/// How many tattoos this bodypart holds for one specific zone.
/obj/item/bodypart/proc/count_tattoos_on_zone(zone)
	. = 0
	for(var/list/entry in tattoos)
		if(entry["zone"] == zone)
			.++

/// Adds a new fresh tattoo entry for the given zone. Returns FALSE if that zone is already full.
/obj/item/bodypart/proc/add_tattoo(zone, text, style, color)
	LAZYINITLIST(tattoos)
	if(count_tattoos_on_zone(zone) >= MAXIMUM_TATTOOS_PER_ZONE)
		return FALSE
	tattoos += list(list(
		"zone" = zone,
		"text" = text,
		"style" = style,
		"color" = color,
		"state" = TATTOO_STATE_FRESH,
	))
	return TRUE

/*
 * EXAMINE
 *
 * NOTE (simplification): coverage is checked per broad zone using outer layers
 * only (gloves for hands, a face-hiding mask/helmet for the head, a shirt for
 * chest/arms/legs). This intentionally does not use the full flags_inv/HIDE*
 * system clothing uses for sprite occlusion - it is good enough for "is this
 * tattoo visible in examine text" and is cheap to run.
 */

/mob/living/carbon/human/proc/is_tattoo_zone_visible(zone)
	switch(zone)
		if(BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND)
			return !gloves
		if(BODY_ZONE_HEAD)
			if(wear_mask?.flags_inv & HIDEFACE)
				return FALSE
			var/obj/item/clothing/head/worn_head = head
			if(istype(worn_head) && (worn_head.flags_inv & HIDEFACE))
				return FALSE
			return TRUE
		if(BODY_ZONE_CHEST, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
			return !wear_shirt
	return TRUE

/proc/format_tattoo_entry_text(list/entry)
	var/is_design = entry["style"] == TATTOO_STYLE_DESIGN
	var/inner = "<font color='[entry["color"]]'>[entry["text"]]</font>"
	return is_design ? inner : "\"[inner]\""

/mob/living/carbon/human/proc/get_tattoo_examine_text()
	var/output = ""
	for(var/obj/item/bodypart/BP as anything in bodyparts)
		if(!length(BP.tattoos))
			continue
		for(var/list/entry as anything in BP.tattoos)
			var/zone = entry["zone"]
			if(!(zone in GLOB.tattoo_zone_names))
				continue
			if(!is_tattoo_zone_visible(zone))
				continue
			var/faded_note = (entry["state"] == TATTOO_STATE_FADED) ? " (faded)" : ""
			output += span_notice("There is a tattoo on [p_their()] [GLOB.tattoo_zone_names[zone]]: [format_tattoo_entry_text(entry)][faded_note].\n")
	return output

/*
 * PERSISTENCE
 *
 * prefs.tattoos[zone] = list(entry, entry, ...)
 */

/datum/preferences
	/// Saved tattoos, keyed by body zone. See the bodypart storage header for the entry format.
	var/list/tattoos = list()

/// Hard validation of everything loaded from the savefile: unknown zones,
/// malformed entries, oversized text, bad colours, out-of-range enums and
/// over-cap zones are all dropped or clamped.
/datum/preferences/proc/validate_tattoos()
	if(!islist(tattoos))
		tattoos = list()
		return
	var/static/list/valid_styles = list(TATTOO_STYLE_LETTERING, TATTOO_STYLE_DESIGN)
	for(var/zone in tattoos)
		if(!(zone in GLOB.tattoo_zone_names))
			tattoos -= zone
			continue
		var/list/entries = tattoos[zone]
		if(!islist(entries))
			tattoos -= zone
			continue
		for(var/list/entry in entries.Copy())
			if(!islist(entry) || !istext(entry["text"]) || !length(entry["text"]))
				entries -= entry
				continue
			entry["zone"] = zone
			entry["text"] = copytext(entry["text"], 1, TATTOO_TEXT_MAX_LENGTH * 2) // *2: html entities from encoding inflate length
			entry["color"] = sanitize_hexcolor(entry["color"], 6, TRUE, "#2B2B2B")
			if(!(entry["style"] in valid_styles))
				entry["style"] = TATTOO_STYLE_DESIGN
			if(entry["state"] != TATTOO_STATE_FRESH && entry["state"] != TATTOO_STATE_FADED)
				entry["state"] = TATTOO_STATE_FRESH
		if(length(entries) > MAXIMUM_TATTOOS_PER_ZONE)
			entries.Cut(MAXIMUM_TATTOOS_PER_ZONE + 1)
		if(!length(entries))
			tattoos -= zone

/// Copies the saved tattoos onto a freshly spawned human. Call from apply_prefs_to()
/// AFTER set_species()/bodypart setup, or the new bodyparts will wipe them.
/datum/preferences/proc/apply_tattoos_to_human(mob/living/carbon/human/character)
	if(!ishuman(character))
		return
	for(var/zone in tattoos)
		var/obj/item/bodypart/BP = character.get_bodypart(zone)
		if(!BP)
			continue
		LAZYINITLIST(BP.tattoos)
		for(var/list/entry in tattoos[zone])
			BP.tattoos += list(copy_tattoo_entry(entry))

/// Reads the current tattoos off the human's bodyparts back into prefs, and saves.
/// Called after a tattoo is added or changes state, as a safety net against
/// server crashes losing the change.
/mob/living/carbon/human/proc/save_tattoos_now()
	if(!client?.prefs)
		return FALSE
	var/list/new_tattoos = list()
	for(var/obj/item/bodypart/BP as anything in bodyparts)
		for(var/list/entry in BP.tattoos)
			var/zone = entry["zone"]
			if(!(zone in GLOB.tattoo_zone_names))
				continue
			if(!new_tattoos[zone])
				new_tattoos[zone] = list()
			new_tattoos[zone] += list(copy_tattoo_entry(entry))
	client.prefs.tattoos = new_tattoos
	client.prefs.save_character()
	return TRUE

/*
 * WASHING
 *
 * Charcoal/natural pigment isn't permanent the way modern ink would be:
 *  - plain water                          : FRESH -> FADED
 *  - soap/scrubbing (fingerprint/fibre)   : FRESH -> FADED, and FADED -> gone
 *
 * Simplification: this does not check whether the zone is covered by clothing
 * before washing it - it assumes the character is washing bare skin.
 */

/mob/living/carbon/human/proc/process_tattoo_wash(clean_types)
	var/is_scrub = clean_types & (CLEAN_TYPE_FINGERPRINTS | CLEAN_TYPE_FIBERS)
	var/faded_any = FALSE
	var/removed_any = FALSE

	for(var/obj/item/bodypart/BP as anything in bodyparts)
		if(!length(BP.tattoos))
			continue
		for(var/list/entry in BP.tattoos.Copy())
			switch(entry["state"])
				if(TATTOO_STATE_FRESH)
					entry["state"] = TATTOO_STATE_FADED
					faded_any = TRUE
				if(TATTOO_STATE_FADED)
					if(is_scrub)
						BP.tattoos -= entry
						removed_any = TRUE

	if(!faded_any && !removed_any)
		return FALSE

	if(removed_any)
		to_chat(src, span_notice("Some of your tattoos have scrubbed away entirely."))
	else
		to_chat(src, span_notice("Some of your tattoos have washed out a little."))
	save_tattoos_now()
	return TRUE

/*
 * THE NEEDLE
 *
 * Self-application only - there is no consent flow because you can never use
 * this on anyone but yourself; attack_self() is the only entry point.
 */

/obj/item/tattoo_needle
	name = "tattoo needle"
	desc = "A wooden handle with a bound needle and a small inkwell. Used to hand-poke tattoos into skin, one prick at a time."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "needle" // TODO: dedicated sprite; reusing the sewing needle for now
	item_weight = 10 GRAMS
	w_class = WEIGHT_CLASS_SMALL
	force = 0
	throwforce = 0
	item_flags = NOBLUDGEON
	resistance_flags = FLAMMABLE
	grid_width = 32
	grid_height = 32

	/// Hex colour of the pigment currently loaded in the inkwell
	var/ink_color = "#2B2B2B"
	/// Display name of the current pigment
	var/ink_style = "Charcoal Black"

/obj/item/tattoo_needle/examine(mob/user)
	. = ..()
	. += span_notice("The inkwell holds [ink_style] pigment.")
	. += span_notice("Alt-click to swap the pigment.")
	. += span_warning("A tattoo made with this will only wash away with water and soap - or come off for good under a surgeon's blade.")

/obj/item/tattoo_needle/AltClick(mob/user, list/modifiers)
	. = ..()
	if(!user.can_perform_action(src, NEED_DEXTERITY))
		return
	var/choice = input(user, "Choose a pigment to load:", "Tattoo Pigment") as null|anything in GLOB.tattoo_ink_colors
	if(!choice || !user.can_perform_action(src, NEED_DEXTERITY))
		return
	ink_color = GLOB.tattoo_ink_colors[choice]
	ink_style = choice
	to_chat(user, span_notice("You load [src] with [ink_style] pigment."))

/obj/item/tattoo_needle/attack_self(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(!ishuman(user))
		to_chat(user, span_warning("You don't have the right kind of skin for this!"))
		return
	var/mob/living/carbon/human/artist = user
	if(!artist.can_perform_action(src, NEED_DEXTERITY))
		return

	var/selected_zone = select_tattoo_zone_radial(artist)
	if(!selected_zone)
		return

	// Precise zones (hands) resolve to the owning limb
	var/obj/item/bodypart/BP = artist.get_bodypart(selected_zone)
	if(!BP)
		to_chat(artist, span_warning("You don't have that body part!"))
		return

	if(!artist.is_tattoo_zone_visible(selected_zone))
		to_chat(artist, span_warning("Your clothes are in the way there!"))
		return

	var/zone_name = GLOB.tattoo_zone_names[selected_zone]
	if(BP.count_tattoos_on_zone(selected_zone) >= MAXIMUM_TATTOOS_PER_ZONE)
		to_chat(artist, span_warning("There's no room left on your [zone_name] for another tattoo!"))
		return

	var/tattoo_text = tgui_input_text(artist, "Describe the tattoo (max [TATTOO_TEXT_MAX_LENGTH] characters):", "Tattoo - [zone_name]", max_length = TATTOO_TEXT_MAX_LENGTH)
	if(!tattoo_text || !artist.can_perform_action(src, NEED_DEXTERITY))
		return

	var/style_choice = tgui_alert(artist, "Is this lettering (shown in quotes, e.g. \"ACAB\") or a design (shown plain, e.g. a wolf's head)?", "Tattoo Style", list("Lettering", "Design"))
	if(!style_choice || !artist.can_perform_action(src, NEED_DEXTERITY))
		return

	// Input stalling: the prompts above can be held open indefinitely, so
	// re-validate the bodypart and the zone's capacity before starting.
	if(QDELETED(BP) || BP.owner != artist)
		return
	if(BP.count_tattoos_on_zone(selected_zone) >= MAXIMUM_TATTOOS_PER_ZONE)
		to_chat(artist, span_warning("There's no room left on your [zone_name] for another tattoo!"))
		return

	to_chat(artist, span_notice("You begin poking a tattoo into your [zone_name]..."))
	artist.adjust_jitter(10 SECONDS)
	artist.add_movespeed_modifier(MOVESPEED_ID_TATTOO_PAIN, multiplicative_slowdown = 0.3)

	var/success = do_after(artist, 8 SECONDS, artist, interaction_key = "tattoo_needle")

	if(!QDELETED(artist))
		artist.remove_movespeed_modifier(MOVESPEED_ID_TATTOO_PAIN)

	if(!success || QDELETED(artist))
		to_chat(artist, span_warning("You stop before finishing the tattoo."))
		return

	// The limb may have been lost or swapped during the do_after
	if(QDELETED(BP) || BP.owner != artist)
		to_chat(artist, span_warning("You stop before finishing the tattoo."))
		return

	if(!BP.add_tattoo(selected_zone, tattoo_text, (style_choice == "Lettering") ? TATTOO_STYLE_LETTERING : TATTOO_STYLE_DESIGN, ink_color))
		to_chat(artist, span_warning("There's no room left on your [zone_name] for another tattoo!"))
		return

	to_chat(artist, span_notice("You finish poking the tattoo into your [zone_name]."))
	artist.apply_damage(2, BRUTE, selected_zone)
	artist.save_tattoos_now()

/// Radial zone picker limited to the zones the user actually has bodyparts for.
/obj/item/tattoo_needle/proc/select_tattoo_zone_radial(mob/living/carbon/human/user)
	var/list/choices = list()
	for(var/zone in GLOB.tattoo_zone_names)
		if(user.get_bodypart(zone))
			choices[GLOB.tattoo_zone_names[zone]] = GLOB.tattoo_radial_icons[zone]

	if(!length(choices))
		to_chat(user, span_warning("You don't have anywhere to put a tattoo!"))
		return null

	var/choice = show_radial_menu(user, user, choices, require_near = TRUE, tooltips = TRUE)
	if(!choice)
		return null

	for(var/zone in GLOB.tattoo_zone_names)
		if(GLOB.tattoo_zone_names[zone] == choice)
			return zone
	return null

/*
 * SURGERY
 *
 * Scrapes one tattoo out of the limb. OPERATION_LOOPING lets the surgeon keep
 * going until the limb is clean.
 */

/datum/surgery_operation/limb/scrape_tattoo
	name = "Scrape Away Tattoo"
	desc = "Scrape an unwanted tattoo out of a patient's skin. \
		Requires the skin to be open."

	implements = list(
		TOOL_SCALPEL = 1,
		TOOL_IMPROVISED_SCALPEL = 2,
	)

	time = 7 SECONDS

	skill_min = SKILL_LEVEL_APPRENTICE
	skill_median = SKILL_LEVEL_JOURNEYMAN

	operation_flags = OPERATION_LOOPING

	all_surgery_states_required = SURGERY_SKIN_OPEN

/datum/surgery_operation/limb/scrape_tattoo/all_required_strings()
	. = ..()
	. += "the limb must have a tattoo"

/datum/surgery_operation/limb/scrape_tattoo/state_check(obj/item/bodypart/limb)
	return length(limb.tattoos) > 0

/datum/surgery_operation/limb/scrape_tattoo/on_preop(obj/item/bodypart/limb, mob/living/surgeon, obj/item/tool, list/operation_args)
	display_results(
		surgeon,
		limb.owner,
		span_notice("I begin scraping the tattoo out of [limb.owner]'s [parse_zone(limb.body_zone)]..."),
		span_notice("[surgeon] begins scraping a tattoo out of [limb.owner]'s [parse_zone(limb.body_zone)]."),
		span_notice("[surgeon] begins scraping a tattoo out of [limb.owner]'s [parse_zone(limb.body_zone)]."),
	)
	display_pain(limb.owner, "My [parse_zone(limb.body_zone)] burns as the ink is scraped out!")

/datum/surgery_operation/limb/scrape_tattoo/on_success(obj/item/bodypart/limb, mob/living/surgeon, obj/item/tool, list/operation_args)
	display_results(
		surgeon,
		limb.owner,
		span_notice("I scrape the tattoo out of [limb.owner]'s [parse_zone(limb.body_zone)], leaving raw skin behind."),
		span_notice("[surgeon] scrapes a tattoo out of [limb.owner]'s [parse_zone(limb.body_zone)]!"),
		span_notice("[surgeon] scrapes a tattoo out of [limb.owner]'s [parse_zone(limb.body_zone)]!"),
	)

	if(length(limb.tattoos))
		limb.tattoos.Cut(1, 2) // remove the oldest tattoo on this limb

	limb.receive_damage(6, flashes = TRUE)

	var/mob/living/carbon/human/patient = limb.owner
	if(ishuman(patient))
		patient.save_tattoos_now()

/datum/surgery_operation/limb/scrape_tattoo/on_failure(obj/item/bodypart/limb, mob/living/surgeon, tool, list/operation_args)
	display_results(
		surgeon,
		limb.owner,
		span_warning("I slip, gouging [limb.owner]'s [parse_zone(limb.body_zone)] without touching the ink!"),
		span_warning("[surgeon] slips, gouging [limb.owner]'s [parse_zone(limb.body_zone)]!"),
		span_warning("[surgeon] slips, gouging [limb.owner]'s [parse_zone(limb.body_zone)]!"),
	)
	display_pain(limb.owner, "I feel the blade dig into my [parse_zone(limb.body_zone)]!")

	limb.receive_damage(15, flashes = TRUE)

/*
 * CHARACTER CREATOR PAGE
 *
 * Mirrors the href/topic style of preferences_body_markings.dm rather than
 * tgui, to stay consistent with the rest of the prefs menu this hooks into.
 */

/datum/preferences/proc/handle_tattoo_topic(mob/user, href_list)
	switch(href_list["preference"])
		if("add_tattoo")
			var/zone = href_list["key"]
			if(!(zone in GLOB.tattoo_zone_names))
				return
			var/list/entries = LAZYACCESS(tattoos, zone)
			if(length(entries) >= MAXIMUM_TATTOOS_PER_ZONE)
				return
			var/tattoo_text = tgui_input_text(user, "Describe the tattoo (max [TATTOO_TEXT_MAX_LENGTH] characters):", "Tattoo - [GLOB.tattoo_zone_names[zone]]", max_length = TATTOO_TEXT_MAX_LENGTH)
			if(!tattoo_text)
				return
			var/style_choice = tgui_alert(user, "Lettering (shown in quotes) or a design (shown plain)?", "Tattoo Style", list("Lettering", "Design"))
			if(!style_choice)
				return
			var/color_choice = input(user, "Choose a pigment:", "Tattoo Pigment") as null|anything in GLOB.tattoo_ink_colors
			if(!color_choice)
				return
			// Input stalling: the prompts above can be held open while more
			// add dialogs are stacked, so re-check the cap before committing.
			entries = LAZYACCESS(tattoos, zone)
			if(length(entries) >= MAXIMUM_TATTOOS_PER_ZONE)
				return
			LAZYINITLIST(tattoos)
			if(!tattoos[zone])
				tattoos[zone] = list()
			tattoos[zone] += list(list(
				"zone" = zone,
				"text" = tattoo_text,
				"style" = (style_choice == "Lettering") ? TATTOO_STYLE_LETTERING : TATTOO_STYLE_DESIGN,
				"color" = GLOB.tattoo_ink_colors[color_choice],
				"state" = TATTOO_STATE_FRESH,
			))
		if("remove_tattoo")
			var/zone = href_list["key"]
			var/index = text2num(href_list["index"])
			var/list/entries = LAZYACCESS(tattoos, zone)
			if(!entries || !index || index < 1 || index > length(entries))
				return
			entries.Cut(index, index + 1)
			if(!length(entries))
				tattoos -= zone
	mark_preview_appearance_dirty()

/datum/preferences/proc/print_tattoo_page()
	var/list/dat = list()
	dat += "<div class='notice'>These are the tattoos your character starts with, written or described in your own words. Only natural, period-appropriate pigments - no modern ink.</div>"
	dat += "<table width='100%'>"
	for(var/zone in GLOB.tattoo_zone_names)
		var/zone_name = GLOB.tattoo_zone_names[zone]
		dat += "<tr><td colspan='2'><h3>[capitalize(zone_name)]</h3></td></tr>"
		var/list/entries = LAZYACCESS(tattoos, zone)
		if(length(entries))
			for(var/i in 1 to length(entries))
				var/list/entry = entries[i]
				var/preview = (entry["style"] == TATTOO_STYLE_DESIGN) ? entry["text"] : "\"[entry["text"]]\""
				dat += "<tr><td width='80%'><font color='[entry["color"]]'>[preview]</font></td>"
				dat += "<td width='20%'><a href='?_src_=prefs;preference=remove_tattoo;task=change_tattoo;key=[zone];index=[i]'>Remove</a></td></tr>"
		if(length(entries) < MAXIMUM_TATTOOS_PER_ZONE)
			dat += "<tr><td colspan='2'><a href='?_src_=prefs;preference=add_tattoo;task=change_tattoo;key=[zone]'>Add a tattoo</a></td></tr>"
	dat += "</table>"
	return dat

/datum/preferences/proc/ShowTattoos(mob/user)
	var/list/dat = list()
	dat += print_tattoo_page()
	var/datum/browser/popup = new(user, "tattoo_customization", "<div align='center'>Tattoo customization</div>", 480, 600)
	popup.set_content(dat.Join())
	popup.open(FALSE)

#undef TATTOO_STATE_FRESH
#undef TATTOO_STATE_FADED
#undef MAXIMUM_TATTOOS_PER_ZONE
#undef TATTOO_STYLE_LETTERING
#undef TATTOO_STYLE_DESIGN
#undef TATTOO_TEXT_MAX_LENGTH
#undef MOVESPEED_ID_TATTOO_PAIN
