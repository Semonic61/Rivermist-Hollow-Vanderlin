/datum/component/riding/creature/terrorbird/get_rider_offsets_and_layers(pass_index, mob/offsetter)
	// Four pixels above a saiga's saddle, clear of the bird's head and neck.
	return list(
		TEXT_NORTH = list(0, 12, MOB_LAYER),
		TEXT_SOUTH = list(0, 12, MOB_LAYER),
		TEXT_EAST = list(-2, 12, MOB_LAYER),
		TEXT_WEST = list(2, 12, MOB_LAYER),
	)

/datum/component/riding/creature/terrorbird/get_parent_offsets_and_layers()
	return list(
		TEXT_NORTH = list(0, 0, OBJ_LAYER),
		TEXT_SOUTH = list(0, 0, ABOVE_MOB_LAYER),
		TEXT_EAST = list(0, 0, OBJ_LAYER),
		TEXT_WEST = list(0, 0, OBJ_LAYER),
	)
