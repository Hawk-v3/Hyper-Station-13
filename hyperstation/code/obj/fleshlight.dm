//Hyperstation 13 fleshlight
//Humbley request this doesnt get ported to other code bases, we strive to make things unique on our server and we dont have alot of coders
//but if you absolutely must. please give us some credit~ <3
//made by quotefox

/obj/item/fleshlight
	name = "fleshlight"
	desc = "A sex toy disguised as a flashlight, used to stimulate someones penis, complete with colour changing sleeve."
	icon = 'hyperstation/icons/obj/fleshlight.dmi'
	icon_state = "fleshlight_base"
	item_state = "fleshlight"
	w_class = WEIGHT_CLASS_SMALL
	var/sleevecolor = "#ffcbd4" //pink
	price = 8
	var/mutable_appearance/sleeve
	var/inuse = 0

/obj/item/fleshlight/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Alt-Click \the [src.name] to customize it.</span>"

/obj/item/fleshlight/Initialize()
	. = ..()
	sleeve = mutable_appearance('hyperstation/icons/obj/fleshlight.dmi', "vagina")
	sleeve.color = sleevecolor
	add_overlay(sleeve)

/obj/item/fleshlight/AltClick(mob/user)
	. = ..()
	var/style = input(usr, "Choose style", "Customize Fleshlight", "vagina") in list("vagina", "anus")
	var/new_color = input(user, "Choose color.", "Customize Fleshlight", sleevecolor) as color|null
	if(new_color)
		cut_overlays()
		sleeve = mutable_appearance('hyperstation/icons/obj/fleshlight.dmi', style)
		sleevecolor = new_color
		sleeve.color = new_color
		add_overlay(sleeve)
	return TRUE

/obj/item/fleshlight/attack(mob/living/carbon/C, mob/living/user)
	var/obj/item/organ/genital/penis/P = C.getorganslot("penis")
	if(inuse == 1) //just to stop stacking and causing people to cum instantly
		return
	if(P&&P.is_exposed())
		inuse = 1
		if(!(C == user)) //if we are targeting someone else.
			C.visible_message("<span class='userlove'>[user] is trying to use [src] on [C]'s penis.</span>", "<span class='userlove'>[user] is trying to use [src] on your penis.</span>")
		if(!do_mob(user, C, 3 SECONDS)) //3 second delay
			inuse = 0
			return
		//checked if not used on yourself, if not, carry on.
		playsound(src, 'sound/lewd/slaps.ogg', 30, 1, -1) //slapping sound
		inuse = 0
		if(!(C == user)) //lewd flavour text
			C.visible_message("<span class='userlove'>[user] pumps [src] on [C]'s penis.</span>", "<span class='userlove'>[user] pumps [src] up and down on your penis.</span>")
		else
			user.visible_message("<span class='userlove'>[user] pumps [src] on their penis.</span>", "<span class='userlove'>You pump the fleshlight on your penis.</span>")
		if(prob(30)) //30% chance to make them moan.
			C.emote("moan")
		C.do_jitter_animation()
		C.adjustArousalLoss(20) //make the target more aroused.
		if(C.can_orgasm() && ishuman(C))
			var/mob/living/carbon/human/user_human = C
			user_human.mob_climax_outside(P, mb_time=0) // instant, because we already did a warmup
		return
	else
		to_chat(user, "<span class='notice'>You don't see anywhere to use this on.</span>")
	inuse = 0
	..()


//Hyperstation 13 portal fleshlight
//kinky!
/obj/item/portallight
	name = "portal fleshlight"
	desc = "A silver love(TM) fleshlight, used to stimulate someones penis, with bluespace tech that allows lovers to hump at a distance."
	icon = 'hyperstation/icons/obj/fleshlight.dmi'
	icon_state = "unpaired"
	item_state = "fleshlight"
	w_class = WEIGHT_CLASS_SMALL
	var/partnercolor = "#ffcbd4"
	var/partnerbase = "normal"
	var/partnerorgan = "portal_vag"
	price = 20
	var/mutable_appearance/sleeve
	var/mutable_appearance/organ
	var/inuse = 0
	var/paired = 0
	var/obj/item/portalunderwear
	var/useable = FALSE

/obj/item/portallight/examine(mob/user)
	. = ..()
	if(!portalunderwear)
		. += "<span class='notice'>The device is unpaired, to pair, swipe against a pair of portal panties. </span>"
	else
		. += "<span class='notice'>The device is paired, and awaiting input. </span>"

/obj/item/portallight/attack(mob/living/carbon/user, mob/living/holder) 
	if(inuse) //just to stop stacking and causing people to cum instantly
		return
	if(!UpdateUsability())
		to_chat(holder, "<span class='notice'>\The [src] appears to be currently unusable.</span>")
		return
	var/option = "Fuck"
	if(user == holder)
		option = input(usr, "Choose action", "Portal Fleshlight", "Fuck") in list("Fuck", "Lick", "Touch")
	var/obj/item/organ/genital/target_genital = portalunderwear.loc
	var/mob/living/carbon/human/target = target_genital.owner
	var/obj/item/organ/genital/penis/P = user.getorganslot("penis")
	if(option == "Fuck" && !P.is_exposed())
		to_chat(holder, "<span class='notice'>You don't see anywhere to use this on.</span>")
		return
	/* 
	WARMUP START - prevents spam/instant climax 
	*/
	inuse = TRUE
	if(user != holder)
		user.visible_message("<span class='userlove'>[holder] is trying to use [src] on [user]'s penis.</span>",\
			"<span class='userlove'>[holder] is trying to use [src] on your penis.</span>")
	if(!do_mob(holder, user, 3 SECONDS))
		inuse = FALSE
		return
	inuse = FALSE
	/* 
	WARMUP END -	proceed with the action 
	*/
	switch(option)
		if("Fuck")
			playsound(src, 'sound/lewd/slaps.ogg', 30, 1, -1)
			if(user == holder)
				holder.visible_message("<span class='userlove'>[holder] pumps [src] on their penis.</span>",
					"<span class='userlove'>You pump the fleshlight on your penis.</span>")
			else
				user.visible_message("<span class='userlove'>[holder] pumps [src] on [user]'s penis.</span>",\
					"<span class='userlove'>[holder] pumps [src] up and down on your penis.</span>")
			to_chat(target, "<span class='love'>You feel a [P.length] inch, [P.shape] shaped penis pumping through the portal into your [target_genital.name].</span>")
			if(prob(30))
				user.emote("moan")
			user.adjustArousalLoss(20)
			target.adjustArousalLoss(20)
			target.do_jitter_animation()
			if(target.can_orgasm() && prob(5)) 
				target.mob_climax_outside(target_genital, spillage=target_genital.is_exposed())
			if(user.can_orgasm())
				var/mob/living/carbon/human/O = user
				var/impreg_chance = target_genital.name == "vagina" && !P.condom && !P.sounding
				if(O.mob_climax_in_partner(P, target, spillage=FALSE, remote=TRUE) && impreg_chance)
					target.impregnate(by=O)
		if("Lick")
			holder.visible_message("<span class='userlove'>[holder] licks into [src].</span>",\
				"<span class='userlove'>You lick into [src].</span>")
			to_chat(target, "<span class='love'>You feel a tongue lick you through the portal against your [target_genital.name].</span>")
			target.adjustArousalLoss(10)
		if("Touch")
			holder.visible_message("<span class='userlove'>[holder] touches softly against [src].</span>",\
				"<span class='userlove'>You touch softly on [src].</span>")
			to_chat(target, "<span class='love'>You feel someone touching your [target_genital.name] through the portal.</span>")
			target.adjustArousalLoss(5)
	if(prob(30))
		target.emote("moan")
	..()

/obj/item/portallight/proc/updatesleeve()
	//get their looks and vagina colour!
	cut_overlays()
	if(!UpdateUsability())
		return
	var/obj/item/organ/genital/G = portalunderwear.loc
	var/mob/living/carbon/human/H = G.owner // H is verified by UpdateUsability()
	var/sleeve_species = "normal"
	switch(H.dna.species.name)
		if("Lizardperson")
			sleeve_species = "lizard"
		if("Slimeperson")
			sleeve_species = "slime"
		if("Avian")
			sleeve_species = "avian"
	sleeve = mutable_appearance('hyperstation/icons/obj/fleshlight.dmi', "portal_sleeve_[sleeve_species]")
	sleeve.color = "#" + H.dna.features["mcolor"]
	add_overlay(sleeve)
	if(G.name == "vagina")
		organ = mutable_appearance('hyperstation/icons/obj/fleshlight.dmi', "portal_vag")
		organ.color = portalunderwear.loc.color
	if(G.name == "anus")
		organ = mutable_appearance('hyperstation/icons/obj/fleshlight.dmi', "portal_anus")
		organ.color = "#" + H.dna.features["mcolor"]
	add_overlay(organ)

/obj/item/portallight/proc/UpdateUsability()
	var/useable = FALSE
	if(portalunderwear && istype(portalunderwear.loc, /obj/item/organ/genital))
		var/obj/item/organ/genital/loc_genitals = portalunderwear.loc
		if(loc_genitals.owner && ishuman(loc_genitals.owner))
			useable = TRUE
	src.useable = useable
	return useable


//Hyperstation 13 portal underwear
//can be attached to vagina or anus, just like the vibrator, still requires pairing with the portallight
/obj/item/portalpanties
	name = "portal panties"
	desc = "A silver love(TM) pair of portal underwear, with bluespace tech allows lovers to hump at a distance. Needs to be paired with a portal fleshlight before use."
	icon = 'hyperstation/icons/obj/fleshlight.dmi'
	icon_state = "portalpanties"
	item_state = "fleshlight"
	w_class = WEIGHT_CLASS_SMALL
	var/obj/item/portallight
	var/attached = FALSE
	var/shapetype = "vagina"

/obj/item/portalpanties/examine(mob/user)
	. = ..()
	if(!portallight)
		. += "<span class='notice'>The device is unpaired, to pair, swipe the fleshlight against this pair of portal panties(TM). </span>"
	else
		. += "<span class='notice'>The device is paired, and awaiting attachment. </span>"

/obj/item/portalpanties/attackby(obj/item/I, mob/living/user) //pairing
	if(istype(I, /obj/item/portallight))
		var/obj/item/portallight/P = I
		if(!P.portalunderwear) //make sure it aint linked to someone else
			portallight = P //pair the fleshlight
			P.portalunderwear = src //pair the panties on the fleshlight.
			P.icon_state = "paired" //we are paired!
			playsound(src, 'sound/machines/ping.ogg', 50, FALSE)
			to_chat(user, "<span class='notice'>[P] has been linked up successfully.</span>")
		else
			to_chat(user, "<span class='notice'>[P] has already been linked to another pair of underwear.</span>")
	else
		..() //just allows people to hit it with other objects, if they so wished.

/obj/item/portalpanties/attack(mob/living/carbon/C, mob/living/user)
	if(!portallight) //we arent paired yet! noobie trap, let them know.
		to_chat(user, "<span class='warning'>[src] can only be attached once paired with a portal fleshlight.</span>")
		return
	var/obj/item/organ/genital/picked_organ
	var/mob/living/carbon/human/S = user
	var/mob/living/carbon/human/T = C
	picked_organ = S.target_genitals(T)
	if(picked_organ)
		C.visible_message("<span class='warning'>[user] is trying to attach [src] to [T]!</span>",\
						"<span class='warning'>[user] is trying to put [src] on you!</span>")
		if(!do_mob(user, C, 3 SECONDS))//warn them and have a delay of 5 seconds to apply.
			return
		if((picked_organ.name == "vagina")||(picked_organ.name == "anus")) //only fits on a vagina or anus
			src.shapetype = picked_organ.name
			if(!picked_organ.equipment)
				to_chat(user, "<span class='love'>You wrap [src] around [T]'s [picked_organ.name].</span>")
			else
				to_chat(user, "<span class='notice'>They already have [picked_organ.equipment.name] there.</span>")
				return
			if(!user.transferItemToLoc(src, picked_organ)) //check if you can put it in
				return
			src.attached = TRUE
			picked_organ.equipment = src
			var/obj/item/portallight/P = portallight
			//now we need to send what they look like, but saddly if the person changes colour for what ever reason, it wont update. but dont tell people shh.
			if(P) //just to make sure
				P.updatesleeve()
		else
			to_chat(user, "<span class='warning'>[src] can only be attached to a vagina or anus.</span>")
			return
	else
		to_chat(user, "<span class='notice'>You don't see anywhere to attach this.</span>")

/obj/item/portalpanties/proc/remove() //if taken off update it.
	if(portallight)
		var/obj/item/portallight/P = portallight
		P.updatesleeve()


/obj/item/storage/box/portallight
	name =  "Portal Fleshlight and Underwear"
	icon = 'hyperstation/icons/obj/fleshlight.dmi'
	desc = "A small silver box with Silver Love Co embossed."
	icon_state = "box"
	price = 15

// portal fleshlight box
/obj/item/storage/box/portallight/PopulateContents()
	new /obj/item/portallight/(src)
	new /obj/item/portalpanties/(src)
	new /obj/item/paper/fluff/portallight(src)

/obj/item/paper/fluff/portallight
	name = "Portal Fleshlight Instructions"
	info = "Thank you for purchasing the Silver Love Portal Fleshlight!<BR>To use, simply register your new portal fleshlight with the provided underwear to link them together. The ask your lover to wear the underwear.<BR>Have fun lovers,<BR><BR>Wilhelmina Steiner."
