/decl/singularity_stage
	abstract_type = /decl/singularity_stage
	var/name = "gravitational singularity"
	var/desc = "A gravitational singularity."
	/// What is the effective physical size of this singularity?
	var/footprint = 1
	/// What is the numerical size of this singularity?
	var/stage_size = 0
	/// What is the minimum singularity energy to reach this sage?
	var/min_energy = -(INFINITY)
	/// What is the maximum singularity energy to stay at this sage?
	var/max_energy = 0
	/// What icon should the singularity use at this stage?
	var/icon
	/// What icon_state should the singularity use at this stage?
	var/icon_state
	/// What x offset should the singularity use at this stage?
	var/pixel_x = 0
	/// What y offset should the singularity use at this stage?
	var/pixel_y = 0
	/// What is the pull range of a singularity at this stage?
	var/grav_pull = 0
	/// What is the feeding range of a singularity at this stage?
	var/consume_range = 0
	/// If true, the singularity will lose energy in Process().
	var/dissipates_over_time = TRUE
	/// How many Process() ticks do we have between dissipations?
	var/ticks_between_dissipations = 10
	/// A counter variable for how many ticks we are along the dissipation.
	var/ticks_since_last_dissipation = 0
	/// How much energy do we lose when we dissipate?
	var/dissipation_energy_loss = 1
	/// What is the percent chance of an event each tick?
	var/event_chance = 0
	/// Do we force a specific event when we proc events?
	var/decl/singularity_event/forced_event = null
	/// Will we wander around?
	var/wander = FALSE
	/// Can explosions destroy the singularity?
	var/explosion_vulnerable = FALSE
	/// What is the heavy range for the EM pulse event in this stage?
	var/em_heavy_range = 8
	/// What is the light range for the EM pulse event in this stage?
	var/em_light_range = 10
	/// What do characters feel when they're mesmerized during this stage?
	var/mesmerize_text = "weak"
	/// Do we ignore PPE for mesmerizing in this stage?
	var/the_goggles_do_nothing = FALSE
	/// Do we ignore obstacles in our way?
	var/ignore_obstacles = FALSE

/decl/singularity_stage/validate()
	. = ..()
	if(consume_range < 0)
		. += "negative consume_range"
	if(grav_pull < 0)
		. += "negative grav_pull"
	else if(consume_range >= 0 && grav_pull < consume_range)
		. += "grav_pull is smaller than consume_range; consume_range will be truncated"
	if(min_energy > max_energy)
		. += "min_energy is larger than max_energy, stage will never be able to exist"

/decl/singularity_stage/proc/handle_dissipation(obj/effect/singularity/source)
	if(dissipates_over_time)
		if(ticks_since_last_dissipation >= ticks_between_dissipations)
			source.energy -= dissipation_energy_loss
			ticks_since_last_dissipation = 0
			return TRUE
		ticks_since_last_dissipation++
	return FALSE

/decl/singularity_stage/proc/grow_to(obj/effect/singularity/source)
	return

/decl/singularity_stage/proc/shrink_to(obj/effect/singularity/source)
	return

/decl/singularity_stage/proc/has_expansion_room(obj/effect/singularity/source)
	return TRUE

/decl/singularity_stage/stage_one
	stage_size = STAGE_ONE
	min_energy = -(INFINITY)
	max_energy = 200
	footprint = 1
	icon = 'icons/obj/singularity.dmi'
	icon_state = "singularity_s1"
	pixel_x = 0
	pixel_y = 0
	grav_pull = 4
	consume_range = 0
	ticks_between_dissipations = 10
	ticks_since_last_dissipation = 0
	dissipation_energy_loss = 1
	wander = FALSE
	event_chance = 0

/decl/singularity_stage/stage_one/shrink_to(obj/effect/singularity/source)
	source.visible_message(SPAN_NOTICE("\The [source] has shrunk to a rather pitiful size."))

/decl/singularity_stage/stage_two
	stage_size = STAGE_TWO
	min_energy = 200
	max_energy = 500
	footprint = 3
	icon = 'icons/effects/96x96.dmi'
	icon_state = "singularity_s3"
	pixel_x = -32
	pixel_y = -32
	grav_pull = 6
	consume_range = 1
	ticks_between_dissipations = 5
	ticks_since_last_dissipation = 0
	dissipation_energy_loss = 5
	wander = TRUE
	event_chance = 10

/decl/singularity_stage/stage_two/grow_to(obj/effect/singularity/source)
	source.visible_message(SPAN_NOTICE("\The [source] noticeably grows in size."))

/decl/singularity_stage/stage_two/shrink_to(obj/effect/singularity/source)
	source.visible_message(SPAN_NOTICE("\The [source] has shrunk to a less powerful size."))

/decl/singularity_stage/stage_three
	min_energy = 500
	max_energy = 1000
	stage_size = STAGE_THREE
	footprint = 3
	icon = 'icons/effects/160x160.dmi'
	icon_state = "singularity_s5"
	pixel_x = -64
	pixel_y = -64
	grav_pull = 8
	consume_range = 2
	ticks_between_dissipations = 4
	ticks_since_last_dissipation = 0
	dissipation_energy_loss = 20
	wander = TRUE
	event_chance = 10

/decl/singularity_stage/stage_three/has_expansion_room(obj/effect/singularity/source)
	return source.check_turfs_in(1, 2) && source.check_turfs_in(2, 2) && source.check_turfs_in(4, 2) && source.check_turfs_in(8, 2)

/decl/singularity_stage/stage_three/grow_to(obj/effect/singularity/source)
	source.visible_message(SPAN_NOTICE("\The [source] expands to a reasonable size."))

/decl/singularity_stage/stage_three/shrink_to(obj/effect/singularity/source)
	source.visible_message(SPAN_NOTICE("\The [source] has returned to a safe size."))

/decl/singularity_stage/stage_four
	min_energy = 1000
	max_energy = 2000
	stage_size = STAGE_FOUR
	footprint = 4
	icon = 'icons/effects/224x224.dmi'
	icon_state = "singularity_s7"
	pixel_x = -96
	pixel_y = -96
	grav_pull = 10
	consume_range = 3
	ticks_between_dissipations = 10
	ticks_since_last_dissipation = 0
	dissipation_energy_loss = 10
	wander = TRUE
	event_chance = 16

/decl/singularity_stage/stage_four/has_expansion_room(obj/effect/singularity/source)
	return source.check_turfs_in(1, 2) && source.check_turfs_in(2, 2) && source.check_turfs_in(4, 2) && source.check_turfs_in(8, 2)

/decl/singularity_stage/stage_four/grow_to(obj/effect/singularity/source)
	source.visible_message(SPAN_WARNING("\The [source] expands to a dangerous size."))

/decl/singularity_stage/stage_four/shrink_to(obj/effect/singularity/source)
	source.visible_message(SPAN_NOTICE("Miraculously, \the [source] reduces in size, and can be contained."))

/decl/singularity_stage/stage_five
	min_energy = 2000
	max_energy = 50000
	stage_size = STAGE_FIVE
	footprint = 5
	icon = 'icons/effects/288x288.dmi'
	icon_state = "singularity_s9"
	pixel_x = -128
	pixel_y = -128
	grav_pull = 10
	consume_range = 4
	dissipates_over_time = FALSE //It cant go smaller due to e loss.
	wander = TRUE
	event_chance = 20
	ignore_obstacles = TRUE

/decl/singularity_stage/stage_five/grow_to(obj/effect/singularity/source)
	source.visible_message(SPAN_DANGER("<font size='2'>\The [source] has grown out of control!</font>"))
