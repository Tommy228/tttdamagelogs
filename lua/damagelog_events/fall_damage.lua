
if SERVER then
	Damagelog:EventHook("EntityTakeDamage")
else
	Damagelog:AddFilter("Show fall damage", DAMAGELOG_FILTER_BOOL, false)
	Damagelog:AddColor("Team Damage", Color(255, 40, 40))
	Damagelog:AddColor("Fall Damage", Color(0, 0, 0))
end

local event = {}

event.Type = "FD"

-- Fall damage is being weird on TTT (it gets called 2 times), so let's use stupid methods!
function event:EntityTakeDamage(ent, dmginfo)
	local att = dmginfo:GetAttacker()
	if not (ent.IsGhost and ent:IsGhost()) and ent:IsPlayer() and att == game.GetWorld() and dmginfo:GetDamageType() == DMG_FALL then
		local damages = dmginfo:GetDamage()
		if math.floor(damages) > 0 then
			local tbl = { 
				[1] = ent:Nick(), 
				[2] = ent:GetRole(), 
				[3] = math.Round(damages), 
				[4] = ent:SteamID()
			}
			local push = ent.was_pushed
			if push and math.max(push.t or 0, push.hurt or 0) > CurTime() - 4 then
				tbl[5] = true
				tbl[6] = push.att:Nick()
				tbl[7] = push.att:GetRole()
				tbl[8] = push.att:SteamID()
				self.CallEvent(tbl)
			else
				local timername = "timerFallDamage_"..tostring(ent:UniqueID())
				if timer.Exists(timername) then
					if ent.FallDamageTable then
						ent.FallDamageTable[3] = math.Round(ent.FallDamageTable[3]+damages)
					end
				else
					timer.Create(timername, 0.1, 1, function()
						if IsValid(ent) and ent.FallDamageTable then
							self.CallEvent(ent.FallDamageTable, 6, 7)
						end
					end)
					tbl[5] = false
					tbl[6] = Damagelog.Time
					local index = Damagelog.DamageTable[1] == "empty" and #Damagelog.DamageTable or #Damagelog.DamageTable + 1
					tbl[7] = index
					Damagelog.DamageTable[index] = "ignore"
					ent.FallDamageTable = tbl
				end
			end
		end
	end
end

function event:ToString(tbl)
	local t = string.format("%s [%s] fell and lost %s HP", tbl[1], Damagelog:StrRole(tbl[2]), tbl[3]) 	
	if tbl[5] then
		t = t.." after being pushed by "..tbl[6].. " ["..Damagelog:StrRole(tbl[7]).."]"
	end
	return t
end

function event:IsAllowed(tbl)

	local pfilter = Damagelog.filter_settings["Filter by player"]
	if pfilter then 
		if not tbl[5] and tbl[4] != pfilter then
			return false
		elseif tbl[5] and not (tbl[4] == pfilter or tbl[7] == pfilter) then
			return false
		end
	end
	local dfilter = Damagelog.filter_settings["Show fall damage"]
	if not dfilter then return false end
	return true
	
end

function event:GetColor(tbl)
	if tbl[5] and Damagelog:IsTeamkill(tbl[2], tbl[7]) then
		return Damagelog:GetColor("Team Damage")
	else
		return Damagelog:GetColor("Fall Damage")
	end
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)
	line:ShowCopy(true, { tbl[1], tbl[4] }, tbl[5] and { tbl[6], tbl[8] })
end

Damagelog:AddEvent(event)