/obj/item/mech_equipment/sleeper
	name = "\improper exosuit sleeper"
	desc = "An exosuit-mounted sleeper designed to maintain patients stabilized on their way to medical facilities."
	icon_state = "mech_sleeper"
	restricted_hardpoints = list(HARDPOINT_BACK)
	restricted_software = list(MECH_SOFTWARE_MEDICAL)
	equipment_delay = 30 //don't spam it on people pls
	active_power_use = 0 //Usage doesn't really require power. We don't want people stuck inside
	origin_tech = @'{"programming":2,"biotech":3}'
	passive_power_use = 1.5 KILOWATTS
	var/obj/machinery/sleeper/mounted/sleeper = null

/obj/item/mech_equipment/sleeper/Initialize()
	. = ..()
	sleeper = new /obj/machinery/sleeper/mounted(src)
	sleeper.forceMove(src)

/obj/item/mech_equipment/sleeper/Destroy()
	sleeper.go_out() //If for any reason you weren't outside already.
	QDEL_NULL(sleeper)
	. = ..()

/obj/item/mech_equipment/sleeper/uninstalled()
	. = ..()
	sleeper?.go_out()

/obj/item/mech_equipment/sleeper/attack_self(var/mob/user)
	. = ..()
	if(.)
		sleeper.ui_interact(user)

/obj/item/mech_equipment/sleeper/attackby(var/obj/item/used_item, var/mob/user)
	if(istype(used_item, /obj/item/chems/glass))
		return sleeper.attackby(used_item, user)
	else
		return ..()

/obj/item/mech_equipment/sleeper/afterattack(var/atom/target, var/mob/living/user, var/inrange, var/params)
	. = ..()
	if(.)
		if(ishuman(target) && !sleeper.occupant)
			owner.visible_message(SPAN_NOTICE("\The [src] is lowered down to load [target]."))
			sleeper.go_in(target, user)
		else to_chat(user, SPAN_WARNING("You cannot load that in!"))

/obj/item/mech_equipment/sleeper/get_hardpoint_maptext()
	if(sleeper && sleeper.occupant)
		return "[sleeper.occupant]"

/obj/machinery/sleeper/mounted
	name = "\improper mounted sleeper"
	density = FALSE
	anchored = FALSE
	idle_power_usage = 0
	active_power_usage = 0 //It'd be hard to handle, so for now all power is consumed by mech sleeper object
	stasis_power = 0
	interact_offline = TRUE
	stat_immune = NOPOWER

/obj/machinery/sleeper/mounted/standard/Initialize(mapload, d, populate_parts)
	. = ..()
	add_reagent_canister(null, new /obj/item/chems/chem_disp_cartridge/adrenaline())
	add_reagent_canister(null, new /obj/item/chems/chem_disp_cartridge/sedatives())
	add_reagent_canister(null, new /obj/item/chems/chem_disp_cartridge/painkillers())
	add_reagent_canister(null, new /obj/item/chems/chem_disp_cartridge/antitoxins())
	add_reagent_canister(null, new /obj/item/chems/chem_disp_cartridge/oxy_meds())

/obj/machinery/sleeper/mounted/DefaultTopicState()
	return global.mech_topic_state

/obj/machinery/sleeper/mounted/ui_interact(var/mob/user, var/ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1, var/datum/topic_state/state = global.mech_topic_state)
	. = ..()

/obj/machinery/sleeper/mounted/nano_host()
	var/obj/item/mech_equipment/sleeper/S = loc
	if(istype(S))
		return S.owner
	return null

//You cannot modify these, it'd probably end with something in nullspace. In any case basic meds are plenty for an ambulance
/obj/machinery/sleeper/mounted/attackby(var/obj/item/used_item, var/mob/user)
	if(istype(used_item, /obj/item/chems/glass))
		if(!user.try_unequip(used_item, src))
			return TRUE
		if(beaker)
			user.put_in_hands(beaker)
			user.visible_message("<span class='notice'>\The [user] removes \the [beaker] from \the [src].</span>", "<span class='notice'>You remove \the [beaker] from \the [src].</span>")
		beaker = used_item
		user.visible_message("<span class='notice'>\The [user] adds \a [used_item] to \the [src].</span>", "<span class='notice'>You add \a [used_item] to \the [src].</span>")
		return TRUE
	return FALSE
