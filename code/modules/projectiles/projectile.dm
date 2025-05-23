//Amount of time in deciseconds to wait before deleting all drawn segments of a projectile.
#define SEGMENT_DELETION_DELAY 5
#define MUZZLE_EFFECT_PIXEL_INCREMENT 16
/obj/item/projectile
	name = "projectile"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "bullet"
	density = TRUE
	anchored = TRUE //There's a reason this is here, Mport. God fucking damn it -Agouri. Find&Fix by Pete. The reason this is here is to stop the curving of emitter shots.
	pass_flags = PASS_FLAG_TABLE
	mouse_opacity = MOUSE_OPACITY_UNCLICKABLE
	randpixel = 0
	material = null
	is_spawnable_type = FALSE
	atom_damage_type = BRUTE //BRUTE, BURN, TOX, OXY, CLONE, ELECTROCUTE are the only things that should be in here, Try not to use PAIN as it doesn't go through stun_effect_act

	// Code for handling tails, if any.
	/// If the projectile leaves a trail.
	var/proj_trail = FALSE
	/// How long the trail lasts.
	var/proj_trail_lifespan = 0
	/// What icon to use for the projectile trail.
	var/proj_trail_icon = 'icons/effects/projectiles/trail.dmi'
	/// What icon_state to use for the projectile trail.
	var/proj_trail_icon_state = "trail"
	/// Any extant trail effects.
	var/list/proj_trails

	var/bumped = 0		//Prevents it from hitting more than one guy at once
	var/def_zone = ""	//Aiming at
	var/atom/movable/firer = null//Who shot it
	var/silenced = 0	//Attack message
	var/yo = null
	var/xo = null
	var/current = null
	var/shot_from = "" // name of the object which shot us
	var/atom/original = null // the target clicked (not necessarily where the projectile is headed). Should probably be renamed to 'target' or something.
	var/turf/starting = null // the projectile's starting turf
	var/list/permutated = list() // we've passed through these atoms, don't try to hit them again

	var/p_x = 16
	var/p_y = 16 // the pixel location of the tile that the player clicked. Default is the center

	var/hitchance_mod = 0
	var/dispersion = 0.0
	var/distance_falloff = 2  //multiplier, higher value means accuracy drops faster with distance

	var/damage = 10
	var/nodamage = 0 //Determines if the projectile will skip any damage inflictions
	var/damage_flags = DAM_BULLET
	var/penetrating = 0 //If greater than zero, the projectile will pass through dense objects as specified by on_penetrate()
	var/life_span //If non-null, this will de-increment every after_move(). When 0, it will delete the projectile.
		//Effects
	var/stun = 0
	var/weaken = 0
	var/paralyze = 0
	var/irradiate = 0
	var/stutter = 0
	var/eyeblur = 0
	var/drowsy = 0
	var/agony = 0

	var/embed = 0 // whether or not the projectile can embed itself in the mob
	var/space_knockback = 0	//whether or not it will knock things back in space
	var/penetration_modifier = 0.2 //How much internal damage this projectile can deal, as a multiplier.

	var/step_delay = 1	// the delay between iterations if not a hitscan projectile

	// effect types to be used
	var/muzzle_type
	var/tracer_type
	var/impact_type

	var/fire_sound
	var/fire_sound_vol = 50
	var/miss_sounds
	var/ricochet_sounds
	var/list/impact_sounds	//for different categories, IMPACT_MEAT etc
	var/shrapnel_type = /obj/item/shard/shrapnel

	var/vacuum_traversal = 1 //Determines if the projectile can exist in vacuum, if false, the projectile will be deleted if it enters vacuum.
//Movement parameters
	var/speed = 0.4		//Amount of deciseconds it takes for projectile to travel
	var/pixel_speed = 33	//pixels per move - DO NOT FUCK WITH THIS UNLESS YOU ABSOLUTELY KNOW WHAT YOU ARE DOING OR UNEXPECTED THINGS /WILL/ HAPPEN!
	var/Angle = 0
	var/original_Angle = 0		//Angle at firing
	var/nondirectional_sprite = FALSE //Set TRUE to prevent projectiles from having their sprites rotated based on firing Angle
	var/forcedodge = FALSE		//to pass through everything

	//Fired processing vars
	var/fired = FALSE	//Have we been fired yet
	var/paused = FALSE	//for suspending the projectile midair
	var/last_projectile_move = 0
	var/last_process = 0
	var/time_offset = 0
	var/datum/point/vector/trajectory
	var/trajectory_ignore_forcemove = FALSE	//instructs forceMove to NOT reset our trajectory to the new location!
	var/range = 50 //This will de-increment every step. When 0, it will deletze the projectile.

	//Hitscan
	var/hitscan = FALSE		//Whether this is hitscan. If it is, speed is basically ignored.
	var/list/beam_segments	//assoc list of datum/point or datum/point/vector, start = end. Used for hitscan effect generation.
	var/datum/point/beam_index
	var/turf/hitscan_last	//last turf touched during hitscanning.

/obj/item/projectile/Initialize()
	if(!hitscan)
		animate_movement = SLIDE_STEPS
	else animate_movement = NO_STEPS
	. = ..()

/obj/item/projectile/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	return TRUE

/obj/item/projectile/damage_flags()
	return damage_flags

//TODO: make it so this is called more reliably, instead of sometimes by bullet_act() and sometimes not
/obj/item/projectile/proc/on_hit(var/atom/target, var/blocked = 0, var/def_zone = null)
	if(blocked >= 100)
		return FALSE
	if(!isliving(target))
		return FALSE

	var/mob/living/L = target
	L.apply_effects(0, weaken, paralyze, stutter, eyeblur, drowsy, 0, blocked)
	L.stun_effect_act(stun, agony, def_zone, src)
	//radiation protection is handled separately from other armour types.
	L.apply_damage(irradiate, IRRADIATE, damage_flags = DAM_DISPERSED)
	return TRUE

//called when the projectile stops flying because it collided with something
/obj/item/projectile/proc/on_impact(var/atom/A)
	if(damage && atom_damage_type == BURN)
		var/turf/T = get_turf(A)
		if(T)
			T.hotspot_expose(700, 5)

	if(space_knockback && ismovable(A))
		var/atom/movable/AM = A
		if(!AM.anchored && !AM.has_gravity())
			if(ismob(AM))
				var/mob/M = AM
				if(!M.can_slip(magboots_only = TRUE))
					return
			var/old_dir = AM.dir
			step(AM,get_dir(firer,AM))
			AM.set_dir(old_dir)

//Checks if the projectile is eligible for embedding. Not that it necessarily will.
/obj/item/projectile/can_embed()
	//embed must be enabled and damage type must be brute
	if(!embed || atom_damage_type != BRUTE)
		return FALSE
	return TRUE

/obj/item/projectile/proc/get_structure_damage()
	if(atom_damage_type == BRUTE || atom_damage_type == BURN)
		return damage
	return 0

/obj/item/projectile/proc/check_penetrate(atom/A)
	return TRUE

//called to launch a projectile
/obj/item/projectile/proc/launch(atom/target, target_zone, atom/movable/shooter, params, Angle_override, forced_spread = 0)
	original = target
	def_zone = check_zone(target_zone)
	firer = shooter
	var/direct_target
	var/turf/actual_target_turf = get_turf(target)
	actual_target_turf = actual_target_turf?.resolve_to_actual_turf()
	if(actual_target_turf == get_turf(src))
		direct_target = target
	preparePixelProjectile(target, shooter ? shooter : get_turf(src), params, forced_spread)
	return fire(Angle_override, direct_target)

//called to launch a projectile from a gun
/obj/item/projectile/proc/launch_from_gun(atom/target, target_zone, atom/movable/shooter, params, Angle_override, forced_spread, var/obj/item/gun/launcher)
	return launch(target, target_zone, shooter, params)

/obj/item/projectile/proc/set_clickpoint(var/params)
	var/list/mouse_control = params2list(params)
	if(mouse_control["icon-x"])
		p_x = text2num(mouse_control["icon-x"])
	if(mouse_control["icon-y"])
		p_y = text2num(mouse_control["icon-y"])

	//randomize clickpoint a bit based on dispersion
	if(dispersion)
		var/radius = round((dispersion*0.443)*world.icon_size*0.8) //0.443 = sqrt(pi)/4 = 2a, where a is the side length of a square that shares the same area as a circle with diameter = dispersion
		p_x = clamp(p_x + gaussian(0, radius) * 0.25, 0, world.icon_size)
		p_y = clamp(p_y + gaussian(0, radius) * 0.25, 0, world.icon_size)

//Used to change the direction of the projectile in flight.
/obj/item/projectile/proc/redirect(var/new_x, var/new_y, var/atom/starting_loc, var/atom/movable/new_firer=null, var/is_ricochet = FALSE)
	var/turf/starting_turf = get_turf(src)
	var/turf/new_target = locate(new_x, new_y, src.z)

	original = new_target
	if(new_firer)
		firer = src
	var/new_Angle = Atan2(starting_turf, new_target)
	if(is_ricochet) // Add some dispersion.
		new_Angle += (rand(-5,5) * 5)
	setAngle(new_Angle)


//Called when the projectile intercepts a mob. Returns 1 if the projectile hit the mob, 0 if it missed and should keep flying.
/obj/item/projectile/proc/attack_mob(var/mob/living/target_mob, var/distance, var/special_miss_modifier=0)
	if(!istype(target_mob))
		return

	//roll to-hit
	var/miss_modifier = max(distance_falloff*(distance)*(distance) - hitchance_mod + special_miss_modifier, -30)
	//makes moving targets harder to hit, and stationary easier to hit
	var/movment_mod = min(5, (world.time - target_mob.l_move_time) - 20)
	//running in a straight line isnt as helpful tho
	if(movment_mod < 0)
		if(target_mob.last_move == get_dir(firer, target_mob))
			movment_mod *= 0.25
		else if(target_mob.last_move == get_dir(target_mob,firer))
			movment_mod *= 0.5
	miss_modifier -= movment_mod
	var/hit_zone = get_zone_with_miss_chance(def_zone, target_mob, miss_modifier, ranged_attack=(distance > 1 || original != target_mob)) //if the projectile hits a target we weren't originally aiming at then retain the chance to miss

	var/result = PROJECTILE_FORCE_MISS
	if(hit_zone)
		def_zone = hit_zone //set def_zone, so if the projectile ends up hitting someone else later (to be implemented), it is more likely to hit the same part
		if(target_mob.mob_modifiers_block_attack(MM_ATTACK_TYPE_PROJECTILE, src, def_zone))
			return TRUE
		result = target_mob.bullet_act(src, def_zone)

	if(result == PROJECTILE_FORCE_MISS)
		if(!silenced)
			target_mob.visible_message("<span class='notice'>\The [src] misses [target_mob] narrowly!</span>")
			if(LAZYLEN(miss_sounds))
				playsound(target_mob.loc, pick(miss_sounds), 60, 1)
		return FALSE

	//hit messages
	if(silenced)
		to_chat(target_mob, "<span class='danger'>You've been hit in the [parse_zone(def_zone)] by \the [src]!</span>")
	else
		target_mob.visible_message("<span class='danger'>\The [target_mob] is hit by \the [src] in the [parse_zone(def_zone)]!</span>")//X has fired Y is now given by the guns so you cant tell who shot you if you could not see the shooter

	//admin logs
	if(!no_attack_log)
		if(ismob(firer))

			var/attacker_message = "shot with \a [src.type]"
			var/victim_message = "shot with \a [src.type]"
			var/admin_message = "shot (\a [src.type])"

			admin_attack_log(firer, target_mob, attacker_message, victim_message, admin_message)
		else
			admin_victim_log(target_mob, "was shot by an <b>UNKNOWN SUBJECT (No longer exists)</b> using \a [src]")

	//sometimes bullet_act() will want the projectile to continue flying
	if (result == PROJECTILE_CONTINUE)
		return FALSE

	return TRUE

/obj/item/projectile/Bump(atom/A, forced=0)
	if(A == src)
		return 0 //no

	if(A == firer)
		forceMove(A.loc)
		return 0 //cannot shoot yourself

	if((bumped && !forced) || (A in permutated))
		return 0

	var/passthrough = 0 //if the projectile should continue flying
	var/distance = get_dist(starting,loc)

	bumped = 1
	if(ismob(A))
		var/mob/M = A
		if(isliving(A))
			//if they have a neck grab on someone, that person gets hit instead
			var/obj/item/grab/grab = locate() in M
			if(grab && grab.shield_assailant())
				visible_message("<span class='danger'>\The [M] uses [grab.affecting] as a shield!</span>")
				if(Bump(grab.affecting, forced=1))
					return //If Bump() returns 0 (keep going) then we continue on to attack M.

			passthrough = !attack_mob(M, distance)
		else
			passthrough = 1 //so ghosts don't stop bullets
	else
		passthrough = (A.bullet_act(src, def_zone) == PROJECTILE_CONTINUE) //backwards compatibility
		if(isturf(A))
			for(var/obj/O in A)
				O.bullet_act(src)
			for(var/mob/living/M in A)
				attack_mob(M, distance)

	//penetrating projectiles can pass through things that otherwise would not let them
	if(!passthrough && penetrating > 0)
		if(check_penetrate(A))
			passthrough = 1
		penetrating--

	//the bullet passes through a dense object!
	if(passthrough || forcedodge)
		//move ourselves onto A so we can continue on our way.
		var/turf/T = get_turf(A)
		if(T)
			forceMove(T)
		permutated.Add(A)
		bumped = 0 //reset bumped variable!
		return 0

	//stop flying
	on_impact(A)

	set_density(0)
	set_invisibility(INVISIBILITY_ABSTRACT)

	qdel(src)
	return 1

/obj/item/projectile/explosion_act()
	SHOULD_CALL_PARENT(FALSE)
	return

/obj/item/projectile/proc/before_move()
	if(!proj_trail || !isturf(loc) || !proj_trail_icon || !proj_trail_icon_state || !proj_trail_lifespan)
		return
	var/obj/effect/overlay/projectile_trail/trail = new(loc)
	trail.master     = src
	trail.icon       = proj_trail_icon
	trail.icon_state = proj_trail_icon_state
	trail.set_density(FALSE)
	LAZYADD(proj_trails, trail)
	QDEL_IN(trail, proj_trail_lifespan)

/obj/item/projectile/proc/after_move()
	if(hitscan && tracer_type && !(locate(/obj/effect/projectile) in loc))
		var/obj/effect/projectile/invislight/light = new
		light.forceMove(loc)
		light.copy_from(tracer_type)
		QDEL_IN(light, 3)
	if(!isnull(life_span) && --life_span <= 0)
		qdel(src)

/obj/item/projectile/after_wounding(obj/item/organ/external/organ, datum/wound/wound)
	//Check if we even broke skin in first place
	if(!wound || !(wound.damage_type == CUT || wound.damage_type == PIERCE))
		return
	//Check if we can do nasty stuff inside
	if(!can_embed() || (organ.species.species_flags & SPECIES_FLAG_NO_EMBED))
		return
	//Embed or sever artery
	var/damage_prob = 0.5 * wound.damage * penetration_modifier
	if(prob(damage_prob))
		var/obj/item/shrapnel = get_shrapnel()
		if(shrapnel)
			shrapnel.forceMove(organ)
			organ.embed_in_organ(shrapnel)
	else if(prob(2 * damage_prob))
		organ.sever_artery()

	organ.owner.projectile_hit_bloody(src, wound.damage*5, null, organ)

/obj/item/projectile/proc/get_shrapnel()
	if(shrapnel_type)
		var/obj/item/SP = new shrapnel_type()
		SP.SetName((name != "shrapnel")? "[name] shrapnel" : "shrapnel")
		SP.desc += " It looks like it was fired from [shot_from]."
		return SP

/obj/item/projectile/get_autopsy_descriptors()
	return list(name)

/obj/item/projectile/is_space_movement_permitted(allow_movement = FALSE)
	//Deletes projectiles that aren't supposed to be in vacuum if they leave pressurised areas
	if (is_below_sound_pressure(get_turf(src)) && !vacuum_traversal)
		qdel(src)
		return
	return SPACE_MOVE_PERMITTED	//Bullets don't drift in space

/obj/item/projectile/proc/fire(angle, atom/direct_target)
	//If no Angle needs to resolve it from xo/yo!
	if(direct_target)
		direct_target.bullet_act(src, def_zone)
		on_impact(direct_target)
		qdel(src)
		return
	if(isnum(Angle))
		setAngle(Angle)
	// trajectory dispersion
	var/turf/starting = get_turf(src)
	if(!starting)
		return
	if(isnull(Angle))	//Try to resolve through offsets if there's no Angle set.
		if(isnull(xo) || isnull(yo))
			PRINT_STACK_TRACE("WARNING: Projectile [type] deleted due to being unable to resolve a target after Angle was null!")
			qdel(src)
			return
		var/turf/target = locate(clamp(starting + xo, 1, world.maxx), clamp(starting + yo, 1, world.maxy), starting.z)
		setAngle(get_projectile_angle(src, target.resolve_to_actual_turf()))
	if(dispersion)
		var/DeviationAngle = (dispersion * 15)
		setAngle(Angle + rand(-DeviationAngle, DeviationAngle))
	original_Angle = Angle
	if(!nondirectional_sprite)
		var/matrix/M = new
		M.Turn(Angle)
		transform = M
	forceMove(starting)
	trajectory = new(starting.x, starting.y, starting.z, 0, 0, Angle, pixel_speed)
	last_projectile_move = world.time
	fired = TRUE
	if(hitscan)
		return process_hitscan()

	if(muzzle_type)
		var/atom/movable/thing = new muzzle_type
		update_effect(thing)
		thing.forceMove(starting)
		thing.pixel_x = trajectory.return_px() + (trajectory.mpx * 0.5)
		thing.pixel_y = trajectory.return_py() + (trajectory.mpy * 0.5)
		var/matrix/M = new
		M.Turn(Angle)
		thing.transform = M
		QDEL_IN(thing, 3)

	if(!is_processing)
		START_PROCESSING(SSprojectiles, src)
	pixel_move(1)	//move it now!

/obj/item/projectile/proc/preparePixelProjectile(atom/target, atom/source, params, Angle_offset = 0)
	var/turf/curloc = get_turf(source)
	var/turf/targloc = get_turf(target)
	targloc = targloc?.resolve_to_actual_turf()
	forceMove(get_turf(source))
	starting = get_turf(source)
	original = target

	var/list/calculated = list(null,null,null)
	var/mob/living/S = source
	if(istype(S))
		S = S.get_effective_gunner()
	if(istype(S) && S.client && params)
		calculated = calculate_projectile_Angle_and_pixel_offsets(S, params)
		p_x = calculated[2]
		p_y = calculated[3]
		setAngle(calculated[1])

	else if(targloc && curloc)
		yo = targloc.y - curloc.y
		xo = targloc.x - curloc.x
		setAngle(get_projectile_angle(src, targloc))
	else
		PRINT_STACK_TRACE("WARNING: Projectile [type] fired without either mouse parameters, or a target atom to aim at!")
		qdel(src)
	if(Angle_offset)
		setAngle(Angle + Angle_offset)

/obj/item/projectile/Crossed(atom/movable/AM) //A mob moving on a tile with a projectile is hit by it.
	..()
	if(isliving(AM) && (AM.density || AM == original) && !(pass_flags & PASS_FLAG_MOB))
		Bump(AM)

/obj/item/projectile/proc/pixel_move(moves, trajectory_multiplier = 1, hitscanning = FALSE)
	if(!loc || !trajectory)
		if(!QDELETED(src))
			if(loc)
				on_impact(loc)
			qdel(src)
		return
	last_projectile_move = world.time
	if(!nondirectional_sprite && !hitscanning)
		var/matrix/M = new
		M.Turn(Angle)
		transform = M
	trajectory.increment(trajectory_multiplier)

	var/turf/T = trajectory.return_turf()
	if(!T)
		if(!QDELETED(src))
			if(loc)
				on_impact(loc)
			qdel(src)
		return

	if(T.z != loc.z)
		before_move()
		before_z_change(loc, T)
		trajectory_ignore_forcemove = TRUE
		forceMove(T)
		trajectory_ignore_forcemove = FALSE
		after_move()
		if(!hitscanning)
			pixel_x = trajectory.return_px()
			pixel_y = trajectory.return_py()
	else
		before_move()
		step_towards(src, T)
		after_move()
		if(!hitscanning)
			pixel_x = trajectory.return_px() - trajectory.mpx * trajectory_multiplier
			pixel_y = trajectory.return_py() - trajectory.mpy * trajectory_multiplier
	if(!hitscanning)
		animate(src, pixel_x = trajectory.return_px(), pixel_y = trajectory.return_py(), time = 1, flags = ANIMATION_END_NOW)
	if(isturf(loc))
		hitscan_last = loc
	if(can_hit_target(original, permutated))
		Bump(original, TRUE)
	check_distance_left()

//Returns true if the target atom is on our current turf and above the right layer
/obj/item/projectile/proc/can_hit_target(atom/target, var/list/passthrough)
	return (target && ((target.layer >= STRUCTURE_LAYER) || ismob(target)) && (loc == get_turf(target)) && (!(target in passthrough)))

/proc/calculate_projectile_Angle_and_pixel_offsets(mob/user, params)
	var/list/mouse_control = params2list(params)
	var/p_x = 0
	var/p_y = 0
	var/Angle = 0
	if(mouse_control["icon-x"])
		p_x = text2num(mouse_control["icon-x"])
	if(mouse_control["icon-y"])
		p_y = text2num(mouse_control["icon-y"])
	if(mouse_control["screen-loc"])
		//Split screen-loc up into X+Pixel_X and Y+Pixel_Y
		var/list/screen_loc_params = splittext(mouse_control["screen-loc"], ",")

		//Split X+Pixel_X up into list(X, Pixel_X)
		var/list/screen_loc_X = splittext(screen_loc_params[1],":")

		//Split Y+Pixel_Y up into list(Y, Pixel_Y)
		var/list/screen_loc_Y = splittext(screen_loc_params[2],":")
		var/x = text2num(screen_loc_X[1]) * 32 + text2num(screen_loc_X[2]) - 32
		var/y = text2num(screen_loc_Y[1]) * 32 + text2num(screen_loc_Y[2]) - 32

		//Calculate the "resolution" of screen based on client's view and world's icon size. This will work if the user can view more tiles than average.
		var/list/screenview = getviewsize(user.client.view)
		var/screenviewX = screenview[1] * world.icon_size
		var/screenviewY = screenview[2] * world.icon_size

		var/ox = round(screenviewX/2) - user.client.pixel_x //"origin" x
		var/oy = round(screenviewY/2) - user.client.pixel_y //"origin" y
		Angle = Atan2(y - oy, x - ox)
	return list(Angle, p_x, p_y)

/obj/item/projectile/proc/check_distance_left()
	range--
	if(range <= 0 && loc)
		end_distance()

/obj/item/projectile/proc/end_distance() //if we want there to be effects when they reach the end of their range
	on_impact(loc)
	qdel(src)

/obj/item/projectile/proc/store_hitscan_collision(datum/point/pcache)
	beam_segments[beam_index] = pcache
	beam_index = pcache
	beam_segments[beam_index] = null

/obj/item/projectile/proc/process_hitscan()
	set waitfor = FALSE
	var/safety = range * 3
	var/return_vector = RETURN_POINT_VECTOR_INCREMENT(src, Angle, MUZZLE_EFFECT_PIXEL_INCREMENT, 1)
	record_hitscan_start(return_vector)
	while(loc && !QDELETED(src))
		if(paused)
			stoplag(1)
			continue
		safety--
		if(safety <= 0)
			qdel(src)
			PRINT_STACK_TRACE("WARNING: [type] projectile encountered infinite recursion during hitscanning!")
			return	//Kill!
		pixel_move(1, 1, TRUE)

/obj/item/projectile/proc/record_hitscan_start(datum/point/pcache)
	beam_segments = list()	//initialize segment list with the list for the first segment
	beam_index = pcache
	beam_segments[beam_index] = null	//record start.

/obj/item/projectile/proc/before_z_change(turf/oldloc, turf/newloc)
	var/datum/point/pcache = trajectory.copy_to()
	if(hitscan)
		store_hitscan_collision(pcache)

/obj/item/projectile/Process()
	last_process = world.time
	if(!loc || !fired || !trajectory)
		fired = FALSE
		return PROCESS_KILL
	if(paused || !isturf(loc))
		last_projectile_move += world.time - last_process		//Compensates for pausing, so it doesn't become a hitscan projectile when unpaused from charged up ticks.
		return
	var/elapsed_time_deciseconds = (world.time - last_projectile_move) + time_offset
	time_offset = 0
	var/required_moves = 0
	if(speed > 0)
		required_moves = floor(elapsed_time_deciseconds / speed)
		if(required_moves > SSprojectiles.global_max_tick_moves)
			var/overrun = required_moves - SSprojectiles.global_max_tick_moves
			required_moves = SSprojectiles.global_max_tick_moves
			time_offset += overrun * speed
		time_offset += MODULUS_FLOAT(elapsed_time_deciseconds, speed)
	else
		required_moves = SSprojectiles.global_max_tick_moves
	if(!required_moves)
		return
	for(var/i in 1 to required_moves)
		pixel_move(required_moves)

/obj/item/projectile/proc/setAngle(new_Angle)	//wrapper for overrides.
	Angle = new_Angle
	if(!nondirectional_sprite)
		var/matrix/M = new
		M.Turn(Angle)
		transform = M
	if(trajectory)
		trajectory.set_angle(new_Angle)
	return TRUE

/obj/item/projectile/forceMove(atom/target)
	. = ..()
	if(trajectory && !trajectory_ignore_forcemove && isturf(target))
		trajectory.initialize_location(target.x, target.y, target.z, 0, 0)

/obj/item/projectile/Destroy()
	QDEL_NULL_LIST(proj_trails)
	if(hitscan)
		if(loc && trajectory)
			var/datum/point/pcache = trajectory.copy_to()
			beam_segments[beam_index] = pcache
		generate_hitscan_tracers()
	STOP_PROCESSING(SSprojectiles, src)
	return ..()

/obj/item/projectile/proc/generate_hitscan_tracers(cleanup = TRUE, duration = 3)
	if(!length(beam_segments))
		return
	if(duration <= 0)
		return
	if(tracer_type)
		for(var/datum/point/p in beam_segments)
			generate_tracer_between_points(src, p, beam_segments[p], tracer_type, color, duration)
	if(muzzle_type && !silenced)
		var/datum/point/p = beam_segments[1]
		var/atom/movable/thing = new muzzle_type
		update_effect(thing)
		p.move_atom_to_src(thing)
		var/matrix/M = new
		M.Turn(original_Angle)
		thing.transform = M
		QDEL_IN(thing, duration)
	if(impact_type)
		var/datum/point/p = beam_segments[beam_segments[beam_segments.len]]
		var/atom/movable/thing = new impact_type
		update_effect(thing)
		p.move_atom_to_src(thing)
		var/matrix/M = new
		M.Turn(Angle)
		thing.transform = M
		QDEL_IN(thing, duration)
	if(cleanup)
		for(var/i in beam_segments)
			qdel(i)
		beam_segments = null
		QDEL_NULL(beam_index)

/obj/item/projectile/proc/update_effect(var/obj/effect/projectile/effect)
	return
