#include "bearcat_areas.dm"
#include "bearcat_jobs.dm"
#include "bearcat_access.dm"

/obj/abstract/submap_landmark/joinable_submap/bearcat
	name      = "FTV Bearcat"
	archetype = /decl/submap_archetype/derelict/bearcat

/decl/submap_archetype/derelict/bearcat
	name      = "derelict cargo vessel"
	crew_jobs = list(
		/datum/job/submap/bearcat_captain,
		/datum/job/submap/bearcat_crewman
	)

/obj/effect/overmap/visitable/ship/bearcat
	name = "light freighter"
	color = "#00ffff"
	vessel_mass = 60
	max_speed = 1/(10 SECONDS)
	burn_delay = 10 SECONDS

/obj/effect/overmap/visitable/ship/bearcat/Initialize()
	name = "[pick("FTV","ITV","IEV")] [pick("Bearcat", "Firebug", "Defiant", "Unsinkable","Horizon","Vagrant")]"
	for(var/area/ship/scrap/A)
		A.name = "\improper [name] - [A.name]"
		global.using_map.area_purity_test_exempt_areas += A.type
	name = "[name], \a [initial(name)]"
	. = ..()

/datum/map_template/ruin/away_site/bearcat_wreck
	name = "Bearcat Wreck"
	description = "A wrecked light freighter."
	suffixes = list("bearcat/bearcat-1.dmm", "bearcat/bearcat-2.dmm")
	cost = 1
	shuttles_to_initialise = list(/datum/shuttle/autodock/ferry/lift)
	area_usage_test_exempted_root_areas = list(/area/ship)
	apc_test_exempt_areas = list(
		/area/ship/scrap/maintenance/engine/port = NO_SCRUBBER|NO_VENT,
		/area/ship/scrap/maintenance/engine/starboard = NO_SCRUBBER|NO_VENT,
		/area/ship/scrap/crew/hallway/port= NO_SCRUBBER|NO_VENT,
		/area/ship/scrap/crew/hallway/starboard= NO_SCRUBBER|NO_VENT,
		/area/ship/scrap/maintenance/hallway = NO_SCRUBBER|NO_VENT,
		/area/ship/scrap/maintenance/lower = NO_SCRUBBER|NO_VENT,
		/area/ship/scrap/maintenance/atmos = NO_SCRUBBER,
		/area/ship/scrap/escape_port = NO_SCRUBBER|NO_VENT,
		/area/ship/scrap/escape_star = NO_SCRUBBER|NO_VENT,
		/area/ship/scrap/shuttle/lift = NO_SCRUBBER|NO_VENT|NO_APC,
		/area/ship/scrap/command/hallway = NO_SCRUBBER|NO_VENT
	)

/datum/shuttle/autodock/ferry/lift
	name = "Cargo Lift"
	shuttle_area = /area/ship/scrap/shuttle/lift
	warmup_time = 3	//give those below some time to get out of the way
	waypoint_station = "nav_bearcat_lift_bottom"
	waypoint_offsite = "nav_bearcat_lift_top"
	sound_takeoff = 'sound/effects/lift_heavy_start.ogg'
	sound_landing = 'sound/effects/lift_heavy_stop.ogg'
	ceiling_type = null
	knockdown = 0
	defer_initialisation = TRUE

/obj/machinery/computer/shuttle_control/lift
	name = "cargo lift controls"
	shuttle_tag = "Cargo Lift"
	ui_template = "shuttle_control_console_lift.tmpl"
	icon_state = "tiny"
	icon_keyboard = "tiny_keyboard"
	icon_screen = "lift"
	density = FALSE

/obj/effect/shuttle_landmark/lift/top
	name = "Top Deck"
	landmark_tag = "nav_bearcat_lift_top"
	flags = SLANDMARK_FLAG_AUTOSET

/obj/effect/shuttle_landmark/lift/bottom
	name = "Lower Deck"
	landmark_tag = "nav_bearcat_lift_bottom"
	base_area = /area/ship/scrap/cargo/lower
	base_turf = /turf/floor/plating

/obj/machinery/door/airlock/autoname/command
	door_color = COLOR_COMMAND_BLUE

/obj/machinery/door/airlock/autoname/engineering
	door_color = COLOR_AMBER

/turf/floor/usedup
	initial_gas = list(/decl/material/gas/carbon_dioxide = MOLES_O2STANDARD, /decl/material/gas/nitrogen = MOLES_N2STANDARD)

/turf/floor/tiled/usedup
	initial_gas = list(/decl/material/gas/carbon_dioxide = MOLES_O2STANDARD, /decl/material/gas/nitrogen = MOLES_N2STANDARD)

/turf/floor/tiled/dark/usedup
	initial_gas = list(/decl/material/gas/carbon_dioxide = MOLES_O2STANDARD, /decl/material/gas/nitrogen = MOLES_N2STANDARD)

/turf/floor/tiled/white/usedup
	initial_gas = list(/decl/material/gas/carbon_dioxide = MOLES_O2STANDARD, /decl/material/gas/nitrogen = MOLES_N2STANDARD)

/obj/abstract/landmark/corpse/deadcap
	name = "Dead Captain"
	corpse_outfits = list(/decl/outfit/deadcap)
	delete_me = FALSE //  we handle this in LateInit

/obj/abstract/landmark/corpse/deadcap/Initialize()
	..()
	return INITIALIZE_HINT_LATELOAD

/obj/abstract/landmark/corpse/deadcap/LateInitialize()
	var/mob/corpse = my_corpse?.resolve()
	if(!istype(corpse))
		return
	corpse.SetName("Captain")
	var/obj/structure/chair/C = locate() in loc
	if(C)
		C.buckle_mob(corpse)
	qdel(src)

/decl/outfit/deadcap
	name = "Derelict Captain"
	uniform = /obj/item/clothing/pants/baggy/casual/classicjeans
	suit = /obj/item/clothing/suit/jacket/winter
	shoes = /obj/item/clothing/shoes/color/black
	r_pocket = /obj/item/radio

/decl/outfit/deadcap/post_equip(mob/living/wearer)
	..()
	var/obj/item/clothing/uniform = wearer.get_equipped_item(slot_w_uniform_str)
	if(uniform)
		var/obj/item/clothing/shirt/hawaii/random/eyegore = new()
		if(uniform.can_attach_accessory(eyegore))
			uniform.attach_accessory(null, eyegore)
		else
			qdel(eyegore)
	var/obj/item/cell/super/C = new()
	wearer.put_in_hands(C)
