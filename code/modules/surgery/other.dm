//Procedures in this file: Internal wound patching, Implant removal.
//////////////////////////////////////////////////////////////////
//					INTERNAL WOUND PATCHING						//
//////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////
//	 Tendon fix surgery step
//////////////////////////////////////////////////////////////////
/decl/surgery_step/fix_tendon
	name = "Repair tendon"
	description = "This procedure repairs damage to a tendon."
	allowed_tools = list(
		TOOL_SUTURES =  100,
		TOOL_CABLECOIL = 75
	)
	can_infect = 1
	blood_level = 1
	min_duration = 70
	max_duration = 90
	shock_level = 40
	delicate = 1
	surgery_candidate_flags = SURGERY_NO_CRYSTAL | SURGERY_NO_ROBOTIC | SURGERY_NEEDS_RETRACTED

/decl/surgery_step/fix_tendon/assess_bodypart(mob/living/user, mob/living/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = ..()
	if(affected && (affected.status & ORGAN_TENDON_CUT))
		return affected

/decl/surgery_step/fix_tendon/begin_step(mob/user, mob/living/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = GET_EXTERNAL_ORGAN(target, target_zone)
	user.visible_message("[user] starts reattaching the damaged [affected.tendon_name] in [target]'s [affected.name] with \the [tool]." , \
	"You start reattaching the damaged [affected.tendon_name] in [target]'s [affected.name] with \the [tool].")
	target.custom_pain("The pain in your [affected.name] is unbearable!",100,affecting = affected)
	..()

/decl/surgery_step/fix_tendon/end_step(mob/living/user, mob/living/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = GET_EXTERNAL_ORGAN(target, target_zone)
	user.visible_message("<span class='notice'>[user] has reattached the [affected.tendon_name] in [target]'s [affected.name] with \the [tool].</span>", \
		"<span class='notice'>You have reattached the [affected.tendon_name] in [target]'s [affected.name] with \the [tool].</span>")
	affected.status &= ~ORGAN_TENDON_CUT
	affected.update_damages()
	..()

/decl/surgery_step/fix_tendon/fail_step(mob/living/user, mob/living/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = GET_EXTERNAL_ORGAN(target, target_zone)
	user.visible_message("<span class='warning'>[user]'s hand slips, smearing [tool] in the incision in [target]'s [affected.name]!</span>" , \
	"<span class='warning'>Your hand slips, smearing [tool] in the incision in [target]'s [affected.name]!</span>")
	affected.take_damage(5, inflicter = tool)
	..()

//////////////////////////////////////////////////////////////////
//	 IB fix surgery step
//////////////////////////////////////////////////////////////////
/decl/surgery_step/fix_vein
	name = "Repair arterial bleeding"
	description = "This procedure repairs damage to an artery."
	allowed_tools = list(
		TOOL_SUTURES =  100,
		TOOL_CABLECOIL = 75
	)
	can_infect = 1
	blood_level = 1
	min_duration = 70
	max_duration = 90
	shock_level = 40
	delicate = 1
	strict_access_requirement = FALSE
	surgery_candidate_flags = SURGERY_NO_CRYSTAL | SURGERY_NO_ROBOTIC | SURGERY_NEEDS_RETRACTED

/decl/surgery_step/fix_vein/assess_bodypart(mob/living/user, mob/living/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = ..()
	if(affected && (affected.status & ORGAN_ARTERY_CUT))
		return affected

/decl/surgery_step/fix_vein/begin_step(mob/user, mob/living/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = GET_EXTERNAL_ORGAN(target, target_zone)
	user.visible_message("[user] starts patching the damaged [affected.artery_name] in [target]'s [affected.name] with \the [tool]." , \
	"You start patching the damaged [affected.artery_name] in [target]'s [affected.name] with \the [tool].")
	target.custom_pain("The pain in your [affected.name] is unbearable!",100,affecting = affected)
	..()

/decl/surgery_step/fix_vein/end_step(mob/living/user, mob/living/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = GET_EXTERNAL_ORGAN(target, target_zone)
	user.visible_message("<span class='notice'>[user] has patched the [affected.artery_name] in [target]'s [affected.name] with \the [tool].</span>", \
		"<span class='notice'>You have patched the [affected.artery_name] in [target]'s [affected.name] with \the [tool].</span>")
	affected.status &= ~ORGAN_ARTERY_CUT
	affected.update_damages()
	..()

/decl/surgery_step/fix_vein/fail_step(mob/living/user, mob/living/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = GET_EXTERNAL_ORGAN(target, target_zone)
	user.visible_message("<span class='warning'>[user]'s hand slips, smearing [tool] in the incision in [target]'s [affected.name]!</span>" , \
	"<span class='warning'>Your hand slips, smearing [tool] in the incision in [target]'s [affected.name]!</span>")
	affected.take_damage(5, inflicter = tool)
	..()


//////////////////////////////////////////////////////////////////
//	 Hardsuit removal surgery step
//////////////////////////////////////////////////////////////////
/decl/surgery_step/hardsuit
	name = "Remove hardsuit"
	description = "This procedure cuts through the bolts on a hardsuit, allowing it to be removed."
	allowed_tools = list(
		TOOL_WELDER = 80,
		TOOL_SAW =    60
	)
	can_infect = 0
	blood_level = 0
	min_duration = 120
	max_duration = 180
	surgery_candidate_flags = 0
	hidden_from_codex = TRUE

/decl/surgery_step/hardsuit/assess_bodypart(mob/living/user, mob/living/target, target_zone, obj/item/tool)
	return TRUE

/decl/surgery_step/hardsuit/get_skill_reqs(mob/living/user, mob/living/target, obj/item/tool)
	return list(SKILL_EVA = SKILL_BASIC)

/decl/surgery_step/hardsuit/can_use(mob/living/user, mob/living/target, target_zone, obj/item/tool)
	if(!istype(target))
		return FALSE
	if(IS_WELDER(tool))
		var/obj/item/weldingtool/welder = tool
		if(!welder.isOn() || !welder.weld(1,user))
			return FALSE
	var/obj/item/rig/rig = target.get_rig()
	return (target_zone == BP_CHEST) && rig && !(rig.canremove)

/decl/surgery_step/hardsuit/begin_step(mob/user, mob/living/target, target_zone, obj/item/tool)
	var/obj/item/rig/rig = target.get_rig()
	user.visible_message("[user] starts cutting through the support systems of [target]'s [rig] with \the [tool]." , \
	"You start cutting through the support systems of [target]'s [rig] with \the [tool].")
	..()

/decl/surgery_step/hardsuit/end_step(mob/living/user, mob/living/target, target_zone, obj/item/tool)

	var/obj/item/rig/rig = target.get_rig()
	if(rig)
		rig.reset()
	user.visible_message("<span class='notice'>[user] has cut through the support systems of [target]'s [rig] with \the [tool].</span>", \
		"<span class='notice'>You have cut through the support systems of [target]'s [rig] with \the [tool].</span>")
	..()

/decl/surgery_step/hardsuit/fail_step(mob/living/user, mob/living/target, target_zone, obj/item/tool)
	user.visible_message("<span class='danger'>[user]'s [tool] can't quite seem to get through the metal...</span>", \
	"<span class='danger'>Your [tool] can't quite seem to get through the metal. It's weakening, though - try again.</span>")
	..()


//////////////////////////////////////////////////////////////////
//	 Disinfection step
//////////////////////////////////////////////////////////////////
/decl/surgery_step/sterilize
	name = "Sterilize wound"
	description = "This procedure sterilizes a wound with antiseptic substances such as alcohol or raw honey."
	allowed_tools = list(
		/obj/item/chems/spray = 100,
		/obj/item/chems/dropper = 100,
		/obj/item/chems/glass/bottle = 90,
		/obj/item/chems/drinks/flask = 90,
		/obj/item/chems/glass/beaker = 75,
		/obj/item/chems/drinks/bottle = 75,
		/obj/item/chems/drinks/glass2 = 75,
		/obj/item/chems/glass/bucket = 50
	)
	var/list/skip_open_container_checks = list(
		/obj/item/chems/spray,
		/obj/item/chems/dropper
	)
	var/list/sterilizing_reagents = list(
		/decl/material/liquid/nutriment/honey,
		/decl/material/liquid/antiseptic
	)

	can_infect = 0
	blood_level = 0
	min_duration = 50
	max_duration = 60

/decl/surgery_step/sterilize/Initialize()
	. = ..()
	for(var/decl/material/liquid/alcohol/booze in decls_repository.get_decls_of_subtype_unassociated(/decl/material/liquid/alcohol))
		if(booze.strength <= 40)
			sterilizing_reagents |= booze.type

/decl/surgery_step/sterilize/assess_bodypart(mob/living/user, mob/living/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = ..()
	if(affected && !affected.is_disinfected() && check_chemicals(tool))
		return affected

/decl/surgery_step/sterilize/get_skill_reqs(mob/living/user, mob/living/target, obj/item/tool)
	return list(SKILL_MEDICAL = SKILL_BASIC)

/decl/surgery_step/sterilize/begin_step(mob/user, mob/living/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = GET_EXTERNAL_ORGAN(target, target_zone)
	user.visible_message("[user] starts pouring [tool]'s contents on \the [target]'s [affected.name]." , \
	"You start pouring [tool]'s contents on \the [target]'s [affected.name].")
	target.custom_pain("Your [affected.name] is on fire!",50,affecting = affected)
	..()

/decl/surgery_step/sterilize/end_step(mob/living/user, mob/living/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = GET_EXTERNAL_ORGAN(target, target_zone)
	var/obj/item/chems/container = tool
	var/amount = container.amount_per_transfer_from_this
	var/temp_holder = new/obj()
	var/datum/reagents/temp_reagents = new(amount, temp_holder)
	container.reagents.trans_to_holder(temp_reagents, amount)
	var/trans = temp_reagents.trans_to_mob(target, temp_reagents.total_volume, CHEM_INJECT) //technically it's contact, but the reagents are being applied to internal tissue
	if (trans > 0)
		user.visible_message("<span class='notice'>[user] rubs [target]'s [affected.name] down with \the [tool]'s contents</span>.", \
			"<span class='notice'>You rub [target]'s [affected.name] down with \the [tool]'s contents.</span>")
	affected.disinfect()
	qdel(temp_reagents)
	qdel(temp_holder)
	..()

/decl/surgery_step/sterilize/fail_step(mob/living/user, mob/living/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = GET_EXTERNAL_ORGAN(target, target_zone)
	var/obj/item/chems/container = tool
	container.reagents.trans_to_mob(target, container.amount_per_transfer_from_this, CHEM_INJECT)
	user.visible_message("<span class='warning'>[user]'s hand slips, spilling \the [tool]'s contents over the [target]'s [affected.name]!</span>" , \
	"<span class='warning'>Your hand slips, spilling \the [tool]'s contents over the [target]'s [affected.name]!</span>")
	affected.disinfect()
	..()

/decl/surgery_step/sterilize/proc/check_chemicals(var/obj/item/chems/container)

	if(!istype(container) || QDELETED(container))
		return FALSE

	var/valid_container = ATOM_IS_OPEN_CONTAINER(container)
	if(!valid_container)
		for(var/check_type in skip_open_container_checks)
			if(istype(container, check_type))
				valid_container = TRUE
				break

	if(!valid_container)
		return FALSE

	if(!container.reagents?.total_volume)
		return FALSE

	// This check means it's impure.
	if(length(container.reagents.reagent_volumes) > length(sterilizing_reagents))
		return FALSE

	// Check if we have sterilizing reagents and -only- sterilizing reagents.
	for(var/decl/material/reagent as anything in container.reagents.reagent_volumes)
		if(!(reagent in sterilizing_reagents))
			return FALSE
		. = TRUE
