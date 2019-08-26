if SERVER then
    Damagelog:EventHook("TTTEquipmentUse")
else
    Damagelog:AddFilter("filter_show_equipment_usage", DAMAGELOG_FILTER_BOOL, true)
end

local EVENT_DETAILS = {
    ID = 1,
    UserId = 2,
    UserName = 3,
    UserRole = 4,
    UserSteamID = 5,
    EquipmentClass = 6,
    ExtraInfo = 7
}

local EVENT_IDS = {
    EQUIPMENT_USE = 1
}

local event = {}
event.Type = "WEP"

function event:TTTEquipmentUse(ply, equipment, info)
    event.CallEvent({
        [EVENT_DETAILS.ID] = EVENT_IDS.EQUIPMENT_USE,
        [EVENT_DETAILS.UserId] = ply:GetDamagelogID(),
        [EVENT_DETAILS.UserName] = ply:Nick(),
        [EVENT_DETAILS.UserRole] = ply:GetRole(),
        [EVENT_DETAILS.UserSteamID] = ply:SteamID(),
        [EVENT_DETAILS.EquipmentClass] = equipment:GetClass(),
        [EVENT_DETAILS.ExtraInfo] = info
    })
end

function event:ToString(eventInfo)
    if eventInfo[EVENT_DETAILS.ID] == EVENT_IDS.EQUIPMENT_USE then
        local translateString = TTTLogTranslate(GetDMGLogLang, "HasUsed")
        return string.format(translateString,
            eventInfo[EVENT_DETAILS.UserName],
            Damagelog:StrRole(eventInfo[EVENT_DETAILS.UserRole]),
            Damagelog:GetWeaponName(eventInfo[EVENT_DETAILS.EquipmentClass]),
            eventInfo[EVENT_DETAILS.ExtraInfo])
    end
end

function event:IsAllowed(tbl)
    return Damagelog.filter_settings["filter_show_equipment_usage"]
end

function event:Highlight(line, tbl, text)
    return table.HasValue(Damagelog.Highlighted, tbl[EVENT_DETAILS.UserId])
end

function event:GetColor(tbl)
    return Damagelog:GetColor("color_purchases")
end

function event:RightClick(line, tbl, text)
    line:ShowTooLong(true)
    line:ShowCopy(true, {tbl[EVENT_DETAILS.UserName], tbl[EVENT_DETAILS.UserSteamID]})
end

Damagelog:AddEvent(event)