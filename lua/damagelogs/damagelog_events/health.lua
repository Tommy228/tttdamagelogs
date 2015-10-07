
if SERVER then
	Damagelog:EventHook("TTTPlayerUsedHealthStation")
	Damagelog:EventHook("TTTEndRound")
else
	Damagelog:AddFilter("Show health station usage", DAMAGELOG_FILTER_BOOL, false)
	Damagelog:AddColor("Heal", Color(0, 255, 128))
end

local event = {}
local usages = {}

event.Type = "HEAL"

function event:TTTPlayerUsedHealthStation(ply, ent, healed)
	if not (ply.IsGhost and ply:IsGhost()) and ply:IsPlayer() then
		if usages[ply:UniqueID()] == nil then
			local timername = "HealTimer_"..tostring(ply:UniqueID())
			timer.Create(timername, 5, 0, function()
				if not IsValid(ply) then
					timer.Destroy(timername)
				elseif usages[ply:UniqueID()] > 0 then
					self:Store(ply, ent, usages[ply:UniqueID()])
					usages[ply:UniqueID()] = 0
				else
					usages[ply:UniqueID()] = nil
					self:RemoveTimer(ply:UniqueID())
				end
			end)
			
			self:Store(ply, ent, healed)
			usages[ply:UniqueID()] = 0
		else
			usages[ply:UniqueID()] = usages[ply:UniqueID()] + healed
		end
	end
end

function event:Store(ply, ent, healed)
	local owner = IsValid(ent:GetPlacer()) and ent:GetPlacer():Nick() or "<disconnected>"
	local tbl = { 
		[1] = ply:Nick(), 
		[2] = ply:GetRole(), 
		[3] = owner, 
		[4] = healed
	}
	self.CallEvent(tbl)
end

function event:RemoveTimer(id)
	local timername = "HealTimer_"..tostring(id)
	if timer.Exists(timername) then
		timer.Destroy(timername)
	end
end

function event:TTTEndRound()
	for k,_ in pairs(usages) do
		self:RemoveTimer(k)
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
