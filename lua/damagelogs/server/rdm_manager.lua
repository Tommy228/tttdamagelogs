util.AddNetworkString("DL_AllowReport")
util.AddNetworkString("DL_AllowMReports")
util.AddNetworkString("DL_ReportPlayer")
util.AddNetworkString("DL_UpdateReports")
util.AddNetworkString("DL_UpdateReport")
util.AddNetworkString("DL_NewReport")
util.AddNetworkString("DL_UpdateStatus")
util.AddNetworkString("DL_SendReport")
util.AddNetworkString("DL_SendAnswer")
util.AddNetworkString("DL_SendForgive")
util.AddNetworkString("DL_GetForgive")
util.AddNetworkString("DL_Death")
util.AddNetworkString("DL_Answering")
util.AddNetworkString("DL_Answering_global")
util.AddNetworkString("DL_ForceRespond")
util.AddNetworkString("DL_StartReport")
util.AddNetworkString("DL_SendLang")
util.AddNetworkString("DL_Conclusion")
util.AddNetworkString("DL_AskOwnReportInfo")
util.AddNetworkString("DL_SendOwnReportInfo")

net.Receive("DL_SendLang", function(_, ply)
	ply.DMGLogLang = net.ReadString()
end)

Damagelog.Reports = Damagelog.Reports or {
	Current = {}
}

Damagelog.getmreports = {
	id = {
		index,
		victim,
		message
	}
}

if not Damagelog.Reports.Previous then
	if file.Exists("damagelog/prevreports.txt", "DATA") then
		Damagelog.Reports.Previous = util.JSONToTable(file.Read("damagelog/prevreports.txt", "DATA"))
		file.Delete("damagelog/prevreports.txt")
	else
		Damagelog.Reports.Previous = {}
	end
end

local function GetBySteamID(steamid)
	for k, v in pairs(player.GetAll()) do
		if v:SteamID() == steamid then return v end
	end
end

local function UpdatePreviousReports()
	local tbl = table.Copy(Damagelog.Reports.Current)

	for k, v in pairs(tbl) do
		v.previous = true
	end

	file.Write("damagelog/prevreports.txt", util.TableToJSON(tbl))
end

local Player = FindMetaTable("Player")

function Player:RemainingReports()
	return 2 - #self.Reported
end

function Player:UpdateReports()
	if not self:CanUseRDMManager() then return end
	local tbl = util.TableToJSON(Damagelog.Reports)
	if not tbl then return end
	local compressed = util.Compress(tbl)
	if not compressed then return end
	net.Start("DL_UpdateReports")
	net.WriteUInt(#compressed, 32)
	net.WriteData(compressed, #compressed)
	net.Send(self)
end

function Player:NewReport(report)
	if not self:CanUseRDMManager() then return end
	net.Start("DL_NewReport")
	net.WriteTable(report)
	net.Send(self)
end

function Player:UpdateReport(previous, index)
	if not self:CanUseRDMManager() then return end
	local tbl = previous and Damagelog.Reports.Previous[index] or Damagelog.Reports.Current[index]
	if not tbl then return end
	net.Start("DL_UpdateReport")
	net.WriteUInt(previous and 1 or 0, 1)
	net.WriteUInt(index, 8)
	net.WriteTable(tbl)
	net.Send(self)
end

function Player:SendReport(tbl)
	if tbl.chat_opened then return end
	net.Start("DL_SendReport")
	net.WriteTable(tbl)
	net.Send(self)
end

hook.Add("PlayerSay", "Damagelog_RDMManager", function(ply, text, teamOnly)
	if Damagelog.RDM_Manager_Enabled then
		if (string.Left(string.lower(text), #Damagelog.RDM_Manager_Command) == Damagelog.RDM_Manager_Command) then
			Damagelog:StartReport(ply)

			return ""
		elseif (Damagelog.Respond_Command and string.Left(string.lower(text), #Damagelog.Respond_Command) == Damagelog.Respond_Command) then
			net.Start("DL_Death")
			net.Send(ply)
		elseif (Damagelog.Previous_Command and string.Left(string.lower(text), #Damagelog.Previous_Command) == Damagelog.Previous_Command) then
			Damagelog:GetMReports(ply)

			return ""
		end
	end
end)

hook.Add("TTTBeginRound", "Damagelog_RDMManger", function()
	for k, v in pairs(player.GetHumans()) do
		if not v.CanReport then
			v.CanReport = true
		end

		table.Empty(v.Reported)
	end
end)

net.Receive("DL_StartReport", function(length, ply)
	Damagelog:StartReport(ply)
end)

function Damagelog:SendLogToVictim(tbl)
	local victim = player.GetBySteamID(tbl.victim)
	if not IsValid(victim) then return end
	net.Start("DL_SendOwnReportInfo")
	net.WriteTable(tbl)
	net.Send(victim)
end

function Damagelog:GetMReports(ply)
	if not IsValid(ply) then return end
	local found = false

	if not ply.CanReport then
		ply:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(ply.DMGLogLang, "NeedToPlay"), 4, "buttons/weapon_cant_buy.wav")
	else
		for k, v in pairs(Damagelog.Reports.Current) do
			if #v.victim > 0 then
				if v.victim ~= ply:SteamID() then return end
				found = true
				net.Start("DL_AllowMReports")
				net.WriteTable(v)
				net.Send(ply)
			end
		end
		if not found then
			ply:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(ply.DMGLogLang, "HaventReported"), 4, "buttons/weapon_cant_buy.wav")
		end
	end
end

net.Receive("DL_AskOwnReportInfo", function(length, ply)
	local previous = net.ReadUInt(1) == 1
	local index = net.ReadUInt(16)
	local tbl = previous and Damagelog.Reports.Previous[index] or Damagelog.Reports.Current[index]
	if tbl.victim != ply:SteamID() then return end
	net.Start("DL_SendOwnReportInfo")
	net.WriteTable(tbl)
	net.Send(ply)
end)

function Damagelog:GetPlayerReportsList(ply)
	local steamid = ply:SteamID()
	
	local previous = {}
	for k,v in pairs(Damagelog.Reports.Previous) do
		if v.victim == steamid then
			table.insert(previous, {
				index = v.index,
				attackerName = v.attacker_nick,
				attackerID = v.attacker
			})
		end
	end 

	local current = {}
	for k,v in pairs(Damagelog.Reports.Current) do
		if v.victim == steamid then
			local tbl = {
				index = v.index,
				attackerName = v.attacker_nick,
				attackerID = v.attacker
			}
			if not current[v.round] then
				current[v.round] = { tbl }
			else
				table.insert(current[v.round], tbl)
			end
		end
	end

	return previous, current
end

function Damagelog:StartReport(ply)
	if not IsValid(ply) then return end

	net.Start("DL_AllowReport")

	if ply.DeathDmgLog then
		net.WriteUInt(1, 1)
		net.WriteTable(ply.DeathDmgLog)
	else
		net.WriteUInt(0, 1)
	end

	local previousReports, currentReports = Damagelog:GetPlayerReportsList(ply)
	net.WriteTable(previousReports)
	net.WriteTable(currentReports)

	local tbl = player.GetAll()
	net.WriteUInt(#tbl, 8)
	for k,v in pairs(player.GetAll()) do
		net.WriteEntity(v)
		if v.DmgLog_DNA and v.DmgLog_DNA[Damagelog.CurrentRound] and v.DmgLog_DNA[Damagelog.CurrentRound][ply] then
			net.WriteUInt(1, 1)
		else
			net.WriteUInt(0, 1)
		end
	end

	net.Send(ply)
end

local function OnDNAFound(ply, killer, corpse)
	if not ply.DmgLog_DNA then
		ply.DmgLog_DNA = {}
	end
	if not ply.DmgLog_DNA[Damagelog.CurrentRound] then
		ply.DmgLog_DNA[Damagelog.CurrentRound] = {}
	end
	ply.DmgLog_DNA[Damagelog.CurrentRound][killer] = true
end
hook.Add("TTTFoundDNA", "Damagelog", OnDNAFound)

net.Receive("DL_ReportPlayer", function(_len, ply)
	local attacker = net.ReadEntity()
	local message = net.ReadString()
	local reportType = net.ReadUInt(3)
	if not ply:CanUseRDMManager() then
		reportType = DAMAGELOG_REPORT_STANDARD
	end

	message = string.gsub(message, "%s+", " ")

	if not ply:CanUseRDMManager() then

		for k, v in pairs(player.GetHumans()) do
			if v:CanUseRDMManager() then
				found = true
				break
			end
		end

		if not found then
			ply:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(ply.DMGLogLang, "NoAdmins"), 4, "buttons/weapon_cant_buy.wav")
			return
		end

		if not ply.CanReport then
			ply:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(ply.DMGLogLang, "NeedToPlay"), 4, "buttons/weapon_cant_buy.wav")
			return
		else
			local remaining_reports = ply:RemainingReports()

			if remaining_reports <= 0 then
				ply:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(ply.DMGLogLang, "OnlyReportTwice"), 4, "buttons/weapon_cant_buy.wav")
				return
			end
		end

		if ply:RemainingReports() <= 0 or not ply.CanReport then return end

		if not attacker:GetNWBool("PlayedSRound", true) then
			ply:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(ply.DMGLogLang, "ReportSpectator"), 5, "buttons/weapon_cant_buy.wav")
			return
		end

	end

	if attacker == ply then return end

	if not IsValid(attacker) then
		ply:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(ply.DMGLogLang, "InvalidAttacker"), 5, "buttons/weapon_cant_buy.wav")
		return
	end

	if table.HasValue(ply.Reported, attacker) then
		ply:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(ply.DMGLogLang, "AlreadyReported"), 5, "buttons/weapon_cant_buy.wav")
		return
	end

	table.insert(ply.Reported, attacker)

	local index = table.insert(Damagelog.Reports.Current, {
		victim = ply:SteamID(),
		victim_nick = ply:Nick(),
		attacker = attacker:SteamID(),
		attacker_nick = attacker:Nick(),
		message = message,
		response = false,
		status = RDM_MANAGER_WAITING,
		admin = false,
		round = Damagelog.CurrentRound or 0,
		chat_open = false,
		logs = ply.DeathDmgLog or false,
		conclusion = false,
		adminReport = reportType != DAMAGELOG_REPORT_STANDARD,
		chatReport = reportType == DAMAGELOG_REPORT_CHAT
	})

	Damagelog.getmreports.id[1] = {}
	Damagelog.getmreports.id[1].victim = ply:SteamID()
	Damagelog.getmreports.id[1].index = index

	Damagelog.Reports.Current[index].index = index

	if reportType != DAMAGELOG_REPORT_STANDARD then
		Damagelog.Reports.Current[index].status = RDM_MANAGER_PROGRESS
		Damagelog.Reports.Current[index].admin = ply:Nick()
	end

	for k, v in pairs(player.GetHumans()) do
		if v:CanUseRDMManager() then
			if v:IsActive() then
				v:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(ply.DMGLogLang, "ReportCreated") .. " (#" .. index .. ") !", 5, "ui/vote_failure.mp3")
			else
				if reportType != DAMAGELOG_REPORT_STANDARD then
					v:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, string.format(TTTLogTranslate(ply.DMGLogLang, "HasAdminReported"), ply:Nick(), attacker:Nick(), index), 5, "ui/vote_failure.mp3")
				else
					v:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, string.format(TTTLogTranslate(ply.DMGLogLang, "HasReported"), ply:Nick(), attacker:Nick(), index), 5, "ui/vote_failure.mp3")
				end
			end
			v:NewReport(Damagelog.Reports.Current[index])
		end
	end

	if reportType != DAMAGELOG_REPORT_CHAT then
		attacker:SendReport(Damagelog.Reports.Current[index])
	end

	if not attacker:CanUseRDMManager() then
		if reportType != DAMAGELOG_REPORT_STANDARD then
			attacker:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, string.format(TTTLogTranslate(ply.DMGLogLang, "HasAdminReportedYou"), ply:Nick()), 5, "ui/vote_failure.mp3")
		else
			attacker:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, string.format(TTTLogTranslate(ply.DMGLogLang, "HasReportedYou"), ply:Nick()), 5, "ui/vote_failure.mp3")
		end
	end

	if reportType != DAMAGELOG_REPORT_STANDARD then
		ply:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, string.format(TTTLogTranslate(ply.DMGLogLang, "YouHaveAdminReported"), attacker:Nick()), 5, "")		
	else
		ply:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, string.format(TTTLogTranslate(ply.DMGLogLang, "YouHaveReported"), attacker:Nick()), 5, "")
	end

	if reportType == DAMAGELOG_REPORT_FORCE and attacker:IsActive() then
		net.Start("DL_Death")
		net.Send(attacker)
	end

	if reportType == DAMAGELOG_REPORT_CHAT then

		local report = Damagelog.Reports.Current[index]

		report.chat_open = {
			admins = { ply },
			victim = ply,
			attacker = attacker,
			players = {}
		}
		report.chat_opened = true
		
		Damagelog.ChatHistory[index] = {}
		
		net.Start("DL_OpenChat")
		net.WriteUInt(index, 32)
		net.WriteUInt(1, 1)
		net.WriteEntity(ply)
		net.WriteEntity(ply)
		net.WriteEntity(attacker)
		net.WriteTable(report.chat_open.players)
		net.WriteUInt(0, 1)
		net.Send({ ply, attacker })
		
		for k,v in pairs(player.GetHumans()) do
			if v:CanUseRDMManager() then	
				v:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, string.format(TTTLogTranslate(GetDMGLogLang, "OpenChatNotification"), ply:Nick(), index), 5, "")
				v:UpdateReport(false, index)
			end
		end

	end

	local syncEnt = Damagelog:GetSyncEnt()
	if not adminReport and IsValid(syncEnt) then
		syncEnt:SetPendingReports(syncEnt:GetPendingReports() + 1)
	end

	UpdatePreviousReports()

end)

net.Receive("DL_UpdateStatus", function(_len, ply)
	local previous = net.ReadUInt(1) == 1
	local index = net.ReadUInt(16)
	local status = net.ReadUInt(4)
	if not ply:CanUseRDMManager() then return end
	local tbl = previous and Damagelog.Reports.Previous[index] or Damagelog.Reports.Current[index]
	if not tbl then return end
	if tbl.status == status then return end
	local previousStatus = tbl.status
	tbl.status = status
	tbl.admin = status == RDM_MANAGER_WAITING and false or ply:Nick()
	local msg

	if status == RDM_MANAGER_WAITING then
		msg = ply:Nick() .. " " .. TTTLogTranslate(ply.DMGLogLang, "HasSetReport") .. " #" .. index .. TTTLogTranslate(ply.DMGLogLang, "To") .. TTTLogTranslate(ply.DMGLogLang, "RDMWating") .. "."
		local syncEnt = Damagelog:GetSyncEnt()
		if not adminReport and IsValid(syncEnt)then
			syncEnt:SetPendingReports(syncEnt:GetPendingReports() + 1)
		end	
	elseif status == RDM_MANAGER_PROGRESS then
		msg = ply:Nick() .. " " .. TTTLogTranslate(ply.DMGLogLang, "DealingReport") .. " #" .. index .. "."

		for k, v in pairs(player.GetAll()) do
			if v:SteamID() == tbl.victim then
				v:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, ply:Nick() .. " " .. TTTLogTranslate(ply.DMGLogLang, "HandlingYourReport"), 5, "ui/vote_yes.mp3")
			end
		end
	elseif status == RDM_MANAGER_FINISHED then
		msg = ply:Nick() .. " " .. TTTLogTranslate(ply.DMGLogLang, "HasSetReport") .. " #" .. index .. TTTLogTranslate(ply.DMGLogLang, "To") .. TTTLogTranslate(ply.DMGLogLang, "Finished") .. "."
		local syncEnt = Damagelog:GetSyncEnt()
		if not adminReport and IsValid(syncEnt) and previousStatus == RDM_MANAGER_WAITING then
			syncEnt:SetPendingReports(syncEnt:GetPendingReports() - 1)
		end
	end

	tbl.autoStatus = false

	for k, v in pairs(player.GetHumans()) do
		if v:CanUseRDMManager() then
			v:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, msg, 5, "")
			v:UpdateReport(previous, index)
		end
	end

	-- No Bots would use RDM Manager
	Damagelog:SendLogToVictim(tbl)
	UpdatePreviousReports()
end)

net.Receive("DL_Conclusion", function(_len, ply)
	local notify = net.ReadUInt(1) == 0
	local previous = net.ReadUInt(1) == 1
	local index = net.ReadUInt(16)
	local conclusion = net.ReadString()
	if not ply:CanUseRDMManager() then return end
	local tbl = previous and Damagelog.Reports.Previous[index] or Damagelog.Reports.Current[index]
	if not tbl then return end

	tbl.conclusion = conclusion

	for k, v in pairs(player.GetHumans()) do
		if v:CanUseRDMManager() then
			if notify then
				v:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, ply:Nick() .. " " .. TTTLogTranslate(ply.DMGLogLang, "HasSetConclusion") .. " #" .. index .. ".", 5, "")
			end
			v:UpdateReport(previous, index)
		end
	end

	Damagelog:SendLogToVictim(tbl)
	UpdatePreviousReports()
end)

hook.Add("PlayerAuthed", "RDM_Manager", function(ply)
	ply.Reported = {}
	ply:UpdateReports()

	for _, tbl in pairs(Damagelog.Reports) do
		for k, v in pairs(tbl) do
			if v.attacker == ply:SteamID() and not v.response and not v.chat_opened then
				ply:SendReport(v)
			end
		end
	end
end)

hook.Add("PlayerDeath", "RDM_Manager", function(ply)
	net.Start("DL_Death")
	net.Send(ply)
end)

hook.Add("TTTEndRound", "RDM_Manager", function()
	for k, v in pairs(player.GetAll()) do
		net.Start("DL_Death")
		net.Send(v)
	end
end)

net.Receive("DL_SendAnswer", function(_, ply)
	local previous = net.ReadUInt(1) ~= 1
	local text = string.gsub(net.ReadString(), "%s+", " ")
	local index = net.ReadUInt(16)
	local tbl = previous and Damagelog.Reports.Previous[index] or Damagelog.Reports.Current[index]
	if not tbl then return end
	if ply:SteamID() != tbl.attacker then return end
	tbl.response = text

	for k, v in pairs(player.GetHumans()) do
		if v:CanUseRDMManager() then
			v:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, (v:IsActive() and TTTLogTranslate(ply.DMGLogLang, "TheReportedPlayer") or ply:Nick()) .. " " .. TTTLogTranslate(ply.DMGLogLang, "HasAnsweredReport") .. " #" .. index .. "!", 5, "ui/vote_yes.mp3")
			v:UpdateReport(previous, index)
		end
	end

	local victim = GetBySteamID(tbl.victim)

	if IsValid(victim) then
		net.Start("DL_SendForgive")
		net.WriteUInt(previous and 1 or 0, 1)
		net.WriteUInt(tbl.canceled and 1 or 0, 1)
		net.WriteUInt(index, 16)
		net.WriteString(tbl.attacker_nick)
		net.WriteString(text)
		net.Send(victim)
	end

	Damagelog:SendLogToVictim(tbl)
	UpdatePreviousReports()
end)

net.Receive("DL_GetForgive", function(_, ply)
	local forgive = net.ReadUInt(1) == 1
	local previous = net.ReadUInt(1) == 1
	local index = net.ReadUInt(16)
	local tbl = previous and Damagelog.Reports.Previous[index] or Damagelog.Reports.Current[index]
	if tbl.chat_opened then return end
	if not tbl then return end
	if ply:SteamID() != tbl.victim then return end

	if forgive then
		tbl.canceled = true
		if tbl.status == RDM_MANAGER_WAITING then
			tbl.status = RDM_MANAGER_FINISHED
			tbl.conclusion = "(Auto) Canceled by the victim"
			tbl.autoStatus = true
		end
	end

	for k, v in pairs(player.GetHumans()) do
		if v:CanUseRDMManager() then
			if forgive then
				if v:IsActive() then
					v:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, TTTLogTranslate(ply.DMGLogLang, "TheReport") .. " #" .. index .. " " .. TTTLogTranslate(ply.DMGLogLang, "HasCanceledByVictim"), 5, "ui/vote_yes.mp3")
				else
					v:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, ply:Nick() .. " " .. TTTLogTranslate(ply.DMGLogLang, "HasCanceledReport") .. " #" .. index .. " !", 5, "ui/vote_yes.mp3")
				end
			else
				if v:IsActive() then
					v:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, TTTLogTranslate(ply.DMGLogLang, "NoMercy") .. " #" .. index .. " !", 5, "ui/vote_yes.mp3")
				else
					v:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, string.format(TTTLogTranslate(ply.DMGLogLang, "DidNotForgive"), ply:Nick(), tbl.attacker_nick, index), 5, "ui/vote_yes.mp3")
				end
			end

			v:UpdateReport(previous, index)
		end
	end

	if forgive then
		ply:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, TTTLogTranslate(ply.DMGLogLang, "GreatYou") .. " " .. TTTLogTranslate(ply.DMGLogLang, "YouCancelReport"), 5, "ui/vote_yes.mp3")
	else
		ply:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, TTTLogTranslate(ply.DMGLogLang, "GreatYou") .. " " .. TTTLogTranslate(ply.DMGLogLang, "YouKeepReport"), 5, "ui/vote_yes.mp3")
	end

	local attacker = GetBySteamID(tbl.attacker)

	if IsValid(attacker) then
		if forgive then
			attacker:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, ply:Nick() .. " " .. TTTLogTranslate(ply.DMGLogLang, "YouCancelReport"), 5, "ui/vote_yes.mp3")
		else
			attacker:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, ply:Nick() .. " " .. TTTLogTranslate(ply.DMGLogLang, "NoMercyForYou"), 5, "ui/vote_yes.mp3")
		end
	end

	Damagelog:SendLogToVictim(tbl)
	UpdatePreviousReports()
	hook.Call("TTTDLog_Decide", nil, ply, IsValid(attacker) and attacker or tbl.attacker, forgive, index)
end)

net.Receive("DL_Answering", function(_len, ply)
	if IsValid(ply) and ply:IsPlayer() and (ply.lastAnswer == nil or (CurTime() - ply.lastAnswer) > 15) then
		net.Start("DL_Answering_global")
		net.WriteString(ply:Nick())
		net.Broadcast()
	end
	ply.lastAnswer = CurTime()
end)

net.Receive("DL_ForceRespond", function(_len, ply)
	local index = net.ReadUInt(16)
	local previous = net.ReadUInt(1) == 1
	if not ply:CanUseRDMManager() then return end
	local tbl = previous and Damagelog.Reports.Previous[index] or Damagelog.Reports.Current[index]
	if not tbl then return end

	if not tbl.response then
		local attacker = GetBySteamID(tbl.attacker)

		if IsValid(attacker) then
			net.Start("DL_Death")
			net.Send(attacker)
		end
	end
end)
