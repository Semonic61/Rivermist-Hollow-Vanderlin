/datum/unit_test/non_craving_vices_do_not_create_generic_addiction
#ifdef FOCUS_QUIRKS_TEST
	focus = TRUE
#endif

/datum/unit_test/non_craving_vices_do_not_create_generic_addiction/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)

	TEST_ASSERT(human.add_quirk(/datum/quirk/vice/wanted), "Test human should accept the Wanted vice.")
	var/datum/quirk/vice/wanted/wanted = human.get_quirk(/datum/quirk/vice/wanted)
	TEST_ASSERT_NOTNULL(wanted, "Test human should have the Wanted vice.")

	wanted.on_life(human)

	TEST_ASSERT_NULL(human.has_status_effect(/datum/status_effect/debuff/addiction), "Non-craving vices should not create generic addiction status effects.")
	TEST_ASSERT_NULL(human.has_stress_type(/datum/stress_event/vice1), "Non-craving vices should not create generic vice stress.")
	TEST_ASSERT_NULL(human.has_stress_type(/datum/stress_event/vice2), "Non-craving vices should not create generic vice stress.")
	TEST_ASSERT_NULL(human.has_stress_type(/datum/stress_event/vice3), "Non-craving vices should not create generic vice stress.")

/datum/unit_test/craving_vices_still_create_specific_addiction
#ifdef FOCUS_QUIRKS_TEST
	focus = TRUE
#endif

/datum/unit_test/craving_vices_still_create_specific_addiction/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)

	TEST_ASSERT(human.add_quirk(/datum/quirk/vice/addiction/smoker), "Test human should accept the Smoker vice.")
	var/datum/quirk/vice/addiction/smoker/smoker = human.get_quirk(/datum/quirk/vice/addiction/smoker)
	TEST_ASSERT_NOTNULL(smoker, "Test human should have the Smoker vice.")

	smoker.next_sate = world.time - 1
	smoker.on_life(human)

	TEST_ASSERT_NOTNULL(human.has_status_effect(/datum/status_effect/debuff/addiction/smoker), "Craving vices should keep creating their specific addiction status effects.")
	TEST_ASSERT_NOTNULL(human.has_stress_type(/datum/stress_event/vice1), "Craving vices should keep creating generic vice stress.")

/datum/unit_test/masochist_uses_custom_addiction_satisfaction
#ifdef FOCUS_QUIRKS_TEST
	focus = TRUE
#endif

/datum/unit_test/masochist_uses_custom_addiction_satisfaction/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)

	TEST_ASSERT(human.add_quirk(/datum/quirk/vice/addiction/masochist), "Test human should accept the Masochist vice.")
	var/datum/quirk/vice/addiction/masochist/masochist = human.get_quirk(/datum/quirk/vice/addiction/masochist)
	TEST_ASSERT_NOTNULL(masochist, "Test human should have the Masochist vice.")

	masochist.next_paincrave = world.time - 1
	masochist.on_life(human)
	TEST_ASSERT_NOTNULL(human.has_status_effect(/datum/status_effect/debuff/addiction/masochist), "An unsated Masochist should receive their pain-craving status effect.")
	TEST_ASSERT_NOTNULL(human.has_stress_type(/datum/stress_event/vice), "An unsated Masochist should receive their custom vice stress.")

	human.sate_addiction(/datum/quirk/vice/addiction/masochist)
	TEST_ASSERT_NULL(human.has_status_effect(/datum/status_effect/debuff/addiction/masochist), "Sating Masochist through the addiction API should clear its pain-craving status effect.")
	TEST_ASSERT_NULL(human.has_stress_type(/datum/stress_event/vice), "Sating Masochist through the addiction API should clear its custom vice stress.")
	TEST_ASSERT(masochist.next_paincrave > world.time, "Sating Masochist should postpone the next pain craving.")

/datum/unit_test/legacy_addiction_quirk_path_migrates
#ifdef FOCUS_QUIRKS_TEST
	focus = TRUE
#endif

/datum/unit_test/legacy_addiction_quirk_path_migrates/Run()
	var/savefile_path = "data/unit_test_legacy_addiction_quirk.sav"
	fdel(savefile_path)

	var/savefile/legacy_save = new /savefile(savefile_path)
	legacy_save.cd = "/character1"
	WRITE_FILE(legacy_save["quirks"], list(list(
		"type" = /datum/quirk/vice/maniac,
		"value" = null,
		"extra" = null,
	)))

	var/datum/preferences/preferences = allocate(/datum/preferences)
	preferences.load_quirks(legacy_save)

	TEST_ASSERT(/datum/quirk/vice/addiction/sadist in preferences.quirks, "The old Maniac save path should migrate to the Sadist addiction subtype.")
	TEST_ASSERT(!(/datum/quirk/vice/maniac in preferences.quirks), "The hidden Maniac alias should not remain in loaded preferences.")

	fdel(savefile_path)

/datum/unit_test/virgin_quirk_uses_shared_trait
#ifdef FOCUS_QUIRKS_TEST
	focus = TRUE
#endif

/datum/unit_test/virgin_quirk_uses_shared_trait/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)

	TEST_ASSERT(human.add_quirk(/datum/quirk/peculiarity/virgin), "Test human should accept the Virgin peculiarity.")
	TEST_ASSERT(HAS_TRAIT(human, TRAIT_VIRGIN), "The Virgin peculiarity should grant the shared virginity trait.")

	human.lose_virginity()
	TEST_ASSERT(!HAS_TRAIT(human, TRAIT_VIRGIN), "Losing virginity should remove the quirk-granted trait.")
