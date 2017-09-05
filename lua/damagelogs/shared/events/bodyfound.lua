if SERVER then
	Damagelog:EventHook("TTTBodyFound")
else
	Damagelog:AddFilter("filter_show_bodies", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("color_found_bodies", Color(127,0,255))
end

local event = {}

event.Type = "BODY"

function event:TTTBodyFound(ply, deadply, rag)
	local tbl = {
		[1] = ply:GetDamagelogID()
	}
	if IsValid(deadply) then
		table.insert(tbl, deadply:GetDamagelogID())
	else
		local nick = CORPSE.GetPlayerNick(rag, TTTLogTranslate(GetDMGLogLang, "DisconnectedPlayer"))
		for k,v in pairs(Damagelog.Roles[#Damagelog.Roles]) do
			if v.nick == nick then
				table.insert(tbl, k)
				break
			end
		end
	end
	self.CallEvent(tbl)
end

function event:ToString(v, roles)
	local ply = Damagelog:InfoFromID(roles, v[1])
	local deadply = Damagelog:InfoFromID(roles, v[2] or -1)
	return string.format(TTTLogTranslate(GetDMGLogLang, "BodyIdentified"), ply.nick, Damagelog:StrRole(ply.role), deadply.nick, Damagelog:StrRole(deadply.role))
end

function event:IsAllowed(tbl)
	return Damagelog.filter_settings["filter_show_bodies"]
end

function event:Highlight(line, tbl, text)
	if table.HasValue(Damagelog.Highlighted, tbl[1]) or table.HasValue(Damagelog.Highlighted, tbl[2]) then
		return true
	end
	return false
end

function event:GetColor(tbl)
	return Damagelog:GetColor("color_found_bodies")
end

function event:RightClick(line, tbl, roles, text)
	line:ShowTooLong(true)
	local ply = Damagelog:InfoFromID(roles, tbl[1])
	line:ShowCopy(true,{ ply.nick, util.SteamIDFrom64(ply.steamid64) })
end

Damagelog:AddEvent(event)