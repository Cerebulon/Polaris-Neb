/obj/item/assembly_holder
	name = "Assembly"
	icon = 'icons/obj/assemblies/new_assemblies.dmi'
	icon_state = "holder"
	item_state = "assembly"
	movable_flags = MOVABLE_FLAG_PROXMOVE
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	w_class = ITEM_SIZE_SMALL
	throw_speed = 3
	throw_range = 10
	is_spawnable_type = FALSE

	var/secured = 0
	var/obj/item/assembly/a_left = null
	var/obj/item/assembly/a_right = null
	var/obj/special_assembly = null

/obj/item/assembly_holder/Initialize()
	. = ..()
	global.listening_objects += src

/obj/item/assembly_holder/Destroy()
	if(!QDELETED(a_left))
		a_left.holder = null
		QDEL_NULL(a_left)
	else
		a_left = null
	if(!QDELETED(a_right))
		a_right.holder = null
		QDEL_NULL(a_right)
	else
		a_right = null
	if(!QDELETED(special_assembly))
		QDEL_NULL(special_assembly)
	else
		special_assembly = null
	return ..()

/obj/item/assembly_holder/proc/attach(var/obj/item/left_item, var/obj/item/right_item, var/mob/user)
	if(!istype(left_item) || !istype(right_item))
		return 0
	var/obj/item/assembly/left = left_item
	var/obj/item/assembly/right = right_item
	if((left.secured)||(right.secured))
		return 0
	if(user)
		user.drop_from_inventory(left)
		user.drop_from_inventory(right)
	left.holder = src
	right.holder = src
	left.forceMove(src)
	right.forceMove(src)
	a_left = left
	a_right = right
	SetName("[left.name]-[right.name] assembly")
	update_icon()
	usr.put_in_hands(src)

	return 1

/obj/item/assembly_holder/proc/process_activation(var/atom/activator, var/normal = 1, var/special = 1)
	if(!activator)	return 0
	if(!secured)
		visible_message("[html_icon(src)] *beep* *beep*", "*beep* *beep*")
	if((normal) && (a_right) && (a_left))
		if(a_right != activator)
			a_right.pulsed(0)
		if(a_left != activator)
			a_left.pulsed(0)
	if(master)
		master.receive_signal()
//	if(special && special_assembly)
//		if(!special_assembly == activator)
//			special_assembly.dothings()
	return 1

/obj/item/assembly_holder/proc/detached()
	return

/obj/item/assembly_holder/HasProximity(atom/movable/AM)
	. = ..()
	if(.)
		if(a_left)
			a_left.HasProximity(AM)
		if(a_right)
			a_right.HasProximity(AM)
		if(special_assembly)
			special_assembly.HasProximity(AM)


/obj/item/assembly_holder/Crossed(atom/movable/AM)
	if(a_left)
		a_left.Crossed(AM)
	if(a_right)
		a_right.Crossed(AM)
	if(special_assembly)
		special_assembly.Crossed(AM)

/obj/item/assembly_holder/on_found(mob/finder as mob)
	if(a_left)
		a_left.on_found(finder)
	if(a_right)
		a_right.on_found(finder)
	if(special_assembly)
		if(istype(special_assembly, /obj/item))
			var/obj/item/S = special_assembly
			S.on_found(finder)

/obj/item/assembly_holder/Move()
	. = ..()
	if(. && a_left && a_right)
		a_left.holder_movement()
		a_right.holder_movement()

/obj/item/assembly_holder/attack_hand()//Perhapse this should be a holder_pickup proc instead, can add if needbe I guess
	if(a_left && a_right)
		a_left.holder_movement()
		a_right.holder_movement()
	return ..()

/obj/item/assembly_holder/attackby(obj/item/used_item, mob/user)
	if(IS_SCREWDRIVER(used_item))
		if(!a_left || !a_right)
			to_chat(user, "<span class='warning'>BUG:Assembly part missing, please report this!</span>")
			return TRUE
		a_left.toggle_secure()
		a_right.toggle_secure()
		secured = !secured
		if(secured)
			to_chat(user, "<span class='notice'>\The [src] is ready!</span>")
		else
			to_chat(user, "<span class='notice'>\The [src] can now be taken apart!</span>")
		update_icon()
		return TRUE
	return ..()

/obj/item/assembly_holder/attack_self(mob/user as mob)
	src.add_fingerprint(user)
	if(src.secured)
		if(!a_left || !a_right)
			to_chat(user, "<span class='warning'>Assembly part missing!</span>")
			return
		if(istype(a_left,a_right.type))//If they are the same type it causes issues due to window code
			switch(alert("Which side would you like to use?",,"Left","Right"))
				if("Left")	a_left.attack_self(user)
				if("Right")	a_right.attack_self(user)
			return
		else
			if(!istype(a_left,/obj/item/assembly/igniter))
				a_left.attack_self(user)
			if(!istype(a_right,/obj/item/assembly/igniter))
				a_right.attack_self(user)
	else
		var/turf/T = get_turf(src)
		if(!T)	return 0
		if(a_left)
			a_left.holder = null
			a_left.forceMove(T)
		if(a_right)
			a_right.holder = null
			a_right.forceMove(T)
		qdel(src)
	return

/obj/item/assembly_holder/hear_talk(mob/living/M, msg, verb, decl/language/speaking)
	if(a_right)
		a_right.hear_talk(M,msg,verb,speaking)
	if(a_left)
		a_left.hear_talk(M,msg,verb,speaking)

/obj/item/assembly_holder/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	if (distance <= 1 || src.loc == user)
		if (src.secured)
			. += "\The [src] is ready!"
		else
			. += "\The [src] can be attached!"

/obj/item/assembly_holder/on_update_icon()
	. = ..()
	if(a_left)
		var/list/left_overlays = list(overlay_image(icon, "[a_left.icon_state]_left"))
		for(var/O in a_left.attached_overlays)
			left_overlays += "[O]_l"
		add_overlay(left_overlays)
	if(a_right)
		var/list/right_overlays = list(overlay_image(icon, "[a_right.icon_state]_right"))
		for(var/O in a_right.attached_overlays)
			right_overlays += "[O]_r"
		add_overlay(right_overlays)
	if(master)
		master.update_icon()

/obj/item/assembly_holder/timer_igniter
	name = "timer-igniter assembly"

/obj/item/assembly_holder/timer_igniter/Initialize()
	. = ..()

	var/obj/item/assembly/igniter/ign = new(src)
	ign.secured = 1
	ign.holder = src
	var/obj/item/assembly/timer/tmr = new(src)
	tmr.time=5
	tmr.secured = 1
	tmr.holder = src
	START_PROCESSING(SSobj, tmr)
	a_left = tmr
	a_right = ign
	secured = 1
	update_icon()
	SetName(initial(name) + " ([tmr.time] secs)")

	loc.verbs += /obj/item/assembly_holder/timer_igniter/verb/configure

/obj/item/assembly_holder/timer_igniter/detached()
	loc.verbs -= /obj/item/assembly_holder/timer_igniter/verb/configure
	..()

/obj/item/assembly_holder/timer_igniter/verb/configure()
	set name = "Set Timer"
	set category = "Object"
	set src in usr

	if ( !(usr.stat || usr.restrained()) )
		var/obj/item/assembly_holder/holder
		if(istype(src,/obj/item/grenade/chem_grenade))
			var/obj/item/grenade/chem_grenade/gren = src
			holder=gren.detonator
		var/obj/item/assembly/timer/tmr = holder.a_left
		if(!istype(tmr,/obj/item/assembly/timer))
			tmr = holder.a_right
		if(!istype(tmr,/obj/item/assembly/timer))
			to_chat(usr, "<span class='notice'>This detonator has no timer.</span>")
			return

		if(tmr.timing)
			to_chat(usr, "<span class='notice'>Clock is ticking already.</span>")
		else
			var/ntime = input("Enter desired time in seconds", "Time", "5") as num
			if (ntime>0 && ntime<1000)
				tmr.time = ntime
				SetName(initial(name) + "([tmr.time] secs)")
				to_chat(usr, "<span class='notice'>Timer set to [tmr.time] seconds.</span>")
			else
				to_chat(usr, "<span class='notice'>Timer can't be [ntime<=0?"negative":"more than 1000 seconds"].</span>")
	else
		to_chat(usr, "<span class='notice'>You cannot do this while [usr.stat?"unconscious/dead":"restrained"].</span>")