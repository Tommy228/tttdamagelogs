

if SERVER then
	--Damagelog:EventHook("Initialize")
else
	Damagelog:AddFilter("Show grenade throws", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("Grenades", Color(0, 128, 0, 255))
end

local event = {}

event.Type = "NADE"

function event:Initialize()
	for k,v in pairs(weapons.GetList()) do		
		if v.Base == "weapon_tttbasegrenade" then
			v.CreateGrenade = function(gren, src, ang, vel, angimp, ply)
				local tbl = {
					[1] = gren.Owner:Nick(),
					[2] = gren.Owner:GetRole(),
					[3] = gren:GetClass(),
					[4] = gren.Owner:SteamID()
				}
				self.CallEvent(tbl)
				return gren.BaseClass.CreateGrenade(gren, src, ang, vel, angimp, ply)
			end
		end
	end
end

function event:ToString(v)
	local weapon = Damagelog.weapon_table[v[3]] or tostring(v[3])
	return string.format("%s [%s] threw %s", v[1], Damagelog:StrRole(v[2]), weapon) 
end

function event:IsAllowed(tbl)
	local pfilter = Damagelog.filter_settings["Filter by player"]
	if pfilter then
		if not tbl[4] == pfilter then
			return false
		end
	end
	local dfilter = Damagelog.filter_settings["Show grenade throws"]
	if not dfilter then return false end
	return true
	
end

function event:GetColor(tbl)
	return Damagelog:GetColor("Grenades")
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)
	line:ShowCopy(true, { tbl[1], tbl[4] })
end

Damagelog:AddEvent(event)