

if SERVER then
	Damagelog:EventHook("TTTOrderedEquipment")
else
	Damagelog:AddFilter("Show weapon purchases", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("Equipment Purchases", Color(128, 0, 128, 255))
end

local event = {}

event.Type = "WEP"

function event:TTTOrderedEquipment(ply, ent, is_item)
	self.CallEvent({
		[1] = ply:Nick(),
		[2] = ply:GetRole(),
		[3] = ply:SteamID(),
		[4] = is_item,
		[5] = ent
	})
end

if CLIENT then
	hook.Add("Initialize", "Damagelog_InitializeEventWeapon", function()
		event.Equips = {
			[EQUIP_RADAR] = "a radar",
			[EQUIP_ARMOR] = "a set of body armor",
			[EQUIP_DISGUISE] = "a disguiser"
		}
	end)
end

function event:ToString(v)
	local weapon = Damagelog.weapon_table[v[5]] or tostring(v[5])
	if tonumber(weapon) then
		weapon = tonumber(weapon)
		if event.Equips[weapon] then
			weapon = event.Equips[weapon]
		end
	end
	return string.format("%s [%s] bought %s", v[1], Damagelog:StrRole(v[2]), weapon) 
end

function event:IsAllowed(tbl)
	local pfilter = Damagelog.filter_settings["Filter by player"]
	if pfilter then
		if not tbl[3] == pfilter then
			return false
		end
	end
	local dfilter = Damagelog.filter_settings["Show weapon purchases"]
	if not dfilter then return false end
	return true

end

function event:GetColor(tbl)
	return Damagelog:GetColor("Equipment Purchases")
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)
	line:ShowCopy(true,{ tbl[1], tbl[3] })
end

Damagelog:AddEvent(event)