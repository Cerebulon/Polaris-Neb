/obj/item/chems
	name = "container"
	desc = "..."
	icon = 'icons/obj/items/chem/container.dmi'
	icon_state = null
	w_class = ITEM_SIZE_SMALL
	material = /decl/material/solid/organic/plastic
	obj_flags = OBJ_FLAG_HOLLOW
	abstract_type = /obj/item/chems
	watertight = TRUE

	var/base_desc
	var/amount_per_transfer_from_this = 5
	var/possible_transfer_amounts = @"[5,10,15,25,30]"
	var/volume = 30
	var/label_text
	var/presentation_flags = 0
	var/show_reagent_name = FALSE
	var/detail_color
	var/detail_state

/obj/item/chems/Initialize(ml, material_key)
	. = ..()
	initialize_reagents()
	if(!possible_transfer_amounts)
		src.verbs -= /obj/item/chems/verb/set_amount_per_transfer_from_this

/obj/item/chems/on_update_icon()
	. = ..()
	if(detail_state)
		add_overlay(overlay_image(icon, "[initial(icon_state)][detail_state]", detail_color || COLOR_WHITE, RESET_COLOR))
	var/image/contents_overlay = get_reagents_overlay(use_single_icon ? icon_state : null)
	if(contents_overlay)
		add_overlay(contents_overlay)
	if(detail_state)
		add_overlay(overlay_image(icon, "[initial(icon_state)][detail_state]", detail_color || COLOR_WHITE, RESET_COLOR))

/obj/item/chems/apply_additional_mob_overlays(mob/living/user_mob, bodytype, image/overlay, slot, bodypart, use_fallback_if_icon_missing)
	var/image/reagents_overlay = get_reagents_overlay(overlay.icon_state)
	if(reagents_overlay)
		overlay.add_overlay(reagents_overlay)
	return ..()

/obj/item/chems/set_custom_desc(var/new_desc)
	base_desc = new_desc
	update_container_desc()

/obj/item/chems/proc/cannot_interact(mob/user)
	if(!CanPhysicallyInteract(user))
		to_chat(user, SPAN_WARNING("You're in no condition to do that!"))
		return TRUE
	if(ismob(loc) && loc != user)
		to_chat(user, SPAN_WARNING("You can't set transfer amounts while \the [src] is being held by someone else."))
		return TRUE
	return FALSE

/obj/item/chems/update_name()
	. = ..() // handles material, etc
	var/newname = name
	if(presentation_flags & PRESENTATION_FLAG_NAME)
		var/decl/material/primary = reagents?.get_primary_reagent_decl()
		if(primary)
			newname += " of [primary.get_presentation_name(src)]"
	if(length(label_text))
		newname += " ([label_text])"
	if(newname != name)
		SetName(newname)

/obj/item/chems/proc/get_base_desc()
	if(!base_desc)
		base_desc = initial(desc)
	. = base_desc

/obj/item/chems/proc/update_container_desc()
	var/list/new_desc_list = list(get_base_desc())
	if(presentation_flags & PRESENTATION_FLAG_DESC)
		var/decl/material/R = reagents?.get_primary_reagent_decl()
		if(R)
			new_desc_list += R.get_presentation_desc(src)
	desc = new_desc_list.Join("\n")

/obj/item/chems/on_reagent_change()
	if((. = ..()))
		update_name()
		update_container_desc()
		update_icon()

/obj/item/chems/verb/set_amount_per_transfer_from_this()
	set name = "Set Transfer Amount"
	set category = "Object"
	set src in range(1)
	if(cannot_interact(usr))
		return
	var/N = input("How much do you wish to transfer per use?", "Set Transfer Amount") as null|anything in cached_json_decode(possible_transfer_amounts)
	if(N && !cannot_interact(usr))
		amount_per_transfer_from_this = N

/obj/item/chems/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	return

/obj/item/chems/attackby(obj/item/used_item, mob/user)

	// Skimming off cream, repurposed from crucibles.
	// TODO: potentially make this an alt interaction and unify with slag skimming.
	if(istype(used_item, /obj/item/chems) && ATOM_IS_OPEN_CONTAINER(used_item) && used_item.reagents?.maximum_volume && reagents?.total_volume && length(reagents.reagent_volumes) > 1)
		var/list/skimmable_reagents = reagents.get_skimmable_reagents()
		if(length(skimmable_reagents))
			var/removing = min(amount_per_transfer_from_this, REAGENTS_FREE_SPACE(used_item.reagents))
			if(removing <= 0)
				to_chat(user, SPAN_WARNING("\The [used_item] is full."))
			else
				var/old_amt = used_item.reagents.total_volume
				reagents.trans_to_holder(used_item.reagents, removing, skip_reagents = (reagents.reagent_volumes - skimmable_reagents))
				to_chat(user, SPAN_NOTICE("You skim [used_item.reagents.total_volume-old_amt] unit\s of [used_item.reagents.get_primary_reagent_name()] from the top of \the [reagents.get_primary_reagent_name()]."))
			return TRUE

	if(used_item.user_can_attack_with(user, silent = TRUE))
		if(IS_PEN(used_item))
			var/tmp_label = sanitize_safe(input(user, "Enter a label for [name]", "Label", label_text), MAX_NAME_LEN)
			if(length(tmp_label) > 10)
				to_chat(user, SPAN_NOTICE("The label can be at most 10 characters long."))
			else
				to_chat(user, SPAN_NOTICE("You set the label to \"[tmp_label]\"."))
				label_text = tmp_label
				update_name()
			return TRUE
	return ..()

/obj/item/chems/standard_pour_into(mob/user, atom/target, amount = 5)
	amount = amount_per_transfer_from_this
	// We'll be lenient: if you lack the dexterity for proper pouring you get a random amount.
	if(!user_can_attack_with(user, silent = TRUE))
		amount = rand(1, floor(amount_per_transfer_from_this * 1.5))
	return ..(user, target, amount)

/obj/item/chems/do_surgery(mob/living/M, mob/living/user)
	if(user.get_target_zone() != BP_MOUTH) //in case it is ever used as a surgery tool
		return ..()

/obj/item/chems/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	if(!reagents)
		return
	if(hasHUD(user, HUD_SCIENCE))
		var/prec = user.skill_fail_chance(SKILL_CHEMISTRY, 10)
		. += SPAN_NOTICE("\The [src] contains: [reagents.get_reagents(precision = prec)].")
	else if((loc == user) && user.skill_check(SKILL_CHEMISTRY, SKILL_EXPERT))
		. += SPAN_NOTICE("Using your chemistry knowledge, you identify the following reagents in \the [src]: [reagents.get_reagents(!user.skill_check(SKILL_CHEMISTRY, SKILL_PROF), 5)].")

/obj/item/chems/shatter(consumed)
	//Skip splashing if we are in nullspace, since splash isn't null guarded
	if(loc)
		reagents.splash(get_turf(src), reagents.total_volume)
	. = ..()

/obj/item/chems/initialize_reagents(populate = TRUE)
	if(!reagents)
		create_reagents(volume)
	else
		reagents.maximum_volume = max(reagents.maximum_volume, volume)
	. = ..()

/obj/item/chems/proc/set_detail_color(var/new_color)
	if(new_color != detail_color)
		detail_color = new_color
		update_icon()
		return TRUE
	return FALSE

/obj/item/chems/ProcessAtomTemperature()

	. = ..()

	if(QDELETED(src) || !reagents?.total_volume || !ATOM_IS_OPEN_CONTAINER(src) || !isatom(loc))
		return

	// Vaporize anything over its boiling point.
	var/update_reagents = FALSE
	for(var/decl/material/reagent as anything in reagents.reagent_volumes)
		if(reagent.can_boil_to_gas && !isnull(reagent.boiling_point) && temperature >= reagent.boiling_point)
			// TODO: reduce atom temperature?
			var/removing = min(reagent.boil_evaporation_per_run, reagents.reagent_volumes[reagent])
			reagents.remove_reagent(reagent, removing, defer_update = TRUE, removed_phases = MAT_PHASE_LIQUID)
			update_reagents = TRUE
			loc.take_vaporized_reagent(reagent, removing)
	if(update_reagents)
		reagents.update_total()

/obj/item/chems/take_vaporized_reagent(reagent, amount)
	if(!reagents?.maximum_volume)
		return ..()
	var/take_reagent = min(amount, REAGENTS_FREE_SPACE(reagents))
	if(take_reagent > 0)
		reagents.add_reagent(reagent, take_reagent)
		amount -= take_reagent
	if(amount > 0)
		return ..(reagent, amount)

//
// Interactions
//
/obj/item/chems/get_quick_interaction_handler(mob/user)
	var/static/interaction = GET_DECL(/decl/interaction_handler/set_transfer/chems)
	return interaction

/obj/item/chems/get_alt_interactions(var/mob/user)
	. = ..()
	var/static/list/chem_interactions = list(
		/decl/interaction_handler/set_transfer/chems,
		/decl/interaction_handler/empty/chems
	)
	LAZYADD(., chem_interactions)

/decl/interaction_handler/set_transfer/chems
	expected_target_type = /obj/item/chems
	examine_desc         = "set the transfer volume"

/decl/interaction_handler/set_transfer/chems/is_possible(var/atom/target, var/mob/user)
	. = ..()
	if(.)
		var/obj/item/chems/C = target
		return !!C.possible_transfer_amounts

/decl/interaction_handler/set_transfer/chems/invoked(atom/target, mob/user, obj/item/prop)
	var/obj/item/chems/C = target
	C.set_amount_per_transfer_from_this()

///Empty a container onto the floor
/decl/interaction_handler/empty/chems
	name                 = "Empty On Floor"
	expected_target_type = /obj/item/chems
	interaction_flags    = INTERACTION_NEEDS_INVENTORY | INTERACTION_NEEDS_PHYSICAL_INTERACTION | INTERACTION_NEVER_AUTOMATIC
	examine_desc         = "empty $TARGET_THEM$ onto the floor"

/decl/interaction_handler/empty/chems/invoked(atom/target, mob/user, obj/item/prop)
	var/turf/T = get_turf(user)
	if(T)
		to_chat(user, SPAN_NOTICE("You empty \the [target] onto the floor."))
		target.reagents.trans_to(T, target.reagents.total_volume)
