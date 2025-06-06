/obj/item/syringe_cartridge
	name = "syringe gun cartridge"
	desc = "An impact-triggered compressed gas cartridge that can be fitted to a syringe for rapid injection."
	icon = 'icons/obj/ammo.dmi'
	icon_state = "syringe-cartridge"
	material = /decl/material/solid/metal/steel
	matter = list(/decl/material/solid/fiberglass = MATTER_AMOUNT_REINFORCEMENT)
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	slot_flags = SLOT_LOWER_BODY | SLOT_EARS
	w_class = ITEM_SIZE_SMALL
	var/icon_flight = "syringe-cartridge-flight" //so it doesn't look so weird when shot
	var/obj/item/chems/syringe/syringe

/obj/item/syringe_cartridge/on_update_icon()
	. = ..()
	underlays.Cut()
	if(syringe)
		var/mutable_appearance/MA = new /mutable_appearance(syringe)
		MA.pixel_x = 0
		MA.pixel_y = 0
		MA.pixel_w = 0
		MA.pixel_z = 0
		MA.layer = FLOAT_LAYER
		MA.plane = FLOAT_PLANE
		underlays += MA

/obj/item/syringe_cartridge/attackby(obj/item/used_item, mob/user)
	if(istype(used_item, /obj/item/chems/syringe))
		if(!user.try_unequip(used_item, src))
			return TRUE
		syringe = used_item
		to_chat(user, "<span class='notice'>You carefully insert [syringe] into [src].</span>")
		set_sharp(TRUE)
		name = "syringe dart"
		update_icon()
		return TRUE
	return ..()

/obj/item/syringe_cartridge/attack_self(mob/user)
	if(syringe)
		to_chat(user, "<span class='notice'>You remove [syringe] from [src].</span>")
		user.put_in_hands(syringe)
		syringe = null
		set_sharp(initial(sharp))
		SetName(initial(name))
		update_icon()

/obj/item/syringe_cartridge/proc/prime()
	//the icon state will revert back when update_icon() is called from throw_impact()
	icon_state = icon_flight
	underlays.Cut()

/obj/item/syringe_cartridge/throw_impact(atom/hit_atom, var/datum/thrownthing/TT)
	..() //handles embedding for us. Should have a decent chance if thrown fast enough
	if(syringe)
		//check speed to see if we hit hard enough to trigger the rapid injection
		//incidentally, this means syringe_cartridges can be used with the pneumatic launcher
		if(TT.speed >= 10 && isliving(hit_atom))
			var/mob/living/L = hit_atom
			//unfortuately we don't know where the dart will actually hit, since that's done by the parent.
			if(L.can_inject(null, ran_zone(TT.target_zone, 30, L)) == CAN_INJECT && syringe.reagents)
				var/reagent_log = syringe.reagents.get_reagents()
				syringe.reagents.trans_to_mob(L, syringe.reagents.total_volume, CHEM_INJECT)
				admin_inject_log(TT.thrower? TT.thrower : null, L, src, reagent_log, 15, violent=1)

		syringe.break_syringe(ishuman(hit_atom)? hit_atom : null)
		syringe.update_icon()

	icon_state = initial(icon_state) //reset icon state
	update_icon()

/obj/item/gun/launcher/syringe
	name = "syringe gun"
	desc = "A spring-loaded rifle designed to fit syringes, designed to incapacitate unruly patients from a distance."
	icon = 'icons/obj/guns/launcher/syringe.dmi'
	icon_state = ICON_STATE_WORLD
	w_class = ITEM_SIZE_LARGE
	_base_attack_force = 7
	material = /decl/material/solid/metal/steel
	slot_flags = SLOT_LOWER_BODY

	fire_sound = 'sound/weapons/empty.ogg'
	fire_sound_text = "a metallic thunk"
	screen_shake = 0
	release_force = 10
	throw_distance = 10

	var/list/darts = list()
	var/max_darts = 1
	var/obj/item/syringe_cartridge/next

/obj/item/gun/launcher/syringe/consume_next_projectile()
	if(next)
		next.prime()
		return next
	return null

/obj/item/gun/launcher/syringe/handle_post_fire()
	..()
	darts -= next
	next = null

/obj/item/gun/launcher/syringe/attack_self(mob/user)
	if(next)
		user.visible_message("[user] unlatches and carefully relaxes the bolt on [src].", "<span class='warning'>You unlatch and carefully relax the bolt on [src], unloading the spring.</span>")
		next = null
	else if(darts.len)
		playsound(src.loc, 'sound/weapons/flipblade.ogg', 50, 1)
		user.visible_message("[user] draws back the bolt on [src], clicking it into place.", "<span class='warning'>You draw back the bolt on \the [src], loading the spring!</span>")
		next = darts[1]
	add_fingerprint(user)

/obj/item/gun/launcher/syringe/attack_hand(mob/user)
	if(!user.is_holding_offhand(src) || !user.check_dexterity(DEXTERITY_HOLD_ITEM, TRUE))
		return ..()
	if(!darts.len)
		to_chat(user, SPAN_WARNING("\The [src] is empty."))
		return TRUE
	if(next)
		to_chat(user, SPAN_WARNING("\The [src]'s cover is locked shut."))
		return TRUE
	var/obj/item/syringe_cartridge/C = darts[1]
	darts -= C
	user.put_in_hands(C)
	user.visible_message(
		SPAN_NOTICE("\The [user] removes \a [C] from \the [src]."),
		SPAN_NOTICE("You remove \a [C] from \the [src].")
	)
	return TRUE

/obj/item/gun/launcher/syringe/attackby(var/obj/item/used_item, mob/user)
	if(istype(used_item, /obj/item/syringe_cartridge))
		var/obj/item/syringe_cartridge/C = used_item
		if(darts.len >= max_darts)
			to_chat(user, "<span class='warning'>[src] is full!</span>")
			return TRUE
		if(!user.try_unequip(C, src))
			return TRUE
		darts += C //add to the end
		user.visible_message("[user] inserts \a [C] into [src].", "<span class='notice'>You insert \a [C] into [src].</span>")
		return TRUE
	else
		return ..()

/obj/item/gun/launcher/syringe/rapid
	name = "syringe gun revolver"
	desc = "A modification of the syringe gun design, using a rotating cylinder to store up to five syringes. The spring still needs to be drawn between shots."
	icon = 'icons/obj/guns/launcher/syringe_rapid.dmi'
	max_darts = 5
	material = /decl/material/solid/metal/steel
	matter = list(/decl/material/solid/fiberglass = MATTER_AMOUNT_REINFORCEMENT)

/obj/item/gun/launcher/syringe/disguised
	name = "deluxe electronic cigarette"
	desc = "A premium model eHavana MK3 electronic cigarette, shaped like a cigar."
	icon = 'icons/clothing/mask/smokables/cigarette_electronic_deluxe.dmi'
	icon_state = ICON_STATE_WORLD
	w_class = ITEM_SIZE_SMALL
	_base_attack_force = 3
	throw_distance = 7
	release_force = 10

/obj/item/gun/launcher/syringe/disguised/on_update_icon()
	. = ..()
	add_overlay("[icon_state]-loaded")

/obj/item/gun/launcher/syringe/disguised/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	if(distance <= 1)
		. += "The button is a little stiff."
