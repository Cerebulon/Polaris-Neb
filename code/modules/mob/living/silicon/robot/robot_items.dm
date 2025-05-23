//A portable analyzer, for research borgs.  This is better then giving them a gripper which can hold anything and letting them use the normal analyzer.
/obj/item/portable_destructive_analyzer
	name = "portable destructive analyzer"
	icon = 'icons/obj/items/borg_module/borg_rnd_analyser.dmi'
	icon_state = "portable_analyzer"
	desc = "Similar to the stationary version, this rather unwieldy device allows you to break down objects in the name of science."
	material = /decl/material/solid/organic/plastic
	matter = list(
		/decl/material/solid/metal/copper = MATTER_AMOUNT_REINFORCEMENT,
		/decl/material/solid/metal/steel  = MATTER_AMOUNT_REINFORCEMENT,
		/decl/material/solid/silicon      = MATTER_AMOUNT_REINFORCEMENT,
	)
	var/obj/item/loaded_item
	var/list/saved_tech_levels = list()

/obj/item/portable_destructive_analyzer/attack_self(mob/user)
	if(!loaded_item)
		to_chat(user, SPAN_WARNING("There is nothing loaded inside \the [src]."))
		return TRUE
	var/choice = input("Do you wish to eject or analyze \the [loaded_item]?", "Portable Analyzer") as null|anything in list("Eject", "Analyze")
	if(!choice || QDELETED(loaded_item) || user.incapacitated() || loc != user)
		return TRUE
	if(choice == "Eject")
		loaded_item.dropInto(user.loc)
		loaded_item = null
		return TRUE
	var/confirm = alert(user, "This will destroy the item inside forever. Are you sure?","Confirm Analyze","Yes","No")
	if(confirm == "Yes" && !QDELETED(loaded_item) && !user.incapacitated() && loc == user)
		to_chat(user, "You activate the analyzer's microlaser, analyzing \the [loaded_item] and breaking it down.")
		var/list/tech_found = cached_json_decode(loaded_item.get_origin_tech())
		for(var/tech in tech_found)
			if(saved_tech_levels[tech] == tech_found[tech])
				saved_tech_levels[tech] = (tech_found[tech]+1)
			else if(saved_tech_levels[tech] < tech_found[tech])
				saved_tech_levels[tech] = tech_found[tech]

		flick("portable_analyzer_scan", src)
		QDEL_NULL(loaded_item)

/obj/item/portable_destructive_analyzer/afterattack(var/atom/target, var/mob/living/user, proximity)
	if(!istype(target,/obj/item) || !proximity || !isturf(target.loc))
		return

	if(istype(target, /obj/machinery/design_database))
		var/obj/machinery/design_database/db = target
		var/transferred = FALSE
		for(var/tech in saved_tech_levels)
			if(db.tech_levels[tech] < saved_tech_levels[tech])
				db.tech_levels[tech] = saved_tech_levels[tech]
				transferred = TRUE
		if(transferred)
			to_chat(user, SPAN_NOTICE("You transfer your saved data into the storage volume of \the [src]."))
		else
			to_chat(user, SPAN_NOTICE("You have no saved data that \the [src] doesn't already have!"))
		return TRUE

	if(loaded_item)
		to_chat(user, SPAN_WARNING("\The [src] already has something inside.  Analyze or eject it first."))
		return
	var/obj/item/I = target
	var/tech = I.get_origin_tech()
	if(!tech)
		to_chat(user, SPAN_WARNING("\The [I] has no interesting data to analyze."))
		return
	I.forceMove(src)
	loaded_item = I
	visible_message(SPAN_NOTICE("\The [user] adds \the [I] to \the [src]."))
	flick("portable_analyzer_load", src)
	icon_state = "portable_analyzer_full"

/obj/item/portable_destructive_analyzer/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	if(distance <= 1)
		if(loaded_item)
			. += "It is holding \the [loaded_item]."
		. += "It has the following data saved:"
		for(var/tech in saved_tech_levels)
			. += "[tech]: [saved_tech_levels[tech]]"

//This is used to unlock other borg covers.
/obj/item/card/robot //This is not a child of id cards, as to avoid dumb typechecks on computers.
	name = "access code transmission device"
	icon_state = "emag"
	desc = "A circuit grafted onto the bottom of an ID card.  It is used to transmit access codes into other robot chassis, \
	allowing you to lock and unlock other robots' panels."

//A harvest item for serviceborgs.
/obj/item/robot_harvester
	name = "auto harvester"
	desc = "A hand-held harvest tool that resembles a sickle.  It uses energy to cut plant matter very efficiently."
	icon = 'icons/obj/items/borg_module/autoharvester.dmi'
	icon_state = "autoharvester"
	max_health = ITEM_HEALTH_NO_DAMAGE

/obj/item/robot_harvester/afterattack(var/atom/target, var/mob/living/user, proximity)
	if(!target)
		return
	if(!proximity)
		return
	if(istype(target,/obj/machinery/portable_atmospherics/hydroponics))
		var/obj/machinery/portable_atmospherics/hydroponics/T = target
		if(T.harvest) //Try to harvest, assuming it's alive.
			T.harvest(user)
		else if(T.dead) //It's probably dead otherwise.
			T.remove_dead(user)
	else
		to_chat(user, "Harvesting \a [target] is not the purpose of this tool. \The [src] is for plants being grown.")

// A special tray for the service droid. Allow droid to pick up and drop items as if they were using the tray normally
// Click on table to unload, click on item to load. Otherwise works identically to a tray.
// Unlike the base item "tray", robotrays ONLY pick up food, drinks and condiments.

/obj/item/plate/tray/robotray
	name = "RoboTray"
	desc = "An autoloading tray specialized for carrying refreshments."

// A special pen for service droids. Can be toggled to switch between normal writting mode, and paper rename mode
// Allows service droids to rename paper items.

/obj/item/pen/robopen
	name = "printing pen"
	var/mode = 1

/obj/item/pen/robopen/make_pen_description()
	desc = "\A [stroke_color_name] [medium_name] printing attachment with a paper naming mode."

/obj/item/pen/robopen/attack_self(mob/user)

	var/choice = input("Would you like to change colour or mode?") as null|anything in list("Colour","Mode")
	if(!choice)
		return

	playsound(src.loc, 'sound/effects/pop.ogg', 50, 0)

	switch(choice)

		if("Colour")
			var/newcolour = input("Which colour would you like to use?") as null|anything in list("black","blue","red","green","yellow")
			if(newcolour)
				set_medium_color(newcolour, newcolour)

		if("Mode")
			if (mode == 1)
				mode = 2
			else
				mode = 1
			to_chat(user, "Changed printing mode to '[mode == 2 ? "Rename Paper" : "Write Paper"]'")

	return

// Copied over from paper's rename verb
// see code/modules/paperwork/paper.dm line 62

/obj/item/pen/robopen/proc/RenamePaper(mob/user, obj/item/paper/paper)
	if ( !user || !paper )
		return
	var/n_name = sanitize_safe(input(user, "What would you like to label the paper?", "Paper Labelling", null)  as text, 32)
	if ( !user || !paper )
		return

	//n_name = copytext(n_name, 1, 32)
	if(( get_dist(user,paper) <= 1  && user.stat == CONSCIOUS))
		paper.SetName("paper[(n_name ? text("- '[n_name]'") : null)]")
		paper.last_modified_ckey = user.ckey
	add_fingerprint(user)
	return

//TODO: Add prewritten forms to dispense when you work out a good way to store the strings.
/obj/item/form_printer
	//name = "paperwork printer"
	name = "paper dispenser"
	icon = 'icons/obj/items/paper_bin.dmi'
	icon_state = "paper_bin1"
	item_state = "sheet-metal"
	max_health = ITEM_HEALTH_NO_DAMAGE

/obj/item/form_printer/use_on_mob(mob/living/target, mob/living/user, animate = TRUE)
	return FALSE

/obj/item/form_printer/afterattack(atom/target, mob/living/user, proximity, params)
	if(istype(target) && !istype(target, /obj/screen) && proximity)
		deploy_paper(get_turf(target))

/obj/item/form_printer/attack_self(mob/user)
	deploy_paper(get_turf(src))

/obj/item/form_printer/proc/deploy_paper(var/turf/T)
	T.visible_message(SPAN_NOTICE("\The [src.loc] dispenses a sheet of crisp white paper."))
	new /obj/item/paper(T)

//Personal shielding for the combat module.
/obj/item/borg/combat/shield
	name = "personal shielding"
	desc = "A powerful experimental module that turns aside or absorbs incoming attacks at the cost of charge."
	icon = 'icons/obj/signs/warnings.dmi'
	icon_state = "shock"
	var/shield_level = 0.5 //Percentage of damage absorbed by the shield.

/obj/item/borg/combat/shield/verb/set_shield_level()
	set name = "Set shield level"
	set category = "Object"
	set src in range(0)

	var/N = input("How much damage should the shield absorb?") in list("5","10","25","50","75","100")
	if (N)
		shield_level = text2num(N)/100

/obj/item/borg/combat/mobility
	name = "mobility module"
	desc = "By retracting limbs and tucking in its head, a combat android can roll at high speeds."
	icon = 'icons/obj/signs/warnings.dmi'
	icon_state = "shock"

/obj/item/inflatable_dispenser
	name = "inflatables dispenser"
	desc = "Hand-held device which allows rapid deployment and removal of inflatables."
	icon = 'icons/obj/items/inflatable_dispenser.dmi'
	icon_state = "inf_deployer"
	w_class = ITEM_SIZE_LARGE
	material = /decl/material/solid/metal/steel

	var/stored_walls = 5
	var/stored_doors = 2
	var/max_walls = 5
	var/max_doors = 2
	var/mode = 0 // 0 - Walls   1 - Doors

/obj/item/inflatable_dispenser/robot
	w_class = ITEM_SIZE_HUGE
	stored_walls = 10
	stored_doors = 5
	max_walls = 10
	max_doors = 5
	max_health = ITEM_HEALTH_NO_DAMAGE

/obj/item/inflatable_dispenser/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	. += "It has [stored_walls] wall segment\s and [stored_doors] door segment\s stored."
	. += "It is set to deploy [mode ? "doors" : "walls"]"

/obj/item/inflatable_dispenser/attack_self(mob/user)
	mode = !mode
	to_chat(user, "You set \the [src] to deploy [mode ? "doors" : "walls"].")

/obj/item/inflatable_dispenser/afterattack(var/atom/A, var/mob/user)
	..(A, user)
	if(!user)
		return
	if(!user.Adjacent(A))
		to_chat(user, "You can't reach!")
		return
	if(isturf(A))
		try_deploy_inflatable(A, user)
	if(istype(A, /obj/item/inflatable) || istype(A, /obj/structure/inflatable))
		pick_up(A, user)

/obj/item/inflatable_dispenser/proc/try_deploy_inflatable(var/turf/T, var/mob/living/user)
	if(mode) // Door deployment
		if(!stored_doors)
			to_chat(user, "\The [src] is out of doors!")
			return

		if(T && istype(T))
			new /obj/structure/inflatable/door(T)
			stored_doors--

	else // Wall deployment
		if(!stored_walls)
			to_chat(user, "\The [src] is out of walls!")
			return

		if(T && istype(T))
			new /obj/structure/inflatable/wall(T)
			stored_walls--

	playsound(T, 'sound/items/zip.ogg', 75, 1)
	to_chat(user, "You deploy the inflatable [mode ? "door" : "wall"]!")

/obj/item/inflatable_dispenser/proc/pick_up(var/obj/A, var/mob/living/user)
	if(istype(A, /obj/structure/inflatable))
		if(istype(A, /obj/structure/inflatable/wall))
			if(stored_walls >= max_walls)
				to_chat(user, "\The [src] is full.")
				return
			stored_walls++
			qdel(A)
		else
			if(stored_doors >= max_doors)
				to_chat(user, "\The [src] is full.")
				return
			stored_doors++
			qdel(A)
		playsound(loc, 'sound/machines/hiss.ogg', 75, 1)
		visible_message("\The [user] deflates \the [A] with \the [src]!")
		return
	if(istype(A, /obj/item/inflatable))
		if(istype(A, /obj/item/inflatable/door))
			if(stored_doors >= max_doors)
				to_chat(user, "\The [src] is full!")
				return
			stored_doors++
			qdel(A)
		else
			if(stored_walls >= max_walls)
				to_chat(user, "\The [src] is full.")
				return
			stored_walls++
			qdel(A)
		visible_message("\The [user] picks up \the [A] with \the [src]!")
		return

	to_chat(user, "You fail to pick up \the [A] with \the [src].")
	return

/obj/item/chems/spray/cleaner/drone
	name = "space cleaner"
	desc = "BLAM!-brand non-foaming space cleaner!"
	volume = 150

/obj/item/robot_rack
	name = "a generic robot rack"
	desc = "A rack for carrying large items as a robot."
	max_health = ITEM_HEALTH_NO_DAMAGE
	var/object_type                    //The types of object the rack holds (subtypes are allowed).
	var/interact_type                  //Things of this type will trigger attack_hand when attacked by this.
	var/capacity = 1                   //How many objects can be held.
	var/list/obj/item/held = list()    //What is being held.

/obj/item/robot_rack/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	. += "It can hold up to [capacity] item\s."

/obj/item/robot_rack/Initialize(mapload, starting_objects = 0)
	. = ..()
	for(var/i = 1, i <= min(starting_objects, capacity), i++)
		held += new object_type(src)

/obj/item/robot_rack/attack_self(mob/user)
	if(!length(held))
		to_chat(user, "<span class='notice'>The rack is empty.</span>")
		return
	var/obj/item/rack = held[length(held)]
	rack.dropInto(loc)
	held -= rack
	rack.attack_self(user) // deploy it
	to_chat(user, "<span class='notice'>You deploy [rack].</span>")
	rack.add_fingerprint(user)

/obj/item/robot_rack/resolve_attackby(obj/O, mob/user, click_params)
	if(istype(O, object_type))
		if(length(held) < capacity)
			to_chat(user, "<span class='notice'>You collect [O].</span>")
			O.forceMove(src)
			held += O
			return
		to_chat(user, "<span class='notice'>\The [src] is full and can't store any more items.</span>")
		return
	if(istype(O, interact_type))
		return O.attack_hand(user)
	. = ..()

/obj/item/bioreactor
	name = "bioreactor"
	desc = "An integrated power generator that runs on most kinds of biomass."
	icon = 'icons/obj/power.dmi'
	icon_state = "portgen0"
	max_health = ITEM_HEALTH_NO_DAMAGE

	var/base_power_generation = 75 KILOWATTS
	var/max_fuel_items = 5
	var/list/fuel_types = list(
		/obj/item/food/butchery/meat = 2,
		/obj/item/food/butchery/meat/fish = 1.5
	)

/obj/item/bioreactor/attack_self(var/mob/user)
	if(contents.len >= 1)
		var/obj/item/removing = contents[1]
		user.put_in_hands(removing)
		to_chat(user, SPAN_NOTICE("You remove \the [removing] from \the [src]."))
	else
		to_chat(user, SPAN_WARNING("There is nothing loaded into \the [src]."))

/obj/item/bioreactor/afterattack(var/atom/movable/target, var/mob/user, var/proximity_flag, var/click_parameters)
	if(!proximity_flag || !istype(target))
		return

	var/is_fuel = istype(target, /obj/item/food/grown)
	is_fuel = is_fuel || is_type_in_list(target, fuel_types)

	if(!is_fuel)
		to_chat(user, SPAN_WARNING("\The [target] cannot be used as fuel by \the [src]."))
		return

	if(contents.len >= max_fuel_items)
		to_chat(user, SPAN_WARNING("\The [src] can fit no more fuel inside."))
		return
	target.forceMove(src)
	to_chat(user, SPAN_NOTICE("You load \the [target] into \the [src]."))

/obj/item/bioreactor/Initialize()
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/bioreactor/Destroy()
	STOP_PROCESSING(SSobj, src)
	. = ..()

/obj/item/bioreactor/Process()
	var/mob/living/silicon/robot/robot = loc
	if(!istype(robot) || !robot.cell || robot.cell.fully_charged() || !contents.len)
		return

	var/generating_power
	var/using_item

	for(var/thing in contents)
		var/atom/A = thing
		if(istype(A, /obj/item/food/grown))
			generating_power = base_power_generation
			using_item = A
		else
			for(var/fuel_type in fuel_types)
				if(istype(A, fuel_type))
					generating_power = fuel_types[fuel_type] * base_power_generation
					using_item = A
					break
		if(using_item)
			break

	if(istype(using_item, /obj/item/stack))
		var/obj/item/stack/stack = using_item
		stack.use(1)
	else if(using_item)
		qdel(using_item)

	if(generating_power)
		robot.cell.give(generating_power * CELLRATE)
