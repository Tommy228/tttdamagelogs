local HTTP = HTTP

local url = CreateConVar("ttt_dmglogs_discordurl", "", FCVAR_PROTECTED + FCVAR_LUA_SERVER, "TTTDamagelogs - Discord Webhook URL")
local disabled = Damagelog.DiscordWebhookMode == 0
local noadmins = Damagelog.DiscordWebhookMode == 1

local limit
local reset = 0

local function post(embed)
	local now = os.time(os.date("!*t"))

	if limit == 0 and now < reset then
		local function tcb()
			post(data)
		end
		timer.Simple(reset - now, tcb)
	end

	local function cb(_, _, headers)
		limit = headers["X-RateLimit-Remaining"]
		reset = headers["X-RateLimit-Reset"]
	end

	HTTP({
		method = "POST",
		url = url:GetString(),
		body = util.TableToJSON({embeds = {embed}}),
		type = "application/json",
		success = cb
	})
end

function Damagelog:DiscordMessage(report, adminOnline)
	if disabled or adminOnline and noadmins then return end

	local data = {
		author = {name = TTTLogTranslate(nil, "ReportCreated")},
		title = TTTLogTranslate(nil, "webhook_ServerInfo"):format(game.GetMap(), report.round),
		fields = {
			{
				name = TTTLogTranslate(nil, "Victim"),
				value = "["..report.victim_nick:gsub("([%*_~<>\\@%]])", "\\%1").."](".."https://steamcommunity.com/profiles/"..util.SteamIDTo64(report.victim)..")",
				inline = true
			},
			{
				name = TTTLogTranslate(nil, "ReportedPlayer"),
				value = "["..report.attacker_nick:gsub("([%*_~<>\\@%]])", "\\%1").."](".."https://steamcommunity.com/profiles/"..util.SteamIDTo64(report.attacker)..")",
				inline = true
			},
			{
				name = TTTLogTranslate(nil, "VictimsReport"),
				value = report.message:gsub("([%*_~<>\\@[])", "\\%1")
			}
		},
		color = adminOnline and 0xffff00 or 0xff0000
	}

	if not noadmins then data.footer = {text = TTTLogTranslate(nil, adminOnline and "webhook_AdminsOnline" or "webhook_NoAdminsOnline")} end

	post(data)
end