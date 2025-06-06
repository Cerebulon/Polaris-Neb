var/global/list/closets = list()

/obj/structure/closet
	name = "closet"
	desc = "It's a basic storage unit."
	icon = 'icons/obj/closets/bases/closet.dmi'
	icon_state = "base"
	density = TRUE
	max_health = 100
	material = /decl/material/solid/metal/steel
	tool_interaction_flags = TOOL_INTERACTION_ANCHOR

	var/welded = 0
	var/large = 1
	var/wall_mounted = 0 //never solid (You can always pass over it)
	var/breakout = 0 //if someone is currently breaking out. mutex
	var/storage_capacity = 2 * MOB_SIZE_MEDIUM //This is so that someone can't pack hundreds of items in a locker/crate
							  //then open it in a populated area to crash clients.
	var/open_sound = 'sound/effects/closet_open.ogg'
	var/close_sound = 'sound/effects/closet_close.ogg'

	var/storage_types = CLOSET_STORAGE_ALL
	var/setup = CLOSET_CAN_BE_WELDED
	var/closet_appearance = /decl/closet_appearance

	// TODO: Turn these into flags. Skipped it for now because it requires updating 100+ locations...
	var/broken = FALSE
	var/opened = FALSE
	var/locked = FALSE

/obj/structure/closet/Destroy()
	global.closets -= src
	. = ..()

/obj/structure/closet/Initialize()
	..()
	global.closets += src
	if((setup & CLOSET_HAS_LOCK))
		verbs += /obj/structure/closet/proc/togglelock_verb

	if(ispath(closet_appearance))
		var/decl/closet_appearance/app = GET_DECL(closet_appearance)
		if(app)
			icon = app.icon
			reset_color()
			queue_icon_update()

	return INITIALIZE_HINT_LATELOAD

/obj/structure/closet/LateInitialize(mapload, ...)
	var/list/will_contain = WillContain()
	if(will_contain)
		create_objects_in_loc(opened ? loc : src, will_contain)

	if(!opened && mapload) // if closed and it's the map loading phase, relevant items at the crate's loc are put in the contents
		store_contents()

/obj/structure/closet/update_lock_overlay()
	return // TODO

/obj/structure/closet/can_install_lock()
	return !(setup & CLOSET_HAS_LOCK) // CLOSET_HAS_LOCK refers to the access lock, not a physical lock.

/obj/structure/closet/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	if(distance <= 1 && !opened)
		var/content_size = 0
		for(var/atom/movable/AM in contents)
			if(!AM.anchored)
				content_size += content_size(AM)
		if(!content_size)
			. += "It is empty."
		else if(storage_capacity > content_size*4)
			. += "It is barely filled."
		else if(storage_capacity > content_size*2)
			. += "It is less than half full."
		else if(storage_capacity > content_size)
			. += "There is still some free space."
		else
			. += "It is full."

	var/mob/observer/ghost/G = user
	if(isghost(G) && (G.client?.holder || G.antagHUD))
		. += "It contains: [counting_english_list(contents)]"

/obj/structure/closet/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(air_group || (height==0 || wall_mounted)) return 1
	return (!density)

/obj/structure/closet/proc/can_open(mob/user)
	if((setup & CLOSET_HAS_LOCK) && locked)
		return FALSE
	if((setup & CLOSET_CAN_BE_WELDED) && welded)
		return FALSE
	if(lock)
		if(user)
			try_unlock(user, user.get_active_held_item())
		if(lock.isLocked())
			return FALSE
	return TRUE

/obj/structure/closet/proc/can_close(mob/user)
	for(var/obj/structure/closet/closet in get_turf(src))
		if(closet != src)
			return FALSE
	return TRUE

/obj/structure/closet/proc/store_contents()
	var/stored_units = 0

	if(storage_types & CLOSET_STORAGE_ITEMS)
		stored_units += store_items(stored_units)
	if(storage_types & CLOSET_STORAGE_MOBS)
		stored_units += store_mobs(stored_units)
	if(storage_types & CLOSET_STORAGE_STRUCTURES)
		stored_units += store_structures(stored_units)

/obj/structure/closet/proc/open(mob/user)
	if(opened)
		return 0

	if(!can_open(user))
		return 0

	dump_contents()

	opened = TRUE
	playsound(loc, open_sound, 50, 1, -3)
	density = FALSE
	update_icon()
	return TRUE

/obj/structure/closet/proc/close(mob/user)
	if(!opened)
		return 0
	if(!can_close(user))
		return 0

	store_contents()
	opened = 0

	playsound(loc, close_sound, 50, 0, -3)
	if(!wall_mounted)
		density = TRUE

	update_icon()

	return 1

#define CLOSET_CHECK_TOO_BIG(x) (stored_units + . + x > storage_capacity)
/obj/structure/closet/proc/store_items(var/stored_units)
	. = 0

	for(var/obj/effect/dummy/chameleon/AD in loc)
		if(CLOSET_CHECK_TOO_BIG(1))
			break
		.++
		AD.forceMove(src)

	for(var/obj/item/I in loc)
		if(I.anchored)
			continue
		var/item_size = content_size(I)
		if(CLOSET_CHECK_TOO_BIG(item_size))
			break
		. += item_size
		I.forceMove(src)
		I.pixel_x = 0
		I.pixel_y = 0
		I.pixel_z = 0

/obj/structure/closet/proc/store_mobs(var/stored_units)
	. = 0
	for(var/mob/living/M in loc)
		if(M.buckled || LAZYLEN(M.pinned) || M.anchored)
			continue
		var/mob_size = content_size(M)
		if(CLOSET_CHECK_TOO_BIG(mob_size))
			break
		. += mob_size
		if(M.client)
			M.client.perspective = EYE_PERSPECTIVE
			M.client.eye = src
		M.forceMove(src)

/obj/structure/closet/proc/store_structures(var/stored_units)
	. = 0

	for(var/obj/structure/S in loc)
		if(S == src)
			continue
		if(S.anchored)
			continue
		var/structure_size = content_size(S)
		if(CLOSET_CHECK_TOO_BIG(structure_size))
			break
		. += structure_size
		S.forceMove(src)

	for(var/obj/machinery/M in loc)
		if(M.anchored)
			continue
		var/structure_size = content_size(M)
		if(CLOSET_CHECK_TOO_BIG(structure_size))
			break
		. += structure_size
		M.forceMove(src)

#undef CLOSET_CHECK_TOO_BIG

// If you adjust any of the values below, please also update /proc/unit_test_weight_of_path(var/path)
/obj/structure/closet/proc/content_size(atom/movable/AM)
	if(ismob(AM))
		var/mob/M = AM
		return M.mob_size
	if(istype(AM, /obj/item))
		var/obj/item/I = AM
		return (I.w_class / 2)
	if(istype(AM, /obj/structure) || istype(AM, /obj/machinery))
		return MOB_SIZE_LARGE
	return 0

/obj/structure/closet/proc/toggle(mob/user)
	if(locked)
		togglelock(user)
	else if(!(opened ? close(user) : open(user)))
		to_chat(user, "<span class='notice'>It won't budge!</span>")
		update_icon()

/obj/structure/closet/explosion_act(severity)
	..()
	if(!QDELETED(src) && (severity == 1 || (severity == 2 && prob(50)) || (severity == 3 && prob(5))))
		physically_destroyed()

/obj/structure/closet/bullet_act(var/obj/item/projectile/Proj)
	if(Proj.penetrating)
		var/distance = get_dist(Proj.starting, get_turf(loc))
		for(var/mob/living/L in contents)
			Proj.attack_mob(L, distance)
			if(!(--Proj.penetrating))
				break
	var/proj_damage = Proj.get_structure_damage()
	if(proj_damage)
		..()
		take_damage(proj_damage, Proj.atom_damage_type)

// Override this so the logic in attackby() can run.
/obj/structure/closet/grab_attack(obj/item/grab/grab, mob/user)
	return FALSE

/obj/structure/closet/attackby(obj/item/used_item, mob/user)

	if(user.check_intent(I_FLAG_HARM) && used_item.get_attack_force(user))
		return ..()

	if(!opened && (istype(used_item, /obj/item/stack/material) || IS_WRENCH(used_item)) )
		return ..()

	var/can_wield = used_item.user_can_attack_with(user, silent = TRUE)

	if(opened)
		if(can_wield)
			if(istype(used_item, /obj/item/grab))
				var/obj/item/grab/grab = used_item
				receive_mouse_drop(grab.affecting, user)      //act like they were dragged onto the closet
				return TRUE
			if(IS_WELDER(used_item))
				var/obj/item/weldingtool/welder = used_item
				if(welder.weld(0,user))
					slice_into_parts(welder, user)
					return TRUE
			if(istype(used_item, /obj/item/gun/energy/plasmacutter))
				var/obj/item/gun/energy/plasmacutter/cutter = used_item
				if(cutter.slice(user))
					slice_into_parts(used_item, user)
				return TRUE
			if(istype(used_item, /obj/item/laundry_basket) && used_item.contents.len && used_item.storage)
				var/turf/T = get_turf(src)
				for(var/obj/item/I in used_item.storage.get_contents())
					used_item.storage.remove_from_storage(user, I, T, TRUE)
				used_item.storage.finish_bulk_removal()
				user.visible_message(
					SPAN_NOTICE("\The [user] empties \the [used_item] into \the [src]."),
					SPAN_NOTICE("You empty \the [used_item] into \the [src]."),
					SPAN_NOTICE("You hear rustling of clothes.")
				)
				return TRUE

		if(user.try_unequip(used_item, loc))
			used_item.pixel_x = 0
			used_item.pixel_y = 0
			used_item.pixel_z = 0
			used_item.pixel_w = 0
			return TRUE
		return FALSE

	if(!can_wield)
		return attack_hand_with_interaction_checks(user)

	if(try_key_unlock(used_item, user))
		return TRUE

	if(try_install_lock(used_item, user))
		return TRUE

	if(istype(used_item, /obj/item/energy_blade))
		var/obj/item/energy_blade/blade = used_item
		if(blade.is_special_cutting_tool() && emag_act(INFINITY, user, "<span class='danger'>The locker has been sliced open by [user] with \an [used_item]</span>!", "<span class='danger'>You hear metal being sliced and sparks flying.</span>"))
			spark_at(loc, amount=5)
			playsound(loc, 'sound/weapons/blade1.ogg', 50, 1)
			open(user)
		return TRUE

	if(istype(used_item, /obj/item/stack/package_wrap))
		return FALSE //Return false to get afterattack to be called

	if(IS_WELDER(used_item) && (setup & CLOSET_CAN_BE_WELDED))
		var/obj/item/weldingtool/welder = used_item
		if(!welder.weld(0,user))
			if(welder.isOn())
				to_chat(user, SPAN_NOTICE("You need more welding fuel to complete this task."))
			return TRUE
		welded = !welded
		update_icon()
		user.visible_message(SPAN_WARNING("\The [src] has been [welded?"welded shut":"unwelded"] by \the [user]."), blind_message = "You hear welding.", range = 3)
		return TRUE
	else if(setup & CLOSET_HAS_LOCK)
		togglelock(user, used_item)
		return TRUE

	return attack_hand_with_interaction_checks(user)

/obj/structure/closet/proc/slice_into_parts(obj/item/used_item, mob/user)
	user.visible_message(
		SPAN_NOTICE("\The [src] has been cut apart by [user] with \the [used_item]."),
		SPAN_NOTICE("You have cut \the [src] apart with \the [used_item]."),
		"You hear welding."
	)
	physically_destroyed()

/obj/structure/closet/receive_mouse_drop(atom/dropping, mob/user, params)
	. = ..()
	var/atom/movable/AM = dropping
	if(!. && istype(AM) && opened && !istype(AM, /obj/structure/closet) && AM.simulated && !AM.anchored && (large || !ismob(AM)))
		step_towards(AM, loc)
		if(user != AM)
			user.visible_message(SPAN_DANGER("\The [user] stuffs \the [AM] into \the [src]!"), SPAN_DANGER("You stuff \the [AM] into \the [src]!"))
		return TRUE

/obj/structure/closet/attack_ai(mob/living/silicon/ai/user)
	if(isrobot(user)) // Robots can open/close it, but not the AI.
		return attack_hand_with_interaction_checks(user)
	return ..()

/obj/structure/closet/relaymove(mob/user)
	if(user.stat || !isturf(loc))
		return
	if(!open(user))
		to_chat(user, SPAN_WARNING("\The [src] won't budge!"))

/obj/structure/closet/attack_hand(mob/user)
	if(!user.check_dexterity(DEXTERITY_SIMPLE_MACHINES, TRUE))
		return ..()
	add_fingerprint(user)
	toggle(user)
	return TRUE

/obj/structure/closet/attack_ghost(mob/ghost)
	if(ghost.client && ghost.client.inquisitive_ghost)
		ghost.examine_verb(src)
		if (!opened)
			to_chat(ghost, "It contains: [english_list(contents)].")

/obj/structure/closet/verb/verb_toggleopen()
	set src in oview(1)
	set category = "Object"
	set name = "Toggle Open"

	if(!CanPhysicallyInteract(usr))
		return

	if(ishuman(usr))
		add_fingerprint(usr)
		toggle(usr)
	else
		to_chat(usr, "<span class='warning'>This mob type can't use this verb.</span>")

/obj/structure/closet/on_update_icon()
	..()
	if(opened)
		icon_state = "open"
	else if(broken)
		icon_state = "closed_emagged[welded ? "_welded" : ""]"
	else if(locked)
		icon_state = "closed_locked[welded ? "_welded" : ""]"
	else
		icon_state = "closed_unlocked[welded ? "_welded" : ""]"

/obj/structure/closet/proc/req_breakout()
	if(opened)
		return 0 //Door's open... wait, why are you in it's contents then?
	if((setup & CLOSET_HAS_LOCK) && locked)
		return 1 // Closed and locked
	return (!welded) //closed but not welded...

/obj/structure/closet/mob_breakout(var/mob/living/escapee)

	. = ..()
	var/breakout_time = 2 //2 minutes by default
	if(breakout || !req_breakout())
		return FALSE

	. = TRUE
	escapee.setClickCooldown(100)

	//okay, so the closet is either welded or locked... resist!!!
	to_chat(escapee, "<span class='warning'>You lean on the back of \the [src] and start pushing the door open. (this will take about [breakout_time] minutes)</span>")

	visible_message("<span class='danger'>\The [src] begins to shake violently!</span>")

	breakout = 1 //can't think of a better way to do this right now.
	for(var/i in 1 to (6*breakout_time * 2)) //minutes * 6 * 5seconds * 2
		if(!do_after(escapee, 50, incapacitation_flags = INCAPACITATION_DEFAULT & ~INCAPACITATION_RESTRAINED)) //5 seconds
			breakout = 0
			return FALSE
		//Perform the same set of checks as above for weld and lock status to determine if there is even still a point in 'resisting'...
		if(!req_breakout())
			breakout = 0
			return FALSE

		playsound(loc, 'sound/effects/grillehit.ogg', 100, 1)
		shake_animation()
		add_fingerprint(escapee)

	//Well then break it!
	breakout = 0
	to_chat(escapee, "<span class='warning'>You successfully break out!</span>")
	visible_message("<span class='danger'>\The [escapee] successfully broke out of \the [src]!</span>")
	playsound(loc, 'sound/effects/grillehit.ogg', 100, 1)
	QDEL_NULL(lock)
	break_open(escapee)
	shake_animation()

/obj/structure/closet/proc/break_open(mob/user)
	welded = FALSE
	if((setup & CLOSET_HAS_LOCK) && locked)
		make_broken()
	//Do this to prevent contents from being opened into nullspace
	//#TODO: There's probably a better way to do this?
	if(istype(loc, /obj/item/parcel))
		var/obj/item/parcel/P = loc
		P.unwrap()
	open(user)

/obj/structure/closet/onDropInto(var/atom/movable/AM)
	return opened ? loc : null

// If we use the /obj/structure/closet/proc/togglelock variant BYOND asks the user to select an input for id_card, which is then mostly irrelevant.
/obj/structure/closet/proc/togglelock_verb()
	set src in oview(1) // One square distance
	set category = "Object"
	set name = "Toggle Lock"

	return togglelock(usr)

/obj/structure/closet/proc/togglelock(var/mob/user, var/obj/item/card/id/id_card)
	if(!(setup & CLOSET_HAS_LOCK))
		return FALSE
	if(!CanPhysicallyInteract(user))
		return FALSE
	if(opened)
		to_chat(user, "<span class='notice'>Close \the [src] first.</span>")
		return FALSE
	if(broken)
		to_chat(user, "<span class='warning'>\The [src] appears to be broken.</span>")
		return FALSE
	if(user.loc == src)
		to_chat(user, "<span class='notice'>You can't reach the lock from inside.</span>")
		return FALSE

	add_fingerprint(user)

	if(!id_card)
		id_card = user.GetIdCard()

	if(!user.check_dexterity(DEXTERITY_COMPLEX_TOOLS))
		return FALSE

	if(CanToggleLock(user, id_card))
		locked = !locked
		visible_message("<span class='notice'>\The [src] has been [locked ? null : "un"]locked by \the [user].</span>", range = 3)
		update_icon()
		return TRUE
	else
		to_chat(user, "<span class='warning'>Access denied!</span>")
		return FALSE

/obj/structure/closet/proc/CanToggleLock(var/mob/user, var/obj/item/card/id/id_card)
	return allowed(user) || (istype(id_card) && check_access_list(id_card.GetAccess()))

/obj/structure/closet/CtrlAltClick(var/mob/user)
	verb_toggleopen()

/obj/structure/closet/emp_act(severity)
	for(var/obj/O in src)
		O.emp_act(severity)
	if(!broken && (setup & CLOSET_HAS_LOCK))
		if(prob(50/severity))
			locked = !locked
			update_icon()
		if(prob(20/severity) && !opened)
			if(!locked)
				open()
			else
				req_access = list(pick(get_all_station_access()))
	..()

/obj/structure/closet/emag_act(var/remaining_charges, var/mob/user, var/emag_source, var/visual_feedback = "", var/audible_feedback = "")
	if(make_broken())
		update_icon()
		if(visual_feedback)
			visible_message(visual_feedback, audible_feedback)
		else if(user && emag_source)
			visible_message("<span class='warning'>\The [src] has been broken by \the [user] with \an [emag_source]!</span>", "You hear a faint electrical spark.")
		else
			visible_message("<span class='warning'>\The [src] sparks and breaks open!</span>", "You hear a faint electrical spark.")
		return 1
	else
		. = ..()

/obj/structure/closet/proc/make_broken()
	if(broken)
		return FALSE
	if(!(setup & CLOSET_HAS_LOCK))
		return FALSE
	broken = TRUE
	locked = FALSE
	desc += " It appears to be broken."
	return TRUE

/obj/structure/closet/CanUseTopicPhysical(mob/user)
	return CanUseTopic(user, global.physical_no_access_topic_state)

/obj/structure/closet/get_alt_interactions(var/mob/user)
	. = ..()
	LAZYADD(., /decl/interaction_handler/closet_lock_toggle)

/decl/interaction_handler/closet_lock_toggle
	name = "Toggle Lock"
	expected_target_type = /obj/structure/closet
	examine_desc = "toggle the lock"

/decl/interaction_handler/closet_lock_toggle/is_possible(atom/target, mob/user, obj/item/prop)
	. = ..()
	if(.)
		var/obj/structure/closet/C = target
		. = !C.opened && (C.setup & CLOSET_HAS_LOCK)

/decl/interaction_handler/closet_lock_toggle/invoked(atom/target, mob/user, obj/item/prop)
	var/obj/structure/closet/C = target
	C.togglelock(user)
