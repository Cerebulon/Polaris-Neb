//Simple borg hand.
//Limited use.
/obj/item/gripper
	name = "magnetic gripper"
	desc = "A simple grasping tool specialized in construction and engineering work."
	icon = 'icons/obj/items/borg_module/borg_gripper.dmi'
	icon_state = "gripper"
	max_health = ITEM_HEALTH_NO_DAMAGE
	item_flags = ITEM_FLAG_NO_BLUDGEON

	//Has a list of items that it can hold.
	var/list/can_hold = list(
		/obj/item/cell,
		/obj/item/stock_parts/circuitboard/airlock_electronics,
		/obj/item/tracker_electronics,
		/obj/item/stock_parts,
		/obj/item/frame,
		/obj/item/frame/camera/kit,
		/obj/item/tank,
		/obj/item/stock_parts/circuitboard,
		/obj/item/stock_parts/smes_coil,
		/obj/item/stock_parts/computer,
		/obj/item/fuel_assembly,
		/obj/item/stack/material/crystal/mapped/phoron,
		/obj/item/stack/material/aerogel/mapped/deuterium,
		/obj/item/stack/material/aerogel/mapped/tritium,
		/obj/item/stack/tile
		)

	var/obj/item/wrapped = null // Item currently being held.

// VEEEEERY limited version for mining borgs. Basically only for swapping cells and upgrading the drills.
/obj/item/gripper/miner
	name = "drill maintenance gripper"
	desc = "A simple grasping tool for the maintenance of heavy drilling machines."

	icon_state = "gripper-mining"

	can_hold = list(
		/obj/item/cell,
		/obj/item/stock_parts,
		/obj/item/stock_parts/circuitboard/miningdrill
	)

/obj/item/gripper/clerical
	name = "clerical gripper"
	desc = "A simple grasping tool for clerical work."

	can_hold = list(
		/obj/item/clipboard,
		/obj/item/paper,
		/obj/item/paper_bundle,
		/obj/item/photo,
		/obj/item/card/id,
		/obj/item/book,
		/obj/item/newspaper,
		/obj/item/parcel,
		/obj/item/forensics/sample
		)

/obj/item/gripper/chemistry
	name = "chemistry gripper"
	desc = "A simple grasping tool for chemical work."

	can_hold = list(
		/obj/item/chems/glass,
		/obj/item/chems/pill,
		/obj/item/chems/ivbag,
		/obj/item/pill_bottle
	)

/obj/item/gripper/research //A general usage gripper, used for toxins/robotics/xenobio/etc
	name = "scientific gripper"
	icon_state = "gripper-sci"
	desc = "A simple grasping tool suited to assist in a wide array of research applications."

	can_hold = list(
		/obj/item/cell,
		/obj/item/stock_parts,
		/obj/item/organ/internal/brain_interface,
		/obj/item/robot_parts,
		/obj/item/borg/upgrade,
		/obj/item/flash,
		/obj/item/organ/internal/brain,
		/obj/item/stack/cable_coil,
		/obj/item/stock_parts/circuitboard,
		/obj/item/chems/glass,
		/obj/item/food/animal_cube,
		/obj/item/stock_parts/computer,
		/obj/item/transfer_valve,
		/obj/item/assembly/signaler,
		/obj/item/assembly/timer,
		/obj/item/assembly/igniter,
		/obj/item/assembly/infra,
		/obj/item/tank
		)

/obj/item/gripper/cultivator
	name = "cultivator gripper"
	icon_state = "gripper"
	desc = "A simple grasping tool used to perform tasks in the xenobiology division, such as handling plant samples and disks."
	can_hold = list(
		/obj/item/chems/glass,
		/obj/item/seeds,
		/obj/item/disk/botany
	)

/obj/item/gripper/service //Used to handle food, drinks, and seeds.
	name = "service gripper"
	icon_state = "gripper"
	desc = "A simple grasping tool used to perform tasks in the service sector, such as handling food, drinks, and seeds."
	can_hold = list(
		/obj/item/chems/glass,
		/obj/item/food,
		/obj/item/chems/drinks,
		/obj/item/chems/condiment,
		/obj/item/seeds,
		/obj/item/glass_extra
	)

/obj/item/gripper/organ //Used to handle organs.
	name = "organ gripper"
	icon_state = "gripper"
	desc = "A simple grasping tool for holding and manipulating organic and mechanical organs, both internal and external."

	can_hold = list(
		/obj/item/organ,
		/obj/item/robot_parts,
		/obj/item/chems/ivbag
	)

/obj/item/gripper/no_use //Used when you want to hold and put items in other things, but not able to 'use' the item

/obj/item/gripper/no_use/attack_self(mob/user)
	return

/obj/item/gripper/no_use/loader //This is used to disallow building with metal.
	name = "sheet loader"
	desc = "A specialized loading device, designed to pick up and insert sheets of materials inside machines."
	icon_state = "gripper-sheet"

	can_hold = list(
		/obj/item/stack/material
	)

/obj/item/gripper/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	if(wrapped)
		. += "It is holding \a [wrapped]."

/obj/item/gripper/attack_self(mob/user)
	if(wrapped)
		return wrapped.attack_self(user)
	return ..()

/obj/item/gripper/verb/drop_gripped_item()

	set name = "Drop Gripped Item"
	set desc = "Release an item from your magnetic gripper."
	set category = "Silicon Commands"
	if(!wrapped)
		// Ensure fumbled items are accessible.
		for(var/obj/item/thing in src.contents)
			thing.dropInto(loc)
		return

	if(wrapped.loc != src)
		wrapped = null
		return

	to_chat(src.loc, "<span class='warning'>You drop \the [wrapped].</span>")
	wrapped.dropInto(loc)
	wrapped = null
	//on_update_icon()

/obj/item/gripper/use_on_mob(mob/living/target, mob/living/user, animate = TRUE)
	// Don't fall through and smack people with gripper, instead just no-op
	return FALSE

/obj/item/gripper/resolve_attackby(var/atom/target, var/mob/living/user, params)

	// Ensure fumbled items are accessible.
	if(!wrapped)
		for(var/obj/item/thing in src.contents)
			wrapped = thing
			break

	if(wrapped) //Already have an item.
		//Temporary put wrapped into user so target's attackby() checks pass.
		wrapped.forceMove(user)

		//The force of the wrapped obj gets set to zero during the use_on_mob() and afterattack().
		var/force_holder = wrapped.get_base_attack_force()
		wrapped.set_base_attack_force(0)

		//Pass the attack on to the target. This might delete/relocate wrapped.
		var/resolved = wrapped.resolve_attackby(target,user,params)

		//If resolve_attackby forces waiting before taking wrapped, we need to let it finish before doing the rest.
		addtimer(CALLBACK(src, PROC_REF(finish_using), target, user, params, force_holder, resolved), 0)

	else if(istype(target,/obj/item)) //Check that we're not pocketing a mob.
		var/obj/item/I = target

		//Check if the item is blacklisted.
		var/grab = 0
		for(var/typepath in can_hold)
			if(istype(I,typepath))
				grab = 1
				break

		//We can grab the item, finally.
		if(grab)
			if(I == user.active_storage?.holder)
				user.active_storage.close(user) //Closes the ui.
			if(I.loc?.storage)
				if(!I.loc.storage.remove_from_storage(user, I, src))
					return
			else
				I.forceMove(src)
			to_chat(user, "<span class='notice'>You collect \the [I].</span>")
			wrapped = I
			return
		else
			to_chat(user, "<span class='danger'>Your gripper cannot hold \the [target].</span>")

	else if(istype(target,/obj/machinery/power/apc))
		var/obj/machinery/power/apc/A = target
		if(A.components_are_accessible(/obj/item/stock_parts/power/battery))
			var/obj/item/stock_parts/power/battery/bat = A.get_component_of_type(/obj/item/stock_parts/power/battery)
			var/obj/item/cell/cell = bat.extract_cell(src)
			if(cell)
				wrapped = cell
				cell.forceMove(src)

	else if(isrobot(target))
		var/mob/living/silicon/robot/A = target
		if(A.opened)
			if(A.cell)
				wrapped = A.cell
				A.cell.add_fingerprint(user)
				A.cell.update_icon()
				A.update_icon()
				A.cell.forceMove(src)
				A.cell = null
				user.visible_message("<span class='danger'>[user] removes the power cell from [A]!</span>", "You remove the power cell.")
				A.power_down()

/obj/item/gripper/proc/finish_using(var/atom/target, var/mob/living/user, params, force_holder, resolved)

	if(QDELETED(wrapped))
		wrapped.forceMove(null)
		wrapped = null
		return

	if(!resolved && wrapped && target)
		wrapped.afterattack(target, user, 1, params)

	if(wrapped)
		wrapped.set_base_attack_force(force_holder)

	//If wrapped was neither deleted nor put into target, put it back into the gripper.
	if(wrapped && user && !QDELETED(wrapped) && wrapped.loc == user)
		wrapped.forceMove(src)
	else
		wrapped = null

//TODO: Matter decompiler.
/obj/item/matter_decompiler
	name = "matter decompiler"
	desc = "Eating trash, bits of glass, or other debris will replenish your stores."
	icon = 'icons/obj/items/borg_module/decompiler.dmi'
	icon_state = "decompiler"
	max_health = ITEM_HEALTH_NO_DAMAGE

	//Metal, glass, wood, plastic.
	var/datum/matter_synth/metal = null
	var/datum/matter_synth/glass = null
	var/datum/matter_synth/wood = null
	var/datum/matter_synth/plastic = null

/obj/item/matter_decompiler/Destroy()
	metal = null
	glass = null
	wood = null
	plastic = null
	return ..()

/obj/item/matter_decompiler/use_on_mob(mob/living/target, mob/living/user, animate = TRUE)
	return FALSE

/obj/item/matter_decompiler/afterattack(atom/target, mob/living/user, proximity, params)

	if(!proximity) return //Not adjacent.

	//We only want to deal with using this on turfs. Specific items aren't important.
	var/turf/T = get_turf(target)
	if(!istype(T))
		return

	//Used to give the right message.
	var/grabbed_something = 0

	for(var/mob/M in T)
		if(islizard(M) || ismouse(M))
			src.loc.visible_message("<span class='danger'>[src.loc] sucks [M] into its decompiler. There's a horrible crunching noise.</span>","<span class='danger'>It's a bit of a struggle, but you manage to suck [M] into your decompiler. It makes a series of visceral crunching noises.</span>")
			new/obj/effect/decal/cleanable/blood/splatter(get_turf(src))
			qdel(M)
			if(wood)
				wood.add_charge(2000)
			if(plastic)
				plastic.add_charge(2000)
			return

		else if(isdrone(M) && !M.client)

			var/mob/living/silicon/robot/D = src.loc

			if(!istype(D))
				return

			to_chat(D, "<span class='danger'>You begin decompiling [M].</span>")

			if(!do_after(D,50,M))
				to_chat(D, "<span class='danger'>You need to remain still while decompiling such a large object.</span>")
				return

			if(!M || !D) return

			to_chat(D, "<span class='danger'>You carefully and thoroughly decompile [M], storing as much of its resources as you can within yourself.</span>")
			qdel(M)
			new/obj/effect/decal/cleanable/blood/oil(get_turf(src))

			if(metal)
				metal.add_charge(15000)
			if(glass)
				glass.add_charge(15000)
			if(wood)
				wood.add_charge(2000)
			if(plastic)
				plastic.add_charge(1000)
			return
		else
			continue

	// TODO: Jesus Christ, use matter or the procs the decompiler nades use.
	for(var/obj/thing in T)
		//Different classes of items give different commodities.
		if(istype(thing,/obj/item/trash/cigbutt))
			if(plastic)
				plastic.add_charge(500)
		else if(istype(thing,/obj/effect/spider/spiderling))
			if(wood)
				wood.add_charge(2000)
			if(plastic)
				plastic.add_charge(2000)
		else if(istype(thing,/obj/item/light))
			var/obj/item/light/L = thing
			if(L.status >= 2)
				if(metal)
					metal.add_charge(250)
				if(glass)
					glass.add_charge(250)
			else
				continue
		else if(istype(thing,/obj/item/remains/robot))
			if(metal)
				metal.add_charge(2000)
			if(plastic)
				plastic.add_charge(2000)
			if(glass)
				glass.add_charge(1000)
		else if(istype(thing,/obj/item/trash))
			if(metal)
				metal.add_charge(1000)
			if(plastic)
				plastic.add_charge(3000)
		else if(istype(thing,/obj/effect/decal/cleanable/blood/gibs/robot))
			if(metal)
				metal.add_charge(2000)
			if(glass)
				glass.add_charge(2000)
		else if(istype(thing,/obj/item/ammo_casing))
			if(metal)
				metal.add_charge(1000)
		else if(istype(thing,/obj/item/shard/shrapnel))
			if(metal)
				metal.add_charge(1000)
		else if(istype(thing,/obj/item/shard))
			if(glass)
				glass.add_charge(1000)
		else if(istype(thing,/obj/item/food/grown))
			if(wood)
				wood.add_charge(4000)
		else if(istype(thing,/obj/item/pipe))
			// This allows drones and engiborgs to clear pipe assemblies from floors.
			pass()
		else
			continue

		qdel(thing)
		grabbed_something = 1

	if(grabbed_something)
		to_chat(user, "<span class='notice'>You deploy your decompiler and clear out the contents of \the [T].</span>")
	else
		to_chat(user, "<span class='danger'>Nothing on \the [T] is useful to you.</span>")
