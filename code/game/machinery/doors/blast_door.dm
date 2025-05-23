// BLAST DOORS
//
// Refactored 27.12.2014 by Atlantis
//
// Blast doors are supposed to be reinforced versions of regular doors. Instead of being manually
// controlled they use buttons or other means of remote control. This is why they cannot be emagged
// as they lack any ID scanning system, they just handle remote control signals. Subtypes have
// different icons, which are defined by set of variables. Subtypes are on bottom of this file.

/obj/machinery/door/blast
	name = "blast door"
	desc = "That looks like it doesn't open easily."
	icon = 'icons/obj/doors/blast_doors/door.dmi'
	icon_state = null
	can_open_manually = FALSE

	// Icon states for different shutter types. Simply change this instead of rewriting the update_icon proc.
	icon_state_open = null
	icon_state_closed = null
	var/icon_state_opening = null
	var/icon_state_closing = null

	var/icon_state_open_broken = null
	var/icon_state_closed_broken = null

	var/open_sound = 'sound/machines/blastdoor_open.ogg'
	var/close_sound = 'sound/machines/blastdoor_close.ogg'

	open_layer = ABOVE_DOOR_LAYER
	closed_layer = ABOVE_WINDOW_LAYER
	dir = NORTH
	explosion_resistance = 25
	atom_flags = ATOM_FLAG_ADJACENT_EXCEPTION

	//Most blast doors are infrequently toggled and sometimes used with regular doors anyways,
	//turning this off prevents awkward zone geometry in places like medbay lobby, for example.
	block_air_zones = 0

	var/decl/material/implicit_material
	autoset_access = FALSE // Uses different system with buttons.
	pry_mod = 1.35

	// To be fleshed out and moved to parent door, but staying minimal for now.
	public_methods = list(
		/decl/public_access/public_method/open_door,
		/decl/public_access/public_method/close_door,
		/decl/public_access/public_method/close_door_delayed,
		/decl/public_access/public_method/toggle_door,
		/decl/public_access/public_method/toggle_door_to
	)
	stock_part_presets = list(/decl/stock_part_preset/radio/receiver/blast_door = 1)
	construct_state = /decl/machine_construction/default/panel_closed/blast_door
	frame_type = /obj/structure/door_assembly/blast
	base_type = /obj/machinery/door/blast

/obj/machinery/door/blast/Initialize()
	implicit_material = GET_DECL(/decl/material/solid/metal/plasteel)
	. = ..()

/obj/machinery/door/blast/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	if((stat & BROKEN))
		. += SPAN_DANGER("It's broken.")

// Proc: Bumped()
// Parameters: 1 (AM - Atom that tried to walk through this object)
// Description: If we are open returns zero, otherwise returns result of parent function.
/obj/machinery/door/blast/Bumped(atom/AM)
	if(!density)
		return ..()
	else
		return 0

// Proc: update_icon()
// Parameters: None
// Description: Updates icon of this object. Uses icon state variables.
/obj/machinery/door/blast/on_update_icon()

	if(set_dir_on_update)
		if(connections & (NORTH|SOUTH))
			set_dir(EAST)
		else
			set_dir(SOUTH)

	if(density)
		if(stat & BROKEN)
			icon_state = icon_state_closed_broken
		else
			icon_state = icon_state_closed
	else
		if(stat & BROKEN)
			icon_state = icon_state_open_broken
		else
			icon_state = icon_state_open
	SSradiation.resistance_cache.Remove(get_turf(src))
	return

// Proc: force_open()
// Parameters: None
// Description: Opens the door. No checks are done inside this proc.
/obj/machinery/door/blast/proc/force_open()
	set waitfor = FALSE
	operating = 1
	playsound(src.loc, open_sound, 100, 1)
	flick(icon_state_opening, src)

	sleep(0.6 SECONDS)
	set_density(FALSE)
	update_nearby_tiles()
	update_icon()
	set_opacity(FALSE)
	layer = open_layer
	operating = 0

// Proc: force_close()
// Parameters: None
// Description: Closes the door. No checks are done inside this proc.
/obj/machinery/door/blast/proc/force_close()
	operating = 1
	playsound(src.loc, close_sound, 100, 1)
	layer = closed_layer
	flick(icon_state_closing, src)

	sleep(0.6 SECONDS)
	set_density(TRUE)
	update_nearby_tiles()
	update_icon()
	set_opacity(TRUE)
	operating = 0

// Proc: force_toggle()
// Parameters: None
// Description: Opens or closes the door, depending on current state. No checks are done inside this proc.
/obj/machinery/door/blast/proc/force_toggle(to_open = density)
	if(to_open)
		force_open()
	else
		force_close()

/obj/machinery/door/blast/get_material()
	RETURN_TYPE(/decl/material)
	return implicit_material

// Proc: attackby()
// Parameters: 2 (used_item - Item this object was clicked with, user - Mob which clicked this object)
// Description: If we are clicked with crowbar or wielded fire axe, try to manually open the door.
// This only works on broken doors or doors without power. Also allows repair with Plasteel.
/obj/machinery/door/blast/attackby(obj/item/used_item, mob/user)
	add_fingerprint(user, 0, used_item)
	if(!panel_open) //Do this here so the door won't change state while prying out the circuit
		if(IS_CROWBAR(used_item) || (istype(used_item, /obj/item/bladed/axe/fire) && used_item.is_held_twohanded()))
			if(((stat & NOPOWER) || (stat & BROKEN)) && !( operating ))
				to_chat(user, "<span class='notice'>You begin prying at \the [src]...</span>")
				if(do_after(user, 2 SECONDS, src))
					force_toggle()
				else
					to_chat(user, "<span class='warning'>You must remain still while working on \the [src].</span>")
			else
				to_chat(user, "<span class='notice'>[src]'s motors resist your effort.</span>")
			return TRUE
	if(istype(used_item, /obj/item/stack/material) && used_item.get_material_type() == /decl/material/solid/metal/plasteel)
		var/amt = ceil((get_max_health() - current_health)/150)
		if(!amt)
			to_chat(user, "<span class='notice'>\The [src] is already fully functional.</span>")
			return TRUE
		var/obj/item/stack/stack = used_item
		if(!stack.can_use(amt))
			to_chat(user, "<span class='warning'>You don't have enough sheets to repair this! You need at least [amt] sheets.</span>")
			return TRUE
		to_chat(user, "<span class='notice'>You begin repairing \the [src]...</span>")
		if(do_after(user, 5 SECONDS, src))
			if(stack.use(amt))
				to_chat(user, "<span class='notice'>You have repaired \the [src].</span>")
				repair()
			else
				to_chat(user, "<span class='warning'>You don't have enough sheets to repair this! You need at least [amt] sheets.</span>")
		else
			to_chat(user, "<span class='warning'>You must remain still while working on \the [src].</span>")
		return TRUE
	return ..()

// Proc: open()
// Parameters: None
// Description: Opens the door. Does necessary checks. Automatically closes if autoclose is true
/obj/machinery/door/blast/open()
	if (!can_open() || (stat & BROKEN || stat & NOPOWER))
		return

	force_open()

	if(autoclose)
		addtimer(CALLBACK(src, PROC_REF(close)), 15 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE)

	return TRUE

// Proc: close()
// Parameters: None
// Description: Closes the door. Does necessary checks.
/obj/machinery/door/blast/close()
	if (!can_close() || (stat & BROKEN || stat & NOPOWER))
		return

	force_close()

/obj/machinery/door/blast/toggle(to_open = density)
	if (operating || (stat & BROKEN || stat & NOPOWER))
		return
	force_toggle(to_open)

// Proc: repair()
// Parameters: None
// Description: Fully repairs the blast door.
/obj/machinery/door/blast/proc/repair()
	current_health = get_max_health()
	set_broken(FALSE)
	queue_icon_update()

/obj/machinery/door/blast/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(air_group) return 1
	return ..()

// Used with mass drivers to time the close.
/obj/machinery/door/blast/proc/delayed_close()
	set waitfor = FALSE
	sleep(5 SECONDS)
	close()

/obj/machinery/door/blast/dismantle()
	var/obj/structure/door_assembly/da = ..()
	. = da

	da.anchored = TRUE
	da.state = 1
	da.created_name = name
	da.update_icon()

/decl/public_access/public_method/close_door_delayed
	name = "delayed close door"
	desc = "Closes the door if possible, after a short delay."
	call_proc = TYPE_PROC_REF(/obj/machinery/door/blast, delayed_close)

/decl/stock_part_preset/radio/receiver/blast_door
	frequency = BLAST_DOORS_FREQ
	receive_and_call = list(
		"open_door" = /decl/public_access/public_method/open_door,
		"close_door" = /decl/public_access/public_method/close_door,
		"close_door_delayed" = /decl/public_access/public_method/close_door_delayed,
		"toggle_door" = /decl/public_access/public_method/toggle_door,
		"toggle_door_to" = /decl/public_access/public_method/toggle_door_to
	)

/obj/machinery/button/blast_door
	name = "remote blast door-control"
	desc = "It controls blast doors, remotely."
	icon = 'icons/obj/machines/button_blastdoor.dmi'
	icon_state = "blastctrl"
	stock_part_presets = list(
		/decl/stock_part_preset/radio/event_transmitter/blast_door_button = 1,
		/decl/stock_part_preset/radio/receiver/blast_door_button = 1
	)
	uncreated_component_parts = list(
		/obj/item/stock_parts/power/apc,
		/obj/item/stock_parts/radio/transmitter/on_event/buildable,
		/obj/item/stock_parts/radio/receiver/buildable
	)
	base_type = /obj/machinery/button/blast_door/buildable
	frame_type = /obj/item/frame/button/blastdoor

/obj/machinery/button/blast_door/buildable
	uncreated_component_parts = list(
		/obj/item/stock_parts/power/apc
	)

/obj/machinery/button/blast_door/Initialize(mapload)
	. = ..()
	if(mapload && id_tag) // This is a mapping convenience: makes mapped buttons guess their doors' starting state.
		for(var/obj/machinery/door/blast/blast in SSmachines.machinery)
			if(blast.id_tag == id_tag)
				state = !blast.density
				break

// Button pressed toggles button_active event, toggles state, and sends a state update to everything, including other buttons.
/decl/stock_part_preset/radio/event_transmitter/blast_door_button
	event = /decl/public_access/public_variable/button_active
	transmit_on_event = list(
		"toggle_door_to" = /decl/public_access/public_variable/button_state
	)
	frequency = BLAST_DOORS_FREQ

// Doors will toggle state if it doesn't match, while other buttons update their tracked state using the received signal.
/decl/stock_part_preset/radio/receiver/blast_door_button
	receive_and_write = list(
		"toggle_door_to" = /decl/public_access/public_variable/button_state
	)
	frequency = BLAST_DOORS_FREQ

/obj/machinery/button/blast_door/on_update_icon()
	if(operating)
		icon_state = "blastctrl1"
	else
		icon_state = "blastctrl"

// SUBTYPE: Regular
// Your classical blast door, found almost everywhere.
/obj/machinery/door/blast/regular
	icon = 'icons/obj/doors/blast_doors/door.dmi'
	icon_state = "closed"
	icon_state_open = "open"
	icon_state_opening = "opening"
	icon_state_closed = "closed"
	icon_state_closing = "closing"

	icon_state_open_broken = "open_broken"
	icon_state_closed_broken = "closed_broken"

	min_force = 30
	max_health = 1000
	block_air_zones = 1

	var/icon_lower_door_open = "open_bottom"
	var/icon_lower_door_open_broken = "open_bottom_broken"

/obj/machinery/door/blast/regular/on_update_icon()
	underlays.Cut()
	. = ..()
	if(!density)
		underlays += image(icon, null, is_broken()? icon_lower_door_open_broken : icon_lower_door_open, BELOW_DOOR_LAYER, dir)

/obj/machinery/door/blast/regular/escape_pod
	name = "Escape Pod release Door"

/obj/machinery/door/blast/regular/escape_pod/Process()
	if(SSevac.evacuation_controller && SSevac.evacuation_controller.emergency_evacuation && SSevac.evacuation_controller.state >= EVAC_LAUNCHING && src.icon_state == icon_state_closed)
		src.force_open()
	. = ..()

/obj/machinery/door/blast/regular/open
	icon_state = "open"
	begins_closed = FALSE

// SUBTYPE: Shutters
// Nicer looking, and also weaker, shutters. Found in kitchen and similar areas.
/obj/machinery/door/blast/shutters
	name = "shutters"
	desc = "A set of mechanized shutters made of a pretty sturdy material."
	icon = 'icons/obj/doors/shutters/door.dmi'
	icon_state = "closed"
	icon_state_open = "open"
	icon_state_opening = "opening"
	icon_state_closed = "closed"
	icon_state_closing = "closing"

	icon_state_open_broken = "open_broken"
	icon_state_closed_broken = "closed_broken"

	open_sound = 'sound/machines/shutters_open.ogg'
	close_sound = 'sound/machines/shutters_close.ogg'
	min_force = 15
	max_health = 500
	explosion_resistance = 10
	pry_mod = 0.55
	frame_type = /obj/structure/door_assembly/blast/shutter

/obj/machinery/door/blast/shutters/open
	begins_closed = FALSE
	icon_state = "open"
