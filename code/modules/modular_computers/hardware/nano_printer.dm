/obj/item/stock_parts/computer/nano_printer
	name = "nano printer"
	desc = "Small integrated printer with paper recycling module."
	power_usage = 50
	origin_tech = @'{"programming":2,"engineering":2}'
	critical = 0
	icon_state = "printer"
	hardware_size = 1
	material = /decl/material/solid/metal/steel

	var/stored_paper = 50
	var/max_paper = 50
	var/last_print

/obj/item/stock_parts/computer/nano_printer/diagnostics()
	. = ..()
	. += "Paper buffer level: [stored_paper]/[max_paper]"

/obj/item/stock_parts/computer/nano_printer/proc/print_text(var/text_to_print, var/paper_title = null, var/paper_type = /obj/item/paper, var/list/md = null)
	if(printer_ready())
		last_print = world.time
		var/turf/T = get_turf(src)
		new paper_type(T, null, text_to_print, paper_title, md)
		stored_paper--
		playsound(T, "sound/machines/dotprinter.ogg", 30)
		T.visible_message("<span class='notice'>\The [src] prints out a paper.</span>")
		return 1

/obj/item/stock_parts/computer/nano_printer/proc/printer_ready()
	if(!stored_paper)
		return 0
	if(!enabled)
		return 0
	if(!check_functionality())
		return 0
	if(world.time < last_print + 1 SECOND)
		return 0
	return 1

// TODO: unify with /obj/item/stock_parts/printer somehow?
/obj/item/stock_parts/computer/nano_printer/attackby(obj/item/used_item, mob/user)
	if(istype(used_item, /obj/item/paper))
		if(stored_paper >= max_paper)
			to_chat(user, "You try to add \the [used_item] into \the [src], but its paper bin is full.")
			return TRUE

		to_chat(user, "You insert \the [used_item] into [src].")
		qdel(used_item)
		stored_paper++
	else if(istype(used_item, /obj/item/paper_bundle))
		var/obj/item/paper_bundle/B = used_item
		var/num_of_pages_added = 0
		if(stored_paper >= max_paper)
			to_chat(user, "You try to add \the [used_item] into \the [src], but its paper bin is full.")
			return TRUE
		if(!B.is_blank())
			if(user)
				to_chat(user, SPAN_WARNING("\The [B] contains some non-blank pages, or something else than paper sheets!"))
			return TRUE
		for(var/obj/item/paper/bundleitem in B) //loop through papers in bundle
			B.pages.Remove(bundleitem)
			qdel(bundleitem)
			num_of_pages_added++
			stored_paper++
			if(stored_paper >= max_paper) //check if the printer is full yet
				to_chat(user, "The printer has been filled to full capacity.")
				break
		switch(length(B.pages))
			if(0) //if all its papers have been put into the printer, delete bundle
				qdel(B)
			if(1) //if only one item left, extract item and delete the one-item bundle
				user.drop_from_inventory(B)
				user.put_in_hands(B.pages[1])
				qdel(B)
			else //if at least two items remain, just update the bundle icon
				B.update_icon()
		to_chat(user, "You add [num_of_pages_added] papers from \the [used_item] into \the [src].")
		return TRUE
	return ..()
