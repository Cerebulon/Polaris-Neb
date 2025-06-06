/datum/event/wallrot/setup()
	announceWhen = rand(0, 300)
	endWhen = announceWhen + 1

/datum/event/wallrot/announce()
	command_announcement.Announce("Harmful fungi detected on [location_name()]. Structures may be contaminated.", "[location_name()] Biologic Sensor Network", zlevels = affecting_z)

/datum/event/wallrot/start()
	spawn()
		var/turf/wall/center = null

		// 100 attempts
		for(var/i=0, i<100, i++)
			var/turf/candidate = locate(rand(1, world.maxx), rand(1, world.maxy), 1)
			if(istype(candidate, /turf/wall))
				center = candidate

		if(center)
			// Make sure at least one piece of wall rots!
			center.rot()

			// Have a chance to rot lots of other walls.
			var/rotcount = 0
			var/actual_severity = severity * rand(5, 10)
			for(var/turf/wall/wall in range(5, center)) if(prob(50))
				wall.rot()
				rotcount++

				// Only rot up to severity walls
				if(rotcount >= actual_severity)
					break
