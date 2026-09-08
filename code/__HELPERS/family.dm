/// Returns the configured job titles for an RMH job category key.
/proc/job_group_list(group_key)
	switch(group_key)
		if("lords")
			return GLOB.lords_positions
		if("keep")
			return GLOB.keep_positions
		if("townhall")
			return GLOB.townhall_positions
		if("townwatch")
			return GLOB.townwatch_positions
		if("chapel")
			return GLOB.chapel_positions
		if("scholars")
			return GLOB.scholars_positions
		if("traders")
			return GLOB.traders_positions
		if("tavern")
			return GLOB.tavern_positions
		if("town")
			return GLOB.town_positions
		if("outsiders")
			return GLOB.outsiders_positions
		if("adventurers")
			return GLOB.adventurers_positions
		if("villains")
			return GLOB.villains_positions
	return list()

/// Human-readable category used to group jobs in the relations UI.
/proc/get_job_category(title)
	if(!title)
		return "Unknown"
	if(title in GLOB.lords_positions)
		return "Lords"
	if(title in GLOB.keep_positions)
		return "The Keep"
	if(title in GLOB.townhall_positions)
		return "Town Hall"
	if(title in GLOB.townwatch_positions)
		return "Town Watch"
	if(title in GLOB.chapel_positions)
		return "Chapel"
	if(title in GLOB.scholars_positions)
		return "Scholars"
	if(title in GLOB.traders_positions)
		return "Traders"
	if(title in GLOB.tavern_positions)
		return "Tavern"
	if(title in GLOB.town_positions)
		return "Towners"
	if(title in GLOB.outsiders_positions)
		return "Outsiders"
	if(title in GLOB.adventurers_positions)
		return "Adventurers"
	if(title in GLOB.villains_positions)
		return "Villains"
	return "Other"

/// Converts an RMH department bitfield into a grudge-pool category.
/proc/dept_flag_to_key(department_flag)
	if(department_flag & LORDS)
		return "lords"
	if(department_flag & KEEP)
		return "keep"
	if(department_flag & TOWNHALL)
		return "townhall"
	if(department_flag & TOWNWATCH)
		return "townwatch"
	if(department_flag & CHAPEL)
		return "chapel"
	if(department_flag & SCHOLARS)
		return "scholars"
	if(department_flag & TRADERS)
		return "traders"
	if(department_flag & TAVERN)
		return "tavern"
	if(department_flag & TOWN)
		return "town"
	if(department_flag & OUTSIDERS)
		return "outsiders"
	if(department_flag & ADVENTURERS)
		return "adventurers"
	if(department_flag & VILLAINS)
		return "villains"
	return null

/// Mirrors a direct family bond into the social relations system.
/proc/link_family(datum/mind/mind_a, datum/mind/mind_b, bond, adopted = FALSE, in_law = FALSE)
	if(!mind_a || !mind_b || mind_a == mind_b)
		return null

	for(var/datum/relation/family/existing in mind_a.relations)
		if(existing.other == mind_b && existing.bond_type == bond)
			existing.adopted = adopted
			existing.in_law = in_law
			existing.refresh_snapshot()
			existing.update_text()
			return existing

	var/relation_type = bond == FAMILY_MEMBER_SPOUSE ? /datum/relation/family/spouse : /datum/relation/family
	var/datum/relation/family/relation = mind_a.add_relation(mind_b, relation_type)
	if(!relation)
		return null

	relation.bond_type = bond
	relation.adopted = adopted
	relation.in_law = in_law
	relation.refresh_snapshot()
	relation.update_text()
	return relation

/// Mirrors both directed sides of a parent/child family bond.
/proc/link_parent_child(datum/mind/parent, datum/mind/child, adopted = FALSE)
	link_family(parent, child, FAMILY_MEMBER_PARENT, adopted)
	link_family(child, parent, FAMILY_MEMBER_CHILD, adopted)

/// Removes one directed family relation without disturbing unrelated bonds.
/proc/unlink_family(datum/mind/mind_a, datum/mind/mind_b, bond, record_divorce = FALSE)
	if(!mind_a || !mind_b)
		return
	var/list/to_remove = list()
	for(var/datum/relation/family/relation in mind_a.relations)
		if(relation.other == mind_b && relation.bond_type == bond)
			to_remove += relation
	for(var/datum/relation/family/relation in to_remove)
		relation.dissolve(record_divorce)
