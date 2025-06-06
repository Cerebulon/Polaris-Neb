//This proc is called whenever someone clicks an inventory ui slot.
/mob/proc/attack_ui(slot)
	var/obj/item/holding = get_active_held_item()
	var/obj/item/equipped = get_equipped_item(slot)
	if (istype(equipped))
		if(istype(holding))
			equipped.attackby(holding, src)
		else
			equipped.attack_hand(src) // We can assume it's physically accessible if it's on our person.
	else
		equip_to_slot_if_possible(holding, slot)

//This is a SAFE proc. Use this instead of equip_to_slot()!
//set del_on_fail to have it delete prop if it fails to equip
//set disable_warning to disable the 'you are unable to equip that' warning.
//unset redraw_mob to prevent the mob from being redrawn at the end.
//set force to replace items in the slot and ignore blocking overwear
/mob/proc/equip_to_slot_if_possible(obj/item/prop, slot, del_on_fail = 0, disable_warning = 0, redraw_mob = 1, force = FALSE, delete_old_item = TRUE, ignore_equipped = FALSE)
	if(!istype(prop) || !slot)
		return FALSE
	. = (can_unequip_item(prop) && can_equip_anything_to_slot(slot) && has_organ_for_slot(slot) && prop.mob_can_equip(src, slot, disable_warning, force, ignore_equipped = ignore_equipped))
	if(.)
		equip_to_slot(prop, slot, redraw_mob, delete_old_item = delete_old_item) //This proc should not ever fail.
	else if(del_on_fail)
		qdel(prop)
	else if(!disable_warning)
		to_chat(src, SPAN_WARNING("You are unable to equip that."))

/mob/proc/can_equip_anything_to_slot(var/slot)

	// Held item slots may not have the dexterity to hold an item.
	if(slot in get_held_item_slots())
		var/datum/inventory_slot/gripper/hand = get_inventory_slot_datum(slot)
		// No actual held item slot, this is a bug or an error.
		if(!istype(hand))
			return FALSE
		// Hand is organ based, ask the organ if it has the required dexterity.
		if(hand.requires_organ_tag)
			var/obj/item/organ/external/hand_organ = get_organ(hand.requires_organ_tag)
			if(!hand_organ || !(hand_organ.get_manual_dexterity() & DEXTERITY_HOLD_ITEM))
				return FALSE
		// Hand is not organ based, ask the gripper slot directly.
		else if(!(hand.get_dexterity() & DEXTERITY_HOLD_ITEM))
			return FALSE

	return (slot in get_all_available_equipment_slots())

//This is an UNSAFE proc. It merely handles the actual job of equipping. All the checks on whether you can or can't eqip need to be done before! Use mob_can_equip() for that task.
//In most cases you will want to use equip_to_slot_if_possible()
/mob/proc/equip_to_slot(obj/item/prop, slot, redraw_mob = TRUE, delete_old_item = TRUE)
	SHOULD_CALL_PARENT(TRUE)
	if(!istype(prop) || isnull(slot))
		return FALSE

	// Handle some special slots.
	if(slot == slot_in_backpack_str)
		remove_from_mob(prop)
		var/obj/item/back = get_equipped_item(slot_back_str)
		if(back)
			prop.forceMove(back)
		else
			prop.dropInto(loc)
		return TRUE

	// Attempt to equip accessories if the slot is already blocked.
	if(!delete_old_item && get_equipped_item(slot))

		var/attached = FALSE
		var/list/check_slots = get_inventory_slots()
		if(islist(check_slots))

			check_slots = check_slots.Copy()
			check_slots -= global.all_hand_slots

			check_slots -= slot
			check_slots.Insert(1, slot)

			var/try_equip_slot = prop.get_fallback_slot()
			if(try_equip_slot && slot != try_equip_slot)
				check_slots -= try_equip_slot
				check_slots.Insert(1, try_equip_slot)

			for(var/slot_string in check_slots)
				var/obj/item/clothing/clothes = get_equipped_item(slot_string)
				if(istype(clothes) && clothes.can_attach_accessory(prop, src))
					clothes.attach_accessory(src, prop)
					attached = TRUE
					break

		if(attached)
			return TRUE

	unequip(prop)
	var/datum/inventory_slot/inv_slot = get_inventory_slot_datum(slot)
	if(inv_slot)
		inv_slot.equipped(src, prop, redraw_mob, delete_old_item)
		if(prop.action_button_name)
			update_action_buttons()
		return TRUE
	to_chat(src, SPAN_WARNING("You are trying to equip this item to an unsupported inventory slot. If possible, please write a ticket with steps to reproduce. Slot was: [slot]"))
	return FALSE

//This is just a commonly used configuration for the equip_to_slot_if_possible() proc, used to equip people when the rounds tarts and when events happen and such.
/mob/proc/equip_to_slot_or_del(obj/item/prop, slot)
	return equip_to_slot_if_possible(prop, slot, 1, 1, 0)

/mob/proc/equip_to_slot_or_store_or_drop(obj/item/prop, slot)
	var/store = equip_to_slot_if_possible(prop, slot, 0, 1, 0)
	if(!store)
		return equip_to_storage_or_drop(prop)
	return store

//puts the item "prop" into an appropriate slot in a human's inventory
//returns 0 if it cannot, 1 if successful
/mob/proc/equip_to_appropriate_slot(obj/item/prop, var/skip_store = 0)
	if(!istype(prop))
		return FALSE
	for(var/slot in get_inventory_slot_priorities())
		if(skip_store)
			if(slot == slot_s_store_str || slot == slot_l_store_str || slot == slot_r_store_str)
				continue
		if(equip_to_slot_if_possible(prop, slot, del_on_fail=0, disable_warning=1, redraw_mob=1))
			return TRUE
	return FALSE

/mob/proc/equip_to_storage(obj/item/newitem)
	// Try put it in their backpack
	var/obj/item/back = get_equipped_item(slot_back_str)
	if(back?.storage?.can_be_inserted(newitem, null, 1))
		back.storage.handle_item_insertion(src, newitem)
		return back

	// Try to place it in any item that can store stuff, on the mob.
	for(var/obj/item/thing in contents)
		if(thing?.storage?.can_be_inserted(newitem, null, 1))
			thing.storage.handle_item_insertion(src, newitem)
			return thing

/mob/proc/equip_to_storage_or_drop(obj/item/newitem)
	var/stored = equip_to_storage(newitem)
	if(!stored && newitem)
		newitem.forceMove(loc)
	return stored

/mob/proc/equip_to_storage_or_put_in_hands(obj/item/newitem)
	var/stored = equip_to_storage(newitem)
	if(!stored && newitem)
		put_in_hands(newitem)
	return stored
//These procs handle putting s tuff in your hand. It's probably best to use these rather than setting l_hand = ...etc
//as they handle all relevant stuff like adding it to the player's screen and updating their overlays.

//Returns the thing in our active hand
/mob/proc/get_active_held_item()
	RETURN_TYPE(/obj/item)
	return null

/mob/proc/get_active_held_item_slot()
	return

//Returns the thing in our inactive hand
/mob/proc/get_inactive_held_items()
	RETURN_TYPE(/list)
	return null

/mob/proc/get_held_items()
	for(var/obj/item/thing in get_inactive_held_items())
		LAZYADD(., thing)
	var/obj/item/thing = get_active_held_item()
	if(istype(thing))
		LAZYADD(., thing)

/mob/proc/get_empty_hand_slot()
	return

/mob/proc/get_empty_hand_slots()
	return

/mob/proc/put_in_active_hand(var/obj/item/prop)
	. = equip_to_slot_if_possible(prop, get_active_held_item_slot(), disable_warning = TRUE)

//Puts the item into (one of) our inactive hand(s) if possible. returns 1 on success.
/mob/proc/put_in_inactive_hand(var/obj/item/prop)
	var/active_slot = get_active_held_item_slot()
	for(var/slot in get_empty_hand_slots())
		if(slot == active_slot)
			continue
		. = equip_to_slot_if_possible(prop, slot, disable_warning = TRUE)
		if(.)
			break
//Puts the item our active hand if possible. Failing that it tries our inactive hand. Returns 1 on success.
//If both fail it drops it on the floor and returns 0.
//This is probably the main one you need to know :)

/mob/proc/put_in_hands_or_del(var/obj/item/prop)
	. = put_in_hands(prop)
	if(!. && !QDELETED(prop))
		qdel(prop)

/mob/proc/put_in_hands(var/obj/item/prop)
	if(!prop)
		return FALSE
	if(put_in_active_hand(prop) || put_in_inactive_hand(prop))
		return TRUE
	drop_from_inventory(prop)
	return FALSE

/mob/proc/put_in_hands_or_store_or_drop(var/obj/item/prop)
	. = put_in_hands(prop)
	if(!.)
		. = equip_to_storage_or_drop(prop)

// Removes an item from inventory and places it in the target atom.
// If canremove or other conditions need to be checked then use unEquip instead.
/mob/proc/drop_from_inventory(var/obj/item/dropping_item, var/atom/target = null, var/play_dropsound = TRUE)
	if(dropping_item)
		remove_from_mob(dropping_item, target, play_dropsound)
		return TRUE
	return FALSE

// Drops a held item from a given slot.
/mob/proc/drop_from_slot(slot_id, atom/new_loc)
	return FALSE

//Drops the item in our active hand. TODO: rename this to drop_active_hand or something
/mob/proc/drop_item(var/atom/Target)
	var/obj/item/I = get_active_held_item()
	if(!istype(I))
		if(length(get_active_grabs()))
			for(var/obj/item/grab/grab as anything in get_active_grabs())
				qdel(grab)
				. = TRUE
			return
		return FALSE
	else if(!I.mob_can_unequip(src, get_equipped_slot_for_item(I), dropping = TRUE))
		return FALSE
	. = drop_from_inventory(I, Target)

/*
	Removes the object from any slots the mob might have, calling the appropriate icon update proc.
	Does nothing else.

	>>>> *** DO NOT CALL THIS PROC DIRECTLY *** <<<<

	It is meant to be called only by other inventory procs.
	It's probably okay to use it if you are transferring the item between slots on the same mob,
	but chances are you're safer calling remove_from_mob() or drop_from_inventory() anyways.

	As far as I can tell the proc exists so that mobs with different inventory slots can override
	the search through all the slots, without having to duplicate the rest of the item dropping.
*/
/mob/proc/unequip(obj/prop)
	SHOULD_CALL_PARENT(TRUE)
	if(!istype(prop))
		return FALSE
	var/datum/inventory_slot/inv_slot = get_inventory_slot_datum(get_equipped_slot_for_item(prop))
	if(inv_slot)
		return inv_slot.unequipped(src, prop)
	return FALSE

/mob/proc/isEquipped(obj/item/I)
	if(!I)
		return FALSE
	return !!get_equipped_slot_for_item(I)

/mob/proc/can_unequip_item(obj/item/I)
	if(!I) //If there's nothing to drop, the drop is automatically successful.
		return TRUE
	if(I in get_organs())
		return FALSE
	var/slot = get_equipped_slot_for_item(I)
	if(!slot && !istype(I.loc, /obj/item/rig_module))
		return TRUE //already unequipped, so success
	return I.mob_can_unequip(src, slot)

/// Gets the inventory slot string ID for the mob whose contents we're in, if any.
/// Checks both equipped and held item slots.
/obj/item/proc/get_any_equipped_slot()
	if(!ismob(loc))
		return null
	var/mob/mob = loc
	return mob.get_any_equipped_slot_for_item(src)

/// Gets the inventory slot string ID for an item that may be in our inventory.
/// Checks both equipped and held item slots.
/mob/proc/get_any_equipped_slot_for_item(obj/item/I)
	var/list/slots = get_inventory_slots() + get_held_item_slots()
	if(!length(slots))
		return
	for(var/slot_str in slots)
		if(get_equipped_item(slot_str) == I) // slots[slot]._holding == I
			return slot_str

/// A counterpart to get_any_equipped_slot_for_item that returns the slot datum rather than the slot name.
/// Checks both equipped and held item slots.
/obj/item/proc/get_any_equipped_slot_datum()
	if(!ismob(loc))
		return null
	var/mob/mob = loc
	return mob.get_inventory_slot_datum(mob.get_any_equipped_slot_for_item(src))

/// Gets the equipment (worn) slot string ID for the mob whose contents we're in, if any. Does not include held slots.
/obj/item/proc/get_equipped_slot()
	if(!ismob(loc))
		return null
	var/mob/mob = loc
	return mob.get_equipped_slot_for_item(src)

/// A helper that returns the slot datum rather than the slot name.
/// Does not include held slots.
/// Saves unnecessary duplicate ismob checks and loc casts.
/obj/item/proc/get_equipped_slot_datum()
	if(!ismob(loc))
		return null
	var/mob/mob = loc
	return mob.get_inventory_slot_datum(mob.get_equipped_slot_for_item(src))

/// Gets the equipment (worn) slot string ID for an item we may be wearing. Does not include held slots.
/mob/proc/get_equipped_slot_for_item(obj/item/I)
	var/list/slots = get_inventory_slots()
	if(!length(slots))
		return
	for(var/slot_str in slots)
		if(get_equipped_item(slot_str) == I) // slots[slot]._holding == I
			return slot_str

/// Gets the held item slot string ID for the mob whose contents we're in, if any. Does not include worn slots.
/obj/item/proc/get_held_slot()
	if(!ismob(loc))
		return null
	var/mob/mob = loc
	return mob.get_held_slot_for_item(src)

/// Gets the held item slot string ID for an item we may be holding. Does not include worn slots.
/mob/proc/get_held_slot_for_item(obj/item/I)
	var/list/slots = get_held_item_slots()
	if(!length(slots))
		return
	for(var/slot in slots)
		if(get_equipped_item(slot) == I)
			return slot

/mob/proc/get_inventory_slot_datum(var/slot)
	return

//This differs from remove_from_mob() in that it checks if the item can be unequipped first. Use drop_from_inventory if you don't want to check.
/mob/proc/try_unequip(obj/item/I, var/atom/target, var/play_dropsound = TRUE)
	if(!can_unequip_item(I))
		return FALSE
	drop_from_inventory(I, target, play_dropsound)
	return TRUE

//Attemps to remove an object on a mob.
/mob/proc/remove_from_mob(var/obj/object, var/atom/target, var/play_dropsound = TRUE)
	if(!istype(object)) // Nothing to remove, so we succeed.
		return TRUE
	unequip(object)
	if(client)
		client.screen -= object
	object.screen_loc = null
	if(!QDELETED(object))
		if(target)
			object.forceMove(target)
		else
			object.dropInto(loc)
		object.reset_plane_and_layer() // this should be done post-move to avoid wasting an icon update
		if(isitem(object))
			var/obj/item/item = object
			item.dropped(src, play_dropsound)
		if(!QDELETED(object)) // dropped might qdelete us
			object.compile_overlays() // avoid world overlays on inventory state and vice versa
	return TRUE

/mob/proc/drop_held_items(drop_loc = loc)
	for(var/thing in get_held_items())
		try_unequip(thing, drop_loc)

//Returns the item equipped to the specified slot, if any.
/mob/proc/get_equipped_item(var/slot)
	SHOULD_CALL_PARENT(TRUE)
	var/datum/inventory_slot/inv_slot = get_inventory_slot_datum(slot)
	return inv_slot?.get_equipped_item()

/mob/proc/get_equipped_items(var/include_carried = 0)
	SHOULD_CALL_PARENT(TRUE)
	var/held_item_slots = get_held_item_slots()
	for(var/slot in get_inventory_slots())
		var/obj/item/thing = get_equipped_item(slot)
		if(istype(thing))
			if(!include_carried && (slot in held_item_slots))
				continue
			LAZYADD(., thing)

/mob/proc/delete_inventory(var/include_carried = FALSE)
	for(var/entry in get_equipped_items(include_carried))
		drop_from_inventory(entry)
		qdel(entry)

/mob/proc/has_organ_for_slot(slot)
	if(slot in global.abstract_inventory_slots)
		return TRUE
	var/datum/inventory_slot/inv_slot = get_inventory_slot_datum(slot)
	if(inv_slot)
		return !!inv_slot.check_has_required_organ(src)
	return has_organ(slot)

// Returns all currently covered body parts
/mob/proc/get_covered_body_parts()
	. = 0
	for(var/obj/item/I as anything in get_equipped_items())
		. |= I.body_parts_covered

// Returns the first item which covers any given body part
/mob/proc/get_covering_equipped_item(var/body_parts)
	if(!isnum(body_parts))
		return null
	for(var/obj/item/I as anything in get_equipped_items())
		if(I.body_parts_covered & body_parts)
			return I

// Returns all items which covers any given body part
/mob/proc/get_covering_equipped_items(var/body_parts)
	. = list()
	for(var/obj/item/I as anything in get_equipped_items())
		if(I.body_parts_covered & body_parts)
			. += I

// Returns the first item which covers all specified body parts.
/mob/proc/get_covering_equipped_item_exact(var/body_parts)
	if(!isnum(body_parts))
		return null
	for(var/obj/item/I as anything in get_equipped_items())
		if((I.body_parts_covered & body_parts) == body_parts)
			return I

// Returns all items which cover all specified body parts.
/mob/proc/get_covering_equipped_items_exact(var/body_parts)
	. = list()
	for(var/obj/item/I as anything in get_equipped_items())
		if((I.body_parts_covered & body_parts) == body_parts)
			. += I

/mob/proc/has_held_item_slot()
	return !!length(get_held_item_slots())

/mob/proc/is_holding_offhand(var/thing)
	return FALSE

/mob/proc/can_be_buckled(var/mob/user)
	. = user.Adjacent(src) && !ispAI(user)

/// If this proc returns false, reconsider_client_screen_presence will set the item's screen_loc to null.
/mob/proc/item_should_have_screen_presence(obj/item/item, slot)
	if(!slot || !istype(hud_used))
		return FALSE
	if(hud_used.is_inventory_shown())
		return TRUE
	var/datum/inventory_slot/inv_slot = get_inventory_slot_datum(slot)
	return !(inv_slot?.can_be_hidden)

/mob/proc/get_held_item_slots()
	return

/mob/proc/add_held_item_slot(var/datum/inventory_slot/held_slot)
	return

/mob/proc/remove_held_item_slot(var/slot)
	return

/mob/proc/select_held_item_slot(var/slot)
	SHOULD_CALL_PARENT(TRUE)
	clear_available_intents()

/mob/proc/get_inventory_slots()
	return

/mob/proc/get_inventory_slot_priorities()
	return

/mob/proc/set_inventory_slots(var/list/new_slots)
	return

/mob/proc/add_inventory_slot()
	return

/mob/proc/remove_inventory_slot(var/slot)
	return

/mob/proc/get_all_available_equipment_slots()
	for(var/slot in get_held_item_slots())
		LAZYDISTINCTADD(., slot)
	for(var/slot in get_inventory_slots())
		LAZYDISTINCTADD(., slot)

/mob/proc/get_hands_organs()
	for(var/hand_slot in get_held_item_slots())
		var/org = GET_EXTERNAL_ORGAN(src, hand_slot)
		if(org)
			LAZYDISTINCTADD(., org)

/mob/proc/get_active_hand_bodypart_flags()
	var/datum/inventory_slot/gripper/inv_slot = get_inventory_slot_datum(get_active_held_item_slot())
	if(istype(inv_slot))
		. = inv_slot.covering_slot_flags
	. ||= SLOT_HANDS
