/datum/relation/ex
	name = "Ex"
	desc = "You were once romantically involved, but not anymore."
	category = "Former Partner"

/datum/relation/ex/get_desc_string()
	return "[holder?.name] and [other?.name] used to be an item, but not anymore."
