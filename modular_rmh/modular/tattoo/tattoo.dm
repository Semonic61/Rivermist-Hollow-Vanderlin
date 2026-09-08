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

/// Tattoo-only zones. These are not bodyparts - they are finer-grained spots
/// that live on a bodypart, see GLOB.tattoo_zone_data.
#define TATTOO_ZONE_FOREHEAD "tattoo_forehead"
#define TATTOO_ZONE_CHEEKS "tattoo_cheeks"
#define TATTOO_ZONE_CHIN "tattoo_chin"
#define TATTOO_ZONE_LIPS "tattoo_lips"
#define TATTOO_ZONE_EARS "tattoo_ears"
#define TATTOO_ZONE_HORNS "tattoo_horns"
#define TATTOO_ZONE_NECK "tattoo_neck"
#define TATTOO_ZONE_BACK "tattoo_back"
#define TATTOO_ZONE_BELLY "tattoo_belly"
#define TATTOO_ZONE_WINGS "tattoo_wings"
#define TATTOO_ZONE_TAIL "tattoo_tail"
#define TATTOO_ZONE_L_THIGH "tattoo_l_thigh"
#define TATTOO_ZONE_R_THIGH "tattoo_r_thigh"
#define TATTOO_ZONE_BREASTS "tattoo_breasts"
#define TATTOO_ZONE_GROIN "tattoo_groin"
#define TATTOO_ZONE_BUTTOCKS "tattoo_buttocks"
#define TATTOO_ZONE_PENIS "tattoo_penis"
#define TATTOO_ZONE_VAGINA "tattoo_vagina"
#define TATTOO_ZONE_L_FOOT "tattoo_l_foot"
#define TATTOO_ZONE_R_FOOT "tattoo_r_foot"

/*
 * ZONE TABLE
 *
 * Tattoo zones are finer-grained than bodyparts: "forehead", "left thigh" and
 * "belly" all live on a bodypart that covers much more than themselves. Each
 * zone therefore declares:
 *   "name"    - display name, used in chat and examine
 *   "limb"    - which bodypart actually stores the entry
 *   "organ"   - optional ORGAN_SLOT_* that must exist for the zone to be valid
 *               (this is what stops you tattooing wings you don't have)
 *   "cover"   - which clothing check hides it, see is_tattoo_zone_visible()
 *
 * Ordered head -> feet: examine output walks this list in order, so the listing
 * always reads top-down regardless of what order tattoos were applied in.
 *
 * Note: the intimate zones from the source build (breasts, groin, buttocks,
 * genitals) are deliberately not carried over - this is a cosmetic system.
 */
GLOBAL_LIST_INIT(tattoo_zone_data, list(
	TATTOO_ZONE_FOREHEAD = list("name" = "forehead", "limb" = BODY_ZONE_HEAD, "cover" = "face"),
	TATTOO_ZONE_CHEEKS = list("name" = "cheeks", "limb" = BODY_ZONE_HEAD, "cover" = "face"),
	TATTOO_ZONE_CHIN = list("name" = "chin", "limb" = BODY_ZONE_HEAD, "cover" = "face"),
	TATTOO_ZONE_LIPS = list("name" = "lips", "limb" = BODY_ZONE_HEAD, "cover" = "face"),
	BODY_ZONE_HEAD = list("name" = "head", "limb" = BODY_ZONE_HEAD, "cover" = "face"),
	TATTOO_ZONE_EARS = list("name" = "ears", "limb" = BODY_ZONE_HEAD, "organ" = ORGAN_SLOT_EARS, "cover" = "face"),
	TATTOO_ZONE_HORNS = list("name" = "horns", "limb" = BODY_ZONE_HEAD, "organ" = ORGAN_SLOT_HORNS, "cover" = "face"),
	TATTOO_ZONE_NECK = list("name" = "neck", "limb" = BODY_ZONE_CHEST, "cover" = "shirt"),
	BODY_ZONE_CHEST = list("name" = "torso", "limb" = BODY_ZONE_CHEST, "cover" = "shirt"),
	TATTOO_ZONE_BACK = list("name" = "back", "limb" = BODY_ZONE_CHEST, "cover" = "shirt"),
	TATTOO_ZONE_BREASTS = list("name" = "breasts", "limb" = BODY_ZONE_CHEST, "organ" = ORGAN_SLOT_BREASTS, "customizer" = /datum/customizer_entry/organ/genitals/breasts, "cover" = "shirt", "intimate" = TRUE),
	TATTOO_ZONE_BELLY = list("name" = "belly", "limb" = BODY_ZONE_CHEST, "cover" = "shirt"),
	TATTOO_ZONE_WINGS = list("name" = "wings", "limb" = BODY_ZONE_CHEST, "organ" = ORGAN_SLOT_WINGS, "cover" = "shirt"),
	BODY_ZONE_L_ARM = list("name" = "left arm", "limb" = BODY_ZONE_L_ARM, "cover" = "shirt"),
	BODY_ZONE_R_ARM = list("name" = "right arm", "limb" = BODY_ZONE_R_ARM, "cover" = "shirt"),
	BODY_ZONE_PRECISE_L_HAND = list("name" = "left hand", "limb" = BODY_ZONE_L_ARM, "cover" = "gloves"),
	BODY_ZONE_PRECISE_R_HAND = list("name" = "right hand", "limb" = BODY_ZONE_R_ARM, "cover" = "gloves"),
	TATTOO_ZONE_GROIN = list("name" = "groin", "limb" = BODY_ZONE_CHEST, "cover" = "pants", "intimate" = TRUE),
	TATTOO_ZONE_PENIS = list("name" = "cock", "limb" = BODY_ZONE_CHEST, "organ" = ORGAN_SLOT_PENIS, "customizer" = /datum/customizer_entry/organ/genitals/penis, "cover" = "pants", "intimate" = TRUE),
	TATTOO_ZONE_VAGINA = list("name" = "cunt", "limb" = BODY_ZONE_CHEST, "organ" = ORGAN_SLOT_VAGINA, "customizer" = /datum/customizer_entry/organ/genitals/vagina, "cover" = "pants", "intimate" = TRUE),
	TATTOO_ZONE_BUTTOCKS = list("name" = "buttocks", "limb" = BODY_ZONE_CHEST, "cover" = "pants", "intimate" = TRUE),
	TATTOO_ZONE_TAIL = list("name" = "tail", "limb" = BODY_ZONE_CHEST, "organ" = ORGAN_SLOT_TAIL, "cover" = "pants"),
	BODY_ZONE_L_LEG = list("name" = "left leg", "limb" = BODY_ZONE_L_LEG, "cover" = "pants"),
	BODY_ZONE_R_LEG = list("name" = "right leg", "limb" = BODY_ZONE_R_LEG, "cover" = "pants"),
	TATTOO_ZONE_L_THIGH = list("name" = "left thigh", "limb" = BODY_ZONE_L_LEG, "cover" = "pants"),
	TATTOO_ZONE_R_THIGH = list("name" = "right thigh", "limb" = BODY_ZONE_R_LEG, "cover" = "pants"),
	TATTOO_ZONE_L_FOOT = list("name" = "left foot", "limb" = BODY_ZONE_L_LEG, "cover" = "shoes"),
	TATTOO_ZONE_R_FOOT = list("name" = "right foot", "limb" = BODY_ZONE_R_LEG, "cover" = "shoes"),
))

/// Maps a targeted body zone (the doll in the player's HUD) to the tattoo zones
/// that live on it, so picking "head" on the doll offers forehead/cheeks/etc.
GLOBAL_LIST_INIT(tattoo_zones_by_limb, build_tattoo_zones_by_limb())

/proc/build_tattoo_zones_by_limb()
	var/list/result = list()
	for(var/zone in GLOB.tattoo_zone_data)
		var/list/zone_data = GLOB.tattoo_zone_data[zone]
		var/limb = zone_data["limb"]
		if(!result[limb])
			result[limb] = list()
		result[limb] += zone
	return result

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

/// Display name for a tattoo zone.
/proc/tattoo_zone_name(zone)
	var/list/zone_data = GLOB.tattoo_zone_data[zone]
	return zone_data ? zone_data["name"] : zone

/// Which bodypart stores entries for this tattoo zone.
/proc/tattoo_zone_limb(zone)
	var/list/zone_data = GLOB.tattoo_zone_data[zone]
	return zone_data ? zone_data["limb"] : null

/// Is this an intimate zone? Tattooing someone else there needs their consent.
/proc/tattoo_zone_is_intimate(zone)
	var/list/zone_data = GLOB.tattoo_zone_data[zone]
	return zone_data ? !!zone_data["intimate"] : FALSE

/**
 * Pigment colour adjusted for chat legibility.
 *
 * Most players run a near-black chat background, where charcoal and soot are
 * effectively invisible. This lifts any pigment that is too dark to read
 * without changing its hue, so a "Charcoal Black" tattoo still reads as the
 * darkest of the greys rather than vanishing into the background.
 * The character sheet preview shows the true pigment on parchment instead.
 */
/proc/tattoo_chat_color(color)
	var/list/rgb_list = ReadRGB(color)
	if(!length(rgb_list))
		return "#d8cf9f"
	var/red = rgb_list[1]
	var/green = rgb_list[2]
	var/blue = rgb_list[3]
	// Rec. 601 luma, the usual cheap brightness approximation
	var/luma = (0.299 * red) + (0.587 * green) + (0.114 * blue)
	var/minimum_luma = 110
	if(luma >= minimum_luma)
		return color
	// Pure black has no hue to preserve, so give it a legible warm grey
	if(luma <= 1)
		return "#9a9a9a"
	var/scale = minimum_luma / luma
	red = min(255, round(red * scale))
	green = min(255, round(green * scale))
	blue = min(255, round(blue * scale))
	return rgb(red, green, blue)

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
 * VISIBILITY AND EXAMINE OUTPUT
 *
 * Coverage is checked per zone using the outer layer that would hide it.
 * This intentionally does not use the full flags_inv/HIDE* occlusion system
 * clothing uses for sprites - it is good enough for "can an onlooker read this
 * tattoo" and is cheap to run.
 */

/mob/living/carbon/human/proc/is_tattoo_zone_visible(zone)
	var/list/zone_data = GLOB.tattoo_zone_data[zone]
	if(!zone_data)
		return FALSE
	switch(zone_data["cover"])
		if("gloves")
			return !gloves
		if("shoes")
			return !shoes
		if("pants")
			return !wear_pants
		if("shirt")
			return !wear_shirt && !wear_armor
		if("face")
			if(wear_mask?.flags_inv & HIDEFACE)
				return FALSE
			var/obj/item/clothing/head/worn_head = head
			if(istype(worn_head) && (worn_head.flags_inv & HIDEFACE))
				return FALSE
			return TRUE
	return TRUE

/// Does this character have the body part a zone needs? Wings zones need wings.
/mob/living/carbon/human/proc/has_tattoo_zone(zone)
	var/list/zone_data = GLOB.tattoo_zone_data[zone]
	if(!zone_data)
		return FALSE
	if(!get_bodypart(zone_data["limb"]))
		return FALSE
	var/needed_organ = zone_data["organ"]
	if(needed_organ && !getorganslot(needed_organ))
		return FALSE
	return TRUE

/// Display name of the pigment a tattoo was inked with, matched back from its hex.
/proc/tattoo_pigment_name(color)
	for(var/pigment_name in GLOB.tattoo_ink_colors)
		if(GLOB.tattoo_ink_colors[pigment_name] == color)
			return pigment_name
	return "unknown pigment"

/**
 * The tattoo itself, as it appears in chat.
 *
 * Dotted underline marks it as the inked part of the sentence, and hovering it
 * names the pigment - the rendered colour is brightened for legibility on dark
 * chat backgrounds, so the tooltip is where the true pigment is stated.
 * Quotes for lettering sit outside the span: they are punctuation, not ink.
 */
/proc/format_tattoo_entry_text(list/entry)
	var/is_design = entry["style"] == TATTOO_STYLE_DESIGN
	var/inner = "<span style='color: [tattoo_chat_color(entry["color"])]; text-decoration: underline dotted;' title='[tattoo_pigment_name(entry["color"])]'>[entry["text"]]</span>"
	return is_design ? inner : "\"[inner]\""

/**
 * Builds the tattoo lines shown at the end of the Look at Features text.
 *
 * Walks GLOB.tattoo_zone_data in declaration order, which runs head -> feet,
 * so the listing always reads top-down. Zones hidden by clothing are skipped,
 * so a cloaked character shows nothing while a bare-chested one shows their
 * torso work.
 *
 * Lettering reads   : On the right arm is written: "TEXT"
 * A design reads    : On the left leg: a coiled serpent
 */
/mob/living/carbon/human/proc/get_tattoo_description_lines()
	var/list/lines = list()
	for(var/zone in GLOB.tattoo_zone_data)
		var/obj/item/bodypart/BP = get_bodypart(tattoo_zone_limb(zone))
		if(!BP || !length(BP.tattoos))
			continue
		if(!is_tattoo_zone_visible(zone))
			continue
		for(var/list/entry as anything in BP.tattoos)
			if(entry["zone"] != zone)
				continue
			var/faded_note = (entry["state"] == TATTOO_STATE_FADED) ? " (faded)" : ""
			if(entry["style"] == TATTOO_STYLE_DESIGN)
				lines += "On the [tattoo_zone_name(zone)] [format_tattoo_entry_text(entry)][faded_note]"
			else
				lines += "On the [tattoo_zone_name(zone)] is written: [format_tattoo_entry_text(entry)][faded_note]"
	return lines

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
		if(!(zone in GLOB.tattoo_zone_data))
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
		// Tattoo zones are finer-grained than bodyparts ("lips" lives on the
		// head), so resolve the owning limb rather than looking the zone up
		// as a bodypart - get_bodypart("tattoo_lips") is always null.
		var/limb_zone = tattoo_zone_limb(zone)
		if(!limb_zone)
			continue
		var/obj/item/bodypart/BP = character.get_bodypart(limb_zone)
		if(!BP)
			continue
		LAZYINITLIST(BP.tattoos)
		for(var/list/entry in tattoos[zone])
			var/list/copied = copy_tattoo_entry(entry)
			copied["zone"] = zone // savefiles from before zones were stored per-entry
			BP.tattoos += list(copied)

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
			if(!(zone in GLOB.tattoo_zone_data))
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
 * Applied by clicking a person with the needle in hand - yourself or someone
 * else. The spot comes from the body zone targeted on the HUD doll, exactly
 * like every other targeted interaction. If a limb hosts several tattoo spots
 * (the head has forehead, cheeks, chin and so on) a short list asks which.
 *
 * Tattooing someone else takes longer and needs them to hold still - walking
 * away cancels it, which is the consent mechanic for ordinary spots. Intimate
 * spots additionally require the target to have enabled the matching ERP
 * preference, so nobody gets written on where they didn't agree to.
 */

/datum/erp_preference/boolean/allow_intimate_tattoos
	name = "Intimate Tattoos"
	description = "Whether others may tattoo your intimate areas (breasts, groin, buttocks, genitals)"
	default_value = FALSE
	category = "General"

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
	. += span_info("Target a body zone, then click yourself or someone else to tattoo them there.")
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

/// Clicking a person - self or otherwise - is the way tattoos get applied.
/obj/item/tattoo_needle/attack(mob/living/target, mob/living/user, list/modifiers)
	if(!ishuman(target) || !ishuman(user))
		return ..()
	try_tattoo(target, user)
	return TRUE

/// Using it in hand tattoos yourself, as a convenience for the common case.
/obj/item/tattoo_needle/attack_self(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(!ishuman(user))
		to_chat(user, span_warning("You don't have the right kind of skin for this!"))
		return
	try_tattoo(user, user)

/obj/item/tattoo_needle/proc/try_tattoo(mob/living/carbon/human/patient, mob/living/carbon/human/artist)
	if(!istype(patient) || !istype(artist))
		return
	if(!artist.can_perform_action(src, NEED_DEXTERITY))
		return

	var/is_self = (patient == artist)

	var/selected_zone = pick_tattoo_zone_for_target(patient, artist, is_self)
	if(!selected_zone)
		return

	var/zone_name = tattoo_zone_name(selected_zone)
	var/obj/item/bodypart/BP = patient.get_bodypart(tattoo_zone_limb(selected_zone))
	if(!BP)
		to_chat(artist, span_warning("[is_self ? "You don't" : "[patient] doesn't"] have that body part!"))
		return

	if(!patient.is_tattoo_zone_visible(selected_zone))
		to_chat(artist, span_warning("[is_self ? "Your" : "[patient]'s"] clothes are in the way there!"))
		return

	if(BP.count_tattoos_on_zone(selected_zone) >= MAXIMUM_TATTOOS_PER_ZONE)
		to_chat(artist, span_warning("There's no room left on [is_self ? "your" : "[patient]'s"] [zone_name] for another tattoo!"))
		return

	var/tattoo_text = tgui_input_text(artist, "Describe the tattoo (max [TATTOO_TEXT_MAX_LENGTH] characters):", "Tattoo - [zone_name]", max_length = TATTOO_TEXT_MAX_LENGTH)
	if(!tattoo_text || !artist.can_perform_action(src, NEED_DEXTERITY))
		return

	var/style_choice = tgui_alert(artist, "Is this lettering (shown in quotes, e.g. \"ACAB\") or a design (shown plain, e.g. a wolf's head)?", "Tattoo Style", list("Lettering", "Design"))
	if(!style_choice || !artist.can_perform_action(src, NEED_DEXTERITY))
		return

	// Input stalling: the prompts above can be held open indefinitely, so
	// re-validate everything that could have changed meanwhile.
	if(QDELETED(BP) || BP.owner != patient || QDELETED(patient))
		return
	if(!can_use_tattoo_zone(patient, artist, selected_zone, is_self))
		return
	if(BP.count_tattoos_on_zone(selected_zone) >= MAXIMUM_TATTOOS_PER_ZONE)
		to_chat(artist, span_warning("There's no room left on [is_self ? "your" : "[patient]'s"] [zone_name] for another tattoo!"))
		return

	var/tattoo_time = is_self ? 8 SECONDS : 12 SECONDS

	if(is_self)
		to_chat(artist, span_notice("You begin poking a tattoo into your [zone_name]..."))
	else
		artist.visible_message(
			span_notice("[artist] begins poking a tattoo into [patient]'s [zone_name]..."),
			span_notice("You begin poking a tattoo into [patient]'s [zone_name]..."),
		)
		to_chat(patient, span_warning("[artist] begins poking a tattoo into your [zone_name]!"))

	patient.adjust_jitter(10 SECONDS)
	artist.add_movespeed_modifier(MOVESPEED_ID_TATTOO_PAIN, multiplicative_slowdown = 0.3)

	var/success = do_after(artist, tattoo_time, patient, interaction_key = "tattoo_needle")

	if(!QDELETED(artist))
		artist.remove_movespeed_modifier(MOVESPEED_ID_TATTOO_PAIN)

	if(!success || QDELETED(artist) || QDELETED(patient))
		to_chat(artist, span_warning("You stop before finishing the tattoo."))
		return

	// The limb may have been lost or swapped during the do_after
	if(QDELETED(BP) || BP.owner != patient)
		to_chat(artist, span_warning("You stop before finishing the tattoo."))
		return

	// ...and the needle may have been moved into the very arm being tattooed
	if(is_self && get_wielding_arm(artist) == tattoo_zone_limb(selected_zone))
		to_chat(artist, span_warning("You can't tattoo the very arm that's holding [src]."))
		return

	if(!can_use_tattoo_zone(patient, artist, selected_zone, is_self))
		return

	if(!BP.add_tattoo(selected_zone, tattoo_text, (style_choice == "Lettering") ? TATTOO_STYLE_LETTERING : TATTOO_STYLE_DESIGN, ink_color))
		to_chat(artist, span_warning("There's no room left on [is_self ? "your" : "[patient]'s"] [zone_name] for another tattoo!"))
		return

	if(is_self)
		to_chat(artist, span_notice("You finish poking the tattoo into your [zone_name]."))
	else
		artist.visible_message(
			span_notice("[artist] finishes the tattoo on [patient]'s [zone_name]."),
			span_notice("You finish the tattoo on [patient]'s [zone_name]."),
		)

	patient.apply_damage(2, BRUTE, tattoo_zone_limb(selected_zone))
	patient.save_tattoos_now()

/**
 * Shared gate for a zone: does the body part exist, and is the artist allowed
 * to work there? Intimate spots on someone else need that person's consent.
 */
/obj/item/tattoo_needle/proc/can_use_tattoo_zone(mob/living/carbon/human/patient, mob/living/carbon/human/artist, zone, is_self, quiet = FALSE)
	if(!patient.has_tattoo_zone(zone))
		return FALSE
	if(is_self || !tattoo_zone_is_intimate(zone))
		return TRUE
	if(patient.get_erp_pref(/datum/erp_preference/boolean/allow_intimate_tattoos))
		return TRUE
	if(!quiet)
		to_chat(artist, span_warning("[patient] isn't willing to be tattooed there."))
	return FALSE

/**
 * Which arm is holding this needle? Returns a BODY_ZONE_*_ARM or null.
 * Odd held indexes are left hands, even ones are right - same convention the
 * rest of the codebase uses (see /mob/proc/held_index_to_dir).
 */
/obj/item/tattoo_needle/proc/get_wielding_arm(mob/living/carbon/human/user)
	var/index = user.get_held_index_of_item(src)
	if(!index)
		return null
	return (index % 2 == 0) ? BODY_ZONE_R_ARM : BODY_ZONE_L_ARM

/obj/item/tattoo_needle/proc/pick_tattoo_zone_for_target(mob/living/carbon/human/patient, mob/living/carbon/human/artist, is_self)
	var/targeted = artist.zone_selected
	var/list/candidates = GLOB.tattoo_zones_by_limb[targeted]

	// Precise zones (hands) target their own limb, so fall back to the limb itself
	if(!candidates)
		candidates = GLOB.tattoo_zones_by_limb[deprecise_zone(targeted)]

	// You can't poke a tattoo into the very arm that's holding the needle
	var/busy_arm = is_self ? get_wielding_arm(artist) : null

	var/list/valid = list()
	var/blocked_by_hand = FALSE
	var/blocked_by_consent = FALSE
	for(var/zone in candidates)
		if(!patient.has_tattoo_zone(zone))
			continue
		if(busy_arm && tattoo_zone_limb(zone) == busy_arm)
			blocked_by_hand = TRUE
			continue
		if(!can_use_tattoo_zone(patient, artist, zone, is_self, quiet = TRUE))
			blocked_by_consent = TRUE
			continue
		valid += zone

	if(!length(valid))
		if(blocked_by_hand)
			to_chat(artist, span_warning("You can't tattoo the very arm that's holding [src] - switch hands first."))
		else if(blocked_by_consent)
			to_chat(artist, span_warning("[patient] isn't willing to be tattooed there."))
		else
			to_chat(artist, span_warning("There's nowhere to put a tattoo there."))
		return null

	if(length(valid) == 1)
		return valid[1]

	var/list/by_name = list()
	for(var/zone in valid)
		by_name[capitalize(tattoo_zone_name(zone))] = zone

	var/choice = input(artist, "Where exactly?", "Tattoo Placement") as null|anything in by_name
	if(!choice)
		return null
	return by_name[choice]

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
 * Reached from Character Setup -> Body -> Tattoos. Lists every zone grouped
 * head -> feet, with what is already inked there and an Add link per zone.
 *
 * Zones the character can't have are still listed but refuse to be used - the
 * preview mob is consulted for wings/horns/tail/ears, and picking one you
 * don't have explains why instead of silently doing nothing.
 */

/// Does the character being edited have what this zone needs?
/// Checked against the selected species' organ list, so a race without wings
/// can't pre-write wing tattoos. Optional organ slots (hollowkin horns and the
/// like) are allowed - the needle re-checks for real in-round anyway.
/datum/preferences/proc/preview_has_tattoo_zone(zone)
	var/list/zone_data = GLOB.tattoo_zone_data[zone]
	if(!zone_data)
		return FALSE
	// Genitals and breasts aren't species organs on this fork - they're
	// per-character customizer entries toggled On/Off in the editor, so ask
	// the customizer rather than the species organ list.
	var/customizer_entry_type = zone_data["customizer"]
	if(customizer_entry_type)
		return has_enabled_customizer_entry_type(customizer_entry_type)

	var/needed_organ = zone_data["organ"]
	if(!needed_organ)
		return TRUE
	var/datum/species/species = pref_species
	if(!species)
		return TRUE
	if(needed_organ in species.organs)
		return TRUE
	if(needed_organ in species.optional_organ_slots)
		return TRUE
	return FALSE

/**
 * TGUI window datum. One per open window, disposed on close.
 * Follows the /datum/gossip_prefs pattern used by the other prefs sub-windows.
 */
/datum/tattoo_prefs
	var/mob/holder

/datum/tattoo_prefs/New(mob/user)
	holder = user

/datum/tattoo_prefs/Destroy()
	holder = null
	return ..()

/datum/tattoo_prefs/ui_close(mob/user)
	qdel(src)

/datum/tattoo_prefs/ui_state(mob/user)
	return GLOB.always_state

/datum/tattoo_prefs/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new /datum/tgui(user, src, "TattooManagement", "Tattoo Management")
		ui.open()

/datum/tattoo_prefs/ui_data(mob/user)
	var/list/entries = list()
	var/list/zones = list()
	var/list/pigments = list()

	var/datum/preferences/prefs = holder?.client?.prefs
	if(user == holder && prefs)
		// Walk the zone table rather than the saved list, so the listing always
		// reads head -> feet regardless of the order tattoos were added in.
		for(var/zone in GLOB.tattoo_zone_data)
			var/list/zone_entries = LAZYACCESS(prefs.tattoos, zone)
			for(var/i in 1 to length(zone_entries))
				var/list/entry = zone_entries[i]
				entries += list(list(
					"zone" = zone,
					"zone_name" = capitalize(tattoo_zone_name(zone)),
					"sentence_name" = tattoo_zone_name(zone),
					"text" = entry["text"],
					"style" = entry["style"],
					"color" = entry["color"],
					"pigment" = tattoo_pigment_name(entry["color"]),
					"state" = entry["state"],
					"index" = i,
				))
			zones += list(list(
				"key" = zone,
				"name" = capitalize(tattoo_zone_name(zone)),
				"sentence_name" = tattoo_zone_name(zone),
				"intimate" = tattoo_zone_is_intimate(zone),
				"present" = prefs.preview_has_tattoo_zone(zone),
				"count" = length(zone_entries),
			))

		for(var/pigment_name in GLOB.tattoo_ink_colors)
			pigments += list(list(
				"name" = pigment_name,
				"color" = GLOB.tattoo_ink_colors[pigment_name],
			))

	return list(
		"tattoos" = entries,
		"zones" = zones,
		"pigments" = pigments,
		"max_length" = TATTOO_TEXT_MAX_LENGTH,
		"max_per_zone" = MAXIMUM_TATTOOS_PER_ZONE,
	)

/datum/tattoo_prefs/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return TRUE

	if(ui.user != holder || !holder?.client?.prefs)
		return FALSE
	var/datum/preferences/prefs = holder.client.prefs

	switch(action)
		if("add_tattoo")
			var/zone = params["zone"]
			if(!(zone in GLOB.tattoo_zone_data))
				return FALSE
			if(!prefs.preview_has_tattoo_zone(zone))
				tgui_alert(holder, "Your character doesn't have [tattoo_zone_name(zone)] to tattoo.", "No Such Body Part", list("OK"))
				return FALSE

			var/list/entries = LAZYACCESS(prefs.tattoos, zone)
			if(length(entries) >= MAXIMUM_TATTOOS_PER_ZONE)
				return FALSE

			// Client-supplied, so sanitize everything rather than trusting the UI
			var/text = trim(sanitize(params["text"]), TATTOO_TEXT_MAX_LENGTH)
			if(!length(text))
				return FALSE

			var/style = (params["style"] == TATTOO_STYLE_LETTERING) ? TATTOO_STYLE_LETTERING : TATTOO_STYLE_DESIGN

			// Only accept colours we actually offer - no arbitrary hex from the client
			var/color = null
			for(var/pigment_name in GLOB.tattoo_ink_colors)
				if(GLOB.tattoo_ink_colors[pigment_name] == params["color"])
					color = GLOB.tattoo_ink_colors[pigment_name]
					break
			if(!color)
				return FALSE

			LAZYINITLIST(prefs.tattoos)
			if(!prefs.tattoos[zone])
				prefs.tattoos[zone] = list()
			prefs.tattoos[zone] += list(list(
				"zone" = zone,
				"text" = text,
				"style" = style,
				"color" = color,
				"state" = TATTOO_STATE_FRESH,
			))
			prefs.save_character()
			prefs.mark_preview_appearance_dirty()
			return TRUE

		if("remove_tattoo")
			var/zone = params["zone"]
			var/index = text2num(params["index"])
			var/list/entries = LAZYACCESS(prefs.tattoos, zone)
			if(!entries || !index || index < 1 || index > length(entries))
				return FALSE
			entries.Cut(index, index + 1)
			if(!length(entries))
				prefs.tattoos -= zone
			prefs.save_character()
			prefs.mark_preview_appearance_dirty()
			return TRUE

	return FALSE

/datum/preferences/proc/ShowTattoos(mob/user)
	var/datum/tattoo_prefs/window = new(user)
	window.ui_interact(user)

#undef TATTOO_STATE_FRESH
#undef TATTOO_STATE_FADED
#undef MAXIMUM_TATTOOS_PER_ZONE
#undef TATTOO_STYLE_LETTERING
#undef TATTOO_STYLE_DESIGN
#undef TATTOO_TEXT_MAX_LENGTH
#undef MOVESPEED_ID_TATTOO_PAIN
#undef TATTOO_ZONE_FOREHEAD
#undef TATTOO_ZONE_CHEEKS
#undef TATTOO_ZONE_CHIN
#undef TATTOO_ZONE_LIPS
#undef TATTOO_ZONE_EARS
#undef TATTOO_ZONE_HORNS
#undef TATTOO_ZONE_NECK
#undef TATTOO_ZONE_BACK
#undef TATTOO_ZONE_BELLY
#undef TATTOO_ZONE_WINGS
#undef TATTOO_ZONE_TAIL
#undef TATTOO_ZONE_L_THIGH
#undef TATTOO_ZONE_R_THIGH
#undef TATTOO_ZONE_BREASTS
#undef TATTOO_ZONE_GROIN
#undef TATTOO_ZONE_BUTTOCKS
#undef TATTOO_ZONE_PENIS
#undef TATTOO_ZONE_VAGINA
#undef TATTOO_ZONE_L_FOOT
#undef TATTOO_ZONE_R_FOOT
