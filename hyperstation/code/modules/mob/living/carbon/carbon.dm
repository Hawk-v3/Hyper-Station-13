/mob/living/carbon
	var/total_pain = 0
	var/pain_effect = 0

//pain
/mob/living/carbon/adjustPainLoss(amount, updating_health = TRUE, forced = FALSE, affected_zone = BODY_ZONE_CHEST)
	if(!forced && (status_flags & GODMODE))
		return FALSE
	apply_damage(amount > 0 ? amount : amount, PAIN, affected_zone)
	return amount

/mob/living/carbon/handle_status_effects()
	..()
	handle_pain()

/mob/living/carbon/proc/handle_pain()
	var/pain_amount = 0
	pain_effect += 1

	//build up pain in the system from all your limbs and natrually heal pain if its attached to a live body.
	for(var/X in bodyparts)
		var/obj/item/bodypart/BP = X
		pain_amount += BP.pain_dam

		var/pain_target = (BP.brute_dam + BP.burn_dam)*0.8
		//natural healing of pain, capped at current damage * 0.8, if the pain is lower, slowly bring up the pain. this will let people "get used, to it."
		if (BP.pain_dam > (pain_target))
			BP.pain_dam -= 1 //bring down to the pain_level.
		else
			BP.pain_dam += 1 //slowly bring pain back, from pain killers.

		//just make sure its zero'd
		if (BP.pain_dam < 0)
			BP.pain_dam = 0
			continue //dont need to do the rest, your fine.

		if (BP.pain_dam && pain_effect > 10 && (stat != DEAD))
			var pain_level = (round(BP.pain_dam / 10))
			if (pain_level <= 4)
				switch(pain_level) //for every 10 points of damage minor -> major
					if(1)//start at 10 just so it doesnt get annoying with micro damage
						to_chat(src, "<span class='warning'>You feel minor pain in your [BP.name].</span>")
					if(2)
						to_chat(src, "<span class='warning'>You feel pain in your [BP.name].</span>")
					if(3)
						to_chat(src, "<span class='warning'>You feel severe pain in your [BP.name].</span>")
					if(4)
						to_chat(src, "<span class='warning'>You feel overwhelming pain in your [BP.name].</span>")
						jitteriness += 2
						stuttering += 2

			else //god damn.. thats alot of pain owe.
				to_chat(src, "<span class='warning'>You cant handle the pain in your [BP.name].</span>")
				jitteriness += 2
				stuttering += 2

	total_pain = pain_amount

	//handle onscreen alert
	if (pain_effect == 5) //alittle early to give you a 5 second warning
		switch(total_pain)
			if(-100 to 29)
				clear_alert("pain")
			if(30 to 79)
				throw_alert("pain", /obj/screen/alert/pain)
			if(80 to 200)
				throw_alert("pain", /obj/screen/alert/painmajor)

	if (pain_effect > 10)
		pain_effect = 0 //reset the timer 10 seconds.
		if(stat != DEAD)
			//status effects for pain..
			if (total_pain > 50 && total_pain < 80)
				to_chat(src, "<span class='warning'>You cant handle the pain...</span>")
				if(prob(20))
					emote("scream")
				jitteriness += 3 //shake
				stuttering += 35	 //stutter words, your in pain bro.

			if (total_pain > 80) //your in trouble. fainting..
				to_chat(src, "<span class='warning'>You cant handle the intense pain...</span>")
				if(prob(20)) //chance of fainting..
					visible_message("<span class='danger'>[src] collapses!</span>")
					Unconscious(100)
				jitteriness += 3 //shake
				stuttering += 3	 //stutter words

	if (total_pain > 110 && stat != DEAD) //taking 77 all damage at once from full health, will put you into shock and kill you. This cant be achived with chip damage (or fist fights), because youll die before you reach this pain level.
		to_chat(src, "<span class='warning'>You give into the pain...</span>")
		visible_message("<span class='danger'>[src] goes into shock!</span>")
		death() // kill.



//HS Pain heal
/mob/living/carbon/adjustPainLoss(amount, updating_health = TRUE, forced = FALSE)
	if (!forced && amount < 0 && HAS_TRAIT(src,TRAIT_NONATURALHEAL))
		return FALSE
	if(!forced && (status_flags & GODMODE))
		return FALSE

	//all attached limbs get pain damage
	for(var/X in bodyparts)
		var/obj/item/bodypart/BP = X
		BP.pain_dam += amount

	return amount