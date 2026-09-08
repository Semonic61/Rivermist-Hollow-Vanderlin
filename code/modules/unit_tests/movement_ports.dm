/// A completed throw must not erase a replacement started by its landing callback.
/datum/unit_test/throw_callback_keeps_replacement
	var/callback_count = 0
#ifdef FOCUS_MOVEMENT_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/throw_callback_keeps_replacement/proc/throw_again(obj/item/item)
	callback_count++
	item.throw_at(run_loc_floor_top_right, 10, 0.1)

/datum/unit_test/throw_callback_keeps_replacement/Run()
	var/obj/item/item = allocate(/obj/item)
	item.throw_at(run_loc_floor_top_right, 10, 0.1, callback = CALLBACK(src, PROC_REF(throw_again), item))
	var/datum/thrownthing/first_throw = item.throwing
	TEST_ASSERT_NOTNULL(first_throw, "The initial throw must still be in flight.")
	first_throw.finalize()

	TEST_ASSERT(QDELETED(first_throw), "The completed throw must release its references.")
	TEST_ASSERT_NOTNULL(item.throwing, "Landing cleanup erased the callback's replacement throw.")
	TEST_ASSERT_EQUAL(SSthrowing.processing[item], item.throwing, "The replacement must remain scheduled.")
	first_throw.finalize()
	TEST_ASSERT_EQUAL(callback_count, 1, "A throw's callback must run only once.")

/// Deleting the thrown atom during a callback must stop the rest of landing cleanup.
/datum/unit_test/throw_callback_can_delete_item
#ifdef FOCUS_MOVEMENT_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/throw_callback_can_delete_item/proc/delete_item(obj/item/item)
	qdel(item)

/datum/unit_test/throw_callback_can_delete_item/Run()
	var/obj/item/item = allocate(/obj/item)
	item.throw_at(run_loc_floor_top_right, 10, 0.1, callback = CALLBACK(src, PROC_REF(delete_item), item))
	var/datum/thrownthing/trajectory = item.throwing
	TEST_ASSERT_NOTNULL(trajectory, "The test throw must still be in flight.")
	trajectory.finalize()
	TEST_ASSERT(QDELETED(item), "The callback should delete the item.")
	TEST_ASSERT(QDELETED(trajectory), "Deleting the item should also delete its trajectory.")
	TEST_ASSERT(!(item in SSthrowing.processing), "Deleted items must leave the throwing subsystem.")

/datum/unit_test/throw_replacement_releases_old_trajectory
#ifdef FOCUS_MOVEMENT_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/throw_replacement_releases_old_trajectory/Run()
	var/obj/item/item = allocate(/obj/item)
	item.throw_at(run_loc_floor_top_right, 10, 0.1)
	var/datum/thrownthing/first_throw = item.throwing
	TEST_ASSERT_NOTNULL(first_throw, "The initial throw must still be in flight.")
	item.throw_at(run_loc_floor_top_right, 10, 0.1)
	TEST_ASSERT(QDELETED(first_throw), "Replacing an active throw must release its old trajectory.")
	TEST_ASSERT_NOTNULL(item.throwing, "The replacement throw must remain active.")
	TEST_ASSERT_EQUAL(SSthrowing.processing[item], item.throwing, "Only the replacement should be processed.")

/datum/unit_test/thrower_reference_expires_safely
#ifdef FOCUS_MOVEMENT_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/thrower_reference_expires_safely/Run()
	var/obj/item/item = allocate(/obj/item)
	var/mob/living/carbon/human/thrower = allocate(/mob/living/carbon/human)
	item.throw_at(run_loc_floor_top_right, 10, 0.1, thrower)
	var/datum/thrownthing/trajectory = item.throwing
	TEST_ASSERT_NOTNULL(trajectory, "The test throw must still be in flight.")
	TEST_ASSERT_EQUAL(trajectory.get_thrower(), thrower, "A live thrower must retain damage attribution.")
	qdel(thrower)
	TEST_ASSERT_NULL(trajectory.get_thrower(), "A deleted thrower must resolve to null.")
	trajectory.finalize()
	TEST_ASSERT(QDELETED(trajectory), "Landing must still finish after the thrower is deleted.")

/// Re-registering and losing a client must respect the fork's town AI policy.
/datum/unit_test/z_registration_cleanup_preserves_ai_policy
#ifdef FOCUS_MOVEMENT_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/z_registration_cleanup_preserves_ai_policy/Run()
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	var/mob/living/simple_animal/hostile/npc = allocate(/mob/living/simple_animal/hostile)
	var/datum/ai_controller/controller = npc.ai_controller
	if(!controller)
		controller = allocate(/datum/ai_controller, npc)
	var/test_z = viewer.z
	var/list/old_clients = SSmobs.clients_by_zlevel[test_z]
	var/list/old_town_z = SSmobs.town_z
	SSmobs.town_z = old_town_z.Copy()
	SSmobs.town_z -= test_z

	// Model Logout after client has already been cleared.
	SSmobs.clients_by_zlevel[test_z] = list(viewer)
	controller.set_ai_status(AI_STATUS_ON)
	viewer.update_z(null)
	var/removed_client = !(viewer in SSmobs.clients_by_zlevel[test_z])
	var/removed_mob = !(viewer in SSmobs.mobs_by_zlevel[test_z])
	var/empty_level_status = controller.ai_status

	viewer.update_z(test_z)
	viewer.update_z(test_z)
	var/registrations = 0
	for(var/mob/registered_mob in SSmobs.mobs_by_zlevel[test_z])
		if(registered_mob == viewer)
			registrations++

	SSmobs.town_z |= test_z
	SSmobs.clients_by_zlevel[test_z] = list(viewer)
	controller.set_ai_status(AI_STATUS_ON)
	viewer.update_z(null)
	var/town_status = controller.ai_status
	SSmobs.clients_by_zlevel[test_z] = old_clients
	SSmobs.town_z = old_town_z

	TEST_ASSERT(removed_client && removed_mob, "Logout must remove both registrations even without a client.")
	TEST_ASSERT_EQUAL(registrations, 1, "Repeated registration must not duplicate the mob.")
	TEST_ASSERT_EQUAL(empty_level_status, AI_STATUS_OFF, "An empty non-town level must stop AI processing.")
	TEST_ASSERT_NOTEQUAL(town_status, AI_STATUS_OFF, "An empty town must keep its local AI policy.")

/datum/unit_test/movement_glide_handles_slow_and_zero_delays
#ifdef FOCUS_MOVEMENT_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/movement_glide_handles_slow_and_zero_delays/Run()
	var/old_multiplier = GLOB.glide_size_multiplier
	GLOB.glide_size_multiplier = 1
	var/slow_glide = DELAY_TO_GLIDE_SIZE(20 * world.tick_lag)
	var/zero_glide = MOVEMENT_ADJUSTED_GLIDE_SIZE(0, 1)
	var/negative_glide = MOVEMENT_ADJUSTED_GLIDE_SIZE(-world.tick_lag, 1)
	var/diagonal_glide = MOVEMENT_ADJUSTED_GLIDE_SIZE(2 * world.tick_lag, sqrt(2))
	GLOB.glide_size_multiplier = 2
	var/dilated_glide = MOVEMENT_ADJUSTED_GLIDE_SIZE(4 * world.tick_lag, 1)
	GLOB.glide_size_multiplier = old_multiplier

	TEST_ASSERT_EQUAL(slow_glide, world.icon_size / 20, "Slow movement must not be clamped to four pixels.")
	TEST_ASSERT_EQUAL(zero_glide, world.icon_size, "Zero delay must still interpolate over one tick.")
	TEST_ASSERT_EQUAL(negative_glide, world.icon_size, "Negative slowdown must not reverse interpolation.")
	TEST_ASSERT(abs(diagonal_glide - world.icon_size * sqrt(2) / 2) < 0.001, "Diagonal interpolation must account for distance.")
	TEST_ASSERT_EQUAL(dilated_glide, world.icon_size / 2, "Keep the local time-dilation multiplier.")

/datum/unit_test/cardinal_move_keeps_diagonal_and_collision_behavior
#ifdef FOCUS_MOVEMENT_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/cardinal_move_keeps_diagonal_and_collision_behavior/Run()
	var/obj/item/item = allocate(/obj/item)
	var/turf/east = get_step(run_loc_floor_bottom_left, EAST)
	TEST_ASSERT(item.Move(east, EAST), "Cardinal movement should reach an open adjacent turf.")
	TEST_ASSERT_EQUAL(get_turf(item), east, "Cardinal movement should update loc.")
	var/turf/diagonal = get_step(east, NORTHEAST)
	item.Move(diagonal, NORTHEAST)
	TEST_ASSERT_EQUAL(get_turf(item), diagonal, "Diagonal movement must still complete both cardinal steps.")
	var/turf/blocked = get_step(diagonal, EAST)
	var/obj/structure/blocker = allocate(/obj/structure, blocked)
	blocker.density = TRUE
	TEST_ASSERT(!item.Move(blocked, EAST), "Renaming CardinalMove must not bypass collision checks.")
	TEST_ASSERT_EQUAL(get_turf(item), diagonal, "A blocked move must leave the item in place.")

/datum/unit_test/jump_landing_does_not_repeat_entered
	var/entries = 0
#ifdef FOCUS_MOVEMENT_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/jump_landing_does_not_repeat_entered/proc/on_entered(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(isliving(arrived))
		entries++

/datum/unit_test/jump_landing_does_not_repeat_entered/Run()
	var/mob/living/carbon/human/jumper = allocate(/mob/living/carbon/human)
	var/turf/landing = get_step(get_turf(jumper), EAST)
	RegisterSignal(landing, COMSIG_ATOM_ENTERED, PROC_REF(on_entered))
	jumper.jump_action_resolve(landing, 0, 1, FALSE)
	jumper.throwing?.finalize()
	UnregisterSignal(landing, COMSIG_ATOM_ENTERED)
	TEST_ASSERT_EQUAL(get_turf(jumper), landing, "The jump should reach its adjacent landing turf.")
	TEST_ASSERT_EQUAL(entries, 1, "Landing must not replay Entered and trigger turf interactions twice.")

	var/turf/next_turf = get_step(landing, NORTH)
	jumper.forceMove(next_turf)
	jumper.jump_extra_step(landing)
	TEST_ASSERT_EQUAL(get_turf(jumper), next_turf, "A delayed extra step must not move a mob that has already left its landing turf.")

/// Passability callbacks take the target turf, not a numeric direction.
/obj/structure/unit_test_passability_target
	density = TRUE

/obj/structure/unit_test_passability_target/CanPass(atom/movable/mover, turf/target)
	. = ..()
	return target == loc

/datum/unit_test/blocked_turf_passes_destination_to_contents
#ifdef FOCUS_MOVEMENT_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/blocked_turf_passes_destination_to_contents/Run()
	var/obj/item/mover = allocate(/obj/item)
	var/turf/destination = get_step(get_turf(mover), EAST)
	allocate(/obj/structure/unit_test_passability_target, destination)
	TEST_ASSERT(!destination.is_blocked_turf(source_atom = mover), "CanPass must receive the turf being checked.")
	TEST_ASSERT(is_blocked_turf(destination), "The compatibility helper should still detect dense contents without a mover.")
	TEST_ASSERT(is_blocked_turf(null), "The compatibility helper must treat missing destinations as blocked.")
