/*
			< ATTENTION >
	If you need to add more map_adjustment, check 'map_adjustment_include.dm'
	These 'map_adjustment.dm' files shouldn't be included in 'dme'
*/

/datum/map_adjustment/rivermist
	// Matched against the first file in _maps/hsector.json.
	map_file_name = "hsector_new.dmm"
	// The voyage jobs, from modular_rmh/code/modules/jobs/job_types/_voyage.
	blacklist = list(
		/datum/job/navigator,
		/datum/job/advclass/burgmeister/lord_captain,
		/datum/job/advclass/councilor/first_mate,
		/datum/job/advclass/town_scholar/ship_doctor,
		/datum/job/advclass/watch_guard/marine,
		/datum/job/advclass/towner/passenger,)
	// Limited positions to ensure core roles are filled.
	slot_adjust = null
