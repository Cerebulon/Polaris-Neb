/decl/uplink
	var/list/items_assoc
	var/list/datum/uplink_item/items
	var/list/datum/uplink_category/categories

/decl/uplink/Initialize()
	. = ..()
	items_assoc = list()
	items = init_subtypes(/datum/uplink_item)
	categories = init_subtypes(/datum/uplink_category)
	categories = dd_sortedObjectList(categories)

	for(var/datum/uplink_item/item in items)
		if(!item.name)
			items -= item
			continue

		items_assoc[item.type] = item

		for(var/datum/uplink_category/category in categories)
			if(item.category == category.type)
				category.items += item
				item.category = category

	for(var/datum/uplink_category/category in categories)
		category.items = dd_sortedObjectList(category.items)

/datum/uplink_item
	var/name
	var/desc
	var/item_cost = 0
	/// Allows specific antag roles to purchase at a different cost
	var/list/antag_costs = list()
	var/datum/uplink_category/category
	/// Antag roles this item is displayed to. If empty, display to all.
	var/list/decl/special_role/antag_roles
	/// Antag roles this item will not be displayed to. If empty, display to all.
	var/list/decl/special_role/exclude_antag_roles

/datum/uplink_item/item
	var/path = null

/datum/uplink_item/proc/buy(var/obj/item/uplink/U, var/mob/user)
	var/extra_args = extra_args(user)
	if(!extra_args)
		return

	if(!can_buy(U))
		return

	var/cost = cost(U.uses, U)

	var/goods = get_goods(U, get_turf(user), user, extra_args)
	if(!goods)
		return

	purchase_log(U, user, cost)
	U.uses -= cost
	U.used_TC += cost
	return goods

// Any additional arguments you wish to send to the get_goods
/datum/uplink_item/proc/extra_args(var/mob/user)
	return 1

/datum/uplink_item/proc/can_buy(obj/item/uplink/U)
	if(cost(U.uses, U) > U.uses)
		return 0

	return can_view(U)

/datum/uplink_item/proc/can_view(obj/item/uplink/U)
	// Making the assumption that if no uplink was supplied, then we don't care about antag roles
	if(!U || !length(antag_roles))
		return 1

	// With no owner, there's no need to check antag status.
	if(!U.uplink_owner)
		return 0

	if(LAZYLEN(exclude_antag_roles))
		for(var/antag_role in exclude_antag_roles)
			var/decl/special_role/antag = GET_DECL(antag_role)
			if(antag.is_antagonist(U.uplink_owner))
				return FALSE
	if(LAZYLEN(antag_roles))
		for(var/antag_role in antag_roles)
			var/decl/special_role/antag = GET_DECL(antag_role)
			if(antag.is_antagonist(U.uplink_owner))
				return TRUE
		return FALSE
	return TRUE

/datum/uplink_item/proc/cost(var/telecrystals, obj/item/uplink/U)
	. = item_cost
	if(U && U.uplink_owner)
		for(var/antag_role in antag_costs)
			var/decl/special_role/antag = GET_DECL(antag_role)
			if(antag.is_antagonist(U.uplink_owner))
				. = min(antag_costs[antag_role], .)
	return max(1, U ?  U.get_item_cost(src, .) : .)

/datum/uplink_item/proc/name()
	return name

/datum/uplink_item/proc/description()
	return desc

// get_goods does not necessarily return physical objects, it is simply a way to acquire the uplink item without paying
/datum/uplink_item/proc/get_goods(var/obj/item/uplink/U, var/loc)
	return 0

/datum/uplink_item/proc/log_icon()
	return

/datum/uplink_item/proc/purchase_log(obj/item/uplink/U, var/mob/user, var/cost)
	SSstatistics.add_field_details("traitor_uplink_items_bought", "[src]")
	log_and_message_admins("used \the [U.loc] to buy \a [src]")
	if(user)
		uplink_purchase_repository.add_entry(user.mind, src, cost)

/datum/uplink_item/dd_SortValue()
	return cost(INFINITY, null)

/********************************
*                           	*
*	Physical Uplink Entries		*
*                           	*
********************************/
/datum/uplink_item/item/buy(var/obj/item/uplink/U, var/mob/user)
	var/obj/item/I = ..()
	if(!I)
		return

	if(istype(I, /list))
		var/list/L = I
		if(L.len) I = L[1]

	if(istype(I) && ishuman(user))
		var/mob/living/human/A = user
		A.put_in_hands(I)
	return I

/datum/uplink_item/item/get_goods(var/obj/item/uplink/U, var/loc)
	var/obj/item/I = new path(loc)
	return I

/datum/uplink_item/item/description()
	if(!desc)
		// Fallback description
		var/obj/temp = src.path
		desc = initial(temp.desc)
	return ..()

/datum/uplink_item/item/log_icon()
	var/obj/I = path
	return html_icon(I)

/****************
* Support procs *
****************/
/proc/get_random_uplink_items(var/obj/item/uplink/U, var/remaining_TC, var/loc)
	var/list/bought_items = list()
	while(remaining_TC)
		var/datum/uplink_random_selection/uplink_selection = get_uplink_random_selection_by_type(/datum/uplink_random_selection/default)
		var/datum/uplink_item/I = uplink_selection.get_random_item(remaining_TC, U, bought_items)
		if(!I)
			break
		bought_items += I
		remaining_TC -= I.cost(remaining_TC, U)

	return bought_items
