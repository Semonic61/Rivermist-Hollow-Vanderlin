/datum/lock/key/rmh_scribe
	lockid_list = list(ACCESS_HAND)
	locked = TRUE
	difficulty = 1

/datum/lock/key/rmh_scribe/lock(user, obj/item, silent = FALSE)
	. = ..()
	holder?.update_appearance()
	SStgui.update_uis(holder)

/datum/lock/key/rmh_scribe/unlock(user, obj/item, silent = FALSE)
	. = ..()
	holder?.update_appearance()
	SStgui.update_uis(holder)

/obj/structure/rmh_scribe_stand
	name = "scribe's stand"
	desc = "A locked writing stand for the official laws. The master and councilor hold its keys."
	icon = 'icons/roguetown/misc/machines.dmi'
	icon_state = "book_binder"
	density = TRUE
	anchored = TRUE
	lock = /datum/lock/key/rmh_scribe
	var/tmp/datum/rmh_law_documents/documents

/obj/structure/rmh_scribe_stand/Initialize(mapload)
	. = ..()
	documents = rmh_get_law_documents()
	RegisterSignal(documents, list(COMSIG_RMH_LAW_PUBLISHED, COMSIG_RMH_DECREES_CHANGED), PROC_REF(on_publication))
	RegisterSignal(documents, COMSIG_PARENT_QDELETING, PROC_REF(on_documents_deleted))
	update_appearance()

/obj/structure/rmh_scribe_stand/Destroy()
	if(documents)
		UnregisterSignal(documents, list(COMSIG_RMH_LAW_PUBLISHED, COMSIG_RMH_DECREES_CHANGED, COMSIG_PARENT_QDELETING))
	documents = null
	return ..()

/obj/structure/rmh_scribe_stand/update_overlays()
	. = ..()
	// Reuse the existing binder and the Tome's two cover states, without binary edits.
	var/book_state = locked() ? "lawtome_0" : "lawtome_1"
	var/mutable_appearance/book = mutable_appearance('icons/roguetown/items/books.dmi', book_state)
	book.pixel_y = 8
	. += book

/obj/structure/rmh_scribe_stand/proc/on_publication(datum/source, document_id)
	SIGNAL_HANDLER
	SStgui.update_uis(src)

/obj/structure/rmh_scribe_stand/proc/on_documents_deleted(datum/source)
	SIGNAL_HANDLER
	documents = null
	SStgui.close_uis(src)

/obj/structure/rmh_scribe_stand/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	if(user.can_read(src, TRUE))
		ui_interact(user)

/obj/structure/rmh_scribe_stand/ui_interact(mob/user, datum/tgui/ui)
	if(!documents)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RmhScribeStand", name)
		ui.set_autoupdate(FALSE)
		ui.open()

/obj/structure/rmh_scribe_stand/proc/can_edit(mob/user)
	return documents && ishuman(user) && !obj_broken && !locked() && Adjacent(user) \
		&& rmh_law_editor_role(user) && user.can_read(src, TRUE) \
		&& user.can_perform_action(src, NEED_DEXTERITY|FORBID_TELEKINESIS_REACH)

/obj/structure/rmh_scribe_stand/ui_data(mob/user)
	if(!documents || !user)
		return list()
	var/role = rmh_law_editor_role(user)
	var/list/saved = can_edit(user) ? rmh_law_saved_record(user, role) : null
	var/list/notes = can_edit(user) ? rmh_law_note_record(user, role) : null
	var/can_read = user.can_read(src, TRUE)
	var/list/decrees = list()
	if(can_read)
		decrees = documents.decrees
	return list(
		"language" = rmh_law_ui_language(user),
		"epoch" = documents.epoch,
		"decrees" = decrees,
		"role" = role,
		"character" = rmh_law_character(user),
		"editor_key" = json_encode(list(user.ckey, rmh_law_character(user), role)),
		"can_edit" = can_edit(user),
		"locked" = locked(),
		"code_revision" = documents.law_code.revision,
		"book_revision" = documents.lawbook.revision,
		"law_code" = can_read ? documents.law_code.content : list(),
		"lawbook" = can_read ? documents.lawbook.content : list("title" = "", "chapters" = list()),
		"saved" = saved ? saved["documents"] : null,
		"notes" = can_edit(user) ? list("revision" = notes ? notes["revision"] : 1, "entries" = notes ? notes["entries"] : list()) : null,
	)

/obj/structure/rmh_scribe_stand/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = ui?.user
	// /obj/structure/ui_act does not propagate the base rejection; check explicitly.
	if(!user || usr != user || !documents || state.can_use_topic(src, user) != UI_INTERACTIVE)
		return FALSE
	if(action == "refresh")
		return Adjacent(user) && user.can_read(src, TRUE)
	if(!can_edit(user))
		return FALSE
	if(params["editor_key"] != json_encode(list(user.ckey, rmh_law_character(user), rmh_law_editor_role(user))))
		return FALSE
	if(action == "save_notes")
		if(params["epoch"] != documents.epoch || !istext(params["content"]) || length(params["content"]) > RMH_LAW_MAX_PAYLOAD)
			return FALSE
		var/list/notes_payload
		try
			notes_payload = json_decode(params["content"])
		catch
			return FALSE
		var/error = rmh_save_law_notes(user, rmh_law_editor_role(user), params["revision"], notes_payload)
		if(error)
			to_chat(user, span_warning(rmh_law_feedback(user, error)))
		else
			to_chat(user, span_notice(rmh_law_feedback(user, "Personal notes saved.")))
		return TRUE
	if(action == "publish_decree_translation")
		if(params["epoch"] != documents.epoch)
			return FALSE
		var/translation_error = documents.publish_decree_translation(params["id"], params["revision"], params["text_en"])
		if(translation_error)
			to_chat(user, span_warning(rmh_law_feedback(user, translation_error)))
		else
			log_game("[key_name(user)] published an English translation of [params["id"]] at [AREACOORD(src)].")
		// The publication signal already updates the stand and remote readers.
		return FALSE
	if(!(action in list("publish", "save_draft", "delete_draft")))
		return FALSE
	var/datum/rmh_law_document/doc = documents.document(params["document"])
	if(!doc || params["epoch"] != documents.epoch)
		return FALSE
	if(action == "delete_draft")
		return rmh_delete_law_draft(user, rmh_law_editor_role(user), params["document"])
	var/revision = params["revision"]
	if(!isnum(revision) || revision < 1 || revision != round(revision) || revision > doc.revision)
		return FALSE
	if(action == "publish" && revision != doc.revision)
		to_chat(user, span_warning(rmh_law_feedback(user, "The published revision changed. Compare with the current document before publishing.")))
		return TRUE
	var/raw = params["content"]
	if(!istext(raw) || length(raw) > RMH_LAW_MAX_PAYLOAD)
		return FALSE
	var/list/payload
	try
		payload = json_decode(raw)
	catch
		return FALSE
	var/list/normalized = doc.normalize(payload, check_ids = action == "publish", for_draft = action == "save_draft")
	if(!normalized)
		to_chat(user, span_warning(rmh_law_feedback(user, "Invalid document: check text limits and identifiers.")))
		return FALSE
	var/error
	if(action == "publish")
		error = documents.publish(params["document"], revision, normalized, user)
		if(!error)
			log_game("[key_name(user)] published [params["document"]] revision [doc.revision] at [AREACOORD(src)].")
			to_chat(user, span_notice(rmh_law_revision_message(params["document"], doc.revision, rmh_law_ui_language(user))))
			// The publication signal already pushes all stands once.
			return FALSE
	else
		error = rmh_save_law_draft(user, rmh_law_editor_role(user), params["document"], revision, normalized)
	if(error)
		to_chat(user, span_warning(rmh_law_feedback(user, error)))
	else
		to_chat(user, span_notice(rmh_law_feedback(user, "Personal draft saved. The official document has not changed.")))
	return TRUE

// --- lawbook.dm ---
/// Existing mapped/vended Tomes become views of the one published lawbook.
/obj/item/book/law
	desc = "A lawbook inlaid with resonant minerals. Its pages follow the official publication and tremble when amended."
	resistance_flags = FIRE_PROOF
	firefuel = 0
	override_find_book = TRUE
	var/tmp/datum/rmh_law_documents/documents

/obj/item/book/law/Initialize(mapload)
	. = ..()
	documents = rmh_get_law_documents()
	RegisterSignal(documents, COMSIG_RMH_LAW_PUBLISHED, PROC_REF(on_lawbook_publication))
	RegisterSignal(documents, COMSIG_PARENT_QDELETING, PROC_REF(on_lawbook_documents_deleted))

/obj/item/book/law/Destroy()
	if(documents)
		UnregisterSignal(documents, list(COMSIG_RMH_LAW_PUBLISHED, COMSIG_PARENT_QDELETING))
	documents = null
	return ..()

/obj/item/book/law/proc/on_lawbook_publication(datum/source, document_id)
	SIGNAL_HANDLER
	if(document_id != RMH_LAW_BOOK)
		return
	SStgui.update_uis(src)
	// Native animation only on exposed copies; books in shelves/bags do no visual work.
	// The global amendment announcement already supplies the temporary sound cue.
	if(isturf(loc) || ismob(loc))
		rmh_resonate()

/obj/item/book/law/proc/on_lawbook_documents_deleted(datum/source)
	SIGNAL_HANDLER
	documents = null
	SStgui.close_uis(src)

/obj/item/book/law/attack_self(mob/user, list/modifiers)
	// Replace only this subtype's legacy HUD/browser reader.
	return read(user)

/obj/item/book/law/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(!open)
		SStgui.close_uis(src)

/obj/item/book/law/read(mob/user)
	if(!user || !in_range(user, src) || !user.can_read(src))
		return FALSE
	if(!user.can_perform_action(src, NEED_LITERACY|FORBID_TELEKINESIS_REACH))
		return FALSE
	if(!open)
		attack_hand_secondary(user)
	if(!rmh_can_read(user) || ui_status(user, GLOB.default_state) < UI_UPDATE)
		return FALSE
	ui_interact(user)
	SEND_SIGNAL(user, COMSIG_BOOK_READ)
	return TRUE

/obj/item/book/law/proc/rmh_can_read(mob/user)
	return documents && open && user && in_range(user, src) && user.can_read(src, TRUE) \
		&& user.can_perform_action(src, NEED_LITERACY|FORBID_TELEKINESIS_REACH)

/obj/item/book/law/ui_status(mob/user, datum/ui_state/state)
	if(!rmh_can_read(user))
		return UI_CLOSE
	return ..()

/obj/item/book/law/ui_interact(mob/user, datum/tgui/ui)
	if(!rmh_can_read(user))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RmhLawbook", name)
		ui.set_autoupdate(FALSE)
		ui.open()

/obj/item/book/law/ui_data(mob/user)
	if(!rmh_can_read(user))
		return list("language" = rmh_law_ui_language(user), "revision" = 0, "lawbook" = list("title" = "", "chapters" = list()))
	return list("language" = rmh_law_ui_language(user), "revision" = documents.lawbook.revision, "lawbook" = documents.lawbook.content)

/obj/item/book/law/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	..()
	// Intentionally no domain actions, including forged editor/draft requests.
	// Contents navigation and search are entirely local to the reader.
	return FALSE

/// Add one Tome alongside the existing recipe selection; do not replace recipes.
/obj/structure/bookcase/random_recipes/Initialize(mapload)
	. = ..()
	if(!(locate(/obj/item/book/law) in src))
		new /obj/item/book/law(src)
	update_appearance(UPDATE_ICON_STATE)

/obj/structure/bookcase/fancy/random_recipes/Initialize(mapload)
	. = ..()
	if(!(locate(/obj/item/book/law) in src))
		new /obj/item/book/law(src)
	update_appearance(UPDATE_ICON_STATE)


/obj/item/book/law/proc/rmh_resonate()
	var/rest_x = pixel_x
	var/rest_y = pixel_y
	animate(src, pixel_x = rest_x + 3, pixel_y = rest_y + 1, time = 1, loop = 4)
	animate(pixel_x = rest_x - 3, pixel_y = rest_y - 1, time = 1)
	animate(pixel_x = rest_x, pixel_y = rest_y, time = 1)
