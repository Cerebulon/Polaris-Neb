#define ONLY_DEPLOY 1
#define ONLY_RETRACT 2
#define SEAL_DELAY 30

/*
 * Defines the behavior of hardsuits/rigs/power armour.
 */

/obj/item/rig
	name = "hardsuit control module"
	icon = 'icons/clothing/rigs/rig.dmi'
	icon_state = ICON_STATE_WORLD
	desc = "A back-mounted hardsuit deployment and control mechanism."
	slot_flags = SLOT_BACK
	w_class = ITEM_SIZE_HUGE
	center_of_mass = null

	// These values are passed on to all component pieces.
	armor_type = /datum/extension/armor/rig
	armor = list(
		ARMOR_MELEE = ARMOR_MELEE_RESISTANT,
		ARMOR_BULLET = ARMOR_BALLISTIC_MINOR,
		ARMOR_LASER = ARMOR_LASER_SMALL,
		ARMOR_ENERGY = ARMOR_ENERGY_MINOR,
		ARMOR_BOMB = ARMOR_BOMB_PADDED,
		ARMOR_BIO = ARMOR_BIO_SHIELDED,
		ARMOR_RAD = ARMOR_RAD_MINOR
		)
	min_cold_protection_temperature = SPACE_SUIT_MIN_COLD_PROTECTION_TEMPERATURE
	max_heat_protection_temperature = SPACE_SUIT_MAX_HEAT_PROTECTION_TEMPERATURE
	max_pressure_protection = RIG_MAX_PRESSURE
	min_pressure_protection = 0

	siemens_coefficient = 0.2
	permeability_coefficient = 0.1
	material = /decl/material/solid/metal/titanium
	matter = list(
		/decl/material/solid/fiberglass           = MATTER_AMOUNT_SECONDARY,
		/decl/material/solid/organic/plastic              = MATTER_AMOUNT_REINFORCEMENT,
		/decl/material/solid/metal/copper         = MATTER_AMOUNT_REINFORCEMENT,
		/decl/material/solid/silicon              = MATTER_AMOUNT_REINFORCEMENT,
		/decl/material/solid/metal/stainlesssteel = MATTER_AMOUNT_TRACE,
	)

	var/equipment_overlay_icon = 'icons/mob/onmob/onmob_rig_modules.dmi'
	var/hides_uniform = 1 	//used to determinate if uniform should be visible whenever the suit is sealed or not

	var/interface_path = "hardsuit.tmpl"
	var/ai_interface_path = "hardsuit.tmpl"
	var/interface_title = "Hardsuit Controller"
	var/wearer_move_delay //Used for AI moving.
	var/ai_controlled_move_delay = 10

	// Keeps track of what this rig should spawn with.
	var/suit_type = "hardsuit"
	var/list/initial_modules

	//Component/device holders.
	var/obj/item/clothing/boots  // Deployable boots, if any.
	var/obj/item/clothing/chest  // Deployable chestpiece, if any.
	var/obj/item/clothing/helmet // Deployable helmet, if any.
	var/obj/item/clothing/gloves // Deployable gauntlets, if any.
	var/obj/item/tank/air_supply = /obj/item/tank/oxygen // Starting air supply, if any.
	var/obj/item/cell/cell =       /obj/item/cell/high   // Starting cell type, if any.

	var/obj/item/rig_module/selected_module // Primary system (used with middle-click)
	var/obj/item/rig_module/vision/visor    // Kinda shitty to have a var for a module, but saves time.
	var/obj/item/rig_module/voice/speech    // As above.
	var/mob/living/human/wearer      // The person currently wearing the rig.
	var/list/installed_modules = list()     // Power consumption/use bookkeeping.

	// Rig status vars.
	var/open = 0                            // Access panel status.
	var/p_open = 0							// Wire panel status
	var/locked = 1                          // Lock status.
	var/subverted = 0
	var/interface_locked = 0
	var/control_overridden = 0
	var/ai_override_enabled = 0
	var/security_check_enabled = 1
	var/malfunctioning = 0
	var/malfunction_delay = 0
	var/electrified = 0
	var/locked_down = 0
	var/aimove_power_usage = 200							  // Power usage per tile travelled when suit is moved by AI in IIS. In joules.

	var/seal_delay = SEAL_DELAY
	var/sealing                                               // Keeps track of seal status independantly of canremove.
	var/offline = 1                                           // Should we be applying suit maluses?
	var/online_slowdown = 0                                   // If the suit is deployed and powered, it sets slowdown to this.
	var/offline_slowdown = 3                                  // If the suit is deployed and unpowered, it sets slowdown to this.
	var/vision_restriction = TINT_NONE
	var/offline_vision_restriction = TINT_HEAVY               // tint value given to helmet
	var/airtight = 1 //If set, will adjust ITEM_FLAG_AIRTIGHT flags on components. Otherwise it should leave them untouched.
	var/visible_name
	var/update_visible_name = FALSE

	var/emp_protection = 0

	// Wiring! How exciting.
	var/datum/wires/rig/wires

	var/banned_modules = list()

	var/list/original_access // Used to restore access after emagging/mending

/obj/item/rig/get_stored_inventory()
	. = ..()
	if(length(.))
		for(var/obj/thing in list(boots, chest, helmet, gloves, air_supply, cell))
			. -= thing

/obj/item/rig/get_cell()
	return cell

/obj/item/rig/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	if(wearer)
		for(var/obj/item/piece in list(helmet,gloves,chest,boots))
			if(!piece || piece.loc != wearer)
				continue
			. += "[html_icon(piece)] \The [piece] [piece.gender == PLURAL ? "are" : "is"] deployed."
	if(src.loc == user)
		. += "The access panel is [locked? "locked" : "unlocked"]."
		. += "The maintenance panel is [open ? "open" : "closed"]."
		. += "The wire panel is [p_open ? "open" : "closed"]."
		. += "Hardsuit systems are [offline ? SPAN_BAD("offline") : SPAN_GOOD("online")]."
		if(open)
			. += "It's equipped with [english_list(installed_modules)]."

/obj/item/rig/Initialize()
	. = ..()
	wires = new(src)

	if(!length(req_access))
		locked = 0
	original_access = req_access?.Copy()

	START_PROCESSING(SSobj, src)

	if(initial_modules && initial_modules.len)
		for(var/path in initial_modules)
			var/obj/item/rig_module/module = new path(src)
			installed_modules += module
			module.installed(src)

	// Create and initialize our various segments.
	if(ispath(cell))
		cell = new cell(src)
	if(ispath(air_supply))
		air_supply = new air_supply(src)
	if(ispath(gloves))
		gloves = new gloves(src)
		verbs |= /obj/item/rig/proc/toggle_gauntlets
	if(ispath(helmet))
		helmet = new helmet(src)
		verbs |= /obj/item/rig/proc/toggle_helmet
	if(ispath(boots))
		boots = new boots(src)
		verbs |= /obj/item/rig/proc/toggle_boots
	if(ispath(chest))
		chest = new chest(src)
		if(allowed)
			chest.allowed = allowed
		verbs |= /obj/item/rig/proc/toggle_chest

	for(var/obj/item/piece in list(gloves,helmet,boots,chest))
		if(!istype(piece))
			continue
		piece.canremove = 0
		piece.SetName("[suit_type] [initial(piece.name)]")
		piece.desc = "It seems to be part of \a [src]."
		piece.min_cold_protection_temperature = min_cold_protection_temperature
		piece.max_heat_protection_temperature = max_heat_protection_temperature
		if(piece.siemens_coefficient > siemens_coefficient) //So that insulated gloves keep their insulation.
			piece.siemens_coefficient = siemens_coefficient
		piece.permeability_coefficient = permeability_coefficient
		if(islist(armor))
			piece.armor = armor.Copy() // codex reads the armor list, not extensions. this list does not have any effect on in game mechanics
			remove_extension(piece, /datum/extension/armor)
			set_extension(piece, armor_type, armor, armor_degradation_speed)

	set_slowdown_and_vision(!offline)
	update_icon()

/obj/item/rig/Destroy()
	QDEL_NULL(gloves)
	QDEL_NULL(boots)
	QDEL_NULL(helmet)
	QDEL_NULL(chest)
	QDEL_NULL(wires)
	QDEL_NULL(air_supply)
	QDEL_NULL(cell)
	QDEL_NULL(selected_module)
	QDEL_NULL(visor)
	QDEL_NULL(speech)
	QDEL_LIST(installed_modules)
	wearer = null
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/rig/proc/set_slowdown_and_vision(var/active)
	if(chest)
		LAZYSET(chest.slowdown_per_slot, slot_wear_suit_str, (active? online_slowdown : offline_slowdown))
	if(helmet)
		helmet.tint = (active? vision_restriction : offline_vision_restriction)
		helmet.update_wearer_vision()

/obj/item/rig/proc/suit_is_deployed()
	if(!istype(wearer) || src.loc != wearer || wearer.get_equipped_item(slot_back_str) != src)
		return 0
	if(helmet && wearer.get_equipped_item(slot_head_str) != helmet)
		return 0
	if(gloves && wearer.get_equipped_item(slot_gloves_str) != gloves)
		return 0
	if(boots && wearer.get_equipped_item(slot_shoes_str) != boots)
		return 0
	if(chest && wearer.get_equipped_item(slot_wear_suit_str) != chest)
		return 0
	return 1

/obj/item/rig/proc/reset()
	canremove = 1
	if(istype(chest))
		chest.check_limb_support(wearer)
	for(var/obj/item/piece in list(helmet, boots, gloves, chest))
		if(!piece) continue
		piece.icon_state = "[initial(icon_state)]"
		if(airtight)
			piece.max_pressure_protection = initial(piece.max_pressure_protection)
			piece.min_pressure_protection = initial(piece.min_pressure_protection)
			piece.item_flags &= ~ITEM_FLAG_AIRTIGHT
	update_icon()

/obj/item/rig/proc/toggle_seals(var/mob/initiator,var/instant)

	if(sealing) return

	// Seal toggling can be initiated by the suit AI, too
	if(!wearer)
		to_chat(initiator, "<span class='danger'>Cannot toggle suit: The suit is currently not being worn by anyone.</span>")
		return 0

	if(!check_power_cost(wearer, 1))
		return 0

	deploy(wearer,instant)

	var/seal_target = !canremove
	var/failed_to_seal

	canremove = 0 // No removing the suit while unsealing.
	sealing = 1

	if(!seal_target && !suit_is_deployed())
		wearer.visible_message("<span class='danger'>[wearer]'s suit flashes an error light.</span>","<span class='danger'>Your suit flashes an error light. It can't function properly without being fully deployed.</span>")
		failed_to_seal = 1

	if(!failed_to_seal)

		if(!instant)
			wearer.visible_message(
				SPAN_HARDSUIT("[wearer]'s suit emits a quiet hum as it begins to adjust its seals."),
				SPAN_HARDSUIT("With a quiet hum, the suit begins running checks and adjusting components."))
			if(seal_delay && !do_after(wearer, seal_delay, src))
				if(wearer) to_chat(wearer, "<span class='warning'>You must remain still while the suit is adjusting the components.</span>")
				failed_to_seal = 1

		if(!wearer)
			failed_to_seal = 1
		else
			var/list/data_to_iterate = list(
				list(
					wearer.get_equipped_item(slot_shoes_str),
					boots,
					"boots"
				),
				list(
					wearer.get_equipped_item(slot_gloves_str),
					gloves,
					"gloves"
				),
				list(
					wearer.get_equipped_item(slot_head_str),
					helmet,
					"helmet"
				),
				list(
					wearer.get_equipped_item(slot_wear_suit_str),
					chest,
					"chest"
				)
			)
			for(var/list/piece_data in data_to_iterate)

				var/obj/item/piece = piece_data[1]
				var/obj/item/compare_piece = piece_data[2]
				var/msg_type = piece_data[3]

				if(!piece || !compare_piece)
					continue

				if(!istype(wearer) || !istype(piece) || !istype(compare_piece) || !msg_type)
					if(wearer) to_chat(wearer, "<span class='warning'>You must remain still while the suit is adjusting the components.</span>")
					failed_to_seal = 1
					break

				if(!failed_to_seal && wearer.get_equipped_item(slot_back_str) == src && piece == compare_piece)

					if(seal_delay && !instant && !do_after(wearer,seal_delay,src,check_holding=0))
						failed_to_seal = 1

					switch(msg_type)
						if("boots")
							to_chat(wearer, SPAN_HARDSUIT("\The [piece] [!seal_target ? "seal around your feet" : "relax their grip on your legs"]."))
							wearer.update_equipment_overlay(slot_shoes_str)
						if("gloves")
							to_chat(wearer, SPAN_HARDSUIT("\The [piece] [!seal_target ? "tighten around your fingers and wrists" : "become loose around your fingers"]."))
							wearer.update_equipment_overlay(slot_gloves_str)
						if("chest")
							to_chat(wearer, SPAN_HARDSUIT("\The [piece] [!seal_target ? "cinches tight again your chest" : "releases your chest"]."))
							wearer.update_equipment_overlay(slot_wear_suit_str)
						if("helmet")
							to_chat(wearer, SPAN_HARDSUIT("\The [piece] hisses [!seal_target ? "closed" : "open"]."))
							wearer.update_equipment_overlay(slot_head_str)
							if(helmet)
								helmet.update_light(wearer)
					//sealed pieces become airtight, protecting against diseases
					var/datum/extension/armor/rig/armor_datum = get_extension(piece, /datum/extension/armor)
					if(istype(armor_datum))
						armor_datum.sealed = !seal_target
					playsound(src, 'sound/machines/suitstorage_lockdoor.ogg', 10, 0)
					piece.update_icon()

				else
					failed_to_seal = 1

		if((wearer && !(istype(wearer) && wearer.get_equipped_item(slot_back_str) == src)) || (!seal_target && !suit_is_deployed()))
			failed_to_seal = 1

	sealing = null

	if(failed_to_seal)
		canremove = !seal_target
		if(airtight)
			update_component_sealed()
		update_icon()
		return 0

	// Success!
	canremove = seal_target
	to_chat(wearer, SPAN_HARDSUIT("<b>Your entire suit [canremove ? "loosens as the components relax" : "tightens around you as the components lock into place"].</b>"))
	if(!canremove && update_visible_name)
		visible_name = wearer.real_name

	if(wearer != initiator)
		to_chat(initiator, SPAN_HARDSUIT("Suit adjustment complete. Suit is now [canremove ? "unsealed" : "sealed"]."))

	if(canremove)
		for(var/obj/item/rig_module/module in installed_modules)
			module.deactivate()
	if(airtight)
		update_component_sealed()
	update_icon()


/obj/item/rig/proc/update_component_sealed()
	for(var/obj/item/piece in list(helmet,boots,gloves,chest))
		if(canremove)
			piece.max_pressure_protection = initial(piece.max_pressure_protection)
			piece.min_pressure_protection = initial(piece.min_pressure_protection)
			piece.item_flags &= ~ITEM_FLAG_AIRTIGHT
		else
			piece.max_pressure_protection = max_pressure_protection
			piece.min_pressure_protection = min_pressure_protection
			piece.item_flags |=  ITEM_FLAG_AIRTIGHT
	if (hides_uniform && chest)
		if(canremove)
			chest.flags_inv &= ~(HIDEJUMPSUIT)
		else
			chest.flags_inv |= HIDEJUMPSUIT
	if (helmet)
		if (canremove)
			helmet.flags_inv &= ~(HIDEMASK)
		else
			helmet.flags_inv |= HIDEMASK
	update_icon()

/obj/item/rig/Process()

	// If we've lost any parts, grab them back.
	var/mob/living/M
	for(var/obj/item/piece in list(gloves,boots,helmet,chest))
		if(piece.loc != src && !(wearer && piece.loc == wearer))
			if(isliving(piece.loc))
				M = piece.loc
				M.drop_from_inventory(piece)
			piece.forceMove(src)

	var/changed = update_offline()
	if(changed)
		if(offline)
			//notify the wearer
			if(!canremove)
				if (offline_slowdown < 3)
					to_chat(wearer, "<span class='danger'>Your suit beeps stridently, and suddenly goes dead.</span>")
				else
					to_chat(wearer, "<span class='danger'>Your suit beeps stridently, and suddenly you're wearing a leaden mass of metal and plastic composites instead of a powered suit.</span>")
			if(offline_vision_restriction >= TINT_MODERATE)
				to_chat(wearer, "<span class='danger'>The suit optics flicker and die, leaving you with restricted vision.</span>")
			else if(offline_vision_restriction >= TINT_BLIND)
				to_chat(wearer, "<span class='danger'>The suit optics drop out completely, drowning you in darkness.</span>")

			if(electrified > 0)
				electrified = 0
			for(var/obj/item/rig_module/module in installed_modules)
				module.deactivate()

		set_slowdown_and_vision(!offline)
		if(istype(chest))
			chest.check_limb_support(wearer)

	if(!offline)
		if(cell && cell.charge > 0 && electrified > 0)
			electrified--

		if(malfunction_delay > 0)
			malfunction_delay--
		else if(malfunctioning)
			malfunctioning--
			malfunction()

		for(var/obj/item/rig_module/module in installed_modules)
			if(!cell.checked_use(module.Process() * CELLRATE))
				module.deactivate()//turns off modules when your cell is dry

//offline should not change outside this proc
/obj/item/rig/proc/update_offline()
	var/go_offline = (!istype(wearer) || loc != wearer || wearer.get_equipped_item(slot_back_str) != src || canremove || sealing || !cell || cell.charge <= 0)
	if(offline != go_offline)
		offline = go_offline
		return 1
	return 0

/obj/item/rig/proc/check_power_cost(var/mob/living/user, var/cost, var/use_unconscious, var/obj/item/rig_module/mod, var/user_is_ai)

	if(!istype(user))
		return 0

	var/fail_msg

	if(!user_is_ai)
		var/mob/living/human/H = user
		if(istype(H) && H.get_equipped_item(slot_back_str) != src)
			fail_msg = "<span class='warning'>You must be wearing \the [src] to do this.</span>"
	if(sealing)
		fail_msg = "<span class='warning'>The hardsuit is in the process of adjusting seals and cannot be activated.</span>"
	else if(!fail_msg && ((use_unconscious && user.stat > 1) || (!use_unconscious && user.stat)))
		fail_msg = "<span class='warning'>You are in no fit state to do that.</span>"
	else if(!cell)
		fail_msg = "<span class='warning'>There is no cell installed in the suit.</span>"
	else if(cost && !cell.check_charge(cost * CELLRATE))
		fail_msg = "<span class='warning'>Not enough stored power.</span>"

	if(fail_msg)
		to_chat(user, "[fail_msg]")
		return 0

	// This is largely for cancelling stealth and whatever.
	if(mod && mod.disruptive)
		for(var/obj/item/rig_module/module in (installed_modules - mod))
			if(module.active && module.disruptable)
				module.deactivate()

	cell.use(cost * CELLRATE)
	return 1

/obj/item/rig/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1, var/nano_state = global.inventory_topic_state)
	if(!user)
		return

	var/list/data = list()

	if(selected_module)
		data["primarysystem"] = "[selected_module.interface_name]"

	if(src.loc != user)
		data["ai"] = 1

	data["seals"] =     "[src.canremove]"
	data["sealing"] =   "[src.sealing]"
	data["helmet"] =    (helmet ? "[helmet.name]" : "None.")
	data["gauntlets"] = (gloves ? "[gloves.name]" : "None.")
	data["boots"] =     (boots ?  "[boots.name]" :  "None.")
	data["chest"] =     (chest ?  "[chest.name]" :  "None.")

	data["charge"] =       cell ? round(cell.charge,1) : 0
	data["maxcharge"] =    cell ? cell.maxcharge : 0
	data["chargestatus"] = cell ? floor(cell.percent()/2) : 0

	data["emagged"] =       subverted
	data["coverlock"] =     locked
	data["interfacelock"] = interface_locked
	data["aicontrol"] =     control_overridden
	data["aioverride"] =    ai_override_enabled
	data["securitycheck"] = security_check_enabled
	data["malf"] =          malfunction_delay

	if(wearer) //Internals below!!!
		data["valveOpen"] = (wearer.internal == air_supply)

		if(!wearer.internal || wearer.internal == air_supply)	// if they have no active internals or if tank is current internal
			data["maskConnected"] = wearer.check_for_airtight_internals(FALSE)

	data["tankPressure"] = round(air_supply && air_supply.air_contents && air_supply.air_contents.return_pressure() ? air_supply.air_contents.return_pressure() : 0)
	data["releasePressure"] = round(air_supply && air_supply.distribute_pressure ? air_supply.distribute_pressure : 0)
	data["defaultReleasePressure"] = air_supply ? round(initial(air_supply.distribute_pressure)) : 0
	data["maxReleasePressure"] = air_supply ? round(TANK_MAX_RELEASE_PRESSURE) : 0
	data["tank"] = air_supply ? 1 : 0

	var/list/module_list = list()
	var/i = 1
	for(var/obj/item/rig_module/module in installed_modules)
		var/list/module_data = list(
			"index" =             i,
			"name" =              "[module.interface_name]",
			"desc" =              "[module.interface_desc]",
			"can_use" =           "[module.usable]",
			"can_select" =        "[module.selectable]",
			"can_toggle" =        "[module.toggleable]",
			"is_active" =         "[module.active]",
			"engagecost" =        module.use_power_cost*10,
			"activecost" =        module.active_power_cost*10,
			"passivecost" =       module.passive_power_cost*10,
			"engagestring" =      module.engage_string,
			"activatestring" =    module.activate_string,
			"deactivatestring" =  module.deactivate_string,
			"damage" =            module.damage
			)

		if(module.charges && module.charges.len)

			module_data["charges"] = list()
			module_data["chargetype"] = module.charge_selected

			for(var/chargetype in module.charges)
				var/datum/rig_charge/charge = module.charges[chargetype]
				module_data["charges"] += list(list("caption" = "[chargetype] ([charge.charges])", "index" = "[chargetype]"))

		module_list += list(module_data)
		i++

	if(module_list.len)
		data["modules"] = module_list

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, ((src.loc != user) ? ai_interface_path : interface_path), interface_title, 480, 550, state = nano_state)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/obj/item/rig/on_update_icon()
	. = ..()
	for(var/obj/item/thing in list(chest, boots, gloves, helmet))
		thing.update_icon()

	if(equipment_overlay_icon && LAZYLEN(installed_modules) && istype(chest, /obj/item))
		for(var/obj/item/rig_module/module in installed_modules)
			if(module.suit_overlay)
				chest.add_overlay(image("icon" = equipment_overlay_icon, "icon_state" = "[module.suit_overlay]", "dir" = SOUTH))

	if(wearer)
		var/static/list/update_rig_slots = list(
			slot_shoes_str,
			slot_gloves_str,
			slot_head_str,
			slot_wear_mask_str,
			slot_wear_suit_str,
			slot_w_uniform_str,
			slot_back_str
		)
		for(var/slot in update_rig_slots)
			wearer.update_equipment_overlay(slot)

/obj/item/rig/apply_additional_mob_overlays(mob/living/user_mob, bodytype, image/overlay, slot, bodypart, use_fallback_if_icon_missing = TRUE)
	if(overlay && slot == slot_back_str && !offline && equipment_overlay_icon && LAZYLEN(installed_modules))
		for(var/obj/item/rig_module/module in installed_modules)
			if(module.suit_overlay)
				overlay.overlays += image("icon" = equipment_overlay_icon, "icon_state" = "[module.suit_overlay]")
	. = ..()

/obj/item/rig/get_req_access()
	if(!security_check_enabled || !locked)
		return list()
	return ..()

/obj/item/rig/proc/check_suit_access(var/mob/living/human/user)

	if(!security_check_enabled)
		return 1

	if(istype(user))
		if(!canremove)
			return 1
		if(malfunction_check(user))
			return 0
		if(user.get_equipped_item(slot_back_str) != src)
			return 0
		else if(!src.allowed(user))
			to_chat(user, "<span class='danger'>Unauthorized user. Access denied.</span>")
			return 0

	else if(!ai_override_enabled)
		to_chat(user, "<span class='danger'>Synthetic access disabled. Please consult hardware provider.</span>")
		return 0

	return 1

//TODO: Fix Topic vulnerabilities for malfunction and AI override.
/obj/item/rig/Topic(href,href_list)
	if(!check_suit_access(usr))
		return 0

	if(href_list["toggle_piece"])
		toggle_piece(href_list["toggle_piece"], usr)
		return 1
	if(href_list["toggle_seals"])
		toggle_seals(usr)
		return 1
	if(href_list["interact_module"])

		var/module_index = text2num(href_list["interact_module"])

		if(module_index > 0 && module_index <= installed_modules.len)
			var/obj/item/rig_module/module = installed_modules[module_index]
			switch(href_list["module_mode"])
				if("activate")
					module.activate()
				if("deactivate")
					module.deactivate()
				if("engage")
					module.engage()
				if("select")
					if(selected_module == module)
						deselect_module()
					else
						module.select()
				if("select_charge_type")
					module.charge_selected = href_list["charge_type"]
		return 1
	if(href_list["toggle_ai_control"])
		ai_override_enabled = !ai_override_enabled
		notify_ai("Synthetic suit control has been [ai_override_enabled ? "enabled" : "disabled"].")
		return 1
	if(href_list["toggle_suit_lock"])
		locked = !locked
		return 1
	if(href_list["air_supply"])
		air_supply.OnTopic(wearer,href_list)
		return 1

/obj/item/rig/proc/notify_ai(var/message)
	for(var/obj/item/rig_module/ai_container/module in installed_modules)
		if(module.integrated_ai && module.integrated_ai.client && !module.integrated_ai.stat)
			to_chat(module.integrated_ai, "[message]")
			. = 1

/obj/item/rig/equipped(mob/living/human/M)
	..()

	if(seal_delay > 0 && istype(M) && M.get_equipped_item(slot_back_str) == src)
		M.visible_message(
			SPAN_HARDSUIT("[M] starts putting on \the [src]..."),
			SPAN_HARDSUIT("You start putting on \the [src]..."))

		if(!do_after(M,seal_delay,src))
			if(M && M.get_equipped_item(slot_back_str) == src)
				if(!M.try_unequip(src))
					return
			src.dropInto(loc)
			return

	if(istype(M) && M.get_equipped_item(slot_back_str) == src)
		M.visible_message(
			SPAN_HARDSUIT("<b>[M] struggles into \the [src].</b>"),
			SPAN_HARDSUIT("<b>You struggle into \the [src].</b>"))
		wearer = M
		update_icon()

/obj/item/rig/proc/toggle_piece(var/piece, var/mob/initiator, var/deploy_mode)

	if(sealing || !cell || !cell.charge)
		return

	if(!istype(wearer) || wearer.get_equipped_item(slot_back_str) != src)
		return

	if(initiator == wearer && wearer.incapacitated(INCAPACITATION_DISABLED)) // If the initiator isn't wearing the suit it's probably an AI.
		return

	var/obj/item/check_slot
	var/equip_to
	var/obj/item/use_obj

	if(!wearer)
		return

	switch(piece)
		if("helmet")
			equip_to = slot_head_str
			use_obj = helmet
		if("gauntlets")
			equip_to = slot_gloves_str
			use_obj = gloves
		if("boots")
			equip_to = slot_shoes_str
			use_obj = boots
		if("chest")
			equip_to = slot_wear_suit_str
			use_obj = chest
	if(equip_to)
		check_slot = wearer.get_equipped_item(equip_to)

	if(use_obj)
		if(check_slot == use_obj && deploy_mode != ONLY_DEPLOY)

			var/mob/living/human/holder

			if(use_obj)
				holder = use_obj.loc
				if(istype(holder))
					if(use_obj && check_slot == use_obj)
						to_chat(wearer, SPAN_HARDSUIT("<b>Your [use_obj.name] [use_obj.gender == PLURAL ? "retract" : "retracts"] swiftly.</b>"))
						use_obj.canremove = 1
						holder.drop_from_inventory(use_obj, src)
						use_obj.canremove = 0

		else if (deploy_mode != ONLY_RETRACT)
			if(check_slot && check_slot == use_obj)
				return
			use_obj.forceMove(wearer)
			if(!wearer.equip_to_slot_if_possible(use_obj, equip_to, 0, 1))
				use_obj.forceMove(src)
				if(check_slot)
					to_chat(initiator, "<span class='danger'>You are unable to deploy \the [piece] as \the [check_slot] [check_slot.gender == PLURAL ? "are" : "is"] in the way.</span>")
					return
			else
				to_chat(wearer, "<span class='notice'>Your [use_obj.name] [use_obj.gender == PLURAL ? "deploy" : "deploys"] swiftly.</span>")
			use_obj.icon_state = initial(use_obj.icon_state)

	if(piece == "helmet" && helmet)
		helmet.update_light(wearer)

/obj/item/rig/proc/deploy(mob/M,var/sealed)

	var/mob/living/human/H = M

	if(!H || !istype(H)) return

	if(H.get_equipped_item(slot_back_str) != src)
		return

	if(sealed)
		for(var/list/slot in list(slot_head_str, slot_gloves_str, slot_shoes_str, slot_wear_suit_str))
			var/obj/item/garbage = H.get_equipped_item(slot)
			if(garbage)
				H.try_unequip(garbage)
				qdel(garbage)

	for(var/piece in list("helmet","gauntlets","chest","boots"))
		toggle_piece(piece, H, ONLY_DEPLOY)

/obj/item/rig/dropped(var/mob/user)
	..()
	for(var/piece in list("helmet","gauntlets","chest","boots"))
		toggle_piece(piece, user, ONLY_RETRACT)
	if(wearer)
		wearer = null

/obj/item/rig/proc/deselect_module()
	if(!selected_module)
		return
	if(selected_module.suit_overlay_inactive)
		selected_module.suit_overlay = selected_module.suit_overlay_inactive
	else
		selected_module.suit_overlay = null
	selected_module = null
	update_icon()

//Todo
/obj/item/rig/proc/malfunction()
	return 0

/obj/item/rig/emp_act(severity_class)
	//set malfunctioning
	if(emp_protection < 30) //for ninjas, really.
		malfunctioning += 10
		if(malfunction_delay <= 0)
			malfunction_delay = max(malfunction_delay, round(30/severity_class))

	//drain some charge
	if(cell) cell.emp_act(severity_class + 1)

	//possibly damage some modules
	take_hit((100/severity_class), "electrical pulse", 1)

/obj/item/rig/proc/shock(mob/user)
	if (electrocute_mob(user, cell, src)) //electrocute_mob() handles removing charge from the cell, no need to do that here.
		spark_at(src, amount = 5, holder = src)
		if(HAS_STATUS(user, STAT_STUN))
			return 1
	return 0

/obj/item/rig/proc/take_hit(damage, source, is_emp=0)

	if(!installed_modules.len)
		return

	var/chance
	if(!is_emp)
		var/damage_resistance = 0
		if(istype(chest, /obj/item/clothing/suit/space))
			var/obj/item/clothing/suit/space/suit = chest
			damage_resistance = suit.breach_threshold
		chance = 2*max(0, damage - damage_resistance)
	else
		//Want this to be roughly independant of the number of modules, meaning that X emp hits will disable Y% of the suit's modules on average.
		//that way people designing hardsuits don't have to worry (as much) about how adding that extra module will affect emp resiliance by 'soaking' hits for other modules
		chance = 2*max(0, damage - emp_protection)*min(installed_modules.len/15, 1)

	if(!prob(chance))
		return

	//deal addition damage to already damaged module first.
	//This way the chances of a module being disabled aren't so remote.
	var/list/valid_modules = list()
	var/list/damaged_modules = list()
	for(var/obj/item/rig_module/module in installed_modules)
		if(module.damage < 2)
			valid_modules |= module
			if(module.damage > 0)
				damaged_modules |= module

	var/obj/item/rig_module/dam_module = null
	if(damaged_modules.len)
		dam_module = pick(damaged_modules)
	else if(valid_modules.len)
		dam_module = pick(valid_modules)

	if(!dam_module) return

	dam_module.damage++

	if(!source)
		source = "hit"

	if(wearer)
		if(dam_module.damage >= 2)
			to_chat(wearer, "<span class='danger'>The [source] has disabled your [dam_module.interface_name]!</span>")
		else
			to_chat(wearer, "<span class='warning'>The [source] has damaged your [dam_module.interface_name]!</span>")
	dam_module.deactivate()

/obj/item/rig/proc/malfunction_check(var/mob/living/human/user)
	if(malfunction_delay)
		if(offline)
			to_chat(user, "<span class='danger'>The suit is completely unresponsive.</span>")
		else
			to_chat(user, "<span class='danger'>ERROR: Hardware fault. Rebooting interface...</span>")
		return 1
	return 0

/obj/item/rig/proc/ai_can_move_suit(var/mob/user, var/check_user_module = 0, var/check_for_ai = 0)

	if(check_for_ai)
		if(!(locate(/obj/item/rig_module/ai_container) in contents))
			return 0
		var/found_ai
		for(var/obj/item/rig_module/ai_container/module in contents)
			if(module.damage >= 2)
				continue
			if(module.integrated_ai && module.integrated_ai.client && !module.integrated_ai.stat)
				found_ai = 1
				break
		if(!found_ai)
			return 0

	if(check_user_module)
		if(!user || !user.loc || !user.loc.loc)
			return 0
		var/obj/item/rig_module/ai_container/module = user.loc.loc
		if(!istype(module) || module.damage >= 2)
			to_chat(user, "<span class='warning'>Your host module is unable to interface with the suit.</span>")
			return 0

	if(offline || !cell || !cell.charge || locked_down)
		if(user) to_chat(user, "<span class='warning'>Your host rig is unpowered and unresponsive.</span>")
		return 0
	if(!wearer || wearer.get_equipped_item(slot_back_str) != src)
		if(user) to_chat(user, "<span class='warning'>Your host rig is not being worn.</span>")
		return 0
	if(!wearer.stat && !control_overridden && !ai_override_enabled)
		if(user) to_chat(user, "<span class='warning'>You are locked out of the suit servo controller.</span>")
		return 0
	return 1

/obj/item/rig/proc/force_rest(var/mob/user)
	if(!ai_can_move_suit(user, check_user_module = 1))
		return
	wearer.lay_down()
	to_chat(user, "<span class='notice'>\The [wearer] is now [wearer.current_posture.prone ? "resting" : "getting up"].</span>")

/obj/item/rig/proc/forced_move(var/direction, var/mob/user)
	if(malfunctioning)
		direction = pick(global.cardinal)

	if(world.time < wearer_move_delay)
		return

	if(!wearer || !wearer.loc || !ai_can_move_suit(user, check_user_module = 1))
		return

	// AIs are a bit slower than regular and ignore move intent.
	wearer_move_delay = world.time + ai_controlled_move_delay

	cell.use(aimove_power_usage * CELLRATE)
	wearer.DoMove(direction, user)

// This returns the rig if you are contained inside one, but not if you are wearing it
/atom/proc/get_rig()
	RETURN_TYPE(/obj/item/rig)
	return loc?.get_rig()

/obj/item/rig/get_rig()
	RETURN_TYPE(/obj/item/rig)
	return src

/mob/living/get_rig()
	RETURN_TYPE(/obj/item/rig)
	var/obj/item/rig/rig = get_equipped_item(slot_back_str)
	if(istype(rig))
		return rig

#undef ONLY_DEPLOY
#undef ONLY_RETRACT
#undef SEAL_DELAY
