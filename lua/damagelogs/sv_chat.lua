
util.AddNetworkString("DL_StartChat")
util.AddNetworkString("DL_OpenChat")
util.AddNetworkString("DL_JoinChat")
util.AddNetworkString("DL_SendChatMessage")
util.AddNetworkString("DL_BroadcastMessage")
util.AddNetworkString("DL_JoinChatCL")
util.AddNetworkString("DL_StopChat")
util.AddNetworkString("DL_AddChatPlayer")
util.AddNetworkString("DL_CloseChat")

local COLOR_VICTIM = Color(18, 190, 29)
local COLOR_ATTACKER = Color(190, 18, 29)
local COLOR_ADMIN = Color(160, 160, 0)
local COLOR_OTHER = Color(29, 18, 190)

Damagelog.ChatHistory = Damagelog.ChatHistory or {}

local function GetFilter(chat, block)
	local filter = {}
	if IsValid(chat.victim) and chat.victim != block then
		table.insert(filter, chat.victim)
	end
	if IsValid(chat.attacker) and chat.attacker != block then
		table.insert(filter, chat.attacker)
	end
	local function process(tbl)
		for k,v in pairs(tbl) do
			if v != block and IsValid(v) then
				table.insert(filter, v)
			end
		end
	end
	process(chat.players)
	process(chat.admins)
	return filter
end

local function IsAllowed(ply, chat)
	if chat.victim == ply then
		return true, COLOR_VICTIM
	elseif chat.attacker == ply then
		return true, COLOR_ATTACKER
	elseif table.HasValue(chat.admins, ply) then
		return true, COLOR_ADMIN
	elseif table.HasValue(chat.players, ply) then
		return true, COLOR_OTHER
	end
	return false
end
	

net.Receive("DL_StartChat", function(_len, ply)

	local report_index = net.ReadUInt(32)

	if not ply:CanUseRDMManager() then return end

	local report = Damagelog.Reports.Current[report_index]
	
	if not report then return end
	
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
	
	for k,v in pairs(Damagelog.Reports.Current) do
		if v.chat_open and k == report_index then
			ply:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, "There is already a chat for this report!", 5, "buttons/weapon_cant_buy.wav")
			return
		end
	end
	
	report.chat_open = {
		admins = { ply },
		victim = victim,
		attacker = attacker,
		players = {}
	}
	
	local history = false
	
	if report.chat_opened then
		history = Damagelog.ChatHistory[report_index] or {}
	else
		report.chat_opened = true
		Damagelog.ChatHistory[report_index] = {}
	end
	
	net.Start("DL_OpenChat")
	net.WriteUInt(report_index, 32)
	net.WriteEntity(ply)
	net.WriteEntity(victim)
	net.WriteEntity(attacker)
	if history then
		net.WriteUInt(1, 1)
		local json = util.TableToJSON(history)
		local compressed = util.Compress(json)
		net.WriteUInt(#compressed, 32)
		net.WriteData(compressed, #compressed)
	else
		net.WriteUInt(0, 1)
	end
	net.Send(GetFilter(report.chat_open))
	
	for k,v in pairs(player.GetHumans()) do
		if v:CanUseRDMManager() then	
			if v != ply then
				v:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, ply:Nick().." has opened a chat for the report #"..report_index..".", 5, "")
			end
			v:UpdateReport(false, report_index)
		end
	end
	
end)

local function AddToChat(id, report, ply)

	if not report.chat_open then return end

	local history = Damagelog.ChatHistory[id] or {}
	local json = util.TableToJSON(history)
	local compressed = util.Compress(json)

	local category = DAMAGELOG_OTHER
	
	if ply:CanUseRDMManager() and not table.HasValue(report.chat_open.admins, ply) then
		table.insert(report.chat_open.admins, ply)
		category = DAMAGELOG_ADMIN
	end
	if ply:SteamID() == report.victim then
		report.chat_open.victim = ply
		category = DAMAGELOG_VICTIM
	elseif ply:SteamID() == report.attacker then
		report.chat_open.attacker = ply
		category = DAMAGELOG_REPORTED
	elseif not table.HasValue(report.chat_open.admins, ply) and not table.HasValue(report.chat_open.players, ply) then
		table.insert(report.chat_open.players, ply)
		category = DAMAGELOG_OTHER
	end
	
	net.Start("DL_JoinChatCL")
	net.WriteUInt(1, 1)
	net.WriteUInt(id, 32)
	net.WriteUInt(#compressed, 32)
	net.WriteData(compressed, #compressed)
	net.WriteTable(report.chat_open)
	net.Send(ply)
		
	net.Start("DL_JoinChatCL")
	net.WriteUInt(0, 1)
	net.WriteUInt(id, 32)
	net.WriteEntity(ply)
	net.WriteUInt(category, 32)
	net.Send(GetFilter(report.chat_open, ply))
	
	for k,v in pairs(player.GetHumans()) do
		if v:CanUseRDMManager() then	
			v:UpdateReport(false, id)
		end
	end	
end

net.Receive("DL_JoinChat", function(_len, ply)

	local id = net.ReadUInt(32)
		
	local report = Damagelog.Reports.Current[id]
	if not report or not report.chat_open then return end
	
	if not ply:CanUseRDMManager() then return end

	AddToChat(id, report, ply)
	
end)

net.Receive("DL_SendChatMessage", function(_len, ply)
	
	local id = net.ReadUInt(32)
	local message = net.ReadString()
		
	if #message == 0 or #message > 200 then return end
		
	local report = Damagelog.Reports.Current[id]
	if not report then return end	
		
	local chat = report.chat_open
	if not chat then return end
	
	local allowed, color = IsAllowed(ply, chat)
	if not allowed then return end
	
	table.insert(Damagelog.ChatHistory[id], {
		nick = ply:Nick(),
		color = { r = color.r, g = color.g, b = color.b, a = color.a },
		msg = message
	})
	
	net.Start("DL_BroadcastMessage")
	net.WriteUInt(id, 32)
	net.WriteEntity(ply)
	net.WriteColor(color)
	net.WriteString(message)
	net.Send(GetFilter(chat))
	
end)

hook.Add("PlayerDisconnected", "Damagelog_Chat", function(ply)
	
	for k,v in pairs(Damagelog.Reports.Current) do
		
		if v.chat_open then
			
			if table.HasValue(v.admins, ply) then
				table.RemoveByValue(v.admins, ply)
				if #v.admins == 1 then
					net.Start("DL_StopChat")
					net.WriteUInt(k, 32)
					net.WriteUInt(0, 1)
					net.Send(GetFilter(v.chat_open))
					v.chat_open = false
					for k,v in pairs(player.GetHumans()) do
						if v:CanUseRDMManager() then	
							v:UpdateReport(false, id)
						end
					end	
				end
			end
			if table.HasValue(v.players, ply) then
				table.RemoveByValue(v.players, ply)
			end
		end
	
	end
end)

net.Receive("DL_AddChatPlayer", function(_len, ply)
	
	local id = net.ReadUInt(32)
	local to_add = net.ReadEntity()
	
	if not ply:CanUseRDMManager() then return end
	
	local report = Damagelog.Reports.Current[id]
	if not report then return end
	
	AddToChat(id, report, to_add)
	
	to_add:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, "You have been added to a chat by an admin!", 5, "")

end)

net.Receive("DL_CloseChat", function(_len, ply)
	
	local id = net.ReadUInt(32)
	local to_add = net.ReadEntity()
	
	if not ply:CanUseRDMManager() then return end
	
	local report = Damagelog.Reports.Current[id]
	if not report then return end
	
	if report.chat_open then
		net.Start("DL_StopChat")
		net.WriteUInt(id, 32)
		net.WriteUInt(1, 1)
		net.WriteEntity(ply)
		net.Send(GetFilter(report.chat_open))
		report.chat_open = false
	end
	
	for k,v in pairs(player.GetHumans()) do
		if v:CanUseRDMManager() then	
			v:UpdateReport(false, id)
		end
	end	
	
end)