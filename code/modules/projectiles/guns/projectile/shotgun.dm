/obj/item/gun/projectile/shotgun/pump
	name = "shotgun"
	desc = "The mass-produced W-T Remington 29x shotgun is a favourite of police and security forces on many worlds. Useful for sweeping alleys."
	icon = 'icons/obj/guns/shotgun/pump.dmi'
	icon_state = ICON_STATE_WORLD
	max_shells = 4
	w_class = ITEM_SIZE_HUGE
	_base_attack_force = 10
	obj_flags =  OBJ_FLAG_CONDUCTIBLE
	slot_flags = SLOT_BACK
	caliber = CALIBER_SHOTGUN
	origin_tech = @'{"combat":4,"materials":2}'
	load_method = SINGLE_CASING
	ammo_type = /obj/item/ammo_casing/shotgun/beanbag
	handle_casings = HOLD_CASINGS
	one_hand_penalty = 8
	bulk = 6
	var/recentpump = 0 // to prevent spammage
	load_sound = 'sound/weapons/guns/interaction/shotgun_instert.ogg'

/obj/item/gun/projectile/shotgun/update_base_icon_state()
	if(length(loaded))
		icon_state = get_world_inventory_state()
	else
		icon_state = "[get_world_inventory_state()]-empty"

/obj/item/gun/projectile/shotgun/pump/consume_next_projectile()
	if(chambered)
		return chambered.BB
	return null

/obj/item/gun/projectile/shotgun/pump/attack_self(mob/user)
	if(!user_can_attack_with(user))
		return TRUE
	if(world.time >= recentpump + 10)
		pump(user)
		recentpump = world.time

/obj/item/gun/projectile/shotgun/pump/proc/pump(mob/M)
	playsound(M, 'sound/weapons/shotgunpump.ogg', 60, 1)

	if(chambered)//We have a shell in the chamber
		chambered.dropInto(loc)//Eject casing
		if(chambered.drop_sound)
			playsound(loc, pick(chambered.drop_sound), 50, 1)
		chambered = null

	if(loaded.len)
		var/obj/item/ammo_casing/AC = loaded[1] //load next casing.
		loaded -= AC //Remove casing from loaded list.
		chambered = AC

	update_icon()

/obj/item/gun/projectile/shotgun/doublebarrel
	name = "double-barreled shotgun"
	desc = "A true classic."
	icon = 'icons/obj/guns/shotgun/doublebarrel.dmi'
	//SPEEDLOADER because rapid unloading.
	//In principle someone could make a speedloader for it, so it makes sense.
	load_method = SINGLE_CASING|SPEEDLOADER
	handle_casings = CYCLE_CASINGS
	max_shells = 2
	w_class = ITEM_SIZE_HUGE
	_base_attack_force = 10
	obj_flags =  OBJ_FLAG_CONDUCTIBLE
	slot_flags = SLOT_BACK
	caliber = CALIBER_SHOTGUN
	origin_tech = @'{"combat":3,"materials":1}'
	ammo_type = /obj/item/ammo_casing/shotgun/beanbag
	one_hand_penalty = 2

	burst_delay = 0
	firemodes = list(
		list(mode_name="fire one barrel at a time", burst=1),
		list(mode_name="fire both barrels at once", burst=2),
		)

/obj/item/gun/projectile/shotgun/doublebarrel/unload_ammo(user, allow_dump)
	return ..(user, allow_dump=1)

//this is largely hacky and bad :(	-Pete
/obj/item/gun/projectile/shotgun/doublebarrel/attackby(var/obj/item/used_item, mob/user)
	if(w_class > ITEM_SIZE_NORMAL && used_item.get_tool_quality(TOOL_SAW) > 0)
		if(istype(used_item, /obj/item/gun/energy/plasmacutter))
			var/obj/item/gun/energy/plasmacutter/cutter = used_item
			if(!cutter.slice(user))
				return ..()
		to_chat(user, "<span class='notice'>You begin to shorten the barrel of \the [src].</span>")
		if(loaded.len)
			for(var/i in 1 to max_shells)
				Fire(user, user)	//will this work? //it will. we call it twice, for twice the FUN
			user.visible_message("<span class='danger'>The shotgun goes off!</span>", "<span class='danger'>The shotgun goes off in your face!</span>")
			return TRUE
		if(!do_after(user, 3 SECONDS, src))	//SHIT IS STEALTHY EYYYYY
			return TRUE
		user.try_unequip(src)
		var/obj/item/gun/projectile/shotgun/doublebarrel/sawn/empty/buddy = new(loc)
		transfer_fingerprints_to(buddy)
		qdel(src)
		to_chat(user, "<span class='warning'>You shorten the barrel of \the [src]!</span>")
		return TRUE
	else
		return ..()

/obj/item/gun/projectile/shotgun/doublebarrel/sawn
	name = "sawn-off shotgun"
	desc = "Omar's coming!"
	icon = 'icons/obj/guns/shotgun/sawnoff.dmi'
	slot_flags = SLOT_LOWER_BODY|SLOT_HOLSTER
	ammo_type = /obj/item/ammo_casing/shotgun/pellet
	w_class = ITEM_SIZE_NORMAL
	one_hand_penalty = 4
	bulk = 2

/obj/item/gun/projectile/shotgun/doublebarrel/sawn/empty
	starts_loaded = FALSE

/obj/item/gun/projectile/shotgun/doublebarrel/quad
	name = "quad-barreled shotgun"
	desc = "A true classic - but doubled. Firing it has a heck of a kick - knocks the air right out of you."
	icon = 'icons/obj/guns/shotgun/quadbarrel.dmi'
	max_shells = 4
	w_class = ITEM_SIZE_HUGE
	origin_tech = @'{"combat":6,"materials":3,"esoteric":9}'
	firemodes = list(
		list(mode_name="fire one barrel at a time", burst=1),
		list(mode_name="fire two barrels at once", burst=2),
		list(mode_name="fire all barrels at once", burst=4)
	)

/obj/item/gun/projectile/shotgun/doublebarrel/quad/empty
	starts_loaded = FALSE
