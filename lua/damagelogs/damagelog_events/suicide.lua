

if SERVER then
	Damagelog:EventHook("DoPlayerDeath")
else
	Damagelog:AddFilter("Show suicides", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("Suicides", Color(25, 25, 220, 255))
end

local event = {}

event.Type = "KILL"

function event:DoPlayerDeath(ply, attacker, dmginfo)
	if (IsValid(attacker) and attacker:IsPlayer() and attacker == ply and not (ply.IsGhost and ply:IsGhost())) or not IsValid(attacker) or not attacker:IsPlayer() then
		Damagelog.SceneID = Damagelog.SceneID + 1
		local scene = Damagelog.SceneID
		local tbl = { 
			[1] = ply:Nick(), 
			[2] = ply:GetRole(), 
			[3] = ply:SteamID(),
			[4] = scene
		} 
		if scene then
			timer.Simple(0.6, function()
				Damagelog.Death_Scenes[scene] = table.Copy(Damagelog.Records)
			end)
		end
		self.CallEvent(tbl)
		ply.rdmInfo = {
			time = Damagelog.Time,
			round = Damagelog.CurrentRound,
		}
		ply.rdmSend = true
	end
end

function event:ToString(v)
	return string.format("<something/world> killed %s [%s]", v[1], Damagelog:StrRole(v[2]), v[3]) 
end

function event:IsAllowed(tbl)
	return Damagelog.filter_settings["Show suicides"]
end

function event:Highlight(line, tbl, text)
	return table.HasValue(Damagelog.Highlighted, tbl[1])
end

function event:GetColor(tbl)
	return Damagelog:GetColor("Suicides")
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)
	line:ShowCopy(true, { tbl[1], tbl[3] })
	line:ShowDeathScene(tbl[1], tbl[1], tbl[4])
end

Damagelog:AddEvent(event)
