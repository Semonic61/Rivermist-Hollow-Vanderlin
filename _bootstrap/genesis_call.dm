/**
 * Keep this as the FIRST include. On BYOND 516.1687, global-proc statics run
 * before datum/world proc statics; a sentinel on /world runs too late.
 * The global bridge is intentional. Actual startup work belongs in world.Genesis
 * or subsystem Initialize, not here. The startup unit test guards this ordering.
 */
/proc/initialize_world()
	world.Genesis()

/proc/early_world_init()
	var/static/bootstrap = initialize_world()
