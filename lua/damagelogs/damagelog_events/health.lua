
if SERVER then
	Damagelog:EventHook("TTTPlayerUsedHealthStation")
else
	Damagelog:AddFilter("Show health station usage", DAMAGELOG_FILTER_BOOL, false)
	Damagelog:AddColor("Heal", Color(0, 255, 128))
end

local event = {}

event.Type = "HEAL"

function event:TTTPlayerUsedHealthStation(ply, ent, healed)
	if not (ply.IsGhost and ply:IsGhost()) and ply:IsPlayer() then
		local owner = IsValid(ent:GetPlacer()) and ent:GetPlacer():Nick() or "<disconnected>"
		local tbl = { 
			[1] = ply:Nick(), 
			[2] = ply:GetRole(), 
			[3] = owner, 
			[4] = healed
		}
		self.CallEvent(tbl)
	end
end

function event:ToString(tbl)
	return string.format("%s [%s] has healed for %s HP with %s's health station", tbl[1], Damagelog:StrRole(tbl[2]), tbl[4], tbl[3]) 
end

function event:IsAllowed(tbl)
	return Damagelog.filter_settings["Show health station usage"]
end

function event:Highlight(line, tbl, text)
	if table.HasValue(Damagelog.Highlighted, tbl[1]) or table.HasValue(Damagelog.Highlighted, tbl[3]) then
		return true
	end
	return false
end

function event:GetColor(tbl)
	return Damagelog:GetColor("Heal")
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)
end

Damagelog:AddEvent(event)
