/obj/item/clothing/webbing/holster
	name = "shoulder holster"
	desc = "A handgun holster."
	icon = 'icons/clothing/accessories/holsters/holster.dmi'
	storage = /datum/storage/holster/shoulder
	accessory_slot = ACCESSORY_SLOT_HOLSTER
	var/list/can_holster = null
	var/sound_in = 'sound/effects/holster/holsterin.ogg'
	var/sound_out = 'sound/effects/holster/holsterout.ogg'

/obj/item/clothing/webbing/holster/Initialize()
	. = ..()
	set_extension(src, /datum/extension/holster, storage, sound_in, sound_out, can_holster)

/obj/item/clothing/webbing/holster/attackby(obj/item/used_item, mob/user)
	var/datum/extension/holster/holster = get_extension(src, /datum/extension/holster)
	if(holster.holster(used_item, user))
		return TRUE
	return ..(used_item, user)

/obj/item/clothing/webbing/holster/attack_hand(mob/user)
	if(!user.check_dexterity(DEXTERITY_HOLD_ITEM, TRUE))
		return ..()
	var/datum/extension/holster/holster = get_extension(src, /datum/extension/holster)
	if(holster.unholster(user))
		return TRUE
	return ..()

/obj/item/clothing/webbing/holster/examined_by(mob/user, distance, infix, suffix)
	. = ..(user)
	var/datum/extension/holster/holster = get_extension(src, /datum/extension/holster)
	holster.examine_holster(user)

/obj/item/clothing/webbing/holster/on_attached(var/obj/item/clothing/holder, var/mob/user)
	. = ..()
	if(istype(holder))
		holder.verbs |= /atom/proc/holster_verb

/obj/item/clothing/webbing/holster/on_accessory_removed(mob/user)
	var/obj/item/clothing/holder = loc
	if(istype(holder))
		var/remove_verb = TRUE
		if(has_extension(holder, /datum/extension/holster))
			remove_verb = FALSE
		for(var/obj/accessory in holder.accessories)
			if(accessory == src)
				continue
			if(has_extension(accessory, /datum/extension/holster))
				remove_verb = FALSE
		if(remove_verb)
			holder.verbs -= /atom/proc/holster_verb
	return ..()

/obj/item/clothing/webbing/holster/armpit
	name = "armpit holster"
	desc = "A worn-out handgun holster. Perfect for concealed carry."

/obj/item/clothing/webbing/holster/waist
	name = "waist holster"
	desc = "A handgun holster. Made of expensive leather."
	icon = 'icons/clothing/accessories/holsters/holster_low.dmi'

/obj/item/clothing/webbing/holster/hip
	name = "hip holster"
	desc = "A handgun holster slung low on the hip, draw pardner!"
	icon = 'icons/clothing/accessories/holsters/holster_hip.dmi'

/obj/item/clothing/webbing/holster/thigh
	name = "thigh holster"
	desc = "A drop leg holster made of a durable synthetic fiber."
	icon = 'icons/clothing/accessories/holsters/holster_thigh.dmi'
	sound_in = 'sound/effects/holster/tactiholsterin.ogg'
	sound_out = 'sound/effects/holster/tactiholsterout.ogg'

/obj/item/clothing/webbing/holster/machete
	name = "blade sheath"
	desc = "A handsome synthetic leather sheath with matching belt."
	icon = 'icons/clothing/accessories/holsters/holster_machete.dmi'
	can_holster = list(
		/obj/item/tool/machete,
		/obj/item/knife/kitchen/cleaver,
		/obj/item/sword/katana
	)
	sound_in = 'sound/effects/holster/sheathin.ogg'
	sound_out = 'sound/effects/holster/sheathout.ogg'

/obj/item/clothing/webbing/holster/knife
	name = "leather knife sheath"
	desc = "A synthetic leather knife sheath which you can strap on your leg."
	icon = 'icons/clothing/accessories/holsters/sheath_leather.dmi'
	can_holster = list(/obj/item/knife)
	sound_in = 'sound/effects/holster/sheathin.ogg'
	sound_out = 'sound/effects/holster/sheathout.ogg'

/obj/item/clothing/webbing/holster/knife/polymer
	name = "polymer knife sheath"
	desc = "A rigid polymer sheath which you can strap on your leg."
	icon = 'icons/clothing/accessories/holsters/sheath_polymer.dmi'
