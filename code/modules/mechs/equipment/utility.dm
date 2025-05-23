/obj/item/mech_equipment/clamp
	name = "mounted clamp"
	desc = "A large, heavy industrial cargo loading clamp."
	icon_state = "mech_clamp"
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	restricted_software = list(MECH_SOFTWARE_UTILITY)
	origin_tech = @'{"materials":2,"engineering":2}'
	var/carrying_capacity = 5
	var/list/obj/carrying = list()

/obj/item/mech_equipment/clamp/resolve_attackby(atom/A, mob/user, click_params)
	if(owner)
		return 0
	return ..()

/obj/item/mech_equipment/clamp/attack_hand(mob/user)
	if(!owner || !LAZYISIN(owner.pilots, user) || owner.hatch_closed || !length(carrying) || !user.check_dexterity(DEXTERITY_HOLD_ITEM, TRUE))
		return ..()
	// Filter out non-items.
	var/list/carrying_items = list()
	for(var/obj/item/thing in carrying)
		carrying_items += thing
	if(!length(carrying_items))
		return TRUE
	var/obj/item/chosen_obj = input(user, "Choose an object to grab.", "Clamp Claw") as null|anything in carrying_items
	if(chosen_obj && do_after(user, 20, owner) && !owner.hatch_closed && !QDELETED(chosen_obj) && (chosen_obj in carrying))
		owner.visible_message(SPAN_NOTICE("\The [user] carefully grabs \the [chosen_obj] from \the [src]."))
		playsound(src, 'sound/mecha/hydraulic.ogg', 50, 1)
		carrying -= chosen_obj
		user.put_in_active_hand(chosen_obj)
	return TRUE

/obj/item/mech_equipment/clamp/afterattack(var/atom/target, var/mob/living/user, var/inrange, var/params)
	. = ..()

	if(.)
		if(length(carrying) >= carrying_capacity)
			to_chat(user, SPAN_WARNING("\The [src] is fully loaded!"))
			return
		if(istype(target, /obj))
			var/obj/O = target
			if(O.buckled_mob)
				return
			if(locate(/mob/living) in O)
				to_chat(user, SPAN_WARNING("You can't load living things into the cargo compartment."))
				return

			if(O.anchored)
				//Special door handling
				if(istype(O, /obj/machinery/door/firedoor))
					var/obj/machinery/door/firedoor/FD = O
					if(FD.blocked)
						FD.visible_message(SPAN_DANGER("\The [owner] begins prying on \the [FD]!"))
						if(do_after(owner,10 SECONDS,FD) && FD.blocked)
							playsound(FD, 'sound/effects/meteorimpact.ogg', 100, 1)
							playsound(FD, 'sound/machines/airlock_creaking.ogg', 100, 1)
							FD.blocked = FALSE
							addtimer(CALLBACK(FD, TYPE_PROC_REF(/obj/machinery/door/firedoor, open), TRUE), 0)
							FD.set_broken(TRUE)
							FD.visible_message(SPAN_WARNING("\The [owner] tears \the [FD] open!"))
					else
						FD.visible_message(SPAN_DANGER("\The [owner] begins forcing \the [FD]!"))
						if(do_after(owner, 4 SECONDS,FD) && !FD.blocked)
							playsound(FD, 'sound/machines/airlock_creaking.ogg', 100, 1)
							if(FD.density)
								FD.visible_message(SPAN_DANGER("\The [owner] forces \the [FD] open!"))
								addtimer(CALLBACK(FD, TYPE_PROC_REF(/obj/machinery/door/firedoor, open), TRUE), 0)
							else
								FD.visible_message(SPAN_WARNING("\The [owner] forces \the [FD] closed!"))
								addtimer(CALLBACK(FD, TYPE_PROC_REF(/obj/machinery/door/firedoor, close), TRUE), 0)
					return
				else if(istype(O, /obj/machinery/door/airlock))
					var/obj/machinery/door/airlock/AD = O
					if(!AD.operating && !AD.locked)
						if(AD.welded)
							AD.visible_message(SPAN_DANGER("\The [owner] begins prying on \the [AD]!"))
							if(do_after(owner, 15 SECONDS,AD) && !AD.locked)
								AD.welded = FALSE
								AD.update_icon()
								playsound(AD, 'sound/effects/meteorimpact.ogg', 100, 1)
								playsound(AD, 'sound/machines/airlock_creaking.ogg', 100, 1)
								AD.visible_message(SPAN_DANGER("\The [owner] tears \the [AD] open!"))
								addtimer(CALLBACK(AD, TYPE_PROC_REF(/obj/machinery/door/airlock, open), TRUE), 0)
								AD.set_broken(TRUE)
								return
						else
							AD.visible_message(SPAN_DANGER("\The [owner] begins forcing \the [AD]!"))
							if((AD.is_broken(NOPOWER) || do_after(owner, 5 SECONDS,AD)) && !(AD.operating || AD.welded || AD.locked))
								playsound(AD, 'sound/machines/airlock_creaking.ogg', 100, 1)
								if(AD.density)
									addtimer(CALLBACK(AD, TYPE_PROC_REF(/obj/machinery/door/airlock, open), TRUE), 0)
									if(!AD.is_broken(NOPOWER))
										AD.set_broken(TRUE)
									AD.visible_message(SPAN_DANGER("\The [owner] forces \the [AD] open!"))
								else
									addtimer(CALLBACK(AD, TYPE_PROC_REF(/obj/machinery/door/airlock, close), TRUE), 0)
									if(!AD.is_broken(NOPOWER))
										AD.set_broken(TRUE)
									AD.visible_message(SPAN_DANGER("\The [owner] forces \the [AD] closed!"))
					if(AD.locked)
						to_chat(user, SPAN_NOTICE("The airlock's bolts prevent it from being forced."))
					return

				to_chat(user, SPAN_WARNING("\The [target] is firmly secured."))
				return

			owner.visible_message(SPAN_NOTICE("\The [owner] begins loading \the [O]."))
			if(do_after(owner, 20, O, 0, 1))
				if((O in carrying) || O.buckled_mob || O.anchored || (locate(/mob/living) in O)) //Repeat checks
					return
				if(length(carrying) >= carrying_capacity)
					to_chat(user, SPAN_WARNING("\The [src] is fully loaded!"))
					return
				O.forceMove(src)
				carrying += O
				owner.visible_message(SPAN_NOTICE("\The [owner] loads \the [O] into its cargo compartment."))
				playsound(src, 'sound/mecha/hydraulic.ogg', 50, 1)

		//attacking - Cannot be carrying something, cause then your clamp would be full
		else if(isliving(target))
			var/mob/living/M = target
			if(user.check_intent(I_FLAG_HARM))
				admin_attack_log(user, M, "attempted to clamp [M] with [src] ", "Was subject to a clamping attempt.", ", using \a [src], attempted to clamp")
				owner.setClickCooldown(owner.arms ? owner.arms.action_delay * 3 : 30) //This is an inefficient use of your powers
				if(prob(33))
					owner.visible_message(SPAN_DANGER("[owner] swings its [src] in a wide arc at [target] but misses completely!"))
					return
				M.attack_generic(owner, (owner.arms ? owner.arms.melee_damage * 1.5 : 0), "slammed") //Honestly you should not be able to do this without hands, but still
				M.throw_at(get_edge_target_turf(owner ,owner.dir),5, 2)
				to_chat(user, "<span class='warning'>You slam [target] with [src.name].</span>")
				owner.visible_message(SPAN_DANGER("[owner] slams [target] with the hydraulic clamp."))
			else
				step_away(M, owner)
				to_chat(user, "You push [target] out of the way.")
				owner.visible_message("[owner] pushes [target] out of the way.")

/obj/item/mech_equipment/clamp/attack_self(var/mob/user)
	. = ..()
	if(.)
		drop_carrying(user, TRUE)

/obj/item/mech_equipment/clamp/get_alt_interactions(mob/user)
	. = ..()
	LAZYADD(., /decl/interaction_handler/mech_equipment/clamp)

/obj/item/mech_equipment/clamp/proc/drop_carrying(var/mob/user, var/choose_object)
	if(!length(carrying))
		to_chat(user, SPAN_WARNING("You are not carrying anything in \the [src]."))
		return
	var/obj/chosen_obj = carrying[1]
	if(choose_object)
		chosen_obj = input(user, "Choose an object to set down.", "Clamp Claw") as null|anything in carrying
	if(!chosen_obj)
		return
	if(chosen_obj.density)
		for(var/atom/A in get_turf(src))
			if(A != owner && A.density && !(A.atom_flags & ATOM_FLAG_CHECKS_BORDER))
				to_chat(user, SPAN_WARNING("\The [A] blocks you from putting down \the [chosen_obj]."))
				return

	owner.visible_message(SPAN_NOTICE("\The [owner] unloads \the [chosen_obj]."))
	playsound(src, 'sound/mecha/hydraulic.ogg', 50, 1)
	chosen_obj.forceMove(get_turf(src))
	carrying -= chosen_obj

/obj/item/mech_equipment/clamp/get_hardpoint_status_value()
	if(length(carrying) > 1)
		return length(carrying)/carrying_capacity
	return null

/obj/item/mech_equipment/clamp/get_hardpoint_maptext()
	if(length(carrying) == 1)
		return carrying[1].name
	else if(length(carrying) > 1)
		return "Multiple"
	. = ..()

/obj/item/mech_equipment/clamp/uninstalled()
	if(length(carrying))
		for(var/obj/load in carrying)
			var/turf/location = get_turf(src)
			var/list/turfs = location.AdjacentTurfsSpace()
			if(load.density)
				if(turfs.len > 0)
					location = pick(turfs)
					turfs -= location
				else
					load.dropInto(location)
					load.throw_at_random(FALSE, rand(2,4), 4)
					location = null
			if(location)
				load.dropInto(location)
			carrying -= load
	. = ..()

/decl/interaction_handler/mech_equipment/clamp
	name = "Release Clamp"
	expected_target_type = /obj/item/mech_equipment/clamp
	examine_desc = "release $TARGET_THEM$"

/decl/interaction_handler/mech_equipment/clamp/invoked(atom/target, mob/user, obj/item/prop)
	var/obj/item/mech_equipment/clamp/clamp = target
	clamp.drop_carrying(user, FALSE)

// A lot of this is copied from floodlights.
/obj/item/mech_equipment/light
	name = "floodlight"
	desc = "An exosuit-mounted light."
	icon_state = "mech_floodlight"
	item_state = "mech_floodlight"
	restricted_hardpoints = list(HARDPOINT_HEAD, HARDPOINT_LEFT_SHOULDER, HARDPOINT_RIGHT_SHOULDER)
	mech_layer = MECH_INTERMEDIATE_LAYER
	origin_tech = @'{"materials":1,"engineering":1}'

	var/on = 0
	var/l_power = 0.9
	var/l_range = 6

/obj/item/mech_equipment/light/installed(mob/living/exosuit/_owner)
	. = ..()
	update_icon()

/obj/item/mech_equipment/light/attack_self(var/mob/user)
	. = ..()
	if(.)
		toggle()
		to_chat(user, "You switch \the [src] [on ? "on" : "off"].")

/obj/item/mech_equipment/light/proc/toggle()
	on = !on
	update_icon()
	owner.update_icon()
	active = on
	passive_power_use = on ? 0.1 KILOWATTS : 0

/obj/item/mech_equipment/light/deactivate()
	if(on)
		toggle()
	..()

/obj/item/mech_equipment/light/on_update_icon()
	. = ..()
	if(on)
		icon_state = "[initial(icon_state)]-on"
		set_light(l_range, l_power)
	else
		icon_state = "[initial(icon_state)]"
		set_light(0, 0)

	//Check our layers
	if(owner && (owner.hardpoints[HARDPOINT_HEAD] == src))
		mech_layer = MECH_INTERMEDIATE_LAYER
	else mech_layer = initial(mech_layer)

#define CATAPULT_SINGLE 1
#define CATAPULT_AREA   2

/obj/item/mech_equipment/catapult
	name = "gravitational catapult"
	desc = "An exosuit-mounted gravitational catapult."
	icon_state = "mech_wormhole"
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	restricted_software = list(MECH_SOFTWARE_UTILITY)
	var/mode = CATAPULT_SINGLE
	var/atom/movable/locked
	equipment_delay = 30 //Stunlocks are not ideal
	origin_tech = @'{"materials":4,"engineering":4,"magnets":4}'
	require_adjacent = FALSE

/obj/item/mech_equipment/catapult/get_hardpoint_maptext()
	var/string
	if(locked)
		string = locked.name + " - "
	if(mode == 1)
		string += "Pull"
	else string += "Push"
	return string


/obj/item/mech_equipment/catapult/attack_self(var/mob/user)
	. = ..()
	if(.)
		mode = mode == CATAPULT_SINGLE ? CATAPULT_AREA : CATAPULT_SINGLE
		to_chat(user, SPAN_NOTICE("You set \the [src] to [mode == CATAPULT_SINGLE ? "single" : "multi"]-target mode."))
		update_icon()


/obj/item/mech_equipment/catapult/afterattack(var/atom/target, var/mob/living/user, var/inrange, var/params)
	. = ..()
	if(.)

		switch(mode)
			if(CATAPULT_SINGLE)
				if(!locked)
					var/atom/movable/AM = target
					if(!istype(AM) || AM.anchored || !AM.simulated)
						to_chat(user, SPAN_NOTICE("Unable to lock on [target]."))
						return
					locked = AM
					to_chat(user, SPAN_NOTICE("Locked on [AM]."))
					return
				else if(target != locked)
					if(locked in view(owner))
						locked.throw_at(target, 14, 1.5, owner)
						log_and_message_admins("used [src] to throw [locked] at [target].", user, owner.loc)
						locked = null

						var/obj/item/cell/cell = owner.get_cell()
						if(istype(cell))
							cell.use(active_power_use * CELLRATE)

					else
						locked = null
						to_chat(user, SPAN_NOTICE("Lock on [locked] disengaged."))
			if(CATAPULT_AREA)

				var/list/atoms = list()
				if(isturf(target))
					atoms = range(target,3)
				else
					atoms = orange(target,3)
				for(var/atom/movable/A in atoms)
					if(A.anchored || !A.simulated) continue
					var/dist = 5-get_dist(A,target)
					A.throw_at(get_edge_target_turf(A,get_dir(target, A)),dist,0.7)


				log_and_message_admins("used [src]'s area throw on [target].", user, owner.loc)
				var/obj/item/cell/cell = owner.get_cell()
				if(istype(cell))
					cell.use(active_power_use * CELLRATE * 2) //bit more expensive to throw all



#undef CATAPULT_SINGLE
#undef CATAPULT_AREA


/obj/item/drill_head
	name = "drill head"
	desc = "A replaceable drill head usually used in exosuit drills."
	icon = 'icons/obj/items/tool/drill_head.dmi'
	icon_state = "drill_head"
	material = /decl/material/solid/metal/steel
	var/durability = 0

/obj/item/drill_head/proc/get_percent_durability()
	return round((durability / material.integrity) * 50)

/obj/item/drill_head/proc/get_visible_durability()
	switch (get_percent_durability())
		if (95 to INFINITY) . = "shows no wear"
		if (75 to 95) . = "shows some wear"
		if (50 to 75) . = "is fairly worn"
		if (10 to 50) . = "is very worn"
		else . = "looks close to breaking"

/obj/item/drill_head/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	. += "It [get_visible_durability()]."

/obj/item/drill_head/steel
	material = /decl/material/solid/metal/steel

/obj/item/drill_head/titanium
	material = /decl/material/solid/metal/titanium

/obj/item/drill_head/plasteel
	material = /decl/material/solid/metal/plasteel

/obj/item/drill_head/diamond
	material = /decl/material/solid/gemstone/diamond

/obj/item/drill_head/Initialize()
	. = ..()
	durability = 2 * material.integrity

/obj/item/mech_equipment/drill
	name = "drill"
	desc = "This is the drill that'll pierce the heavens!"
	icon_state = "mech_drill"
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	restricted_software = list(MECH_SOFTWARE_UTILITY)
	equipment_delay = 10

	//Drill can have a head
	var/obj/item/drill_head/drill_head
	origin_tech = @'{"materials":2,"engineering":2}'

/obj/item/mech_equipment/drill/Initialize()
	. = ..()
	if (ispath(drill_head))
		drill_head = new drill_head(src)

/obj/item/mech_equipment/drill/attack_self(var/mob/user)
	. = ..()
	if(.)
		if(drill_head)
			owner.visible_message(SPAN_WARNING("[owner] revs the [drill_head], menancingly."))
			playsound(src, 'sound/mecha/mechdrill.ogg', 50, 1)

/obj/item/mech_equipment/drill/get_hardpoint_maptext()
	if(drill_head)
		return "Integrity: [drill_head.get_percent_durability()]%"
	return

/obj/item/mech_equipment/drill/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	if (drill_head)
		. += "It has a[distance > 3 ? "" : " [drill_head.material.name]"] drill head installed."
		if (distance < 4)
			. += "The drill head [drill_head.get_visible_durability()]."
	else
		. += "It does not have a drill head installed."

/obj/item/mech_equipment/drill/proc/attach_head(obj/item/drill_head/DH, mob/user)
	if (user && !user.try_unequip(DH))
		return
	if (drill_head)
		visible_message(SPAN_NOTICE("\The [user] detaches \the [drill_head] mounted on \the [src]."))
		drill_head.dropInto(get_turf(src))
	user.visible_message(SPAN_NOTICE("\The [user] mounts \the [drill_head] on \the [src]."))
	DH.forceMove(src)
	drill_head = DH

/obj/item/mech_equipment/drill/attackby(obj/item/used_item, mob/user)
	if (istype(used_item, /obj/item/drill_head))
		attach_head(used_item, user)
		return TRUE
	. = ..()

/obj/item/mech_equipment/drill/proc/scoop_ore(at_turf)
	if (!owner)
		return
	for (var/hardpoint in owner.hardpoints)
		var/obj/item/item = owner.hardpoints[hardpoint]
		if (!istype(item))
			continue
		var/obj/structure/ore_box/ore_box = locate(/obj/structure/ore_box) in item
		if (!ore_box)
			continue
		for(var/obj/item/stack/material/ore/ore in range(1, at_turf))
			if (!(get_dir(owner, ore) & owner.dir))
				continue
			ore_box.insert_ore(ore)

/obj/item/mech_equipment/drill/afterattack(atom/target, mob/living/user, inrange, params)
	if (!..()) // /obj/item/mech_equipment/afterattack implements a usage guard
		return

	if(!target.simulated)
		return

	if (!drill_head)
		if (istype(target, /obj/item/drill_head))
			attach_head(target, user)
		else
			to_chat(user, SPAN_WARNING("\The [src] doesn't have a head!"))
		return

	if (ismob(target))
		to_chat(target, FONT_HUGE(SPAN_DANGER("You're about to get drilled - dodge!")))

	else if (isobj(target))
		var/obj/tobj = target
		var/decl/material/mat = tobj.get_material()
		if (mat && mat.hardness < drill_head.material?.hardness)
			to_chat(user, SPAN_WARNING("\The [target] is too hard to be destroyed by [drill_head.material ? "a [drill_head.material.adjective_name]" : "this"] drill."))
			return

	else if (istype(target, /turf/unsimulated))
		to_chat(user, SPAN_WARNING("\The [target] can't be drilled away."))
		return

	var/obj/item/cell/mech_cell = owner.get_cell()
	mech_cell.use(active_power_use * CELLRATE) //supercall made sure we have one

	var/delay = 3 SECONDS //most things
	switch (drill_head.material.brute_armor)
		if (15 to INFINITY) delay = 0.5 SECONDS //voxalloy on a good roll
		if (10 to 15) delay = 1 SECOND //titanium, diamond
		if (5 to 10) delay = 2 SECONDS //plasteel, steel
	owner.setClickCooldown(delay)

	playsound(src, 'sound/mecha/mechdrill.ogg', 50, 1)
	owner.visible_message(
		SPAN_WARNING("\The [owner] starts to drill \the [target]."),
		blind_message = SPAN_WARNING("You hear a large motor whirring.")
	)
	if (!do_after(owner, delay, target))
		return
	if (src != owner.selected_system)
		to_chat(user, SPAN_WARNING("You must keep \the [src] selected to use it."))
		return
	if (drill_head.durability <= 0)
		drill_head.shatter()
		drill_head = null
		return

	if (istype(target, /turf/wall/natural))
		for (var/turf/wall/natural/M in RANGE_TURFS(target, 1))
			if (!(get_dir(owner, M) & owner.dir))
				continue
			drill_head.durability -= 1
			M.dismantle_turf()
		scoop_ore(target)
		return

	if (istype(target, /turf/wall))
		var/turf/wall/wall = target
		var/wall_hardness = max(wall.material.hardness, wall.reinf_material ? wall.reinf_material.hardness : 0)
		if (wall_hardness > drill_head.material.hardness)
			to_chat(user, SPAN_WARNING("\The [wall] is too hard to drill through with \the [drill_head]."))
			drill_head.durability -= 2
			return

	if(istype(target, /turf))
		for(var/turf/asteroid as anything in RANGE_TURFS(target, 1))
			if (!(get_dir(owner, asteroid) & owner.dir))
				continue
			if(asteroid.can_be_dug(drill_head.material?.hardness) && asteroid.drop_diggable_resources(user))
				drill_head.durability -= 1
				scoop_ore(asteroid)
		return

	var/audible = "loudly grinding machinery"
	if (isliving(target)) //splorch
		audible = "a terrible rending of metal and flesh"

	owner.visible_message(
		SPAN_DANGER("\The [owner] drives \the [src] into \the [target]."),
		blind_message = SPAN_WARNING("You hear [audible].")
	)
	log_and_message_admins("used [src] on [target]", user, owner.loc)
	drill_head.durability -= 1
	target.explosion_act(2)


/obj/item/mech_equipment/drill/steel
	drill_head = /obj/item/drill_head/steel

/obj/item/mech_equipment/drill/titanium
	drill_head = /obj/item/drill_head/titanium

/obj/item/mech_equipment/drill/plasteel
	drill_head = /obj/item/drill_head/plasteel

/obj/item/mech_equipment/drill/diamond
	drill_head = /obj/item/drill_head/diamond

/obj/item/gun/energy/plasmacutter/mounted/mech
	use_external_power = TRUE
	has_safety = FALSE


/obj/item/mech_equipment/mounted_system/taser/plasma
	name = "mounted plasma cutter"
	desc = "An industrial plasma cutter mounted onto the chassis of the mech. "
	icon_state = "mech_plasma"
	holding = /obj/item/gun/energy/plasmacutter/mounted/mech
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND, HARDPOINT_LEFT_SHOULDER, HARDPOINT_RIGHT_SHOULDER)
	restricted_software = list(MECH_SOFTWARE_UTILITY)
	origin_tech = @'{"materials":4,"engineering":6,"exoticmatter":4,"combat":3}'

/obj/item/mech_equipment/mounted_system/taser/autoplasma
	icon_state = "mech_energy"
	holding = /obj/item/gun/energy/plasmacutter/mounted/mech/auto
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	restricted_software = list(MECH_SOFTWARE_UTILITY)
	origin_tech = @'{"materials":5,"engineering":6,"exoticmatter":4,"combat":4}'

/obj/item/gun/energy/plasmacutter/mounted/mech/auto
	charge_cost = 13
	name = "rotatory plasma cutter"
	desc = "A state-of-the-art rotating, variable intensity, sequential-cascade plasma cutter. Resist the urge to aim this at your coworkers."
	max_shots = 15
	firemodes = list(
		list(mode_name="single shot", autofire_enabled=0, burst=1, fire_delay=6, dispersion = list(0.0)),
		list(mode_name="full auto",   autofire_enabled=1, burst=1, fire_delay=1, burst_accuracy = list(0,-1,-1,-1,-1,-2,-2,-2), dispersion = list(1.0, 1.0, 1.0, 1.0, 1.1)),
	)

/obj/item/mech_equipment/ionjets
	name = "\improper exosuit manouvering unit"
	desc = "A testament to the fact that sometimes more is actually more. These oversized electric resonance boosters allow exosuits to move in microgravity and can even provide brief speed boosts. The stabilizers can be toggled with ctrl-click."
	icon_state = "mech_jet_off"
	restricted_hardpoints = list(HARDPOINT_BACK)
	restricted_software = list(MECH_SOFTWARE_UTILITY)
	active_power_use = 90 KILOWATTS
	passive_power_use = 0 KILOWATTS
	var/activated_passive_power = 2 KILOWATTS
	var/movement_power = 75
	origin_tech = @'{"magnets":3,"engineering":3,"exoticmatter":3}'
	var/datum/effect/effect/system/trail/ion/ion_trail
	require_adjacent = FALSE
	var/stabilizers = FALSE
	var/slide_distance = 6

/obj/item/mech_equipment/ionjets/Initialize()
	. = ..()
	ion_trail = new /datum/effect/effect/system/trail/ion()
	ion_trail.set_up(src)

/obj/item/mech_equipment/ionjets/Destroy()
	QDEL_NULL(ion_trail)
	return ..()

/obj/item/mech_equipment/ionjets/proc/provides_thrust()
	if(!active)
		return FALSE
	var/obj/item/cell/cell = owner?.get_cell()
	if(istype(cell))
		if(cell.checked_use(movement_power * CELLRATE))
			return TRUE
		deactivate()
	return FALSE

/obj/item/mech_equipment/ionjets/attack_self(mob/user)
	. = ..()
	if (!.)
		return

	if (active)
		deactivate()
	else
		activate()

/obj/item/mech_equipment/ionjets/proc/activate()
	passive_power_use = activated_passive_power
	ion_trail.start()
	active = TRUE
	update_icon()

/obj/item/mech_equipment/ionjets/deactivate()
	. = ..()
	passive_power_use = 0 KILOWATTS
	ion_trail.stop()
	update_icon()

/obj/item/mech_equipment/ionjets/on_update_icon()
	. = ..()
	if (active)
		icon_state = "mech_jet_on"
		set_light(1, 1, 1, l_color = COLOR_LIGHT_CYAN)
	else
		icon_state = "mech_jet_off"
		set_light(0)
	if(owner)
		owner.update_icon()

/obj/item/mech_equipment/ionjets/get_hardpoint_maptext()
	if (active)
		return "ONLINE - Stabilizers [stabilizers ? "on" : "off"]"
	else return "OFFLINE"

/obj/item/mech_equipment/ionjets/proc/slideCheck(turf/target)
	if (owner && istype(target))
		if ((get_dist(owner, target) <= slide_distance) && (get_dir(get_turf(owner), target) == owner.dir))
			return TRUE
	return FALSE

/obj/item/mech_equipment/ionjets/afterattack(atom/target, mob/living/user, inrange, params)
	. = ..()
	if (. && active)
		if (owner.z != target.z)
			to_chat(user, SPAN_WARNING("You cannot reach that level!"))
			return FALSE
		var/turf/TT = get_turf(target)
		if (slideCheck(TT))
			playsound(src, 'sound/magic/forcewall.ogg', 30, 1)
			owner.visible_message(
				SPAN_WARNING("\The [src] charges up in preparation for a slide!"),
				blind_message = SPAN_WARNING("You hear a loud hum and an intense crackling.")
			)
			new /obj/effect/temporary(get_step(owner.loc, global.reverse_dir[owner.dir]), 2 SECONDS, 'icons/effects/effects.dmi',"cyan_sparkles")
			owner.setClickCooldown(2 SECONDS)
			if (do_after(owner, 2 SECONDS, same_direction = TRUE) && slideCheck(TT))
				owner.visible_message(SPAN_DANGER("Burning hard, \the [owner] thrusts forward!"))
				owner.throw_at(get_ranged_target_turf(owner, owner.dir, slide_distance), slide_distance, 1, owner, FALSE)
			else
				owner.visible_message(SPAN_DANGER("\The [src] sputters and powers down."))
				owner.sparks.set_up(3,0,owner)
				owner.sparks.start()

		else
			to_chat(user, SPAN_WARNING("You cannot slide there!"))

/obj/item/mech_equipment/ionjets/get_alt_interactions(mob/user)
	. = ..()
	LAZYADD(., /decl/interaction_handler/mech_equipment/ionjets)

/decl/interaction_handler/mech_equipment/ionjets
	name = "Toggle Stabilizers"
	expected_target_type = /obj/item/mech_equipment/ionjets
	examine_desc = "toggle the stabilizers"

/decl/interaction_handler/mech_equipment/ionjets/is_possible(atom/target, mob/user, obj/item/prop)
	. = ..()
	if(.)
		var/obj/item/mech_equipment/ionjets/jets = target
		return jets.active

/decl/interaction_handler/mech_equipment/ionjets/invoked(atom/target, mob/user, obj/item/prop)
	var/obj/item/mech_equipment/ionjets/jets = target
	jets.stabilizers = !jets.stabilizers
	to_chat(user, SPAN_NOTICE("You toggle the stabilizers [jets.stabilizers ? "on" : "off"]"))
	return TRUE

//Exosuit camera
/datum/extension/network_device/camera/mech
	expected_type = /obj/item/mech_equipment/camera
	cameranet_enabled = FALSE
	requires_connection = FALSE

/datum/extension/network_device/camera/mech/is_functional()
	var/obj/item/mech_equipment/camera/R = holder
	return R.active

/obj/item/mech_equipment/camera
	name = "exosuit camera"
	desc = "A dedicated visible light spectrum camera for remote feeds. It comes with its own transmitter!"
	icon_state = "mech_camera"
	restricted_hardpoints = list(HARDPOINT_LEFT_SHOULDER, HARDPOINT_RIGHT_SHOULDER)
	restricted_software = list(MECH_SOFTWARE_UTILITY)
	equipment_delay = 10

	origin_tech = @'{"materials":1,"engineering":1,"magnets":2}'


/obj/item/mech_equipment/camera/Initialize()
	. = ..()

	set_extension(src, /datum/extension/network_device/camera/mech, null, null, null, TRUE, list(CAMERA_CHANNEL_PUBLIC), "unregistered exocamera")

/obj/item/mech_equipment/camera/installed(mob/living/exosuit/_owner)
	. = ..()
	if(owner)
		var/datum/extension/network_device/camera/mech/D = get_extension(src, /datum/extension/network_device)
		D.display_name = "[owner.name] camera feed"

/obj/item/mech_equipment/camera/uninstalled()
	. = ..()
	var/datum/extension/network_device/camera/mech/D = get_extension(src, /datum/extension/network_device)
	D.display_name = "unregistered exocamera"

/obj/item/mech_equipment/camera/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	var/datum/extension/network_device/camera/mech/D = get_extension(src, /datum/extension/network_device)
	. += "Channel: [english_list(D.channels)]; Feed is currently: [active ? "Online" : "Offline"]."

/obj/item/mech_equipment/camera/proc/activate()
	passive_power_use = 0.2 KILOWATTS
	active = TRUE

/obj/item/mech_equipment/camera/deactivate()
	passive_power_use = 0
	. = ..()

/obj/item/mech_equipment/camera/attackby(obj/item/used_item, mob/user)
	. = ..()

	if(IS_SCREWDRIVER(used_item))
		var/datum/extension/network_device/camera/mech/D = get_extension(src, /datum/extension/network_device)
		D.ui_interact(user)

/obj/item/mech_equipment/camera/attack_self(mob/user)
	. = ..()
	if(.)
		if(active)
			deactivate()
		else
			activate()
		to_chat(user, SPAN_NOTICE("You toggle \the [src] [active ? "on" : "off"]"))

/obj/item/mech_equipment/camera/get_hardpoint_maptext()
	var/datum/extension/network_device/camera/mech/D = get_extension(src, /datum/extension/network_device)
	return "[english_list(D.channels)]: [active ? "ONLINE" : "OFFLINE"]"
