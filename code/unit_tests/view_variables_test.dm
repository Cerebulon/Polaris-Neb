/datum/unit_test/view_variables_special_vv_handlers_shall_be_valid
	name = "VIEW VARIABLES: All Special VV Handlers Shall Be Valid"

/datum/unit_test/view_variables_special_vv_handlers_shall_be_valid/start_test()
	var/list/faulty_handlers = list()
	var/list/vv_set_handlers = decls_repository.get_decls_of_subtype(/decl/vv_set_handler)
	for(var/vv_handler in vv_set_handlers)
		var/decl/vv_set_handler/set_handler = vv_set_handlers[vv_handler]
		if(!ispath(set_handler.handled_type))
			log_bad("[set_handler] does not have a valid handled type. Expected a path, was [log_info_line(set_handler.handled_type)]")
			faulty_handlers |= set_handler
		if(!islist(set_handler.handled_vars))
			log_bad("[set_handler] does not have a handled variables list. Expected a list, was [log_info_line(set_handler.handled_vars)]")
			faulty_handlers |= set_handler
		else if(!set_handler.handled_vars.len)
			log_bad("[set_handler] as an empty handled variables list.")
			faulty_handlers |= set_handler
		else
			continue
			// Somehow check for missing vars here without creating instances.
			// I.e.:  for(var/handled_var in set_handler.handled_vars) check handled_var in handled_type.vars

	if(faulty_handlers.len)
		fail("The following special VV handlers are invalid: [english_list(faulty_handlers)]")
	else
		pass("All special VV handlers are valid.")
	return 1

/datum/unit_test/view_variables_no_special_vv_handlers_shall_have_overlapping_handling
	name = "VIEW VARIABLES: No Special VV Handlers Shall Have Overlapping Handling"

/datum/unit_test/view_variables_no_special_vv_handlers_shall_have_overlapping_handling/start_test()
	var/failed = 0
	var/list/vv_set_handlers = decls_repository.get_decls_of_subtype(/decl/vv_set_handler)
	for(var/vv_handler in vv_set_handlers)
		var/decl/vv_set_handler/sh1 = vv_set_handlers[vv_handler]
		for(var/other_vv_handler in vv_set_handlers)
			var/decl/vv_set_handler/sh2 = vv_set_handlers[other_vv_handler]
			if(sh1 == sh2)
				continue
			if(!(ispath(sh1.handled_type, sh2.handled_type) || ispath(sh2.handled_type, sh1.handled_type)))
				continue
			var/list/intersected_vars = sh1.handled_vars & sh2.handled_vars
			if(intersected_vars.len)
				failed =  TRUE
				log_bad("[sh1] and [sh2] have the following overlaps: [english_list(intersected_vars)]")

	if(failed)
		fail("One or more special VV handlers had overlapping handling.")
	else
		pass("No special VV handlers had overlapping handling.")
	return 1
