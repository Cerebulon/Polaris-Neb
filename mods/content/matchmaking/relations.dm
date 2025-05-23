/datum/preferences
	var/list/relations
	var/list/relations_info

/datum/category_group/player_setup_category/relations_preferences
	name = "Matchmaking"
	sort_order = 6.5 // someone should really redo how these work
	category_item_type = /datum/category_item/player_setup_item/relations

/datum/category_item/player_setup_item/relations
	name = "Matchmaking"
	sort_order = 1

/datum/category_item/player_setup_item/relations/load_character(datum/pref_record_reader/R)
	pref.relations =      R.read("relations")
	pref.relations_info = R.read("relations_info")

/datum/category_item/player_setup_item/relations/save_character(datum/pref_record_writer/writer)
	writer.write("relations",      pref.relations)
	writer.write("relations_info", pref.relations_info)

/datum/category_item/player_setup_item/relations/sanitize_character()
	if(!pref.relations)
		pref.relations = list()
	if(!pref.relations_info)
		pref.relations_info = list()

/datum/category_item/player_setup_item/relations/content(mob/user)
	.=list()
	. += "Characters with enabled relations are paired up randomly after spawn. You can terminate relations when you first open relations info window, but after that it's final."
	. += "<hr>"
	. += "<br><b>What do they know about you?</b> This is the general info that all kinds of your connections would know. <a href='byond://?src=\ref[src];relation_info=["general"]'>Edit</a>"
	. += "<br><i>[pref.relations_info["general"] ? pref.relations_info["general"] : "Nothing specific."]</i>"
	. += "<hr>"
	for(var/datum/relation/relation as anything in subtypesof(/datum/relation))
		. += "<b>[initial(relation.name)]</b>\t"
		if(initial(relation.name) in pref.relations)
			. += "<span class='linkOn'>On</span>"
			. += "<a href='byond://?src=\ref[src];relation=[initial(relation.name)]'>Off</a>"
		else
			. += "<a href='byond://?src=\ref[src];relation=[initial(relation.name)]'>On</a>"
			. += "<span class='linkOn'>Off</span>"
		. += "<br><i>[initial(relation.desc)]</i>"
		. += "<br><b>What do they know about you?</b><a href='byond://?src=\ref[src];relation_info=[initial(relation.name)]'>Edit</a>"
		. += "<br><i>[pref.relations_info[initial(relation.name)] ? pref.relations_info[initial(relation.name)] : "Nothing specific."]</i>"
		. += "<hr>"
	. = jointext(.,null)

/datum/category_item/player_setup_item/relations/OnTopic(var/href,var/list/href_list, var/mob/user)
	if(href_list["relation"])
		var/relation = href_list["relation"]
		pref.relations ^= relation
		return TOPIC_REFRESH
	if(href_list["relation_info"])
		var/relation = href_list["relation_info"]
		var/info = sanitize(input("Character info", "What would you like the other party for this connection to know about your character?",html_decode(pref.relations_info[relation])) as message|null)
		if(info)
			pref.relations_info[relation] = info
		return TOPIC_REFRESH
	return ..()
