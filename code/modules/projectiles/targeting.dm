/obj/item/weapon/gun/verb/toggle_firerate()
	set name = "Toggle Firerate"
	set category = "Object"
	firerate = !firerate
	if (firerate == 1)
		to_chat(loc, "You will now continue firing when your target moves.")
	else
		to_chat(loc, "You will now only fire once, then lower your aim, when your target moves.")

/obj/item/weapon/gun/verb/lower_aim()
	set name = "Lower Aim"
	set category = "Object"
	if(target)
		stop_aim()
		usr.visible_message("<span class='notice'>\The [usr] lowers \the [src]...</span>")
		return 1
	return 0

//Clicking gun will still lower aim for guns that don't overwrite this
/obj/item/weapon/gun/attack_self()
	if(!lower_aim())
		return ..()

//Removing the lock and the buttons.
/obj/item/weapon/gun/dropped(mob/user as mob)
	stop_aim()
	if (user && user.client)
		user.client.remove_gun_icons()
	return ..()

/obj/item/weapon/gun/equipped(var/mob/user, var/slot, hand_index)
	if(!hand_index)
		stop_aim()
		if (user && user.client)
			user.client.remove_gun_icons()
	return ..()

//Removes lock fro mall targets
/obj/item/weapon/gun/proc/stop_aim()
	if(target)
		for(var/mob/living/M in target)
			if(M)
				M.NotTargeted(src) //Untargeting people.
		qdel(target)
		target = null

//Compute how to fire.....
/obj/item/weapon/gun/proc/PreFire(atom/A as mob|obj|turf|area, mob/living/user as mob|obj, params, struggle = 0)
	//Lets not spam it.
	if(lock_time > world.time - 2)
		return
	. //the rare and mystical rogue ".". nobody knows what this majestic beast does or why is it here. not even why it compiles is known for certain. legend says should it be touched, everything will probably break; but nobody dares try.
	if(ismob(A) && isliving(A) && !(A in target))
		Aim(A) 	//Clicked a mob, aim at them
	else  		//Didn't click someone, check if there is anyone along that guntrace
		var/mob/living/M = GunTrace(usr.x,usr.y,A.x,A.y,usr.z,usr)  //Find dat mob.
		if(M && isliving(M) && (M in view(user)) && !(M in target))
			Aim(M) //Aha!  Aim at them!
		else if(!ismob(M) || (ismob(M) && !(M in view(user)))) //Nope!  They weren't there!
			Fire(A,user,params, "struggle" = struggle)  //Fire like normal, then.
	usr.dir = get_cardinal_dir(src, A)

//Aiming at the target mob.
/obj/item/weapon/gun/proc/Aim(var/mob/living/M)
	if (M.alpha <= 1)
		return // no abusing aiming to reveal cloaked individuals. Why do cloaking cloaks set alpha to specifically 1 anyway? The human eye can't see that 'cept maybe on a fully white background.
	if(!target || !(M in target))
		lock_time = world.time
		if(target && !automatic) //If they're targeting someone and they have a non automatic weapon.
			for(var/mob/living/L in target)
				if(L)
					L.NotTargeted(src)
			qdel(target)
			target = null
			usr.visible_message("<span class='danger'>[usr] turns \the [src] on [M]!</span>")
		else
			usr.visible_message("<span class='danger'>[usr] aims \a [src] at [M]!</span>")
		M.Targeted(src)

//HE MOVED, SHOOT HIM!
/obj/item/weapon/gun/proc/TargetActed(var/mob/living/T)
	var/mob/living/M = loc
	if(M == T)
		return
	if(!istype(M))
		return
	if(src != M.get_active_hand())
		stop_aim()
		return
	M.last_move_intent = world.time
	if(canbe_fired())
		var/firing_check = can_hit(T,usr) //0 if it cannot hit them, 1 if it is capable of hitting, and 2 if a special check is preventing it from firing.
		if(firing_check > 0)
			if(firing_check == 1)
				Fire(T,usr, reflex = 1)
		else if(!told_cant_shoot)
			to_chat(M, "<span class='warning'>They can't be hit from here!</span>")
			told_cant_shoot = 1
			spawn(30)
				told_cant_shoot = 0
	else
		click_empty(M)

	usr.dir = get_cardinal_dir(src, T)

	if (!firerate) // If firerate is set to lower aim after one shot, untarget the target
		T.NotTargeted(src)

//Yay, math!

#define SIGN(X) ((X<0)?-1:1)

proc/GunTrace(X1,Y1,X2,Y2,Z=1,exc_obj,PX1=16,PY1=16,PX2=16,PY2=16)
//	to_chat(bluh, "Tracin' [X1],[Y1] to [X2],[Y2] on floor [Z].")
	var/turf/T
	var/mob/living/M
	if(X1==X2)
		if(Y1==Y2)
			return 0 //Light cannot be blocked on same tile
		else
			var/s = SIGN(Y2-Y1)
			Y1+=s
			while(1)
				T = locate(X1,Y1,Z)
				if(!T)
					return 0
				M = locate() in T
				if(M)
					return M
				M = locate() in orange(1,T)-exc_obj
				if(M)
					return M
				Y1+=s
	else
		var/m=(WORLD_ICON_SIZE*(Y2-Y1)+(PY2-PY1))/(WORLD_ICON_SIZE*(X2-X1)+(PX2-PX1))
		var/b=(Y1+PY1/WORLD_ICON_SIZE-0.015625)-m*(X1+PX1/WORLD_ICON_SIZE-0.015625) //In tiles
		var/signX = SIGN(X2-X1)
		var/signY = SIGN(Y2-Y1)
		if(X1<X2)
			b+=m
		while(1)
			var/xvert = round(m*X1+b-Y1)
			if(xvert)
				Y1+=signY //Line exits tile vertically
			else
				X1+=signX //Line exits tile horizontally
			T = locate(X1,Y1,Z)
			if(!T)
				return 0
			M = locate() in T
			if(M)
				return M
			M = locate() in orange(1,T)-exc_obj
			if(M)
				return M
	return 0


//Targeting management procs
mob/var
	list/targeted_by
	target_time = -100
	last_move_intent = -100
	last_target_click = -5
	target_locked = null

mob/living/proc/Targeted(var/obj/item/weapon/gun/I) //Self explanitory.
	if(!I.target)
		I.target = list(src)
	else if(I.automatic && I.target.len < 5) //Automatic weapon, they can hold down a room.
		I.target += src
	else if(I.target.len >= 5)
		if(ismob(I.loc))
			to_chat(I.loc, "You can only target 5 people at once!")
		return
	else
		return
	for(var/mob/living/K in viewers(usr))
		K << 'sound/weapons/TargetOn.ogg'

	if(!targeted_by)
		targeted_by = list()
	targeted_by += I
	I.lock_time = world.time + 20 //Target has 2 second to realize they're targeted and stop (or target the opponent).
	to_chat(src, "((<span class='danger'>Your character is being targeted. They have 2 seconds to stop any click or move actions. </span>While targeted, they may \
	drag and drop items in or into the map, speak, and click on interface buttons. Clicking on the map objects (floors and walls are fine), their items \
	 (other than a weapon to de-target), or moving will result in being fired upon. <span class='warning'>The aggressor may also fire manually, </span>\
	 so try not to get on their bad side.\black ))")

	if(targeted_by.len == 1)
		spawn(0)
			target_locked = image("icon" = 'icons/effects/Targeted.dmi', "icon_state" = "locking")
			update_targeted()
			spawn(0)
				sleep(20)
				if(target_locked)
					target_locked = image("icon" = 'icons/effects/Targeted.dmi', "icon_state" = "locked")
					update_targeted()

	//Adding the buttons to the controler person
	var/mob/living/T = I.loc
	if(T)
		if(T.client)
			T.client.add_gun_icons()
		else
			I.lower_aim()
			return
		if(m_intent == "run" && T.client.target_can_move == 1 && T.client.target_can_run == 0 && (ishuman(T)))
			to_chat(src, "<spanclass='warning'>Your captive is allowing you to walk. Make sure to change your move intent to walk before trying to move, or you will be fired upon.</span>")//Self explanitory.

			//set_m_intent("walk") -there's a real fucked up exploit behind this, so it's been removed. Needs testing. -Angelite-

		//Processing the aiming. Should be probably in separate object with process() but lasy.
		while(targeted_by && T.client)
			if((last_move_intent > I.lock_time + 10) && !T.client.target_can_move) //If target moved when not allowed to
				I.TargetActed(src)
				if(I.last_moved_mob == src) //If they were the last ones to move, give them more of a grace period, so that an automatic weapon can hold down a room better.
					I.lock_time = world.time + 5
				I.lock_time = world.time + 5
				I.last_moved_mob = src
			else if((last_move_intent > I.lock_time + 10) && !T.client.target_can_run && m_intent == "run") //If the target ran while targeted
				I.TargetActed(src)
				if(I.last_moved_mob == src) //If they were the last ones to move, give them more of a grace period, so that an automatic weapon can hold down a room better.
					I.lock_time = world.time + 5
				I.lock_time = world.time + 5
				I.last_moved_mob = src
			if((last_target_click > I.lock_time + 10) && !T.client.target_can_click) //If the target clicked the map to pick something up/shoot/etc
				I.TargetActed(src)
				if(I.last_moved_mob == src) //If they were the last ones to move, give them more of a grace period, so that an automatic weapon can hold down a room better.
					I.lock_time = world.time + 5
				I.lock_time = world.time + 5
				I.last_moved_mob = src
			sleep(1)

mob/living/proc/NotTargeted(var/obj/item/weapon/gun/I)
	if(!I.silenced)
		for(var/mob/living/M in viewers(src))
			M << 'sound/weapons/TargetOff.ogg'
	targeted_by -= I
	I.target.Remove(src) //De-target them
	if(!I.target.len)
		I.target = null
	var/mob/living/T = I.loc //Remove the targeting icons
	if(T && ismob(T) && !I.target)
		T.client.remove_gun_icons()
	if(!targeted_by.len)
		del (target_locked) //Remove the overlay
		targeted_by = null
	spawn(1) update_targeted()

//If you move out of range, it isn't going to still stay locked on you any more.
client/var
	target_can_move = 0
	target_can_run = 0
	target_can_click = 0
	gun_mode = 0

//These are called by the on-screen buttons, adjusting what the victim can and cannot do.
client/proc/add_gun_icons()
	if (!usr.item_use_icon)
		usr.item_use_icon = new /obj/abstract/screen/gun/item
		usr.item_use_icon.icon_state = "no_item[target_can_click]"
		usr.item_use_icon.name = "[target_can_click ? "Disallow" : "Allow"] Item Use"

	if (!usr.gun_move_icon)
		usr.gun_move_icon = new /obj/abstract/screen/gun/move
		usr.gun_move_icon.icon_state = "no_walk[target_can_move]"
		usr.gun_move_icon.name = "[target_can_move ? "Disallow" : "Allow"] Walking"

	if (target_can_move && !usr.gun_run_icon)
		usr.gun_run_icon = new /obj/abstract/screen/gun/run
		usr.gun_run_icon.icon_state = "no_run[target_can_run]"
		usr.gun_run_icon.name = "[target_can_run ? "Disallow" : "Allow"] Running"

	screen += usr.item_use_icon
	screen += usr.gun_move_icon
	if (target_can_move)
		screen += usr.gun_run_icon

client/proc/remove_gun_icons()
	if(!usr)
		return
	if(usr.gun_move_icon)
		qdel(usr.gun_move_icon)
		screen -= usr.gun_move_icon
		usr.gun_move_icon = null
	if(usr.item_use_icon)
		qdel(usr.item_use_icon)
		screen -= usr.item_use_icon
		usr.item_use_icon = null
	if(usr.gun_run_icon)
		qdel(usr.gun_run_icon)
		screen -= usr.gun_run_icon
		usr.gun_run_icon = null

client/verb/ToggleGunMode()
	set hidden = 1
	gun_mode = !gun_mode
	if(gun_mode)
		to_chat(usr, "You will now take people captive.")
		add_gun_icons()
	else
		to_chat(usr, "You will now shoot where you target.")
		for(var/obj/item/weapon/gun/G in usr)
			G.stop_aim()
		remove_gun_icons()
	if(usr.gun_setting_icon)
		usr.gun_setting_icon.icon_state = "gun[gun_mode]"


client/verb/AllowTargetMove()
	set hidden=1

	//Changing client's permissions
	target_can_move = !target_can_move
	if(target_can_move)
		to_chat(usr, "Target may now walk.")
		usr.gun_run_icon = new /obj/abstract/screen/gun/run
		screen += usr.gun_run_icon
	else
		to_chat(usr, "Target may no longer move.")
		target_can_run = 0
		qdel(usr.gun_run_icon)	//no need for icon for running permission
		usr.gun_run_icon = null

	//Updating walking permission button
	if(usr.gun_move_icon)
		usr.gun_move_icon.icon_state = "no_walk[target_can_move]"
		usr.gun_move_icon.name = "[target_can_move ? "Disallow" : "Allow"] Walking"

	//Handling change for all the guns on client
	for(var/obj/item/weapon/gun/G in usr)
		G.lock_time = world.time + 5
		if(G.target)
			for(var/mob/living/M in G.target)
				if(target_can_move)
					to_chat(M, "Your character may now <b>walk</b> at the discretion of their targeter.")
					if(!target_can_run && (ishuman(M)))
						to_chat(M, "<span class='warning'>Your move intent is now set to walk, as your targeter permits it.</span>")
						M.set_m_intent("walk")
				else
					to_chat(M, "<span class='danger'>Your character will now be shot if they move.</span>")

mob/living/proc/set_m_intent(var/intent)
	if (intent != "walk" && intent != "run")
		return 0
	m_intent = intent
	if(hud_used)
		if (hud_used.move_intent)
			hud_used.move_intent.icon_state = intent == "walk" ? "walking" : "running"

client/verb/AllowTargetRun()
	set hidden=1

	//Changing client's permissions
	target_can_run = !target_can_run
	if(target_can_run)
		to_chat(usr, "Target may now run.")
	else
		to_chat(usr, "Target may no longer run.")

	//Updating running permission button
	if(usr.gun_run_icon)
		usr.gun_run_icon.icon_state = "no_run[target_can_run]"
		usr.gun_run_icon.name = "[target_can_run ? "Disallow" : "Allow"] Running"

	//Handling change for all the guns on client
	for(var/obj/item/weapon/gun/G in usr)
		G.lock_time = world.time + 5
		if(G.target)
			for(var/mob/living/M in G.target)
				if(target_can_run)
					to_chat(M, "Your character may now <b>run</b> at the discretion of their targeter.")
				else
					to_chat(M, "<span class='danger'>Your character will now be shot if they run.</span>")

client/verb/AllowTargetClick()
	set hidden=1

	//Changing client's permissions
	target_can_click = !target_can_click
	if(target_can_click)
		to_chat(usr, "Target may now use items.")
	else
		to_chat(usr, "Target may no longer use items.")

	if(usr.item_use_icon)
		usr.item_use_icon.icon_state = "no_item[target_can_click]"
		usr.item_use_icon.name = "[target_can_click ? "Disallow" : "Allow"] Item Use"

	//Handling change for all the guns on client
	for(var/obj/item/weapon/gun/G in usr)
		G.lock_time = world.time + 5
		if(G.target)
			for(var/mob/living/M in G.target)
				if(target_can_click)
					to_chat(M, "Your character may now <b>use items</b> at the discretion of their targeter.")
				else
					to_chat(M, "<span class='danger'>Your character will now be shot if they use items.</span>")
