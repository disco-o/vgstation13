
/obj/machinery/replicator
	name = "alien machine"
	desc = "It's some kind of pod with strange wires and gadgets all over it."
	icon = 'icons/obj/xenoarchaeology.dmi'
	icon_state = "borgcharger0(old)"
	density = 1

	idle_power_usage = 100
	active_power_usage = 1000
	use_power = 1

	machine_flags = WRENCHMOVE

	var/spawn_progress = 0
	var/max_spawn_ticks = 5
	var/list/construction = list()
	var/list/spawning_types = list()

/obj/machinery/replicator/Destroy()
	new /datum/artifact_postmortem_data(src)
	..()

/obj/machinery/replicator/New()
	..()

	var/list/viables = list(
		//Medical
		/obj/item/weapon/reagent_containers/glass/bottle/chloralhydrate,
		/obj/item/roller,
		/obj/item/device/healthanalyzer,
		/obj/item/weapon/reagent_containers/glass/bottle/toxin,
		/obj/item/weapon/reagent_containers/syringe/inaprovaline,
		/obj/item/weapon/reagent_containers/glass/bottle/capsaicin,
		/obj/item/weapon/reagent_containers/glass/bottle/frostoil,
		/obj/item/weapon/reagent_containers/glass/beaker/large/erlenmeyer,
		/obj/item/device/reagent_scanner/adv,

		//Robots (and the mimic)
		/mob/living/simple_animal/hostile/mimic,
		/mob/living/simple_animal/hostile/viscerator,
		/mob/living/simple_animal/hostile/hivebot,
	//	/obj/machinery/bot/cleanbot/roomba, //UNLEASH THE HORDE
	//	/obj/machinery/bot/secbot, //Probably a bad idea.

		//Tools
		/obj/item/device/analyzer,
		/obj/item/device/flash,
		/obj/item/device/multitool,
		/obj/item/device/camera,
		/obj/item/tool/crowbar/red,
		/obj/item/weapon/lighter/zippo,
		/obj/item/weapon/pickaxe,
		/obj/item/weapon/pickaxe/shovel,
		/obj/item/stack/cable_coil/random,
		/obj/item/weapon/soap/,

		//Weapons and Security Gear
		/obj/item/weapon/kitchen/utensil/knife/large/butch,
		/obj/item/weapon/kitchen/utensil/knife/large,
		/obj/item/clothing/gloves/knuckles,
		/obj/item/weapon/handcuffs,
		/obj/item/weapon/hatchet,
		/obj/item/device/hailer,
		/obj/item/weapon/storage/fancy/donut_box,
		/obj/item/clothing/accessory/holomap_chip, //Too far?

		//Toys
		/obj/item/toy/sword,
		/obj/item/toy/snappop,
		/obj/item/toy/gun,
		/obj/item/weapon/beach_ball,

		//Grenades
		/obj/item/weapon/grenade/chem_grenade/cleaner,
		/obj/item/weapon/grenade/chem_grenade/metalfoam,
		/obj/item/weapon/grenade/flashbang,		//Pretty powerful
		/obj/item/weapon/grenade/smokebomb,
		/obj/item/weapon/grenade/chem_grenade/wind,

		//Clothing
		/obj/item/clothing/glasses/sunglasses,
		/obj/item/clothing/gloves/anchor_arms,
		/obj/item/clothing/accessory/storage/webbing/paramed,	//Pretty powerful

		//Other
		/obj/structure/closet/acloset,
		/obj/item/beacon,
		/obj/item/device/paicard,
		/obj/item/weapon/bikehorn,
		/obj/item/weapon/caution,
		/obj/item/weapon/caution/cone,
		/obj/item/weapon/cell/high,
		/obj/item/device/assembly/mousetrap,
		/obj/item/pizzabox/meat,		//Pizza boxes: infinite food. Might be an issue
		/obj/item/pizzabox/margherita,
		/obj/item/pizzabox/vegetable,
		/obj/item/pizzabox/mushroom,
		/obj/item/weapon/beartrap,
		/obj/item/stack/package_wrap/syndie,
		/obj/item/device/handtv,
		/obj/item/device/wormhole_jaunter,
		/obj/item/mounted/poster,
		/obj/item/inflatable/wall,
		/obj/item/inflatable/door,
		/obj/item/toy/balloon/long,

		)

	var/quantity = rand(5,15)
	for(var/i=0, i<quantity, i++)
		var/button_desc = "[pick("a yellow","a purple","a green","a blue","a red","an orange","a white")], "
		button_desc += "[pick("round","square","diamond","heart","dog","human")] shaped "
		button_desc += "[pick("toggle","switch","lever","button","pad","hole")]"
		var/type = pick(viables)
		viables.Remove(type)
		construction[button_desc] = type

/obj/machinery/replicator/process()
	if(spawning_types.len && powered())
		spawn_progress++
		if(spawn_progress > max_spawn_ticks)
			src.visible_message("<span class='notice'>[bicon(src)] [src] pings!</span>")
			var/spawn_type = spawning_types[1]
			new spawn_type(src.loc)

			spawning_types.Remove(spawning_types[1])
			spawn_progress = 0
			max_spawn_ticks = rand(5,30)

			if(!spawning_types.len)
				use_power = 1
				icon_state = "borgcharger0(old)"

			playsound(src, 'sound/machines/heps.ogg', 50, 0)

		else if(prob(5))
			src.visible_message("<span class='notice'>[bicon(src)] [src] [pick("clicks","whizzes","whirrs","whooshes","clanks","clongs","clonks","bangs")].</span>")

/obj/machinery/replicator/bullet_act(var/obj/item/projectile/Proj)
	if(istype(Proj ,/obj/item/projectile/beam)||istype(Proj,/obj/item/projectile/bullet)||istype(Proj,/obj/item/projectile/ricochet))
		log_attack("<font color='red'>[Proj.firer ? "[key_name(Proj.firer)]" : "Something"] shot [src]/([formatJumpTo(src)]) with a [Proj.type]</font>")
		src.visible_message("<span class='notice'>\The [Proj] [Proj.damage ? "hits" : "glances off"] \the [src]!</span>")
		if(prob(Proj.damage/2))
			if(Proj.firer)
				msg_admin_attack("[key_name(Proj.firer)] blew up [src]/([formatJumpTo(src)]) with a [Proj.type] (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[Proj.firer.x];Y=[Proj.firer.y];Z=[Proj.firer.z]'>JMP</a>)")
			explosion(get_turf(src), -1, 2, 3, 3, whodunnit = Proj.firer)
			src.investigation_log(I_ARTIFACT, "|| blew up after taking damage from || [Proj.type] || fired by [Proj.firer ? "[key_name(Proj.firer)]" : "something"].")
			qdel(src)
	return ..()

/obj/machinery/replicator/attackby(var/obj/item/O, var/mob/user)
	if(O.is_wrench(user))
		return ..()
	else if(O.force > 10)
		log_attack("<font color='red'>[user] damaged [src]/([formatJumpTo(src)]) with [O]</font>")
		src.visible_message("<span class='warning'>\The [user] damages \the [src] with \the [O].</span>")
		if(prob(O.force/2))
			msg_admin_attack("[user] blew up [src]/([formatJumpTo(src)]) with [O] (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[user.x];Y=[user.y];Z=[user.z]'>JMP</a>)")
			src.investigation_log(I_ARTIFACT, "|| blew up after taking damage from || [O] || attacked by [key_name(user)].")
			explosion(get_turf(src), -1, 2, 3, 3, whodunnit = user)
			qdel(src)
	else
		src.visible_message("<span class='warning'>\The [user] taps \the [src] with \the [O].</span>")

/obj/machinery/replicator/attack_hand(mob/user as mob)
	if(..())
		return 1

	interact(user)

/obj/machinery/replicator/interact(mob/user)
	var/dat = "The control panel displays an incomprehensible selection of controls, many with unusual markings or text around them.<br>"
	dat += "<br>"
	for(var/index=1, index<=construction.len, index++)
		dat += "<A href='?src=\ref[src];activate=[index]'>\[[construction[index]]\]</a><br>"

	user << browse(dat, "window=alien_replicator")

/obj/machinery/replicator/Topic(href, href_list)
	if(spawning_types.len > 0)
		to_chat(usr, "<span class='warning'>The machine is already processing something. The buttons are unresponsive.</span>")
		return

	if(href_list["activate"])
		var/index = text2num(href_list["activate"])
		if(index > 0 && index <= construction.len)
			src.visible_message("<span class='notice'>[bicon(src)] a [pick("light","dial","display","meter","pad")] on [src]'s front [pick("blinks","flashes")] [pick("red","yellow","blue","orange","purple","green","white")].[isobserver(usr) ? " Spooky." : ""]</span>")
			spawning_types.Add(construction[construction[index]])
			src.investigation_log(I_ARTIFACT, "|| [spawning_types[1]] || added to replication queue by [key_name(usr)][isobserver(usr) ? "'s ghostly hands" : ""].")
			spawn_progress = 0
			use_power = 2
			icon_state = "borgcharger1(old)"
			playsound(src, 'sound/machines/click.ogg', 50, 0)
