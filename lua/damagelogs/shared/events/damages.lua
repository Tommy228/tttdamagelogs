if SERVER then
	Damagelog:EventHook("Initialize")
	Damagelog:EventHook("PlayerTakeRealDamage")
else
	Damagelog:AddFilter("filter_show_damages", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("color_team_damages", Color(255, 40, 40))
	Damagelog:AddColor("color_damages", Color(0, 0, 0))
end

local event = {}

event.Type = "DMG"
event.IsDamage = true

function event:Initialize()
	local old_func = GAMEMODE.PlayerTakeDamage
	function GAMEMODE:PlayerTakeDamage(ent, infl, att, amount, dmginfo)
		local original_dmg = dmginfo:GetDamage()
		if IsValid(att) then
			old_func(self, ent, infl, att, amount, dmginfo)
		end
		hook.Call("PlayerTakeRealDamage", GAMEMODE, ent, dmginfo, original_dmg)
	end
end

function event:PlayerTakeRealDamage(ent, dmginfo, original_dmg)

	local att = dmginfo:GetAttacker()
	if not (ent.IsGhost and ent:IsGhost()) and ent:IsPlayer() and (IsValid(att) and att:IsPlayer()) and ent != att then
		if math.floor(original_dmg) > 0 then
			local tbl = {
				[1] = ent:GetDamagelogID() ,
				[2] = att:GetDamagelogID(),
				[3] = math.Round(dmginfo:GetDamage()),
				[4] = Damagelog:WeaponFromDmg(dmginfo),
				[5] = math.Round(original_dmg)
			}
			if Damagelog:IsTeamkill(ent:GetRole(), att:GetRole()) then
				tbl.icon = { "icon16/exclamation.png" }
			elseif Damagelog.Time then
				local found_dmg = false
				for k,v in pairs(Damagelog.DamageTable) do
					if type(v) == "table" and Damagelog.events[v.id] and Damagelog.events[v.id].IsDamage then
						if v.time >= Damagelog.Time - 10 and v.time <= Damagelog.Time then
							found_dmg = true
							break
						end
					end
				end
				if not found_dmg then
					local first
					local shoots = {}
					for k,v in pairs(Damagelog.ShootTables[Damagelog.CurrentRound] or {}) do
						if k >= Damagelog.Time - 10 and k <= Damagelog.Time then
							shoots[k] = v
						end
					end
					for k,v in pairs(shoots) do
						if not first or k < first  then
							first = k
						end
					end
					if shoots[first] then
						for k,v in pairs(shoots[first]) do
							if v[1] == ent:Nick() then
								tbl.icon = { "icon16/error.png", TTTLogTranslate(GetDMGLogLang, "VictimShotFirst") }
							end
						end
					end
				end
			end
			self.CallEvent(tbl)
		end
	end

end

function event:ToString(tbl, roles)

	local weapon = tbl[4]
	weapon = Damagelog:GetWeaponName(weapon)
	local karma_reduced = tbl[3] < tbl[5]
	local ent = Damagelog:InfoFromID(roles, tbl[1])
	local att = Damagelog:InfoFromID(roles, tbl[2])
	local str = string.format(TTTLogTranslate(GetDMGLogLang, "HasDamaged"), att.nick, Damagelog:StrRole(att.role), ent.nick, Damagelog:StrRole(ent.role), tbl[3])
	if karma_reduced then
		str = str .. string.format(" (%s)", tbl[5])
	end
	return str .. string.format(TTTLogTranslate(GetDMGLogLang, "HPWeapon"), weapon or TTTLogTranslate(GetDMGLogLang, "UnknownWeapon"))

end

function event:IsAllowed(tbl)
	return Damagelog.filter_settings["filter_show_damages"]
end

function event:Highlight(line, tbl, text)
	if table.HasValue(Damagelog.Highlighted, tbl[1]) or table.HasValue(Damagelog.Highlighted, tbl[2]) then
		return true
	end
	return false
end

function event:GetColor(tbl, roles)

	local ent = Damagelog:InfoFromID(roles, tbl[1])
	local att = Damagelog:InfoFromID(roles, tbl[2])
	if Damagelog:IsTeamkill(att.role, ent.role) then
		return Damagelog:GetColor("color_team_damages")
	else
		return Damagelog:GetColor("color_damages")
	end

end

function event:RightClick(line, tbl, roles, text)

	line:ShowTooLong(true)
	local attackerInfo = Damagelog:InfoFromID(roles, tbl[1])
	local victimInfo = Damagelog:InfoFromID(roles, tbl[2])
	line:ShowCopy(true, { attackerInfo.nick, util.SteamIDFrom64(attackerInfo.steamid64) }, { victimInfo.nick, util.SteamIDFrom64(victimInfo.steamid64) })
	line:ShowDamageInfos(tbl[2], tbl[1])

end

Damagelog:AddEvent(event)
