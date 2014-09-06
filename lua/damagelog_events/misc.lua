
if SERVER then
	Damagelog:EventHook("TTTPlayerDisguised")
	Damagelog:EventHook("TTTBeginRound")
	Damagelog:EventHook("TTTC4Disarm")
	Damagelog:EventHook("TTTC4Destroyed")
	Damagelog:EventHook("TTTC4Pickup")
	Damagelog:EventHook("Initialize")
else
	Damagelog:AddFilter("Show disguisings", DAMAGELOG_FILTER_BOOL, false)
	Damagelog:AddFilter("Show teleports", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddFilter("Show C4 logs", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("Misc", Color(0, 179, 179, 255))
end

local event = {}

event.Type = "MISC"

if SERVER then

	local meta = FindMetaTable("Entity")
	local old_func = meta.SetNWBool
	function meta:SetNWBool(name, value)
		if name == "disguised" and value != self:GetNWBool("disguised") then
			hook.Call("TTTPlayerDisguised", GAMEMODE, self, value)
		end
		old_func(self, name, value)
	end
	
end

if SERVER then
	hook.Add("Initialize", "Initialize_C4Event", function()
		for k,v in pairs(weapons.GetList()) do
			if v.ClassName == "weapon_ttt_c4" then
				local old_stick = v.BombStick
				local old_drop = v.BombDrop
				local function LogC4(bomb)
					event.CallEvent({
						[1] = 7,
						[2] = bomb.Owner:Nick(),
						[3] = bomb.Owner:GetRole(),
						[4] = bomb.Owner:SteamID()
					})
				end
				v.BombStick = function(bomb)
					LogC4(bomb)
					old_stick(bomb)
				end
				v.BombDrop = function(bomb)
					LogC4(bomb)
					old_drop(bomb)
				end
			end
		end
	end)
end

function event:TTTC4Disarm(ply, result, bomb)
	local name = IsValid(bomb:GetOwner()) and bomb:GetOwner():Nick() or "<Disconnected>"
	self.CallEvent({
		[1] = 4,
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
		[1] = 6,
		[2] = ply:Nick(),
		[3] = ply:GetRole(),
		[4] = ply:SteamID(),
		[5] = name
	})
end

function event:TTTC4Destroyed(ply, bomb)
	local name = IsValid(bomb:GetOwner()) and bomb:GetOwner():Nick() or "<Disconnected>"
	self.CallEvent({
		[1] = 5,
		[2] = ply:Nick(),
		[3] = ply:GetRole(),
		[4] = ply:SteamID(),
		[5] = name
	})
end

function event:TTTBeginRound()
	for k,v in pairs(player.GetAll()) do
		if v.NoDisguise then 
			v.NoDisguise = false
		end
	end
end

function event:TTTPlayerDisguised(ply, enabled)
	if ply.NoDisguise then return end
	local timername = "DisguiserTimer_"..tostring(ply:UniqueID())
	if not timer.Exists(timername) then
		ply.DisguiseUses = 1
		ply.DisguiseTimer = 10
		timer.Create(timername, 1, 0, function()
			if not IsValid(ply) then
				timer.Destroy(timername)
			else
				ply.DisguiseTimer = ply.DisguiseTimer - 1
				if ply.DisguiseTimer <= 0 then
					timer.Destroy(timername)
				end
				if ply.DisguiseUses > 6 then
					ply.NoDisguise = true
					self.CallEvent({
						[1] = 3,
						[2] = ply:Nick(),
						[3] = ply:GetRole(),
						[4] = ply:SteamID()
					})
					timer.Destroy(timername)
				end
			end
		end)
	else
		if ply.DisguiseUses and ply.DisguiseTimer then
			ply.DisguiseUses = ply.DisguiseUses + 1
			ply.DisguiseTimer = ply.DisguiseTimer + 1
		end
	end
	self.CallEvent({
		[1] = 1,
		[2] = ply:Nick(),
		[3] = ply:GetRole(),
		[4] = ply:SteamID(),
		[5] = enabled
	})
end

function event:Initialize()
	for k,v in pairs(weapons.GetList()) do
		if v.ClassName == "weapon_ttt_teleport" then
			local old_func = v.TakePrimaryAmmo
			v.TakePrimaryAmmo = function(wep, count)
				self.CallEvent({
					[1] = 2,
					[2] = wep.Owner:Nick(),
					[3] = wep.Owner:GetRole(),
					[4] = wep.Owner:SteamID()
				})
				if old_func then
					return old_func(wep, count)
				else
					return wep.BaseClass.TakePrimaryAmmo(wep, count)
				end
			end
		end
	end
end

function event:ToString(v)
	local text
	if v[1] == 1 then
		return string.format("%s [%s] has %s their disguiser", v[2], Damagelog:StrRole(v[3]), v[5] and "enabled" or "disabled")
	elseif v[1] == 2 then
		return string.format("%s [%s] has teleported", v[2], Damagelog:StrRole(v[3]))
	elseif v[1] == 3 then
		return string.format("%s [%s] is spamming their disguiser. Disguise logging will be stopped.", v[2], Damagelog:StrRole(v[3]))
	elseif v[1] == 4 then
		return string.format("%s [%s] has disarmed the C4 of %s %s success.", v[2], Damagelog:StrRole(v[3]), v[5], v[6] and "with" or "without")
	elseif v[1] == 5 then
		return string.format("%s [%s] has destroyed the C4 of %s.", v[2], Damagelog:StrRole(v[3]), v[5])
	elseif v[1] == 6 then
		return string.format("%s [%s] has picked up the C4 of %s.", v[2], Damagelog:StrRole(v[3]), v[5])
	elseif v[1] == 7 then
		return string.format("%s [%s] planted or dropped a C4", v[2], Damagelog:StrRole(v[3]))
	end
end

function event:IsAllowed(tbl)
	local pfilter = Damagelog.filter_settings["Filter by player"]
	if pfilter then
		if tbl[4] != pfilter then return false end
	end
	if (tbl[1] == 1 or tbl[1] == 3) and not Damagelog.filter_settings["Show disguisings"] then return false end
	if tbl[1] == 2 and not Damagelog.filter_settings["Show teleports"] then return false end
	if (tbl[1] == 4 or tbl[1] == 5 or tbl[1] == 6 or tbl[1] == 7) and not Damagelog.filter_settings["Show C4 logs"] then return false end
	return true
end

function event:GetColor(tbl)
	return Damagelog:GetColor("Misc")
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)
	line:ShowCopy(true, { tbl[2], tbl[4] })
end

Damagelog:AddEvent(event)