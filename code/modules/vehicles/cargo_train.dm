/obj/vehicle/train/cargo/engine
	name = "cargo train tug"
	desc = "A rideable electric car designed for pulling cargo trolleys."
	icon = 'icons/obj/vehicles.dmi'
	icon_state = "cargo_engine"
	on = 0
	powered = 1
	locked = 0
	load_item_visible = 1
	load_offset_x = 0
	buckle_pixel_shift = list("x" = 0, "y" = 0, "z" = 7)
	charge_use = 1 KILOWATTS
	active_engines = 1
	var/car_limit = 3		//how many cars an engine can pull before performance degrades
	var/obj/item/key/cargo_train/key

/obj/item/key/cargo_train
	desc = "A small key on a yellow fob reading \"Choo Choo!\"."
	material = /decl/material/solid/metal/steel
	matter = list(
		/decl/material/solid/organic/plastic = MATTER_AMOUNT_REINFORCEMENT
	)
	icon = 'icons/obj/vehicles.dmi'
	icon_state = "train_keys"
	w_class = ITEM_SIZE_TINY

/obj/vehicle/train/cargo/trolley
	name = "cargo train trolley"
	icon = 'icons/obj/vehicles.dmi'
	icon_state = "cargo_trailer"
	anchored = FALSE
	passenger_allowed = 0
	locked = 0
	buckle_pixel_shift = list("x" = 0, "y" = 0, "z" = 8)

	load_item_visible = 1
	load_offset_x = 0
	load_offset_y = 4


//-------------------------------------------
// Standard procs
//-------------------------------------------
/obj/vehicle/train/cargo/engine/Initialize()
	. = ..()
	cell = new /obj/item/cell/high(src)
	key = new(src)
	var/image/I = new(icon = icon, icon_state = "cargo_engine_overlay")
	I.plane = plane
	I.layer = layer
	overlays += I
	turn_off()	//so engine verbs are correctly set

/obj/vehicle/train/cargo/engine/Move(var/turf/destination)
	if(on && cell.charge < (charge_use * CELLRATE))
		turn_off()
		update_stats()
		if(load && is_train_head())
			to_chat(load, "The drive motor briefly whines, then drones to a stop.")

	if(is_train_head() && !on)
		return 0

	//space check ~no flying space trains sorry
	if(on && isspaceturf(destination))
		return 0

	return ..()

/obj/vehicle/train/cargo/trolley/attackby(obj/item/used_item, mob/user)
	if(open && IS_WIRECUTTER(used_item))
		passenger_allowed = !passenger_allowed
		user.visible_message("<span class='notice'>[user] [passenger_allowed ? "cuts" : "mends"] a cable in [src].</span>","<span class='notice'>You [passenger_allowed ? "cut" : "mend"] the load limiter cable.</span>")
		return TRUE
	return ..()

/obj/vehicle/train/cargo/engine/attackby(obj/item/used_item, mob/user)
	if(istype(used_item, /obj/item/key/cargo_train))
		if(!key && user.try_unequip(used_item, src))
			key = used_item
			verbs += /obj/vehicle/train/cargo/engine/verb/remove_key
		return TRUE
	return ..()

//cargo trains are open topped, so there is a chance the projectile will hit the mob ridding the train instead
/obj/vehicle/train/cargo/bullet_act(var/obj/item/projectile/Proj)
	if(buckled_mob && prob(70))
		buckled_mob.bullet_act(Proj)
		return
	..()

/obj/vehicle/train/cargo/on_update_icon()
	if(open)
		icon_state = initial(icon_state) + "_open"
	else
		icon_state = initial(icon_state)

/obj/vehicle/train/cargo/trolley/insert_cell(var/obj/item/cell/cell, var/mob/living/human/H)
	return

/obj/vehicle/train/cargo/engine/insert_cell(var/obj/item/cell/cell, var/mob/living/human/H)
	..()
	update_stats()

/obj/vehicle/train/cargo/engine/remove_cell(var/mob/living/human/H)
	..()
	update_stats()

/obj/vehicle/train/cargo/engine/Bump(atom/Obstacle)
	var/obj/machinery/door/D = Obstacle
	var/mob/living/human/H = load
	if(istype(D) && istype(H))
		D.Bumped(H)		//a little hacky, but hey, it works, and respects access rights

	..()

/obj/vehicle/train/cargo/trolley/Bump(atom/Obstacle)
	if(!lead)
		return //so people can't knock others over by pushing a trolley around
	..()

//-------------------------------------------
// Train procs
//-------------------------------------------
/obj/vehicle/train/cargo/engine/turn_on()
	if(!key)
		return
	else
		..()
		update_stats()

		verbs -= /obj/vehicle/train/cargo/engine/verb/stop_engine
		verbs -= /obj/vehicle/train/cargo/engine/verb/start_engine

		if(on)
			verbs += /obj/vehicle/train/cargo/engine/verb/stop_engine
		else
			verbs += /obj/vehicle/train/cargo/engine/verb/start_engine

/obj/vehicle/train/cargo/engine/turn_off()
	..()

	verbs -= /obj/vehicle/train/cargo/engine/verb/stop_engine
	verbs -= /obj/vehicle/train/cargo/engine/verb/start_engine

	if(!on)
		verbs += /obj/vehicle/train/cargo/engine/verb/start_engine
	else
		verbs += /obj/vehicle/train/cargo/engine/verb/stop_engine

/obj/vehicle/train/cargo/crossed_mob(var/mob/living/victim)
	victim.apply_effects(5, 5)
	for(var/i = 1 to rand(1,5))
		var/obj/item/organ/external/E = pick(victim.get_external_organs())
		if(E)
			victim.apply_damage(rand(5,10), BRUTE, E.organ_tag)

/obj/vehicle/train/cargo/trolley/crossed_mob(var/mob/living/victim)
	..()
	attack_log += text("\[[time_stamp()]\] <font color='red'>ran over [victim.name] ([victim.ckey])</font>")

/obj/vehicle/train/cargo/engine/crossed_mob(var/mob/living/victim)
	..()
	if(is_train_head() && ishuman(load))
		var/mob/living/human/D = load
		to_chat(D, "<span class='danger'>You ran over \the [victim]!</span>")
		visible_message("<span class='danger'>\The [src] ran over \the [victim]!</span>")
		attack_log += text("\[[time_stamp()]\] <font color='red'>ran over [victim.name] ([victim.ckey]), driven by [D.name] ([D.ckey])</font>")
		msg_admin_attack("[D.name] ([D.ckey]) ran over [victim.name] ([victim.ckey]). (<A HREF='byond://?_src_=holder;adminplayerobservecoodjump=1;X=[src.x];Y=[src.y];Z=[src.z]'>JMP</a>)")
	else
		attack_log += text("\[[time_stamp()]\] <font color='red'>ran over [victim.name] ([victim.ckey])</font>")


//-------------------------------------------
// Interaction procs
//-------------------------------------------
/obj/vehicle/train/cargo/engine/relaymove(mob/user, direction)
	if(user != load || user.incapacitated())
		return 0

	if(is_train_head())
		if(direction == global.reverse_dir[dir] && tow)
			return 0
		if(Move(get_step(src, direction)))
			return 1
		return 0
	else
		return ..()

/obj/vehicle/train/cargo/engine/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	if(distance <= 1)
		. += "The power light is [on ? "on" : "off"].\nThere are[key ? "" : " no"] keys in the ignition."
		. += "The charge meter reads [cell? round(cell.percent(), 0.01) : 0]%"

/obj/vehicle/train/cargo/engine/verb/start_engine()
	set name = "Start engine"
	set category = "Object"
	set src in view(0)

	if(!ishuman(usr))
		return

	if(on)
		to_chat(usr, "The engine is already running.")
		return

	turn_on()
	if (on)
		to_chat(usr, "You start [src]'s engine.")
	else
		if(cell.charge < charge_use)
			to_chat(usr, "[src] is out of power.")
		else
			to_chat(usr, "[src]'s engine won't start.")

/obj/vehicle/train/cargo/engine/verb/stop_engine()
	set name = "Stop engine"
	set category = "Object"
	set src in view(0)

	if(!ishuman(usr))
		return

	if(!on)
		to_chat(usr, "The engine is already stopped.")
		return

	turn_off()
	if (!on)
		to_chat(usr, "You stop [src]'s engine.")

/obj/vehicle/train/cargo/engine/verb/remove_key()
	set name = "Remove key"
	set category = "Object"
	set src in view(0)

	if(!ishuman(usr))
		return

	if(!key || (load && load != usr))
		return

	if(on)
		turn_off()

	usr.put_in_hands(key)
	key = null

	verbs -= /obj/vehicle/train/cargo/engine/verb/remove_key

//-------------------------------------------
// Loading/unloading procs
//-------------------------------------------
/obj/vehicle/train/cargo/trolley/load(var/atom/movable/loading)
	if(ismob(loading) && !passenger_allowed)
		return 0
	if(!istype(loading,/obj/machinery) && !istype(loading,/obj/structure/closet) && !istype(loading,/obj/structure/largecrate) && !istype(loading,/obj/structure/reagent_dispensers) && !istype(loading,/obj/structure/ore_box) && !ishuman(loading))
		return 0

	//if there are any items you don't want to be able to interact with, add them to this check
	// ~no more shielded, emitter armed death trains
	if(istype(loading, /obj/machinery))
		load_object(loading)
	else
		..()

	if(load)
		return 1

/obj/vehicle/train/cargo/engine/load(var/atom/movable/loading)
	if(!ishuman(loading))
		return 0

	return ..()

//Load the object "inside" the trolley and add an overlay of it.
//This prevents the object from being interacted with until it has
// been unloaded. A dummy object is loaded instead so the loading
// code knows to handle it correctly.
/obj/vehicle/train/cargo/trolley/proc/load_object(var/atom/movable/loading)
	if(!isturf(loading.loc)) //To prevent loading things from someone's inventory, which wouldn't get handled properly.
		return 0
	if(load || loading.anchored)
		return 0

	var/datum/vehicle_dummy_load/dummy_load = new()
	load = dummy_load

	if(!load)
		return
	dummy_load.actual_load = loading
	loading.forceMove(src)

	if(load_item_visible)
		loading.pixel_x += load_offset_x
		loading.pixel_y += load_offset_y
		loading.plane = plane
		loading.layer = VEHICLE_LOAD_LAYER

		overlays += loading

		//we can set these back now since we have already cloned the icon into the overlay
		loading.pixel_x = initial(loading.pixel_x)
		loading.pixel_y = initial(loading.pixel_y)
		loading.reset_plane_and_layer()

/obj/vehicle/train/cargo/trolley/unload(var/mob/user, var/direction)
	if(istype(load, /datum/vehicle_dummy_load))
		var/datum/vehicle_dummy_load/dummy_load = load
		load = dummy_load.actual_load
		dummy_load.actual_load = null
		qdel(dummy_load)
		overlays.Cut()
	..()

//-------------------------------------------
// Latching/unlatching procs
//-------------------------------------------

/obj/vehicle/train/cargo/engine/latch(obj/vehicle/train/T, mob/user)
	if(!istype(T) || !Adjacent(T))
		return 0

	//if we are attaching a trolley to an engine we don't care what direction
	// it is in and it should probably be attached with the engine in the lead
	if(istype(T, /obj/vehicle/train/cargo/trolley))
		T.attach_to(src, user)
	else
		var/T_dir = get_dir(src, T)	//figure out where T is wrt src

		if(dir == T_dir) 	//if car is ahead
			src.attach_to(T, user)
		else if(global.reverse_dir[dir] == T_dir)	//else if car is behind
			T.attach_to(src, user)

//-------------------------------------------------------
// Stat update procs
//
// Update the trains stats for speed calculations.
// The longer the train, the slower it will go. car_limit
// sets the max number of cars one engine can pull at
// full speed. Adding more cars beyond this will slow the
// train proportionate to the length of the train. Adding
// more engines increases this limit by car_limit per
// engine.
//-------------------------------------------------------
/obj/vehicle/train/cargo/engine/update_car(var/train_length, var/active_engines)
	src.train_length = train_length
	src.active_engines = active_engines

	//Update move delay
	if(!is_train_head() || !on)
		move_delay = initial(move_delay)		//so that engines that have been turned off don't lag behind
	else
		move_delay = max(0, (-car_limit * active_engines) + train_length - active_engines) // limits base overweight so you cant overspeed trains
		move_delay *= (1 / max(1, active_engines)) * 2                                     // overweight penalty (scaled by the number of engines)
		move_delay += get_config_value(/decl/config/num/movement_run)      // base reference speed
		move_delay *= 1.1                                                                  // makes cargo trains 10% slower than running when not overweight

/obj/vehicle/train/cargo/trolley/update_car(var/train_length, var/active_engines)
	src.train_length = train_length
	src.active_engines = active_engines

	if(!lead && !tow)
		anchored = FALSE
	else
		anchored = TRUE
