// Public payload literals are intentional: modular defines are included after core tests.
#if defined(UNIT_TESTS) || defined(SPACEMAN_DMM)
/datum/unit_test/rmh_law_publications_independent
/datum/unit_test/rmh_law_publications_independent/Run()
	var/datum/rmh_law_documents/store = allocate(/datum/rmh_law_documents)
	var/code_revision = store.law_code.revision
	var/book_revision = store.lawbook.revision
	var/old_book = json_encode(store.lawbook.content)
	var/list/legacy_before = GLOB.laws_of_the_land
	var/list/payload = list(list("id" = "draft_test", "text" = "A new law <as plain text>."))
	var/error = store.publish("law_code", code_revision, payload)
	// Restore the world before assertions can early-return.
	GLOB.laws_of_the_land = legacy_before
	TEST_ASSERT_NULL(error, "The valid code publication was rejected.")
	TEST_ASSERT_EQUAL(store.law_code.revision, code_revision + 1, "The code revision did not advance.")
	TEST_ASSERT_EQUAL(store.lawbook.revision, book_revision, "Publishing the code changed the book revision.")
	TEST_ASSERT_EQUAL(json_encode(store.lawbook.content), old_book, "Publishing the code changed the book.")
	var/list/published = store.law_code.content[1]
	var/official_id = published["id"]
	TEST_ASSERT(copytext(official_id, 1, 7) != "draft_", "A client draft ID became an official ID.")
	var/list/input_entry = payload[1]
	input_entry["text"] = "Mutated input"
	TEST_ASSERT_EQUAL(published["text"], "A new law <as plain text>.", "Publication retained the editor's mutable list.")
	var/snapshot = json_encode(store.law_code.content)
	error = store.publish("law_code", code_revision, list())
	TEST_ASSERT_NOTNULL(error, "A stale writer silently overwrote the code.")
	TEST_ASSERT_EQUAL(json_encode(store.law_code.content), snapshot, "A rejected publication changed the code.")
	var/list/book = store.lawbook.normalize(store.lawbook.content)
	book["title"] = "A book-only change"
	error = store.publish("lawbook", book_revision, book)
	TEST_ASSERT_NULL(error, "A code publication incorrectly invalidated a book editor's base revision.")
	TEST_ASSERT_EQUAL(json_encode(store.law_code.content), snapshot, "A book publication changed the code.")

/datum/unit_test/rmh_law_ids_limits_and_seed
/datum/unit_test/rmh_law_ids_limits_and_seed/Run()
	var/datum/rmh_law_documents/store = allocate(/datum/rmh_law_documents)
	var/datum/rmh_law_document/code/doc = store.law_code
	var/list/rows = list(list("id" = "draft_a", "text" = "First"), list("id" = "draft_b", "text" = "Second"))
	doc.assign_ids(rows)
	doc.content = rows
	var/list/first = rows[1]
	var/list/second = rows[2]
	var/list/reordered = doc.normalize(list(second, first))
	var/list/reordered_first = reordered[1]
	TEST_ASSERT_EQUAL(reordered_first["id"], second["id"], "Reordering changed the second law's stable ID.")
	TEST_ASSERT_NULL(doc.normalize(list(first, first)), "Duplicate IDs were accepted.")
	TEST_ASSERT_NULL(doc.normalize(list(list("id" = "unknown", "text" = "Foreign ID"))), "Unknown official IDs were accepted.")
	TEST_ASSERT_NULL(doc.normalize(list(list("id" = "draft_blank", "text" = "  "))), "Blank laws were accepted.")
	TEST_ASSERT_NULL(doc.normalize(list(list("id" = "draft_long", "text" = repeat_string(2049, "x")))), "Oversized law text was accepted.")
	TEST_ASSERT_NOTNULL(doc.normalize(list(list("id" = "draft_unfinished", "text" = "")), check_ids = FALSE, for_draft = TRUE), "An unfinished personal draft was rejected.")
	TEST_ASSERT_NULL(store.lawbook.normalize(list("title" = "Malformed", "chapters" = "not a list")), "Malformed book shape was accepted.")
	TEST_ASSERT_NOTNULL(store.lawbook.normalize(store.lawbook.content), "The Tome's starter text violates editor limits.")
	var/list/chapters = store.lawbook.content["chapters"]
	TEST_ASSERT(length(chapters), "The Tome of Justice starter chapter is missing.")
	var/list/chapter = chapters[1]
	var/list/articles = chapter["articles"]
	TEST_ASSERT(length(articles) > 1, "The original Tome paragraphs were not imported as ordered articles.")
	var/list/source_pages = strings("books/law.json", "Contents")
	var/list/bodies = list()
	for(var/list/article as anything in articles)
		bodies += article["body"]
	var/regex/whitespace = regex("\\s+", "g")
	var/expected = whitespace.Replace(trim(html_decode(GLOB.html_tags.Replace(jointext(source_pages, "\n"), ""))), " ")
	var/actual = whitespace.Replace(jointext(bodies, " "), " ")
	TEST_ASSERT_EQUAL(actual, expected, "The starter book changed or omitted the Tome of Justice wording.")


/datum/unit_test/rmh_scribe_office_and_lock
/datum/unit_test/rmh_scribe_office_and_lock/Run()
	var/mob/living/carbon/human/editor = allocate(/mob/living/carbon/human)
	if(!editor.mind)
		editor.mind = new
	editor.mind.set_assigned_role(/datum/job/councilor::title)
	TEST_ASSERT_EQUAL(rmh_law_editor_role(editor), "councilor", "An in-round councilor appointment has no access.")
	editor.mind.set_assigned_role(/datum/job/servant::title)
	TEST_ASSERT_NULL(rmh_law_editor_role(editor), "The former councilor retained editing rights after demotion.")
	editor.mind.set_assigned_role(/datum/job/burgmeister::title)
	TEST_ASSERT_EQUAL(rmh_law_editor_role(editor), "burgmeister", "The Burgmeister has no editing office.")
	var/obj/structure/rmh_scribe_stand/stand = allocate(/obj/structure/rmh_scribe_stand)
	var/datum/lock/key/stand_lock = stand.lock
	TEST_ASSERT(stand.locked(), "A new stand should be locked.")
	TEST_ASSERT(stand_lock.check_access_list(list(ACCESS_HAND)), "A councilor key cannot open the stand.")
	TEST_ASSERT(stand_lock.check_access_list(list(ACCESS_LORD)), "A master key cannot open the stand.")
	TEST_ASSERT(!stand_lock.check_access_list(list(ACCESS_MERCHANT)), "A merchant key opens the stand.")
	TEST_ASSERT(!stand.can_edit(editor), "A locked stand allowed editing.")

/datum/unit_test/rmh_law_draft_validation
/datum/unit_test/rmh_law_draft_validation/Run()
	var/datum/preference/list_type/rmh_law_drafts/pref = allocate(/datum/preference/list_type/rmh_law_drafts)
	var/list/saved_code = list("epoch" = "old-round", "revision" = 7, "content" = list(list("id" = "draft_saved", "text" = "")))
	var/list/record = list("character" = "Character A", "role" = "burgmeister", "documents" = list("law_code" = saved_code))
	TEST_ASSERT(pref.is_valid(list(record)), "A valid unfinished account draft was rejected.")
	TEST_ASSERT(!pref.is_accessible(null), "Private law drafts are exposed as a generic preference.")
	TEST_ASSERT(!pref.is_valid(list(record, record)), "Ambiguous duplicate character/office records were accepted.")
	var/list/other_role = record.Copy()
	other_role["role"] = "councilor"
	var/list/other_character = record.Copy()
	other_character["character"] = "Character B"
	TEST_ASSERT(pref.is_valid(list(record, other_role, other_character)), "Separate offices and characters were not accepted.")
	var/list/invalid = record.Copy()
	invalid["role"] = "servant"
	TEST_ASSERT(!pref.is_valid(list(invalid)), "A draft with an unknown office was accepted.")
	invalid = record.Copy()
	invalid["documents"] = list("outlaws" = saved_code)
	TEST_ASSERT(!pref.is_valid(list(invalid)), "A draft for a non-document target was accepted.")

/datum/unit_test/rmh_physical_lawbook_read_only
/datum/unit_test/rmh_physical_lawbook_read_only/Run()
	var/obj/item/book/law/book = allocate(/obj/item/book/law)
	var/obj/item/book/law/other = allocate(/obj/item/book/law)
	TEST_ASSERT_EQUAL(book.documents, other.documents, "Physical Tomes have different publication owners.")
	TEST_ASSERT(!length(book.pages) && !length(other.pages), "Physical Tomes eagerly copied legacy pages.")
	TEST_ASSERT(book.override_find_book, "The legacy per-item page loader is still enabled.")
	TEST_ASSERT(book.resistance_flags & FIRE_PROOF, "The Tome is not fireproof.")
	TEST_ASSERT(!(book.resistance_flags & FLAMMABLE), "The Tome is still flammable.")
	TEST_ASSERT_EQUAL(book.firefuel, 0, "A fireproof Tome can still be consumed as fuel.")
	book.fire_act(10)
	TEST_ASSERT(!(book.resistance_flags & ON_FIRE), "The Tome caught fire.")
	var/snapshot = json_encode(book.documents.lawbook.content)
	var/revision = book.documents.lawbook.revision
	TEST_ASSERT(!book.ui_act("publish", list("document" = "lawbook", "content" = "forged")), "The reader accepted a forged publication.")
	TEST_ASSERT(!book.ui_act("save_draft", list()), "The reader accepted a draft action.")
	TEST_ASSERT_EQUAL(book.documents.lawbook.revision, revision, "A rejected reader action changed the revision.")
	TEST_ASSERT_EQUAL(json_encode(book.documents.lawbook.content), snapshot, "A rejected reader action changed the book.")
	var/list/redacted = book.ui_data(null)
	var/list/redacted_book = redacted["lawbook"]
	TEST_ASSERT(!length(redacted_book["chapters"]), "The reader disclosed pages without an eligible reader.")

/datum/unit_test/rmh_recipe_shelves_include_lawbook
/datum/unit_test/rmh_recipe_shelves_include_lawbook/Run()
	var/list/shelves = list(
		allocate(/obj/structure/bookcase/random_recipes),
		allocate(/obj/structure/bookcase/fancy/random_recipes),
	)
	for(var/obj/structure/bookcase/shelf as anything in shelves)
		var/tomes = 0
		var/recipes = 0
		for(var/obj/item/book/law/book in shelf)
			tomes++
		for(var/obj/item/recipe_book/book in shelf)
			recipes++
		TEST_ASSERT_EQUAL(tomes, 1, "A recipe shelf should start with exactly one Tome.")
		TEST_ASSERT_EQUAL(recipes, 4, "Adding a Tome replaced the shelf's recipe books.")

/datum/unit_test/rmh_bilingual_law_boundaries
/datum/unit_test/rmh_bilingual_law_boundaries/Run()
	var/datum/rmh_law_document/code/doc = allocate(/datum/rmh_law_document/code)
	var/list/legacy = doc.normalize(list(list("id" = "draft_old", "text" = "Original")))
	TEST_ASSERT_NOTNULL(legacy, "An old-format saved draft was rejected.")
	var/list/old_row = legacy[1]
	TEST_ASSERT_EQUAL(old_row["text_en"], "", "An old draft acquired an invented translation.")
	var/list/input_row = list("id" = "draft_bilingual", "text" = "Original", "text_en" = "English <plain text>")
	var/list/normalized = doc.normalize(list(input_row))
	TEST_ASSERT_NOTNULL(normalized, "A valid English translation was rejected.")
	var/list/row = normalized[1]
	TEST_ASSERT_EQUAL(row["text_en"], "English <plain text>", "The translation was dropped or interpreted as HTML.")
	input_row["text_en"] = "Changed input"
	TEST_ASSERT_EQUAL(row["text_en"], "English <plain text>", "The document retained a mutable editor record.")
	input_row["text_en"] = repeat_string(2049, "x")
	TEST_ASSERT_NULL(doc.normalize(list(input_row)), "An oversized translation was accepted.")
	input_row["text_en"] = 123
	TEST_ASSERT_NULL(doc.normalize(list(input_row)), "A non-text translation was accepted.")

/datum/unit_test/rmh_decree_translation_identity
/datum/unit_test/rmh_decree_translation_identity/Run()
	var/list/legacy_before = GLOB.lord_decrees
	var/datum/rmh_law_documents/store = allocate(/datum/rmh_law_documents)
	GLOB.lord_decrees = list("First", "Second")
	store.sync_legacy_decrees()
	var/list/first = store.decrees[1]
	var/id = first["id"]
	var/error = store.publish_decree_translation(id, first["revision"], "Translated first")
	var/stale_error = store.publish_decree_translation(id, 1, "Stale overwrite")
	GLOB.lord_decrees = list("Second", "First")
	store.sync_legacy_decrees()
	var/list/moved = store.decrees[2]
	var/moved_id = moved["id"]
	var/moved_english = moved["text_en"]
	GLOB.lord_decrees = list("Replacement", "Second")
	store.sync_legacy_decrees()
	var/list/replacement = store.decrees[1]
	var/new_id = replacement["id"]
	var/new_english = replacement["text_en"]
	var/deleted_error = store.publish_decree_translation(id, 2, "Wrong decree")
	// Restore legacy round state before assertions can return early.
	GLOB.lord_decrees = legacy_before
	TEST_ASSERT_NULL(error, "A valid decree translation was rejected.")
	TEST_ASSERT_NOTNULL(stale_error, "A stale translation overwrote a newer one.")
	TEST_ASSERT_EQUAL(moved_id, id, "Reordering changed the identity of an unchanged decree.")
	TEST_ASSERT_EQUAL(moved_english, "Translated first", "Reordering moved the translation onto another decree.")
	TEST_ASSERT_NOTEQUAL(new_id, id, "A replacement decree reused an abolished identity.")
	TEST_ASSERT_EQUAL(new_english, "", "A new decree inherited an unrelated translation.")
	TEST_ASSERT_NOTNULL(deleted_error, "An abolished decree accepted a translation.")

/datum/unit_test/rmh_scom_reader_modes
/datum/unit_test/rmh_scom_reader_modes/Run()
	var/obj/structure/fake_machine/scomm/device = allocate(/obj/structure/fake_machine/scomm)
	TEST_ASSERT_EQUAL(device.rmh_reader_mode(), "normal", "An active general-line SCOM has the wrong reader mode.")
	device.garrisonline = TRUE
	TEST_ASSERT_EQUAL(device.rmh_reader_mode(), "garrison", "An active garrison-line SCOM has the wrong reader mode.")
	device.speaking = FALSE
	TEST_ASSERT_EQUAL(device.rmh_reader_mode(), "muted", "Mute must take priority over the garrison line.")
	device.speaking = TRUE
	device.listening = FALSE
	TEST_ASSERT_EQUAL(device.rmh_reader_mode(), "muted", "A deafened SCOM must use the muted reader mode.")
	device.listening = TRUE
	device.obj_broken = TRUE
	TEST_ASSERT_EQUAL(device.rmh_reader_mode(), "muted", "A broken SCOM must use the muted reader mode.")

/datum/unit_test/rmh_private_notes_boundaries
/datum/unit_test/rmh_private_notes_boundaries/Run()
	var/list/row = list("id" = "draft_note", "title" = "", "body" = "")
	var/list/normalized = rmh_normalize_law_notes(list(row), list(), TRUE)
	TEST_ASSERT_NOTNULL(normalized, "An unfinished private note was rejected.")
	row["body"] = "Changed after validation"
	var/list/saved_row = normalized[1]
	TEST_ASSERT_EQUAL(saved_row["body"], "", "The normalized note retained mutable input.")
	TEST_ASSERT_NULL(rmh_normalize_law_notes(list(row, row)), "Duplicate note IDs were accepted.")
	row["id"] = "note_999"
	TEST_ASSERT_NULL(rmh_normalize_law_notes(list(row), list("note_1"), TRUE), "A forged official note ID was accepted.")
	row["id"] = "draft_note"
	row["body"] = repeat_string(8193, "x")
	TEST_ASSERT_NULL(rmh_normalize_law_notes(list(row)), "An oversized note was accepted.")
	TEST_ASSERT_NOTNULL(rmh_normalize_law_notes(list()), "Deleting every note must be valid.")
	var/datum/preference/list_type/rmh_law_notes/pref = allocate(/datum/preference/list_type/rmh_law_notes)
	var/list/entries = list(list("id" = "note_1", "title" = "Private", "body" = "<plain text>"))
	var/list/record = list("character" = "Character A", "role" = "burgmeister", "revision" = 2, "next_id" = 1, "entries" = entries, "schema" = 1)
	TEST_ASSERT(pref.is_valid(list(record)), "A valid private note record was rejected.")
	TEST_ASSERT(!pref.is_accessible(null), "Private notes are exposed in generic preferences.")
	TEST_ASSERT(!pref.is_valid(list(record, record)), "Duplicate private identities were accepted.")
	var/list/other = record.Copy()
	other["role"] = "councilor"
	TEST_ASSERT(pref.is_valid(list(record, other)), "The two offices cannot keep separate notes.")
	other["role"] = "servant"
	TEST_ASSERT(!pref.is_valid(list(other)), "An unrelated office can store private notes.")
	other = record.Copy()
	other["character"] = "Character B"
	TEST_ASSERT(pref.is_valid(list(record, other)), "Characters cannot keep separate notes.")
	other = record.Copy()
	other["next_id"] = 0
	TEST_ASSERT(!pref.is_valid(list(other)), "A corrupt official note counter was accepted.")
	other = record.Copy()
	other["schema"] = 2
	TEST_ASSERT(!pref.is_valid(list(other)), "An unknown notes schema was accepted.")

/datum/unit_test/rmh_throat_laws_disabled
/datum/unit_test/rmh_throat_laws_disabled/Run()
	var/obj/structure/fake_machine/titan/throat = allocate(/obj/structure/fake_machine/titan)
	var/snapshot = json_encode(GLOB.laws_of_the_land)
	TEST_ASSERT(!throat.make_law(null, "Forbidden"), "THROAT still accepts a law.")
	TEST_ASSERT(!throat.remove_law("remove law 1"), "THROAT still revokes laws.")
	TEST_ASSERT(!throat.purge_laws(), "THROAT still purges laws.")
	for(var/command in list("make law", "remove law 1", "purge laws"))
		TEST_ASSERT(!throat.recognize_command(null, command), "A disabled voice command was accepted.")
	for(var/action in list("make_law", "remove_law", "purge_laws"))
		TEST_ASSERT(!throat.ui_act(action, list("text" = "Forbidden", "index" = "1")), "A forged disabled UI command was accepted.")
	throat.switch_mode("Make Law")
	TEST_ASSERT_EQUAL(throat.mode, "None", "The disabled law-writing mode is still reachable.")
	TEST_ASSERT(!("Make Law" in throat.command_list) && !("Remove Law" in throat.command_list) && !("Purge Laws" in throat.command_list), "Help still advertises disabled law commands.")
	TEST_ASSERT(("Make Decree" in throat.command_list) && ("Remove Decree" in throat.command_list) && ("Set Taxes" in throat.command_list), "Unrelated THROAT commands disappeared.")
	TEST_ASSERT_EQUAL(json_encode(GLOB.laws_of_the_land), snapshot, "A disabled THROAT command changed the code.")

/datum/unit_test/rmh_decree_board_states
/datum/unit_test/rmh_decree_board_states/Run()
	var/obj/structure/rmh_decree_board/board = allocate(/obj/structure/rmh_decree_board)
	board.UnregisterSignal(board.documents, list("rmh_decrees_changed", COMSIG_PARENT_QDELETING))
	board.on_documents_deleted(board.documents)
	var/datum/rmh_law_documents/store = allocate(/datum/rmh_law_documents)
	store.decrees = list()
	board.documents = store
	board.RegisterSignal(store, "rmh_decrees_changed", "on_decrees_changed")
	board.RegisterSignal(store, COMSIG_PARENT_QDELETING, "on_documents_deleted")
	board.update_appearance()
	TEST_ASSERT_NULL(board.count_message(), "An empty board announces.")
	TEST_ASSERT_EQUAL(board.icon_state, "decree_board_1", "An empty board is not intact.")
	TEST_ASSERT_EQUAL(length(board.overlays), 0, "An empty board displays notices.")
	store.decrees = list(list("id" = "decree_1", "text" = "An active decree", "text_en" = "", "revision" = 1))
	SEND_SIGNAL(store, "rmh_decrees_changed")
	TEST_ASSERT_EQUAL(board.icon_state, "decree_board_2", "A decree notification did not select the populated sprite.")
	TEST_ASSERT_EQUAL(length(board.overlays), 0, "A legacy paper overlay covers the new board sprite.")
	var/snapshot = json_encode(store.decrees)
	var/message = board.count_message()
	TEST_ASSERT_NOTNULL(message, "A populated board is silent.")
	board.atom_break(null, TRUE)
	TEST_ASSERT_EQUAL(board.icon_state, "decree_board_3", "The broken appearance did not activate.")
	TEST_ASSERT_EQUAL(length(board.overlays), 0, "A broken board still displays notices.")
	TEST_ASSERT_NOTEQUAL(board.count_message(), message, "A broken board's announcement is not distorted.")
	TEST_ASSERT(!board.can_read_decrees(null), "A broken board permits reading.")
	TEST_ASSERT(!board.ui_act("make_decree", list("text" = "Forged")), "A read-only board accepted an editing action.")
	TEST_ASSERT_EQUAL(json_encode(store.decrees), snapshot, "Breaking or reading the board changed central decrees.")
	var/obj/item/natural/glass/pane = allocate(/obj/item/natural/glass)
	var/obj/item/natural/glass/shard/shard = allocate(/obj/item/natural/glass/shard)
	var/obj/item/natural/bundle/glass/bundle = allocate(/obj/item/natural/bundle/glass)
	TEST_ASSERT(board.is_repair_glass(pane), "A glass pane cannot repair the board.")
	TEST_ASSERT(board.is_repair_glass(bundle), "A glass bundle cannot repair the board.")
	TEST_ASSERT(!board.is_repair_glass(shard), "A glass shard can repair the board.")
	bundle.amount = 0
	TEST_ASSERT(!board.is_repair_glass(bundle), "An empty glass bundle can repair the board.")
	board.atom_fix()
	TEST_ASSERT_EQUAL(board.icon_state, "decree_board_2", "Repair did not restore the populated sprite.")
	TEST_ASSERT_EQUAL(board.icon, 'modular_rmh/icons/obj/structures/laws_objs.dmi', "The board does not use the supplied artwork.")
	TEST_ASSERT_EQUAL(length(board.overlays), 0, "Repair restored the obsolete paper overlay.")
	TEST_ASSERT_EQUAL(board.count_message(), message, "Repair did not restore clear speech.")
	store.decrees = list()
	SEND_SIGNAL(store, "rmh_decrees_changed")
	TEST_ASSERT_EQUAL(board.icon_state, "decree_board_1", "Revocation did not restore the empty sprite.")
	TEST_ASSERT_NULL(board.count_message(), "A board without active decrees still announces.")
	qdel(store)
	TEST_ASSERT_NULL(board.documents, "The board retained its deleted publication owner.")
	TEST_ASSERT_NULL(board.announcement_timer, "Deleting the publication owner retained the announcement timer.")

/datum/unit_test/rmh_poster_snapshot_isolation
/datum/unit_test/rmh_poster_snapshot_isolation/Run()
	var/obj/item/rmh_decree_poster/poster = allocate(/obj/item/rmh_decree_poster)
	var/list/entry = list("id" = "decree_1", "text" = "Original decree <plain text>", "text_en" = "English copy", "revision" = 1)
	TEST_ASSERT(poster.copy_decree(entry), "A valid decree could not be copied.")
	TEST_ASSERT_EQUAL(poster.icon_state, "decree_poster_3", "A filled portable poster is not ready for hanging.")
	entry["text"] = "Changed official text"
	entry["text_en"] = "Changed translation"
	TEST_ASSERT_EQUAL(poster.snapshot["text"], "Original decree <plain text>", "The poster retained mutable official data.")
	TEST_ASSERT_EQUAL(poster.snapshot["text_en"], "English copy", "The poster translation changed with the source.")
	TEST_ASSERT(!poster.copy_decree(entry), "A filled snapshot could be overwritten by copying again.")
	var/official = json_encode(entry)
	TEST_ASSERT(!poster.replace_forgery("Forged", "", 4, 0), "A stale forgery overwrote the poster.")
	TEST_ASSERT(poster.replace_forgery("Поддельный указ", "Forged decree", SKILL_RANK_EXPERT, 1), "A valid physical forgery was rejected.")
	TEST_ASSERT_EQUAL(json_encode(entry), official, "Forging the copy changed the official decree.")
	TEST_ASSERT_EQUAL(poster.content_revision, 2, "A forgery did not advance the local revision.")
	TEST_ASSERT_EQUAL(poster.snapshot["text_en"], "Forged decree", "The English forgery was not stored locally.")
	TEST_ASSERT(!poster.replace_forgery("", "", 4, 2), "A blank forged decree was accepted.")
	TEST_ASSERT(!poster.replace_forgery(repeat_string(2049, "x"), "", 4, 2), "An oversized forgery was accepted.")
	var/obj/item/rmh_decree_poster/other = allocate(/obj/item/rmh_decree_poster)
	TEST_ASSERT(!other.copy_decree(list("text" = repeat_string(2049, "x"))), "An oversized decree was silently copied.")
	TEST_ASSERT_NULL(other.snapshot, "A rejected copy filled a blank poster.")
	TEST_ASSERT(other.copy_decree(list("text" = "Legacy decree")), "A decree without an English field was rejected.")
	TEST_ASSERT_EQUAL(other.snapshot["text_en"], "", "A missing translation was invented.")
	var/list/redacted = poster.ui_data(null)
	TEST_ASSERT_EQUAL(length(redacted["decrees"]), 0, "An ineligible reader received the snapshot.")

/datum/unit_test/rmh_poster_forgery_marks
/datum/unit_test/rmh_poster_forgery_marks/Run()
	var/text = "Текст Text 12!?\n"
	var/list/marks = rmh_poster_marks(text, SKILL_RANK_EXPERT)
	TEST_ASSERT_EQUAL(length(marks), length_char(text), "Formatting is not indexed by Unicode characters.")
	for(var/mark in marks)
		TEST_ASSERT_EQUAL(mark, 0, "Expert handwriting acquired low-skill errors.")
	TEST_ASSERT_EQUAL(length(rmh_poster_marks("", 0)), 0, "An empty translation created formatting entries.")
	marks = rmh_poster_marks(text, SKILL_RANK_NONE)
	TEST_ASSERT_EQUAL(length(marks), length_char(text), "Low-skill formatting changed the text length.")
	for(var/index in 1 to length(marks))
		var/letter = copytext_char(text, index, index + 1)
		TEST_ASSERT(marks[index] in list(0, 1, 2), "Client markup or an unknown style reached the snapshot.")
		if(uppertext(letter) == lowertext(letter))
			TEST_ASSERT_EQUAL(marks[index], 0, "Non-letter punctuation was randomly emphasized.")

/datum/unit_test/rmh_poster_removal_preserves_sheet
/datum/unit_test/rmh_poster_removal_preserves_sheet/Run()
	for(var/tear in list(FALSE, TRUE))
		var/obj/structure/rmh_decree_poster/mount = allocate(/obj/structure/rmh_decree_poster)
		var/obj/item/rmh_decree_poster/sheet = allocate(/obj/item/rmh_decree_poster)
		sheet.copy_decree(list("text" = "A durable local snapshot", "text_en" = "Local translation"))
		var/snapshot = json_encode(sheet.snapshot)
		sheet.forceMove(mount)
		mount.poster = sheet
		var/obj/item/rmh_decree_poster/removed = mount.detach_poster(null, tear)
		TEST_ASSERT_EQUAL(removed, sheet, "Removal created a different sheet instead of returning the original.")
		TEST_ASSERT(!QDELETED(sheet), "Removing the mount deleted the readable sheet.")
		TEST_ASSERT(QDELETED(mount), "The empty mount survived removal.")
		TEST_ASSERT_EQUAL(json_encode(sheet.snapshot), snapshot, "Removal changed text, translation or formatting.")
		TEST_ASSERT_EQUAL(sheet.damaged, tear, "The requested careful/rough removal state was not preserved.")
		TEST_ASSERT_EQUAL(sheet.icon_state, tear ? "decree_poster_2" : "decree_poster_3", "Removal lost the portable/torn sprite.")
		TEST_ASSERT(isturf(sheet.loc), "The removed sheet was left inside a deleted mount.")
		var/obj/structure/rmh_decree_poster/invalid = allocate(/obj/structure/rmh_decree_poster)
		TEST_ASSERT(!invalid.attach_poster(sheet, null), "A poster can attach without a real wall.")

/datum/unit_test/rmh_mounted_poster_access
/datum/unit_test/rmh_mounted_poster_access/Run()
	var/obj/structure/rmh_decree_poster/mount = allocate(/obj/structure/rmh_decree_poster)
	var/obj/item/rmh_decree_poster/sheet = allocate(/obj/item/rmh_decree_poster)
	var/mob/living/carbon/human/reader = allocate(/mob/living/carbon/human)
	reader.forceMove(get_turf(mount))
	reader.set_skillrank(/datum/attribute/skill/misc/reading, SKILL_RANK_APPRENTICE)
	sheet.copy_decree(list("text" = "Mounted decree"))
	sheet.forceMove(mount)
	mount.poster = sheet
	TEST_ASSERT_EQUAL(sheet.ui_host(reader), mount, "A mounted sheet does not use its visible host.")
	TEST_ASSERT(sheet.can_handle(reader), "A nearby reader cannot access the contained sheet through its mount.")
	TEST_ASSERT(sheet.can_read_poster(reader), "A literate reader cannot open the mounted poster.")
	var/obj/item/tattoo_machine/tool = allocate(/obj/item/tattoo_machine)
	reader.put_in_hands(tool)
	sheet.tool_ref = WEAKREF(tool)
	TEST_ASSERT(sheet.can_forge(reader), "Holding a tattoo machine cannot reach the mounted poster.")
	reader.dropItemToGround(tool)
	TEST_ASSERT(!sheet.can_forge(reader), "Forging no longer requires the held tattoo machine.")
	mount.poster = null
	TEST_ASSERT(!sheet.can_handle(reader), "A sheet with the wrong mount ownership is accessible.")

/datum/unit_test/rmh_publication_notices
/datum/unit_test/rmh_publication_notices/Run()
	var/list/old = list(list("id" = "entry_1", "text" = "Existing law", "text_en" = ""))
	TEST_ASSERT_NULL(rmh_law_publication_notice("law_code", old, old.Copy()), "An unchanged publication announces.")
	var/list/one = old.Copy()
	one += list(list("id" = "entry_2", "text" = "<b>New law</b>", "text_en" = ""))
	var/list/notice = rmh_law_publication_notice("law_code", old, one, "en")
	TEST_ASSERT_EQUAL(notice["title"], "A LAW IS DECLARED", "One addition lost the original throne announcement.")
	TEST_ASSERT_EQUAL(notice["text"], "2. <b>New law</b>", "The announcement summary pre-encodes text that priority_announce will encode again.")
	TEST_ASSERT_EQUAL(html_encode(notice["text"]), "2. &lt;b&gt;New law&lt;/b&gt;", "The stock announcement encoder does not retain the law number and literal text.")
	var/list/batch = one.Copy()
	batch += list(list("id" = "entry_3", "text" = "Another law", "text_en" = ""))
	notice = rmh_law_publication_notice("law_code", old, batch)
	TEST_ASSERT(findtext(notice["text"], "2"), "A batch announcement did not count its two new laws.")
	TEST_ASSERT(!findtext(notice["text"], "Another law"), "A batch unnecessarily broadcasts every legal paragraph.")
	var/list/amended = list(list("id" = "entry_1", "text" = "Amended wording", "text_en" = ""))
	notice = rmh_law_publication_notice("law_code", old, amended)
	TEST_ASSERT_NOTEQUAL(notice["title"], "A LAW IS DECLARED", "Amending an existing ID announces a new law.")
	notice = rmh_law_publication_notice("lawbook", list("title" = "Before", "chapters" = list()), list("title" = "After", "chapters" = list()))
	TEST_ASSERT_NOTNULL(notice, "A changed detailed book has no amendment announcement.")
	TEST_ASSERT_EQUAL(notice["sound"], 'sound/misc/alert.ogg', "The documented temporary book cue changed without its report.")

/datum/unit_test/rmh_lawbook_translation_compatibility
/datum/unit_test/rmh_lawbook_translation_compatibility/Run()
	var/datum/rmh_law_document/book/doc = allocate(/datum/rmh_law_document/book)
	var/list/legacy = list("title" = "Original", "chapters" = list(list("id" = "draft_chapter", "title" = "Chapter", "intro" = "", \
		"articles" = list(list("id" = "draft_article", "title" = "Article", "body" = "Source text")))))
	var/list/normalized = doc.normalize(legacy)
	TEST_ASSERT_NOTNULL(normalized, "Old saved books without translation fields became invalid.")
	TEST_ASSERT_EQUAL(normalized["title_en"], "", "Normalization invented a translation.")
	var/list/chapters = normalized["chapters"]
	var/list/chapter = chapters[1]
	var/list/articles = chapter["articles"]
	var/list/article = articles[1]
	normalized["title_en"] = "English book"
	chapter["title_en"] = "English chapter"
	article["body_en"] = "English text"
	TEST_ASSERT_NOTNULL(doc.normalize(normalized), "A bilingual book was rejected.")
	TEST_ASSERT_EQUAL(article["body"], "Source text", "Translation replaced the source body.")
	article["body_en"] = repeat_string(8193, "x")
	TEST_ASSERT_NULL(doc.normalize(normalized), "Oversized translated body bypassed validation.")
	article["body_en"] = 123
	TEST_ASSERT_NULL(doc.normalize(normalized), "A nontext translation was accepted.")
	article["body_en"] = ""
	chapter["unknown"] = "Untrusted metadata"
	TEST_ASSERT_NULL(doc.normalize(normalized), "Unknown chapter fields survived normalization.")
	TEST_ASSERT_NOTNULL(doc.normalize(legacy), "Validation mutated the legacy saved payload.")

/datum/unit_test/rmh_identical_publications_are_quiet
/datum/unit_test/rmh_identical_publications_are_quiet/Run()
	var/datum/rmh_law_documents/store = allocate(/datum/rmh_law_documents)
	var/book_revision = store.lawbook.revision
	var/code_revision = store.law_code.revision
	var/next_book_id = store.lawbook.next_id
	TEST_ASSERT_NULL(store.publish("lawbook", book_revision, store.lawbook.content), "Unchanged book publication was rejected.")
	TEST_ASSERT_EQUAL(store.lawbook.revision, book_revision, "An unchanged book invalidated other editors.")
	TEST_ASSERT_EQUAL(store.lawbook.next_id, next_book_id, "An unchanged book consumed identifiers.")
	TEST_ASSERT_NULL(store.publish("law_code", code_revision, store.law_code.content), "Unchanged code publication was rejected.")
	TEST_ASSERT_EQUAL(store.law_code.revision, code_revision, "An unchanged code invalidated other editors.")

/datum/unit_test/rmh_poster_titles_and_mechanics
/datum/unit_test/rmh_poster_titles_and_mechanics/Run()
	TEST_ASSERT_EQUAL(rmh_decree_title("Title\nBody"), "Title", "The poster title includes the body.")
	TEST_ASSERT_EQUAL(rmh_decree_title("  Заголовок[ascii2text(13)]\nТекст"), "Заголовок", "A Cyrillic or CRLF title is malformed.")
	var/obj/item/rmh_decree_poster/poster = allocate(/obj/item/rmh_decree_poster)
	poster.copy_decree(list("text" = "Первый указ\nТекст"))
	TEST_ASSERT(findtext(poster.name, "Первый указ"), "Copying did not name the poster from its title.")
	TEST_ASSERT(poster.replace_forgery("Другой заголовок\nПодделка", "", SKILL_RANK_EXPERT, 1), "Valid titled forgery failed.")
	TEST_ASSERT(findtext(poster.name, "Другой заголовок"), "Forgery did not update the poster title.")
	TEST_ASSERT_EQUAL(length(poster.get_mechanics_examine(null)), 5, "Poster mechanics are missing from the stock collapsible list.")

/datum/unit_test/rmh_localized_publication_messages
/datum/unit_test/rmh_localized_publication_messages/Run()
	var/list/old = list()
	var/list/next = list(list("id" = "entry_1", "text" = "Исходный закон", "text_en" = "English law"))
	var/list/ru = rmh_law_publication_notice("law_code", old, next, "ru")
	var/list/en = rmh_law_publication_notice("law_code", old, next, "en")
	TEST_ASSERT(findtext(ru["text"], "Исходный закон"), "Russian publication lost the source.")
	TEST_ASSERT(findtext(en["text"], "English law"), "English publication ignored its manual translation.")
	TEST_ASSERT_NOTEQUAL(ru["title"], en["title"], "Publication headers ignore language.")
	TEST_ASSERT_EQUAL(rmh_law_revision_message("law_code", 4, "ru"), "Опубликована 4-я редакция свода.", "Russian revision feedback exposes internal document IDs.")
	TEST_ASSERT(findtext(rmh_law_revision_message("lawbook", 4, "en"), "revision 4"), "English revision feedback is missing.")
#endif
