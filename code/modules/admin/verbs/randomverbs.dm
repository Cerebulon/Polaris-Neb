/client/proc/cmd_admin_drop_everything(mob/M as mob in SSmobs.mob_list)
	set category = null
	set name = "Drop Everything"
	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return

	var/confirm = alert(src, "Make [M] drop everything?", "Message", "Yes", "No")
	if(confirm != "Yes")
		return

	for(var/obj/item/thing in M.get_contained_external_atoms())
		M.drop_from_inventory(thing)

	log_admin("[key_name(usr)] made [key_name(M)] drop everything!")
	message_admins("[key_name_admin(usr)] made [key_name_admin(M)] drop everything!", 1)
	SSstatistics.add_field_details("admin_verb","DEVR") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_check_new_players()	//Allows admins to determine who the newer players are.
	set category = "Admin"
	set name = "Check new Players"
	if(!holder)
		to_chat(src, "Only staff members may use this command.")

	var/age = alert(src, "Age check", "Show accounts yonger then _____ days","7", "30" , "All")

	if(age == "All")
		age = 9999999
	else
		age = text2num(age)

	var/missing_ages = 0
	var/msg = ""

	for(var/client/C in global.clients)
		if(C.player_age == "Requires database")
			missing_ages = 1
			continue
		if(C.player_age < age)
			msg += "[key_name(C, 1, 1, 1)]: account is [C.player_age] days old<br>"

	if(missing_ages)
		to_chat(src, "Some accounts did not have proper ages set in their clients.  This function requires database to be present")

	if(msg != "")
		show_browser(src, msg, "window=Player_age_check")
	else
		to_chat(src, "No matches for that age range found.")


/client/proc/cmd_admin_world_narrate() // Allows administrators to fluff events a little easier -- TLE
	set category = "Special Verbs"
	set name = "Global Narrate"
	set desc = "Narrate to everyone."

	if(!check_rights(R_ADMIN))
		return

	var/result = cmd_admin_narrate_helper(src)
	if (!result)
		return

	to_world(result[1])

	log_and_message_admins(" - GlobalNarrate [result[2]]/[result[3]]: [result[4]]")
	SSstatistics.add_field_details("admin_verb","GLN") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!


/proc/cmd_admin_narrate_helper(var/user, var/style, var/size, var/message)
	if (!style)
		style = input("Pick a text style:", "Text Style") as null|anything in list(
			"default",
			"italic",
			"bold",
			"subtle",
			"notice",
			"warning",
			"danger",
			"occult",
			"unsafe"
		)
	if (!style)
		return

	if (style == "unsafe")
		if (!get_config_value(/decl/config/toggle/allow_unsafe_narrates))
			to_chat(user, SPAN_WARNING("Unsafe narrates are not permitted by the server configuration."))
			return

	if (style != "unsafe")
		if (!size)
			size = input("Pick a text size:", "Text Size") as null|anything in list(
				"normal",
				"small",
				"large",
				"huge",
				"giant"
			)
		if (!size)
			return

	if (!message)
		message = input("Message:", text("Enter the text you wish to appear to your target:")) as null|text
		if (style != "unsafe")
			message = sanitize(message)
	if (!message)
		return

	var/result = message
	if (style != "unsafe")
		switch (style)
			if ("italic")  result = "<i>[result]</i>"
			if ("bold")    result = "<b>[result]</b>"
			if ("subtle")  result = "<b>You hear a voice in your head... [result]</b>"
			if ("notice")  result = SPAN_NOTICE(result)
			if ("warning") result = SPAN_WARNING(result)
			if ("danger")  result = SPAN_DANGER(result)
			if ("occult")  result = SPAN_OCCULT(result)
		switch (size)
			if ("small")  result = FONT_SMALL(result)
			if ("large")  result = FONT_LARGE(result)
			if ("huge")   result = FONT_HUGE(result)
			if ("giant")  result = FONT_GIANT(result)

	return list(result, style, size, message)


// Targetted narrate: will narrate to one specific mob
/client/proc/cmd_admin_direct_narrate(var/mob/M)
	set category = "Special Verbs"
	set name = "Direct Narrate"
	set desc = "Narrate to a specific mob."

	if (!check_rights(R_INVESTIGATE))
		return

	if (!M)
		M = input("Direct narrate to who?", "Active Players") as null|anything in get_mob_with_client_list()
	if (!M)
		return

	var/style
	var/size

	if (!check_rights(R_ADMIN, FALSE))
		style = "subtle"
		size = "normal"

	var/result = cmd_admin_narrate_helper(src, style, size)
	if (!result)
		return

	to_chat(M, result[1])
	log_and_message_admins(" - DirectNarrate [result[2]]/[result[3]] to ([M.name]/[M.key]): [result[4]]")
	SSstatistics.add_field_details("admin_verb","DIRN") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

// Local narrate, narrates to everyone who can see where you are regardless of whether they are blind or deaf.
/client/proc/cmd_admin_local_narrate()
	set category = "Special Verbs"
	set name = "Local Narrate"
	set desc = "Narrate to everyone who can see the turf your mob is on."

	if(!check_rights(R_ADMIN))
		return

	var/result = cmd_admin_narrate_helper(src)
	if (!result)
		return

	var/list/listening_hosts = hosts_in_view_range(usr)

	for(var/listener in listening_hosts)
		to_chat(listener, result[1])
	log_and_message_admins(" - LocalNarrate [result[2]]/[result[3]]: [result[4]]")

// Visible narrate, it's as if it's a visible message
/client/proc/cmd_admin_visible_narrate(var/atom/A)
	set category = "Special Verbs"
	set name = "Visible Narrate"
	set desc = "Narrate to those who can see the given atom."

	if(!check_rights(R_ADMIN))
		return

	var/mob/M = mob

	if(!M)
		to_chat(src, "You must be in control of a mob to use this.")
		return

	var/result = cmd_admin_narrate_helper(src)
	if (!result)
		return

	M.visible_message(result[1], result[1], narrate = TRUE)
	log_and_message_admins(" - VisibleNarrate [result[2]]/[result[3]] on [A]: [result[4]]")

// Visible narrate, it's as if it's an audible message
/client/proc/cmd_admin_audible_narrate(var/atom/A)
	set category = "Special Verbs"
	set name = "Audible Narrate"
	set desc = "Narrate to those who can hear the given atom."

	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return

	var/mob/M = mob

	if(!M)
		to_chat(src, "You must be in control of a mob to use this.")
		return

	var/result = cmd_admin_narrate_helper(src)
	if (!result)
		return

	M.audible_message(result[1], result[1], narrate = TRUE)
	log_and_message_admins(" - AudibleNarrate [result[2]]/[result[3]] on [A]: [result[4]]")

/client/proc/cmd_admin_godmode(mob/M as mob in SSmobs.mob_list)
	set category = "Special Verbs"
	set name = "Godmode"
	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return
	M.status_flags ^= GODMODE
	to_chat(usr, "<span class='notice'>Toggled [(M.status_flags & GODMODE) ? "ON" : "OFF"]</span>")
	log_admin("[key_name(usr)] has toggled [key_name(M)]'s nodamage to [(M.status_flags & GODMODE) ? "On" : "Off"]")
	message_admins("[key_name_admin(usr)] has toggled [key_name_admin(M)]'s nodamage to [(M.status_flags & GODMODE) ? "On" : "Off"]", 1)
	SSstatistics.add_field_details("admin_verb","GOD") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/proc/cmd_admin_mute(mob/M as mob, mute_type)
	if(!usr || !usr.client)
		return
	if(!usr.client.holder)
		to_chat(usr, SPAN_WARNING("Error: cmd_admin_mute: You don't have permission to do this."))
		return
	if(!M.client)
		to_chat(usr, SPAN_WARNING("Error: cmd_admin_mute: This mob doesn't have a client tied to it."))
		return
	if(M.client.holder)
		to_chat(usr, SPAN_WARNING("Error: cmd_admin_mute: You cannot mute an admin/mod."))
		return

	var/muteunmute
	var/mute_string

	switch(mute_type)
		if(MUTE_IC)			mute_string = "IC (say and emote)"
		if(MUTE_OOC)		mute_string = "OOC"
		if(MUTE_AOOC)		mute_string = "AOOC"
		if(MUTE_PRAY)		mute_string = "pray"
		if(MUTE_ADMINHELP)	mute_string = "adminhelp, admin PM and ASAY"
		if(MUTE_DEADCHAT)	mute_string = "deadchat and DSAY"
		if(MUTE_ALL)		mute_string = "everything"
		else				return


	if(M.client.prefs.muted & mute_type)
		muteunmute = "unmuted"
		M.client.prefs.muted &= ~mute_type
	else
		muteunmute = "muted"
		M.client.prefs.muted |= mute_type

	log_admin("[key_name(usr)] has [muteunmute] [key_name(M)] from [mute_string]")
	message_staff("[key_name_admin(usr)] has [muteunmute] [key_name_admin(M)] from [mute_string].", 1)
	to_chat(M, "<span class = 'alert'>You have been [muteunmute] from [mute_string].</span>")
	SSstatistics.add_field_details("admin_verb","MUTE") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/*
Allow admins to set players to be able to respawn/bypass 30 min wait, without the admin having to edit variables directly
Ccomp's first proc.
*/
/proc/get_ghosts(var/notify, var/what = 2)
	// what = 1, return ghosts ass list.
	// what = 2, return mob list

	var/list/mobs = list()
	var/list/ghosts = list()
	var/list/sortmob = sortTim(SSmobs.mob_list, /proc/cmp_name_asc) // get the mob list.
	var/any=0
	for(var/mob/observer/ghost/M in sortmob)
		mobs.Add(M)                                             //filter it where it's only ghosts
		any = 1                                                 //if no ghosts show up, any will just be 0
	if(!any)
		if(notify)
			to_chat(notify, "There doesn't appear to be any ghosts for you to select.")
		return
	for(var/mob/M in mobs)
		var/name = M.name
		ghosts[name] = M                                        //get the name of the mob for the popup list
	if(what == 1)
		return ghosts
	return mobs

/client/proc/get_ghosts_by_key()
	. = list()
	for(var/mob/observer/ghost/M in SSmobs.mob_list)
		.[M.ckey] = M
	. = sortTim(., /proc/cmp_text_asc)

/client/proc/allow_character_respawn(var/selection in get_ghosts_by_key())
	set category = "Special Verbs"
	set name = "Allow player to respawn"
	set desc = "Allows the player bypass the wait to respawn or allow them to re-enter their corpse."

	if(!check_rights(R_ADMIN))
		return

	var/list/ghosts = get_ghosts_by_key()
	var/mob/observer/ghost/G = ghosts[selection]
	if(!istype(G))
		to_chat(src, "<span class='warning'>[selection] no longer has an associated ghost.</span>")
		return

	if(G.has_enabled_antagHUD == 1 && get_config_value(/decl/config/toggle/antag_hud_restricted))
		var/response = alert(src, "[selection] has enabled antagHUD. Are you sure you wish to allow them to respawn?","Ghost has used AntagHUD","No","Yes")
		if(response == "No") return
	else
		var/response = alert(src, "Are you sure you wish to allow [selection] to respawn?","Allow respawn","No","Yes")
		if(response == "No") return

	/*
	  time of death is checked in /mob/verb/abandon_mob() which is the Respawn verb.
	  timeofdeath is used for bodies on autopsy but since we're messing with a ghost I'm pretty sure
	  there won't be an autopsy.
	*/
	G.timeofdeath          = -(INFINITY)
	G.has_enabled_antagHUD = 2
	G.can_reenter_corpse  |= CORPSE_CAN_RESPAWN

	G.show_message("<span class=notice><b>You may now respawn.  You should roleplay as if you learned nothing about the round during your time with the dead.</b></span>", 1)
	log_and_message_admins("has allowed [key_name(G)] to bypass the [get_config_value(/decl/config/num/respawn_delay)] minute respawn limit.")

/client/proc/toggle_antagHUD_use()
	set category = "Server"
	set name = "Toggle antagHUD usage"
	set desc = "Toggles antagHUD usage for observers"

	if(!holder)
		to_chat(src, "Only administrators may use this command.")
	var/action = "disabled"
	if(toggle_config_value(/decl/config/toggle/antag_hud_allowed))
		action = "enabled"
	to_chat(src, "<span class='notice'><B>AntagHUD usage has been [action]</B></span>")
	log_admin("[key_name(usr)] has [action] antagHUD usage for observers")
	message_admins("Admin [key_name_admin(usr)] has [action] antagHUD usage for observers", 1)

/client/proc/toggle_antagHUD_restrictions()
	set category = "Server"
	set name = "Toggle antagHUD Restrictions"
	set desc = "Restricts players that have used antagHUD from being able to join this round."
	if(!holder)
		to_chat(src, "Only administrators may use this command.")
	var/action=""
	if(toggle_config_value(/decl/config/toggle/antag_hud_restricted))
		for(var/mob/observer/ghost/g in get_ghosts(src))
			to_chat(g, "<span class='danger'>The administrator has placed restrictions on joining the round if you use AntagHUD</span>")
			to_chat(g, "<span class='danger'>Your AntagHUD has been disabled, you may choose to re-enabled it but will be under restrictions</span>")
			g.antagHUD = 0
			g.has_enabled_antagHUD = 0
		action = "placed restrictions"
		to_chat(src, "<span class='danger'>AntagHUD restrictions have been enabled</span>")
	else
		for(var/mob/observer/ghost/g in get_ghosts(src))
			to_chat(g, "<span class='notice'><B>The administrator has lifted restrictions on joining the round if you use AntagHUD</B></span>")
		action = "lifted restrictions"
		to_chat(src, "<span class='notice'><B>AntagHUD restrictions have been lifted</B></span>")
	log_admin("[key_name(usr)] has [action] on joining the round if they use AntagHUD")
	message_admins("Admin [key_name_admin(usr)] has [action] on joining the round if they use AntagHUD", 1)

/*
If a guy was gibbed and you want to revive him, this is a good way to do so.
Works kind of like entering the game with a new character. Character receives a new mind if they didn't have one.
Traitors and the like can also be revived with the previous role mostly intact.
/N */
/client/proc/respawn_character()
	set category = "Special Verbs"
	set name = "Respawn Character"
	set desc = "Respawn a person that has been gibbed/dusted/killed. They must be a ghost for this to work and preferably should not have a body to go back into."
	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return
	var/input = ckey(input(src, "Please specify which key will be respawned.", "Key", ""))
	if(!input)
		return

	var/mob/observer/ghost/G_found
	for(var/mob/observer/ghost/G in global.player_list)
		if(G.ckey == input)
			G_found = G
			break

	if(!G_found)//If a ghost was not found.
		to_chat(usr, SPAN_WARNING("There is no active key like that in the game or the person is not currently a ghost."))
		return

	var/mob/living/human/new_character = new(get_random_spawn_turf(SPAWN_FLAG_JOBS_CAN_SPAWN)) //The mob being spawned.
	var/datum/computer_file/report/crew_record/record_found			//Referenced to later to either randomize or not randomize the character.
	if(G_found.mind && !G_found.mind.active)
		record_found = get_crewmember_record(G_found.real_name)

	if(record_found)//If they have a record we can determine a few things.
		new_character.real_name = record_found.get_name()
		new_character.set_gender(record_found.get_gender())
		new_character.set_age(record_found.get_age())
		new_character.blood_type = record_found.get_bloodtype()
	else
		new_character.set_gender(pick(MALE,FEMALE))
		var/datum/preferences/A = new()
		A.setup()
		A.randomize_appearance_and_body_for(new_character)
		new_character.real_name = G_found.real_name

	if(!new_character.real_name)
		if(new_character.gender == MALE)
			new_character.real_name = capitalize(pick(global.using_map.first_names_male)) + " " + capitalize(pick(global.using_map.last_names))
		else
			new_character.real_name = capitalize(pick(global.using_map.first_names_female)) + " " + capitalize(pick(global.using_map.last_names))
	new_character.SetName(new_character.real_name)

	if(G_found.mind && !G_found.mind.active)
		G_found.mind.transfer_to(new_character)	//be careful when doing stuff like this! I've already checked the mind isn't in use
	else
		new_character.mind_initialize()
	if(!new_character.mind.assigned_role)
		new_character.mind.assigned_role = global.using_map.default_job_title//If they somehow got a null assigned role.

	//DNA
	if(record_found)//Pull up their name from database records if they did have a mind.
		new_character.set_unique_enzymes(record_found.get_dna())
	new_character.key = G_found.key

	/*
	The code below functions with the assumption that the mob is already a traitor if they have a special role.
	So all it does is re-equip the mob with powers and/or items. Or not, if they have no special role.
	If they don't have a mind, they obviously don't have a special role.
	*/

	var/player_key = G_found.key

	//Now for special roles and equipment.
	var/decl/special_role/antag_data = GET_DECL(new_character.mind.assigned_special_role)
	if(istype(antag_data))
		antag_data.add_antagonist(new_character.mind)
		antag_data.place_mob(new_character)
	else
		SSjobs.equip_job_title(new_character, new_character.mind.assigned_role, 1)

	//Announces the character on all the systems, based on the record.
	if(!issilicon(new_character))//If they are not a cyborg/AI.
		if(!record_found && !player_is_antag(new_character.mind, only_offstation_roles = 1)) //If there are no records for them. If they have a record, this info is already in there. MODE people are not announced anyway.
			if(alert(new_character,"Would you like an active AI to announce this character?",,"No","Yes")=="Yes")
				call(/proc/AnnounceArrival)(new_character, new_character.mind.assigned_role)

	log_and_message_admins("has respawned [player_key] as [new_character.real_name].")

	to_chat(new_character, "You have been fully respawned. Enjoy the game.")
	SSstatistics.add_field_details("admin_verb","RSPCH") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	return new_character

/client/proc/cmd_admin_add_freeform_ai_law()
	set category = "Fun"
	set name = "Add Custom AI law"
	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return
	var/input = sanitize(input(usr, "Please enter anything you want the AI to do. Anything. Serious.", "What?", "") as text|null)
	if(!input)
		return
	for(var/mob/living/silicon/ai/M in SSmobs.mob_list)
		if (M.stat == DEAD)
			to_chat(usr, "Upload failed. No signal is being detected from the AI.")
		else if (M.see_in_dark == 0)
			to_chat(usr, "Upload failed. Only a faint signal is being detected from the AI, and it is not responding to our requests. It may be low on power.")
		else
			M.add_ion_law(input)
			for(var/mob/living/silicon/ai/O in SSmobs.mob_list)
				to_chat(O, SPAN_WARNING("[input]... LAWS UPDATED."))
				O.show_laws()

	log_admin("Admin [key_name(usr)] has added a new AI law - [input]")
	message_admins("Admin [key_name_admin(usr)] has added a new AI law - [input]", 1)

	var/show_log = alert(src, "Show ion message?", "Message", "Yes", "No")
	if(show_log == "Yes")
		command_announcement.Announce("Ion storm detected near the [station_name()]. Please check all AI-controlled equipment for errors.", "Anomaly Alert", new_sound = 'sound/AI/ionstorm.ogg')
	SSstatistics.add_field_details("admin_verb","IONC") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_admin_rejuvenate(mob/living/M as mob in SSmobs.mob_list)
	set category = "Special Verbs"
	set name = "Rejuvenate"
	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return
	if(!mob)
		return
	if(!istype(M))
		alert("Cannot revive a ghost")
		return
	if(get_config_value(/decl/config/toggle/on/admin_revive))
		M.revive()

		log_and_message_admins("healed / revived [key_name_admin(M)]!")
	else
		alert("Admin revive disabled")
	SSstatistics.add_field_details("admin_verb","REJU") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_admin_create_centcom_report()
	set category = "Special Verbs"
	set name = "Create Command Report"
	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return
	var/input = sanitize(input(usr, "Please enter anything you want. Anything. Serious.", "What?", "") as message|null, extra = 0)
	var/customname = sanitize_safe(input(usr, "Pick a title for the report.", "Title") as text|null)
	if(!input)
		return
	if(!customname)
		customname = "[global.using_map.boss_name] Update"

	// Even admin must bow to the whim of the autolanguagefilter.
	if(filter_block_message(mob, input) || filter_block_message(mob, customname))
		return

	//New message handling
	post_comm_message(customname, replacetext(input, "\n", "<br/>"))

	switch(alert("Should this be announced to the general population?",,"Yes","No"))
		if("Yes")
			command_announcement.Announce(input, customname, new_sound = global.using_map.command_report_sound, msg_sanitized = 1);
		if("No")
			minor_announcement.Announce(message = "New [global.using_map.company_name] Update available at all communication consoles.")

	log_admin("[key_name(src)] has created a command report: [input]")
	message_admins("[key_name_admin(src)] has created a command report", 1)
	SSstatistics.add_field_details("admin_verb","CCR") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_admin_delete(atom/O as obj|mob|turf in range(world.view))
	set category = "Admin"
	set name = "Delete"

	if (!holder)
		to_chat(src, "Only administrators may use this command.")
		return

	if (alert(src, "Are you sure you want to delete:\n[O]\nat ([O.x], [O.y], [O.z])?", "Confirmation", "Yes", "No") == "Yes")
		log_admin("[key_name(usr)] deleted [O] at ([O.x],[O.y],[O.z])")
		message_admins("[key_name_admin(usr)] deleted [O] at ([O.x],[O.y],[O.z])", 1)
		SSstatistics.add_field_details("admin_verb","DEL") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

		// turfs are special snowflakes that'll explode if qdel'd
		if (isturf(O))
			var/turf/T = O
			T.ChangeTurf(world.turf)
		else
			qdel(O)

/client/proc/cmd_admin_list_open_jobs()
	set category = "Admin"
	set name = "List free slots"

	if (!holder)
		to_chat(src, "Only administrators may use this command.")
		return
	for(var/datum/job/job in SSjobs.primary_job_datums)
		to_chat(src, "[job.title]: [job.total_positions]")
	SSstatistics.add_field_details("admin_verb","LFS") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_admin_explosion(atom/O as obj|mob|turf in range(world.view))
	set category = "Special Verbs"
	set name = "Explosion"

	if(!check_rights(R_DEBUG|R_FUN))	return

	var/devastation = input("Range of total devastation. -1 to none", text("Input"))  as num|null
	if(devastation == null) return
	var/heavy = input("Range of heavy impact. -1 to none", text("Input"))  as num|null
	if(heavy == null) return
	var/light = input("Range of light impact. -1 to none", text("Input"))  as num|null
	if(light == null) return
	var/flash = input("Range of flash. -1 to none", text("Input"))  as num|null
	if(flash == null) return
	if ((devastation != -1) || (heavy != -1) || (light != -1) || (flash != -1))
		if ((devastation > 20) || (heavy > 20) || (light > 20))
			if (alert(src, "Are you sure you want to do this? It will laaag.", "Confirmation", "Yes", "No") == "No")
				return
		explosion(O, devastation, heavy, light, flash)
		log_admin("[key_name(usr)] created an explosion ([devastation],[heavy],[light],[flash]) at ([O.x],[O.y],[O.z])")
		message_admins("[key_name_admin(usr)] created an explosion ([devastation],[heavy],[light],[flash]) at ([O.x],[O.y],[O.z])", 1)
		SSstatistics.add_field_details("admin_verb","EXPL") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
		return
	else
		return

/client/proc/cmd_admin_emp(atom/O as obj|mob|turf in range(world.view))
	set category = "Special Verbs"
	set name = "EM Pulse"

	if(!check_rights(R_DEBUG|R_FUN))	return

	var/heavy = input("Range of heavy pulse.", text("Input"))  as num|null
	if(heavy == null) return
	var/light = input("Range of light pulse.", text("Input"))  as num|null
	if(light == null) return

	if (heavy || light)

		empulse(O, heavy, light)
		log_admin("[key_name(usr)] created an EM Pulse ([heavy],[light]) at ([O.x],[O.y],[O.z])")
		message_admins("[key_name_admin(usr)] created an EM PUlse ([heavy],[light]) at ([O.x],[O.y],[O.z])", 1)
		SSstatistics.add_field_details("admin_verb","EMP") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

		return
	else
		return

/client/proc/cmd_admin_gib(mob/M as mob in SSmobs.mob_list)
	set category = "Special Verbs"
	set name = "Gib"
	if(!check_rights(R_ADMIN|R_FUN))	return
	var/confirm = alert(src, "You sure?", "Confirm", "Yes", "No")
	if(confirm != "Yes") return
	//Due to the delay here its easy for something to have happened to the mob
	if(!M)	return
	log_admin("[key_name(usr)] has gibbed [key_name(M)]")
	message_admins("[key_name_admin(usr)] has gibbed [key_name_admin(M)]", 1)
	M.gib()
	SSstatistics.add_field_details("admin_verb","GIB") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_admin_gib_self()
	set name = "Gibself"
	set category = "Fun"

	var/confirm = alert(src, "You sure?", "Confirm", "Yes", "No")
	if(confirm == "Yes")
		if (isobserver(mob)) // so they don't spam gibs everywhere
			return
		else
			mob.gib()

		log_and_message_admins("used gibself.")
		SSstatistics.add_field_details("admin_verb","GIBS") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_admin_check_contents(mob/living/M as mob in SSmobs.mob_list)
	set category = "Special Verbs"
	set name = "Check Contents"
	for(var/t in M.get_mob_contents())
		to_chat(usr, "[t]")
	SSstatistics.add_field_details("admin_verb","CC") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/toggle_view_range()
	set category = "Special Verbs"
	set name = "Change View Range"
	set desc = "switches between 1x and custom views"

	if(view == world.view)
		view = input("Select view range:", "Change View Range", 7) in list(1,2,3,4,5,6,7,8,9,10,11,12,13,14,128)
	else
		view = world.view
		OnResize()

	log_and_message_admins("changed their view range to [view].")
	SSstatistics.add_field_details("admin_verb","CVRA") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/admin_call_shuttle()

	set category = "Admin"
	set name = "Call Evacuation"

	if(!SSticker.mode || !SSevac.evacuation_controller)
		return

	if(!check_rights(R_ADMIN))	return

	if(alert(src, "Are you sure?", "Confirm", "Yes", "No") != "Yes") return

	if(SSticker.mode.auto_recall_shuttle)
		if(input("The evacuation will just be cancelled if you call it. Call anyway?") in list("Confirm", "Cancel") != "Confirm")
			return

	var/choice = input("Is this an emergency evacuation or a crew transfer?") in list("Emergency", "Crew Transfer")
	SSevac.evacuation_controller.call_evacuation(usr, (choice == "Emergency"))

	SSstatistics.add_field_details("admin_verb","CSHUT") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	log_and_message_admins("admin-called an evacuation.")
	return

/client/proc/admin_cancel_shuttle()
	set category = "Admin"
	set name = "Cancel Evacuation"

	if(!check_rights(R_ADMIN))	return

	if(alert(src, "You sure?", "Confirm", "Yes", "No") != "Yes") return

	if(!SSevac.evacuation_controller)
		return

	SSevac.evacuation_controller.cancel_evacuation()

	SSstatistics.add_field_details("admin_verb","CCSHUT") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	log_and_message_admins("admin-cancelled the evacuation.")

/client/proc/admin_deny_shuttle()
	set category = "Admin"
	set name = "Toggle Deny Evac"

	if (!SSevac.evacuation_controller)
		return

	if(!check_rights(R_ADMIN))	return

	SSevac.evacuation_controller.deny = !SSevac.evacuation_controller.deny

	log_admin("[key_name(src)] has [SSevac.evacuation_controller.deny ? "denied" : "allowed"] evacuation to be called.")
	message_admins("[key_name_admin(usr)] has [SSevac.evacuation_controller.deny ? "denied" : "allowed"] evacuation to be called.")

/client/proc/cmd_admin_attack_log(mob/M as mob in SSmobs.mob_list)
	set category = "Special Verbs"
	set name = "Attack Log"

	to_chat(usr, text("<span class='danger'>Attack Log for []</span>", mob))
	for(var/t in M.attack_logs_)
		to_chat(usr, t)
	SSstatistics.add_field_details("admin_verb","ATTL") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!


/client/proc/everyone_random()
	set category = "Fun"
	set name = "Make Everyone Random"
	set desc = "Make everyone have a random appearance. You can only use this before rounds!"

	if(!check_rights(R_FUN))	return

	if (GAME_STATE >= RUNLEVEL_GAME)
		to_chat(usr, "Nope you can't do this, the game's already started. This only works before rounds!")
		return

	if(global.random_players)
		global.random_players = 0
		message_admins("Admin [key_name_admin(usr)] has disabled \"Everyone is Special\" mode.", 1)
		to_chat(usr, "Disabled.")
		return


	var/notifyplayers = alert(src, "Do you want to notify the players?", "Options", "Yes", "No", "Cancel")
	if(notifyplayers == "Cancel")
		return

	log_admin("Admin [key_name(src)] has forced the players to have random appearances.")
	message_admins("Admin [key_name_admin(usr)] has forced the players to have random appearances.", 1)

	if(notifyplayers == "Yes")
		to_world("<span class='notice'><b>Admin [usr.key] has forced the players to have completely random identities!</b></span>")

	to_chat(usr, "<i>Remember: you can always disable the randomness by using the verb again, assuming the round hasn't started yet</i>.")
	global.random_players = 1
	SSstatistics.add_field_details("admin_verb","MER") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!


/client/proc/toggle_random_events()
	set category = "Server"
	set name = "Toggle random events on/off"

	set desc = "Toggles random events such as meteors, black holes, blob (but not space dust) on/off"
	if(!check_rights(R_SERVER))	return

	toggle_config_value(/decl/config/toggle/on/allow_random_events)
	if(get_config_value(/decl/config/toggle/on/allow_random_events))
		to_chat(usr, "Random events enabled")
		message_admins("Admin [key_name_admin(usr)] has enabled random events.", 1)
	else
		to_chat(usr, "Random events disabled")
		message_admins("Admin [key_name_admin(usr)] has disabled random events.", 1)
	SSstatistics.add_field_details("admin_verb","TRE") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
