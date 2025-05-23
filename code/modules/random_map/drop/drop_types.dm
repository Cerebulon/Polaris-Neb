var/global/list/datum/supply_drop_loot/supply_drop

/proc/supply_drop_random_loot_types()
	if(!supply_drop)
		supply_drop = init_subtypes(/datum/supply_drop_loot)
		supply_drop = dd_sortedObjectList(supply_drop)
	return supply_drop

/datum/supply_drop_loot
	var/name = ""
	var/container = null
	var/list/contents = null

/datum/supply_drop_loot/proc/contents()
	return contents

/datum/supply_drop_loot/proc/drop(turf/T)
	var/C = container ? new container(T) : T
	for(var/content in contents())
		new content(C)

/datum/supply_drop_loot/dd_SortValue()
	return name

/datum/supply_drop_loot/lasers
	name = "Lasers"
	container = /obj/structure/largecrate
/datum/supply_drop_loot/lasers/New()
	..()
	contents = list(
		/obj/item/gun/energy/laser,
		/obj/item/gun/energy/laser,
		/obj/item/gun/energy/sniperrifle,
		/obj/item/gun/energy/ionrifle)

/datum/supply_drop_loot/ballistics
	name = "Ballistics"
	container = /obj/structure/largecrate
/datum/supply_drop_loot/ballistics/New()
	..()
	contents = list(
		/obj/item/gun/projectile/pistol,
		/obj/item/gun/projectile/shotgun/doublebarrel,
		/obj/item/gun/projectile/shotgun/pump,
		/obj/item/gun/projectile/automatic/smg,
		/obj/item/gun/projectile/automatic/assault_rifle)

/datum/supply_drop_loot/seeds
	name = "Seeds"
	container = /obj/structure/closet/crate
/datum/supply_drop_loot/seeds/New()
	..()
	contents = list(
		/obj/item/seeds/chiliseed,
		/obj/item/seeds/berryseed,
		/obj/item/seeds/cornseed,
		/obj/item/seeds/eggplantseed,
		/obj/item/seeds/tomatoseed,
		/obj/item/seeds/appleseed,
		/obj/item/seeds/soyaseed,
		/obj/item/seeds/wheatseed,
		/obj/item/seeds/carrotseed,
		/obj/item/seeds/lemonseed,
		/obj/item/seeds/orangeseed,
		/obj/item/seeds/grassseed,
		/obj/item/seeds/sunflowerseed,
		/obj/item/seeds/chantermycelium,
		/obj/item/seeds/potatoseed,
		/obj/item/seeds/sugarcaneseed)

/datum/supply_drop_loot/food
	name = "Food"
	container = /obj/structure/largecrate
/datum/supply_drop_loot/food/New()
	..()
	contents = list(
		/obj/item/chems/condiment/yeast,
		/obj/item/chems/condiment/flour,
		/obj/item/chems/condiment/flour,
		/obj/item/chems/condiment/flour,
		/obj/item/chems/drinks/milk,
		/obj/item/chems/drinks/milk,
		/obj/item/food/dairy/butter/stick,
		/obj/item/box/fancy/egg_box,
		/obj/item/food/tofu,
		/obj/item/food/tofu,
		/obj/item/food/butchery/meat,
		/obj/item/food/butchery/meat)

/datum/supply_drop_loot/armour
	name = "Armour"
	container = /obj/structure/largecrate
/datum/supply_drop_loot/armour/New()
	..()
	contents = list(
		/obj/item/clothing/head/helmet/riot,
		/obj/item/clothing/suit/armor/riot,
		/obj/item/clothing/head/helmet/riot,
		/obj/item/clothing/suit/armor/riot,
		/obj/item/clothing/head/helmet/riot,
		/obj/item/clothing/suit/armor/riot,
		/obj/item/clothing/suit/armor/vest,
		/obj/item/clothing/suit/armor/vest,
		/obj/item/clothing/suit/armor/vest/heavy,
		/obj/item/clothing/suit/armor/vest/heavy,
		/obj/item/clothing/suit/armor/laserproof,
		/obj/item/clothing/suit/armor/bulletproof)

/datum/supply_drop_loot/materials
	name = "Materials"
	container = /obj/structure/largecrate
/datum/supply_drop_loot/materials/New()
	..()
	contents = list(
		/obj/item/stack/material/sheet/mapped/steel,
		/obj/item/stack/material/sheet/mapped/steel,
		/obj/item/stack/material/sheet/mapped/steel,
		/obj/item/stack/material/pane/mapped/glass,
		/obj/item/stack/material/pane/mapped/glass,
		/obj/item/stack/material/plank/mapped/wood,
		/obj/item/stack/material/panel/mapped/plastic,
		/obj/item/stack/material/pane/mapped/rglass,
		/obj/item/stack/material/sheet/reinforced/mapped/plasteel)

/datum/supply_drop_loot/medical
	name = "Medical"
	container = /obj/structure/closet/crate/medical
/datum/supply_drop_loot/medical/New()
	..()
	contents = list(
		/obj/item/firstaid/regular,
		/obj/item/firstaid/trauma,
		/obj/item/firstaid/fire,
		/obj/item/firstaid/toxin,
		/obj/item/firstaid/o2,
		/obj/item/firstaid/adv,
		/obj/item/chems/glass/bottle/antitoxin,
		/obj/item/chems/glass/bottle/stabilizer,
		/obj/item/chems/glass/bottle/sedatives,
		/obj/item/box/syringes,
		/obj/item/box/autoinjectors)

/datum/supply_drop_loot/materials
	name = "Materials"
	container = /obj/structure/largecrate
/datum/supply_drop_loot/materials/New()
	..()
	contents = list(
		/obj/item/stack/material/sheet/mapped/steel,
		/obj/item/stack/material/sheet/mapped/steel,
		/obj/item/stack/material/sheet/mapped/steel,
		/obj/item/stack/material/pane/mapped/glass,
		/obj/item/stack/material/pane/mapped/glass,
		/obj/item/stack/material/plank/mapped/wood,
		/obj/item/stack/material/panel/mapped/plastic,
		/obj/item/stack/material/pane/mapped/rglass,
		/obj/item/stack/material/sheet/reinforced/mapped/plasteel)

/datum/supply_drop_loot/hydroponics
	name = "Hydroponics"
	container = /obj/structure/largecrate
/datum/supply_drop_loot/hydroponics/New()
	..()
	contents = list(
		/obj/machinery/portable_atmospherics/hydroponics,
		/obj/machinery/portable_atmospherics/hydroponics,
		/obj/machinery/portable_atmospherics/hydroponics)

/datum/supply_drop_loot/power
	name = "Power"
	container = /obj/structure/largecrate
/datum/supply_drop_loot/power/New()
	..()
	contents = list(
		/obj/machinery/port_gen/pacman,
		/obj/machinery/port_gen/pacman/super,
		/obj/machinery/port_gen/pacman/mrs)

/datum/supply_drop_loot/power/contents()
	return list(pick(contents))
