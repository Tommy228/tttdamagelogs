if SERVER then
	Damagelog:EventHook("DoPlayerDeath")
else
	Damagelog:AddFilter("filter_show_suicides", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("color_suicides", Color(25, 25, 220, 255))
end

local event = {}

event.Type = "KILL"

function event:DoPlayerDeath(ply, attacker, dmginfo)
	local class = attacker:GetClass()
	if ((IsValid(attacker) and ((attacker:IsPlayer() and attacker == ply) or class == "prop_physics" or class == "func_physbox"))) or attacker:IsWorld() and not (dmginfo:IsDamageType(DMG_DROWN) or (ply.IsGhost and ply:IsGhost())) then
		Damagelog.SceneID = Damagelog.SceneID + 1
		local scene = Damagelog.SceneID
		Damagelog.SceneRounds[scene] = Damagelog.CurrentRound
		local tbl = {
			[1] = ply:GetDamagelogID(),
			[2] = scene
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

function event:ToString(v, roles)
	local info = Damagelog:InfoFromID(roles, v[1])
	return string.format(TTTLogTranslate(GetDMGLogLang, "SomethingKilled"), info.nick, Damagelog:StrRole(info.role))
end

function event:IsAllowed(tbl)
	return Damagelog.filter_settings["filter_show_suicides"]
end

function event:Highlight(line, tbl, text)
	return table.HasValue(Damagelog.Highlighted, tbl[1])
end

function event:GetColor(tbl)
	return Damagelog:GetColor("color_suicides")
end

function event:RightClick(line, tbl, roles, text)
	line:ShowTooLong(true)
	local ply = Damagelog:InfoFromID(roles, tbl[1])
	line:ShowCopy(true, { ply.nick, util.SteamIDFrom64(ply.steamid64) })
	line:ShowDeathScene(tbl[1], tbl[1], tbl[2])
end

Damagelog:AddEvent(event)
