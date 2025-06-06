/datum/preferences
	var/list/may_be_special_role
	var/list/be_special_role

/datum/category_item/player_setup_item/antagonism
	abstract_type = /datum/category_item/player_setup_item/antagonism

/datum/category_item/player_setup_item/antagonism/candidacy
	name = "Candidacy"
	sort_order = 1

/datum/category_item/player_setup_item/antagonism/candidacy/load_character(datum/pref_record_reader/R)
	pref.be_special_role =     R.read("be_special")
	pref.may_be_special_role = R.read("may_be_special")

/datum/category_item/player_setup_item/antagonism/candidacy/save_character(datum/pref_record_writer/writer)
	writer.write("be_special",     pref.be_special_role)
	writer.write("may_be_special", pref.may_be_special_role)

/datum/category_item/player_setup_item/antagonism/candidacy/sanitize_character()
	if(!istype(pref.be_special_role))
		pref.be_special_role = list()
	if(!istype(pref.may_be_special_role))
		pref.may_be_special_role = list()

	var/special_roles = valid_special_roles()
	var/old_be_special_role = pref.be_special_role.Copy()
	var/old_may_be_special_role = pref.may_be_special_role.Copy()
	for(var/role in old_be_special_role)
		if(!(role in special_roles))
			pref.be_special_role -= role
	for(var/role in old_may_be_special_role)
		if(!(role in special_roles))
			pref.may_be_special_role -= role

/datum/category_item/player_setup_item/antagonism/candidacy/content(var/mob/user)
	. = list()
	. += "<b>Special Role Availability:</b><br>"
	. += "<table>"
	var/list/all_antag_types = decls_repository.get_decls_of_subtype(/decl/special_role)
	for(var/antag_type in all_antag_types)
		var/decl/special_role/antag = all_antag_types[antag_type]
		. += "<tr><td>[antag.name]: </td><td>"
		if(jobban_isbanned(preference_mob(), antag.name))
			. += "<span class='danger'>\[BANNED\]</span><br>"
		else if(antag.name in pref.be_special_role)
			. += "<span class='linkOn'>High</span> <a href='byond://?src=\ref[src];add_maybe=[antag.name]'>Low</a> <a href='byond://?src=\ref[src];del_special=[antag.name]'>Never</a></br>"
		else if(antag.name in pref.may_be_special_role)
			. += "<a href='byond://?src=\ref[src];add_special=[antag.name]'>High</a> <span class='linkOn'>Low</span> <a href='byond://?src=\ref[src];del_special=[antag.name]'>Never</a></br>"
		else
			. += "<a href='byond://?src=\ref[src];add_special=[antag.name]'>High</a> <a href='byond://?src=\ref[src];add_maybe=[antag.name]'>Low</a> <span class='linkOn'>Never</span></br>"

		. += "</td></tr>"
	. += "</table>"
	. += "<b>Ghost Role Availability:</b>"
	. += "<table>"
	var/list/all_ghost_traps = decls_repository.get_decls_of_subtype(/decl/ghosttrap)
	for(var/ghost_trap_key in all_ghost_traps)
		var/decl/ghosttrap/ghost_trap = all_ghost_traps[ghost_trap_key]
		if(!ghost_trap.list_as_special_role)
			continue

		. += "<tr><td>[capitalize(ghost_trap.name)]: </td><td>"
		if(banned_from_ghost_role(preference_mob(), ghost_trap))
			. += "<span class='danger'>\[BANNED\]</span><br>"
		else if(ghost_trap.pref_check in pref.be_special_role)
			. += "<span class='linkOn'>High</span> <a href='byond://?src=\ref[src];add_maybe=[ghost_trap.pref_check]'>Low</a> <a href='byond://?src=\ref[src];del_special=[ghost_trap.pref_check]'>Never</a></br>"
		else if(ghost_trap.pref_check in pref.may_be_special_role)
			. += "<a href='byond://?src=\ref[src];add_special=[ghost_trap.pref_check]'>High</a> <span class='linkOn'>Low</span> <a href='byond://?src=\ref[src];del_special=[ghost_trap.pref_check]'>Never</a></br>"
		else
			. += "<a href='byond://?src=\ref[src];add_special=[ghost_trap.pref_check]'>High</a> <a href='byond://?src=\ref[src];add_maybe=[ghost_trap.pref_check]'>Low</a> <span class='linkOn'>Never</span></br>"

		. += "</td></tr>"
	. += "<tr><td>Select All: </td><td><a href='byond://?src=\ref[src];select_all=2'>High</a> <a href='byond://?src=\ref[src];select_all=1'>Low</a> <a href='byond://?src=\ref[src];select_all=0'>Never</a></td></tr>"
	. += "</table>"
	. = jointext(.,null)

/datum/category_item/player_setup_item/proc/banned_from_ghost_role(var/mob, var/decl/ghosttrap/ghost_trap)
	for(var/ban_type in ghost_trap.ban_checks)
		if(jobban_isbanned(mob, ban_type))
			return 1
	return 0

/datum/category_item/player_setup_item/antagonism/candidacy/OnTopic(var/href,var/list/href_list, var/mob/user)
	if(href_list["add_special"])
		if(!(href_list["add_special"] in valid_special_roles(FALSE)))
			return TOPIC_HANDLED
		pref.be_special_role |= href_list["add_special"]
		pref.may_be_special_role -= href_list["add_special"]
		return TOPIC_REFRESH

	if(href_list["del_special"])
		if(!(href_list["del_special"] in valid_special_roles(FALSE)))
			return TOPIC_HANDLED
		pref.be_special_role -= href_list["del_special"]
		pref.may_be_special_role -= href_list["del_special"]
		return TOPIC_REFRESH

	if(href_list["add_maybe"])
		pref.be_special_role -= href_list["add_maybe"]
		pref.may_be_special_role |= href_list["add_maybe"]
		return TOPIC_REFRESH

	if(href_list["select_all"])
		var/selection = text2num(href_list["select_all"])
		var/list/roles = valid_special_roles(FALSE)

		for(var/id in roles)
			switch(selection)
				if(0)
					pref.be_special_role -= id
					pref.may_be_special_role -= id
				if(1)
					pref.be_special_role -= id
					pref.may_be_special_role |= id
				if(2)
					pref.be_special_role |= id
					pref.may_be_special_role -= id
		return TOPIC_REFRESH

	return ..()

/datum/category_item/player_setup_item/antagonism/candidacy/proc/valid_special_roles(var/include_bans = TRUE)
	var/list/private_valid_special_roles = list()

	var/list/all_antag_types = decls_repository.get_decls_of_subtype(/decl/special_role)
	for(var/antag_type in all_antag_types)
		var/decl/special_role/role = all_antag_types[antag_type]
		if(!include_bans)
			if(jobban_isbanned(preference_mob(), role.name))
				continue
		private_valid_special_roles |= role.name

	var/list/all_ghost_traps = decls_repository.get_decls_of_subtype(/decl/ghosttrap)
	for(var/ghost_trap_key in all_ghost_traps)
		var/decl/ghosttrap/ghost_trap = all_ghost_traps[ghost_trap_key]
		if(!ghost_trap.list_as_special_role)
			continue
		if(!include_bans)
			if(banned_from_ghost_role(preference_mob(), ghost_trap))
				continue
		private_valid_special_roles |= ghost_trap.pref_check
	return private_valid_special_roles

/client/proc/wishes_to_be_role(var/role)
	if(!prefs)
		return FALSE
	if(role in prefs.be_special_role)
		return 2
	if(role in prefs.may_be_special_role)
		return 1
	return FALSE	//Default to "never" if they don't opt-in.
