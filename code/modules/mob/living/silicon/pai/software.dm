var/global/list/pai_emotions = list(
		"Happy" = 1,
		"Cat" = 2,
		"Extremely Happy" = 3,
		"Face" = 4,
		"Laugh" = 5,
		"Off" = 6,
		"Sad" = 7,
		"Angry" = 8,
		"What" = 9,
		"Neutral" = 10,
		"Silly" = 11,
		"Nose" = 12,
		"Smirk" = 13,
		"Exclamation Points" = 14,
		"Question Mark" = 15
	)


var/global/list/pai_software_by_key = list()
var/global/list/default_pai_software = list()
/proc/populate_pai_software_list()
	pai_software_by_key = list()
	default_pai_software = list()
	for(var/type in subtypesof(/datum/pai_software))
		var/datum/pai_software/P = new type()
		if(pai_software_by_key[P.id])
			var/datum/pai_software/O = pai_software_by_key[P.id]
			PRINT_STACK_TRACE("pAI software module [type] has the same key ([P.id]) as [O.type] [O.id]!")
			continue
		pai_software_by_key[P.id] = P
		if(P.default)
			default_pai_software[P.id] = P

/mob/living/silicon/pai/proc/paiInterface()
	ui_interact(src)

/mob/living/silicon/pai/ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = 1)

	if(user != src || !istype(card))
		ui?.set_nano_status(STATUS_CLOSE, 0)
		return

	if(ui_key != "main")
		var/datum/pai_software/S = software[ui_key]
		if(S && !S.toggle)
			S.on_ui_interact(src, ui, force_open)
		else if(ui)
			ui.set_nano_status(STATUS_CLOSE, 0)
		return

	var/data[0]

	// Software we have bought
	var/bought_software[0]
	// Software we have not bought
	var/not_bought_software[0]

	for(var/key in pai_software_by_key)
		var/datum/pai_software/S = pai_software_by_key[key]
		var/software_data[0]
		software_data["name"] = S.name
		software_data["id"] = S.id
		if(key in software)
			software_data["on"] = S.is_active(src)
			bought_software[++bought_software.len] = software_data
		else
			software_data["ram"] = S.ram_cost
			not_bought_software[++not_bought_software.len] = software_data

	data["bought"] = bought_software
	data["not_bought"] = not_bought_software
	data["available_ram"] = ram

	// Emotions
	var/emotions[0]
	for(var/name in pai_emotions)
		var/emote[0]
		emote["name"] = name
		emote["id"] = pai_emotions[name]
		emotions[++emotions.len] = emote

	data["emotions"] = emotions
	data["current_emotion"] = card.current_emotion

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "pai_interface.tmpl", "pAI Software Interface", 450, 600)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/mob/living/silicon/pai/OnSelfTopic(href_list)
	if(href_list["software"])
		var/soft = href_list["software"]
		var/datum/pai_software/S = software[soft]
		if(S.toggle)
			S.toggle(src)
		else
			ui_interact(src, ui_key = soft)
		return TOPIC_HANDLED

	else if(href_list["stopic"])
		var/soft = href_list["stopic"]
		var/datum/pai_software/S = software[soft]
		if(S)
			return S.Topic(list2params(href_list), href_list)

	else if(href_list["purchase"])
		var/soft = href_list["purchase"]
		var/datum/pai_software/S = pai_software_by_key[soft]
		if(S && (ram >= S.ram_cost))
			ram -= S.ram_cost
			software[S.id] = S
			S.on_purchase(src)
		return TOPIC_HANDLED

	else if(href_list["image"])
		var/img = text2num(href_list["image"])
		if(1 <= img && img <= pai_emotions.len)
			card.setEmotion(img)
		return TOPIC_HANDLED

	return ..()
