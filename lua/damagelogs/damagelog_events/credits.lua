if SERVER then
	hook.Add("Initialize", "Damagelog_ORAddCredits", function()
		local plymeta = FindMetaTable( "Player" )
		if not plymeta then Error("FAILED TO FIND PLAYER TABLE") return end
		function plymeta:AddCredits(amt)
		   self:SetCredits(self:GetCredits() + amt)
		   hook.Call("TTTAddCredits", GAMEMODE, self, amt)
		end
	end)

	Damagelog:EventHook("TTTAddCredits")
else
	Damagelog:AddFilter("Show credit changes", DAMAGELOG_FILTER_BOOL, false)
	Damagelog:AddColor("Credits", Color(255,155,0))
end

local event = {}

event.Type = "CRED"

function event:TTTAddCredits(ply, credits)
	self.CallEvent({
		[1] = (IsValid(ply) and ply:Nick() or "<Disconnected Player>"),
		[2] = (IsValid(ply) and ply:GetRole() or "disconnected"),
		[3] = (IsValid(ply) and ply:SteamID() or "<Disconnected Player>"),
		[4] = credits
	})
end

function event:ToString(v)
	return string.format("%s [%s] %s %s credit%s", v[1], Damagelog:StrRole(v[2]), v[4]>0 and "received" or "used", v[4]>0 and v[4] or -v[4], v[4] > 1 and "s" or "")
end

function event:IsAllowed(tbl)
	return Damagelog.filter_settings["Show credit changes"]
end

function event:Highlight(line, tbl, text)
	if table.HasValue(Damagelog.Highlighted, tbl[1]) or table.HasValue(Damagelog.Highlighted, tbl[4]) then
		return true
	end
	return false
end

function event:GetColor(tbl)
	return Damagelog:GetColor("Credits")
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)
	line:ShowCopy(true, { tbl[1], tbl[3] })
end

Damagelog:AddEvent(event)