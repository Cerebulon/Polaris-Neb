/obj/structure/closet/crate
	name = "crate"
	desc = "A rectangular steel crate."
	icon = 'icons/obj/closets/bases/crate.dmi'
	closet_appearance = /decl/closet_appearance/crate
	atom_flags = ATOM_FLAG_CLIMBABLE
	setup = 0
	storage_types = CLOSET_STORAGE_ITEMS
	var/rigged = 0

/obj/structure/closet/crate/open(mob/user)
	if((atom_flags & ATOM_FLAG_CLIMBABLE) && !opened && can_open(user))
		object_shaken()
	. = ..()
	if(.)
		if(rigged)
			visible_message("<span class='danger'>There are wires attached to the lid of [src]...</span>")
			for(var/obj/item/assembly_holder/H in src)
				// This proc expects an /obj/item, and usr is never that, but it must be non-null for the code to function.
				// TODO: Rewrite or refactor either this code or the proc itself to avoid that.
				H.process_activation(usr)
			for(var/obj/item/assembly/A in src)
				A.activate()

/obj/structure/closet/crate/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	if(rigged && opened)
		var/list/devices = list()
		for(var/obj/item/assembly_holder/H in src)
			devices += H
		for(var/obj/item/assembly/A in src)
			devices += A
		. += "There are some wires attached to the lid, connected to [english_list(devices)]."

/obj/structure/closet/crate/attackby(obj/item/used_item, mob/user)
	if(opened)
		return ..()
	else if(istype(used_item, /obj/item/stack/package_wrap))
		return FALSE // let afterattack run
	else if(istype(used_item, /obj/item/stack/cable_coil))
		var/obj/item/stack/cable_coil/C = used_item
		if(rigged)
			to_chat(user, "<span class='notice'>[src] is already rigged!</span>")
			return TRUE
		if (C.use(1))
			to_chat(user, "<span class='notice'>You rig [src].</span>")
			rigged = 1
			return TRUE
		return FALSE
	else if((istype(used_item, /obj/item/assembly_holder) || istype(used_item, /obj/item/assembly)) && rigged)
		if(!user.try_unequip(used_item, src))
			return TRUE
		to_chat(user, "<span class='notice'>You attach [used_item] to [src].</span>")
		return TRUE
	else if(IS_WIRECUTTER(used_item))
		if(rigged)
			to_chat(user, "<span class='notice'>You cut away the wiring.</span>")
			playsound(loc, 'sound/items/Wirecutter.ogg', 100, 1)
			rigged = 0
			return TRUE
		return FALSE
	else
		return ..()

/obj/structure/closet/crate/secure
	desc = "A secure crate."
	name = "Secure crate"
	closet_appearance = /decl/closet_appearance/crate/secure
	setup = CLOSET_HAS_LOCK
	locked = TRUE

/obj/structure/closet/crate/secure/Initialize()
	. = ..()
	update_icon()

/obj/structure/closet/crate/plastic
	name = "plastic crate"
	desc = "A rectangular plastic crate."
	closet_appearance = /decl/closet_appearance/crate/plastic

/obj/structure/closet/crate/plastic/rations //For use in the escape shuttle
	name = "emergency rations"
	desc = "A crate of emergency rations."

/obj/structure/closet/crate/plastic/rations/WillContain()
	return list(
		/obj/random/mre = 6,
		/obj/item/chems/drinks/cans/waterbottle = 12
	)

/obj/structure/closet/crate/internals
	name = "internals crate"
	desc = "An internals crate."

/obj/structure/closet/crate/internals/fuel
	name = "\improper Fuel tank crate"
	desc = "A fuel tank crate."

/obj/structure/closet/crate/internals/fuel/WillContain()
	return list(/obj/item/tank/hydrogen = 4)

/obj/structure/closet/crate/trashcart
	name = "trash cart"
	desc = "A heavy, metal trashcart with wheels."
	closet_appearance = /decl/closet_appearance/cart/trash
	icon = 'icons/obj/closets/bases/cart.dmi'

/obj/structure/closet/crate/medical
	name = "medical crate"
	desc = "A medical crate."
	closet_appearance = /decl/closet_appearance/crate/medical

/obj/structure/closet/crate/rcd
	name = "\improper RCD crate"
	desc = "A crate with rapid construction device."

/obj/structure/closet/crate/rcd/WillContain()
	return list(
		/obj/item/rcd_ammo = 3,
		/obj/item/rcd
	)

/obj/structure/closet/crate/solar
	name = "solar pack crate"

/obj/structure/closet/crate/solar/WillContain()
	return list(
		/obj/item/solar_assembly = 14,
		/obj/item/stock_parts/circuitboard/solar_control,
		/obj/item/tracker_electronics,
		/obj/item/paper/solar
	)

/obj/structure/closet/crate/solar_assembly
	name = "solar assembly crate"

/obj/structure/closet/crate/solar_assembly/WillContain()
	return list(/obj/item/solar_assembly = 16)

/obj/structure/closet/crate/freezer
	name = "freezer"
	desc = "A freezer."
	temperature = -16 CELSIUS
	closet_appearance = /decl/closet_appearance/crate/freezer

	var/target_temp = T0C - 40
	var/cooling_power = 40

/obj/structure/closet/crate/freezer/return_air()
	var/datum/gas_mixture/gas = (..())
	if(!gas)	return null
	var/datum/gas_mixture/newgas = new/datum/gas_mixture()
	newgas.copy_from(gas)
	if(newgas.temperature <= target_temp)	return

	if((newgas.temperature - cooling_power) > target_temp)
		newgas.temperature -= cooling_power
	else
		newgas.temperature = target_temp
	return newgas

/obj/structure/closet/crate/freezer/ProcessAtomTemperature()
	return PROCESS_KILL

/obj/structure/closet/crate/freezer/meat
	name = "meat crate"
	desc = "A crate of meat."

/obj/structure/closet/crate/freezer/meat/WillContain()
	return list(
		/obj/item/food/butchery/meat/beef = 4,
		/obj/item/food/butchery/meat/syntiflesh = 4,
		/obj/item/food/butchery/meat/fish = 4
	)

/obj/structure/closet/crate/bin
	name = "large bin"
	desc = "A large bin."

/obj/structure/closet/crate/radiation
	name = "radioactive crate"
	desc = "A lead-lined crate with a radiation sign on it."
	closet_appearance = /decl/closet_appearance/crate/radiation

/obj/structure/closet/crate/radiation_gear
	name = "radioactive gear crate"
	desc = "A crate with a radiation sign on it."
	closet_appearance = /decl/closet_appearance/crate/radiation

/obj/structure/closet/crate/radiation_gear/WillContain()
	return list(/obj/item/clothing/suit/radiation = 8)

/obj/structure/closet/crate/secure/weapon
	name = "weapons crate"
	desc = "A secure weapons crate."
	closet_appearance = /decl/closet_appearance/crate/secure/weapon

/obj/structure/closet/crate/secure/explosives
	name = "explosives crate"
	desc = "A secure explosives crate."
	closet_appearance = /decl/closet_appearance/crate/secure/hazard

/obj/structure/closet/crate/secure/shuttle
	name = "storage compartment"
	desc = "A secure storage compartment bolted to the floor, to secure loose objects on Zero-G flights."
	anchored = TRUE
	closet_appearance = /decl/closet_appearance/crate/secure/shuttle

/obj/structure/closet/crate/secure/gear
	name = "gear crate"
	desc = "A secure gear crate."
	closet_appearance = /decl/closet_appearance/crate/secure/weapon

/obj/structure/closet/crate/secure/hydrosec
	name = "secure hydroponics crate"
	desc = "A crate with a lock on it, painted in the scheme of botany and botanists."
	closet_appearance = /decl/closet_appearance/crate/secure/hydroponics

/obj/structure/closet/crate/large
	name = "large crate"
	desc = "A hefty metal crate."
	storage_capacity = 2 * MOB_SIZE_LARGE
	storage_types = CLOSET_STORAGE_ITEMS|CLOSET_STORAGE_STRUCTURES
	closet_appearance = /decl/closet_appearance/large_crate
	icon = 'icons/obj/closets/bases/large_crate.dmi'

/obj/structure/closet/crate/large/hydroponics
	closet_appearance = /decl/closet_appearance/large_crate/hydroponics

/obj/structure/closet/crate/secure/large
	name = "large crate"
	desc = "A hefty metal crate with an electronic locking system."
	closet_appearance = /decl/closet_appearance/large_crate/secure

	storage_capacity = 2 * MOB_SIZE_LARGE
	storage_types = CLOSET_STORAGE_ITEMS|CLOSET_STORAGE_STRUCTURES
	icon = 'icons/obj/closets/bases/large_crate.dmi'

//fluff variant
/obj/structure/closet/crate/secure/large/reinforced
	desc = "A hefty, reinforced metal crate with an electronic locking system."

/obj/structure/closet/crate/hydroponics
	name = "hydroponics crate"
	desc = "All you need to destroy those pesky weeds and pests."
	closet_appearance = /decl/closet_appearance/crate/hydroponics

/obj/structure/closet/crate/hydroponics/prespawned/WillContain()
	return list(
		/obj/item/chems/spray/plantbgone = 2,
		/obj/item/tool/hoe/mini = 2,
		/obj/item/plants = 2,
		/obj/item/tool/axe/hatchet = 2,
		/obj/item/wirecutters/clippers = 2,
		/obj/item/scanner/plant = 2
	)

/obj/structure/closet/crate/hydroponics/exotic
	name = "exotic seeds crate"
	desc = "All you need to destroy that pesky planet."

/obj/structure/closet/crate/hydroponics/exotic/WillContain()
	return list(
		/obj/item/seeds/random = 6,
		/obj/item/seeds/ambrosiavulgarisseed = 2,
		/obj/item/seeds/kudzuseed,
		/obj/item/seeds/libertymycelium,
		/obj/item/seeds/reishimycelium
	)

/obj/structure/closet/crate/secure/biohazard
	name = "biohazard cart"
	desc = "A heavy cart with extensive sealing. You shouldn't eat things you find in it."
	open_sound = 'sound/items/Deconstruct.ogg'
	close_sound = 'sound/items/Deconstruct.ogg'
	req_access = list(access_xenobiology)
	closet_appearance = /decl/closet_appearance/cart/biohazard
	storage_capacity = 2 * MOB_SIZE_LARGE
	storage_types = CLOSET_STORAGE_ITEMS|CLOSET_STORAGE_MOBS|CLOSET_STORAGE_STRUCTURES
	movable_flags = MOVABLE_FLAG_WHEELED
	icon = 'icons/obj/closets/bases/cart.dmi'

/obj/structure/closet/crate/secure/biohazard/blanks/WillContain()
	return list(/obj/structure/closet/body_bag/cryobag/blank)

/obj/structure/closet/crate/secure/biohazard/blanks/can_close(mob/user)
	for(var/obj/structure/closet/closet in get_turf(src))
		if(closet != src && !(istype(closet, /obj/structure/closet/body_bag/cryobag)))
			return 0
	return 1

/obj/structure/closet/crate/secure/biohazard/alt
	name = "biowaste disposal cart"
	desc = "A heavy cart used for organ disposal with markings indicating the things inside are probably gross."
	req_access = list(access_surgery)
	closet_appearance = /decl/closet_appearance/cart/biohazard/alt
	movable_flags = MOVABLE_FLAG_WHEELED

/obj/structure/closet/crate/paper_refill
	name = "paper refill crate"
	desc = "A rectangular plastic crate, filled up with blank papers for refilling bins and printers. A bureaucrat's favorite."

/obj/structure/closet/crate/paper_refill/WillContain()
	return list(/obj/item/paper = 30)

/obj/structure/closet/crate/uranium
	name = "fissibles crate"
	desc = "A crate with a radiation sign on it."
	closet_appearance = /decl/closet_appearance/crate/radiation

/obj/structure/closet/crate/uranium/WillContain()
	return list(/obj/item/stack/material/puck/mapped/uranium/ten = 5)

/obj/structure/closet/crate/chest
	name = "chest"
	desc = "A compact, hinged chest."
	icon = 'icons/obj/closets/bases/chest.dmi'
	open_sound = 'sound/effects/storage/briefcase.ogg'
	close_sound = 'sound/effects/storage/briefcase.ogg'
	closet_appearance = /decl/closet_appearance/crate/chest
	material_alteration = MAT_FLAG_ALTERATION_COLOR | MAT_FLAG_ALTERATION_NAME | MAT_FLAG_ALTERATION_DESC
	material = /decl/material/solid/organic/wood/oak
	color = /decl/material/solid/organic/wood/oak::color
	var/icon/overlay_icon = 'icons/obj/closets/bases/chest.dmi'
	// TODO: Rework chest crafting so that this can use reinf_material instead.
	/// The material used for the opacity and color of the trim overlay.
	var/decl/material/overlay_material = /decl/material/solid/metal/iron

/obj/structure/closet/crate/chest/Initialize()
	. = ..()
	if(ispath(overlay_material))
		overlay_material = GET_DECL(overlay_material)
	// icon update is already queued in parent because of closet appearance

/obj/structure/closet/crate/chest/update_material_desc(override_desc)
	..()
	if(overlay_material)
		desc = "[desc] It has a trim made of [overlay_material.solid_name]."

/obj/structure/closet/crate/chest/on_update_icon()
	. = ..()
	if(istype(overlay_material))
		var/overlay_state = opened ? "open-overlay" : "base-overlay"
		var/image/trim = overlay_image(overlay_icon, overlay_state, overlay_material.color, RESET_COLOR|RESET_ALPHA)
		trim.alpha = clamp((50 + overlay_material.opacity * 255), 0, 255)
		add_overlay(trim)

/obj/structure/closet/crate/chest/ebony
	material = /decl/material/solid/organic/wood/ebony
	color = /decl/material/solid/organic/wood/ebony::color