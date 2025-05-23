/obj/machinery/forensic
	name = "forensic omnianalyzer"
	desc = "A highly advanced microscope capable of analyzing any type of forensic evidence."
	icon = 'icons/obj/forensics.dmi'
	icon_state = "microscope"
	anchored = TRUE
	density = TRUE
	base_type = /obj/machinery/forensic
	construct_state = /decl/machine_construction/default/panel_closed
	uncreated_component_parts = null
	var/obj/item/sample
	var/report_num
	var/list/allowed_evidence_types = list(
		/datum/forensics/fingerprints,
		/datum/forensics/fibers,
		/datum/forensics/gunshot_residue,
		/datum/forensics/trace_dna,
		/datum/forensics/blood_dna
	)

/obj/machinery/forensic/Destroy()
	if(sample)
		sample.dropInto(loc)
		clear_sample()
	return ..()

/obj/machinery/forensic/proc/set_sample(var/obj/O)
	if(O != sample && O)
		clear_sample()
		events_repository.register(/decl/observ/destroyed, O, src, TYPE_PROC_REF(/obj/machinery/forensic, clear_sample))
		sample = O
		update_icon()

/obj/machinery/forensic/proc/clear_sample()
	if(sample)
		events_repository.unregister(/decl/observ/destroyed, sample, src)
		sample = null
		update_icon()

/obj/machinery/forensic/get_tool_manipulation_info()
	var/list/res = list("Use <b>harm</b> intent when manipulating with machine with tools.")
	return res + ..()

/obj/machinery/forensic/attackby(obj/item/used_item, mob/user)
	if((. = component_attackby(used_item, user)))
		return

	if(user?.check_intent(I_FLAG_HARM))
		return ..() // bash, bash!

	if(sample)
		to_chat(user, SPAN_WARNING("There is already a sample in \the [src]."))
		return TRUE

	if(istype(used_item, /obj/item/evidencebag))
		var/obj/item/evidencebag/B = used_item
		if(B.stored_item)
			to_chat(user, SPAN_NOTICE("You insert \the [B.stored_item] from \the [B]."))
			B.stored_item.forceMove(src)
			set_sample(B.stored_item)
			B.empty()
			return TRUE
	if(!user.try_unequip(used_item, src))
		return TRUE
	to_chat(user, SPAN_NOTICE("You insert \the [used_item] into  \the [src]."))
	set_sample(used_item)
	update_icon()
	return TRUE

/obj/machinery/forensic/proc/get_report()
	if(!sample)
		return "No sample"
	var/list/evidence = list()
	var/scaned_object = sample.name
	if(istype(sample, /obj/item/forensics/sample))
		var/obj/item/forensics/sample/S = sample
		scaned_object = S.object ? S.object : S.name
		for(var/datum/forensics/F in S.evidence)
			if(is_type_in_list(F, allowed_evidence_types))
				evidence += F
	else
		var/datum/extension/forensic_evidence/forensics = get_extension(sample, /datum/extension/forensic_evidence)
		for(var/T in allowed_evidence_types)
			if(forensics.evidence[T])
				evidence += forensics.evidence[T]

	. = list("<h2>Forensic report #[++report_num]</h2>")
	. += "<h4>Scanned item:</h4> [scaned_object]"
	for(var/datum/forensics/F in evidence)
		if(LAZYLEN(F.data))
			. += F.get_formatted_data()
		else
			. += "No [F.name] detected."

	. = jointext(., "<br>")

/obj/machinery/forensic/proc/print_report()
	var/obj/item/paper/report = new(get_turf(src), null, get_report(), "[src] report #[++report_num]: [sample.name]")
	playsound(loc, "sound/machines/dotprinter.ogg", 30, 1)
	report.apply_custom_stamp('icons/obj/items/stamps/stamp_brig.dmi', "by \the [src]")

/obj/machinery/forensic/proc/remove_sample(var/mob/living/remover)
	if(!istype(remover) || remover.incapacitated() || !Adjacent(remover))
		return
	if(!sample)
		to_chat(remover, SPAN_WARNING("\The [src] does not have a sample in it."))
		return
	to_chat(remover, SPAN_NOTICE("You remove \the [sample] from \the [src]."))
	remover.put_in_hands(sample)
	clear_sample()

/obj/machinery/forensic/handle_mouse_drop(atom/over, mob/user, params)
	if(user == over)
		remove_sample(user)
		return TRUE
	. = ..()

/obj/machinery/forensic/get_alt_interactions(var/mob/user)
	. = ..()
	LAZYADD(., /decl/interaction_handler/forensics_remove_sample)

/decl/interaction_handler/forensics_remove_sample
	name = "Remove Sample"
	expected_target_type = /obj/machinery/forensic
	examine_desc = "remove a sample"

/decl/interaction_handler/forensics_remove_sample/invoked(atom/target, mob/user, obj/item/prop)
	var/obj/machinery/forensic/F = target
	F.remove_sample(user)
