// Stolen en masse from N3X15 of /vg/station with much gratitude.

// The idea is to have 4 bits for coming and 4 for going.
#define TRACKS_COMING_NORTH 1
#define TRACKS_COMING_SOUTH 2
#define TRACKS_COMING_EAST  4
#define TRACKS_COMING_WEST  8
#define TRACKS_GOING_NORTH  16
#define TRACKS_GOING_SOUTH  32
#define TRACKS_GOING_EAST   64
#define TRACKS_GOING_WEST   128

#define TRACKS_CRUSTIFY_TIME   5 SECONDS

/datum/fluidtrack
	var/direction=0
	var/basecolor=COLOR_BLOOD_HUMAN
	var/wet=0
	var/fresh=1
	var/image/overlay

/datum/fluidtrack/New(_direction,_color,_wet)
	src.direction=_direction
	src.basecolor=_color
	src.wet=_wet

/obj/effect/decal/cleanable/blood/tracks/reveal_blood()
	// don't reveal non-blood tracks
	if(ispath(chemical, /decl/material/liquid/blood) && !fluorescent)
		if(stack && stack.len)
			for(var/datum/fluidtrack/track in stack)
				track.basecolor = COLOR_LUMINOL
		..()

// Footprints, tire trails...
/obj/effect/decal/cleanable/blood/tracks
	amount = 0
	random_icon_states = null
	icon = 'icons/effects/fluidtracks.dmi'
	cleanable_scent = null

	var/dirs=0
	var/coming_state="blood1"
	var/going_state="blood2"
	var/updatedtracks=0

	// dir = id in stack
	var/list/setdirs=list(
		"1"=0,
		"2"=0,
		"4"=0,
		"8"=0,
		"16"=0,
		"32"=0,
		"64"=0,
		"128"=0
	)

	// List of laid tracks and their colors.
	var/list/datum/fluidtrack/stack=list()

	/**
	* Add tracks to an existing trail.
	*
	* @param DNA bloodDNA to add to collection.
	* @param comingdir Direction tracks come from, or 0.
	* @param goingdir Direction tracks are going to (or 0).
	* @param bloodcolor Color of the blood when wet.
	*/
/obj/effect/decal/cleanable/blood/tracks/proc/AddTracks(var/list/DNA, var/comingdir, var/goingdir, var/bloodcolor=COLOR_BLOOD_HUMAN)

	var/updated=0
	// Shift our goingdir 4 spaces to the left so it's in the GOING bitblock.
	var/realgoing=BITSHIFT_LEFT(goingdir,4)

	// Current bit
	var/b=0

	// When tracks will start to dry out
	var/t=world.time + TRACKS_CRUSTIFY_TIME

	var/datum/fluidtrack/track

	// Process 4 bits
	for(var/bi=0;bi<4;bi++)
		b=BITFLAG(bi)
		// COMING BIT
		// If setting
		if(comingdir&b)
			// If not wet or not set
			if(dirs&b)
				var/sid=setdirs["[b]"]
				track=stack[sid]
				if(track.wet==t && track.basecolor==bloodcolor)
					continue
				// Remove existing stack entry
				stack.Remove(track)
			track=new /datum/fluidtrack(b,bloodcolor,t)
			stack.Add(track)
			setdirs["[b]"]=stack.Find(track)
			updatedtracks |= b
			updated=1

		// GOING BIT (shift up 4)
		b=BITSHIFT_LEFT(b,4)
		if(realgoing&b)
			// If not wet or not set
			if(dirs&b)
				var/sid=setdirs["[b]"]
				track=stack[sid]
				if(track.wet==t && track.basecolor==bloodcolor)
					continue
				// Remove existing stack entry
				stack.Remove(track)
			track=new /datum/fluidtrack(b,bloodcolor,t)
			stack.Add(track)
			setdirs["[b]"]=stack.Find(track)
			updatedtracks |= b
			updated=1

	dirs |= comingdir|realgoing
	if(islist(blood_DNA))
		blood_DNA |= DNA.Copy()
	if(updated)
		update_icon()

/obj/effect/decal/cleanable/blood/tracks/on_update_icon()
	cut_overlays()
	color = "#ffffff"
	var/truedir=0

	// Update ONLY the overlays that have changed.
	for(var/datum/fluidtrack/track in stack)
		var/stack_idx=setdirs["[track.direction]"]
		var/state=coming_state
		truedir=track.direction
		if(truedir&240) // Check if we're in the GOING block
			state=going_state
			truedir=BITSHIFT_RIGHT(truedir,4)

		if(track.overlay)
			track.overlay=null
		var/image/I = image(icon, icon_state=state, dir=FIRST_DIR(truedir))
		I.color = track.basecolor

		track.fresh=0
		track.overlay=I
		stack[stack_idx]=track
		add_overlay(I)
	updatedtracks=0 // Clear our memory of updated tracks.
	compile_overlays()

/obj/effect/decal/cleanable/blood/tracks/footprints
	name = "wet footprints"
	dryname = "dried footprints"
	desc = "They look like still wet tracks left by footwear."
	drydesc = "They look like dried tracks left by footwear."
	coming_state = "human1"
	going_state  = "human2"

/obj/effect/decal/cleanable/blood/tracks/footprints/reversed
	coming_state = "human2"
	going_state = "human1"

/obj/effect/decal/cleanable/blood/tracks/footprints/reversed/AddTracks(var/list/DNA, var/comingdir, var/goingdir, var/bloodcolor=COLOR_BLOOD_HUMAN)
	comingdir = comingdir && global.reverse_dir[comingdir]
	goingdir = goingdir && global.reverse_dir[goingdir]
	..(DNA, comingdir, goingdir, bloodcolor)

/obj/effect/decal/cleanable/blood/tracks/snake
	name = "wet tracks"
	dryname = "dried tracks"
	desc = "They look like still wet tracks left by a giant snake."
	drydesc = "They look like dried tracks left by a giant snake."
	coming_state = "snake1"
	going_state  = "snake2"

/obj/effect/decal/cleanable/blood/tracks/paw
	name = "wet tracks"
	dryname = "dried tracks"
	desc = "They look like still wet tracks left by a mammal."
	drydesc = "They look like dried tracks left by a mammal."
	coming_state = "paw1"
	going_state  = "paw2"

/obj/effect/decal/cleanable/blood/tracks/claw
	name = "wet tracks"
	dryname = "dried tracks"
	desc = "They look like still wet tracks left by a reptile."
	drydesc = "They look like dried tracks left by a reptile."
	coming_state = "claw1"
	going_state  = "claw2"

/obj/effect/decal/cleanable/blood/tracks/wheels
	name = "wet tracks"
	dryname = "dried tracks"
	desc = "They look like still wet tracks left by wheels."
	drydesc = "They look like dried tracks left by wheels."
	coming_state = "wheels"
	going_state  = ""
	gender = PLURAL

/obj/effect/decal/cleanable/blood/tracks/body
	name = "wet trails"
	dryname = "dried trails"
	desc = "A still-wet trail left by someone crawling."
	drydesc = "A dried trail left by someone crawling."
	coming_state = "trail1"
	going_state  = "trail2"
