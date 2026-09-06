/datum/quirk/vice/addiction/lovefiend
	name = "Nymphomaniac"
	desc = "I must make love!"
	time = 40 MINUTES
	needsate_text = "I'm so horny..."
	sated_text = "That's much better..."
	point_value = 3
	debuff = /datum/status_effect/debuff/addiction/lovefiend

/datum/quirk/vice/addiction/sadist
	name = "Sadist"
	desc = "There is no greater pleasure than the suffering of another."
	time = 2 HOURS
	needsate_text = "I need to hear someone whimper."
	sated_text = "That's much better..."
	point_value = 3
	debuff = /datum/status_effect/debuff/addiction/sadist

/datum/status_effect/debuff/addiction/lovefiend
	id = "addiction_lovefiend"
	alert_type = /atom/movable/screen/alert/status_effect/debuff/addiction/lovefiend

/atom/movable/screen/alert/status_effect/debuff/addiction/sadist
	name = "Sadistic Craving"
	desc = "I need to hear someone suffer."

/atom/movable/screen/alert/status_effect/debuff/addiction/lovefiend
	name = "Nymphomaniac Craving"
	desc = "I need intimacy."

// Hidden until existing saves have been migrated to the addiction subtype.
/datum/quirk/vice/lovefiend
	parent_type = /datum/quirk/vice/addiction/lovefiend
	abstract_type = /datum/quirk/vice/lovefiend
