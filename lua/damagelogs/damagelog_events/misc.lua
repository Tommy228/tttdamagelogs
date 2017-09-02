
if SERVER then
	Damagelog:EventHook("TTTPlayerDisguised")
	Damagelog:EventHook("TTTBeginRound")
	Damagelog:EventHook("Initialize")
else
	Damagelog:AddFilter("Show disguisings", DAMAGELOG_FILTER_BOOL, false)
	Damagelog:AddFilter("Show teleports", DAMAGELOG_FILTER_BOOL, true)
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
	local weap = weapons.GetStored("weapon_ttt_teleport")
	local old_func = weap.TakePrimaryAmmo
	weap.TakePrimaryAmmo = function(wep, count)
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

function event:ToString(v)
	local text
	if v[1] == 1 then
		return string.format("%s [%s] %s their disguiser", v[2], Damagelog:StrRole(v[3]), v[5] and "enabled" or "disabled")
	elseif v[1] == 2 then
		return string.format("%s [%s] teleported", v[2], Damagelog:StrRole(v[3]))
	elseif v[1] == 3 then
		return string.format("%s [%s] is spamming their disguiser. Disguise logging will be stopped.", v[2], Damagelog:StrRole(v[3]))
	end
end

function event:IsAllowed(tbl)
	if (tbl[1] == 1 or tbl[1] == 3) and not Damagelog.filter_settings["Show disguisings"] then return false end
	if tbl[1] == 2 and not Damagelog.filter_settings["Show teleports"] then return false end
	return true
end

function event:Highlight(line, tbl, text)
	return table.HasValue(Damagelog.Highlighted, tbl[1])
end

function event:GetColor(tbl)
	return Damagelog:GetColor("Misc")
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)
	line:ShowCopy(true, { tbl[2], tbl[4] })
end

Damagelog:AddEvent(event)