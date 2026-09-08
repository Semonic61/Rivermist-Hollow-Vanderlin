/datum/unit_test/buckling_port_factions
#ifdef FOCUS_BUCKLING_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/buckling_port_factions/Run()
	var/mob/living/carbon/human/first = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/second = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/friend = allocate(/mob/living/carbon/human)
	var/list/source_factions = list("port_test")
	first.set_faction(source_factions)
	second.set_faction(list("port_test"))
	source_factions += "caller_mutation"
	TEST_ASSERT(!first.has_faction("caller_mutation"), "A caller mutated cached factions.")
	TEST_ASSERT_EQUAL(first.get_faction(), second.get_faction(), "Equal static factions should reuse their cache.")
	first.add_faction("first_only")
	TEST_ASSERT(!second.has_faction("first_only"), "Changing one mob changed another mob's factions.")
	TEST_ASSERT(!first.faction_check_atom(second, TRUE), "An exact match accepted a subset.")
	first.remove_faction("first_only")
	TEST_ASSERT(first.faction_check_atom(second, TRUE), "Own reference strings broke exact faction matching.")
	first.set_faction(list("a-b", "c"))
	second.set_faction(list("a", "b-c"))
	TEST_ASSERT(!first.faction_check_atom(second), "Delimited cache keys aliased different faction names.")
	first.befriend(friend)
	TEST_ASSERT(first.faction_check_atom(friend), "Dynamic friendship did not make a mob an ally.")
	TEST_ASSERT(first.has_faction_or_allies(null, list(REF(friend))), "Allies-only queries failed.")
	TEST_ASSERT(!first.has_ally(list(REF(friend), "missing"), TRUE), "A match-all query accepted a missing ally.")
	first.unfriend(friend)
	TEST_ASSERT(!first.has_ally(friend), "Unfriending left an ally behind.")

/datum/unit_test/buckling_port_carry_cleanup
#ifdef FOCUS_BUCKLING_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/buckling_port_carry_cleanup/Run()
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human)
	TEST_ASSERT(carrier.buckle_mob(rider, TRUE, TRUE, RIDER_NEEDS_ARMS), "Piggyback mounting failed.")
	TEST_ASSERT(HAS_TRAIT(rider, TRAIT_UNDENSE), "Piggyback rider was not made non-dense.")
	TEST_ASSERT(!rider.density, "Piggyback rider remained dense.")
	TEST_ASSERT(!rider.updating_glide_size, "Rider did not inherit carrier glide.")
	TEST_ASSERT(!(locate(/obj/item/riding_offhand) in rider.held_items), "Piggyback unexpectedly reserved hands.")
	carrier.unbuckle_mob(rider, TRUE)
	TEST_ASSERT(!HAS_TRAIT(rider, TRAIT_UNDENSE), "Dismount leaked non-density.")
	TEST_ASSERT(rider.updating_glide_size, "Dismount did not restore independent glide.")
	TEST_ASSERT_NULL(rider.mob_offsets["riding"], "Dismount leaked riding offsets.")
	TEST_ASSERT_NULL(carrier.GetComponent(/datum/component/riding), "The last rider left a component behind.")
	TEST_ASSERT(carrier.buckle_mob(rider, TRUE, TRUE, CARRIER_NEEDS_ARM), "Fireman mounting failed.")
	TEST_ASSERT_EQUAL(rider.lying_angle, 90, "Fireman carry did not rotate the passenger.")
	carrier.unbuckle_mob(rider, TRUE)
	TEST_ASSERT(carrier.buckle_mob(rider, TRUE, TRUE, RIDER_NEEDS_ARMS), "Remount failed.")
	TEST_ASSERT_EQUAL(rider.lying_angle, 0, "A remount retained the previous fireman angle.")

/datum/unit_test/buckling_port_blocked_mount
#ifdef FOCUS_BUCKLING_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/buckling_port_blocked_mount/proc/block_buckle()
	SIGNAL_HANDLER
	return COMPONENT_BLOCK_BUCKLE

/datum/unit_test/buckling_port_blocked_mount/Run()
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human)
	var/old_slowdown = carrier.total_multiplicative_slowdown()
	RegisterSignal(carrier, COMSIG_MOVABLE_PREBUCKLE, PROC_REF(block_buckle))
	var/succeeded = carrier.buckle_mob(rider, TRUE, TRUE, RIDER_NEEDS_ARMS)
	UnregisterSignal(carrier, COMSIG_MOVABLE_PREBUCKLE)
	TEST_ASSERT(!succeeded, "A blocked mount succeeded.")
	TEST_ASSERT_NULL(rider.buckled, "A blocked mount left the passenger buckled.")
	TEST_ASSERT_NULL(carrier.GetComponent(/datum/component/riding), "A blocked mount leaked its component.")
	TEST_ASSERT(!HAS_TRAIT(rider, TRAIT_UNDENSE), "A blocked mount leaked non-density.")
	TEST_ASSERT_EQUAL(carrier.total_multiplicative_slowdown(), old_slowdown, "A blocked mount slowed the carrier.")
	var/mob/living/simple_animal/hostile/retaliate/saiga/horse/tame/mount = allocate(/mob/living/simple_animal/hostile/retaliate/saiga/horse/tame)
	RegisterSignal(mount, COMSIG_MOVABLE_PREBUCKLE, PROC_REF(block_buckle))
	succeeded = mount.buckle_mob(rider, TRUE)
	UnregisterSignal(mount, COMSIG_MOVABLE_PREBUCKLE)
	TEST_ASSERT(!succeeded, "A blocked animal mount succeeded.")
	TEST_ASSERT_NULL(mount.GetComponent(/datum/component/riding), "A failed animal mount recreated the legacy riding component.")
	TEST_ASSERT(mount.ai_controller.able_to_run, "A failed mount left the animal's AI paused.")
	var/mob/living/simple_animal/unrideable = allocate(/mob/living/simple_animal)
	TEST_ASSERT(!unrideable.buckle_mob(rider), "An unrideable animal accepted a rider.")
	TEST_ASSERT_NULL(unrideable.GetComponent(/datum/component/riding), "An unrideable animal gained a riding component.")

/datum/unit_test/buckling_port_failed_move
#ifdef FOCUS_BUCKLING_PORT_TESTS
	focus = TRUE
#endif

/mob/living/carbon/human/buckling_test_blocked/Move()
	return FALSE

/datum/unit_test/buckling_port_failed_move/Run()
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human/buckling_test_blocked, get_step(run_loc_floor_bottom_left, EAST))
	TEST_ASSERT(!carrier.buckle_mob(rider, TRUE, FALSE, CARRIER_NEEDS_ARM), "A failed step completed a buckle.")
	TEST_ASSERT_NULL(rider.buckled, "A failed step leaked buckled state.")
	TEST_ASSERT(!carrier.has_buckled_mobs(), "A failed step leaked the passenger list.")
	TEST_ASSERT_NULL(carrier.GetComponent(/datum/component/riding), "A failed step leaked the component.")
	TEST_ASSERT(!HAS_TRAIT(rider, TRAIT_IMMOBILIZED), "A failed step leaked buckle immobilization.")

/datum/unit_test/buckling_port_component_deleted
#ifdef FOCUS_BUCKLING_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/buckling_port_component_deleted/Run()
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human)
	TEST_ASSERT(carrier.buckle_mob(rider, TRUE, TRUE, RIDER_NEEDS_ARMS), "Mounting failed.")
	qdel(carrier.GetComponent(/datum/component/riding))
	TEST_ASSERT_NULL(rider.buckled, "Deleting the component stranded its passenger.")
	TEST_ASSERT(!HAS_TRAIT(rider, TRAIT_UNDENSE), "Deleting the component leaked non-density.")
	TEST_ASSERT_NULL(rider.mob_offsets["riding"], "Deleting the component leaked offsets.")

/datum/unit_test/buckling_port_custom_passenger
#ifdef FOCUS_BUCKLING_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/buckling_port_custom_passenger/Run()
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/custom_passenger = allocate(/mob/living/carbon/human)
	carrier.max_buckled_mobs = 2
	TEST_ASSERT(carrier.buckle_mob(rider, TRUE, TRUE, RIDER_NEEDS_ARMS), "Normal rider could not mount.")
	ADD_TRAIT(custom_passenger, TRAIT_CANT_RIDE, TRAIT_GENERIC)
	TEST_ASSERT(carrier.buckle_mob(custom_passenger, TRUE), "Custom passenger could not buckle.")
	custom_passenger.set_mob_offsets("test_custom", _x = 10, _y = -5)
	carrier.setDir(EAST)
	var/datum/component/riding/riding = carrier.GetComponent(/datum/component/riding)
	TEST_ASSERT_EQUAL(length(riding.riders), 1, "The riding component adopted a harness passenger.")
	TEST_ASSERT_NULL(custom_passenger.mob_offsets["riding"], "Riding offsets overrode the custom passenger.")
	carrier.unbuckle_mob(rider, TRUE)
	TEST_ASSERT(QDELETED(riding), "A harness passenger kept normal riding alive.")
	TEST_ASSERT_EQUAL(custom_passenger.buckled, carrier, "Dismounting a rider removed the harness passenger.")
	TEST_ASSERT_NOTNULL(custom_passenger.mob_offsets["test_custom"], "Dismount cleanup erased custom offsets.")

/datum/unit_test/buckling_port_ai_pause
#ifdef FOCUS_BUCKLING_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/buckling_port_ai_pause/Run()
	var/mob/living/simple_animal/hostile/retaliate/saiga/horse/tame/mount = allocate(/mob/living/simple_animal/hostile/retaliate/saiga/horse/tame)
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human)
	var/datum/ai_controller/controller = mount.ai_controller
	TEST_ASSERT_NOTNULL(controller, "The mount needs an AI controller.")
	TEST_ASSERT(controller.able_to_run, "An unpaused AI must be runnable.")
	var/datum/move_loop/loop = SSmove_manager.move_towards(mount, run_loc_floor_top_right, delay = 10)
	TEST_ASSERT_NOTNULL(loop, "The move loop did not start.")
	TEST_ASSERT(mount.buckle_mob(rider, TRUE), "Mounting failed.")
	TEST_ASSERT(!controller.able_to_run, "Mounted AI continued planning.")
	TEST_ASSERT(!controller.can_move(), "Mounted AI could still move.")
	TEST_ASSERT(QDELETED(loop), "Mounting did not stop an existing move loop.")
	ADD_TRAIT(mount, TRAIT_AI_PAUSED, "test_other_pause")
	mount.unbuckle_mob(rider, TRUE)
	TEST_ASSERT(!controller.able_to_run, "Dismount cleared someone else's pause.")
	REMOVE_TRAIT(mount, TRAIT_AI_PAUSED, "test_other_pause")
	TEST_ASSERT(controller.able_to_run, "AI did not become runnable after the last pause ended.")
	ADD_TRAIT(mount, TRAIT_AI_MOVEMENT_HALTED, "test_movement_pause")
	TEST_ASSERT(controller.able_to_run && !controller.can_move(), "Movement-only pause also disabled planning.")
	var/datum/idle_behavior/idle_random_walk/idle_walk = allocate(/datum/idle_behavior/idle_random_walk)
	idle_walk.walk_chance = 100
	var/old_location = mount.loc
	idle_walk.perform_idle_behavior(1, controller)
	TEST_ASSERT_EQUAL(mount.loc, old_location, "Idle wandering bypassed the movement-only pause.")
	REMOVE_TRAIT(mount, TRAIT_AI_MOVEMENT_HALTED, "test_movement_pause")
	controller.PauseAi(2)
	TEST_ASSERT(!controller.able_to_run, "Timed pause did not stop AI.")
	sleep(3)
	TEST_ASSERT(controller.able_to_run, "Timed pause did not expire.")

/datum/unit_test/buckling_port_mount_upkeep
#ifdef FOCUS_BUCKLING_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/buckling_port_mount_upkeep/Run()
	var/mob/living/simple_animal/hostile/retaliate/saiga/horse/tame/mount = allocate(/mob/living/simple_animal/hostile/retaliate/saiga/horse/tame)
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human)
	TEST_ASSERT(mount.buckle_mob(rider, TRUE), "Mounting failed.")
	var/datum/component/generic_mob_hunger/fuel = mount.GetComponent(/datum/component/generic_mob_hunger)
	TEST_ASSERT_NOTNULL(fuel, "The horse lost its hunger component.")
	fuel.current_hunger = fuel.max_hunger * 0.1
	var/old_hunger = fuel.current_hunger
	rider.m_intent = MOVE_INTENT_WALK
	TEST_ASSERT(mount.relaydrive(rider, EAST), "The rider could not move the horse.")
	TEST_ASSERT_EQUAL(fuel.current_hunger, old_hunger - mount.ride_hunger_cost, "A ridden tile did not consume exactly one upkeep payment.")
	var/datum/component/riding/riding = mount.GetComponent(/datum/component/riding)
	TEST_ASSERT(COOLDOWN_TIMELEFT(riding, vehicle_move_cooldown) >= MOUNT_TIRED_SLOWDOWN, "Riding skill negated the tired mount slowdown.")
	old_hunger = fuel.current_hunger
	TEST_ASSERT(!mount.relaydrive(rider, EAST), "A move bypassed its cooldown.")
	TEST_ASSERT_EQUAL(fuel.current_hunger, old_hunger, "A rejected move consumed feed.")

/datum/unit_test/buckling_port_special_carry
#ifdef FOCUS_BUCKLING_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/buckling_port_special_carry/Run()
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human)
	var/mob/living/simple_animal/hostile/retaliate/chicken/chicken = allocate(/mob/living/simple_animal/hostile/retaliate/chicken)
	var/matrix/chicken_transform = matrix(chicken.transform)
	TEST_ASSERT(carrier.can_be_firemanned(chicken), "A chicken lost its fireman-carry flag.")
	TEST_ASSERT(carrier.buckle_mob(chicken, TRUE, TRUE, CARRIER_NEEDS_ARM), "Could not carry a chicken.")
	TEST_ASSERT_EQUAL(chicken.lying_angle, 90, "The carried animal did not lie across the shoulder.")
	var/matrix/carried_transform = chicken.transform
	TEST_ASSERT_NOTEQUAL(carried_transform.a, chicken_transform.a, "The animal changed lying_angle but its sprite stayed upright.")
	carrier.unbuckle_mob(chicken, TRUE)
	carried_transform = chicken.transform
	TEST_ASSERT_EQUAL(carried_transform.a, chicken_transform.a, "The animal kept its carry rotation after dismount.")
	TEST_ASSERT_EQUAL(carried_transform.b, chicken_transform.b, "The animal kept its carry rotation after dismount.")
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human)
	ADD_TRAIT(carrier, TRAIT_PONYGIRL_RIDEABLE, TRAIT_GENERIC)
	TEST_ASSERT(carrier.buckle_mob(rider), "Pony equipment no longer allowed mounting.")
	var/datum/component/riding/creature/riding = carrier.GetComponent(/datum/component/riding/creature)
	TEST_ASSERT(riding.can_be_driven, "Pony equipment lost rider steering.")
	TEST_ASSERT(carrier.relaymove(rider, EAST), "Pony rider could not steer.")
	TEST_ASSERT_EQUAL(carrier.loc, get_step(run_loc_floor_bottom_left, EAST), "Pony did not move.")

/datum/unit_test/buckling_port_ai_transfer
#ifdef FOCUS_BUCKLING_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/buckling_port_ai_transfer/Run()
	var/mob/living/simple_animal/hostile/first = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/simple_animal/hostile/second = allocate(/mob/living/simple_animal/hostile)
	var/datum/ai_controller/controller = first.ai_controller
	if(!controller)
		controller = allocate(/datum/ai_controller, first)
	controller.set_movement_target(type, second)
	ADD_TRAIT(first, TRAIT_AI_PAUSED, "old_pawn")
	controller.PossessPawn(second)
	TEST_ASSERT_NULL(first.ai_controller, "The old pawn kept its controller.")
	TEST_ASSERT_NULL(controller.current_movement_target, "Possession kept the old movement target.")
	TEST_ASSERT(controller.able_to_run, "The old pawn's pause followed the controller.")
	REMOVE_TRAIT(first, TRAIT_AI_PAUSED, "old_pawn")
	ADD_TRAIT(first, TRAIT_AI_PAUSED, "old_pawn")
	TEST_ASSERT(controller.able_to_run, "The controller still listened to the old pawn.")
	ADD_TRAIT(second, TRAIT_AI_PAUSED, "new_pawn")
	TEST_ASSERT(!controller.able_to_run, "The controller did not listen to the new pawn.")
	controller.UnpossessPawn(FALSE)
	TEST_ASSERT_NULL(controller.our_cells, "Unpossession kept the watched cells.")
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_OFF, "Unpossessed AI stayed active.")
	qdel(controller)

/datum/unit_test/buckling_port_custom_mounts
#ifdef FOCUS_BUCKLING_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/buckling_port_custom_mounts/Run()
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human)
	var/mob/living/simple_animal/hostile/retaliate/saiga/horse/kid/foal = allocate(/mob/living/simple_animal/hostile/retaliate/saiga/horse/kid)
	foal.tamed(rider)
	TEST_ASSERT(!foal.can_buckle, "Taming made a foal rideable.")
	var/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird/bird = allocate(/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird)
	bird.tamed(rider)
	TEST_ASSERT(bird.buckle_mob(rider, TRUE), "Could not mount the terrorbird.")
	TEST_ASSERT_NOTNULL(bird.GetComponent(/datum/component/riding/creature/terrorbird), "Terrorbird used saiga riding offsets.")
	bird.unbuckle_mob(rider, TRUE)
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human)
	var/obj/item/bodypart/taur/jdeer/taur = allocate(/obj/item/bodypart/taur/jdeer)
	// Normal character setup supplies these colors before attaching the limb.
	taur.taur_color = COLOR_WHITE
	taur.taur_markings = COLOR_WHITE
	taur.taur_tertiary = COLOR_WHITE
	taur.attach_limb(carrier, TRUE)
	TEST_ASSERT_EQUAL(carrier.get_bodypart(BODY_ZONE_TAUR), taur, "Could not attach the test taur bodypart.")
	TEST_ASSERT(carrier.buckle_mob(rider, TRUE), "Could not mount the Jdeer carrier.")
	TEST_ASSERT_EQUAL(rider.mob_offsets["jdeer_rider"]["y"], 16, "Jdeer passenger lost its extra height.")
	carrier.setDir(NORTH)
	carrier.setDir(SOUTH)
	TEST_ASSERT_EQUAL(rider.mob_offsets["jdeer_rider"]["y"], 16, "Jdeer passenger height accumulated when turning.")
	carrier.unbuckle_mob(rider, TRUE)
	TEST_ASSERT_NULL(rider.mob_offsets["jdeer_rider"], "Jdeer height remained after dismount.")

/datum/unit_test/buckling_port_taming
#ifdef FOCUS_BUCKLING_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/buckling_port_taming/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/mob/living/simple_animal/hostile/retaliate/goat/goat = allocate(/mob/living/simple_animal/hostile/retaliate/goat)
	var/obj/item/reagent_containers/food/snacks/produce/grain/wheat/food = allocate(/obj/item/reagent_containers/food/snacks/produce/grain/wheat)
	goat.befriend(user)
	goat.tame_chance = 100
	TEST_ASSERT(goat.attempt_feed(food, user), "Could not feed a goat.")
	TEST_ASSERT(goat.tame, "A befriended but wild animal could no longer be tamed.")
	TEST_ASSERT(QDELETED(food), "Hand feeding did not consume food.")
	var/mob/living/simple_animal/untameable = allocate(/mob/living/simple_animal)
	untameable.tame_chance = 0
	TEST_ASSERT(!untameable.try_tame(user), "Zero-chance untameable animals became tameable.")
	TEST_ASSERT(!untameable.tame, "Untameable animal became tame.")

/datum/unit_test/buckling_port_alert_appearance
#ifdef FOCUS_BUCKLING_PORT_TESTS
	focus = TRUE
#endif

/datum/unit_test/buckling_port_alert_appearance/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/master = allocate(/obj/item)
	master.pixel_x = 20
	var/original_plane = master.plane
	var/atom/movable/screen/alert/alert = user.throw_alert("port_test", /atom/movable/screen/alert, new_master = master)
	TEST_ASSERT_NOTNULL(alert, "The master-based alert was not created.")
	var/mutable_appearance/appearance_copy = alert.add_atom_icon(master)
	TEST_ASSERT_EQUAL(appearance_copy.pixel_x, master.base_pixel_x, "Alert inherited the master's transient offset.")
	TEST_ASSERT_EQUAL(master.plane, original_plane, "Building an alert changed the master's plane.")
	master.color = COLOR_RED
	master.update_appearance(UPDATE_OVERLAYS)
	var/mutable_appearance/master_overlay = alert.managed_overlays
	TEST_ASSERT_EQUAL(master_overlay.color, master.color, "Master appearance updates did not refresh the alert.")
	user.clear_alert("port_test")
	TEST_ASSERT(QDELETED(alert), "Clearing an alert left it alive.")

/datum/unit_test/buckling_port_door_redirect
#ifdef FOCUS_BUCKLING_PORT_TESTS
	focus = TRUE
#endif
	var/redirected_clicks = 0

/datum/unit_test/buckling_port_door_redirect/proc/record_click()
	SIGNAL_HANDLER
	redirected_clicks++
	return COMPONENT_CANCEL_ATTACK_CHAIN

/datum/unit_test/buckling_port_door_redirect/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/structure/door/door = allocate(/obj/structure/door)
	RegisterSignal(door, COMSIG_ATOM_ATTACK_HAND, PROC_REF(record_click))
	var/turf/old_turf = get_turf(door)
	var/turf/new_turf = get_step(old_turf, EAST)
	TEST_ASSERT(SEND_SIGNAL(old_turf, COMSIG_ATOM_ATTACK_HAND, user, list()) & COMPONENT_CANCEL_ATTACK_CHAIN, "Floor clicks did not reach the door.")
	sleep(1) // Let the redirected unarmed attack finish before moving or deleting its target.
	TEST_ASSERT_EQUAL(redirected_clicks, 1, "The redirected click did not reach the door's attack_hand.")
	door.forceMove(new_turf)
	TEST_ASSERT(!(SEND_SIGNAL(old_turf, COMSIG_ATOM_ATTACK_HAND, user, list()) & COMPONENT_CANCEL_ATTACK_CHAIN), "Moving the door left a click listener on the old turf.")
	TEST_ASSERT(SEND_SIGNAL(new_turf, COMSIG_ATOM_ATTACK_HAND, user, list()) & COMPONENT_CANCEL_ATTACK_CHAIN, "The moved door did not listen on its new turf.")
	sleep(1)
	TEST_ASSERT_EQUAL(redirected_clicks, 2, "Moving the door lost or duplicated its redirected attack.")
	qdel(door)
	TEST_ASSERT(!(SEND_SIGNAL(new_turf, COMSIG_ATOM_ATTACK_HAND, user, list()) & COMPONENT_CANCEL_ATTACK_CHAIN), "Deleting the door left a click listener behind.")
