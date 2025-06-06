/mob/living/exosuit/premade/heavy
	name = "Heavy exosuit"
	desc = "A heavily armored combat exosuit."

/obj/item/mech_component/manipulators/heavy/painted
	color = COLOR_TITANIUM

/obj/item/mech_component/propulsion/heavy/painted
	color = COLOR_TITANIUM

/obj/item/mech_component/sensors/heavy/painted
	color = COLOR_TITANIUM

/obj/item/mech_component/chassis/heavy/painted
	color = COLOR_TITANIUM

/mob/living/exosuit/premade/heavy/Initialize()
	if(!arms)
		arms = new /obj/item/mech_component/manipulators/heavy/painted(src)
	if(!legs)
		legs = new /obj/item/mech_component/propulsion/heavy/painted(src)
	if(!head)
		head = new /obj/item/mech_component/sensors/heavy/painted(src)
	if(!body)
		body = new /obj/item/mech_component/chassis/heavy/painted(src)
	. = ..()

/mob/living/exosuit/premade/heavy/spawn_mech_equipment()
	..()
	install_system(new /obj/item/mech_equipment/mounted_system/taser/laser(src), HARDPOINT_LEFT_HAND)
	install_system(new /obj/item/mech_equipment/mounted_system/taser/ion(src), HARDPOINT_RIGHT_HAND)
	install_system(new /obj/item/mech_equipment/shields(src), HARDPOINT_BACK)

/obj/item/mech_component/manipulators/heavy
	name = "heavy arms"
	exosuit_desc_string = "super-heavy reinforced manipulators"
	icon_state = "heavy_arms"
	desc = "Designed to function where any other piece of equipment would have long fallen apart, the Superheavy Lifter series can take a beating and excel at delivering it."
	melee_damage = 25
	action_delay = 15
	max_damage = 90
	power_use = 60
	material = /decl/material/solid/metal/steel

/obj/item/mech_component/propulsion/heavy
	name = "heavy legs"
	exosuit_desc_string = "heavy hydraulic legs"
	desc = "Oversized actuators struggle to move these armoured legs. "
	icon_state = "heavy_legs"
	move_delay = 5
	turn_delay = 5
	max_damage = 160
	power_use = 100
	material = /decl/material/solid/metal/steel

/obj/item/mech_component/sensors/heavy
	name = "heavy sensors"
	exosuit_desc_string = "a reinforced monoeye"
	desc = "A solitary sensor moves inside a recessed slit in the armour plates."
	icon_state = "heavy_head"
	max_damage = 120
	power_use = 0
	material = /decl/material/solid/metal/steel

/obj/item/mech_component/sensors/heavy/prebuild()
	..()
	software = new(src)
	software.installed_software = list(MECH_SOFTWARE_WEAPONS)

/obj/item/mech_component/chassis/heavy
	name = "reinforced exosuit chassis"
	hatch_descriptor = "hatch"
	desc = "The HI-Koloss chassis is a veritable juggernaut, capable of protecting a pilot even in the most hostile of environments. It handles like a battlecruiser, however."
	pilot_coverage = 100
	exosuit_desc_string = "a heavily armoured chassis"
	icon_state = "heavy_body"
	max_damage = 150
	mech_health = 500
	power_use = 50
	has_hardpoints = list(HARDPOINT_BACK)
	material = /decl/material/solid/metal/steel
	matter = list(/decl/material/solid/metal/uranium = MATTER_AMOUNT_REINFORCEMENT)

/obj/item/mech_component/chassis/heavy/prebuild()
	pilot_positions = list(
		list(
			"[NORTH]" = list("x" = 8,  "y" = 8),
			"[SOUTH]" = list("x" = 9,  "y" = 2),
			"[EAST]"  = list("x" = 4,  "y" = 8),
			"[WEST]"  = list("x" = 12, "y" = 8)
		)
	)
	. = ..()
	m_armour = new /obj/item/robot_parts/robot_component/armour/exosuit/combat(src)

/mob/living/exosuit/premade/heavy/merc/Initialize()
	. = ..()
	if(arms)
		arms.color = COLOR_RED
	if(legs)
		legs.color = COLOR_RED
	if(head)
		head.color = COLOR_RED
	if(body)
		body.color = COLOR_DARK_GUNMETAL

/mob/living/exosuit/premade/heavy/merc/spawn_mech_equipment()
	install_system(new /obj/item/mech_equipment/mounted_system/taser(src), HARDPOINT_LEFT_HAND)
	install_system(new /obj/item/mech_equipment/mounted_system/taser/laser(src), HARDPOINT_RIGHT_HAND)
	install_system(new /obj/item/mech_equipment/shields(src), HARDPOINT_BACK)

/obj/structure/mech_wreckage/heavy
	name = "heavy exosuit wreckage"
	loot_pool = list(
		/obj/item/mech_equipment/mounted_system/taser =       80,
		/obj/item/mech_equipment/mounted_system/taser/laser = 80,
		/obj/item/mech_equipment/shields =                    80,
		/obj/item/mech_component/manipulators/heavy/painted = 40,
		/obj/item/mech_component/propulsion/heavy/painted =   40,
		/obj/item/mech_component/sensors/heavy/painted =      40,
		/obj/item/mech_component/chassis/heavy/painted =      40
	)
