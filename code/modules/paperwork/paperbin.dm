/////////////////////////////////////////////////////////////////
// Paper Bin
/////////////////////////////////////////////////////////////////
/obj/item/paper_bin
	name                = "paper bin"
	icon                = 'icons/obj/items/paper_bin.dmi'
	icon_state          = "paper_bin1"
	item_state          = "sheet-metal"
	randpixel           = 0
	layer               = BELOW_OBJ_LAYER
	w_class             = ITEM_SIZE_NORMAL
	throw_speed         = 3
	throw_range         = 7
	material            = /decl/material/solid/organic/plastic
	var/amount          = 30  //How much paper is in the bin.
	var/tmp/max_amount  = 30  //How much paper fits in the bin
	var/list/papers	  //List of papers put in the bin for reference.

/obj/item/paper_bin/Destroy()
	LAZYCLEARLIST(papers) //Gets rid of any refs
	return ..()

/obj/item/paper_bin/handle_mouse_drop(atom/over, mob/user, params)
	if((loc == user || in_range(src, user)) && user.get_empty_hand_slot())
		user.put_in_hands(src)
		return TRUE
	. = ..()

/obj/item/paper_bin/attack_hand(mob/user)

	// This is required due to the mousedrop code calling attack_hand directly.
	if(!CanPhysicallyInteract(user))
		return FALSE

	if(user.check_intent(I_FLAG_HARM) || !user.check_dexterity(DEXTERITY_HOLD_ITEM, TRUE))
		return ..()

	if(LAZYLEN(papers) < 1 && amount < 1)
		to_chat(user, SPAN_WARNING("\The [src] is empty!"))
		return TRUE

	var/obj/item/paper/P
	if(LAZYLEN(papers) > 0)	//If there's any custom paper on the stack, use that instead of creating a new paper.
		P = papers[papers.len]
		LAZYREMOVE(papers, P)
	else
		var/paper_kind = input(user, "What kind of paper?") in list("Regular", "Green", "Blue", "Pink", "Yellow", "Carbon-Copy", "Cancel")
		switch(paper_kind)
			if("Regular")
				P = new /obj/item/paper
			if("Green")
				P = new /obj/item/paper/green
			if("Blue")
				P = new /obj/item/paper/blue
			if("Pink")
				P = new /obj/item/paper/pink
			if("Yellow")
				P = new /obj/item/paper/yellow
			if("Carbon-Copy")
				P = new /obj/item/paper/carbon
			else
				return TRUE

		if(!istype(P, /obj/item/paper/carbon) && global.current_holiday?.name == "April Fool's Day" && prob(30))
			P.rigged = TRUE
			P.set_content("<font face=\"[P.crayonfont]\" color=\"red\"><b>HONK HONK HONK HONK HONK HONK HONK<br>HOOOOOOOOOOOOOOOOOOOOOONK<br>APRIL FOOLS</b></font>")

	user.put_in_hands(P)
	to_chat(user, SPAN_NOTICE("You take \the [P] out of \the [src]."))
	amount--
	update_icon()
	add_fingerprint(user)
	return TRUE

/obj/item/paper_bin/attackby(obj/item/used_item, mob/user)
	if(istype(used_item, /obj/item/paper))
		if(amount >= max_amount)
			to_chat(user, SPAN_WARNING("\The [src] is full!"))
			return TRUE
		if(!user.try_unequip(used_item, src))
			return TRUE
		add_paper(used_item)
		to_chat(user, SPAN_NOTICE("You put [used_item] in [src]."))
		return TRUE
	else if(istype(used_item, /obj/item/paper_bundle))
		if(amount >= max_amount)
			to_chat(user, SPAN_WARNING("\The [src] is full!"))
			return TRUE
		var/obj/item/paper_bundle/B = used_item
		var/was_there_a_photo = FALSE
		for(var/obj/item/bundleitem in used_item) //loop through items in bundle
			if(istype(bundleitem, /obj/item/paper)) //if item is paper, add into the bin
				LAZYREMOVE(B.pages, bundleitem)
				add_paper(bundleitem)
			else if(istype(bundleitem, /obj/item/photo)) //if item is photo, drop it on the ground
				was_there_a_photo = TRUE
				bundleitem.dropInto(user.loc)
				bundleitem.reset_plane_and_layer()
		to_chat(user, SPAN_NOTICE("You loosen \the [used_item] and add its papers into \the [src]."))
		B.reevaluate_existence()
		if(was_there_a_photo)
			to_chat(user, SPAN_NOTICE("The photo cannot go into \the [src]."))
		return TRUE
	return ..()

/obj/item/paper_bin/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	if(distance > 1)
		return
	if(amount)
		. += SPAN_NOTICE("There [(amount > 1 ? "are [amount] papers" : "is one paper")] in the bin.")
	else
		. += SPAN_NOTICE("There are no papers in the bin.")
	. += SPAN_NOTICE("It can contain at most [max_amount] papers.")

/obj/item/paper_bin/on_update_icon()
	. = ..()
	if(amount <= 0)
		icon_state = "paper_bin0"
	else if(amount <= (max_amount / 3))
		icon_state = "paper_bin1"
	else if(amount >= max_amount)
		icon_state = "paper_bin3"
	else
		icon_state = "paper_bin2"

/obj/item/paper_bin/dump_contents(atom/forced_loc = loc, mob/user)
	. = ..()
	//Dump all stored papers too
	for(var/i=1 to amount)
		var/obj/item/paper/P = new /obj/item/paper(forced_loc)
		P.merge_with_existing(forced_loc, user)
	LAZYCLEARLIST(papers)

/obj/item/paper_bin/proc/add_paper(var/obj/item/paper/P)
	if(amount >= max_amount)
		return
	//Add only non-blank papers into the paper list
	if(P.is_blank())
		qdel(P)
	else
		LAZYDISTINCTADD(papers, P)
		P.forceMove(src)
	amount++
	update_icon()
	return TRUE

/obj/item/paper_bin/get_alt_interactions(mob/user)
	. = ..()
	LAZYADD(., /decl/interaction_handler/paper_bin_dump_contents)

/////////////////////////////////////////////////////////////////
// Empty Bin Interaction
/////////////////////////////////////////////////////////////////
/decl/interaction_handler/paper_bin_dump_contents
	name                 = "Dump Contents"
	expected_target_type = /obj/item/paper_bin
	examine_desc         = "empty $TARGET_THEM$"

/decl/interaction_handler/paper_bin_dump_contents/is_possible(var/obj/item/paper_bin/target, mob/user, obj/item/prop)
	return ..() && target.amount > 0

/decl/interaction_handler/paper_bin_dump_contents/invoked(atom/target, mob/user, obj/item/prop)
	var/obj/item/paper_bin/bin = target
	to_chat(user, SPAN_NOTICE("You start emptying \the [bin]..."))
	if(do_after(user, 2 SECONDS) && !QDELETED(bin))
		bin.dump_contents()
		to_chat(user, SPAN_NOTICE("You emptied \the [bin]."))
