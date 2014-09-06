
-- sometimes there's no other way

hook.Add("Initialize", "Damagelog_C4Stuff", function()

	local function SendDisarmResult(ply, idx, result, bomb)
		hook.Call("TTTC4Disarm", GAMEMODE, ply, result, bomb)
		umsg.Start("c4_disarm_result", ply)
		umsg.Short(idx)
		umsg.Bool(result)
		umsg.End()
	end
	local function ReceiveC4Disarm(ply, cmd, args)
		if (not IsValid(ply)) or (not ply:IsTerror()) or (not ply:Alive()) or #args != 2 then return end
		local idx = tonumber(args[1])
		local wire = tonumber(args[2])
		if not idx or not wire then return end
		local bomb = ents.GetByIndex(idx)
		if IsValid(bomb) and bomb:GetArmed() then
			if bomb:GetPos():Distance(ply:GetPos()) > 256 then
				return
			elseif bomb.SafeWires[wire] or ply:IsTraitor() or ply == bomb:GetOwner() then
				LANG.Msg(ply, "c4_disarmed")
				bomb:Disarm(ply)
				SendDisarmResult(ply, idx, true, bomb)
			else
				SendDisarmResult(ply, idx, false, bomb)
				bomb:FailedDisarm(ply)
			end
		end
	end
	concommand.Add("ttt_c4_disarm", ReceiveC4Disarm)

	local function ReceiveC4Destroy(ply, cmd, args)
		if (not IsValid(ply)) or (not ply:IsTerror()) or (not ply:Alive()) or #args != 1 then return end
		local idx = tonumber(args[1])
		if not idx then return end
		local bomb = ents.GetByIndex(idx)
		if IsValid(bomb) and (not bomb:GetArmed()) then
			if bomb:GetPos():Distance(ply:GetPos()) > 256 then return
			else
				util.EquipmentDestroyed(bomb:GetPos())
				hook.Call("TTTC4Destroyed", GAMEMODE, ply, bomb)
				bomb:Remove()
			end
		end
	end
	concommand.Add("ttt_c4_destroy", ReceiveC4Destroy)
	
	local function ReceiveC4Pickup(ply, cmd, args)
		if (not IsValid(ply)) or (not ply:IsTerror()) or (not ply:Alive()) or #args != 1 then return end
		local idx = tonumber(args[1])
		if not idx then return end
		local bomb = ents.GetByIndex(idx)
		if IsValid(bomb) and bomb.GetArmed and (not bomb:GetArmed()) then
			if bomb:GetPos():Distance(ply:GetPos()) > 256 then return
			elseif not ply:CanCarryType(WEAPON_EQUIP1) then
				LANG.Msg(ply, "c4_no_room")
			else
				local prints = bomb.fingerprints or {}
				local wep = ply:Give("weapon_ttt_c4")
				hook.Call("TTTC4Pickup", GAMEMODE, ply, bomb)
				if IsValid(wep) then
					wep.fingerprints = wep.fingerprints or {}
					table.Add(wep.fingerprints, prints)
					bomb:Remove()
				end
			end
		end
	end
	concommand.Add("ttt_c4_pickup", ReceiveC4Pickup)
   
end)