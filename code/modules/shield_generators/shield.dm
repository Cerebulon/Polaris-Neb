/obj/effect/shield
	name = "energy shield"
	desc = "An impenetrable field of energy, capable of blocking anything as long as it's active."
	icon = 'icons/obj/machines/shielding.dmi'
	icon_state = "shield_normal"
	alpha = 100
	anchored = TRUE
	layer = ABOVE_HUMAN_LAYER
	density = TRUE
	invisibility = INVISIBILITY_NONE
	atmos_canpass = CANPASS_PROC
	var/obj/machinery/shield_generator/gen = null
	var/disabled_for = 0
	var/diffused_for = 0

/obj/effect/shield/on_update_icon()

	if(gen && gen.check_flag(MODEFLAG_PHOTONIC) && !disabled_for && !diffused_for)
		set_opacity(TRUE)
	else
		set_opacity(FALSE)

	if(gen && gen.check_flag(MODEFLAG_OVERCHARGE))
		color = COLOR_VIOLET
	else
		color = COLOR_DEEP_SKY_BLUE

	set_light(2, 1, color)

	cut_overlays()
	for(var/direction in global.cardinal)
		var/turf/resolved_turf = get_step_resolving_mimic(src, direction)
		if(!resolved_turf)
			continue
		var/found = locate(/obj/effect/shield) in resolved_turf
		if(found)
			add_overlay(image(icon = icon, icon_state = "[icon_state]edge", dir = direction))

/obj/effect/shield/update_nearby_tiles(need_rebuild)
	. = ..()
	for(var/direction in global.cardinal)
		var/turf/resolved_turf = get_step_resolving_mimic(src, direction)
		if(!resolved_turf)
			continue
		for(var/obj/effect/shield/shield in resolved_turf)
			if(!(shield.atom_flags & ATOM_FLAG_INITIALIZED)) // they'll update themselves later
				continue
			shield.update_icon()

// Prevents shuttles, singularities and pretty much everything else from moving the field segments away.
// The only thing that is allowed to move us is the Destroy() proc.
/obj/effect/shield/forceMove()
	. = QDELING(src) && ..()

/obj/effect/shield/Initialize(mapload)
	. = ..()
	update_icon()
	update_nearby_tiles()

/obj/effect/shield/Destroy()
	if(gen)
		if(src in gen.field_segments)
			gen.field_segments -= src
		if(src in gen.damaged_segments)
			gen.damaged_segments -= src
		gen = null
	update_nearby_tiles()
	forceMove(null, 1)
	set_light(0)

	var/turf/current_loc = get_turf(src)
	for(var/direction in global.cardinal)
		var/turf/T = get_step(current_loc, direction)
		if(T)
			for(var/obj/effect/shield/F in T)
				F.queue_icon_update()
	. = ..()


// Temporarily collapses this shield segment.
/obj/effect/shield/proc/fail(var/duration)
	if(duration <= 0)
		return

	if(gen)
		gen.damaged_segments |= src
	disabled_for += duration
	set_density(0)
	set_invisibility(INVISIBILITY_MAXIMUM)
	update_nearby_tiles()
	update_icon()
	update_explosion_resistance()


// Regenerates this shield segment.
/obj/effect/shield/proc/regenerate()
	if(!gen)
		return

	disabled_for = max(0, disabled_for - 1)
	diffused_for = max(0, diffused_for - 1)

	if(!disabled_for && !diffused_for)
		set_density(1)
		set_invisibility(INVISIBILITY_NONE)
		update_nearby_tiles()
		update_icon()
		update_explosion_resistance()
		gen.damaged_segments -= src


/obj/effect/shield/proc/diffuse(var/duration)
	// The shield is trying to counter diffusers. Cause lasting stress on the shield.
	if(gen.check_flag(MODEFLAG_BYPASS) && !disabled_for)
		take_damage(duration * rand(8, 12), SHIELD_DAMTYPE_EM)
		return

	diffused_for = max(duration, 0)
	gen.damaged_segments |= src
	set_density(0)
	set_invisibility(INVISIBILITY_MAXIMUM)
	update_nearby_tiles()
	update_icon()
	update_explosion_resistance()

// Fails shield segments in specific range. Range of 1 affects the shielded turf only.
/obj/effect/shield/proc/fail_adjacent_segments(var/range, var/hitby = null)
	if(hitby)
		visible_message(SPAN_DANGER("\The [src] flashes a bit as \the [hitby] collides with it, eventually fading out in a rain of sparks!"))
	else
		visible_message(SPAN_DANGER("\The [src] flashes a bit as it eventually fades out in a rain of sparks!"))
	fail(range * 2)

	for(var/obj/effect/shield/S in range(range, src))
		// Don't affect shields owned by other shield generators
		if(S.gen != src.gen)
			continue
		// The closer we are to impact site, the longer it takes for shield to come back up.
		S.fail(-(-range + get_dist(src, S)) * 2)

/obj/effect/shield/take_damage(damage, damage_type = BRUTE, damage_flags, inflicter, armor_pen = 0, silent, do_update_health)
	if(!gen)
		qdel(src)
		return

	if(!damage)
		return

	damage = round(damage)

	new /obj/effect/temporary(get_turf(src), 2 SECONDS,'icons/obj/machines/shielding.dmi',"shield_impact")
	impact_effect(round(abs(damage * 2)))

	var/list/field_segments = gen.field_segments
	switch(gen.take_shield_damage(damage, damage_type))
		if(SHIELD_ABSORBED)
			return
		if(SHIELD_BREACHED_MINOR)
			fail_adjacent_segments(rand(1, 3), inflicter)
			return
		if(SHIELD_BREACHED_MAJOR)
			fail_adjacent_segments(rand(2, 5), inflicter)
			return
		if(SHIELD_BREACHED_CRITICAL)
			fail_adjacent_segments(rand(4, 8), inflicter)
			return
		if(SHIELD_BREACHED_FAILURE)
			fail_adjacent_segments(rand(8, 16), inflicter)
			for(var/obj/effect/shield/S in field_segments)
				S.fail(1)
			return


// As we have various shield modes, this handles whether specific things can pass or not.
/obj/effect/shield/CanPass(var/atom/movable/mover, var/turf/target, var/height=0, var/air_group=0)
	// Somehow we don't have a generator. This shouldn't happen. Delete the shield.
	if(!gen)
		qdel(src)
		return 1
	if(disabled_for || diffused_for)
		return 1
	// Atmosphere containment.
	if(air_group)
		return !gen.check_flag(MODEFLAG_ATMOSPHERIC)
	if(mover)
		return mover.can_pass_shield(gen)
	return 1

// EMP. It may seem weak but keep in mind that multiple shield segments are likely to be affected.
/obj/effect/shield/emp_act(var/severity)
	if(!disabled_for)
		take_damage(rand(30,60) / severity, SHIELD_DAMTYPE_EM)


// Explosions
/obj/effect/shield/explosion_act(var/severity)
	SHOULD_CALL_PARENT(FALSE)
	if(!disabled_for)
		take_damage(rand(10,15) / severity, SHIELD_DAMTYPE_PHYSICAL)


// Fire
/obj/effect/shield/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	SHOULD_CALL_PARENT(FALSE)
	if(!disabled_for)
		take_damage(rand(5,10), SHIELD_DAMTYPE_HEAT)

// Projectiles
/obj/effect/shield/bullet_act(var/obj/item/projectile/proj)
	if(proj.atom_damage_type == BURN)
		take_damage(proj.get_structure_damage(), SHIELD_DAMTYPE_HEAT)
	else if (proj.atom_damage_type == BRUTE)
		take_damage(proj.get_structure_damage(), SHIELD_DAMTYPE_PHYSICAL)
	else
		take_damage(proj.get_structure_damage(), SHIELD_DAMTYPE_EM)

// Attacks with hand tools. Blocked by Hyperkinetic flag.
/obj/effect/shield/attackby(var/obj/item/used_item, var/mob/user)
	return bash(used_item, user)

/obj/effect/shield/bash(obj/item/weapon, mob/user)
	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	user.do_attack_animation(src)

	if(!gen.check_flag(MODEFLAG_HYPERKINETIC))
		user.visible_message("<span class='danger'>\The [user] tries to attack \the [src] with \the [weapon], but it passes through!</span>")
		return TRUE
	var/force = weapon.expend_attack_force(user)
	user.visible_message("<span class='danger'>\The [user] [pick(weapon.attack_verb)] \the [src] with \the [weapon]!</span>")
	switch(weapon.atom_damage_type)
		if(BURN)
			take_damage(force, SHIELD_DAMTYPE_HEAT)
		if (BRUTE)
			take_damage(force, SHIELD_DAMTYPE_PHYSICAL)
		else
			take_damage(force, SHIELD_DAMTYPE_EM)
	if(gen.check_flag(MODEFLAG_OVERCHARGE) && (weapon.obj_flags & OBJ_FLAG_CONDUCTIBLE))
		overcharge_shock(user)
	return TRUE


// Special treatment for meteors because they would otherwise penetrate right through the shield.
/obj/effect/shield/Bumped(var/atom/movable/mover)
	if(!gen)
		qdel(src)
		return 0
	impact_effect(2)
	mover.shield_impact(src)
	return ..()


/obj/effect/shield/proc/overcharge_shock(var/mob/living/M)
	M.take_damage(rand(20, 40), BURN)
	SET_STATUS_MAX(M, STAT_WEAK, 5)
	to_chat(M, "<span class='danger'>As you come into contact with \the [src] a surge of energy paralyses you!</span>")
	take_damage(10, SHIELD_DAMTYPE_EM)

// Called when a flag is toggled. Can be used to add on-toggle behavior, such as visual changes.
/obj/effect/shield/proc/flags_updated()
	if(!gen)
		qdel(src)
		return

	// Update airflow
	update_nearby_tiles()
	update_icon()
	update_explosion_resistance()

/obj/effect/shield/proc/update_explosion_resistance()
	if(gen && gen.check_flag(MODEFLAG_HYPERKINETIC))
		explosion_resistance = INFINITY
	else
		explosion_resistance = 0

// Shield collision checks below
/atom/movable/proc/can_pass_shield(var/obj/machinery/shield_generator/gen)
	return 1

// Other mobs
/mob/living/can_pass_shield(var/obj/machinery/shield_generator/gen)
	return !gen.check_flag(MODEFLAG_NONHUMANS)

// Human mobs
/mob/living/human/can_pass_shield(var/obj/machinery/shield_generator/gen)
	if(isSynthetic())
		return !gen.check_flag(MODEFLAG_ANORGANIC)
	return !gen.check_flag(MODEFLAG_HUMANOIDS)

// Silicon mobs
/mob/living/silicon/can_pass_shield(var/obj/machinery/shield_generator/gen)
	return !gen.check_flag(MODEFLAG_ANORGANIC)


// Generic objects. Also applies to bullets and meteors.
/obj/can_pass_shield(var/obj/machinery/shield_generator/gen)
	return !gen.check_flag(MODEFLAG_HYPERKINETIC)

// Beams
/obj/item/projectile/beam/can_pass_shield(var/obj/machinery/shield_generator/gen)
	return !gen.check_flag(MODEFLAG_PHOTONIC)

// Beams
/obj/item/projectile/ship_munition/energy/can_pass_shield(var/obj/machinery/shield_generator/gen)
	return !gen.check_flag(MODEFLAG_PHOTONIC)

// Shield on-impact logic here. This is called only if the object is actually blocked by the field (can_pass_shield applies first)
/atom/movable/proc/shield_impact(var/obj/effect/shield/S)
	return

/mob/living/shield_impact(var/obj/effect/shield/S)
	if(!S.gen.check_flag(MODEFLAG_OVERCHARGE))
		return
	S.overcharge_shock(src)

/obj/effect/meteor/shield_impact(var/obj/effect/shield/S)
	if(!S.gen.check_flag(MODEFLAG_HYPERKINETIC))
		return
	S.take_damage(get_shield_damage(), SHIELD_DAMTYPE_PHYSICAL, inflicter = src)
	visible_message(SPAN_DANGER("\The [src] breaks into dust!"))
	make_debris()
	qdel(src)

// Small visual effect, makes the shield tiles brighten up by becoming more opaque for a moment, and spreads to nearby shields.
/obj/effect/shield/proc/impact_effect(var/i, var/list/affected_shields = list())
	i = clamp(i, 1, 10)
	alpha = 255
	animate(src, alpha = initial(alpha), time = 1 SECOND)
	affected_shields |= src
	i--
	if(i)
		addtimer(CALLBACK(src, PROC_REF(spread_impact_effect), i, affected_shields), 2)

/obj/effect/shield/proc/spread_impact_effect(var/i, var/list/affected_shields = list())
	for(var/direction in global.cardinal)
		var/turf/T = get_step(src, direction)
		if(T) // Incase we somehow stepped off the map.
			for(var/obj/effect/shield/F in T)
				if(!(F in affected_shields))
					F.impact_effect(i, affected_shields) // Spread the effect to them

/obj/effect/shield/attack_hand(var/mob/user)
	impact_effect(3) // Harmless, but still produces the 'impact' effect.
	return ..()
