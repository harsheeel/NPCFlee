-- Script idea by Hazey17, coded by Inferno (Christopher M.)

-- Last Entity Ped aimed at
local LastEntity = false
-- Last vehicle aimed at
local LastVehicle = false
-- Able to rob ped
local AbleToRob = false
-- Currently robbing ped
local Robbing = false
-- Keys to car
local HasKeys = false

-- Create new thread
Citizen.CreateThread(function()
	-- Forever (Note, however, this will only run once per robbing, due to the Citizen.Wait's)
	while true do
		-- Safe looping
        	Citizen.Wait(0)
		-- Get the entity Ped is aiming at
        	local FoundEntity, AimedEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())
		-- If the ped is aiming at the entity in the car, there is an entity in the car, and it's not an entity we are already dealing with, and player has a weapon other than fists.
		if FoundEntity and LastEntity ~= AimedEntity and IsPedInAnyVehicle(AimedEntity, false) and IsPedArmed(PlayerPedId(), 7) then
			-- Set last entity so this ped
			LastEntity = AimedEntity
			-- Get the vehicle the entity is driving
			LastVehicle = GetVehiclePedIsIn(AimedEntity, false)
            		-- 85% chance the ped will stop, 15% chance they will keep driving
            		if math.random() >= 0.15 then
                		-- If the ped is not a real player.
                		if not IsPedAPlayer(AimedEntity) then
					-- If animation dictionary not loaded
					if not HasAnimDictLoaded("random@mugging3") then
                        			-- Load animation Dictionary
                        			RequestAnimDict("random@mugging3")
						-- While the dictionary is not loaded
						while not HasAnimDictLoaded("random@mugging3") do
						    -- Wait
						    Citizen.Wait(0)
						end
                    			end
					-- Make ped get out and not close door
					TaskLeaveVehicle(AimedEntity, LastVehicle, 256)
					-- Make ped turn off engine
					SetVehicleEngineOn(LastVehicle, false, false, false)
					-- While they are still in the vehicle
					while IsPedInAnyVehicle(AimedEntity, false) do
					-- Wait
					Citizen.Wait(0)
					end

					-- Make sure they forget what is going on
					SetBlockingOfNonTemporaryEvents(AimedEntity, true)
					-- Once out, clear their tasks
					ClearPedTasksImmediately(AimedEntity)
					-- Hands up animation
					TaskPlayAnim(AimedEntity, "random@mugging3", "handsup_standing_base", 8.0, -8, 0.01, 49, 0, 0, 0, 0)
					-- Make sure they do not get back into the vehicle they came from
					ResetPedLastVehicle(AimedEntity)
					-- Keep ped in place
					TaskWanderInArea(AimedEntity, 0, 0, 0, 20, 100, 100)
					-- Make them drop their guns, since they are surrendering
					SetPedDropsWeapon(AimedEntity)
					-- Remove any exisiting keys from the player
					HasKeys = false
					-- Set able to rob to true
					AbleToRob = true
					-- Wait for robbing
					Citizen.Wait(math.random(4000, 8000))
					-- Set able to rob to false
					AbleToRob = false
					-- Check if ped is still alive (player might have shot ped by now tbh) and ped is not in the process of being robbed
					if not IsEntityDead(AimedEntity) and not Robbing then
						-- Stop animation
						StopAnimTask(AimedEntity, "random@mugging3", "handsup_standing_base", 1.0)
						-- Clear tasks
						ClearPedTasksImmediately(AimedEntity)
						-- Make them run away from player
						TaskReactAndFleePed(AimedEntity, PlayerPedId())
					end
				end
			end
		end
	end
end)

-- Create new thread
Citizen.CreateThread(function()
	-- Forever
	while true do
		-- Safe looping
		Citizen.Wait(0)
		-- If player is able to rob ped, and they just pressed E
		if AbleToRob and IsControlJustPressed(0, 38) and not IsEntityDead(LastEntity) then
			-- Player ped
			local PlayerPed = PlayerPedId()
			-- Ped coordinates
			local LastEntityCoords = GetEntityCoords(LastEntity)
			-- Player coordinates
			local PlayerCoords = GetEntityCoords(PlayerPed)
			-- Distance between player and ped
			local Distance = Vdist(LastEntityCoords.x, LastEntityCoords.y, LastEntityCoords.z, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z)
			-- If player is right next to ped
			if Distance < 3.5 then
				-- Set ped as not robbable
				AbleToRob = false
				-- Set the robbing as in-progress
				Robbing = true
				-- If animation dictionary not loaded
				if not HasAnimDictLoaded("anim@gangops@morgue@table@") then
					-- Load animation Dictionary
					RequestAnimDict("anim@gangops@morgue@table@")
					-- While the dictionary is not loaded
					while not HasAnimDictLoaded("anim@gangops@morgue@table@") do
						-- Wait
						Citizen.Wait(0)
					end
				end
				-- Rotate the ped so the player do not end up in the car
				SetEntityRotation(LastEntity, 0, 0, 90, 0, 0)
				-- Attach the ped and the player (this is just a lazy way of orienting the player with the ped)
				AttachEntityToEntity(PlayerPed, LastEntity, GetEntityBoneIndexByName(LastEntity, "BONETAG_SPINE"), 0.75, 0, 0, 0.0, 0.0, 67.0, false, false, false, true, 0, false)
				-- Pat down animation
				TaskPlayAnim(PlayerPed, "anim@gangops@morgue@table@", "player_search", 8.0, -8, 5000, 33, 0, 0, 0, 0)
				-- Wait for the animation to end
				Citizen.Wait(5000)
				-- If the ped is still alive
				if not IsEntityDead(LastEntity) then
					-- Stop animation
					ClearPedTasksImmediately(LastEntity)
					-- Make them run away
					TaskReactAndFleePed(LastEntity, PlayerPed)
				end
				-- 80% chance the ped will give the keys, 20% chance they will not
				if math.random() >= 0.20 then
					-- Screen notifcation
					NewNoti("~g~They hand over the keys.")
					-- Success sound
					PlaySoundFrontend(-1, "HACKING_SUCCESS", 0, 1)
					-- Give player keys
					HasKeys = true
				else
					-- Screen notifcation
					NewNoti("~r~They do not give you the keys.")
					-- Fail sound
					PlaySoundFrontend(-1, "HACKING_FAILURE", 0, 1)
					-- Give player keys
					HasKeys = false
				end
				-- Detach the ped and the player
				DetachEntity(PlayerPed, false, false)
				-- Stop the pat down animation
				StopAnimTask(PlayerPedId(), "anim@gangops@morgue@table@", "player_search", 1.0)
				-- Clear tasks (stops side-way gun)
				ClearPedTasksImmediately(PlayerPed)
				ClearPedSecondaryTask(PlayerPed)
				-- End robbing
				Robbing = false
			end
		end
	end
end)

-- Create new thread
Citizen.CreateThread(function()
	-- Forever
	while true do
		-- Safe looping
		Citizen.Wait(0)
		-- If ped has stoped a car
		if LastVehicle then
			-- If ped is in any vehicle
			if IsPedInAnyVehicle(PlayerPedId(), true) then
				-- Not set above to save resources, player ped
				local PlayerPed = PlayerPedId()
				-- If the last robbed vehicle is the vehicle the ped is currently in, is the driver, and does not have the keys
				if LastVehicle == GetVehiclePedIsIn(PlayerPed, false) and GetPedInVehicleSeat(LastVehicle, -1) and not HasKeys then
					-- Turn off engine
					SetVehicleEngineOn(LastVehicle, false, true, false)
					-- Stops flickering of player trying to turn engine on
					ClearPedSecondaryTask(PlayerPed)
				end
			end
		end

		-- If currently robbing a ped
		if Robbing then
			-- Disable a bunch of shooting, punshing, etc. keys
			DisableControlAction(0, 24, true)
			DisableControlAction(0, 25, true)
			DisableControlAction(0, 47, true)
			DisableControlAction(0, 58, true)
			DisableControlAction(0, 263, true)
			DisableControlAction(0, 264, true)
			DisableControlAction(0, 257, true)
			DisableControlAction(0, 140, true)
			DisableControlAction(0, 141, true)
			DisableControlAction(0, 142, true)
			DisableControlAction(0, 143, true)
		end
	end
end)

-- Draws notification on client's screen
function NewNoti(Text, Flash)
	-- Tell GTA that a string will be passed
	SetNotificationTextEntry("STRING")
	-- Pass temporary variable to notification
	AddTextComponentString(Text)
	-- Draw new notification on client's screen
	DrawNotification(Flash, true)
end
