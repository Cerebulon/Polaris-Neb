/datum/map_template/ruin/exoplanet/ec_old_crash
	name = "Expeditionary Ship"
	description = "An abandoned ancient STL exploration ship."
	prefix = "mods/content/government/ruins/"
	suffixes = list("ec_old_crash/ec_old_crash.dmm")
	cost = 0.5
	apc_test_exempt_areas = list(
		/area/map_template/ecship/engine = NO_SCRUBBER|NO_VENT|NO_APC,
		/area/map_template/ecship/cockpit = NO_SCRUBBER|NO_APC
	)
	template_tags = TEMPLATE_TAG_HUMAN|TEMPLATE_TAG_WRECK
	template_flags = TEMPLATE_FLAG_CLEAR_CONTENTS | TEMPLATE_FLAG_NO_RUINS

/area/map_template/ecship/crew
	name = "\improper Crew Area"
	icon_state = "crew_quarters"

/area/map_template/ecship/science
	name = "\improper Science Module"
	icon_state = "xeno_lab"

/area/map_template/ecship/cryo
	name = "\improper Cryosleep Module"
	icon_state = "cryo"

/area/map_template/ecship/engineering
	name = "\improper Engineering"
	icon_state = "engineering_supply"

/area/map_template/ecship/engine
	name = "\improper Engine Exterior"
	icon_state = "engine"
	area_flags = AREA_FLAG_EXTERNAL

/area/map_template/ecship/cockpit
	name = "\improper Cockpit"
	icon_state = "bridge"

//Low pressure setup
/obj/machinery/atmospherics/unary/vent_pump/low
	use_power = 1
	icon_state = "map_vent_out"
	external_pressure_bound = 0.25 ATM

/turf/floor/tiled/lowpressure
	initial_gas = list(/decl/material/gas/carbon_dioxide = MOLES_O2STANDARD)

/turf/floor/tiled/white/lowpressure
	initial_gas = list(/decl/material/gas/carbon_dioxide = MOLES_O2STANDARD)

/obj/item/disk/astrodata
	name = "astronomical data disk"
	desc = "A disk with a wealth of astronomical data recorded. Astrophysicists at the EC Observatory would love to see this."
	color = COLOR_BLUE_GRAY

/obj/item/ecletters
	name = "bundle of letters"
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "docs_part"
	item_state = "paper"
	material = /decl/material/solid/organic/paper

/obj/item/ecletters/Initialize()
	. = ..()
	desc = "A bunch of letters from Galactic Survey Administration explorers to their family and loved ones, dated [global.using_map.game_year - 142]. They're not hopeful."

/obj/item/paper/ecrashlog
	name = "handwritten note"

/obj/item/paper/ecrashlog/Initialize()
	. = ..()
	var/shipname = "SCG-E [pick("Magellan", "Gagarin", "Drake", "Horizon", "Aurora")]"
	var/decl/background_detail/S = GET_DECL(/decl/background_detail/heritage/human)
	var/new_info = {"
	I am Lieutenant Hao Ru, captain of [shipname], of the Galactic Survey Administration.<br>
	We are dying. The Ran Mission has failed.<br>
	Our ship has suffered a catastrophic chain of failures whist crew was in cryotransit. It started with thruster controls going inoperable, and our auto-pilot was unable to adjust course away from an asteroid cluster. <br>
	We've lost the navigational suite from impacts, and are flying blind. We have tried every option, and our engineers have ascertained that there is no way to repair it in the field.<br>
	Most of the crew have accepted their fate quietly, and have opted to go back into cryo for a slim hope of rescue, if we were to be found before backup power runs out. I will soon join them, after completing my duty.<br>
	I've used this module as a strongbox, because it is only one rated for re-entry. I leave the astrodata I managed to salvage here. It has a few promising scans. I would not want it to be wasted.<br>
	Some of the crew wrote letters to their kin, in case we are found. They deserve any consolation they get, so I've put the letters here, too.<br>
	The crew for this mission is:<br>
	Ensign [S.get_random_name(null, pick(MALE,FEMALE))]<br>
	Ensign [S.get_random_name(null, pick(MALE,FEMALE))]<br>
	Chief Explorer [S.get_random_name(null, pick(MALE,FEMALE))]<br>
	Senior Explorer [S.get_random_name(null, pick(MALE,FEMALE))]<br>
	Senior Explorer [S.get_random_name(null, pick(MALE,FEMALE))]<br>
	Explorer [S.get_random_name(null, pick(MALE,FEMALE))]<br>
	I am Lieutenant Hao Ru, captain of [shipname] of the Galactic Survey Administration. I will be joining my crew in cryo now.<br>
	<i>3rd December [global.using_map.game_year - 142]</i></tt>
	"}
	set_content(new_info)

/obj/machinery/alarm/low/Initialize()
	. = ..()
	TLV["pressure"] = list(0.10 ATM, 0.20 ATM, 1.10 ATM, 1.20 ATM)
