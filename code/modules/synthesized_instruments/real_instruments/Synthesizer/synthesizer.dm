//Synthesizer and minimoog. They work the same

/datum/sound_player/synthesizer
	volume = 40

/obj/structure/synthesized_instrument/synthesizer
	name = "The Synthesizer 3.0"
	desc = "This thing emits shockwaves as it plays. This is not good for your hearing."
	icon_state = "synthesizer"
	anchored = TRUE
	density = TRUE
	path = /datum/instrument
	sound_player = /datum/sound_player/synthesizer

/obj/structure/synthesized_instrument/synthesizer/attackby(obj/item/used_item, mob/user, params)
	if (IS_WRENCH(used_item))
		if (!anchored && !isspaceturf(get_turf(src)))
			playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
			to_chat(user, "<span class='notice'>You begin to tighten \the [src] to the floor...</span>")
			if (do_after(user, 2 SECONDS))
				if(!anchored && !isspaceturf(get_turf(src)))
					user.visible_message( \
						"[user] tightens \the [src]'s casters.", \
						"<span class='notice'>You tighten \the [src]'s casters. Now it can be played again.</span>", \
						"<span class='italics'>You hear a ratchet.</span>")
					src.anchored = TRUE
		else if(anchored)
			playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
			to_chat(user, "<span class='notice'>You begin to loosen \the [src]'s casters...</span>")
			if (do_after(user, 4 SECONDS))
				if(anchored)
					user.visible_message( \
						"[user] loosens \the [src]'s casters.", \
						"<span class='notice'>You loosen \the [src]. Now it can be pulled somewhere else.</span>", \
						"<span class='italics'>You hear a ratchet.</span>")
					src.anchored = FALSE
			return TRUE
		// we failed to do anything because we were unanchored in space, fall through to parent and smack it?
	return ..()

/obj/structure/synthesized_instrument/synthesizer/shouldStopPlaying(mob/user)
	return !((src && in_range(src, user) && src.anchored) || src.real_instrument.player.song.autorepeat)


//in-hand version
/obj/item/synthesized_instrument/synthesizer
	name = "Synthesizer Mini"
	desc = "The power of an entire orchestra in a handy midi keyboard format."
	icon_state = "h_synthesizer"
	path = /datum/instrument
	sound_player = /datum/sound_player/synthesizer

/obj/structure/synthesized_instrument/synthesizer/minimoog
	name = "space minimoog"
	desc = "This is a minimoog, like a space piano, but more spacey!"
	icon_state = "minimoog"
