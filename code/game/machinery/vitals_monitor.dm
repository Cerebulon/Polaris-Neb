
/obj/machinery/vitals_monitor
	name = "vitals monitor"
	desc = "A bulky yet mobile machine, showing some odd graphs."
	icon = 'icons/obj/heartmonitor.dmi'
	icon_state = "base"
	anchored = FALSE
	power_channel = EQUIP
	idle_power_usage = 10
	active_power_usage = 100
	stat_immune = NOINPUT
	uncreated_component_parts = null
	construct_state = /decl/machine_construction/default/panel_closed

	var/mob/living/human/victim
	var/beep = TRUE

/obj/machinery/vitals_monitor/Destroy()
	victim = null
	. = ..()

/obj/machinery/vitals_monitor/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	if(victim)
		if(stat & NOPOWER)
			. += SPAN_NOTICE("It's unpowered.")
			return
		. += SPAN_NOTICE("Vitals of [victim]:")
		. += SPAN_NOTICE("Pulse: [victim.get_pulse_as_string(GETPULSE_TOOL)]")

		var/brain_activity = "none"
		var/obj/item/organ/internal/brain = GET_INTERNAL_ORGAN(victim, BP_BRAIN)
		if(brain && victim.stat != DEAD && !(victim.status_flags & FAKEDEATH))
			if(user.skill_check(SKILL_MEDICAL, SKILL_BASIC))
				switch(brain.get_current_damage_threshold())
					if(0 to 2)
						brain_activity = "normal"
					if(3 to 5)
						brain_activity = "weak"
					if(6 to INFINITY)
						brain_activity = "extremely weak"
			else
				brain_activity = "some"
		. += SPAN_NOTICE("Brain activity: [brain_activity]")

		var/breathing = "none"
		var/obj/item/organ/internal/lungs/lungs = victim.get_organ(BP_LUNGS, /obj/item/organ/internal/lungs)
		if(istype(lungs) && !(victim.status_flags & FAKEDEATH))
			if(lungs.breath_fail_ratio < 0.3)
				breathing = "normal"
			else if(lungs.breath_fail_ratio < 1)
				breathing = "shallow"

		. += SPAN_NOTICE("Breathing: [breathing]")

/obj/machinery/vitals_monitor/Process()
	if(QDELETED(victim))
		victim = null
	if(victim && !Adjacent(victim))
		victim = null
		update_use_power(POWER_USE_IDLE)
	if(victim)
		update_icon()
	if(beep && victim && victim.get_pulse())
		playsound(src, 'sound/machines/quiet_beep.ogg', 40)

/obj/machinery/vitals_monitor/handle_mouse_drop(atom/over, mob/user, params)
	if(ishuman(over))
		if(victim)
			victim = null
			update_use_power(POWER_USE_IDLE)
		victim = over
		update_use_power(POWER_USE_ACTIVE)
		visible_message(SPAN_NOTICE("\The [src] is now showing data for \the [victim]."))
		return TRUE
	. = ..()

/obj/machinery/vitals_monitor/on_update_icon()
	overlays.Cut()
	if(stat & NOPOWER)
		return
	overlays += image(icon, icon_state = "screen")

	if(!victim)
		return

	switch(victim.get_pulse())
		if(PULSE_NONE)
			overlays += image(icon, icon_state = "pulse_flatline")
			overlays += image(icon, icon_state = "pulse_warning")
		if(PULSE_SLOW, PULSE_NORM,)
			overlays += image(icon, icon_state = "pulse_normal")
		if(PULSE_FAST, PULSE_2FAST)
			overlays += image(icon, icon_state = "pulse_veryfast")
		if(PULSE_THREADY)
			overlays += image(icon, icon_state = "pulse_thready")
			overlays += image(icon, icon_state = "pulse_warning")

	var/obj/item/organ/internal/brain = GET_INTERNAL_ORGAN(victim, BP_BRAIN)
	if(istype(brain) && victim.stat != DEAD && !(victim.status_flags & FAKEDEATH))
		switch(brain.get_current_damage_threshold())
			if(0 to 2)
				overlays += image(icon, icon_state = "brain_ok")
			if(3 to 5)
				overlays += image(icon, icon_state = "brain_bad")
			if(6 to INFINITY)
				overlays += image(icon, icon_state = "brain_verybad")
				overlays += image(icon, icon_state = "brain_warning")
	else
		overlays += image(icon, icon_state = "brain_warning")

	var/obj/item/organ/internal/lungs/lungs = victim.get_organ(BP_LUNGS, /obj/item/organ/internal/lungs)
	if(istype(lungs) && !(victim.status_flags & FAKEDEATH))
		if(lungs.breath_fail_ratio < 0.3)
			overlays += image(icon, icon_state = "breathing_normal")
		else if(lungs.breath_fail_ratio < 1)
			overlays += image(icon, icon_state = "breathing_shallow")
		else
			overlays += image(icon, icon_state = "breathing_warning")
	else
		overlays += image(icon, icon_state = "breathing_warning")

/obj/machinery/vitals_monitor/verb/toggle_beep()
	set name = "Toggle Monitor Beeping"
	set category = "Object"
	set src in view(1)

	var/mob/user = usr
	if(!istype(user))
		return

	if(CanPhysicallyInteract(user))
		beep = !beep
		to_chat(user, SPAN_NOTICE("You turn the sound on \the [src] [beep ? "on" : "off"]."))

/obj/item/stock_parts/circuitboard/vitals_monitor
	name = "circuit board (Vitals Monitor)"
	build_path = /obj/machinery/vitals_monitor
	board_type = "machine"
	req_components = list(
		/obj/item/stock_parts/console_screen = 1)
	additional_spawn_components = list(
		/obj/item/stock_parts/power/battery/buildable/stock = 1,
		/obj/item/cell/high = 1
	)