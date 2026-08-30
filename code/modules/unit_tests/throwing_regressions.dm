/datum/unit_test/throwing_deleted_grab_pickup
	procs_tested = list(/obj/item/proc/attempt_pickup)
#ifdef FOCUS_THROWING_REGRESSION_TESTS
	focus = TRUE
#endif

/datum/unit_test/throwing_deleted_grab_pickup/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/grabbing/grab = allocate(/obj/item/grabbing)
	TEST_ASSERT(user.put_in_active_hand(grab, forced = TRUE), "Could not put the test grab into the user's hand.")

	grab.attempt_pickup(user)

	TEST_ASSERT(QDELETED(grab), "Picking up a held DROPDEL grab did not delete it.")
	TEST_ASSERT_NULL(user.get_active_held_item(), "Deleting the grab left it in the user's hand.")

/datum/unit_test/throwing_fetch_uses_thrown_object
	procs_tested = list(/datum/pet_command/fetch/proc/listened_throw)
#ifdef FOCUS_THROWING_REGRESSION_TESTS
	focus = TRUE
#endif

/datum/unit_test/throwing_fetch_uses_thrown_object/Run()
	var/mob/living/simple_animal/hostile/pet = allocate(/mob/living/simple_animal/hostile)
	if(!pet.ai_controller)
		allocate(/datum/ai_controller, pet)
	var/mob/living/carbon/human/thrower = allocate(/mob/living/carbon/human)
	var/datum/pet_command/fetch/fetch_command = allocate(/datum/pet_command/fetch, pet)
	var/obj/item/thrown_item = allocate(/obj/item)

	fetch_command.listened_throw(thrower, thrown_item)
	sleep(1) // Immediate landings defer command activation out of the signal handler.

	TEST_ASSERT_EQUAL(pet.ai_controller.blackboard[BB_CURRENT_PET_TARGET], thrown_item, "Fetch ignored the object reported by a completed throw.")
	TEST_ASSERT_EQUAL(pet.ai_controller.blackboard[BB_FETCH_DELIVER_TO], thrower, "Fetch did not remember who threw the item.")
	pet.ai_controller.clear_blackboard_key(BB_CURRENT_PET_TARGET)
	pet.ai_controller.clear_blackboard_key(BB_FETCH_DELIVER_TO)
	var/mob/living/carbon/human/thrown_mob = allocate(/mob/living/carbon/human)

	fetch_command.listened_throw(thrower, thrown_mob)
	fetch_command.listened_throw(thrower, thrown_mob)

	TEST_ASSERT_NULL(pet.ai_controller.blackboard[BB_CURRENT_PET_TARGET], "Fetch tried to retrieve a thrown mob.")

/datum/unit_test/throwing_fireman_carry
	procs_tested = list(/mob/living/carbon/throw_item)
#ifdef FOCUS_THROWING_REGRESSION_TESTS
	focus = TRUE
#endif

/datum/unit_test/throwing_fireman_carry/Run()
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/passenger = allocate(/mob/living/carbon/human)
	TEST_ASSERT(carrier.start_pulling(passenger, GRAB_PASSIVE, suppress_message = TRUE, accurate = TRUE), "Could not establish the test grab.")
	TEST_ASSERT(istype(carrier.get_active_held_item(), /obj/item/grabbing), "The test grab did not occupy the active hand.")
	TEST_ASSERT(carrier.buckle_mob(passenger, force = TRUE, check_loc = TRUE, buckle_mob_flags = CARRIER_NEEDS_ARM), "Could not begin the fireman carry.")
	TEST_ASSERT_NOTNULL(carrier.GetComponent(/datum/component/riding), "Fireman carry did not create its riding component.")
	passenger.move_resist = MOVE_FORCE_VERY_WEAK

	carrier.throw_item(run_loc_floor_top_right)

	TEST_ASSERT_NULL(passenger.buckled, "Throwing a fireman-carried passenger left them buckled.")
	TEST_ASSERT(!carrier.has_buckled_mobs(), "Throwing a fireman-carried passenger left them in the carrier's passenger list.")
	TEST_ASSERT_NULL(carrier.GetComponent(/datum/component/riding), "Throwing a fireman-carried passenger left the riding component active.")
	TEST_ASSERT(carrier.pulling != passenger, "Throwing a fireman-carried passenger left the grab active.")
	TEST_ASSERT(passenger.throwing || get_turf(passenger) != get_turf(carrier), "The fireman-carried passenger was released without being thrown.")

/obj/item/throwing_signal_test
	move_resist = MOVE_FORCE_VERY_WEAK

/datum/unit_test/throwing_success_signal
	procs_tested = list(/mob/living/carbon/throw_item)
	var/atom/movable/signaled_thing
	var/throw_signal_count = 0
#ifdef FOCUS_THROWING_REGRESSION_TESTS
	focus = TRUE
#endif

/datum/unit_test/throwing_success_signal/proc/record_throw(mob/source, atom/movable/thrown_thing)
	SIGNAL_HANDLER
	signaled_thing = thrown_thing
	throw_signal_count++

/datum/unit_test/throwing_success_signal/Run()
	var/mob/living/carbon/human/thrower = allocate(/mob/living/carbon/human)
	RegisterSignal(thrower, COMSIG_MOB_THROW, PROC_REF(record_throw))
	var/obj/item/throwing_signal_test/thrown_item = allocate(/obj/item/throwing_signal_test)
	TEST_ASSERT(thrower.put_in_active_hand(thrown_item, forced = TRUE), "Could not equip the throwable test item.")

	thrower.throw_item(run_loc_floor_top_right)
	sleep(1) // Signal callbacks are dispatched through CallAsync.

	TEST_ASSERT(thrown_item.throwing || get_turf(thrown_item) != get_turf(thrower), "The test item was not thrown.")
	TEST_ASSERT_EQUAL(signaled_thing, thrown_item, "The throw signal did not report the object that was actually thrown.")
	TEST_ASSERT_EQUAL(throw_signal_count, 1, "One successful throw emitted an unexpected number of throw signals.")
