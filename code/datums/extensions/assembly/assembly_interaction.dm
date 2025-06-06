/datum/extension/assembly/proc/attackby(var/obj/item/used_item, var/mob/user)
	if(IS_WRENCH(used_item))
		if(parts.len)
			to_chat(user, "Remove all components from \the [holder] before disassembling it.")
			return TRUE
		SSmaterials.create_object(/decl/material/solid/metal/steel, get_turf(holder), steel_sheet_cost)
		if(user)
			user.visible_message("\The [holder] has been disassembled by [user].")
		qdel(holder)
		return TRUE

	if(IS_WELDER(used_item))
		var/obj/item/weldingtool/welder = used_item
		if(!welder.isOn())
			to_chat(user, "\The [used_item] is off.")
			return TRUE

		if(!damage)
			to_chat(user, "\The [holder] does not require repairs.")
			return TRUE

		to_chat(user, "You begin repairing damage to \the [holder]...")
		if(welder.weld(round(damage/75)) && do_after(user, damage/10))
			damage = 0
			to_chat(user, "You repair \the [holder].")
		return TRUE

	if(IS_SCREWDRIVER(used_item))
		if(!parts.len)
			to_chat(user, "This device doesn't have any components installed.")
			return TRUE
		var/list/component_names = list()
		for(var/obj/item/stock_parts/computer/H in parts)
			component_names.Add(H.name)

		var/choice = input(user, "Which component do you want to uninstall?", "[assembly_name] maintenance", null) as null|anything in component_names
		if(!choice)
			return TRUE
		var/atom/movable/HA = holder
		if(!HA.Adjacent(user))
			return TRUE

		var/obj/item/stock_parts/H = find_component_by_name(choice)
		if(!H)
			return TRUE

		uninstall_component(user, H)
		return TRUE

	if(istype(used_item, /obj/item/card/id)) // ID Card, try to insert it.
		var/obj/item/stock_parts/computer/card_slot/card_slot = get_component(PART_CARD)
		if(!card_slot)
			to_chat(user, SPAN_WARNING("You try to insert [used_item] into [holder], but it does not have an ID card slot installed."))
			return TRUE
		card_slot.insert_id(used_item, user)
		return TRUE

	if(istype(used_item, /obj/item/charge_stick)) // Try to insert charge stick.
		var/obj/item/stock_parts/computer/charge_stick_slot/mstick_slot = get_component(PART_MSTICK)
		if(!mstick_slot)
			to_chat(user, SPAN_WARNING("You try to insert [used_item] into [holder], but it does not have a charge-stick slot installed."))
			return TRUE
		mstick_slot.insert_stick(used_item, user)
		return TRUE

	if(istype(used_item, PART_DRIVE)) // Portable HDD, try to insert it.
		var/obj/item/stock_parts/computer/hard_drive/portable/I = used_item
		var/obj/item/stock_parts/computer/drive_slot/drive_slot = get_component(PART_D_SLOT)
		if(!drive_slot)
			to_chat(user, SPAN_WARNING("You try to insert [I] into [holder], but it does not have a drive slot installed."))
			return TRUE
		drive_slot.insert_drive(I, user)
		return TRUE

	if(istype(used_item, /obj/item/disk))
		var/obj/item/disk/disk = used_item
		var/obj/item/stock_parts/computer/data_disk_drive/disk_drive = get_component(PART_DSKSLOT)
		if(!disk_drive)
			to_chat(user, SPAN_WARNING("You try to insert [disk] into [holder], but it does not have a disk slot installed."))
			return TRUE
		disk_drive.insert_disk(disk, user)
		return TRUE

	if(istype(used_item, /obj/item/paper))
		var/obj/item/paper/paper = used_item
		if(paper.info)
			var/obj/item/stock_parts/computer/scanner/scanner = get_component(PART_SCANNER)
			if(scanner)
				scanner.attackby(user, used_item)
			return TRUE

	if(istype(used_item, /obj/item/paper) || istype(used_item, /obj/item/paper_bundle))
		var/obj/item/stock_parts/computer/scanner/scanner = get_component(PART_SCANNER)
		if(scanner)
			scanner.attackby(used_item, user)
		return TRUE

	if(istype(used_item, /obj/item/aicard))
		var/obj/item/stock_parts/computer/ai_slot/ai_slot = get_component(PART_AI)
		if(ai_slot)
			ai_slot.attackby(used_item, user)
		return TRUE

	if(istype(used_item, /obj/item/stock_parts))
		return try_install_component(user, used_item)
	return FALSE