/datum/preferences
	var/list/all_underwear
	var/list/all_underwear_metadata
	var/decl/backpack_outfit/backpack
	var/list/backpack_metadata
	var/decl/survival_box_option/survival_box_choice
	var/decl/starting_cash_choice/starting_cash_choice
	var/give_passport = TRUE

/datum/category_item/player_setup_item/physical/equipment
	name = "Clothing"
	sort_order = 4

	var/static/list/backpacks_by_name

/datum/category_item/player_setup_item/physical/equipment/New()
	..()
	if(!backpacks_by_name)
		backpacks_by_name = list()
		var/bos = global.using_map.get_available_backpacks()
		for(var/backpack_option in bos)
			var/decl/backpack_outfit/backpack_outfit = bos[backpack_option]
			backpacks_by_name[backpack_outfit.name] = backpack_outfit

/datum/category_item/player_setup_item/physical/equipment/load_character(datum/pref_record_reader/R)
	pref.all_underwear =          R.read("all_underwear")
	pref.all_underwear_metadata = R.read("all_underwear_metadata")
	pref.backpack_metadata =      R.read("backpack_metadata")
	pref.starting_cash_choice =   decls_repository.get_decl_by_id_or_var(R.read("starting_cash_choice"), /decl/starting_cash_choice)
	pref.survival_box_choice =    decls_repository.get_decl_by_id_or_var(R.read("survival_box"), /decl/survival_box_option)

	pref.give_passport = R.read("passport")
	if(isnull(pref.give_passport))
		pref.give_passport = TRUE

	var/load_backbag = R.read("backpack")
	pref.backpack = backpacks_by_name[load_backbag] || get_default_outfit_backpack()

/datum/category_item/player_setup_item/physical/equipment/save_character(datum/pref_record_writer/writer)
	writer.write("all_underwear",          pref.all_underwear)
	writer.write("all_underwear_metadata", pref.all_underwear_metadata)
	writer.write("backpack",               pref.backpack.name)
	writer.write("backpack_metadata",      pref.backpack_metadata)
	writer.write("survival_box",           pref.survival_box_choice?.uid)
	writer.write("starting_cash_choice",   pref.starting_cash_choice?.uid)
	writer.write("passport",               pref.give_passport)

/datum/category_item/player_setup_item/physical/equipment/sanitize_character()
	if(!istype(pref.all_underwear))
		pref.all_underwear = list()

		for(var/datum/category_group/underwear/WRC in global.underwear.categories)
			for(var/datum/category_item/underwear/WRI in WRC.items)
				if(WRI.is_default(pref.gender ? pref.gender : MALE))
					pref.all_underwear[WRC.name] = WRI.name
					break

	var/decl/bodytype/mob_bodytype = pref.get_bodytype_decl()
	if(!(mob_bodytype.appearance_flags & HAS_UNDERWEAR))
		pref.all_underwear.Cut()

	if(!istype(pref.all_underwear_metadata))
		pref.all_underwear_metadata = list()

	for(var/underwear_category in pref.all_underwear)
		var/datum/category_group/underwear/UWC = global.underwear.categories_by_name[underwear_category]
		if(!UWC)
			pref.all_underwear -= underwear_category
		else
			var/datum/category_item/underwear/UWI = UWC.items_by_name[pref.all_underwear[underwear_category]]
			if(!UWI)
				pref.all_underwear -= underwear_category

	for(var/underwear_metadata in pref.all_underwear_metadata)
		if(!(underwear_metadata in pref.all_underwear))
			pref.all_underwear_metadata -= underwear_metadata

	if(!pref.backpack || !(pref.backpack.name in backpacks_by_name))
		pref.backpack = get_default_outfit_backpack()

	if(!istype(pref.backpack_metadata))
		pref.backpack_metadata = list()

	for(var/backpack_metadata_name in pref.backpack_metadata)
		if(!(backpack_metadata_name in backpacks_by_name))
			pref.backpack_metadata -= backpack_metadata_name

	for(var/backpack_name in backpacks_by_name)
		var/decl/backpack_outfit/backpack = backpacks_by_name[backpack_name]
		var/list/tweak_metadata = pref.backpack_metadata["[backpack]"]
		if(tweak_metadata)
			for(var/tw in backpack.tweaks)
				var/datum/backpack_tweak/tweak = tw
				var/list/metadata = tweak_metadata["[tweak]"]
				tweak_metadata["[tweak]"] = tweak.validate_metadata(metadata)

	if(length(global.using_map.starting_cash_choices))
		if(!pref.starting_cash_choice || !(pref.starting_cash_choice.type in global.using_map.starting_cash_choices))
			pref.starting_cash_choice = global.using_map.starting_cash_choices[global.using_map.starting_cash_choices[1]]
	else
		pref.starting_cash_choice = null

	// if you have at least one box available, 'none' must be its own bespoke option
	if(length(global.using_map.survival_box_choices))
		if(!pref.survival_box_choice || !(pref.survival_box_choice.type in global.using_map.survival_box_choices))
			pref.survival_box_choice = global.using_map.survival_box_choices[global.using_map.survival_box_choices[1]]
	else
		pref.survival_box_choice = null

/datum/category_item/player_setup_item/physical/equipment/content()
	. = list()
	. += "<b>Equipment:</b><br>"
	var/decl/bodytype/mob_bodytype = pref.get_bodytype_decl()
	if(mob_bodytype?.appearance_flags & HAS_UNDERWEAR)
		for(var/datum/category_group/underwear/UWC in global.underwear.categories)
			var/item_name = (pref.all_underwear && pref.all_underwear[UWC.name]) ? pref.all_underwear[UWC.name] : "None"
			. += "[UWC.name]: <a href='byond://?src=\ref[src];change_underwear=[UWC.name]'><b>[item_name]</b></a>"

			var/datum/category_item/underwear/UWI = UWC.items_by_name[item_name]
			if(UWI)
				for(var/datum/gear_tweak/gt in UWI.tweaks)
					. += " <a href='byond://?src=\ref[src];underwear=[UWC.name];tweak=\ref[gt]'>[gt.get_contents(get_underwear_metadata(UWC.name, gt))]</a>"

			. += "<br>"
	. += "<b>Backpack type:</b> <a href='byond://?src=\ref[src];change_backpack=1'><b>[pref.backpack.name]</b></a>"
	for(var/datum/backpack_tweak/bt in pref.backpack.tweaks)
		. += " <a href='byond://?src=\ref[src];backpack=[pref.backpack.name];tweak=\ref[bt]'>[bt.get_ui_content(get_backpack_metadata(pref.backpack, bt))]</a>"
	. += "<br>"

	if(length(global.using_map.survival_box_choices) > 1)
		. += "<b>Survival box type:</b> <a href='byond://?src=\ref[src];change_survival_box=1'><b>[pref.survival_box_choice]</b></a><br>"

	if(global.using_map.passport_type)
		. += "<b>Passport:</b> <a href='byond://?src=\ref[src];toggle_passport=1'><b>[pref.give_passport ? "Yes" : "No"]</b></a><br>"

	if(length(global.using_map.starting_cash_choices) > 1)
		. += "<br><b>Personal finances:</b><br><a href='byond://?src=\ref[src];change_cash_choice=1'>[pref.starting_cash_choice]</a><br>"
	return jointext(.,null)

/datum/category_item/player_setup_item/physical/equipment/proc/get_underwear_metadata(var/underwear_category, var/datum/gear_tweak/gt)
	var/metadata = pref.all_underwear_metadata[underwear_category]
	if(!metadata)
		metadata = list()
		pref.all_underwear_metadata[underwear_category] = metadata

	var/tweak_data = metadata["[gt]"]
	if(!tweak_data)
		tweak_data = gt.get_default()
		metadata["[gt]"] = tweak_data
	return tweak_data

/datum/category_item/player_setup_item/physical/equipment/proc/get_backpack_metadata(var/decl/backpack_outfit/backpack_outfit, var/datum/backpack_tweak/bt)
	var/metadata = pref.backpack_metadata[backpack_outfit.name]
	if(!metadata)
		metadata = list()
		pref.backpack_metadata[backpack_outfit.name] = metadata

	var/tweak_data = metadata["[bt]"]
	if(!tweak_data)
		tweak_data = bt.get_default_metadata()
		metadata["[bt]"] = tweak_data
	return tweak_data

/datum/category_item/player_setup_item/physical/equipment/proc/set_underwear_metadata(var/underwear_category, var/datum/gear_tweak/gt, var/new_metadata)
	var/list/metadata = pref.all_underwear_metadata[underwear_category]
	metadata["[gt]"] = new_metadata

/datum/category_item/player_setup_item/physical/equipment/proc/set_backpack_metadata(var/decl/backpack_outfit/backpack_outfit, var/datum/backpack_tweak/bt, var/new_metadata)
	var/metadata = pref.backpack_metadata[backpack_outfit.name]
	metadata["[bt]"] = new_metadata

/datum/category_item/player_setup_item/physical/equipment/OnTopic(var/href,var/list/href_list, var/mob/user)
	if(href_list["change_underwear"])
		var/datum/category_group/underwear/UWC = global.underwear.categories_by_name[href_list["change_underwear"]]
		if(!UWC)
			return TOPIC_NOACTION
		var/datum/category_item/underwear/selected_underwear = input(user, "Choose underwear:", CHARACTER_PREFERENCE_INPUT_TITLE, pref.all_underwear[UWC.name]) as null|anything in UWC.items
		if(selected_underwear && CanUseTopic(user))
			pref.all_underwear[UWC.name] = selected_underwear.name
		return TOPIC_REFRESH_UPDATE_PREVIEW
	else if(href_list["toggle_passport"])
		pref.give_passport = !pref.give_passport
		return TOPIC_REFRESH
	else if(href_list["change_survival_box"] && length(global.using_map.survival_box_choices))
		var/list/display_choices = list() // for some reason, to get this to work, we have to flip the list
		for(var/key in global.using_map.survival_box_choices)
			display_choices += global.using_map.survival_box_choices[key]
		var/chosen_box = input(user, "Select a survival box alternative.", "Survival Box", pref.survival_box_choice) as null|anything in display_choices
		if(!chosen_box)
			return TOPIC_NOACTION
		pref.survival_box_choice = chosen_box
		return TOPIC_REFRESH
	else if(href_list["underwear"] && href_list["tweak"])
		var/underwear = href_list["underwear"]
		if(!(underwear in pref.all_underwear))
			return TOPIC_NOACTION
		var/datum/gear_tweak/gt = locate(href_list["tweak"])
		if(!gt)
			return TOPIC_NOACTION
		var/new_metadata = gt.get_metadata(user, get_underwear_metadata(underwear, gt))
		if(new_metadata)
			set_underwear_metadata(underwear, gt, new_metadata)
			return TOPIC_REFRESH_UPDATE_PREVIEW
	else if(href_list["change_backpack"])
		var/new_backpack = input(user, "Choose backpack style:", CHARACTER_PREFERENCE_INPUT_TITLE, pref.backpack) as null|anything in backpacks_by_name
		if(!isnull(new_backpack) && CanUseTopic(user))
			pref.backpack = backpacks_by_name[new_backpack]
			return TOPIC_REFRESH_UPDATE_PREVIEW
	else if(href_list["backpack"] && href_list["tweak"])
		var/backpack_name = href_list["backpack"]
		if(!(backpack_name in backpacks_by_name))
			return TOPIC_NOACTION
		var/decl/backpack_outfit/backpack_option = backpacks_by_name[backpack_name]
		var/datum/backpack_tweak/bt = locate(href_list["tweak"]) in backpack_option.tweaks
		if(!bt)
			return TOPIC_NOACTION
		var/new_metadata = bt.get_metadata(user, get_backpack_metadata(backpack_option, bt))
		if(new_metadata)
			set_backpack_metadata(backpack_option, bt, new_metadata)
			return TOPIC_REFRESH_UPDATE_PREVIEW
	else if(href_list["change_cash_choice"])
		var/list/display_choices = list()
		for(var/key in global.using_map.starting_cash_choices)
			display_choices += global.using_map.starting_cash_choices[key]
		var/chosen_cash = input(user, "Select a personal finance alternative.", "Personal Finances", pref.starting_cash_choice) as null|anything in display_choices
		if(!chosen_cash)
			return TOPIC_NOACTION
		pref.starting_cash_choice = chosen_cash
		return TOPIC_REFRESH
	return ..()
