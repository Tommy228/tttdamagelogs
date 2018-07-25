if SERVER then
	Damagelog:EventHook("DL_AslayHook")
else
	Damagelog:AddFilter("filter_show_aslays", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("colors_aslays", Color(255, 128, 128, 255))
end

local event = {}
event.Type = "ASLAY"

function event:DL_AslayHook(ply)
	local tbl = {
		[1] = ply:GetDamagelogID()
	}

	self.CallEvent(tbl)
end

function event:ToString(v, roles)
	local ply = Damagelog:InfoFromID(roles, v[1])

	return string.format(TTTLogTranslate(GetDMGLogLang, "AutoSlain"), ply.nick, Damagelog:StrRole(ply.role))
end

function event:IsAllowed(tbl)
	return Damagelog.filter_settings["filter_show_aslays"]
end

function event:Highlight(line, tbl, text)
	return table.HasValue(Damagelog.Highlighted, tbl[1])
end

function event:GetColor(tbl)
	return Damagelog:GetColor("colors_aslays")
end

function event:RightClick(line, tbl, roles, text)
	line:ShowTooLong(true)
	local ply = Damagelog:InfoFromID(roles, tbl[1])
	line:ShowCopy(true, {ply.nick, util.SteamIDFrom64(ply.steamid64)})
end

Damagelog:AddEvent(event)
