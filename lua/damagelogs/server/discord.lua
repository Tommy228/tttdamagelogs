local POST_MODES = {
    DISABLED = 0,
    WHEN_ADMINS_OFFLINE = 1,
    ALWAYS = 2
}

local HTTP = HTTP
local url = CreateConVar("ttt_dmglogs_discordurl", "", FCVAR_PROTECTED + FCVAR_LUA_SERVER, "TTTDamagelogs - Discord Webhook URL")
local disabled = Damagelog.DiscordWebhookMode == POST_MODES.DISABLED
local emitOnlyWhenAdminsOffline = Damagelog.DiscordWebhookMode == POST_MODES.WHEN_ADMINS_OFFLINE
local limit = 5
local reset = 0


local function SendDiscordMessage(embed)
    local now = os.time(os.date("!*t"))

    if limit == 0 and now < reset then
        local function tcb()
            SendDiscordMessage(data)
        end

        timer.Simple(reset - now, tcb)
    end

    local function successCallback(status, body, headers)
        limit = headers["X-RateLimit-Remaining"]
        reset = headers["X-RateLimit-Reset"]
    end

    HTTP({
        method = "POST",
        url = url:GetString(),
        body = util.TableToJSON({
            embeds = {embed}
        }),
        type = "application/json",
        success = successCallback
    })
end


function Damagelog:DiscordMessage(discordUpdate)
    if disabled or (emitOnlyWhenAdminsOffline and discordUpdate.adminOnline) then
        return
    end

    local data = {
        title = TTTLogTranslate(nil, "ReportCreated"):format(discordUpdate.reportId),
        description = TTTLogTranslate(nil, "webhook_ServerInfo"):format(game.GetMap(), discordUpdate.round),
        fields = {
            {
                name = TTTLogTranslate(nil, "Victim"),
                value = "[" .. discordUpdate.victim.nick:gsub("([%*_~<>\\@%]])", "\\%1") .. "](https://steamcommunity.com/profiles/" .. util.SteamIDTo64(discordUpdate.victim.steamID) .. ")",
                inline = true
            },
            {
                name = TTTLogTranslate(nil, "ReportedPlayer"),
                value = "[" .. discordUpdate.attacker.nick:gsub("([%*_~<>\\@%]])", "\\%1") .. "](https://steamcommunity.com/profiles/" .. util.SteamIDTo64(discordUpdate.attacker.steamID) .. ")",
                inline = true
            },
            {
                name = TTTLogTranslate(nil, "VictimsReport"),
                value = discordUpdate.reportMessage:gsub("([%*_~<>\\@[])", "\\%1")
            }
        },
        color = 0xffff00
    }

    if discordUpdate.responseMessage != nil then
        local forgivenRow = {
            name = TTTLogTranslate(nil, "ReportedPlayerResponse"),
            value = discordUpdate.responseMessage:gsub("([%*_~<>\\@[])", "\\%1")
        }
        table.insert(data.fields, forgivenRow)
    end

    if discordUpdate.reportForgiven != nil then
        local rowMessage = ""
        if discordUpdate.reportForgiven.forgiven then
            data.color = 0x00ff00
            rowMessage = "Forgiven" // TODO: Translate
        else
            data.color = 0xff0000
            rowMessage = "Kept" // TODO: Translate
        end

        local forgivenRow = {
            name = "Forgiven / Kept?", // TODO: Translate
            value = rowMessage
        }
        table.insert(data.fields, forgivenRow)
    end

    if discordUpdate.reportHandled != nil then
        data.color = 0x8888ff

        local rowMessage = "[" .. discordUpdate.reportHandled.admin.nick:gsub("([%*_~<>\\@%]])", "\\%1") .. "](https://steamcommunity.com/profiles/" .. util.SteamIDTo64(discordUpdate.reportHandled.admin.steamID) .. ")"

        local reportHandlerRow = {
            name = "Report handled by", // TODO: Translate
            value = rowMessage
        }
        table.insert(data.fields, reportHandlerRow)
    end

    if emitOnlyWhenAdminsOffline == false then
        data.footer = {
            text = TTTLogTranslate(nil, discordUpdate.adminOnline and "webhook_AdminsOnline" or "webhook_NoAdminsOnline")
        }
    end

    SendDiscordMessage(data)
end
