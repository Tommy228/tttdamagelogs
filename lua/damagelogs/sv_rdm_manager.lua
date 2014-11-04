
util.AddNetworkString("DL_AllowReport")
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

Damagelog.Reports = Damagelog.Reports or { Current = {} }

if not Damagelog.Reports.Previous then
	if file.Exists("damagelog/prevreports.txt", "DATA") then
		Damagelog.Reports.Previous = util.JSONToTable(file.Read("damagelog/prevreports.txt", "DATA"))
		file.Delete("damagelog/prevreports.txt")
	else
		Damagelog.Reports.Previous = {}
	end
end

local function GetBySteamID(steamid)
	for k,v in pairs(player.GetAll()) do
		if v:SteamID() == steamid then
			return v
		end
	end
end

local function UpdatePreviousReports()
	local tbl = table.Copy(Damagelog.Reports.Current)
	for k,v in pairs(tbl) do
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
	net.Start("DL_UpdateReports")
	net.WriteTable(Damagelog.Reports)
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
	net.WriteUInt(index, 4)
	net.WriteTable(tbl)
	net.Send(self)
end

function Player:SendReport(tbl)
	net.Start("DL_SendReport")
	net.WriteTable(tbl)
	net.Send(self)
end

hook.Add("PlayerSay", "Damagelog_RDMManager", function(ply, text, teamOnly)
	if Damagelog.RDM_Manager_Enabled and (string.Left(string.lower(text), #Damagelog.RDM_Manager_Command) == Damagelog.RDM_Manager_Command) then
		Damagelog:StartReport(ply)
		return ""
	end
end)

hook.Add("TTTBeginRound", "Damagelog_RDMManger", function()
	for k,v in pairs(player.GetHumans()) do
		if not v.CanReport then
			v.CanReport = true
		end
		table.Empty(v.Reported)
	end
end)

net.Receive("DL_StartReport", function(length, ply)
	Damagelog:StartReport(ply)
end)

function Damagelog:StartReport(ply)
	if not IsValid(ply) then return end
	local found = false
	for k,v in pairs(player.GetHumans()) do
		if v:CanUseRDMManager() then
			found = true
			break
		end
	end
	if not found then
		ply:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, "No admins online !", 4, "buttons/weapon_cant_buy.wav")
		return
	end
	if not ply.CanReport then
		ply:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, "You need to play before being able to report!", 4, "buttons/weapon_cant_buy.wav")
	else
		local remaining_reports = ply:RemainingReports()
		if remaining_reports <= 0 then
			ply:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, "You can only report twice per round!", 4, "buttons/weapon_cant_buy.wav")
		else
			net.Start("DL_AllowReport")
			if ply.DeathDmgLog and ply.DeathDmgLog[Damagelog.CurrentRound] then
				net.WriteUInt(1, 1)
				net.WriteTable(ply.DeathDmgLog[Damagelog.CurrentRound])
			else
				net.WriteUInt(0,1);
			end
			net.Send(ply)
		end
	end
end

net.Receive("DL_ReportPlayer", function(_len, ply)
	local attacker = net.ReadEntity()
	local message = net.ReadString()
	if ply:RemainingReports() <= 0 or not ply.CanReport then return end
	if attacker == ply then return end
	if table.HasValue(ply.Reported, attacker) then
		ply:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, "You have already reported this player!", 5, "buttons/weapon_cant_buy.wav")
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
		round = Damagelog.CurrentRound,
		logs = ply.DeathDmgLog and ply.DeathDmgLog[Damagelog.CurrentRound] or false
	})
	Damagelog.Reports.Current[index].index = index
	for k,v in pairs(player.GetHumans()) do
		if v:CanUseRDMManager() then
			v:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, ply:Nick().." has reported "..attacker:Nick().. " (#"..index..") !", 5, "ui/vote_failure.wav")
			v:NewReport(Damagelog.Reports.Current[index])
		end
	end
	attacker:SendReport(Damagelog.Reports.Current[index])
	if not attacker:CanUseRDMManager() then
		attacker:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, ply:Nick().." has reported you!", 5, "ui/vote_failure.wav")
	end
	ply:Damagelog_Notify(DAMAGELOG_NOTIFY_ALERT, "You have reported "..attacker:Nick(), 5, "")
	UpdatePreviousReports()
end)

net.Receive("DL_UpdateStatus", function(_len, ply)
	local previous = net.ReadUInt(1) == 1
	local index = net.ReadUInt(4)
	local status = net.ReadUInt(4)
	if not ply:CanUseRDMManager() then return end
	local tbl = previous and Damagelog.Reports.Previous[index] or Damagelog.Reports.Current[index]
	if not tbl then return end
	if tbl.status == status or tbl.status == RDM_MANAGER_CANCELED then return end
	tbl.status = status
	tbl.admin = status == RDM_MANAGER_WAITING and false or ply:Nick()
	local msg
	if status == RDM_MANAGER_WAITING then
		msg = ply:Nick().." has set the report #"..index.." to Waiting."
	elseif status == RDM_MANAGER_PROGRESS then
		msg = ply:Nick().." is now dealing with the report #"..index.."."
	elseif status == RDM_MANAGER_FINISHED then
		msg = ply:Nick().." has set the report #"..index.." to Finished."
	end
	for k,v in pairs(player.GetHumans()) do
		if v:CanUseRDMManager() then	
			if v != ply then
				v:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, msg, 5, "")
			end
			v:UpdateReport(previous, index)
		end
	end
	UpdatePreviousReports()
end)

hook.Add("PlayerAuthed", "RDM_Manager", function(ply)
	ply.Reported = {}
	ply:UpdateReports()
	for _,tbl in pairs(Damagelog.Reports) do
		for k,v in pairs(tbl) do
			if v.attacker == ply:SteamID() and not v.response then
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
	for k,v in pairs(player.GetAll()) do
		net.Start("DL_Death")
		net.Send(v)
	end
end)

local waiting_forgive = {}

net.Receive("DL_SendAnswer", function(_, ply)
	local previous = net.ReadUInt(1) != 1
	local text = net.ReadString()
	local index = net.ReadUInt(4)
	local tbl = previous and Damagelog.Reports.Previous[index] or Damagelog.Reports.Current[index]
	if not tbl then return end
	if ply:SteamID() != tbl.attacker then return end
	tbl.response = text
	for k,v in pairs(player.GetHumans()) do
		if v:CanUseRDMManager() then	
			v:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, ply:Nick().." has answered to the report #"..index.." !", 5, "ui/vote_yes.wav")
			v:UpdateReport(previous, index)
		end
	end
	local victim = GetBySteamID(tbl.victim)
	if IsValid(victim) then
		net.Start("DL_SendForgive")
		net.WriteUInt(previous and 1 or 0, 1)
		net.WriteUInt(index, 4)
		net.WriteString(tbl.attacker_nick)
		net.WriteString(text)
		net.Send(victim)
	end
	UpdatePreviousReports()
end)

net.Receive("DL_GetForgive", function(_, ply)
	local forgive = net.ReadUInt(1) == 1
	local previous = net.ReadUInt(1) == 1
	local index = net.ReadUInt(4)
	local tbl = previous and Damagelog.Reports.Previous[index] or Damagelog.Reports.Current[index]
	if not tbl then return end
	if ply:SteamID() != tbl.victim then return end
	if forgive then
		tbl.status = RDM_MANAGER_CANCELED
	end
	for k,v in pairs(player.GetHumans()) do
		if v:CanUseRDMManager() then	
			if forgive then
				v:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, ply:Nick().." has canceled to the report #"..index.." !", 5, "ui/vote_yes.wav")
			else
				v:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, ply:Nick().." did not forgive "..tbl.attacker_nick.." on the report #"..index.." !", 5, "ui/vote_yes.wav")
			end
			v:UpdateReport(previous, index)
		end
	end
	if forgive then
		ply:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, "You decided to cancel the report.", 5, "ui/vote_yes.wav")
	else
		ply:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, "You decided to keep the report.", 5, "ui/vote_yes.wav")
	end
	local attacker = GetBySteamID(tbl.attacker)
	if IsValid(attacker) then
		if forgive then
			attacker:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, ply:Nick().." decided to cancel the report.", 5, "ui/vote_yes.wav")
		else
			attacker:Damagelog_Notify(DAMAGELOG_NOTIFY_INFO, ply:Nick().." does not want to forgive you.", 5, "ui/vote_yes.wav")
		end
	end
	UpdatePreviousReports()
end)

net.Receive("DL_Answering", function(_len, ply)
	net.Start("DL_Answering_global")
	net.WriteString(ply:Nick())
	net.Broadcast()
end)

net.Receive("DL_ForceRespond", function(_len, ply)
	local index = net.ReadUInt(4)
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