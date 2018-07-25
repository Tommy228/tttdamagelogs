if SERVER then
	Damagelog:EventHook("TTTOrderedEquipment")
else
	Damagelog:AddFilter("filter_show_purchases", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("color_purchases", Color(128, 0, 128, 255))
end

local event = {}

event.Type = "WEP"

function event:TTTOrderedEquipment(ply, ent, is_item)
	self.CallEvent({
		[1] = ply:GetDamagelogID(),
		[2] = is_item,
		[3] = ent
	})
end

function event:ToString(v, roles)
	local weapon = v[3]
	if isnumber(weapon) then
		weapon = tonumber(weapon)
		for _,role in pairs(EquipmentItems) do
			local found = false
			for k,v in pairs(role) do
				if v.id == weapon then
					local translated = LANG.TryTranslation(v.name)
      				weapon = translated or v.name
					found = true
					break
				end
			end
			if found then break end
		end
	else
		weapon = Damagelog:GetWeaponName(weapon)
	end
	local ply = Damagelog:InfoFromID(roles, v[1])
	return string.format(TTTLogTranslate(GetDMGLogLang, "HasBought"), ply.nick, Damagelog:StrRole(ply.role), weapon)
end

function event:IsAllowed(tbl)
	return Damagelog.filter_settings["filter_show_purchases"]
end

function event:Highlight(line, tbl, text)
	return table.HasValue(Damagelog.Highlighted, tbl[1])
end

function event:GetColor(tbl)
	return Damagelog:GetColor("color_purchases")
end

function event:RightClick(line, tbl, roles, text)
	line:ShowTooLong(true)
	local ply = Damagelog:InfoFromID(roles, tbl[1])
	line:ShowCopy(true,{ ply.nick, util.SteamIDFrom64(ply.steamid64) })
end

Damagelog:AddEvent(event)