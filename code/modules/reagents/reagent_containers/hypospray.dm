////////////////////////////////////////////////////////////////////////////////
/// HYPOSPRAY
////////////////////////////////////////////////////////////////////////////////

/obj/item/chems/hypospray // abstract shared type, do not use directly
	name = "hypospray"
	desc = "A sterile, air-needle autoinjector for rapid administration of drugs to patients."
	icon = 'icons/obj/hypospray.dmi'
	icon_state = ICON_STATE_WORLD
	abstract_type = /obj/item/chems/hypospray
	origin_tech = @'{"materials":4,"biotech":5}'
	amount_per_transfer_from_this = 5
	volume = 30
	possible_transfer_amounts = null
	atom_flags = ATOM_FLAG_OPEN_CONTAINER
	slot_flags = SLOT_LOWER_BODY
	material = /decl/material/solid/organic/plastic
	matter = list(
		/decl/material/solid/fiberglass = MATTER_AMOUNT_REINFORCEMENT,
		/decl/material/solid/metal/aluminium = MATTER_AMOUNT_TRACE,
		/decl/material/solid/metal/silver = MATTER_AMOUNT_TRACE
	)

	// autoinjectors takes less time than a normal syringe (overriden for hypospray).
	// This delay is only applied when injecting conscious mobs, and is not applied for self-injection
	// The 1.9 factor scales it so it takes the following number of seconds:
	// NONE   1.47
	// BASIC  1.00
	// ADEPT  0.68
	// EXPERT 0.53
	// PROF   0.39
	var/time = (1 SECONDS) / 1.9
	var/single_use = TRUE // autoinjectors are not refillable (overriden for hypospray)

/obj/item/chems/hypospray/on_update_icon()
	icon_state = get_world_inventory_state()
	. = ..()

/obj/item/chems/hypospray/use_on_mob(mob/living/target, mob/living/user, animate = TRUE)

	if(!reagents?.total_volume)
		to_chat(user, SPAN_WARNING("\The [src] is empty."))
		return TRUE

	var/allow = target.can_inject(user, check_zone(user.get_target_zone(), target))
	if(!allow)
		return TRUE

	if (allow == INJECTION_PORT)
		if(target != user)
			user.visible_message(SPAN_WARNING("\The [user] begins hunting for an injection port on \the [target]'s suit!"))
		else
			to_chat(user, SPAN_NOTICE("You begin hunting for an injection port on your suit."))
		if(!user.do_skilled(INJECTION_PORT_DELAY, SKILL_MEDICAL, target))
			return TRUE

	user.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
	user.do_attack_animation(target)

	if(user != target && !target.incapacitated() && time) // you're injecting someone else who is conscious, so apply the device's intrisic delay
		to_chat(user, SPAN_WARNING("\The [user] is trying to inject \the [target] with \the [name]."))
		if(!user.do_skilled(time, SKILL_MEDICAL, target))
			return TRUE

	if(single_use && reagents.total_volume <= 0) // currently only applies to autoinjectors
		atom_flags &= ~ATOM_FLAG_OPEN_CONTAINER // Prevents autoinjectors to be refilled.

	to_chat(user, SPAN_NOTICE("You inject [target] with [src]."))
	to_chat(target, SPAN_NOTICE("You feel a tiny prick!"))
	playsound(src, 'sound/effects/hypospray.ogg',25)
	user.visible_message(SPAN_WARNING("[user] injects [target] with [src]."))

	if(target.reagents)
		var/contained = REAGENT_LIST(src)
		var/trans = reagents.trans_to_mob(target, amount_per_transfer_from_this, CHEM_INJECT)
		admin_inject_log(user, target, src, contained, trans)
		to_chat(user, SPAN_NOTICE("[trans] unit\s injected. [reagents.total_volume] unit\s remaining in \the [src]."))

	return TRUE

////////////////////////////////////////////////////////////////////////////////
/// VIAL HYPOSPRAY
////////////////////////////////////////////////////////////////////////////////
/obj/item/chems/hypospray/vial
	name = "hypospray"
	desc = "A sterile, air-needle autoinjector for rapid administration of drugs to patients. Uses a replaceable 30u vial."
	possible_transfer_amounts = @"[1,2,5,10,15,20,30]"
	amount_per_transfer_from_this = 5
	volume = 0
	time = 0 // hyposprays are instant for conscious people
	single_use = FALSE
	material = /decl/material/solid/metal/steel
	var/obj/item/chems/glass/beaker/vial/loaded_vial

/obj/item/chems/hypospray/vial/Initialize()
	. = ..()
	create_contents()

/obj/item/chems/hypospray/vial/proc/create_contents()
	insert_vial(new /obj/item/chems/glass/beaker/vial(src))

/obj/item/chems/hypospray/vial/proc/insert_vial(var/obj/item/chems/glass/beaker/vial/V, var/mob/user)
	if(user && !user.try_unequip(V, src))
		return

	var/usermessage = ""
	if(loaded_vial)
		remove_vial(user, "swap", FALSE)
		usermessage = "You load \the [V] into \the [src] as you remove the old one."
	else
		usermessage = "You load \the [V] into \the [src]."

	if(ATOM_IS_OPEN_CONTAINER(V))
		V.atom_flags ^= ATOM_FLAG_OPEN_CONTAINER
		V.update_icon()

	loaded_vial = V
	reagents.maximum_volume = loaded_vial.reagents.maximum_volume
	loaded_vial.reagents.trans_to_holder(reagents, volume)

	if(user)
		user.visible_message(SPAN_NOTICE("[user] has loaded [V] into \the [src]."), SPAN_NOTICE("[usermessage]"))

	update_icon()
	playsound(loc, 'sound/weapons/empty.ogg', 50, TRUE)
	return TRUE

/obj/item/chems/hypospray/vial/proc/remove_vial(var/mob/user, var/swap_mode, var/should_update_icon = TRUE)
	if(!loaded_vial)
		return
	reagents.trans_to_holder(loaded_vial.reagents,volume)
	reagents.maximum_volume = 0
	loaded_vial.update_icon()
	if(user)
		user.put_in_hands(loaded_vial)
	loaded_vial = null
	if(user)
		if (swap_mode != "swap") // if swapping vials, we will print a different message in another proc
			to_chat(user, "You remove the vial from \the [src].")
	playsound(loc, 'sound/weapons/flipblade.ogg', 50, TRUE)
	if(should_update_icon)
		update_icon()
	return TRUE

/obj/item/chems/hypospray/vial/attack_hand(mob/user)
	if(!user.is_holding_offhand(src) || !user.check_dexterity(DEXTERITY_HOLD_ITEM, TRUE))
		return ..()
	if(!loaded_vial)
		to_chat(user, SPAN_NOTICE("There is no vial loaded in \the [src]."))
	else
		remove_vial(user)
	return TRUE

/obj/item/chems/hypospray/vial/attackby(obj/item/used_item, mob/user)
	if(!istype(used_item, /obj/item/chems/glass/beaker/vial))
		return ..()
	if(!do_after(user, 1 SECOND, src))
		return TRUE
	insert_vial(used_item, user)
	return TRUE

/obj/item/chems/hypospray/vial/afterattack(obj/target, mob/user, proximity) // hyposprays can be dumped into, why not out? uses standard_pour_into helper checks.
	if(!proximity)
		return
	standard_pour_into(user, target)

////////////////////////////////////////////////////////////////////////////////
/// AUTOINJECTOR
////////////////////////////////////////////////////////////////////////////////
/obj/item/chems/hypospray/autoinjector
	name = "autoinjector"
	desc = "A rapid and safe way to administer small amounts of drugs by untrained or trained personnel."
	icon = 'icons/obj/autoinjector.dmi'
	amount_per_transfer_from_this = 5
	volume = 5
	origin_tech = @'{"materials":2,"biotech":2}'
	slot_flags = SLOT_LOWER_BODY | SLOT_EARS
	w_class = ITEM_SIZE_SMALL
	detail_state = "_band"
	detail_color = COLOR_CYAN
	abstract_type = /obj/item/chems/hypospray/autoinjector
	var/autolabel = TRUE  		// if set, will add label with the name of the first initial reagent

/obj/item/chems/hypospray/autoinjector/Initialize()
	. = ..()
	if(label_text)
		update_name()
	update_icon()

/obj/item/chems/hypospray/autoinjector/populate_reagents()
	SHOULD_CALL_PARENT(TRUE)
	. = ..()
	if(reagents?.total_volume > 0 && autolabel && !label_text) // don't override preset labels
		label_text = "[reagents.get_primary_reagent_name()], [reagents.total_volume]u"

/obj/item/chems/hypospray/autoinjector/use_on_mob(mob/living/target, mob/living/user, animate = TRUE)
	. = ..()
	if(.)
		update_icon()

/obj/item/chems/hypospray/autoinjector/on_update_icon()
	. = ..()
	if(reagents?.total_volume <= 0)
		icon_state = "[icon_state]_used"

/obj/item/chems/hypospray/autoinjector/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..(user)
	if(reagents?.total_volume)
		. += SPAN_NOTICE("It is currently loaded.")
	else
		. += SPAN_NOTICE("It is spent.")

////////////////////////////////////////////////////////////////////////////////
// Autoinjector - Stabilizer
////////////////////////////////////////////////////////////////////////////////
/obj/item/chems/hypospray/autoinjector/stabilizer/populate_reagents()
	add_to_reagents(/decl/material/liquid/stabilizer, reagents.maximum_volume)
	. = ..()

////////////////////////////////////////////////////////////////////////////////
// Autoinjector - Adrenaline
////////////////////////////////////////////////////////////////////////////////
/obj/item/chems/hypospray/autoinjector/adrenaline/populate_reagents()
	add_to_reagents(/decl/material/liquid/adrenaline, reagents.maximum_volume)
	. = ..()

////////////////////////////////////////////////////////////////////////////////
// Autoinjector - Detox
////////////////////////////////////////////////////////////////////////////////
/obj/item/chems/hypospray/autoinjector/detox
	detail_color = COLOR_GREEN

/obj/item/chems/hypospray/autoinjector/detox/populate_reagents()
	add_to_reagents(/decl/material/liquid/antitoxins, reagents.maximum_volume)
	. = ..()

////////////////////////////////////////////////////////////////////////////////
// Autoinjector - Pain
////////////////////////////////////////////////////////////////////////////////
/obj/item/chems/hypospray/autoinjector/pain
	detail_color = COLOR_PURPLE

/obj/item/chems/hypospray/autoinjector/pain/populate_reagents()
	add_to_reagents(/decl/material/liquid/painkillers, reagents.maximum_volume)
	. = ..()

////////////////////////////////////////////////////////////////////////////////
// Autoinjector - Antirad
////////////////////////////////////////////////////////////////////////////////
/obj/item/chems/hypospray/autoinjector/antirad
	detail_color = COLOR_AMBER

/obj/item/chems/hypospray/autoinjector/antirad/populate_reagents()
	add_to_reagents(/decl/material/liquid/antirads, reagents.maximum_volume)
	. = ..()

////////////////////////////////////////////////////////////////////////////////
// Autoinjector - Hallucinogenics
////////////////////////////////////////////////////////////////////////////////
/obj/item/chems/hypospray/autoinjector/hallucinogenics
	detail_color = COLOR_DARK_GRAY

/obj/item/chems/hypospray/autoinjector/hallucinogenics/populate_reagents()
	add_to_reagents(/decl/material/liquid/hallucinogenics, reagents.maximum_volume)
	. = ..()

////////////////////////////////////////////////////////////////////////////////
// Autoinjector - Clotting agent
////////////////////////////////////////////////////////////////////////////////

/obj/item/chems/hypospray/autoinjector/clotting
	name = "autoinjector (clotting agent)"
	desc = "A refined version of the standard autoinjector, allowing greater capacity. This variant excels at treating bleeding wounds and internal bleeding."

/obj/item/chems/hypospray/autoinjector/clotting/populate_reagents()
	. = ..()
	var/amt = round(reagents.maximum_volume*0.5)
	add_to_reagents(/decl/material/liquid/stabilizer, amt)
	add_to_reagents(/decl/material/liquid/clotting_agent, (reagents.maximum_volume - amt))

////////////////////////////////////////////////////////////////////////////////
// Autoinjector - Empty
////////////////////////////////////////////////////////////////////////////////
/obj/item/chems/hypospray/autoinjector/empty
	name = "autoinjector"
	detail_color = COLOR_WHITE

/obj/item/chems/hypospray/autoinjector/empty/populate_reagents()
	SHOULD_CALL_PARENT(FALSE)
	return
