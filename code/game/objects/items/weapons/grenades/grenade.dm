/obj/item/grenade
	name = "grenade"
	desc = "A hand held grenade, with an adjustable timer."
	w_class = ITEM_SIZE_SMALL
	icon = 'icons/obj/items/grenades/grenade.dmi'
	icon_state = ICON_STATE_WORLD
	throw_speed = 4
	throw_range = 20
	obj_flags = OBJ_FLAG_CONDUCTIBLE | OBJ_FLAG_HOLLOW
	slot_flags = SLOT_LOWER_BODY
	z_flags = ZMM_MANGLE_PLANES
	material = /decl/material/solid/metal/steel
	var/active
	var/det_time = 50
	var/fail_det_time = 5 // If you are clumsy and fail, you get this time.
	var/arm_sound = 'sound/weapons/armbomb.ogg'

/obj/item/grenade/dropped(mob/user)
	. = ..()
	if(active)
		update_icon()

/obj/item/grenade/equipped(mob/user)
	. = ..()
	if(active)
		update_icon()

/obj/item/grenade/on_update_icon()
	. = ..()
	z_flags &= ~ZMM_MANGLE_PLANES
	if(active)
		if(check_state_in_icon("[icon_state]-active", icon))
			if(plane == HUD_PLANE)
				add_overlay("[icon_state]-active")
			else
				add_overlay(emissive_overlay(icon, "[icon_state]-active"))
				z_flags |= ZMM_MANGLE_PLANES
	else if(check_state_in_icon("[icon_state]-pin", icon))
		add_overlay("[icon_state]-pin")

/obj/item/grenade/proc/clown_check(var/mob/living/user)
	if(user.has_genetic_condition(GENE_COND_CLUMSY) && prob(50))
		to_chat(user, "<span class='warning'>Huh? How does this thing work?</span>")
		det_time = fail_det_time
		activate(user)
		add_fingerprint(user)
		return 0
	return 1

/obj/item/grenade/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	if(distance <= 0 && !isnull(det_time))
		if(det_time > 1)
			. += "The timer is set to [det_time/10] seconds."
		else
			. += "\The [src] is set for instant detonation."

/obj/item/grenade/attack_self(mob/user)
	if(active)
		return
	if(!user.check_dexterity(DEXTERITY_WEAPONS))
		return TRUE // prevent further interactions
	if(clown_check(user))
		to_chat(user, "<span class='warning'>You prime \the [name]! [det_time/10] seconds!</span>")
		activate(user)
		add_fingerprint(user)
		user.toggle_throw_mode(TRUE)

/obj/item/grenade/proc/activate(mob/user)
	if(active)
		return
	if(user)
		msg_admin_attack("[user.name] ([user.ckey]) primed \a [src] (<A HREF='byond://?_src_=holder;adminplayerobservecoodjump=1;X=[user.x];Y=[user.y];Z=[user.z]'>JMP</a>)")
	active = TRUE
	update_icon()
	playsound(loc, arm_sound, 75, 0, -3)
	addtimer(CALLBACK(src, PROC_REF(detonate)), det_time)

/obj/item/grenade/proc/detonate()
	var/turf/T = get_turf(src)
	if(T)
		T.hotspot_expose(700,125)

/obj/item/grenade/attackby(obj/item/used_item, mob/user)
	if(IS_SCREWDRIVER(used_item))
		switch(det_time)
			if (1)
				det_time = 10
				to_chat(user, SPAN_NOTICE("You set \the [src] for 1 second detonation time."))
			if (10)
				det_time = 30
				to_chat(user, SPAN_NOTICE("You set \the [src] for 3 second detonation time."))
			if (30)
				det_time = 50
				to_chat(user, SPAN_NOTICE("You set \the [src] for 5 second detonation time."))
			if (50)
				det_time = 1
				to_chat(user, SPAN_NOTICE("You set \the [src] for instant detonation."))
		add_fingerprint(user)
		return TRUE
	return ..()
