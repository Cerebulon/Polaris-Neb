// Holographic Items!

// Holographic tables are in code/modules/tables/presets.dm
// Holographic racks are in code/modules/tables/rack.dm

/turf/floor/holofloor
	thermal_conductivity = 0

/turf/floor/holofloor/get_lumcount(var/minlum = 0, var/maxlum = 1)
	return 0.8

/turf/floor/holofloor/attackby(obj/item/used_item, mob/user)
	return TRUE
	// HOLOFLOOR DOES NOT GIVE A FUCK

/turf/floor/holofloor/carpet
	name          = "brown carpet"
	icon          = 'icons/turf/flooring/carpet.dmi'
	icon_state    = "brown"
	_flooring     = /decl/flooring/carpet

/turf/floor/holofloor/concrete
	name          = "brown carpet"
	icon          = 'icons/turf/flooring/carpet.dmi'
	icon_state    = "brown"
	_flooring     = /decl/flooring/carpet

/turf/floor/holofloor/concrete
	name          = "floor"
	icon          = 'icons/turf/flooring/misc.dmi'
	icon_state    = "concrete"
	_flooring     = null

/turf/floor/holofloor/tiled
	name          = "floor"
	icon          = 'icons/turf/flooring/tiles.dmi'
	icon_state    = "steel"
	_flooring     = /decl/flooring/tiling

/turf/floor/holofloor/tiled/dark
	name          = "dark floor"
	icon_state    = "dark"
	_flooring     = /decl/flooring/tiling/dark

/turf/floor/holofloor/tiled/stone
	name          = "stone floor"
	icon_state    = "stone"
	_flooring     = /decl/flooring/tiling/stone

/turf/floor/holofloor/lino
	name          = "lino"
	icon          = 'icons/turf/flooring/linoleum.dmi'
	icon_state    = "lino"
	_flooring     = /decl/flooring/linoleum

/turf/floor/holofloor/wood
	name          = "wooden floor"
	icon          = 'icons/turf/flooring/wood.dmi'
	icon_state    = "wood0"
	color         = WOOD_COLOR_CHOCOLATE
	_flooring     = /decl/flooring/wood

/turf/floor/holofloor/grass
	name          = "lush grass"
	icon          = 'icons/turf/flooring/fakegrass.dmi'
	icon_state    = "grass0"
	_flooring     = /decl/flooring/grass/fake

/turf/floor/holofloor/snow
	name          = "snow"
	icon          = 'icons/turf/flooring/snow.dmi'
	icon_state    = "snow0"
	_flooring     = /decl/flooring/snow/fake

/turf/floor/holofloor/space
	name          = "\proper space"
	icon          = 'icons/turf/flooring/fake_space.dmi'
	icon_state    = "space0"
	_flooring     = /decl/flooring/fake_space

/turf/floor/holofloor/reinforced
	name          = "reinforced holofloor"
	icon          = 'icons/turf/flooring/tiles.dmi'
	_flooring     = /decl/flooring/reinforced
	icon_state    = "reinforced"

/turf/floor/holofloor/beach
	desc          = "Uncomfortably gritty for a hologram."
	icon          = 'icons/misc/beach.dmi'
	_flooring     = /decl/flooring/sand/fake
	abstract_type = /turf/floor/holofloor/beach

/turf/floor/holofloor/beach/sand
	name          = "sand"
	icon_state    = "desert0"

/turf/floor/holofloor/beach/coastline
	name          = "coastline"
	icon          = 'icons/misc/beach2.dmi'
	icon_state    = "sandwater"
	_flooring     = /decl/flooring/sand/fake

/turf/floor/holofloor/beach/water
	name          = "water"
	icon_state    = "seashallow"
	_flooring     = /decl/flooring/fake_water

/turf/floor/holofloor/desert
	name          = "desert sand"
	desc          = "Uncomfortably gritty for a hologram."
	icon          = 'icons/turf/flooring/barren.dmi'
	icon_state    = "barren"
	_flooring     = /decl/flooring/sand/fake

/turf/floor/holofloor/desert/Initialize(var/ml)
	. = ..()
	if(prob(10))
		LAZYADD(decals, image('icons/turf/flooring/decals.dmi', "asteroid[rand(0,9)]"))

/obj/structure/holostool
	name          = "stool"
	desc          = "Apply butt."
	icon          = 'icons/obj/furniture.dmi'
	icon_state    = "stool_padded_preview"
	anchored      = TRUE

/obj/item/clothing/gloves/boxing/hologlove
	name          = "boxing gloves"
	desc          = "Because you really needed another excuse to punch your crewmates."

/obj/structure/window/reinforced/holowindow/full
	dir           = NORTHEAST
	icon_state    = "rwindow_full"

/obj/structure/window/reinforced/holowindow/attackby(obj/item/used_item, mob/user)
	if(IS_SCREWDRIVER(used_item) || IS_CROWBAR(used_item) || IS_WRENCH(used_item))
		to_chat(user, SPAN_NOTICE("It's a holowindow, you can't dismantle it!"))
		return TRUE
	return bash(used_item, user)

/obj/structure/window/reinforced/holowindow/shatter(var/display_message = 1)
	playsound(src, "shatter", 70, 1)
	if(display_message)
		visible_message("[src] fades away as it shatters!")
	qdel(src)
	return

// This subtype is deleted when a ready button in the same area is pressed.
/obj/structure/window/reinforced/holowindow/disappearing

/obj/machinery/door/window/holowindoor/attackby(obj/item/used_item, mob/user)

	if (src.operating == 1)
		return TRUE

	if(src.density && istype(used_item, /obj/item) && !istype(used_item, /obj/item/card))
		playsound(src.loc, 'sound/effects/Glasshit.ogg', 75, 1)
		visible_message("<span class='danger'>\The [src] was hit by \the [used_item].</span>")
		if(used_item.atom_damage_type == BRUTE || used_item.atom_damage_type == BURN)
			take_damage(used_item.expend_attack_force(user))
		return TRUE

	src.add_fingerprint(user)
	if (src.allowed(user))
		if (src.density)
			open()
		else
			close()
		return TRUE

	else if (src.density)
		flick("[base_state]deny", src)
		return TRUE
	return FALSE

/obj/machinery/door/window/holowindoor/shatter(var/display_message = TRUE)
	set_density(FALSE)
	playsound(loc, "shatter", 70, TRUE)
	if(display_message)
		visible_message("[src] fades away as it shatters!")
	animate(src, 0.5 SECONDS, alpha = 0)
	QDEL_IN_CLIENT_TIME(src, 0.5 SECONDS)

/obj/structure/bed/holobed
	tool_interaction_flags = 0
	holographic = TRUE
	material = /decl/material/solid/metal/aluminium/holographic

/obj/structure/chair/holochair
	tool_interaction_flags = 0
	holographic = TRUE
	material = /decl/material/solid/metal/aluminium/holographic

/obj/item/holo
	atom_damage_type =  PAIN
	no_attack_log = 1
	max_health = ITEM_HEALTH_NO_DAMAGE

/obj/item/holo/esword
	name = "holosword"
	desc = "May the force be within you. Sorta."
	icon = 'icons/obj/items/weapon/e_sword.dmi'
	icon_state = "sword0"
	throw_speed = 1
	throw_range = 5
	w_class = ITEM_SIZE_SMALL
	atom_flags = ATOM_FLAG_NO_BLOOD
	base_parry_chance = 50
	_base_attack_force = 3
	var/active = 0
	var/item_color

/obj/item/holo/esword/green
	item_color = "green"

/obj/item/holo/esword/red
	item_color = "red"

/obj/item/holo/esword/handle_shield(mob/user, var/damage, atom/damage_source = null, mob/attacker = null, var/def_zone = null, var/attack_text = "the attack")
	. = ..()
	if(.)
		spark_at(user.loc, amount=5)
		playsound(user.loc, 'sound/weapons/blade1.ogg', 50, 1)

/obj/item/holo/esword/get_parry_chance(mob/user)
	return active ? ..() : 0

/obj/item/holo/esword/Initialize()
	. = ..()
	item_color = pick("red","blue","green","purple")

/obj/item/holo/esword/attack_self(mob/user)
	active = !active
	if (active)
		set_base_attack_force(30)
		icon_state = "sword[item_color]"
		w_class = ITEM_SIZE_HUGE
		playsound(user, 'sound/weapons/saberon.ogg', 50, 1)
		to_chat(user, "<span class='notice'>[src] is now active.</span>")
	else
		set_base_attack_force(3)
		icon_state = "sword0"
		w_class = ITEM_SIZE_SMALL
		playsound(user, 'sound/weapons/saberoff.ogg', 50, 1)
		to_chat(user, "<span class='notice'>[src] can now be concealed.</span>")

	update_held_icon()

	add_fingerprint(user)
	return

//BASKETBALL OBJECTS
/obj/structure/holohoop
	name = "basketball hoop"
	desc = "Boom, Shakalaka!"
	icon = 'icons/obj/structures/basketball.dmi'
	icon_state = "hoop"
	anchored = TRUE
	density = TRUE
	throwpass = 1

/obj/structure/holohoop/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if (istype(mover,/obj/item) && mover.throwing)
		var/obj/item/thing = mover
		if(istype(thing, /obj/item/projectile))
			return
		if(prob(50))
			thing.dropInto(loc)
			visible_message("<span class='notice'>Swish! \the [thing] lands in \the [src].</span>", range = 3)
		else
			visible_message("<span class='warning'>\The [thing] bounces off of \the [src]'s rim!</span>", range = 3)
		return 0
	else
		return ..(mover, target, height, air_group)

//VOLEYBALL OBJECTS
/obj/structure/holonet
	name = "net"
	desc = "Bullshit, you can be mine!"
	icon = 'icons/obj/structures/volleyball.dmi'
	icon_state = "volleynet_mid"
	density = TRUE
	anchored = TRUE
	layer = TABLE_LAYER
	throwpass = 1
	dir = EAST

/obj/structure/holonet/end
	icon_state = "volleynet_end"

/obj/structure/holonet/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if (istype(mover,/obj/item) && mover.throwing)
		var/obj/item/thing = mover
		if(istype(thing, /obj/item/projectile))
			return
		if(prob(10))
			thing.dropInto(loc)
			visible_message("<span class='notice'>Swish! \the [thing] gets caught in \the [src].</span>", range = 3)
			return 0
		else
			return 1
	else
		return ..(mover, target, height, air_group)

/obj/machinery/readybutton
	name = "Ready Declaration Device"
	desc = "This device is used to declare ready. If all devices in an area are ready, the event will begin!"
	icon = 'icons/obj/monitors.dmi'
	icon_state = "auth_off"
	var/ready = 0
	var/area/currentarea = null
	var/eventstarted = 0

	anchored = TRUE
	idle_power_usage = 2
	active_power_usage = 6
	power_channel = ENVIRON

/obj/machinery/readybutton/attack_ai(mob/living/silicon/ai/user)
	to_chat(user, "The AI is not to interact with these devices!")
	return

/obj/machinery/readybutton/attackby(obj/item/used_item, mob/user)
	to_chat(user, "The device is a solid button, there's nothing you can do with it!")
	return TRUE

/obj/machinery/readybutton/physical_attack_hand(mob/user)
	currentarea = get_area(src)
	if(!currentarea)
		qdel(src)
		return TRUE

	if(eventstarted)
		to_chat(user, "The event has already begun!")
		return TRUE

	ready = !ready

	update_icon()

	var/numbuttons = 0
	var/numready = 0
	for(var/obj/machinery/readybutton/button in currentarea)
		numbuttons++
		if (button.ready)
			numready++

	if(numbuttons == numready)
		begin_event()
	return TRUE

/obj/machinery/readybutton/on_update_icon()
	if(ready)
		icon_state = "auth_on"
	else
		icon_state = "auth_off"

/obj/machinery/readybutton/proc/begin_event()

	eventstarted = 1

	for(var/obj/structure/window/reinforced/holowindow/disappearing/window in currentarea)
		qdel(window)

	for(var/mob/M in currentarea)
		to_chat(M, "FIGHT!")

//Holocarp

/mob/living/simple_animal/hostile/carp/holodeck
	icon = 'icons/mob/simple_animal/holocarp.dmi'
	alpha = 127
	butchery_data = null

/mob/living/simple_animal/hostile/carp/holodeck/carp_randomify()
	return

/mob/living/simple_animal/hostile/carp/holodeck/on_update_icon()
	SHOULD_CALL_PARENT(FALSE)
	return

/mob/living/simple_animal/hostile/carp/holodeck/Initialize()
	. = ..()
	set_light(2) //hologram lighting

/mob/living/simple_animal/hostile/carp/holodeck/proc/set_safety(var/safe)
	if (safe)
		faction = MOB_FACTION_NEUTRAL
		natural_weapon.set_base_attack_force(0)
		environment_smash = 0
		ai?.try_destroy_surroundings = FALSE
	else
		faction = "carp"
		natural_weapon.set_base_attack_force(natural_weapon.get_initial_base_attack_force())

/mob/living/simple_animal/hostile/carp/holodeck/gib(do_gibs = TRUE)
	SHOULD_CALL_PARENT(FALSE)
	if(stat != DEAD)
		death(gibbed = TRUE)
	if(stat == DEAD)
		qdel(src)
		return TRUE
	return FALSE

/mob/living/simple_animal/hostile/carp/holodeck/get_death_message(gibbed)
	return "fades away..."

/mob/living/simple_animal/hostile/carp/holodeck/get_self_death_message(gibbed)
	return "You have been destroyed."

/mob/living/simple_animal/hostile/carp/holodeck/death(gibbed)
	. = ..()
	if(. && !gibbed)
		gib()
