/obj/machinery/chemical_dispenser
	name = "chemical dispenser"
	icon = 'icons/obj/machines/chemistry/dispenser.dmi'
	icon_state = "dispenser"
	layer = BELOW_OBJ_LAYER
	clicksound = "button"
	clickvol = 20

	construct_state = /decl/machine_construction/default/panel_closed
	uncreated_component_parts = null
	stat_immune = 0
	base_type = /obj/machinery/chemical_dispenser
	var/list/spawn_cartridges = null // Set to a list of types to spawn one of each on New()

	var/list/cartridges = list() // Associative, label -> cartridge
	var/obj/item/chems/container

	var/ui_title = "Chemical Dispenser"

	var/accept_drinking = 0
	var/amount = 30

	idle_power_usage = 100
	density = TRUE
	anchored = TRUE
	obj_flags = OBJ_FLAG_ANCHORABLE
	core_skill = SKILL_CHEMISTRY
	var/can_contaminate = TRUE
	var/buildable = TRUE
	var/static/list/acceptable_containers = list(
		/obj/item/chems/glass,
		/obj/item/chems/condiment,
		/obj/item/chems/drinks
	)

	var/beaker_offset = 0
	var/beaker_positions = list(0,1)

/obj/machinery/chemical_dispenser/Initialize(mapload, d=0, populate_parts = TRUE)
	. = ..()
	if(spawn_cartridges && populate_parts)
		for(var/type in spawn_cartridges)
			add_cartridge(new type(src))

/obj/machinery/chemical_dispenser/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	. += "It has [cartridges.len] cartridges installed, and has space for [DISPENSER_MAX_CARTRIDGES - cartridges.len] more."

/obj/machinery/chemical_dispenser/proc/add_cartridge(obj/item/chems/chem_disp_cartridge/C, mob/user)
	. = FALSE
	if(!istype(C))
		if(user)
			to_chat(user, "<span class='warning'>\The [C] will not fit in \the [src]!</span>")
		return

	if(cartridges.len >= DISPENSER_MAX_CARTRIDGES)
		if(user)
			to_chat(user, "<span class='warning'>\The [src] does not have any slots open for \the [C] to fit into!</span>")
		return

	var/datum/extension/labels/lab = get_extension(C, /datum/extension/labels)
	if(!length(lab?.labels))
		if(user)
			to_chat(user, "<span class='warning'>\The [C] does not have a label!</span>")
		return

	if(cartridges[lab.labels[1]])
		if(user)
			to_chat(user, "<span class='warning'>\The [src] already contains a cartridge with that label!</span>")
		return

	if(user)
		if(user.try_unequip(C))
			to_chat(user, "<span class='notice'>You add \the [C] to \the [src].</span>")
		else
			return

	C.forceMove(src)
	cartridges[lab.labels[1]] = C
	cartridges = sortTim(cartridges, /proc/cmp_text_asc)
	SSnano.update_uis(src)
	return TRUE

/obj/machinery/chemical_dispenser/proc/remove_cartridge(label)
	. = cartridges[label]
	cartridges -= label
	SSnano.update_uis(src)

/obj/machinery/chemical_dispenser/attackby(obj/item/used_item, mob/user)
	if(istype(used_item, /obj/item/chems/chem_disp_cartridge))
		add_cartridge(used_item, user)
		return TRUE

	if(IS_CROWBAR(used_item) && !panel_open && length(cartridges))
		var/label = input(user, "Which cartridge would you like to remove?", "Chemical Dispenser") as null|anything in cartridges
		if(!label) return TRUE
		var/obj/item/chems/chem_disp_cartridge/C = remove_cartridge(label)
		if(C)
			to_chat(user, SPAN_NOTICE("You remove \the [C] from \the [src]."))
			C.dropInto(loc)
			return TRUE

	if(is_type_in_list(used_item, acceptable_containers))
		if(container)
			to_chat(user, SPAN_WARNING("There is already \a [container] on \the [src]!"))
			return TRUE

		var/obj/item/chems/new_container = used_item

		if(!accept_drinking && (istype(new_container,/obj/item/chems/condiment) || istype(new_container,/obj/item/chems/drinks)))
			to_chat(user, SPAN_WARNING("This machine only accepts beakers!"))
			return TRUE

		if(!ATOM_IS_OPEN_CONTAINER(new_container))
			to_chat(user, SPAN_WARNING("You don't see how \the [src] could dispense reagents into \the [new_container]."))
			return TRUE
		if(!user.try_unequip(new_container, src))
			return TRUE
		set_container(new_container)
		to_chat(user, SPAN_NOTICE("You set \the [new_container] on \the [src]."))
		return TRUE

	return ..()

/obj/machinery/chemical_dispenser/proc/set_container(var/obj/item/chems/new_container)
	if(container == new_container)
		return
	if(container)
		events_repository.unregister(/decl/observ/moved, container, src)
		events_repository.unregister(/decl/observ/destroyed, container, src)
	container = new_container
	if(container)
		events_repository.register(/decl/observ/moved, container, src, PROC_REF(check_container_status))
		events_repository.register(/decl/observ/destroyed, container, src, PROC_REF(check_container_status))
	update_icon()
	SSnano.update_uis(src) // update all UIs attached to src

/obj/machinery/chemical_dispenser/proc/check_container_status()
	if(container && (QDELETED(container) || container.loc != src))
		set_container(null)

/obj/machinery/chemical_dispenser/ui_interact(mob/user, ui_key = "main",var/datum/nanoui/ui = null, var/force_open = 1)
	// this is the data which will be sent to the ui
	var/data[0]
	data["amount"] = amount
	data["isBeakerLoaded"] = container ? 1 : 0
	data["glass"] = accept_drinking
	var beakerD[0]
	if(LAZYLEN(container?.reagents?.reagent_volumes))
		for(var/decl/material/reagent as anything in container.reagents.reagent_volumes)
			beakerD[++beakerD.len] = list("name" = reagent.use_name, "volume" = REAGENT_VOLUME(container.reagents, reagent))
	data["beakerContents"] = beakerD

	if(container) // Container has had null reagents in the past; may be due to qdel without clearing reference.
		data["beakerCurrentVolume"] = container.reagents?.total_volume || 0
		data["beakerMaxVolume"] = container.reagents?.maximum_volume || 0
	else
		data["beakerCurrentVolume"] = null
		data["beakerMaxVolume"] = null

	var chemicals[0]
	for(var/label in cartridges)
		var/obj/item/chems/chem_disp_cartridge/C = cartridges[label]
		chemicals[++chemicals.len] = list("label" = label, "amount" = C.reagents.total_volume)
	data["chemicals"] = chemicals

	// update the ui if it exists, returns null if no ui is passed/found
	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "chem_disp.tmpl", ui_title, 390, 680)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/obj/machinery/chemical_dispenser/OnTopic(mob/user, href_list)
	if(href_list["amount"])
		amount = round(text2num(href_list["amount"]), 1) // round to nearest 1
		amount = max(0, min(120, amount)) // Since the user can actually type the commands himself, some sanity checking
		return TOPIC_REFRESH

	if(href_list["dispense"])
		var/label = href_list["dispense"]
		if(cartridges[label] && container && ATOM_IS_OPEN_CONTAINER(container))
			var/obj/item/chems/chem_disp_cartridge/C = cartridges[label]
			var/mult = 1 + (-0.5 + round(rand(), 0.1))*(user.skill_fail_chance(core_skill, 0.3, SKILL_ADEPT))
			C.reagents.trans_to(container, amount*mult)
			var/contaminants_left = rand(0, max(SKILL_ADEPT - user.get_skill_value(core_skill), 0)) * can_contaminate
			var/choices = cartridges.Copy()
			while(length(choices) && contaminants_left)
				var/chosen_label = pick_n_take(choices)
				var/obj/item/chems/chem_disp_cartridge/choice = cartridges[chosen_label]
				if(choice == C)
					continue
				choice.reagents.trans_to(container, round(rand()*amount/5, 0.1))
				contaminants_left--
			return TOPIC_REFRESH
		return TOPIC_HANDLED

	else if(href_list["ejectBeaker"])
		if(!container)
			return TOPIC_HANDLED

		var/obj/item/chems/previous_container = container

		set_container(null)

		if(CanPhysicallyInteract(user))
			user.put_in_hands(previous_container)
		else
			previous_container.dropInto(loc)

		return TOPIC_REFRESH

/obj/machinery/chemical_dispenser/interface_interact(mob/user)
	ui_interact(user)
	return TRUE

/obj/machinery/chemical_dispenser/on_update_icon()
	cut_overlays()
	if(container)
		add_overlay(image(icon, "lil_beaker", pixel_x = pick(beaker_positions), pixel_y = beaker_offset))
