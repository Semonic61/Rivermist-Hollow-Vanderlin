/datum/relation/family/spouse
	name = "Spouse"
	bond_type = "spouse"
	symmetric = TRUE
	upgrades = list(/datum/relation/acquaintance, /datum/relation/divorced)

/datum/relation/family/spouse/dissolve(record_divorce = TRUE)
	var/datum/mind/former_holder = holder
	var/datum/mind/former_other = other
	. = ..()
	// Create the records after the spouse bonds are gone, otherwise their
	// incompatibility checks correctly reject the divorced state.
	if(!record_divorce || !former_holder || !former_other)
		return
	var/datum/relation/divorced/holder_record = former_holder.add_relation(former_other, /datum/relation/divorced)
	if(holder_record)
		holder_record.refresh_snapshot()
	var/datum/relation/divorced/other_record = former_other.add_relation(former_holder, /datum/relation/divorced)
	if(other_record)
		other_record.refresh_snapshot()
