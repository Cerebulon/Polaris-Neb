// TODO: remove the robot.central_processor and robot.cell variables and completely rely on the robot component system
/datum/robot_component
	var/name
	/// Installation status; not a bool, may be -1, 0 or 1.
	var/installed    = 0
	var/powered      = FALSE
	var/toggled      = TRUE
	var/brute_damage = 0
	var/burn_damage  = 0
	/// Amount of power used every MC tick. In joules.
	var/idle_usage   = 0
	/// Amount of power used for every action. Actions are module-specific. Actuator for each tile moved, etc.
	var/active_usage = 0
	/// HP of this component.
	var/max_damage   = 30
	var/mob/living/silicon/robot/owner
	/// The actual device object that has to be installed for this.
	var/external_type
	/// The wrapped device(e.g. radio), only set if external_type isn't null
	var/obj/item/wrapped

/datum/robot_component/New(mob/living/silicon/robot/robot)
	src.owner = robot

/datum/robot_component/proc/accepts_component(var/obj/item/thing)
	. = istype(thing, external_type)

/datum/robot_component/proc/install()
	return

/datum/robot_component/proc/uninstall()
	return

/datum/robot_component/proc/destroy()
	if (istype(wrapped, /obj/item/robot_parts/robot_component))
		var/obj/item/robot_parts/robot_component/comp = wrapped
		wrapped.icon_state = comp.icon_state_broken

	installed = -1
	uninstall()

/datum/robot_component/Destroy()
	if(owner)
		owner.components -= src
	owner = null
	wrapped = null
	return ..()

/datum/robot_component/proc/repair()
	if (istype(wrapped, /obj/item/robot_parts/robot_component))
		var/obj/item/robot_parts/robot_component/comp = wrapped
		wrapped.icon_state = comp.icon_state

	installed = 1
	install()

/datum/robot_component/proc/take_component_damage(brute, electronics, sharp, edge)
	if(installed != 1) return

	brute_damage += brute
	burn_damage += electronics

	if(brute_damage + burn_damage >= max_damage) destroy()

/datum/robot_component/proc/heal_damage(brute, electronics)
	if(installed != 1)
		// If it's not installed, can't repair it.
		return 0

	brute_damage = max(0, brute_damage - brute)
	burn_damage = max(0, burn_damage - electronics)

/datum/robot_component/proc/is_powered()
	return (installed == 1) && (brute_damage + burn_damage < max_damage) && (!idle_usage || powered)

/datum/robot_component/proc/update_power_state()
	if(toggled == 0)
		powered = 0
		return
	if(owner.cell_use_power(idle_usage))
		powered = 1
	else
		powered = 0

// ARMOUR
// Protects the cyborg from damage. Usually first module to be hit
// No power usage
/datum/robot_component/armour
	name = "armour plating"
	external_type = /obj/item/robot_parts/robot_component/armour
	max_damage = 150

// LIGHT ARMOUR
// Same as armour, but for flying borgs - Less protection.
/datum/robot_component/armour/light
	name = "light armour plating"
	external_type = /obj/item/robot_parts/robot_component/armour/light
	max_damage = 75

/datum/robot_component/armour/accepts_component(var/obj/item/thing)
	. = (!istype(thing, /obj/item/robot_parts/robot_component/armour/exosuit) && ..())

// ACTUATOR
// Enables movement.
// Uses no power when idle. Uses 200J for each tile the cyborg moves.
/datum/robot_component/actuator
	name = "actuator"
	idle_usage = 0
	active_usage = 200
	external_type = /obj/item/robot_parts/robot_component/actuator
	max_damage = 50


//A fixed and much cleaner implementation of /tg/'s special snowflake code.
/datum/robot_component/actuator/is_powered()
	return (installed == 1) && (brute_damage + burn_damage < max_damage)


// POWER CELL
// Stores power (how unexpected..)
// No power usage
/datum/robot_component/cell
	name = "power cell"
	max_damage = 50
	var/obj/item/cell/stored_cell = null

/datum/robot_component/cell/destroy()
	..()
	stored_cell = owner.cell
	owner.cell = null

/datum/robot_component/cell/Destroy()
	QDEL_NULL(stored_cell)
	return ..()

/datum/robot_component/cell/repair()
	owner.cell = stored_cell
	stored_cell = null

// RADIO
// Enables radio communications
// Uses no power when idle. Uses 10J for each received radio message, 50 for each transmitted message.
/datum/robot_component/radio
	name = "radio"
	external_type = /obj/item/robot_parts/robot_component/radio
	idle_usage = 15		//it's not actually possible to tell when we receive a message over our radio, so just use 10W every tick for passive listening
	active_usage = 75	//transmit power
	max_damage = 40


// BINARY RADIO
// Enables binary communications with other cyborgs/AIs
// Uses no power when idle. Uses 10J for each received radio message, 50 for each transmitted message
/datum/robot_component/binary_communication
	name = "binary communication device"
	external_type = /obj/item/robot_parts/robot_component/binary_communication_device
	idle_usage = 5
	active_usage = 25
	max_damage = 30


// CAMERA
// Enables cyborg vision. Can also be remotely accessed via consoles.
// Uses 10J constantly
/datum/robot_component/camera
	name = "camera"
	external_type = /obj/item/robot_parts/robot_component/camera
	idle_usage = 10
	max_damage = 40

/datum/robot_component/camera/update_power_state()
	. = ..()
	cameranet.update_visibility(owner, FALSE)

/datum/robot_component/camera/destroy()
	. = ..()
	cameranet.update_visibility(owner, FALSE)

// SELF DIAGNOSIS MODULE
// Analyses cyborg's modules, providing damage readouts and basic information
// Uses 1kJ burst when analysis is done
/datum/robot_component/diagnosis_unit
	name = "self-diagnosis unit"
	active_usage = 1000
	external_type = /obj/item/robot_parts/robot_component/diagnosis_unit
	max_damage = 30




// HELPER STUFF



// Initializes cyborg's components. Technically, adds default set of components to new borgs
/mob/living/silicon/robot/proc/initialize_components()
	components["actuator"] = new/datum/robot_component/actuator(src)
	components["radio"] = new/datum/robot_component/radio(src)
	components["power cell"] = new/datum/robot_component/cell(src)
	components["diagnosis unit"] = new/datum/robot_component/diagnosis_unit(src)
	components["camera"] = new/datum/robot_component/camera(src)
	components["comms"] = new/datum/robot_component/binary_communication(src)
	components["armour"] = new/datum/robot_component/armour(src)

// Checks if component is functioning
/mob/living/silicon/robot/proc/is_component_functioning(module_name)
	var/datum/robot_component/C = components[module_name]
	return C && C.installed == 1 && C.toggled && C.is_powered()

// Returns component by it's string name
/mob/living/silicon/robot/proc/get_component(var/component_name)
	var/datum/robot_component/C = components[component_name]
	return C



// COMPONENT OBJECTS



// Component Objects
// These objects are visual representation of modules
/obj/item/robot_parts/robot_component
	icon = 'icons/obj/robot_component.dmi'
	icon_state = "working"
	material = /decl/material/solid/metal/steel
	current_health = 30
	max_health = 30
	var/burn_damage = 0
	var/brute_damage = 0
	var/icon_state_broken = "broken"

/obj/item/robot_parts/robot_component/check_health(lastdamage, lastdamtype, lastdamflags, consumed)
	var/current_max_health = get_max_health()
	if(lastdamage > 0)
		if(lastdamtype == BRUTE)
			brute_damage = clamp(lastdamage, 0, current_max_health)
		if(lastdamtype == BURN || lastdamtype == ELECTROCUTE)
			burn_damage = clamp(lastdamage, 0, current_max_health)

	//Health works differently for this thing
	current_health = clamp(current_max_health - (brute_damage + burn_damage), 0, current_max_health)
	. = ..()

/obj/item/robot_parts/robot_component/proc/set_bruteloss(var/amount)
	var/current_max_health = get_max_health()
	brute_damage = clamp(amount, 0, current_max_health)
	current_health = current_max_health - (brute_damage + burn_damage)
	check_health(amount, BRUTE)

/obj/item/robot_parts/robot_component/proc/set_burnloss(var/amount)
	var/current_max_health = get_max_health()
	burn_damage = clamp(amount, 0, current_max_health)
	current_health = current_max_health - (brute_damage + burn_damage)
	check_health(amount, BURN)

/obj/item/robot_parts/robot_component/physically_destroyed(skip_qdel)
	var/obj/item/stock_parts/circuitboard/broken/broken_device = new (get_turf(src))
	if(icon_state_broken != "broken")
		broken_device.icon = src.icon
		broken_device.icon_state = icon_state_broken
	broken_device.name = "broken [name]"
	. = ..()

/obj/item/robot_parts/robot_component/proc/is_functional()
	return ((brute_damage + burn_damage) < get_max_health())

/obj/item/robot_parts/robot_component/binary_communication_device
	name = "binary communication device"
	icon_state = "binradio"
	icon_state_broken = "binradio_broken"

/obj/item/robot_parts/robot_component/actuator
	name = "actuator"
	icon_state = "motor"
	icon_state_broken = "motor_broken"

/obj/item/robot_parts/robot_component/armour
	name = "armour plating"
	icon_state = "armor"
	icon_state_broken = "armor_broken"

/obj/item/robot_parts/robot_component/armour/light
	name = "light-weight armour plating"
	material = /decl/material/solid/metal/steel

/obj/item/robot_parts/robot_component/camera
	name = "camera"
	icon_state = "camera"
	icon_state_broken = "camera_broken"

/obj/item/robot_parts/robot_component/diagnosis_unit
	name = "diagnosis unit"
	icon_state = "analyser"
	icon_state_broken = "analyser_broken"

/obj/item/robot_parts/robot_component/radio
	name = "radio"
	icon_state = "radio"
	icon_state_broken = "radio_broken"