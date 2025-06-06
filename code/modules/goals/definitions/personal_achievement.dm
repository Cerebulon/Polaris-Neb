// Simple toggles. Get an input from somewhere in the code, marked
// as successful/unsuccessful for the rest of the round. Nothing very special.
/datum/goal/achievement
	var/failable = FALSE
	var/success = FALSE

/datum/goal/achievement/update_progress(var/progress)
	if(!success && !failable)
		success = progress
		on_completion()
	else if (success && failable)
		success = progress
		on_failure()

/datum/goal/achievement/check_success()
	return success

/datum/goal/achievement/fistfight
	description = "You're feeling antsy. Blow off some steam in a fistfight."
	completion_message = "You feel less like you want to punch someone."

/datum/goal/achievement/givehug
	description = "Give someone a hug."
	completion_message = "You made someone's day a little brighter."

/datum/goal/achievement/gethug
	description = "Receive a hug."
	completion_message = "Someone made your day a little brighter."

/datum/goal/achievement/graffiti
	description = "Screw the rules! Graffiti something!"
	completion_message = "Yeah! Smash the state!"

/datum/goal/achievement/newshound
	description = "Catch up on the news with a newspaper, none of that newfangled digital media."
	completion_message = "You feel much more in-the-know."