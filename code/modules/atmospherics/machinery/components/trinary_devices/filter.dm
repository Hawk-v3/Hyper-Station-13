/obj/machinery/atmospherics/components/trinary/filter
	icon_state = "filter_off"
	density = FALSE

	name = "gas filter"
	desc = "Very useful for filtering gasses."

	can_unwrench = TRUE

	var/transfer_rate = MAX_TRANSFER_RATE
	var/filter_type = null
	var/frequency = 0
	var/datum/radio_frequency/radio_connection

	construction_type = /obj/item/pipe/trinary/flippable
	pipe_state = "filter"

/obj/machinery/atmospherics/components/trinary/filter/examine(mob/user)
	. = ..()
	. += "<span class='notice'>You can hold <b>Ctrl</b> and click on it to toggle it on and off.</span>"
	. += "<span class='notice'>You can hold <b>Alt</b> and click on it to maximize its flow rate.</span>"

/obj/machinery/atmospherics/components/trinary/filter/CtrlClick(mob/user)
	var/area/A = get_area(src)
	var/turf/T = get_turf(src)
	if(user.canUseTopic(src, BE_CLOSE, FALSE,))
		on = !on
		update_icon()
		investigate_log("Filter, [src.name], turned on by [key_name(usr)] at [x], [y], [z], [A]", INVESTIGATE_ATMOS)
		message_admins("Filter, [src.name], turned [on ? "on" : "off"] by [ADMIN_LOOKUPFLW(usr)] at [ADMIN_COORDJMP(T)], [A]")
		return ..()

/obj/machinery/atmospherics/components/trinary/filter/AltClick(mob/user)
	. = ..()
	var/area/A = get_area(src)
	var/turf/T = get_turf(src)
	if(user.canUseTopic(src, BE_CLOSE, FALSE,))
		transfer_rate = MAX_TRANSFER_RATE
		to_chat(user,"<span class='notice'>You maximize the flow rate on the [src].</span>")
		investigate_log("Filter, [src.name], was maximized by [key_name(usr)] at [x], [y], [z], [A]", INVESTIGATE_ATMOS)
		message_admins("Filter, [src.name], was maximized by [ADMIN_LOOKUPFLW(usr)] at [ADMIN_COORDJMP(T)], [A]")
		return TRUE

/obj/machinery/atmospherics/components/trinary/filter/proc/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	if(frequency)
		radio_connection = SSradio.add_object(src, frequency, RADIO_ATMOSIA)

/obj/machinery/atmospherics/components/trinary/filter/Destroy()
	SSradio.remove_object(src,frequency)
	return ..()

/obj/machinery/atmospherics/components/trinary/filter/update_icon()
	cut_overlays()
	for(var/direction in GLOB.cardinals)
		if(!(direction & initialize_directions))
			continue
		var/obj/machinery/atmospherics/node = findConnecting(direction)

		var/image/cap
		if(node)
			cap = getpipeimage(icon, "cap", direction, node.pipe_color, piping_layer = piping_layer)
		else
			cap = getpipeimage(icon, "cap", direction, piping_layer = piping_layer)

		add_overlay(cap)

	return ..()

/obj/machinery/atmospherics/components/trinary/filter/update_icon_nopipes()
	var/on_state = on && nodes[1] && nodes[2] && nodes[3] && is_operational()
	icon_state = "filter_[on_state ? "on" : "off"][flipped ? "_f" : ""]"

/obj/machinery/atmospherics/components/trinary/filter/power_change()
	var/old_stat = stat
	..()
	if(stat != old_stat)
		update_icon()

/obj/machinery/atmospherics/components/trinary/filter/process_atmos()
	..()
	if(!on || !(nodes[1] && nodes[2] && nodes[3]) || !is_operational())
		return

	var/datum/gas_mixture/air1 = airs[1]
	var/datum/gas_mixture/air2 = airs[2]
	var/datum/gas_mixture/air3 = airs[3]

	var/input_starting_pressure = air1.return_pressure()

	if((input_starting_pressure < 0.01))
		return

	//Calculate necessary moles to transfer using PV=nRT

	var/transfer_ratio = transfer_rate/air1.volume

	//Actually transfer the gas

	if(transfer_ratio > 0)
		var/datum/gas_mixture/removed = air1.remove_ratio(transfer_ratio)

		if(!removed)
			return

		var/filtering = TRUE
		if(!ispath(filter_type))
			if(filter_type)
				filter_type = gas_id2path(filter_type) //support for mappers so they don't need to type out paths
			else
				filtering = FALSE

		if(filtering && removed.gases[filter_type])
			var/datum/gas_mixture/filtered_out = new

			filtered_out.temperature = removed.temperature
			filtered_out.gases[filter_type] = removed.gases[filter_type]

			removed.gases[filter_type] = 0
			GAS_GARBAGE_COLLECT(removed.gases)

			var/datum/gas_mixture/target = (air2.return_pressure() < 9000 ? air2 : air1)
			target.merge(filtered_out)

		if(air3.return_pressure() <= 9000)
			air3.merge(removed)
		else
			air1.merge(removed) // essentially just leaving it in

	update_parents()

/obj/machinery/atmospherics/components/trinary/filter/atmosinit()
	set_frequency(frequency)
	return ..()

/obj/machinery/atmospherics/components/trinary/filter/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = FALSE, \
																	datum/tgui/master_ui = null, datum/tgui_state/state = GLOB.tgui_default_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "AtmosFilter", name, 475, 185, master_ui, state)
		ui.open()

/obj/machinery/atmospherics/components/trinary/filter/ui_data()
	var/data = list()
	data["on"] = on
	data["rate"] = round(transfer_rate)
	data["max_rate"] = round(MAX_TRANSFER_RATE)

	data["filter_types"] = list()
	data["filter_types"] += list(list("name" = "Nothing", "path" = "", "selected" = !filter_type))
	for(var/path in GLOB.meta_gas_ids)
		data["filter_types"] += list(list("name" = GLOB.meta_gas_names[path], "id" = GLOB.meta_gas_ids[path], "selected" = (path == gas_id2path(filter_type))))

	return data

/obj/machinery/atmospherics/components/trinary/filter/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("power")
			on = !on
			investigate_log("was turned [on ? "on" : "off"] by [key_name(usr)]", INVESTIGATE_ATMOS)
			. = TRUE
		if("rate")
			var/rate = params["rate"]
			if(rate == "max")
				rate = MAX_TRANSFER_RATE
				. = TRUE
			else if(rate == "input")
				rate = input("New transfer rate (0-[MAX_TRANSFER_RATE] L/s):", name, transfer_rate) as num|null
				if(!isnull(rate) && !..())
					. = TRUE
			else if(text2num(rate) != null)
				rate = text2num(rate)
				. = TRUE
			if(.)
				transfer_rate = CLAMP(rate, 0, MAX_TRANSFER_RATE)
				investigate_log("was set to [transfer_rate] L/s by [key_name(usr)]", INVESTIGATE_ATMOS)
		if("filter")
			filter_type = null
			var/filter_name = "nothing"
			var/gas = gas_id2path(params["mode"])
			if(gas in GLOB.meta_gas_names)
				filter_type = gas
				filter_name	= GLOB.meta_gas_names[gas]
			investigate_log("was set to filter [filter_name] by [key_name(usr)]", INVESTIGATE_ATMOS)
			. = TRUE
	update_icon()

/obj/machinery/atmospherics/components/trinary/filter/can_unwrench(mob/user)
	. = ..()
	if(. && on && is_operational())
		to_chat(user, "<span class='warning'>You cannot unwrench [src], turn it off first!</span>")
		return FALSE

// Mapping

/obj/machinery/atmospherics/components/trinary/filter/layer1
	piping_layer = 1
	icon_state = "filter_off_map-1"
/obj/machinery/atmospherics/components/trinary/filter/layer3
	piping_layer = 3
	icon_state = "filter_off_map-3"

/obj/machinery/atmospherics/components/trinary/filter/on
	on = TRUE
	icon_state = "filter_on"

/obj/machinery/atmospherics/components/trinary/filter/on/layer1
	piping_layer = 1
	icon_state = "filter_on_map-1"
/obj/machinery/atmospherics/components/trinary/filter/on/layer3
	piping_layer = 3
	icon_state = "filter_on_map-3"

/obj/machinery/atmospherics/components/trinary/filter/flipped
	icon_state = "filter_off_f"
	flipped = TRUE

/obj/machinery/atmospherics/components/trinary/filter/flipped/layer1
	piping_layer = 1
	icon_state = "filter_off_f_map-1"
/obj/machinery/atmospherics/components/trinary/filter/flipped/layer3
	piping_layer = 3
	icon_state = "filter_off_f_map-3"

/obj/machinery/atmospherics/components/trinary/filter/flipped/on
	on = TRUE
	icon_state = "filter_on_f"

/obj/machinery/atmospherics/components/trinary/filter/flipped/on/layer1
	piping_layer = 1
	icon_state = "filter_on_f_map-1"
/obj/machinery/atmospherics/components/trinary/filter/flipped/on/layer3
	piping_layer = 3
	icon_state = "filter_on_f_map-3"

/obj/machinery/atmospherics/components/trinary/filter/atmos //Used for atmos waste loops
	on = TRUE
	icon_state = "filter_on"
/obj/machinery/atmospherics/components/trinary/filter/atmos/n2
	name = "nitrogen filter"
	filter_type = "n2"
/obj/machinery/atmospherics/components/trinary/filter/atmos/o2
	name = "oxygen filter"
	filter_type = "o2"
/obj/machinery/atmospherics/components/trinary/filter/atmos/co2
	name = "carbon dioxide filter"
	filter_type = "co2"
/obj/machinery/atmospherics/components/trinary/filter/atmos/n2o
	name = "nitrous oxide filter"
	filter_type = "n2o"
/obj/machinery/atmospherics/components/trinary/filter/atmos/plasma
	name = "plasma filter"
	filter_type = "plasma"

/obj/machinery/atmospherics/components/trinary/filter/atmos/flipped //This feels wrong, I know
	icon_state = "filter_on_f"
	flipped = TRUE
/obj/machinery/atmospherics/components/trinary/filter/atmos/flipped/n2
	name = "nitrogen filter"
	filter_type = "n2"
/obj/machinery/atmospherics/components/trinary/filter/atmos/flipped/o2
	name = "oxygen filter"
	filter_type = "o2"
/obj/machinery/atmospherics/components/trinary/filter/atmos/flipped/co2
	name = "carbon dioxide filter"
	filter_type = "co2"
/obj/machinery/atmospherics/components/trinary/filter/atmos/flipped/n2o
	name = "nitrous oxide filter"
	filter_type = "n2o"
/obj/machinery/atmospherics/components/trinary/filter/atmos/flipped/plasma
	name = "plasma filter"
	filter_type = "plasma"

// These two filter types have critical_machine flagged to on and thus causes the area they are in to be exempt from the Grid Check event.

/obj/machinery/atmospherics/components/trinary/filter/critical
	critical_machine = TRUE

/obj/machinery/atmospherics/components/trinary/filter/flipped/critical
	critical_machine = TRUE