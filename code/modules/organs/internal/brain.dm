/obj/item/organ/internal/brain
	name = "brain"
	desc = "A piece of juicy meat found in a person's head."
	organ_tag = BP_BRAIN
	parent_organ = BP_HEAD
	icon_state = "brain2"
	w_class = ITEM_SIZE_SMALL
	throw_speed = 3
	throw_range = 5
	origin_tech = @'{"biotech":3}'
	attack_verb = list("attacked", "slapped", "whacked")
	relative_size = 85
	damage_reduction = 0
	scale_max_damage_to_species_health = FALSE
	transfer_brainmob_with_organ = TRUE
	_base_attack_force = 1
	var/can_use_brain_interface = TRUE
	var/should_announce_brain_damage = TRUE
	var/oxygen_reserve = 6
	VAR_PRIVATE/mob/living/_brainmob = /mob/living/brain

/obj/item/organ/internal/brain/get_brainmob(var/create_if_missing = FALSE)
	if(!istype(_brainmob) && create_if_missing)
		initialize_brainmob()
	if(istype(_brainmob))
		return _brainmob

/obj/item/organ/internal/brain/Initialize()
	. = ..()
	if(species)
		set_max_damage(species.total_health)
	else
		set_max_damage(200)

/obj/item/organ/internal/brain/proc/initialize_brainmob()
	if(istype(_brainmob))
		return
	if(!ispath(_brainmob))
		_brainmob = initial(_brainmob)
	if(ispath(_brainmob))
		_brainmob = new _brainmob(src)
	else
		_brainmob = null

/obj/item/organ/internal/brain/getToxLoss()
	return 0

/obj/item/organ/internal/brain/set_species(species_uid)
	. = ..()
	icon_state = "brain-prosthetic"
	if(species)
		set_max_damage(species.total_health)
	else
		set_max_damage(200)

/obj/item/organ/internal/brain/Destroy()
	if(istype(_brainmob))
		QDEL_NULL(_brainmob)
	. = ..()

/obj/item/organ/internal/brain/get_examine_strings(mob/user, distance, infix, suffix)
	. = ..()
	if(distance <= 1)
		var/brain_status = get_brain_status(user)
		if(brain_status)
			. += brain_status

/obj/item/organ/internal/brain/proc/get_brain_status(mob/user)
	. = list()
	if(istype(_brainmob) && _brainmob?.client) //if thar be a brain inside... the brain.
		. += "You can feel the small spark of life still left in this one."
	else
		. += "This one seems particularly lifeless. Perhaps it will regain some of its luster later."

/obj/item/organ/internal/brain/do_install(mob/living/target, affected, in_place, update_icon, detached)
	if(!(. = ..()))
		return
	if(istype(owner))
		SetName(initial(name)) //Reset the organ's name to stay coherent if we're putting it back into someone's skull

/obj/item/organ/internal/brain/do_uninstall(in_place, detach, ignore_children, update_icon)
	if(!in_place && istype(owner) && name == initial(name))
		SetName("\the [owner.real_name]'s [initial(name)]")
	if(!(. = ..()))
		return

/obj/item/organ/internal/brain/can_recover()
	return !(status & ORGAN_DEAD)

/obj/item/organ/internal/brain/proc/handle_severe_damage()
	set waitfor = FALSE
	should_announce_brain_damage = FALSE
	to_chat(owner, "<span class = 'notice' font size='10'><B>Where am I...?</B></span>")
	sleep(5 SECONDS)
	if(!owner)
		return
	to_chat(owner, "<span class = 'notice' font size='10'><B>What's going on...?</B></span>")
	sleep(10 SECONDS)
	if(!owner)
		return
	to_chat(owner, "<span class = 'notice' font size='10'><B>What happened...?</B></span>")
	alert(owner, "You have taken massive brain damage! You will not be able to remember the events leading up to your injury.", "Brain Damaged")

/obj/item/organ/internal/brain/organ_can_heal()
	return (_organ_damage && owner && GET_CHEMICAL_EFFECT(owner, CE_BRAIN_REGEN) > 0) || ..()

/obj/item/organ/internal/brain/has_limited_healing()
	return (!owner || GET_CHEMICAL_EFFECT(owner, CE_BRAIN_REGEN) <= 0) && ..()

/obj/item/organ/internal/brain/get_organ_heal_amount()
	if(!has_limited_healing())
		. = 1 // We have full healing, so we always heal at least 1 unit of damage.
	. += (owner ? GET_CHEMICAL_EFFECT(owner, CE_BRAIN_REGEN) : 0)

/obj/item/organ/internal/brain/Process()
	if(owner)

		if(_organ_damage < (max_damage / 4))
			should_announce_brain_damage = TRUE

		handle_disabilities()

		// Brain damage from low oxygenation or lack of blood.
		if(owner.should_have_organ(BP_HEART))

			// No heart? You are going to have a very bad time. Not 100% lethal because heart transplants should be a thing.
			var/blood_volume = owner.get_blood_oxygenation()
			if(blood_volume < BLOOD_VOLUME_SURVIVE)
				if(!owner.has_chemical_effect(CE_STABLE, 1) || prob(60))
					oxygen_reserve = max(0, oxygen_reserve-1)
			else
				oxygen_reserve = min(initial(oxygen_reserve), oxygen_reserve+1)
			if(!oxygen_reserve) //(hardcrit)
				SET_STATUS_MAX(owner, STAT_PARA, 3)

			//Effects of bloodloss
			if(blood_volume < BLOOD_VOLUME_SAFE)
				var/damprob
				var/stability_effect = GET_CHEMICAL_EFFECT(owner, CE_STABLE)
				switch(blood_volume)
					if(BLOOD_VOLUME_OKAY to BLOOD_VOLUME_SAFE)
						if(prob(1))
							to_chat(owner, "<span class='warning'>You feel [pick("dizzy","woozy","faint")]...</span>")
						damprob = stability_effect ? 30 : 60
						if(!past_damage_threshold(2) && prob(damprob))
							take_damage(1)
					if(BLOOD_VOLUME_BAD to BLOOD_VOLUME_OKAY)
						SET_STATUS_MAX(owner, STAT_BLURRY, 6)
						damprob = stability_effect ? 40 : 80
						if(!past_damage_threshold(4) && prob(damprob))
							take_damage(1)
						if(!HAS_STATUS(owner, STAT_PARA) && prob(10))
							SET_STATUS_MAX(owner, STAT_PARA, rand(1,3))
							to_chat(owner, "<span class='warning'>You feel extremely [pick("dizzy","woozy","faint")]...</span>")
					if(BLOOD_VOLUME_SURVIVE to BLOOD_VOLUME_BAD)
						SET_STATUS_MAX(owner, STAT_BLURRY, 6)
						damprob = stability_effect ? 60 : 100
						if(!past_damage_threshold(6) && prob(damprob))
							take_damage(1)
						if(!HAS_STATUS(owner, STAT_PARA) && prob(15))
							SET_STATUS_MAX(owner, STAT_PARA, rand(3,5))
							to_chat(owner, "<span class='warning'>You feel extremely [pick("dizzy","woozy","faint")]...</span>")
					if(-(INFINITY) to BLOOD_VOLUME_SURVIVE) // Also see heart.dm, being below this point puts you into cardiac arrest.
						SET_STATUS_MAX(owner, STAT_BLURRY, 6)
						damprob = stability_effect ? 80 : 100
						if(prob(damprob))
							take_damage(1)
						if(prob(damprob))
							take_damage(1)
	..()

/obj/item/organ/internal/brain/take_damage(damage, damage_type = BRUTE, damage_flags, inflicter, armor_pen = 0, silent, do_update_health)
	. = ..()
	if(owner && damage >= 10) //This probably won't be triggered by oxyloss or mercury. Probably.
		var/damage_secondary = damage * 0.20
		owner.flash_eyes()
		SET_STATUS_MAX(owner, STAT_BLURRY, damage_secondary)
		SET_STATUS_MAX(owner, STAT_CONFUSE, damage_secondary * 2)
		SET_STATUS_MAX(owner, STAT_PARA, damage_secondary)
		SET_STATUS_MAX(owner, STAT_WEAK, round(damage, 1))
		if(prob(30))
			addtimer(CALLBACK(src, PROC_REF(brain_damage_callback), damage), rand(6, 20) SECONDS, TIMER_UNIQUE)

/obj/item/organ/internal/brain/proc/brain_damage_callback(var/damage) //Confuse them as a somewhat uncommon aftershock. Side note: Only here so a spawn isn't used. Also, for the sake of a unique timer.
	if(!QDELETED(owner))
		to_chat(owner, SPAN_NOTICE(FONT_HUGE("<B>I can't remember which way is forward...</B>")))
		ADJ_STATUS(owner, STAT_CONFUSE, damage)

/obj/item/organ/internal/brain/proc/handle_disabilities()
	if(owner.stat)
		return
	if(owner.has_genetic_condition(GENE_COND_EPILEPSY) && prob(1))
		owner.seizure()
	else if(owner.has_genetic_condition(GENE_COND_TOURETTES) && prob(10))
		SET_STATUS_MAX(owner, STAT_STUN, 10)
		switch(rand(1, 3))
			if(1)
				owner.emote(/decl/emote/visible/twitch)
			if(2 to 3)
				owner.say("[prob(50) ? ";" : ""][pick("SHIT", "PISS", "FUCK", "CUNT", "COCKSUCKER", "MOTHERFUCKER", "TITS")]")
		ADJ_STATUS(owner, STAT_JITTER, 100)
	else if(owner.has_genetic_condition(GENE_COND_NERVOUS) && prob(10))
		SET_STATUS_MAX(owner, STAT_STUTTER, 10)


/obj/item/organ/internal/brain/handle_damage_effects()
	..()

	if(_organ_damage >= round(max_damage / 2) && should_announce_brain_damage)
		handle_severe_damage()

	if(!BP_IS_PROSTHETIC(src) && prob(1))
		owner.custom_pain("Your head feels numb and painful.",10)
	if(is_bruised() && prob(1) && !HAS_STATUS(owner, STAT_BLURRY))
		to_chat(owner, "<span class='warning'>It becomes hard to see for some reason.</span>")
		owner.set_status_condition(STAT_BLURRY, 10)
	var/held = owner.get_active_held_item()
	if(_organ_damage >= 0.5*max_damage && prob(1) && held)
		to_chat(owner, "<span class='danger'>Your hand won't respond properly, and you drop what you are holding!</span>")
		owner.try_unequip(held)
	if(_organ_damage >= 0.6*max_damage)
		SET_STATUS_MAX(owner, STAT_SLUR, 2)
	if(is_broken())
		if(!owner.current_posture.prone)
			to_chat(owner, "<span class='danger'>You black out!</span>")
		SET_STATUS_MAX(owner, STAT_PARA, 10)

/obj/item/organ/internal/brain/surgical_fix(mob/user)
	var/blood_volume = owner.get_blood_oxygenation()
	if(blood_volume < BLOOD_VOLUME_SURVIVE)
		to_chat(user, SPAN_DANGER("Parts of \the [src] didn't survive the procedure due to lack of air supply!"))
		set_max_damage(floor(max_damage - 0.25*_organ_damage))
	heal_damage(_organ_damage)

/obj/item/organ/internal/brain/die()
	if(istype(_brainmob) && _brainmob.stat != DEAD)
		_brainmob.death()
	..()
