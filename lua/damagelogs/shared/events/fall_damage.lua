if SERVER then
	Damagelog:EventHook("EntityTakeDamage")
else
	Damagelog:AddFilter("filter_show_falldamage", DAMAGELOG_FILTER_BOOL, false)
	Damagelog:AddColor("color_fall_damages", Color(0, 0, 0))
end

local event = {}

event.Type = "FD"

function event:EntityTakeDamage(ent, dmginfo)
	local att = dmginfo:GetAttacker()
	if not (ent.IsGhost and ent:IsGhost()) and ent:IsPlayer() and att:IsWorld() and dmginfo:GetDamageType() == DMG_FALL then
		local damages = dmginfo:GetDamage()
		if math.floor(damages) > 0 then
			local tbl = {
				[1] = ent:GetDamagelogID(),
				[2] = math.Round(damages)
			}
			local push = ent.was_pushed
			if push and math.max(push.t or 0, push.hurt or 0) > CurTime() - 4 then
				tbl[3] = true
				tbl[4] = push.att:GetDamagelogID()
			else
				tbl[3] = false
			end
			self.CallEvent(tbl)
		end
	end
end

function event:ToString(tbl, roles)
	local ply = Damagelog:InfoFromID(roles, tbl[1])
	local t = string.format(TTTLogTranslate(GetDMGLogLang, "FallDamage"), ply.nick, Damagelog:StrRole(ply.role), tbl[2])
	if tbl[3] then
		local att = Damagelog:InfoFromID(roles, tbl[4])
		t = t..string.format(TTTLogTranslate(GetDMGLogLang, "AfterPush"), att.nick, Damagelog:StrRole(att.role))
	end
	return t
end

function event:IsAllowed(tbl)
	return Damagelog.filter_settings["filter_show_falldamage"]
end

function event:Highlight(line, tbl, text)
	return table.HasValue(Damagelog.Highlighted, tbl[1])
end

function event:GetColor(tbl)
	if tbl[5] and Damagelog:IsTeamkill(tbl[2], tbl[7]) then
		return Damagelog:GetColor("color_team_damages")
	else
		return Damagelog:GetColor("color_fall_damages")
	end
end

function event:RightClick(line, tbl, roles, text)
	line:ShowTooLong(true)
	local ply = Damagelog:InfoFromID(roles, tbl[1])
	if tbl[3] then
		local att = Damagelog:InfoFromID(roles, tbl[4])
		line:ShowCopy(true,{ ply.nick, util.SteamIDFrom64(ply.steamid64) }, { att.nick, util.SteamIDFrom64(att.steamid64) })
	else
		line:ShowCopy(true,{ ply.nick, util.SteamIDFrom64(ply.steamid64) })
	end
end

Damagelog:AddEvent(event)