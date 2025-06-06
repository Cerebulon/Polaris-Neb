// TODO: This is literally only available from abandoned mining crates. Remove?
/obj/item/latexballon
	name = "latex glove"
	desc = "A latex glove, usually used as a balloon."
	icon = 'icons/obj/items/latexballon.dmi'
	icon_state = "latexballon"
	item_state = "lgloves"
	w_class = ITEM_SIZE_SMALL
	throw_speed = 1
	throw_range = 15
	material = /decl/material/solid/organic/plastic
	_base_attack_force = 0
	var/datum/gas_mixture/air_contents = null

/obj/item/latexballon/proc/blow(obj/item/tank/tank)
	if (icon_state == "latexballon_bursted")
		return
	src.air_contents = tank.remove_air_volume(3)
	icon_state = "latexballon_blow"
	item_state = "latexballon"

/obj/item/latexballon/proc/burst()
	if (!air_contents)
		return
	playsound(src, 'sound/weapons/gunshot/gunshot.ogg', 100, 1)
	icon_state = "latexballon_bursted"
	item_state = "lgloves"
	loc.assume_air(air_contents)

/obj/item/latexballon/explosion_act(severity)
	..()
	if(!QDELETED(src))
		if(severity == 1 || (severity == 2 && prob(50)))
			qdel(src)
		else
			burst()

/obj/item/latexballon/bullet_act()
	burst()

/obj/item/latexballon/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(exposed_temperature > T0C+100)
		burst()
	return ..()

/obj/item/latexballon/attackby(obj/item/used_item, mob/user)
	if (used_item.can_puncture())
		burst()
		return TRUE
	return FALSE
