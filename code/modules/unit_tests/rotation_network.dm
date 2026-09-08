/obj/structure/rotation_network_test_node
	name = "rotation network test node"
	anchored = TRUE

/datum/unit_test/rotation_network_propagates_once_per_segment
#ifdef FOCUS_ROTATION_NETWORK_TESTS
	focus = TRUE
#endif

/datum/unit_test/rotation_network_propagates_once_per_segment/Run()
	var/turf/source_turf = run_loc_floor_bottom_left
	var/turf/output_turf = get_step(source_turf, EAST)
	var/obj/structure/rotation_network_test_node/source = allocate(/obj/structure/rotation_network_test_node, source_turf)
	var/obj/structure/rotation_network_test_node/output = allocate(/obj/structure/rotation_network_test_node, output_turf)

	source.dpdir = EAST
	source.stress_generator = TRUE
	source.rotation_direction = WEST
	source.rotations_per_minute = 12
	output.dpdir = WEST

	var/datum/rotation_network/network = new
	network.add_connection(source)
	network.add_connection(output)
	network.rebuild_group()

	TEST_ASSERT_EQUAL(output.rotation_direction, WEST, "A shaft-connected output should inherit the generator's direction.")
	TEST_ASSERT_EQUAL(output.rotations_per_minute, 12, "A shaft-connected output should inherit the generator's speed.")
	TEST_ASSERT_EQUAL(length(network.segments), 1, "A straight shaft connection should build one propagation segment.")
	TEST_ASSERT_EQUAL(source.try_network_merge(output), TRUE, "Rechecking an existing connection should be a harmless no-op, not a rotation conflict.")

	var/obj/structure/rotation_network_test_node/detached = allocate(/obj/structure/rotation_network_test_node, get_step(output_turf, EAST))
	var/datum/rotation_network/old_detached_network = new
	old_detached_network.add_connection(detached)
	TEST_ASSERT_EQUAL(source.try_network_merge(detached), TRUE, "Two compatible rotation networks should merge successfully.")
	TEST_ASSERT(QDELETED(old_detached_network), "Merging networks should retire the emptied network and its segment graph.")
	TEST_ASSERT_EQUAL(detached.rotation_network, network, "Every migrated node should belong to the surviving network.")

/datum/unit_test/rotation_network_splits_every_disconnected_component
#ifdef FOCUS_ROTATION_NETWORK_TESTS
	focus = TRUE
#endif

/datum/unit_test/rotation_network_splits_every_disconnected_component/Run()
	var/turf/center_turf = get_step(get_step(run_loc_floor_bottom_left, EAST), NORTH)
	var/obj/structure/rotation_network_test_node/center = allocate(/obj/structure/rotation_network_test_node, center_turf)
	var/obj/structure/rotation_network_test_node/north = allocate(/obj/structure/rotation_network_test_node, get_step(center_turf, NORTH))
	var/obj/structure/rotation_network_test_node/east = allocate(/obj/structure/rotation_network_test_node, get_step(center_turf, EAST))
	var/obj/structure/rotation_network_test_node/west = allocate(/obj/structure/rotation_network_test_node, get_step(center_turf, WEST))

	center.dpdir = NORTH | EAST | WEST
	north.dpdir = SOUTH
	east.dpdir = WEST
	west.dpdir = EAST

	var/datum/rotation_network/network = new
	network.add_connection(center)
	network.add_connection(north)
	network.add_connection(east)
	network.add_connection(west)

	network.remove_connection(center)
	network.reassess_group(center)

	var/list/distinct_networks = list()
	for(var/obj/structure/rotation_network_test_node/arm in list(north, east, west))
		TEST_ASSERT_NOTNULL(arm.rotation_network, "Every surviving arm should retain a rotation network.")
		distinct_networks[arm.rotation_network] = TRUE
		TEST_ASSERT_EQUAL(length(arm.rotation_network.connected), 1, "Disconnected arms must not keep sharing stress or rotation state.")

	TEST_ASSERT_EQUAL(length(distinct_networks), 3, "Removing a three-way junction should create three independent networks.")

/datum/unit_test/roller_topology_is_not_a_rotation_conflict
#ifdef FOCUS_ROTATION_NETWORK_TESTS
	focus = TRUE
#endif

/datum/unit_test/roller_topology_is_not_a_rotation_conflict/Run()
	var/turf/roller_turf = run_loc_floor_bottom_left
	var/obj/structure/roller/roller = allocate(/obj/structure/roller, roller_turf)
	var/obj/structure/rotation_network_test_node/shaft = allocate(/obj/structure/rotation_network_test_node, get_step(roller_turf, NORTH))
	roller.movedir = NORTH

	TEST_ASSERT_NULL(roller.can_connect(shaft), "A shaft in front of a roller is incompatible topology, not an opposing-power conflict.")

	roller.rotation_direction = EAST
	roller.rotations_per_minute = 8
	shaft.rotation_direction = WEST
	shaft.rotations_per_minute = 8
	TEST_ASSERT_EQUAL(roller.can_connect(shaft), FALSE, "Actually opposing powered directions should still report a destructive conflict.")
