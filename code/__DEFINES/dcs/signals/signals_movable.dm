#define COMSIG_MOVABLE_BUCKLE "buckle"							//from base of atom/movable/buckle_mob(): (mob, force)
#define COMSIG_MOVABLE_UNBUCKLE "unbuckle"						//from base of atom/movable/unbuckle_mob(): (mob, force)

///from /obj/vehicle/proc/driver_move, caught by the riding component to check and execute the driver trying to drive the vehicle
#define COMSIG_RIDDEN_DRIVER_MOVE "driver_move"
	#define COMPONENT_DRIVER_BLOCK_MOVE (1<<0)

///from /atom/movable/proc/buckle_mob(): (mob/living/M, force, check_loc, buckle_mob_flags)
#define COMSIG_MOVABLE_PREBUCKLE "prebuckle" // this is the last chance to interrupt and block a buckle before it finishes
	#define COMPONENT_BLOCK_BUCKLE (1<<0)

#define COMSIG_MOB_OVERLAY_FORCE_REMOVE "mob_overlay_force_remove"
#define COMSIG_MOB_OVERLAY_FORCE_UPDATE "mob_overlay_force_update"
/// From base of /client/Move(): (new_loc, direction)
#define COMSIG_MOB_CLIENT_PRE_MOVE "mob_client_pre_move"
	/// Should always match COMPONENT_MOVABLE_BLOCK_PRE_MOVE as these are interchangeable and used to block movement.
	#define COMSIG_MOB_CLIENT_BLOCK_PRE_MOVE COMPONENT_MOVABLE_BLOCK_PRE_MOVE
	/// The argument of move_args which corresponds to the loc we're moving to
	#define MOVE_ARG_NEW_LOC 1
	/// The arugment of move_args which dictates our movement direction
	#define MOVE_ARG_DIRECTION 2
/// From base of /client/Move(): (direction, old_direction)
#define COMSIG_MOB_CLIENT_MOVED "mob_client_moved"

#define COMSIG_MOB_FOOD_EAT "mob_food_ate"

// /datum/element/movetype_handler signals
/// Called when the floating anim has to be temporarily stopped and restarted later: (timer)
#define COMSIG_PAUSE_FLOATING_ANIM "pause_floating_anim"
/// From base of datum/element/movetype_handler/on_movement_type_trait_gain: (flag, old_movement_type)
#define COMSIG_MOVETYPE_FLAG_ENABLED "movetype_flag_enabled"
/// From base of datum/element/movetype_handler/on_movement_type_trait_loss: (flag, old_movement_type)
#define COMSIG_MOVETYPE_FLAG_DISABLED "movetype_flag_disabled"

/// After the rider's buckle state changes: (atom/movable/seat).
#define COMSIG_MOB_BUCKLED "mob_buckle"
#define COMSIG_MOB_UNBUCKLED "mob_unbuckle"
/// From set_anchored(): (new_value).
#define COMSIG_MOVABLE_SET_ANCHORED "movable_set_anchored"
/// From set_density(): (new_value).
#define COMSIG_ATOM_DENSITY_CHANGED "atom_density_change"
/// From toggle_move_intent().
#define COMSIG_MOVE_INTENT_TOGGLED "move_intent_toggled"
/// Before starting a pull: (atom/movable/target, force).
#define COMSIG_LIVING_TRY_PULL "living_try_pull"
	#define COMSIG_LIVING_CANCEL_PULL (1<<0)
