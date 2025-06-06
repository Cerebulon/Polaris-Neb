/obj/machinery/microwave
	name = "microwave"
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "mw"
	layer = BELOW_OBJ_LAYER
	density = TRUE
	anchored = TRUE
	idle_power_usage = 5
	active_power_usage = 100
	atom_flags = ATOM_FLAG_NO_CHEM_CHANGE | ATOM_FLAG_OPEN_CONTAINER
	construct_state = /decl/machine_construction/default/panel_closed
	uncreated_component_parts = null
	stat_immune = 0
	var/operating = FALSE // Is it on?
	var/dirty = 0 // = {0..100} Does it need cleaning?
	var/broken = 0 // ={0,1,2} How broken is it???
	var/max_n_of_items = 20 // default, adjusted by matter bins
	var/datum/composite_sound/microwave/soundloop

	// These determine if the current cooking process failed, the vars above determine if the microwave is broken
	var/cook_break = FALSE
	var/cook_dirty = FALSE
	var/failed = FALSE // pretty much exclusively for sending the fail state across to the UI, using recipe elsewhere is preferred

	var/cook_time = 400
	var/start_time = 0
	var/end_time = 0
	var/cooking_power = 1

	var/cooking_temperature = 93 CELSIUS // 200 F apparently?

// see code/modules/food/recipes_microwave.dm for recipes

/*******************
*   Initialising
********************/

/obj/machinery/microwave/Initialize()
	. = ..()
	create_reagents(100)
	soundloop = new(list(src), FALSE)

/obj/machinery/microwave/Destroy()
	dispose()
	QDEL_NULL(soundloop)
	return ..()

/*******************
*   Item Adding
********************/

/obj/machinery/microwave/grab_attack(obj/item/grab/grab, mob/user)
	to_chat(user, SPAN_WARNING("This is ridiculous. You can not fit \the [grab.affecting] into \the [src]."))
	return TRUE

/obj/machinery/microwave/attackby(var/obj/item/used_item, var/mob/user)
	if(broken > 0)
		if(broken == 2 && IS_SCREWDRIVER(used_item)) // If it's broken and they're using a screwdriver
			user.visible_message(
				SPAN_NOTICE("\The [user] starts to fix part of [src]."),
				SPAN_NOTICE("You start to fix part of [src].")
			)
			if (do_after(user, 20, src))
				user.visible_message(
					SPAN_NOTICE("\The [user] fixes part of [src]."),
					SPAN_NOTICE("You have fixed part of [src].")
				)
				broken = 1 // Fix it a bit
		else if(broken == 1 && IS_WRENCH(used_item)) // If it's broken and they're doing the wrench
			user.visible_message(
				SPAN_NOTICE("\The [user] starts to fix part of [src]."),
				SPAN_NOTICE("You start to fix part of [src].")
			)
			if (do_after(user, 20, src))
				user.visible_message(
					SPAN_NOTICE("\The [user] fixes [src]."),
					SPAN_NOTICE("You have fixed [src].")
				)
				broken = 0 // Fix it!
				dirty = 0 // just to be sure
				update_icon()
				atom_flags = ATOM_FLAG_OPEN_CONTAINER
		else
			to_chat(user, SPAN_WARNING("It's broken!"))
			return 1
	else if((. = component_attackby(used_item, user)))
		dispose()
		return
	else if(dirty==100) // The microwave is all dirty so can't be used!
		if(istype(used_item, /obj/item/chems/spray/cleaner) || istype(used_item, /obj/item/chems/rag)) // If they're trying to clean it then let them
			user.visible_message(
				SPAN_NOTICE("\The [user] starts to clean [src]."),
				SPAN_NOTICE("You start to clean [src].")
			)
			if (do_after(user, 20, src))
				user.visible_message(
					SPAN_NOTICE("\The [user] has cleaned [src]."),
					SPAN_NOTICE("You have cleaned [src].")
				)
				dirty = 0 // It's clean!
				broken = 0 // just to be sure
				update_icon()
				atom_flags = ATOM_FLAG_OPEN_CONTAINER
		else //Otherwise bad luck!!
			to_chat(user, SPAN_WARNING("It's dirty!"))
			return 1
	else if(!istype(used_item, /obj/item/chems/glass/bowl) && (istype(used_item,/obj/item/chems/glass) || istype(used_item,/obj/item/chems/drinks) || istype(used_item,/obj/item/chems/condiment) ))
		if (!used_item.reagents)
			return 1
		return // transfer is handled in afterattack
	else if(IS_WRENCH(used_item))
		user.visible_message(
			SPAN_NOTICE("\The [user] begins [anchored ? "securing" : "unsecuring"] [src]."),
			SPAN_NOTICE("You attempt to [anchored ? "secure" : "unsecure"] [src].")
		)
		if (do_after(user,20, src))
			anchored = !anchored
			user.visible_message(
				SPAN_NOTICE("\The [user] [anchored ? "secures" : "unsecures"] [src]."),
				SPAN_NOTICE("You [anchored ? "secure" : "unsecure"] [src].")
			)
		else
			to_chat(user, SPAN_NOTICE("You decide not to do that."))
	else if(used_item.w_class <= ITEM_SIZE_LARGE) // this must be last
		if (LAZYLEN(get_contained_external_atoms()) >= max_n_of_items)
			to_chat(user, SPAN_WARNING("This [src] is full of ingredients, you cannot put more."))
			return 1
		if(istype(used_item, /obj/item/stack)) // This is bad, but I can't think of how to change it
			var/obj/item/stack/S = used_item
			if(S.get_amount() > 1)
				var/obj/item/stack/new_stack = S.split(1)
				if(new_stack)
					new_stack.forceMove(src)
					user.visible_message(
						SPAN_NOTICE("\The [user] has added \a [new_stack.singular_name] to \the [src]."),
						SPAN_NOTICE("You add one of [used_item] to \the [src].")
					)
					SSnano.update_uis(src)
				return
		if (!user.try_unequip(used_item, src))
			return
		user.visible_message(
			SPAN_NOTICE("\The [user] has added \the [used_item] to \the [src]."),
			SPAN_NOTICE("You add \the [used_item] to \the [src].")
		)
		SSnano.update_uis(src)
		return
	else
		to_chat(user, SPAN_WARNING("You have no idea what you can cook with \the [used_item]."))
	SSnano.update_uis(src)

/obj/machinery/microwave/components_are_accessible(path)
	return (broken == 0) && ..()

/obj/machinery/microwave/cannot_transition_to(state_path, mob/user)
	if(broken)
		return SPAN_NOTICE("\The [src] is too broken to do this!")
	. = ..()

/obj/machinery/microwave/state_transition(decl/machine_construction/new_state)
	..()
	updateUsrDialog()

// need physical proximity for our interface.
/obj/machinery/microwave/DefaultTopicState()
	return global.physical_topic_state

/obj/machinery/microwave/interface_interact(mob/user)
	ui_interact(user)
	return TRUE

/*******************
*   Microwave Menu
********************/
/obj/machinery/microwave/ui_interact(mob/user, ui_key, datum/nanoui/ui, force_open, datum/nanoui/master_ui, datum/topic_state/state)
	. = ..()
	var/data = list()
	data["cooking_items"] = list()
	for(var/obj/used_item in get_contained_external_atoms())
		data["cooking_items"][used_item.name]++
	data["cooking_reagents"] = list()
	for(var/decl/material/reagent as anything in reagents.reagent_volumes)
		data["cooking_reagents"][reagent.name] = reagents.reagent_volumes[reagent]
	data["on"] = !!operating
	data["broken"] = broken > 0
	data["dirty"] = dirty >= 100
	data["failed"] = failed
	data["start_time"] = start_time
	data["cook_time"] = cook_time
	data["past_half_time"] = REALTIMEOFDAY >= (start_time + cook_time/2)
	// update the ui if it exists, returns null if no ui is passed/found
	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		// the ui does not exist, so we'll create a new() one
		// for a list of parameters and their descriptions see the code docs in \code\modules\nano\nanoui.dm
		ui = new(user, src, ui_key, "microwave.tmpl", capitalize(name), 300, 300)
		// when the ui is first opened this is the data it will use
		ui.set_initial_data(data)
		ui.open()

/***********************************
*   Microwave Menu Handling/Cooking
************************************/
/obj/machinery/microwave/proc/cook()
	cook_break = FALSE
	cook_dirty = FALSE

	if(stat & (NOPOWER|BROKEN))
		return

	if (!reagents.total_volume && !length(get_contained_external_atoms())) //dry run
		start()
		return

	if (reagents.total_volume && prob(50)) // 50% chance a liquid recipe gets messy
		dirty += ceil(reagents.total_volume / 10)

	var/decl/recipe/recipe = select_recipe(RECIPE_CATEGORY_MICROWAVE, src, cooking_temperature)
	if (!recipe)
		failed = TRUE
		cook_time = update_cook_time()
		dirty += 5
		if (prob(max(10, dirty*5)))
			// It's dirty enough to mess up the microwave
			cook_dirty = TRUE
		else if (has_extra_item())
			// Something's in the microwave that shouldn't be! Time to break!
			cook_break = TRUE
	else
		failed = FALSE
		cook_time = update_cook_time(round(recipe.cooking_time * 2))

	start()

/obj/machinery/microwave/proc/update_cook_time(var/ct = 200)
	return (ct / cooking_power)

/obj/machinery/microwave/proc/finish_cooking()
	var/decl/recipe/recipe = select_recipe(RECIPE_CATEGORY_MICROWAVE, src, cooking_temperature)
	if(!recipe)
		return
	var/result = recipe.result
	var/list/cooked_items = list()
	while(recipe)
		try
			cooked_items += recipe.produce_result(src)
			recipe = select_recipe(RECIPE_CATEGORY_MICROWAVE, src, cooking_temperature)
			if (!recipe || (recipe.result != result))
				break
		catch(var/exception/E)
			PRINT_STACK_TRACE("Runtime when processing microwave recipe spawn: [EXCEPTION_TEXT(E)]")
			break

	//Any leftover reagents are divided amongst the foods
	var/total = reagents.total_volume
	for (var/obj/item/I in cooked_items)
		reagents.trans_to_holder(I.reagents, total/cooked_items.len)
		I.dropInto(loc) // since eject only ejects ingredients!

	dispose(message = FALSE) //clear out anything left

	return

/obj/machinery/microwave/Process() // What you see here are the remains of proc/wzhzhzh, 2011 - 2021. RIP.
	if (!operating || stat & (NOPOWER|BROKEN) || (REALTIMEOFDAY > end_time))
		stop()

/obj/machinery/microwave/proc/half_time_process()
	if (!operating || stat & (NOPOWER|BROKEN))
		return

	playsound(src, 'sound/machines/click.ogg', 20, 1)

	if(failed)
		visible_message(SPAN_WARNING("\The [src] begins to leak an acrid smoke..."))

	SSnano.update_uis(src)

/obj/machinery/microwave/proc/has_extra_item()
	for(var/obj/thing in get_contained_external_atoms())
		if(!istype(thing,/obj/item/food))
			return TRUE
	return FALSE

/obj/machinery/microwave/proc/start()
	start_time = REALTIMEOFDAY
	end_time = cook_time + start_time
	operating = TRUE
	update_use_power(POWER_USE_ACTIVE)

	START_PROCESSING_MACHINE(src, MACHINERY_PROCESS_SELF)
	addtimer(CALLBACK(src, PROC_REF(half_time_process)), cook_time / 2)
	visible_message(SPAN_NOTICE("[src] turns on."), SPAN_NOTICE("You hear a microwave."))

	if(cook_dirty)
		playsound(loc, 'sound/effects/splat.ogg', 50, 1) // Play a splat sound
		icon_state = "mwbloody1" // Make it look dirty!!
	else
		icon_state = "mw1"

	set_light(1, 1.5)
	soundloop.start(src)
	update_icon()
	SSnano.update_uis(src)

/obj/machinery/microwave/proc/after_finish_loop()
	set_light(0)
	soundloop.stop(src)
	update_icon()

/obj/machinery/microwave/proc/stop(var/abort = FALSE)
	STOP_PROCESSING_MACHINE(src, MACHINERY_PROCESS_SELF)
	after_finish_loop()

	update_use_power(POWER_USE_OFF)
	operating = FALSE // Turn it off again aferwards
	if(cook_dirty || cook_break)
		atom_flags &= ~ATOM_FLAG_OPEN_CONTAINER //So you can't add condiments
	if(cook_dirty)
		visible_message(SPAN_WARNING("The insides of [src] get covered in muck!"))
		dirty = 100 // Make it dirty so it can't be used util cleaned
		icon_state = "mwbloody0" // Make it look dirty too
	else if(cook_break)
		var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
		s.set_up(2, global.alldirs, src)
		icon_state = "mwb" // Make it look all busted up and shit
		visible_message(SPAN_WARNING("[src] sprays out a shower of sparks - it's broken!")) //Let them know they're stupid
		broken = 2 // Make it broken so it can't be used until fixed
	else
		icon_state = "mw"

	cook_dirty = FALSE
	cook_break = FALSE

	if(failed)
		fail()
		failed = FALSE
	else if(!abort)
		finish_cooking()

	SSnano.update_uis(src)

/obj/machinery/microwave/on_reagent_change()
	if((. = ..()) && !operating)
		SSnano.update_uis(src)

/obj/machinery/microwave/proc/dispose(var/mob/user, var/message = TRUE)
	var/list/ingredients = get_contained_external_atoms()
	if (!LAZYLEN(ingredients) && !reagents.total_volume)
		return
	for (var/obj/thing in ingredients)
		thing.dropInto(loc)
	if (reagents.total_volume)
		dirty++
	reagents.clear_reagents()
	if(user && message)
		to_chat(user, SPAN_NOTICE("You empty [src]."))
	SSnano.update_uis(src)

/obj/machinery/microwave/proc/eject_item(var/mob/user, var/obj/thing, var/message = TRUE)
	if(!istype(thing) || !length(get_contained_external_atoms()))
		return
	thing.dropInto(loc)
	if(user && message)
		to_chat(user, SPAN_NOTICE("You remove [thing] from [src]."))
	SSnano.update_uis(src)

/obj/machinery/microwave/proc/eject_reagent(var/mob/user, var/decl/material/reagent)
	if(!reagents.reagent_volumes[reagent])
		SSnano.update_uis(src)
		return // should not happen, must be a UI glitch or href hacking
	var/obj/item/chems/held_container = user.get_active_held_item()
	if(istype(held_container))
		var/amount_to_move = min(REAGENTS_FREE_SPACE(held_container.reagents), REAGENT_VOLUME(reagents, reagent))
		if(amount_to_move <= 0)
			to_chat(user, SPAN_WARNING("[held_container] is full!"))
			return
		to_chat(user, SPAN_NOTICE("You empty [amount_to_move] units of [reagent.name] into [held_container]."))
		reagents.trans_type_to(held_container, reagent, amount_to_move)
	else
		to_chat(user, SPAN_NOTICE("You try to dump out the [reagent.name], but it gets all over [src] because you have nothing to put it in."))
		dirty++
		reagents.clear_reagent(reagent)
	SSnano.update_uis(src)

/obj/machinery/microwave/on_update_icon()
	if(dirty == 100)
		icon_state = "mwbloody[operating]"
	else if(broken)
		icon_state = "mwb"
	else
		icon_state = "mw[operating]"

/obj/machinery/microwave/proc/fail()
	failed = TRUE
	var/amount = 0
	var/list/ingredients = get_contained_external_atoms()
	// Kill + delete mobs in mob holders
	for (var/obj/item/holder/H in ingredients)
		for (var/mob/living/M in H.contents)
			M.death()
			qdel(M)

	for (var/obj/thing in ingredients)
		amount++
		if (thing.reagents && thing.reagents.primary_reagent)
			amount += REAGENT_VOLUME(thing.reagents, thing.reagents.primary_reagent)
		qdel(thing)
	reagents.clear_reagents()
	SSnano.update_uis(src)
	var/obj/item/food/badrecipe/ffuu = new(src)
	ffuu.add_to_reagents(/decl/material/solid/carbon, amount)
	ffuu.add_to_reagents(/decl/material/liquid/acrylamide, amount/10)
	return ffuu

/obj/machinery/microwave/OnTopic(mob/user, href_list)
	switch(href_list["action"])
		if ("cook")
			cook()
			return TOPIC_REFRESH

		if ("dispose")
			dispose(user)
			return TOPIC_REFRESH

		if ("ejectitem")
			for(var/obj/thing in get_contained_external_atoms())
				if(strip_improper(thing.name) == href_list["target"])
					eject_item(user, thing)
					break
			return TOPIC_REFRESH

		if ("ejectreagent")
			for(var/decl/material/reagent as anything in reagents.reagent_volumes)
				if(reagent.name == href_list["target"])
					eject_reagent(user, reagent)
					break
			return TOPIC_REFRESH

		if ("abort")
			stop(abort = TRUE)
			return TOPIC_REFRESH

/obj/machinery/microwave/RefreshParts()
	..()
	var/bin_rating = 0 // 2
	var/cap_rating = 0 // 3
	var/las_rating = 0 // 1

	bin_rating = total_component_rating_of_type(/obj/item/stock_parts/matter_bin)
	cap_rating = total_component_rating_of_type(/obj/item/stock_parts/capacitor)
	las_rating = total_component_rating_of_type(/obj/item/stock_parts/micro_laser)

	change_power_consumption(initial(active_power_usage) - (cap_rating * 25), POWER_USE_ACTIVE)
	max_n_of_items = initial(max_n_of_items) + floor(bin_rating)
	cooking_power = initial(cooking_power) + (las_rating / 3)
