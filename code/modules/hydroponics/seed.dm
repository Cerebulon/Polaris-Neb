/datum/codex_entry/scannable/flora
	category = /decl/codex_category/flora

/datum/seed
	//Tracking.
	var/uid                        // Unique identifier.
	var/name                       // Index for global list.
	var/product_name               // Plant name for seed packet and product strings.
	var/seed_noun = SEED_NOUN_SEEDS// Descriptor for packet.
	var/display_name               // Prettier name.
	var/roundstart                 // If set, seed will not display variety number.
	var/mysterious                 // Only used for the random seed packets.
	var/scanned                    // If it was scanned with a plant analyzer.
	var/can_self_harvest = 0       // Mostly used for living mobs.
	var/growth_stages = 0          // Number of stages the plant passes through before it is mature.
	var/list/_traits               // Initialized in New()
	var/list/mutants               // Possible predefined mutant varieties, if any.
	var/list/chems                 // Chemicals that plant produces in products/injects into victim.
	var/list/dried_chems           // Chemicals that a dried plant product will have.
	var/list/roasted_chems         // Chemicals that a roasted/grilled plant product will have.
	var/list/consume_gasses        // The plant will absorb these gasses during its life.
	var/list/exude_gasses          // The plant will exude these gasses during its life.
	var/grown_tag                  // Used by the reagent grinder.
	var/trash_type                 // Garbage item produced when eaten.
	var/splat_type = /obj/effect/decal/cleanable/fruit_smudge // Graffiti decal.
	var/product_type = /obj/item/food/grown
	var/product_material
	var/force_layer
	var/req_CO2_moles    = 1.0// Moles of CO2 required for photosynthesis.
	var/hydrotray_only
	var/base_seed_value = 5 // Used when generating price.
	var/scannable_result
	var/grown_is_seed = FALSE
	var/product_w_class = ITEM_SIZE_SMALL
	var/produces_pollen = 0

	// Dissection values.
	var/min_seed_extracted = 1
	var/max_seed_extracted = 2
	var/slice_product = /obj/item/food/processed_grown/slice
	var/slice_amount = 5

	// Cached images for overlays
	var/image/dead_overlay
	var/image/harvest_overlay
	var/list/growing_overlays

	// Backyard grilling vars. Not passed through genetics.
	var/backyard_grilling_rawness      = 20
	var/backyard_grilling_product      = /obj/item/food/badrecipe
	var/backyard_grilling_announcement = "smokes and chars!"

	// Used to show an icon when drying in a rack.
	var/drying_state = "grown"

	// Used to set allergens on growns.
	var/allergen_flags = ALLERGEN_VEGETABLE

/datum/seed/New()
	update_growth_stages()
	uid = "[sequential_id(/datum/seed)]"

// TODO integrate other traits.
/datum/seed/proc/get_monetary_value()
	. = 1
	for(var/decl/plant_trait/plant_trait in decls_repository.get_decls_of_subtype_unassociated(/decl/plant_trait))
		. += plant_trait.get_worth_of_value(get_trait(plant_trait.type))
	. = max(1, round(. * base_seed_value))

/datum/seed/proc/get_trash_type()
	return trash_type

/datum/seed/proc/set_trait(var/trait, var/nval, var/ubound, var/lbound, var/degrade)
	if(!isnull(degrade))
		nval *= degrade
	if(!isnull(ubound))
		nval = min(nval,ubound)
	if(!isnull(lbound))
		nval = max(nval,lbound)

	var/decl/plant_trait/plant_trait = GET_DECL(trait)
	if(!istype(plant_trait) || nval == plant_trait.default_value)
		LAZYREMOVE(_traits, trait)
	else
		LAZYSET(_traits, trait, nval)
	plant_trait.handle_post_trait_set(src)

/datum/seed/proc/get_trait(var/trait)
	if(trait in _traits)
		return _traits[trait]
	var/decl/plant_trait/plant_trait = GET_DECL(trait)
	return plant_trait.default_value

/datum/seed/proc/create_spores(var/turf/T)
	if(!T)
		return
	if(!istype(T))
		T = get_turf(T)
	if(!T)
		return

	var/datum/reagents/R = new/datum/reagents(100, global.temp_reagents_holder)
	if(chems.len)
		for(var/rid in chems)
			var/injecting = min(5,max(1,get_trait(TRAIT_POTENCY)/3))
			R.add_reagent(rid,injecting)

	var/datum/effect/effect/system/smoke_spread/chem/spores/S = new(name)
	S.attach(T)
	S.set_up(R, round(get_trait(TRAIT_POTENCY)/4), 0, T)
	S.start()
	qdel(R)

// Does brute damage to a target.
/datum/seed/proc/do_thorns(var/mob/living/human/target, var/obj/item/fruit, var/target_limb)

	if(!get_trait(TRAIT_CARNIVOROUS))
		return

	if(!istype(target))
		if(ismouse(target))
			new /obj/item/remains/mouse(get_turf(target))
			qdel(target)
		else if(islizard(target))
			new /obj/item/remains/lizard(get_turf(target))
			qdel(target)
		return

	var/obj/item/organ/external/affecting = target_limb ? GET_EXTERNAL_ORGAN(target, target_limb) : pick(target.get_external_organs())
	if(affecting?.species?.species_flags & (SPECIES_FLAG_NO_EMBED|SPECIES_FLAG_NO_MINOR_CUT))
		to_chat(target, "<span class='danger'>\The [fruit]'s thorns scratch against the armour on your [affecting.name]!</span>")
		return

	var/damage = 0
	var/edged = 0
	if(get_trait(TRAIT_CARNIVOROUS) >= 2)
		if(affecting)
			to_chat(target, "<span class='danger'>\The [fruit]'s thorns pierce your [affecting.name] greedily!</span>")
		else
			to_chat(target, "<span class='danger'>\The [fruit]'s thorns pierce your flesh greedily!</span>")
		damage = max(5, round(15*get_trait(TRAIT_POTENCY)/100, 1))
		edged = prob(get_trait(TRAIT_POTENCY)/2)
	else
		if(affecting)
			to_chat(target, "<span class='danger'>\The [fruit]'s thorns dig deeply into your [affecting.name]!</span>")
		else
			to_chat(target, "<span class='danger'>\The [fruit]'s thorns dig deeply into your flesh!</span>")
		damage = max(1, round(5*get_trait(TRAIT_POTENCY)/100, 1))
		edged = prob(get_trait(TRAIT_POTENCY)/5)

	var/damage_flags = DAM_SHARP|(edged? DAM_EDGE : 0)
	target.apply_damage(damage, BRUTE, target_limb, damage_flags, used_weapon = "Thorns")

// Adds reagents to a target.
/datum/seed/proc/do_sting(var/mob/living/human/target, var/obj/item/fruit)
	if(!get_trait(TRAIT_STINGS))
		return

	var/list/external_organs = target.get_external_organs()
	if(chems && chems.len && target.reagents && LAZYLEN(external_organs))

		var/obj/item/organ/external/affecting = pick(external_organs)
		for(var/slot in global.standard_clothing_slots)
			var/obj/item/clothing/C = target.get_equipped_item(slot)
			if(istype(C) && (C.body_parts_covered & affecting.body_part) && (C.item_flags & ITEM_FLAG_THICKMATERIAL))
				affecting = null
				break

		if(!(target.species && target.species.species_flags & (SPECIES_FLAG_NO_EMBED|SPECIES_FLAG_NO_MINOR_CUT)))	affecting = null

		if(affecting)
			to_chat(target, "<span class='danger'>You are stung by \the [fruit] in your [affecting.name]!</span>")
			for(var/rid in chems)
				var/injecting = min(5,max(1,get_trait(TRAIT_POTENCY)/5))
				target.add_to_reagents(rid,injecting)
		else
			to_chat(target, "<span class='danger'>Sharp spines scrape against your armour!</span>")

/datum/seed/proc/do_photosynthesis(var/turf/current_turf, var/datum/gas_mixture/environment, var/light_supplied)
	// Photosynthesis - *very* simplified process.
	// For now, only light-dependent reactions are available (no Calvin cycle).
	// It's active only for those plants which doesn't consume nor exude gasses.
	if(!get_trait(TRAIT_PHOTOSYNTHESIS))
		return
	if(!(environment) || !(environment.gas))
		return
	if(LAZYLEN(exude_gasses) || LAZYLEN(consume_gasses ))
		return
	if(!(light_supplied) || !(get_trait(TRAIT_REQUIRES_WATER)))
		return
	if(environment.get_gas(/decl/material/gas/carbon_dioxide) >= req_CO2_moles)
		environment.adjust_gas(/decl/material/gas/carbon_dioxide, -req_CO2_moles, 1)
		environment.adjust_gas(/decl/material/gas/oxygen, req_CO2_moles, 1)

/datum/seed/proc/make_splat(var/turf/T, var/obj/item/thrown)
	if(!splat_type || (locate(splat_type) in T))
		return
	var/atom/splat = new splat_type(T, src)
	splat.SetName("[product_name] [pick("smear","smudge","splatter")]")
	if(get_trait(TRAIT_BIOLUM))
		var/clr
		if(get_trait(TRAIT_BIOLUM_COLOUR))
			clr = get_trait(TRAIT_BIOLUM_COLOUR)
		splat.set_light(get_trait(TRAIT_BIOLUM), l_color = clr)
	splat.color = get_trait(TRAIT_FLESH_COLOUR) || get_trait(TRAIT_PRODUCT_COLOUR)

//Splatter a turf.
//Thrown can be null, but T cannot.
/datum/seed/proc/splatter(var/turf/T, var/obj/item/thrown)
	make_splat(T, thrown)

	var/datum/reagents/splat_reagents = thrown?.reagents
	if(!splat_reagents?.maximum_volume) // if thrown doesn't exist or has no reagents, use the seed's default reagents.
		splat_reagents = new /datum/reagents(INFINITY, global.temp_reagents_holder)
		var/potency = get_trait(TRAIT_POTENCY)
		for(var/rid in chems)
			var/list/reagent_amounts = chems[rid]
			if(LAZYLEN(reagent_amounts))
				var/rtotal = reagent_amounts[1]
				var/list/data = null
				if(reagent_amounts?[2] && potency > 0)
					rtotal += round(potency/reagent_amounts[2])
				if(rid == /decl/material/liquid/nutriment)
					LAZYSET(data, product_name, max(1,rtotal))
				splat_reagents.add_reagent(rid,max(1,rtotal),data)
	if(splat_reagents)
		var/splat_range = min(10,max(1,get_trait(TRAIT_POTENCY)/15))
		splat_reagents.splash_area(T, range = splat_range)
	qdel(splat_reagents)
	qdel(thrown)

//Applies an effect to a target atom.
/datum/seed/proc/thrown_at(var/obj/item/thrown,var/atom/target, var/force_explode)

	var/splatted
	var/turf/origin_turf = get_turf(target)

	if(force_explode || get_trait(TRAIT_EXPLOSIVE))
		create_spores(origin_turf)
		if(origin_turf)
			origin_turf.visible_message(SPAN_DANGER("\The [thrown] explodes!"))
		splatter(origin_turf,thrown)
		return

	if(isliving(target))
		splatted = apply_special_effect(target,thrown)
	else if(isturf(target))
		for(var/mob/living/M in target)
			splatted |= apply_special_effect(M, thrown)

	if(get_trait(TRAIT_JUICY) && splatted)
		if(origin_turf)
			origin_turf.visible_message(SPAN_DANGER("\The [thrown] splatters against [target]!"))
		splatter(origin_turf,thrown)

/datum/seed/proc/handle_plant_environment(var/obj/machinery/portable_atmospherics/hydroponics/holder, var/datum/gas_mixture/environment, var/light_supplied, var/check_only)

	var/growth_rate = 1
	var/turf/current_turf = isturf(holder) ? holder : get_turf(holder)
	if(istype(holder))
		growth_rate = holder.get_growth_rate()

	var/health_change = 0
	// Handle gas consumption.
	if(consume_gasses && consume_gasses.len)
		var/missing_gas = 0
		for(var/gas in consume_gasses)
			if(LAZYACCESS(environment?.gas, gas) >= consume_gasses[gas])
				if(!check_only)
					environment.adjust_gas(gas,-consume_gasses[gas],1)
			else
				missing_gas++

		if(missing_gas > 0)
			health_change += missing_gas * growth_rate

	// Process it.
	var/pressure = environment.return_pressure()
	if(pressure < get_trait(TRAIT_LOWKPA_TOLERANCE)|| pressure > get_trait(TRAIT_HIGHKPA_TOLERANCE))
		health_change += rand(1,3) * growth_rate

	if(abs(environment.temperature - get_trait(TRAIT_IDEAL_HEAT)) > get_trait(TRAIT_HEAT_TOLERANCE))
		health_change += rand(1,3) * growth_rate

	// Handle gas production.
	if(exude_gasses && exude_gasses.len && !check_only)
		for(var/gas in exude_gasses)
			environment.adjust_gas(gas, max(1,round((exude_gasses[gas]*(get_trait(TRAIT_POTENCY)/5))/exude_gasses.len)))

	//Handle temperature change.
	if(get_trait(TRAIT_ALTER_TEMP) != 0 && !check_only)
		var/target_temp = get_trait(TRAIT_ALTER_TEMP) > 0 ? 500 : 80
		if(environment && abs(environment.temperature-target_temp) > 0.1)
			var/datum/gas_mixture/removed = environment.remove(0.25 * environment.total_moles)
			if(removed)
				var/heat_transfer = abs(removed.get_thermal_energy_change(target_temp))
				heat_transfer = min(heat_transfer,abs(get_trait(TRAIT_ALTER_TEMP) * 10000))
				removed.add_thermal_energy((get_trait(TRAIT_ALTER_TEMP) > 0 ? 1 : -1) * heat_transfer)
			environment.merge(removed)

	// Handle light requirements.
	if(!light_supplied)
		light_supplied = current_turf.get_lumcount() * 5
	if(light_supplied)
		if(abs(light_supplied - get_trait(TRAIT_IDEAL_LIGHT)) > get_trait(TRAIT_LIGHT_TOLERANCE))
			health_change += rand(1,3) * growth_rate

	for(var/obj/effect/effect/smoke/chem/smoke in range(1, current_turf))
		if(smoke.reagents.has_reagent(/decl/material/liquid/weedkiller))
			return 100

	// Pressure and temperature are needed as much as water and light.
	// If any of the previous environment checks has failed
	// the photosynthesis cannot be triggered.
	if(health_change == 0)
		do_photosynthesis(current_turf, environment, light_supplied)

	return health_change

/datum/seed/proc/apply_special_effect(var/mob/living/target,var/obj/item/thrown)
	do_sting(target,thrown)
	do_thorns(target,thrown)

	// Teleport tomato code copied over from grown.dm.
	if(get_trait(TRAIT_TELEPORTING))

		//Plant potency determines radius of teleport.
		var/outer_teleport_radius = get_trait(TRAIT_POTENCY)/5
		var/inner_teleport_radius = get_trait(TRAIT_POTENCY)/15

		var/turf/T = get_random_turf_in_range(target, outer_teleport_radius, inner_teleport_radius)
		if(T)
			spark_at(target, cardinal_only = TRUE)
			new/obj/effect/decal/cleanable/molten_item(get_turf(target)) // Leave a pile of goo behind for dramatic effect...
			target.forceMove(T)                                     // And teleport them to the chosen location.
	return TRUE

/datum/seed/proc/generate_name()
	var/prefix = ""
	var/name = ""
	if(prob(50)) //start with a prefix.
		//These are various plant/mushroom genuses.
		//I realize these might not be entirely accurate, but it could facilitate RP.
		var/list/possible_prefixes
		if(seed_noun == SEED_NOUN_CUTTINGS || seed_noun == SEED_NOUN_SEEDS || (seed_noun == SEED_NOUN_NODES && prob(50)))
			possible_prefixes = list("amelanchier", "saskatoon",
										"magnolia", "angiosperma", "osmunda", "scabiosa", "spigelia", "psydrax", "chastetree",
										"strychnos", "treebine", "caper", "justica", "ragwortus", "everlasting", "combretum",
										"loganiaceae", "gelsemium", "logania", "sabadilla", "neuburgia", "canthium", "rytigynia",
										"chaste", "vitex", "cissus", "capparis", "senecio", "curry", "cycad", "liverwort", "charophyta",
										"glaucophyte", "pinidae", "vascular", "embryophyte", "lillopsida")
		else
			possible_prefixes = list("bisporus", "bitorquis", "campestris", "crocodilinus", "agaricus",
									"armillaria", "matsutake", "mellea", "ponderosa", "auricularia", "auricala",
									"polytricha", "boletus", "badius", "edulis", "mirabilis", "zelleri",
									"calvatia", "gigantea", "clitopilis", "prumulus", "entoloma", "abortivum",
									"suillus", "tuber", "aestivum", "volvacea", "delica", "russula", "rozites")

		possible_prefixes |= list("butter", "shad", "sugar", "june", "wild", "rigus", "curry", "hard", "soft", "dark", "brick", "stone", "red", "brown",
								"black", "white", "paper", "slippery", "honey", "bitter")
		prefix = pick(possible_prefixes)

	var/num = rand(2,5)
	var/list/possible_name = list("rhon", "cus", "quam", "met", "eget", "was", "reg", "zor", "fra", "rat", "sho", "ghen", "pa",
								"eir", "lip", "sum", "lor", "em", "tem", "por", "invi", "dunt", "ut", "la", "bore", "mag", "na",
								"al", "i", "qu", "yam", "er", "at", "sed", "di", "am", "vol", "up", "tua", "at", "ve", "ro", "eos",
								"et", "ac", "cus")
	for(var/i in 1 to num)
		var/syl = pick(possible_name)
		possible_name -= syl
		name += syl

	if(prefix)
		name = "[prefix] [name]"
	product_name = name
	display_name = "[name] plant"

//Creates a random seed. MAKE SURE THE LINE HAS DIVERGED BEFORE THIS IS CALLED.
/datum/seed/proc/randomize(var/temperature = T20C, var/pressure = 1 ATM)

	roundstart = 0
	mysterious = 1
	seed_noun = pick(SEED_NOUN_SEEDS, SEED_NOUN_PITS, SEED_NOUN_NODES, SEED_NOUN_CUTTINGS)

	set_trait(TRAIT_POTENCY,rand(5,30),200,0)
	set_trait(TRAIT_PRODUCT_ICON,pick(SSplants.plant_product_sprites))
	set_trait(TRAIT_PLANT_ICON,pick(SSplants.plant_sprites))
	set_trait(TRAIT_PLANT_COLOUR,get_random_colour(0,75,190))
	set_trait(TRAIT_PRODUCT_COLOUR,get_random_colour(0,75,190))
	update_growth_stages()

	if(prob(20))
		set_trait(TRAIT_HARVEST_REPEAT,1)

	if(prob(15))
		if(prob(15))
			set_trait(TRAIT_JUICY,2)
		else
			set_trait(TRAIT_JUICY,1)

	if(prob(5))
		set_trait(TRAIT_STINGS,1)

	if(prob(5))
		set_trait(TRAIT_PRODUCES_POWER,1)

	if(prob(1))
		set_trait(TRAIT_EXPLOSIVE,1)
	else if(prob(1))
		set_trait(TRAIT_TELEPORTING,1)

	var/skip_toxins = prob(30)
	var/list/gasses  = list()
	var/list/liquids = list()
	var/list/all_materials = decls_repository.get_decls_of_subtype(/decl/material)
	for(var/mat_type in all_materials)
		var/decl/material/mat = all_materials[mat_type]
		if(mat.exoplanet_rarity_plant == MAT_RARITY_NOWHERE)
			continue
		if(skip_toxins && mat.toxicity)
			continue
		if(!isnull(mat.heating_point) && length(mat.heating_products) && temperature >= mat.heating_point)
			// TODO: Maybe add products, but that could lead to having a lot of water or something.
			continue
		if(!isnull(mat.chilling_point) && length(mat.chilling_products) && temperature <= mat.chilling_point)
			continue
		switch(mat.phase_at_temperature(temperature, pressure))
			if(MAT_PHASE_GAS)
				if(isnull(mat.gas_condensation_point) || mat.gas_condensation_point > temperature)
					gasses[mat.type] = mat.exoplanet_rarity_plant
			if(MAT_PHASE_LIQUID)
				liquids[mat.type] = mat.exoplanet_rarity_plant
	liquids -= /decl/material/liquid/nutriment

	if(length(gasses))
		if(prob(5))
			var/gas = pickweight(gasses)
			gasses -= gas
			LAZYSET(consume_gasses, gas, rand(3,9))
		if(prob(5))
			var/gas = pickweight(gasses)
			gasses -= gas
			LAZYSET(exude_gasses, gas, rand(3,9))

	chems = list()
	if(prob(80))
		chems[/decl/material/liquid/nutriment] = list(rand(1,10),rand(10,20))
	if(length(liquids))
		for(var/x = 1 to rand(0, 5))
			var/new_chem = pickweight(liquids)
			liquids -= new_chem
			chems[new_chem] = list(rand(1,10), rand(10,20))

	if(prob(90))
		set_trait(TRAIT_REQUIRES_NUTRIENTS,1)
		set_trait(TRAIT_NUTRIENT_CONSUMPTION,rand(25)/25)
	else
		set_trait(TRAIT_REQUIRES_NUTRIENTS,0)

	if(prob(90))
		set_trait(TRAIT_REQUIRES_WATER,1)
		set_trait(TRAIT_WATER_CONSUMPTION,rand(10))
	else
		set_trait(TRAIT_REQUIRES_WATER,0)

	set_trait(TRAIT_IDEAL_HEAT,       rand(100,400))
	set_trait(TRAIT_HEAT_TOLERANCE,   rand(10,30))
	set_trait(TRAIT_IDEAL_LIGHT,      rand(2,10))
	set_trait(TRAIT_LIGHT_TOLERANCE,  rand(2,7))
	set_trait(TRAIT_TOXINS_TOLERANCE, rand(2,7))
	set_trait(TRAIT_PEST_TOLERANCE,   rand(2,7))
	set_trait(TRAIT_WEED_TOLERANCE,   rand(2,7))
	set_trait(TRAIT_LOWKPA_TOLERANCE, rand(10,50))
	set_trait(TRAIT_HIGHKPA_TOLERANCE,rand(100,300))

	if(prob(5))
		set_trait(TRAIT_ALTER_TEMP,rand(-5,5))

	if(prob(1))
		set_trait(TRAIT_IMMUTABLE,-1)

	var/carnivore_prob = rand(100)
	if(carnivore_prob < 5)
		set_trait(TRAIT_CARNIVOROUS,2)
	else if(carnivore_prob < 10)
		set_trait(TRAIT_CARNIVOROUS,1)

	if(prob(10))
		set_trait(TRAIT_PARASITE,1)

	var/vine_prob = rand(100)
	if(vine_prob < 5)
		set_trait(TRAIT_SPREAD,2)
	else if(vine_prob < 10)
		set_trait(TRAIT_SPREAD,1)

	if(prob(5))
		set_trait(TRAIT_BIOLUM,1)
		set_trait(TRAIT_BIOLUM_COLOUR,get_random_colour(0,75,190))

	set_trait(TRAIT_ENDURANCE,rand(60,100))
	set_trait(TRAIT_YIELD,rand(3,15))
	set_trait(TRAIT_MATURATION,rand(5,15))
	set_trait(TRAIT_PRODUCTION,rand(1,10))

	generate_name()

//Returns a key corresponding to an entry in the global seed list.
/datum/seed/proc/get_mutant_variant()
	if(!mutants || !mutants.len || get_trait(TRAIT_IMMUTABLE) > 0) return 0
	return pick(mutants)

//Mutates the plant overall (randomly).
/datum/seed/proc/mutate(var/degree, var/atom/location)

	if(!degree || get_trait(TRAIT_IMMUTABLE) > 0) return

	location.visible_message("<span class='notice'>\The [display_name] quivers!</span>")

	//This looks like shit, but it's a lot easier to read/change this way.
	var/total_mutations = rand(1,1+degree)
	for(var/i = 0;i<total_mutations;i++)
		switch(rand(0,11))
			if(0) //Plant cancer!
				set_trait(TRAIT_ENDURANCE,get_trait(TRAIT_ENDURANCE)-rand(10,20),null,0)
				location.visible_message("<span class='danger'>\The [display_name] withers rapidly!</span>")
			if(1)
				set_trait(TRAIT_NUTRIENT_CONSUMPTION,get_trait(TRAIT_NUTRIENT_CONSUMPTION)+rand(-(degree*0.1),(degree*0.1)),5,0)
				set_trait(TRAIT_WATER_CONSUMPTION,   get_trait(TRAIT_WATER_CONSUMPTION)   +rand(-degree,degree),50,0)
				set_trait(TRAIT_JUICY,              !get_trait(TRAIT_JUICY))
				set_trait(TRAIT_STINGS,             !get_trait(TRAIT_STINGS))
			if(2)
				set_trait(TRAIT_IDEAL_HEAT,          get_trait(TRAIT_IDEAL_HEAT) +      (rand(-5,5)*degree),800,70)
				set_trait(TRAIT_HEAT_TOLERANCE,      get_trait(TRAIT_HEAT_TOLERANCE) +  (rand(-5,5)*degree),800,70)
				set_trait(TRAIT_LOWKPA_TOLERANCE,    get_trait(TRAIT_LOWKPA_TOLERANCE)+ (rand(-5,5)*degree),80,0)
				set_trait(TRAIT_HIGHKPA_TOLERANCE,   get_trait(TRAIT_HIGHKPA_TOLERANCE)+(rand(-5,5)*degree),500,110)
				set_trait(TRAIT_EXPLOSIVE,1)
			if(3)
				set_trait(TRAIT_IDEAL_LIGHT,         get_trait(TRAIT_IDEAL_LIGHT)+(rand(-1,1)*degree),30,0)
				set_trait(TRAIT_LIGHT_TOLERANCE,     get_trait(TRAIT_LIGHT_TOLERANCE)+(rand(-2,2)*degree),10,0)
			if(4)
				set_trait(TRAIT_TOXINS_TOLERANCE,    get_trait(TRAIT_TOXINS_TOLERANCE)+(rand(-2,2)*degree),10,0)
			if(5)
				set_trait(TRAIT_WEED_TOLERANCE,      get_trait(TRAIT_WEED_TOLERANCE)+(rand(-2,2)*degree),10, 0)
				if(prob(degree*5))
					set_trait(TRAIT_CARNIVOROUS,     get_trait(TRAIT_CARNIVOROUS)+rand(-degree,degree),2, 0)
					if(get_trait(TRAIT_CARNIVOROUS))
						location.visible_message("<span class='notice'>\The [display_name] shudders hungrily.</span>")
			if(6)
				set_trait(TRAIT_WEED_TOLERANCE,      get_trait(TRAIT_WEED_TOLERANCE)+(rand(-2,2)*degree),10, 0)
				if(prob(degree*5))
					set_trait(TRAIT_PARASITE,!get_trait(TRAIT_PARASITE))
			if(7)
				if(get_trait(TRAIT_YIELD) != -1)
					set_trait(TRAIT_YIELD,           get_trait(TRAIT_YIELD)+(rand(-2,2)*degree),10,0)
			if(8)
				set_trait(TRAIT_ENDURANCE,           get_trait(TRAIT_ENDURANCE)+(rand(-5,5)*degree),100,10)
				set_trait(TRAIT_PRODUCTION,          get_trait(TRAIT_PRODUCTION)+(rand(-1,1)*degree),10, 1)
				set_trait(TRAIT_POTENCY,             get_trait(TRAIT_POTENCY)+(rand(-20,20)*degree),200, 0)
				if(prob(degree*5))
					set_trait(TRAIT_SPREAD,          get_trait(TRAIT_SPREAD)+rand(-1,1),2, 0)
					location.visible_message("<span class='notice'>\The [display_name] spasms visibly, shifting in the tray.</span>")
			if(9)
				set_trait(TRAIT_MATURATION,          get_trait(TRAIT_MATURATION)+(rand(-1,1)*degree),30, 0)
				if(prob(degree*5))
					set_trait(TRAIT_HARVEST_REPEAT, !get_trait(TRAIT_HARVEST_REPEAT))
			if(10)
				if(prob(degree*2))
					set_trait(TRAIT_BIOLUM,         !get_trait(TRAIT_BIOLUM))
					if(get_trait(TRAIT_BIOLUM))
						location.visible_message("<span class='notice'>\The [display_name] begins to glow!</span>")
						if(prob(degree*2))
							set_trait(TRAIT_BIOLUM_COLOUR,get_random_colour(0,75,190))
							location.visible_message("<span class='notice'>\The [display_name]'s glow </span><font color='[get_trait(TRAIT_BIOLUM_COLOUR)]'>changes colour</font>!")
					else
						location.visible_message("<span class='notice'>\The [display_name]'s glow dims...</span>")
			if(11)
				set_trait(TRAIT_TELEPORTING,1)

	return

//Mutates a specific trait/set of traits.
/datum/seed/proc/apply_gene(var/datum/plantgene/gene)
	if(!istype(gene) || !gene?.values || get_trait(TRAIT_IMMUTABLE) > 0)
		return
	gene.genetype.modify_seed(gene, src)
	update_growth_stages()

//Place the plant products at the feet of the user.
/datum/seed/proc/harvest(var/mob/user, var/yield_mod, var/harvest_sample, var/force_amount)

	if(!user)
		return FALSE

	if(!force_amount && get_trait(TRAIT_YIELD) == 0 && !harvest_sample)
		if(istype(user)) to_chat(user, "<span class='danger'>You fail to harvest anything useful.</span>")
	else
		if(istype(user)) to_chat(user, "You [harvest_sample ? "take a sample" : "harvest"] from the [display_name].")
		//This may be a new line. Update the global if it is.
		if(name == "new line" || !(name in SSplants.seeds))
			uid = sequential_id(/datum/seed/)
			name = "[uid]"
			SSplants.seeds[name] = src

		if(harvest_sample)
			return new /obj/item/seeds/extracted(get_turf(user), null, src)

		var/total_yield = 0
		if(!isnull(force_amount))
			total_yield = force_amount
		else
			if(get_trait(TRAIT_YIELD) > -1)
				if(isnull(yield_mod) || yield_mod < 1)
					yield_mod = 0
					total_yield = get_trait(TRAIT_YIELD)
				else
					total_yield = get_trait(TRAIT_YIELD) + rand(yield_mod)
				total_yield = max(1,total_yield)

		. = list()
		if(ispath(product_type, /obj/item/stack))
			var/obj/item/stack/stack = product_type
			var/remaining_yield = total_yield
			var/per_stack = initial(stack.max_amount)
			while(remaining_yield > 0)
				var/using_yield = min(remaining_yield, per_stack)
				remaining_yield -= using_yield
				. += new product_type(get_turf(user), using_yield)
		else
			for(var/i = 1 to total_yield)
				var/obj/item/product
				if(ispath(product_type, /obj/item/food))
					product = new product_type(get_turf(user), null, TRUE, src)
					if(allergen_flags)
						var/obj/item/food/food = product
						food.add_allergen_flags(allergen_flags)
				else
					product = new product_type(get_turf(user), null, src)
				. += product

				if(get_trait(TRAIT_PRODUCT_COLOUR) && istype(product, /obj/item/food))
					var/obj/item/food/snack = product
					snack.color = get_trait(TRAIT_PRODUCT_COLOUR)
					snack.filling_color = get_trait(TRAIT_PRODUCT_COLOUR)

				if(mysterious)
					product.name += "?"
					product.desc += " On second thought, something about this one looks strange."

				if(get_trait(TRAIT_BIOLUM))
					var/clr
					if(get_trait(TRAIT_BIOLUM_COLOUR))
						clr = get_trait(TRAIT_BIOLUM_COLOUR)
					product.set_light(get_trait(TRAIT_BIOLUM), l_color = clr)

				//Handle spawning in living, mobile products.
				if(isliving(product))
					product.visible_message("<span class='notice'>The pod disgorges [product]!</span>")
					handle_living_product(product)
					if(istype(product,/mob/living/simple_animal/mushroom)) // Gross.
						var/mob/living/simple_animal/mushroom/mush = product
						mush.seed = src

// When the seed in this machine mutates/is modified, the tray seed value
// is set to a new datum copied from the original. This datum won't actually
// be put into the global datum list until the product is harvested, though.
/datum/seed/proc/diverge(var/modified)

	if(get_trait(TRAIT_IMMUTABLE) > 0)
		return

	//Set up some basic information.
	var/datum/seed/new_seed = new
	new_seed.name             = "new line"
	new_seed.uid              = 0
	new_seed.roundstart       = 0
	new_seed.can_self_harvest = can_self_harvest
	new_seed.grown_tag        = grown_tag
	new_seed.trash_type       = trash_type
	new_seed.product_type     = product_type

	//Copy over everything else.
	if(mutants)        new_seed.mutants = mutants.Copy()
	if(chems)          new_seed.chems = chems.Copy()
	if(consume_gasses) new_seed.consume_gasses = consume_gasses.Copy()
	if(exude_gasses)   new_seed.exude_gasses = exude_gasses.Copy()

	new_seed.product_name = "[(roundstart ? "[(modified ? "modified" : "mutant")] " : "")][product_name]"
	new_seed.display_name = "[(roundstart ? "[(modified ? "modified" : "mutant")] " : "")][display_name]"
	new_seed.seed_noun    = seed_noun
	new_seed._traits      = deepCopyList(_traits)
	new_seed.update_growth_stages()
	return new_seed

/datum/seed/proc/update_growth_stages()
	if(get_trait(TRAIT_PLANT_ICON))
		growth_stages = SSplants.plant_sprites[get_trait(TRAIT_PLANT_ICON)]
	else
		growth_stages = 0

/datum/seed/proc/get_growth_type()
	if(get_trait(TRAIT_SPREAD) == 2)
		switch(seed_noun)
			if(SEED_NOUN_CUTTINGS)
				return GROWTH_WORMS
			if(SEED_NOUN_NODES)
				return GROWTH_BIOMASS
			if(SEED_NOUN_SPORES)
				return GROWTH_MOLD
			else
				return GROWTH_VINES
	return 0

/datum/seed/proc/get_growth_stage_overlay(growth_stage)
	var/plant_icon = get_trait(TRAIT_PLANT_ICON)
	var/image/res = image('icons/obj/hydroponics/hydroponics_growing.dmi', "[plant_icon]-[growth_stage]")
	if(get_growth_type())
		res.icon_state = "[get_growth_type()]-[growth_stage]"
	else
		res.icon_state = "[plant_icon]-[growth_stage]"

	if(get_growth_type())
		res.icon = 'icons/obj/hydroponics/hydroponics_vines.dmi'

	res.color = get_trait(TRAIT_PLANT_COLOUR)

	if(get_trait(TRAIT_LARGE))
		res.icon = 'icons/obj/hydroponics/hydroponics_large.dmi'
		res.pixel_x = -8
		res.pixel_y = -16

	var/leaves = get_trait(TRAIT_LEAVES_COLOUR)
	if(leaves)
		var/image/I = image(res.icon, "[plant_icon]-[growth_stage]-leaves")
		I.color = leaves
		I.appearance_flags = RESET_COLOR
		res.overlays += I

	return res

/datum/seed/PopulateClone(datum/seed/clone)
	clone = ..()
	//!! - Cloning means having an independent working copy, so leave its unique uid - !!
	clone.roundstart       = FALSE
	clone.name             = "[product_name][(roundstart ? " strain #[clone.uid]" : "")]"
	clone.product_name     = clone.name
	clone.display_name     = "[display_name][(roundstart ? " strain #[clone.uid]" : "")]"
	clone.seed_noun        = seed_noun

	//Seed traits
	clone._traits          = deepCopyList(_traits)
	clone.mutants          = mutants?.Copy()
	clone.chems            = chems?.Copy()
	clone.consume_gasses   = consume_gasses?.Copy()
	clone.exude_gasses     = exude_gasses?.Copy()

	//Appearence
	clone.growth_stages    = growth_stages
	clone.force_layer      = force_layer
	clone.splat_type       = splat_type

	//things that probably should be traits
	clone.mysterious       = mysterious
	clone.req_CO2_moles    = req_CO2_moles
	clone.hydrotray_only   = hydrotray_only
	clone.can_self_harvest = can_self_harvest

	//misc data
	clone.grown_tag        = grown_tag
	clone.trash_type       = trash_type
	clone.product_type     = product_type
	clone.base_seed_value  = base_seed_value
	clone.scannable_result = scannable_result

	clone.update_growth_stages()
	return clone

/datum/seed/proc/show_slice_message(mob/user, obj/item/tool, obj/item/food/grown/sliced)
	if(slice_product == /obj/item/food/processed_grown/chopped)
		sliced.visible_message(SPAN_NOTICE("\The [user] quickly chops up \the [sliced] with \the [tool]."))
	else if(slice_product == /obj/item/food/processed_grown/crushed)
		sliced.visible_message(SPAN_NOTICE("\The [user] methodically crushes \the [sliced] with the handle of \the [tool]."))
	else if(slice_product == /obj/item/food/processed_grown/sticks)
		sliced.visible_message(SPAN_NOTICE("\The [user] neatly slices \the [sliced] into sticks with \the [tool]."))
	else
		return null
	return TRUE

/datum/seed/proc/show_slice_message_poor(mob/user, obj/item/tool, obj/item/food/grown/sliced)
	if(slice_product == /obj/item/food/processed_grown/chopped)
		sliced.visible_message(SPAN_NOTICE("\The [user] crudely chops \the [sliced] with \the [tool]."))
	else if(slice_product == /obj/item/food/processed_grown/crushed)
		sliced.visible_message(SPAN_NOTICE("\The [user] messily crushes \the [sliced] with the handle of \the [tool]."))
	else if(slice_product == /obj/item/food/processed_grown/sticks)
		sliced.visible_message(SPAN_NOTICE("\The [user] roughly slices \the [sliced] into sticks with \the [tool]."))
	else
		return null
	return TRUE
