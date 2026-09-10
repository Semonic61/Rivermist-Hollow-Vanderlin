// Hunting & Tracking pack - which ground holds a footprint.
//
// Reopening core turf types to add a var and set its default is a plain type extension, not a proc
// override, so this stays clear of the "RMH overrides silently win over core procs" hazard in
// ai_navigation/modular_guide.md.
//
// track_prob is the base percentage chance that a step leaves a track here. It stays 0 on every
// turf not listed below - masonry, tiling, indoor flooring - which is what keeps the movement hook
// cheap in town: check_track_creation() bails on the first check for the majority of the map.

/turf
	/// Base chance (0-100) that a living mob leaves a footprint when stepping onto this turf.
	var/track_prob = 0

// Soft ground - holds a print well.
/turf/open/floor/dirt
	track_prob = 25

/turf/open/floor/dirt/road
	track_prob = 25

/turf/open/floor/cracked_earth
	track_prob = 20

/turf/open/floor/snow
	track_prob = 35

/turf/open/floor/snow/rough
	track_prob = 25

/turf/open/floor/snow/patchy
	track_prob = 20

/turf/open/floor/sand
	track_prob = 30

/turf/open/floor/sand/desert
	track_prob = 30

// Vegetation - bent grass and broken stems rather than prints.
/turf/open/floor/grass
	track_prob = 20

/turf/open/floor/grass/healthy
	track_prob = 20

/turf/open/floor/grass/mixyel
	track_prob = 20

/turf/open/floor/grass/red
	track_prob = 20

/turf/open/floor/grass/yel
	track_prob = 20

/turf/open/floor/grass/cold
	track_prob = 20

// Hard-ish surfaces that still scuff, mostly indoors - deliberately low.
/turf/open/floor/twig
	track_prob = 10

/turf/open/floor/wood
	track_prob = 10

/turf/open/floor/woodturned
	track_prob = 10

/turf/open/floor/ruinedwood
	track_prob = 10

/turf/open/floor/hay
	track_prob = 12

/turf/open/floor/carpet
	track_prob = 15
