/// Character Creator owns the current account UI language; keep the legacy
/// client setting only as a fallback when the preferences datum is unavailable.
/proc/rmh_law_ui_language(mob/user)
	var/client/viewer = user?.client
	var/datum/preferences/preferences = viewer?.prefs
	return sanitize_preferred_ui_language(preferences ? preferences.character_creator_lang : viewer?.preferred_ui_language)

/// Refresh existing readers after the validated Character Creator action.
/// The locale provider changes in place: unsaved drafts and editor keys survive.
/datum/preferences/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	var/previous_language = character_creator_lang
	. = ..()
	if(action != "cc_set_lang" || previous_language == character_creator_lang)
		return
	var/mob/user = ui?.user
	if(!user || user.client != parent || parent?.prefs != src)
		return
	SStgui.update_user_uis(user)
	parent.rmh_scom_reader?.send_publication()

GLOBAL_DATUM(rmh_law_documents, /datum/rmh_law_documents)

/// Lazy: GLOB initialization order must not select the starter lawset twice.
/proc/rmh_get_law_documents()
	RETURN_TYPE(/datum/rmh_law_documents)
	if(!GLOB.rmh_law_documents)
		GLOB.rmh_law_documents = new
	return GLOB.rmh_law_documents

/// Two independent round-local publications. Saved drafts never initialize these.
/datum/rmh_law_documents
	var/datum/rmh_law_document/code/law_code
	var/datum/rmh_law_document/book/lawbook
	var/epoch

/datum/rmh_law_documents/New()
	. = ..()
	epoch = "[world.realtime]-[world.timeofday]"
	law_code = new
	lawbook = new
	sync_legacy_code()
	lawbook.seed_tome()
	sync_legacy_decrees()

/datum/rmh_law_documents/Destroy()
	if(GLOB.rmh_law_documents == src)
		GLOB.rmh_law_documents = null
	decrees = null
	QDEL_NULL(law_code)
	QDEL_NULL(lawbook)
	return ..()

/datum/rmh_law_documents/proc/document(document_id)
	RETURN_TYPE(/datum/rmh_law_document)
	switch(document_id)
		if(RMH_LAW_CODE)
			return law_code
		if(RMH_LAW_BOOK)
			return lawbook

/// Import starter laws and character preferences; THROAT cannot edit these.
/datum/rmh_law_documents/proc/sync_legacy_code()
	var/list/old = law_code.content
	var/list/next = list()
	var/list/used_ids = list()
	for(var/legacy_text in GLOB.laws_of_the_land)
		var/text = html_decode(legacy_text)
		var/list/entry
		for(var/list/candidate as anything in old)
			if(candidate["text"] == text && !(candidate["id"] in used_ids))
				entry = candidate.Copy()
				break
		if(!entry)
			entry = list("id" = law_code.allocate_id(), "text" = text, "text_en" = "")
		used_ids += entry["id"]
		next += list(entry)
	if(json_encode(old) == json_encode(next))
		return FALSE
	law_code.content = next
	law_code.revision++
	SEND_SIGNAL(src, COMSIG_RMH_LAW_PUBLISHED, RMH_LAW_CODE)
	return TRUE

/// No sleeps between version comparison and replacing the published snapshot.
/datum/rmh_law_documents/proc/publish(document_id, expected_revision, list/payload, mob/publisher)
	var/datum/rmh_law_document/doc = document(document_id)
	if(!doc || expected_revision != doc.revision)
		return "The published revision changed. Compare with the current document before publishing."
	var/list/normalized = doc.normalize(payload, check_ids = TRUE)
	if(!normalized)
		return "Invalid document: check text limits, identifiers and document structure."
	var/list/before = doc.content
	// Identical publications neither invalidate editors nor trigger resonance.
	if(json_encode(normalized) == json_encode(doc.normalize(before, check_ids = FALSE)))
		return null
	doc.assign_ids(normalized)
	doc.content = normalized
	doc.revision++
	if(document_id == RMH_LAW_CODE)
		var/list/projection = list()
		for(var/list/entry as anything in normalized)
			// Legacy consumers use browser HTML; official TGUI content stays plain text.
			projection += html_encode(entry["text"])
		GLOB.laws_of_the_land = projection
	SEND_SIGNAL(src, COMSIG_RMH_LAW_PUBLISHED, document_id)
	if(publisher)
		rmh_announce_law_publication(document_id, before, normalized)
	return null

/datum/rmh_law_document
	var/revision = 1
	var/next_id = 0
	var/list/content = list()

/datum/rmh_law_document/Destroy()
	content = null
	return ..()

/datum/rmh_law_document/proc/allocate_id()
	next_id++
	return "entry_[next_id]"

/datum/rmh_law_document/proc/normalize(list/payload, check_ids = TRUE, for_draft = FALSE)
	return null

/datum/rmh_law_document/proc/assign_ids(list/payload)
	return

/// IDs are unique across a document; fresh client IDs are never official IDs.
/datum/rmh_law_document/proc/valid_id(id, list/seen, list/existing, check_ids)
	if(!istext(id) || !length(id) || length(id) > RMH_LAW_MAX_TITLE || (id in seen))
		return FALSE
	if(check_ids && !(id in existing) && copytext(id, 1, 7) != "draft_")
		return FALSE
	seen += id
	return TRUE

/proc/rmh_law_text(value, limit, allow_empty = TRUE)
	if(!istext(value) || length_char(value) > limit)
		return FALSE
	return allow_empty || length(trim(value))

/datum/rmh_law_document/code

/datum/rmh_law_document/code/normalize(list/payload, check_ids = TRUE, for_draft = FALSE)
	if(!islist(payload) || length(payload) > RMH_LAW_MAX_LAWS)
		return null
	var/list/existing = list()
	for(var/list/entry as anything in content)
		existing += entry["id"]
	var/list/seen = list()
	var/list/result = list()
	var/text_size = 0
	for(var/list/entry as anything in payload)
		if(!islist(entry) || (length(entry) != 2 && !(length(entry) == 3 && ("text_en" in entry))))
			return null
		if(!valid_id(entry["id"], seen, existing, check_ids) || !rmh_law_text(entry["text"], RMH_LAW_MAX_TEXT, allow_empty = for_draft))
			return null
		var/english = ("text_en" in entry) ? entry["text_en"] : ""
		if(!rmh_law_text(english, RMH_LAW_MAX_TEXT))
			return null
		text_size += length_char(entry["text"]) + length_char(english)
		if(text_size > RMH_LAW_MAX_DOCUMENT)
			return null
		result += list(list("id" = entry["id"], "text" = entry["text"], "text_en" = english))
	return result

/datum/rmh_law_document/code/assign_ids(list/payload)
	for(var/list/entry as anything in payload)
		if(copytext(entry["id"], 1, 7) == "draft_")
			entry["id"] = allocate_id()

/// Required legacy fields plus optional translations; unknown fields never survive.
/proc/rmh_law_fields(value, list/required, list/optional)
	if(!islist(value))
		return FALSE
	var/list/fields = value
	for(var/key in required)
		if(!(key in fields))
			return FALSE
	for(var/key in fields)
		if(!(key in required) && !(key in optional))
			return FALSE
	return TRUE

/datum/rmh_law_document/book
	content = list("title" = "Tome of Justice", "title_en" = "", "chapters" = list())

/// Read the SAME source as /obj/item/book/law; do not maintain a second legal text.
/datum/rmh_law_document/book/proc/seed_tome()
	var/list/pages = strings("books/law.json", "Contents")
	var/list/articles = list()
	for(var/page in pages)
		// Paragraph boundaries become ordered articles, retaining the original wording.
		var/list/paragraphs = splittext(replacetext(page, "<hr>", ""), "</p>")
		for(var/paragraph in paragraphs)
			var/body = trim(html_decode(GLOB.html_tags.Replace(paragraph, "")))
			if(!length(body))
				continue
			articles += list(list("id" = allocate_id(), "title" = "Article [length(articles) + 1]", "title_en" = "", "body" = body, "body_en" = ""))
	content = list(
		"title" = "Tome of Justice",
		"title_en" = "",
		"chapters" = list(list("id" = allocate_id(), "title" = "The New Law of the Town", "title_en" = "", "intro" = "", "intro_en" = "", "articles" = articles)),
	)

/datum/rmh_law_document/book/normalize(list/payload, check_ids = TRUE, for_draft = FALSE)
	if(!rmh_law_fields(payload, list("title", "chapters"), list("title_en")) || !rmh_law_text(payload["title"], RMH_LAW_MAX_TITLE, allow_empty = for_draft))
		return null
	var/title_en = ("title_en" in payload) ? payload["title_en"] : ""
	if(!rmh_law_text(title_en, RMH_LAW_MAX_TITLE))
		return null
	var/list/chapters = payload["chapters"]
	if(!islist(chapters) || length(chapters) > RMH_LAW_MAX_CHAPTERS)
		return null
	var/list/existing_chapters = list()
	var/list/existing_articles = list()
	var/list/current_chapters = content["chapters"]
	for(var/list/chapter as anything in current_chapters)
		existing_chapters += chapter["id"]
		var/list/current_articles = chapter["articles"]
		for(var/list/article as anything in current_articles)
			existing_articles += article["id"]
	var/list/seen = list()
	var/list/result_chapters = list()
	var/article_count = 0
	var/text_size = length_char(payload["title"]) + length_char(title_en)
	for(var/list/chapter as anything in chapters)
		if(!rmh_law_fields(chapter, list("id", "title", "intro", "articles"), list("title_en", "intro_en")))
			return null
		if(!valid_id(chapter["id"], seen, existing_chapters, check_ids))
			return null
		if(!rmh_law_text(chapter["title"], RMH_LAW_MAX_TITLE, allow_empty = for_draft) || !rmh_law_text(chapter["intro"], RMH_LAW_MAX_BODY))
			return null
		var/chapter_title_en = ("title_en" in chapter) ? chapter["title_en"] : ""
		var/intro_en = ("intro_en" in chapter) ? chapter["intro_en"] : ""
		if(!rmh_law_text(chapter_title_en, RMH_LAW_MAX_TITLE) || !rmh_law_text(intro_en, RMH_LAW_MAX_BODY))
			return null
		var/list/articles = chapter["articles"]
		if(!islist(articles))
			return null
		article_count += length(articles)
		if(article_count > RMH_LAW_MAX_ARTICLES)
			return null
		text_size += length_char(chapter["title"]) + length_char(chapter["intro"]) + length_char(chapter_title_en) + length_char(intro_en)
		var/list/result_articles = list()
		for(var/list/article as anything in articles)
			if(!rmh_law_fields(article, list("id", "title", "body"), list("title_en", "body_en")) || !valid_id(article["id"], seen, existing_articles, check_ids))
				return null
			if(!rmh_law_text(article["title"], RMH_LAW_MAX_TITLE, allow_empty = for_draft) || !rmh_law_text(article["body"], RMH_LAW_MAX_BODY, allow_empty = for_draft))
				return null
			var/article_title_en = ("title_en" in article) ? article["title_en"] : ""
			var/body_en = ("body_en" in article) ? article["body_en"] : ""
			if(!rmh_law_text(article_title_en, RMH_LAW_MAX_TITLE) || !rmh_law_text(body_en, RMH_LAW_MAX_BODY))
				return null
			text_size += length_char(article["title"]) + length_char(article["body"]) + length_char(article_title_en) + length_char(body_en)
			result_articles += list(list("id" = article["id"], "title" = article["title"], "title_en" = article_title_en, "body" = article["body"], "body_en" = body_en))
		if(text_size > RMH_LAW_MAX_DOCUMENT)
			return null
		result_chapters += list(list("id" = chapter["id"], "title" = chapter["title"], "title_en" = chapter_title_en, "intro" = chapter["intro"], "intro_en" = intro_en, "articles" = result_articles))
	return list("title" = payload["title"], "title_en" = title_en, "chapters" = result_chapters)

/datum/rmh_law_document/book/assign_ids(list/payload)
	var/list/chapters = payload["chapters"]
	for(var/list/chapter as anything in chapters)
		if(copytext(chapter["id"], 1, 7) == "draft_")
			chapter["id"] = allocate_id()
		var/list/articles = chapter["articles"]
		for(var/list/article as anything in articles)
			if(copytext(article["id"], 1, 7) == "draft_")
				article["id"] = allocate_id()

/**
 * One announcement per changed publication, never per book/board instance.
 * Pure summary helper also keeps batch additions distinct from amendments.
 */
/proc/rmh_law_publication_notice(document_id, list/before, list/after, language = "ru")
	if(json_encode(before) == json_encode(after))
		return null
	if(language == "en")
		return rmh_law_publication_notice_en(document_id, before, after)
	if(document_id == RMH_LAW_BOOK)
		return list("title" = "В КНИГУ ЗАКОНОВ ВНЕСЕНЫ ПОПРАВКИ", \
			"text" = "Опубликованы поправки к Книге законов. Ознакомьтесь с обновлённым изданием.", \
			"sound" = RMH_LAW_SOUND_BOOK)
	if(document_id != RMH_LAW_CODE)
		return null
	var/list/old_ids = list()
	for(var/list/entry as anything in before)
		old_ids += entry["id"]
	var/list/additions = list()
	for(var/list/entry as anything in after)
		if(!(entry["id"] in old_ids))
			additions += list(entry)
	if(length(additions) == 1)
		var/list/entry = additions[1]
		return list("title" = "ВВЕДЁН НОВЫЙ ЗАКОН ГРАДА", \
			"text" = "[after.Find(entry)]. [entry["text"]]", "sound" = RMH_LAW_SOUND_CODE)
	if(length(additions) > 1)
		return list("title" = "ВВЕДЕНЫ НОВЫЕ ЗАКОНЫ ГРАДА", \
			"text" = "Введено новых законов града: [length(additions)]. Ознакомьтесь с обновлённым сводом.", \
			"sound" = RMH_LAW_SOUND_CODE)
	return list("title" = "СВОД ЗАКОНОВ ГРАДА ОБНОВЛЁН", \
		"text" = "Опубликованы изменения свода законов града. Ознакомьтесь с действующей редакцией.", \
		"sound" = RMH_LAW_SOUND_CODE)

// --- decrees.dm ---
/// Stable identities are a projection of the existing THROAT decree list, not history.
/datum/rmh_law_documents
	var/list/decrees = list()
	var/next_decree_id = 0

/datum/rmh_law_documents/proc/sync_legacy_decrees()
	var/list/next = list()
	var/list/used = list()
	for(var/legacy in GLOB.lord_decrees)
		var/text = html_decode(legacy)
		var/list/entry
		for(var/list/candidate as anything in decrees)
			if(candidate["text"] == text && !(candidate["id"] in used))
				entry = candidate.Copy()
				break
		if(!entry)
			next_decree_id++
			entry = list("id" = "decree_[next_decree_id]", "text" = text, "text_en" = "", "revision" = 1)
		used += entry["id"]
		next += list(entry)
	if(json_encode(next) == json_encode(decrees))
		return FALSE
	decrees = next
	SEND_SIGNAL(src, COMSIG_RMH_DECREES_CHANGED)
	return TRUE

/datum/rmh_law_documents/proc/publish_decree_translation(id, expected_revision, text_en)
	if(!rmh_law_text(text_en, RMH_LAW_MAX_TEXT))
		return "The English translation exceeds the text limit."
	var/list/selected
	var/total = length_char(text_en)
	for(var/list/entry as anything in decrees)
		if(entry["id"] == id)
			selected = entry
		else
			total += length_char(entry["text_en"])
	if(!selected || !isnum(expected_revision) || selected["revision"] != expected_revision)
		return "The decree changed or was abolished. Reload its current translation."
	if(total > RMH_LAW_MAX_DOCUMENT)
		return "The round's decree translation size limit was reached."
	if(selected["text_en"] == text_en)
		return null
	selected["text_en"] = text_en
	selected["revision"]++
	SEND_SIGNAL(src, COMSIG_RMH_DECREES_CHANGED)
	return null

// --- legacy_laws.dm ---
// Laws are published only at the scribe stand; retain THROAT's other duties.
/obj/structure/fake_machine/titan/make_law(mob/living/carbon/human/user, message)
	return FALSE

/obj/structure/fake_machine/titan/remove_law(message)
	return FALSE

/obj/structure/fake_machine/titan/purge_laws()
	return FALSE

/obj/structure/fake_machine/titan/Initialize(mapload)
	. = ..()
	command_list -= list("Make Law", "Remove Law", "Purge Laws")

/obj/structure/fake_machine/titan/recognize_command(mob/living/carbon/human/user, message)
	if(findtext(message, "make law") || findtext(message, "remove law") || findtext(message, "purge laws"))
		return FALSE
	return ..()

/obj/structure/fake_machine/titan/switch_mode(mode_to_switch_to)
	if(mode_to_switch_to == "Make Law")
		reset_mode()
		return FALSE
	return ..()

/obj/structure/fake_machine/titan/ui_data(mob/user)
	. = ..()
	.["decree_records"] = rmh_get_law_documents().decrees
	.["voice_commands"] = command_list.Copy()
	.["language"] = rmh_law_ui_language(user)
	.["throat_mode"] = mode
	.["crown_present"] = !QDELETED(SSroguemachine.crown)
	.["key_present"] = !QDELETED(SSroguemachine.key)
	// This route has no law editor or legacy positional decree list.
	. -= list("laws", "decrees")

/obj/structure/fake_machine/titan/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	var/mob/user = ui?.user
	// Reject malformed or stale requests before the legacy action switch.
	if(!user || usr != user || !ishuman(user) || !islist(params) || ui.status != UI_INTERACTIVE || ui_status(user, GLOB.physical_state) != UI_INTERACTIVE)
		return FALSE
	if(action in list("make_announcement", "make_decree"))
		if(!rmh_law_text(params["text"], 500, FALSE))
			return FALSE
	if(action in list("declare_outlaw", "pardon_outlaw"))
		if(!rmh_law_text(params["name"], RMH_LAW_MAX_TITLE, FALSE))
			return FALSE
	if(action == "refresh")
		return TRUE
	if(action == "remove_decree")
		var/index = istext(params["index"]) ? text2num(params["index"]) : 0
		var/list/current = rmh_get_law_documents().decrees
		if(index < 1 || index > length(current) || index != round(index))
			return FALSE
		var/list/entry = current[index]
		if(entry["id"] != params["id"] || entry["revision"] != params["revision"])
			to_chat(usr, span_warning(rmh_ui_text(usr, "Указ изменился. Обновите перечень.", "The decree changed. Refresh the list.")))
			return TRUE
	if(action in list("make_law", "remove_law", "purge_laws"))
		// Keep the parent UI lifecycle, but never enter its legacy law switch.
		..("rmh_disabled_law_command", params)
		return FALSE
	return ..()

/datum/job/lord/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	var/list/decrees_before = GLOB.lord_decrees.Copy()
	. = ..()
	rmh_notify_decree_change(decrees_before)
	GLOB.rmh_law_documents?.sync_legacy_code()

/// The fork's Burgmeister is independent of /datum/job/lord.
/datum/job/burgmeister/after_spawn(mob/living/spawned, client/player_client)
	var/list/decrees_before = GLOB.lord_decrees.Copy()
	. = ..()
	var/datum/preferences/prefs = player_client?.prefs
	if(!prefs)
		return
	var/list/laws = prefs.read_preference(/datum/preference/list_type/role_setting/monarch_law)
	if(length(laws))
		GLOB.laws_of_the_land = list()
		for(var/law in laws)
			GLOB.laws_of_the_land += trim(law)
	var/list/decrees = prefs.read_preference(/datum/preference/list_type/role_setting/monarch_decree)
	if(length(decrees))
		GLOB.lord_decrees = list()
		for(var/decree in decrees)
			GLOB.lord_decrees += trim(decree)
	GLOB.rmh_law_documents?.sync_legacy_code()
	rmh_notify_decree_change(decrees_before)

/proc/rmh_notify_decree_change(list/before)
	if(GLOB.rmh_law_documents && json_encode(before) != json_encode(GLOB.lord_decrees))
		GLOB.rmh_law_documents.sync_legacy_decrees()

/obj/structure/fake_machine/titan/make_decree(mob/living/carbon/human/user, message)
	var/list/before = GLOB.lord_decrees.Copy()
	. = ..()
	rmh_notify_decree_change(before)

/obj/structure/fake_machine/titan/remove_decree(message)
	var/list/before = GLOB.lord_decrees.Copy()
	. = ..()
	rmh_notify_decree_change(before)


/proc/rmh_ui_text(mob/user, russian, english)
	return rmh_law_ui_language(user) == "ru" ? russian : english

/proc/rmh_law_revision_message(document_id, revision, language)
	if(language == "ru")
		return "Опубликована [revision]-я редакция [document_id == RMH_LAW_CODE ? "свода" : "книги законов"]."
	return "Published revision [revision] of [document_id == RMH_LAW_CODE ? "the law code" : "the lawbook"]."

/proc/rmh_announce_law_publication(document_id, list/before, list/after)
	// One rare publication fan-out, preserving stock hearing and sound-preference checks.
	var/list/russian = list()
	var/list/english = list()
	for(var/mob/viewer as anything in GLOB.player_list)
		if(rmh_law_ui_language(viewer) == "ru")
			russian += viewer
		else
			english += viewer
	for(var/language in list("ru", "en"))
		var/list/players = language == "ru" ? russian : english
		if(!length(players))
			continue
		var/list/notice = rmh_law_publication_notice(document_id, before, after, language)
		if(notice)
			priority_announce(notice["text"], notice["title"], notice["sound"], "Captain", players = players)

/proc/rmh_law_publication_notice_en(document_id, list/before, list/after)
	if(document_id == RMH_LAW_BOOK)
		return list("title" = "LAWBOOK AMENDED", "text" = "Amendments to the lawbook have been published. Read the updated edition.", "sound" = RMH_LAW_SOUND_BOOK)
	if(document_id != RMH_LAW_CODE)
		return null
	var/list/old_ids = list()
	for(var/list/entry as anything in before)
		old_ids += entry["id"]
	var/list/additions = list()
	for(var/list/entry as anything in after)
		if(!(entry["id"] in old_ids))
			additions += list(entry)
	if(length(additions) == 1)
		var/list/entry = additions[1]
		var/english = entry["text_en"]
		var/text = istext(english) && length(trim(english)) ? english : entry["text"]
		return list("title" = "A LAW IS DECLARED", "text" = "[after.Find(entry)]. [text]", "sound" = RMH_LAW_SOUND_CODE)
	if(length(additions) > 1)
		return list("title" = "NEW TOWN LAWS", "text" = "New town laws enacted: [length(additions)]. Read the updated code.", "sound" = RMH_LAW_SOUND_CODE)
	return list("title" = "LAW CODE UPDATED", "text" = "Changes to the town law code have been published. Read the current edition.", "sound" = RMH_LAW_SOUND_CODE)

/proc/rmh_law_feedback(mob/user, message)
	if(rmh_law_ui_language(user) != "ru")
		return message
	var/static/list/messages = list(
		"Could not write the account savefile." = "Не удалось записать данные аккаунта.",
		"I begin replacing the board's broken glass." = "Я начинаю заменять разбитое стекло доски.",
		"Invalid document: check text limits and identifiers." = "Недопустимый документ: проверьте объём текста и идентификаторы.",
		"Invalid document: check text limits, identifiers and document structure." = "Недопустимый документ: проверьте объём текста, идентификаторы и структуру.",
		"Invalid notes: check identifiers and text limits." = "Недопустимые записи: проверьте идентификаторы и объём текста.",
		"Personal draft saved. The official document has not changed." = "Личный черновик сохранён. Опубликованный документ не изменился.",
		"Personal notes saved." = "Личные записи сохранены.",
		"Please wait a moment before writing drafts again." = "Подождите немного перед следующим сохранением.",
		"The English translation exceeds the text limit." = "Английский перевод превышает допустимый объём.",
		"The account draft record limit was reached." = "Достигнут предел разделов черновиков аккаунта.",
		"The account draft size limit was reached." = "Достигнут предел объёма черновиков аккаунта.",
		"The account note storage limit was reached." = "Достигнут предел объёма записей аккаунта.",
		"The account note-record limit was reached." = "Достигнут предел разделов личных записей.",
		"The decree changed or was abolished. Reload its current translation." = "Указ изменён или отменён. Загрузите его текущий перевод.",
		"The decree changed or was revoked. Choose from the current list." = "Указ изменён или отозван. Выберите его в актуальном перечне.",
		"The published revision changed. Compare with the current document before publishing." = "Опубликованная редакция изменилась. Сверьте документ перед публикацией.",
		"The round's decree translation size limit was reached." = "Достигнут предел объёма переводов указов в этом раунде.",
		"The saved notes changed. Compare and reload them before saving." = "Сохранённые записи изменились. Сверьте и загрузите их перед сохранением.",
		"There is already a poster on this face of the wall." = "На этой стороне стены уже висит постер.",
		"This character has no usable account save." = "Для этого персонажа недоступно сохранение аккаунта.",
		"This decree exceeds the poster's text limit." = "Указ превышает допустимый объём текста постера.",
	)
	return istext(messages[message]) ? messages[message] : message
