if SERVER then
	Damagelog:EventHook("DoPlayerDeath")
else
	Damagelog:AddFilter("Show kills", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("Teamkills", Color(255, 40, 40))
	Damagelog:AddColor("Kills", Color(255, 128, 0, 255))
end

local event = {}

event.Type = "KILL"

function event:DoPlayerDeath(ply, attacker, dmginfo)
	if IsValid(attacker) and attacker:IsPlayer() and attacker != ply and not (attacker.IsGhost and attacker:IsGhost()) then
		local scene = false
		Damagelog.SceneID = Damagelog.SceneID + 1
		scene = Damagelog.SceneID
		local tbl = { 
			[1] = attacker:Nick(), 
			[2] = attacker:GetRole(), 
			[3] = ply:Nick(), 
			[4] = ply:GetRole(), 
			[5] = Damagelog:WeaponFromDmg(dmginfo),
			[6] = ply:SteamID(),
			[7] = attacker:SteamID(),
			[8] = scene
		}
		self.CallEvent(tbl)
		if scene then
			timer.Simple(0.6, function()
				Damagelog.Death_Scenes[scene] = table.Copy(Damagelog.Records)
			end)
		end
		if GetRoundState() == ROUND_ACTIVE then
			net.Start("DL_Ded")
			if tbl[2] == ROLE_TRAITOR and (tbl[4] == ROLE_INNOCENT or tbl[4] == ROLE_DETECTIVE) then
				net.WriteUInt(0,1)
			else
				net.WriteUInt(1,1)
				net.WriteString(tbl[1])
			end
			net.Send(ply)
			ply:SetNWEntity("DL_Killer", attacker)
		end
	end
end

function event:ToString(v)

	local weapon = Damagelog.weapon_table[v[5]] or v[5]
	text = string.format("%s [%s] killed %s [%s] with an unknown weapon", v[1], Damagelog:StrRole(v[2]), v[3], Damagelog:StrRole(v[4])) 
	if weapon then
		text = string.format("%s [%s] killed %s [%s] with %s", v[1], Damagelog:StrRole(v[2]), v[3], Damagelog:StrRole(v[4]), weapon)
	end
	return text
	
end

function event:IsAllowed(tbl)
	return Damagelog.filter_settings["Show kills"]	
end

function event:Highlight(line, tbl, text)
	if table.HasValue(Damagelog.Highlighted, tbl[1]) or table.HasValue(Damagelog.Highlighted, tbl[3]) then
		return true
	end
	return false
end

function event:GetColor(tbl)
	
	if Damagelog:IsTeamkill(tbl[2], tbl[4]) then
		return Damagelog:GetColor("Teamkills")
	else
		return Damagelog:GetColor("Kills")
	end
	
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)
	line:ShowCopy(true, { tbl[1], tbl[7] }, { tbl[3], tbl[6] })
	line:ShowDamageInfos(tbl[3], tbl[1])
	if tbl[8] then
		line:ShowDeathScene(tbl[3], tbl[1], tbl[8])
	end
end

Damagelog:AddEvent(event)
