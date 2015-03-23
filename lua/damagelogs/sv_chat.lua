
util.AddNetworkString("DL_StartChat")
util.AddNetworkString("DL_OpenChat")

Damagelog.CurrentChat = Damagelog.CurrentChat or {}

local function GetFilter(chat)
	local filter = {}
	if IsValid(chat.victim) then
		table.insert(filter, chat.victim)
	end
	if IsValid(chat.attacker) then
		table.insert(filter, chat.attacker)
	end
	local function process(tbl)
		for k,v in pairs(tbl) do
			if IsValid(v) then
				table.insert(filter, v)
			end
		end
	end
	process(chat.players)
	process(chat.admins)
	return filter
end
	

net.Receive("DL_StartChat", function(_len, ply)

	local report_index = net.ReadUInt(32)

	if not ply:IsAdmin() then return end

	local report = Damagelog.Reports.Current[report_index]
	
	local victim
	local attacker
	
	for k,v in pairs(player.GetAll()) do
		if v:SteamID() == report.victim then
			victim = v
		elseif v:SteamID() == report.attacker then
			attacker = v
		elseif attacker and victim then
			break
		end
	end
	
	if not IsValid(victim) or not IsValid(attacker) then
		ply:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, "The victim or the reported player are disconnected!", 5, "buttons/weapon_cant_buy.wav")
		return 		
	end
	
	for k,v in pairs(Damagelog.CurrentChat) do
		if v.reportindex == report_index then
			--ply:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, "There is already a chat for this report!", 5, "buttons/weapon_cant_buy.wav")
			return
		end
	end
	
	local id = table.insert(Damagelog.CurrentChat, {
		reportindex = report_index,
		admins = { ply },
		victim = victim,
		attacker = attacker,
		players = {}
	})
	
	net.Start("DL_OpenChat")
	net.WriteEntity(ply)
	net.WriteEntity(victim)
	net.WriteEntity(attacker)
	net.Send(GetFilter(Damagelog.CurrentChat[id]))
	
end)