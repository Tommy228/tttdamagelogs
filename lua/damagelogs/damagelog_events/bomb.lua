
if SERVER then
	Damagelog:EventHook("TTTC4Arm")
	Damagelog:EventHook("TTTC4Disarm")
	Damagelog:EventHook("TTTC4Destroyed")
	Damagelog:EventHook("TTTC4Pickup")
	Damagelog:EventHook("Initialize")
else
	Damagelog:AddFilter("Show C4 logs", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("C4", Color(0, 179, 179, 255))
end

local event = {}

EVENT_C4_DROP    = 1
EVENT_C4_ARM     = 2
EVENT_C4_DISARM  = 3
EVENT_C4_DESTROY = 4
EVENT_C4_PICKUP  = 5

event.Type = "C4"

function event:TTTC4Disarm(ply, result, bomb)
	local name = IsValid(bomb:GetOwner()) and bomb:GetOwner():Nick() or "<Disconnected>"
	self.CallEvent({
		[1] = EVENT_C4_DISARM,
		[2] = ply:Nick(),
		[3] = ply:GetRole(),
		[4] = ply:SteamID(),
		[5] = name,
		[6] = result
	})
end

function event:TTTC4Pickup(ply, bomb)
	local name = IsValid(bomb:GetOwner()) and bomb:GetOwner():Nick() or "<Disconnected>"
	self.CallEvent({
		[1] = EVENT_C4_PICKUP,
		[2] = ply:Nick(),
		[3] = ply:GetRole(),
		[4] = ply:SteamID(),
		[5] = name
	})
end

function event:TTTC4Destroyed(ply, bomb)
	local name = IsValid(bomb:GetOwner()) and bomb:GetOwner():Nick() or "<Disconnected>"
	self.CallEvent({
		[1] = EVENT_C4_DESTROY,
		[2] = ply:Nick(),
		[3] = ply:GetRole(),
		[4] = ply:SteamID(),
		[5] = name
	})
end

function event:TTTC4Arm(ply, bomb)
	local name = IsValid(bomb:GetOwner()) and bomb:GetOwner():Nick() or "<Disconnected>"
	self.CallEvent({
		[1] = EVENT_C4_ARM,
		[2] = ply:Nick(),
		[3] = ply:GetRole(),
		[4] = ply:SteamID(),
		[5] = name
	})
end

function event:Initialize()
	local weap = weapons.GetStored("weapon_ttt_c4")
	local old_stick = weap.BombStick
	local old_drop = weap.BombDrop
	local function LogC4(bomb)
		event.CallEvent({
			[1] = EVENT_C4_DROP,
			[2] = bomb.Owner:Nick(),
			[3] = bomb.Owner:GetRole(),
			[4] = bomb.Owner:SteamID()
		})
	end
	weap.BombStick = function(bomb)
		LogC4(bomb)
		old_stick(bomb)
	end
	weap.BombDrop = function(bomb)
		LogC4(bomb)
		old_drop(bomb)
	end
end

function event:ToString(v)
	local text
	if v[1] == EVENT_C4_DROP then
		return string.format("%s [%s] planted or dropped a C4", v[2], Damagelog:StrRole(v[3]))
	elseif v[1] == EVENT_C4_ARM then
		local str = string.format("%s [%s] armed a C4", v[2], Damagelog:StrRole(v[3]))
		if v[2] != v[5] then str = string.format("%s owned by %s", str, v[5]) end
		return str
	elseif v[1] == EVENT_C4_DISARM then
		return string.format("%s [%s] disarmed the C4 of %s %s success.", v[2], Damagelog:StrRole(v[3]), v[5], v[6] and "with" or "without")
	elseif v[1] == EVENT_C4_DESTROY then
		return string.format("%s [%s] destroyed the C4 of %s.", v[2], Damagelog:StrRole(v[3]), v[5])
	elseif v[1] == EVENT_C4_PICKUP then
		return string.format("%s [%s] picked up the C4 of %s.", v[2], Damagelog:StrRole(v[3]), v[5])
	end
end

function event:IsAllowed(tbl)
	return Damagelog.filter_settings["Show C4 logs"]
end

function event:Highlight(line, tbl, text)
	return table.HasValue(Damagelog.Highlighted, tbl[1])
end

function event:GetColor(tbl)
	return Damagelog:GetColor("C4")
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)
	line:ShowCopy(true, { tbl[2], tbl[4] })
end

Damagelog:AddEvent(event)