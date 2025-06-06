/obj/machinery/optable
	name = "operating table"
	desc = "Used for advanced medical procedures."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "table2-idle"
	density = TRUE
	anchored = TRUE
	throwpass = 1
	idle_power_usage = 1
	active_power_usage = 5
	construct_state = /decl/machine_construction/default/panel_closed
	uncreated_component_parts = null

	var/suppressing = FALSE
	var/mob/living/victim
	var/obj/machinery/computer/operating/computer = null

/obj/machinery/optable/Initialize()
	. = ..()
	for(dir in list(NORTH,EAST,SOUTH,WEST))
		computer = locate(/obj/machinery/computer/operating, get_step(src, dir))
		if (computer)
			computer.table = src
			break

/obj/machinery/optable/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	. += SPAN_NOTICE("The neural suppressors are switched [suppressing ? "on" : "off"].")

/obj/machinery/optable/grab_attack(obj/item/grab/grab, mob/user)
	if(isliving(grab.affecting) && check_table(grab.affecting))
		take_victim(grab.affecting, user)
		qdel(grab)
		return TRUE
	return ..()

/obj/machinery/optable/state_transition(var/decl/machine_construction/default/new_state)
	. = ..()
	if(istype(new_state))
		updateUsrDialog()

/obj/machinery/optable/physical_attack_hand(var/mob/user)

	if(!victim)
		to_chat(user, "<span class='warning'>There is nobody on \the [src]. It would be pointless to turn the suppressor on.</span>")
		return TRUE

	if(stat & (NOPOWER|BROKEN))
		to_chat(user, "<span class='warning'>You try to switch on the suppressor, yet nothing happens.</span>")
		return TRUE

	if(user != victim && !suppressing) // Skip checks if you're doing it to yourself or turning it off, this is an anti-griefing mechanic more than anything.
		user.visible_message("<span class='warning'>\The [user] begins switching on \the [src]'s neural suppressor.</span>")
		if(!do_after(user, 30, src) || !user || !src || user.incapacitated() || !user.Adjacent(src))
			return TRUE
		if(!victim)
			to_chat(user, "<span class='warning'>There is nobody on \the [src]. It would be pointless to turn the suppressor on.</span>")
			return TRUE

	suppressing = !suppressing
	user.visible_message("<span class='notice'>\The [user] switches [suppressing ? "on" : "off"] \the [src]'s neural suppressor.</span>")
	return TRUE

/obj/machinery/optable/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	. = (air_group || height == 0 || (istype(mover) && mover.checkpass(PASS_FLAG_TABLE)))

/obj/machinery/optable/receive_mouse_drop(atom/dropping, mob/user, params)
	. = ..()
	if(!.)
		if(istype(dropping, /obj/item) && user.get_active_held_item() == dropping && user.try_unequip(dropping, loc))
			return FALSE
		if(isliving(dropping) && check_table(dropping))
			take_victim(dropping, user)
			return FALSE

/obj/machinery/optable/proc/check_victim()
	if(!victim || !victim.current_posture.prone || victim.loc != loc)
		suppressing = FALSE
		victim = null
		for(var/mob/living/human/H in loc)
			if(H.current_posture.prone)
				victim = H
				break
	if(victim)
		if(suppressing && GET_STATUS(victim, STAT_ASLEEP) < 3)
			SET_STATUS_MAX(victim, STAT_ASLEEP, 3)
	. = !!victim
	update_icon()

/obj/machinery/optable/on_update_icon()
	icon_state = "table2-idle"
	if(ishuman(victim))
		var/mob/living/human/H = victim
		if(H.get_pulse())
			icon_state = "table2-active"

/obj/machinery/optable/Process()
	check_victim()

/obj/machinery/optable/proc/take_victim(mob/living/target, mob/living/user)
	if (target == user)
		user.visible_message( \
		SPAN_NOTICE("\The [user] climbs on \the [src]."), \
		SPAN_NOTICE("You climb on \the [src]."))
	else
		visible_message(SPAN_NOTICE("\The [target] has been laid on \the [src] by \the [user]."))
	target.dropInto(loc)
	target.set_posture(/decl/posture/lying/deliberate)
	add_fingerprint(user)
	update_icon()

/obj/machinery/optable/climb_on()
	if(usr.stat || !ishuman(usr) || usr.restrained() || !check_table(usr))
		return
	take_victim(usr,usr)

/obj/machinery/optable/proc/check_table(mob/living/patient)
	check_victim()
	if(src.victim && get_turf(victim) == get_turf(src) && victim.current_posture.prone)
		to_chat(usr, "<span class='warning'>\The [src] is already occupied!</span>")
		return FALSE
	if(patient.buckled)
		to_chat(usr, "<span class='notice'>Unbuckle \the [patient] first!</span>")
		return FALSE
	if(patient.anchored)
		return FALSE
	return TRUE

/obj/machinery/optable/power_change()
	. = ..()
	if(stat & (NOPOWER|BROKEN))
		suppressing = FALSE

/obj/machinery/optable/get_surgery_surface_quality(mob/living/victim, mob/living/user)
	return OPERATE_IDEAL