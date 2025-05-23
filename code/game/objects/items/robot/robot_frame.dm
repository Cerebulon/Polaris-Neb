/obj/item/robot_parts/robot_suit
	name = "standard robot frame"
	desc = "A complex metal backbone with standard limb sockets and pseudomuscle anchors."
	icon_state = "robo_suit"

	var/list/parts = list()
	var/list/required_parts = list(
		BP_L_ARM = /obj/item/robot_parts/l_arm,
		BP_R_ARM = /obj/item/robot_parts/r_arm,
		BP_CHEST = /obj/item/robot_parts/chest,
		BP_L_LEG = /obj/item/robot_parts/l_leg,
		BP_R_LEG = /obj/item/robot_parts/r_leg,
		BP_HEAD  = /obj/item/robot_parts/head
	)
	var/created_name = ""
	var/product = /mob/living/silicon/robot

/obj/item/robot_parts/robot_suit/Initialize()
	. = ..()
	update_icon()

/obj/item/robot_parts/robot_suit/on_update_icon()
	. = ..()
	for(var/part in required_parts)
		if(parts[part])
			add_overlay("[part]+o")

/obj/item/robot_parts/robot_suit/proc/check_completion()
	for(var/part in required_parts)
		if(!parts[part])
			return FALSE
	SSstatistics.add_field("cyborg_frames_built",1)
	return TRUE

/obj/item/robot_parts/robot_suit/attackby(obj/item/used_item, mob/user)

	// Uninstall a robotic part.
	if(IS_CROWBAR(used_item))
		if(!parts.len)
			to_chat(user, SPAN_WARNING("\The [src] has no parts to remove."))
			return TRUE
		var/removing = pick(parts)
		var/obj/item/robot_parts/part = parts[removing]
		part.forceMove(get_turf(src))
		user.put_in_hands(part)
		parts -= removing
		to_chat(user, SPAN_WARNING("You lever \the [part] off \the [src]."))
		update_icon()
		return TRUE

	// Install a robotic part.
	else if (istype(used_item, /obj/item/robot_parts))
		var/obj/item/robot_parts/part = used_item
		if(!required_parts[part.bp_tag] || !istype(used_item, required_parts[part.bp_tag]))
			to_chat(user, SPAN_WARNING("\The [src] is not compatible with \the [used_item]."))
		else if(parts[part.bp_tag])
			to_chat(user, SPAN_WARNING("\The [src] already has \a [used_item] installed."))
		else if(part.can_install(user) && user.try_unequip(used_item, src))
			parts[part.bp_tag] = part
			update_icon()
		return TRUE

	// Install a brain.
	else if(istype(used_item, /obj/item/organ/internal/brain_interface))

		if(!isturf(loc))
			to_chat(user, SPAN_WARNING("You can't put \the [used_item] in without the frame being on the ground."))
			return TRUE

		if(!check_completion())
			to_chat(user, SPAN_WARNING("The frame is not ready for the central processor to be installed."))
			return TRUE

		var/obj/item/organ/internal/brain_interface/M = used_item
		var/mob/living/brainmob = M?.get_brainmob()
		if(!brainmob)
			to_chat(user, SPAN_WARNING("Sticking an empty [used_item.name] into the frame would sort of defeat the purpose."))
			return TRUE

		if(jobban_isbanned(brainmob, ASSIGNMENT_ROBOT))
			to_chat(user, SPAN_WARNING("\The [used_item] does not seem to fit."))
			return TRUE

		if(brainmob.stat == DEAD)
			to_chat(user, SPAN_WARNING("Sticking a dead [used_item.name] into the frame would sort of defeat the purpose."))
			return TRUE

		var/ghost_can_reenter = 0
		if(brainmob.mind)
			if(!brainmob.key)
				for(var/mob/observer/ghost/G in global.player_list)
					if(G.can_reenter_corpse && G.mind == brainmob.mind)
						ghost_can_reenter = 1
						break
			else
				ghost_can_reenter = 1
		if(!ghost_can_reenter)
			to_chat(user, SPAN_WARNING("\The [used_item] is completely unresponsive; there's no point."))
			return TRUE

		if(!user.try_unequip(used_item))
			return TRUE

		SSstatistics.add_field("cyborg_frames_built",1)
		var/mob/living/silicon/robot/O = new product(get_turf(loc))
		if(!O)
			return TRUE

		O.central_processor = used_item
		O.set_invisibility(INVISIBILITY_NONE)
		O.custom_name = created_name
		O.updatename("Default")

		clear_antag_roles(brainmob.mind, implanted = TRUE) // some antag roles persist
		brainmob.mind.transfer_to(O)
		if(O.mind && O.mind.assigned_role)
			O.job = O.mind.assigned_role
		else
			O.job = ASSIGNMENT_ROBOT

		var/obj/item/robot_parts/chest/chest = parts[BP_CHEST]
		chest.cell.forceMove(O)
		used_item.forceMove(O) //Should fix cybros run time erroring when blown up. It got deleted before, along with the frame.

		// Since we "magically" installed a cell, we also have to update the correct component.
		if(O.cell)
			var/datum/robot_component/cell_component = O.components["power cell"]
			cell_component.wrapped = O.cell
			cell_component.installed = 1

		SSstatistics.add_field("cyborg_birth",1)
		RAISE_EVENT(/decl/observ/cyborg_created, O)
		O.Namepick()
		qdel(src)
		return TRUE

	else if(IS_PEN(used_item))
		var/t = sanitize_safe(input(user, "Enter new robot name", src.name, src.created_name), MAX_NAME_LEN)
		if(t && (in_range(src, user) || loc == user))
			created_name = t
		return TRUE
	else
		return ..()

/obj/item/robot_parts/robot_suit/Destroy()
	parts.Cut()
	for(var/thing in contents)
		qdel(thing)
	. = ..()

/obj/item/robot_parts/robot_suit/proc/dismantled_from(var/mob/living/silicon/robot/donor)
	for(var/thing in required_parts - list(BP_CHEST, BP_HEAD))
		var/part_type = required_parts[thing]
		parts[thing] = new part_type(src)
	var/obj/item/robot_parts/chest/chest = (locate() in donor.contents) || new
	if(chest)
		chest.forceMove(src)
		parts[BP_CHEST] = chest
	update_icon()

/obj/item/robot_parts/robot_suit/SetDefaultName()
	SetName(initial(name))

/obj/item/robot_parts/robot_suit/flyer
	name = "flying robot frame"
	icon = 'icons/obj/robot_parts_flying.dmi'
	product = /mob/living/silicon/robot/flying
	required_parts = list(
		BP_L_ARM = /obj/item/robot_parts/l_arm,
		BP_R_ARM = /obj/item/robot_parts/r_arm,
		BP_CHEST = /obj/item/robot_parts/chest,
		BP_HEAD  = /obj/item/robot_parts/head
	)
