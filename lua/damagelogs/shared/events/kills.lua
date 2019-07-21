if SERVER then
    Damagelog:EventHook("DoPlayerDeath")
else
    Damagelog:AddFilter("filter_show_kills", DAMAGELOG_FILTER_BOOL, true)
    Damagelog:AddColor("color_team_kills", Color(255, 40, 40))
    Damagelog:AddColor("color_kills", Color(255, 128, 0, 255))
end

local event = {}
event.Type = "KILL"

function event:DoPlayerDeath(ply, attacker, dmginfo)
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= ply and not (attacker.IsGhost and attacker:IsGhost()) then
        local scene = false
        Damagelog.SceneID = Damagelog.SceneID + 1
        scene = Damagelog.SceneID
        Damagelog.SceneRounds[scene] = Damagelog.CurrentRound

        local tbl = {
            [1] = attacker:GetDamagelogID(),
            [2] = ply:GetDamagelogID(),
            [3] = Damagelog:WeaponFromDmg(dmginfo),
            [4] = scene
        }

        self.CallEvent(tbl)

        if scene then
            timer.Simple(0.6, function()
                Damagelog.Death_Scenes[scene] = table.Copy(Damagelog.Records)
            end)
        end

        if GetRoundState() == ROUND_ACTIVE then
            net.Start("DL_Ded")

            if not ROLES and attacker:GetRole() == ROLE_TRAITOR and (ply:GetRole() == ROLE_INNOCENT or ply:GetRole() == ROLE_DETECTIVE) or ROLES and attacker:HasTeamRole(TEAM_TRAITOR) and not ply:HasTeamRole(TEAM_TRAITOR) then
                net.WriteUInt(0, 1)
            else
                net.WriteUInt(1, 1)
                net.WriteString(attacker:Nick())
            end

            net.Send(ply)
            ply:SetNWEntity("DL_Killer", attacker)
        end
    end
end

function event:ToString(v, roles)
    local weapon = v[3]
    weapon = Damagelog:GetWeaponName(weapon)
    local attackerInfo = Damagelog:InfoFromID(roles, v[1])
    local victimInfo = Damagelog:InfoFromID(roles, v[2])

    return string.format(TTTLogTranslate(GetDMGLogLang, "HasKilled"), attackerInfo.nick, Damagelog:StrRole(attackerInfo.role), victimInfo.nick, Damagelog:StrRole(victimInfo.role), weapon or TTTLogTranslate(GetDMGLogLang, "UnknownWeapon"))
end

function event:IsAllowed(tbl)
    return Damagelog.filter_settings["filter_show_kills"]
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

    if Damagelog:IsTeamkill(player.GetBySteamID64(att.steamid64), player.GetBySteamID64(ent.steamid64)) then
        return Damagelog:GetColor("color_team_kills")
    else
        return Damagelog:GetColor("color_kills")
    end
end

function event:RightClick(line, tbl, roles, text)
    local attackerInfo = Damagelog:InfoFromID(roles, tbl[1])
    local victimInfo = Damagelog:InfoFromID(roles, tbl[2])
    line:ShowTooLong(true)
    line:ShowCopy(true, {attackerInfo.nick, util.SteamIDFrom64(attackerInfo.steamid64)}, {victimInfo.nick, util.SteamIDFrom64(victimInfo.steamid64)})
    line:ShowDamageInfos(tbl[1], tbl[2])
    line:ShowDeathScene(tbl[2], tbl[1], tbl[4])
end

Damagelog:AddEvent(event)