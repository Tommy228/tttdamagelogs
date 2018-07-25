surface.CreateFont("DL_RDM_Manager", {
	font = "DermaLarge",
	size = 20
})

surface.CreateFont("DL_Conclusion", {
	font = "DermaLarge",
	size = 18,
	weight = 600
})

surface.CreateFont("DL_ConclusionText", {
	font = "DermaLarge",
	size = 18
})

surface.CreateFont("DL_ResponseDisabled", {
	font = "DermaLarge",
	size = 16
})

local color_trablack = Color(0, 0, 0, 240)
local mode = Damagelog.ULX_AutoslayMode

local function AdjustText(str, font, w)
	surface.SetFont(font)
	local size = surface.GetTextSize(str)

	if size <= w then
		return str
	else
		local last_space
		local i = 0

		for k, v in pairs(string.ToTable(str)) do
			local _w = surface.GetTextSize(v)
			i = i + _w

			if i > w then
				local sep = last_space or k

				return string.Left(str, sep), string.Right(str, #str - sep)
			end

			if v == " " then
				last_space = k
			end
		end
	end
end

local show_finished = CreateClientConVar("rdm_manager_show_finished", "1", FCVAR_ARCHIVE)

cvars.AddChangeCallback("rdm_manager_show_finished", function(name, old, new)
	if IsValid(Damagelog.CurrentReports) then
		Damagelog.CurrentReports:UpdateAllReports()
	end

	if IsValid(Damagelog.PreviousReports) then
		Damagelog.PreviousReports:UpdateAllReports()
	end
end)

local status = {
	[RDM_MANAGER_WAITING] = TTTLogTranslate(GetDMGLogLang, "RDMWaiting"),
	[RDM_MANAGER_PROGRESS] = TTTLogTranslate(GetDMGLogLang, "RDMInProgress"),
	[RDM_MANAGER_FINISHED] = TTTLogTranslate(GetDMGLogLang, "RDMFinished")
}

RDM_MANAGER_STATUS = status

local icons = {
	[RDM_MANAGER_WAITING] = "icon16/clock.png",
	[RDM_MANAGER_PROGRESS] = "icon16/arrow_refresh.png",
	[RDM_MANAGER_FINISHED] = "icon16/accept.png"
}

RDM_MANAGER_ICONS = icons

local colors = {
	[RDM_MANAGER_PROGRESS] = Color(0, 0, 190),
	[RDM_MANAGER_FINISHED] = Color(0, 190, 0),
	[RDM_MANAGER_WAITING] = Color(100, 100, 100)
}

local function TakeAction()
	local report = Damagelog.SelectedReport
	if not report then return end
	local current = not report.previous
	local attacker = player.GetBySteamID(report.attacker)
	local victim = player.GetBySteamID(report.victim)
	local menuPanel = DermaMenu()

	menuPanel:AddOption(TTTLogTranslate(GetDMGLogLang, "RDMSetConclusion"), function()
		Derma_StringRequest(TTTLogTranslate(GetDMGLogLang, "RDMConclusion"), TTTLogTranslate(GetDMGLogLang, "RDMWriteConclusion"), "", function(txt)
			if #txt > 0 and #txt < 200 then
				net.Start("DL_Conclusion")
				net.WriteUInt(0, 1)
				net.WriteUInt(report.previous and 1 or 0, 1)
				net.WriteUInt(report.index, 16)
				net.WriteString(txt)
				net.SendToServer()
			end
		end)
	end):SetImage("icon16/comment.png")

	if not report.response then
		menuPanel:AddOption(TTTLogTranslate(GetDMGLogLang, "RDMForceRespond"), function()
			if IsValid(attacker) then
				net.Start("DL_ForceRespond")
				net.WriteUInt(report.index, 16)
				net.WriteUInt(current and 0 or 1, 1)
				net.SendToServer()
			else
				Derma_Message(TTTLogTranslate(GetDMGLogLang, "RDMNotValid"), TTTLogTranslate(GetDMGLogLang, "Error"), "OK")
			end
		end):SetImage("icon16/clock_red.png")
	end

	if not report.previous then

		if not report.chat_open then

			menuPanel:AddOption(report.chat_opened and TTTLogTranslate(GetDMGLogLang, "ViewChat") or TTTLogTranslate(GetDMGLogLang, "OpenChat"), function()
				if not report.chat_opened then
					net.Start("DL_StartChat")
					net.WriteUInt(report.index, 32)
					net.SendToServer()

					if not report.response then
						Damagelog.DisableResponse(true)
					end

					if report.status == RDM_MANAGER_WAITING then
						net.Start("DL_UpdateStatus")
						net.WriteUInt(report.previous and 1 or 0, 1)
						net.WriteUInt(report.index, 16)
						net.WriteUInt(RDM_MANAGER_PROGRESS, 4)
						net.SendToServer()
					end

				else
					net.Start("DL_ViewChat")
					net.WriteUInt(report.index, 32)
					net.SendToServer()
				end
			end):SetImage("icon16/application_view_list.png")

		else

			menuPanel:AddOption(TTTLogTranslate(GetDMGLogLang, "JoinChat"), function()
				net.Start("DL_JoinChat")
				net.WriteUInt(report.index, 32)
				net.SendToServer()
			end):SetImage("icon16/application_go.png")

		end

	end

	menuPanel:AddOption(TTTLogTranslate(GetDMGLogLang, "ShowDeathScene"), function()
		local found = false
		local roles = Damagelog.Roles[report.round]
		local victimID = util.SteamIDTo64(report.victim)
		local attackerID = util.SteamIDTo64(report.attacker)
		for k, v in pairs(report.logs or {}) do
			if IsValid(Damagelog.events[v.id]) and Damagelog.events[v.id].type == "KILL" then
				local infos = v.infos
				local ent = Damagelog:InfoFromID(roles, infos[1])
				local att = Damagelog:InfoFromID(roles, infos[2])
				if ent.steamid64 == victimID and att.steamid64 == attackerID then
					net.Start("DL_AskDeathScene")
					net.WriteUInt(infos[4], 32)
					net.WriteUInt(infos[2], 32)
					net.WriteUInt(infos[1], 32)
					net.WriteString(report.attacker)
					net.SendToServer()
					found = true
					break
				end
			end
		end
		if not found then
			Derma_Message(TTTLogTranslate(GetDMGLogLang, "DeathSceneNotFound"), TTTLogTranslate(GetDMGLogLang, "Error"), "OK")
		end
	end):SetImage("icon16/television.png")

	if serverguard or ulx then

		if serverguard or (ulx and (mode == 1 or mode == 2)) then
			local function SetConclusion(ply, num, reason)
				net.Start("DL_Conclusion")
				net.WriteUInt(1, 1)
				net.WriteUInt(report.previous and 1 or 0, 1)
				net.WriteUInt(report.index, 16)
				local typ = mode == 1 and "AutoReasonSlay" or "AutoReasonJail"
				net.WriteString(string.format(TTTLogTranslate(GetDMGLogLang, typ), ply, num, reason))
				net.SendToServer()
			end

			local function SetConclusionBan(ply, num, reason)
				net.Start("DL_Conclusion")
				net.WriteUInt(1, 1)
				net.WriteUInt(report.previous and 1 or 0, 1)
				net.WriteUInt(report.index, 16)
				net.WriteString(string.format(TTTLogTranslate(GetDMGLogLang, "AutoReasonBan"), ply, num, reason))
				net.SendToServer()
			end

			local slaynr_pnl = vgui.Create("DMenuOption", menuPanel)
			local slaynr = DermaMenu(menuPanel)
			slaynr:SetVisible(false)
			slaynr_pnl:SetSubMenu(slaynr)
			local txt = TTTLogTranslate(GetDMGLogLang, "SlayNextRound")
			if ulx and mode == 2 then
				txt = TTTLogTranslate(GetDMGLogLang, "JailNextRound")
			end
			slaynr_pnl:SetText(txt)
			slaynr_pnl:SetImage("icon16/lightning_go.png")
			menuPanel:AddPanel(slaynr_pnl)
			slaynr:AddOption(TTTLogTranslate(GetDMGLogLang, "ReportedPlayer") .. " ("..report.attacker_nick..")", function()
				local frame = vgui.Create("RDM_Manager_Slay_Reason", Damagelog.Menu)
				frame.SetConclusion = SetConclusion
				frame:SetPlayer(true, attacker, report.attacker, report)
			end):SetImage("icon16/user_delete.png")
			slaynr:AddOption(TTTLogTranslate(GetDMGLogLang, "Victim") .. " ("..report.victim_nick..")", function()
				local frame = vgui.Create("RDM_Manager_Slay_Reason", Damagelog.Menu)
				frame.SetConclusion = SetConclusion
				frame:SetPlayer(false, victim, report.victim, report)
			end):SetImage("icon16/user.png")

			local slaynr_pnl = vgui.Create("DMenuOption", menuPanel)
			local slaynr = DermaMenu(menuPanel)
			slaynr:SetVisible(false)
			slaynr_pnl:SetSubMenu(slaynr)
			slaynr_pnl:SetText("Ban")
			slaynr_pnl:SetImage("icon16/bomb.png")
			menuPanel:AddPanel(slaynr_pnl)
			slaynr:AddOption(TTTLogTranslate(GetDMGLogLang, "ReportedPlayer") .. " ("..report.attacker_nick..")", function()
				local frame = vgui.Create("RDM_Manager_Ban_Reason", Damagelog.Menu)
				frame.SetConclusion = SetConclusionBan
				frame:SetPlayer(true, attacker, report.attacker, report)
			end):SetImage("icon16/user_delete.png")
			slaynr:AddOption(TTTLogTranslate(GetDMGLogLang, "Victim") .. " ("..report.victim_nick..")", function()
				local frame = vgui.Create("RDM_Manager_Ban_Reason", Damagelog.Menu)
				frame.SetConclusion = SetConclusionBan
				frame:SetPlayer(false, victim, report.victim, report)
			end):SetImage("icon16/user.png")


		end

		menuPanel:AddOption(TTTLogTranslate(GetDMGLogLang, "SlayReportedPlayerNow"), function()
			if IsValid(attacker) then
				if ulx then
					RunConsoleCommand("ulx", "slay", attacker:Nick())
				else
					serverguard.command.Run("slay", false, ply:Nick())
				end
			else
				Damagelog:Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(GetDMGLogLang, "RDMNotValid"), 2, "buttons/weapon_cant_buy.wav")
			end
		end):SetImage("icon16/lightning.png")

		local slaynr_pnl = vgui.Create("DMenuOption", menuPanel)
			local slaynr = DermaMenu(menuPanel)
			slaynr:SetVisible(false)
			slaynr_pnl:SetSubMenu(slaynr)
			slaynr_pnl:SetText(TTTLogTranslate(GetDMGLogLang, "SendMessage"))
			slaynr_pnl:SetImage("icon16/user_edit.png")
			menuPanel:AddPanel(slaynr_pnl)
			slaynr:AddOption(TTTLogTranslate(GetDMGLogLang, "ReportedPlayer") .. " ("..report.attacker_nick..")", function()
				if IsValid(attacker) then
					Derma_StringRequest(TTTLogTranslate(GetDMGLogLang, "PrivateMessage"), string.format(TTTLogTranslate(GetDMGLogLang, "WhatToSay"), attacker:Nick()), "", function(msg)
						if ulx then
							RunConsoleCommand("ulx", "psay", attacker:Nick(), Damagelog.PrivateMessagePrefix.." "..msg)
						else
							serverguard.command.Run("pm", attacker:Nick(), Damagelog.PrivateMessagePrefix.. " "..msg)
						end
					end)
				else
					Damagelog:Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(GetDMGLogLang, "VictimReportedDisconnected"), 2, "buttons/weapon_cant_buy.wav")
				end
			end):SetImage("icon16/user_delete.png")
			slaynr:AddOption(TTTLogTranslate(GetDMGLogLang, "Victim") .. " ("..report.victim_nick..")", function()
				if IsValid(victim) then
					Derma_StringRequest(TTTLogTranslate(GetDMGLogLang, "PrivateMessage"), string.format(TTTLogTranslate(GetDMGLogLang, "WhatToSay"), victim:Nick()), "", function(msg)
						if ulx then
							RunConsoleCommand("ulx", "psay", victim:Nick(), Damagelog.PrivateMessagePrefix.." "..msg)
						else
							serverguard.command.Run("pm", attacker:Nick(), Damagelog.PrivateMessagePrefix.. " "..msg)
						end
					end)
				else
					Damagelog:Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(GetDMGLogLang, "VictimReportedDisconnected"), 2, "buttons/weapon_cant_buy.wav")
				end
			end):SetImage("icon16/user.png")

			local slaynr_pnl = vgui.Create("DMenuOption", menuPanel)
			local slaynr = DermaMenu(menuPanel)
			slaynr:SetVisible(false)
			slaynr_pnl:SetSubMenu(slaynr)
			local txt = TTTLogTranslate(GetDMGLogLang, "RemoveAutoSlays")
			if ulx and mode == 2 then
				txt = TTTLogTranslate(GetDMGLogLang, "RemoveAutoJails")
			elseif serverguard then
				txt = TTTLogTranslate(GetDMGLogLang, "RemoveOneAutoSlay")
			end
			slaynr_pnl:SetText(txt)
			slaynr_pnl:SetImage("icon16/cancel.png")
			menuPanel:AddPanel(slaynr_pnl)

			slaynr:AddOption(TTTLogTranslate(GetDMGLogLang, "ReportedPlayer") .. " ("..report.attacker_nick..")", function()
				if IsValid(attacker) then
					if ulx then
						RunConsoleCommand("ulx", mode == 1 and "aslay" or "ajail", attacker:Nick(), "0")
					else
						serverguard.command.Run("raslay", false, attacker:Nick())
					end
				else
					if ulx then
						RunConsoleCommand("ulx", mode == 1 and "aslayid" or "ajailid", report.attacker, "0")
					else
						Damagelog:Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(GetDMGLogLang, "VictimReportedDisconnected"), 2, "buttons/weapon_cant_buy.wav")
					end
				end
			end):SetImage("icon16/user_delete.png")

			slaynr:AddOption(TTTLogTranslate(GetDMGLogLang, "TheVictim") .. " ("..report.victim_nick..")", function()
				if IsValid(victim) then
					if ulx then
						RunConsoleCommand("ulx", mode == 1 and "aslay" or "ajail", victim:Nick(), "0")
					else
						serverguard.command.Run("raslay", false, victim:Nick())
					end
				else
					if ulx then
						RunConsoleCommand("ulx", mode == 1 and "aslayid" or "ajailid", report.victim, "0")
					else
						Damagelog:Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(GetDMGLogLang, "VictimReportedDisconnected"), 2, "buttons/weapon_cant_buy.wav")
					end
				end
			end):SetImage("icon16/user.png")
	end

	menuPanel:Open()
end
local PANEL = {}

function PANEL:Init()
	self:SetMultiSelect(false)
	self.IDWidth = 25
	self.VictimWidth = 105
	self.ReportedPlayerWidth = 105
	self.RoundWidth = 49
	self.ResponseStatusWidth = 110
	self.CanceledWidth = 55
	self.StatusWidth = 174
	self.CanceledPos = self.IDWidth + self.ReportedPlayerWidth + self.VictimWidth + self.RoundWidth + self.ResponseStatusWidth
	self:AddColumn("ID"):SetFixedWidth(self.IDWidth)
	self:AddColumn(TTTLogTranslate(GetDMGLogLang, "Victim")):SetFixedWidth(self.VictimWidth)
	self:AddColumn(TTTLogTranslate(GetDMGLogLang, "ReportedPlayer")):SetFixedWidth(self.ReportedPlayerWidth)
	self:AddColumn(TTTLogTranslate(GetDMGLogLang, "Round")):SetFixedWidth(self.RoundWidth)
	self:AddColumn(TTTLogTranslate(GetDMGLogLang, "ResponseStatus")):SetFixedWidth(self.ResponseStatusWidth)
	self:AddColumn(TTTLogTranslate(GetDMGLogLang, "Canceled")):SetFixedWidth(self.CanceledWidth)
	self:AddColumn(TTTLogTranslate(GetDMGLogLang, "Status")):SetFixedWidth(self.StatusWidth)
	self.Reports = {}
end

function PANEL:SetOuputs(victim, killer)
	self.VictimOutput = victim
	self.KillerOuput = killer
end

function PANEL:SetReportsTable(tbl)
	self.ReportsTable = tbl
end

function PANEL:GetStatus(report)
	local str = status[report.status]

	if report.status == RDM_MANAGER_FINISHED and report.autoStatus then
		str = TTTLogTranslate(GetDMGLogLang, "RDMManagerAuto").." "..str
	end

	if (report.status == RDM_MANAGER_FINISHED or report.status == RDM_MANAGER_PROGRESS) and report.admin then
		str = str .. " " .. TTTLogTranslate(GetDMGLogLang, "By") .. " " .. report.admin
	end

	return str
end

function PANEL:UpdateReport(index)
	local report = self.ReportsTable[index]
	if not report then return end
	local str
	if report.chat_open then
		str = TTTLogTranslate(GetDMGLogLang, "ChatActive")
	elseif report.chat_opened then
		str = TTTLogTranslate(GetDMGLogLang, "ChatOpenedShort")
	else
		str = report.response and TTTLogTranslate(GetDMGLogLang, "RDMResponded") or TTTLogTranslate(GetDMGLogLang, "RDMWaitingAttacker")
	end
	local tbl = {
		report.index,
		report.adminReport and "N/A (Admin Report)" or report.victim_nick,
		report.attacker_nick,
		report.round or "?",
		str,
		report.adminReport and "N/A" or "";
		self:GetStatus(report)
	}

	if not self.Reports[index] then
		if report.status != RDM_MANAGER_FINISHED or show_finished:GetBool() then
			self.Reports[index] = self:AddLine(unpack(tbl))
			self.Reports[index].status = report.status
			self.Reports[index].index = report.index
			local tbl = {self.Reports[index]}

			self.Reports[index].CanceledIcon = vgui.Create("DImage", self.Reports[index])
			self.Reports[index].CanceledIcon:SetSize(16, 16)
			self.Reports[index].CanceledIcon:SetImage(report.canceled and "icon16/tick.png" or "icon16/cross.png")
			self.Reports[index].CanceledIcon:SetPos(self.CanceledPos + self.CanceledWidth / 2 - 10)

			if report.adminReport then
				self.Reports[index].CanceledIcon:SetVisible(false)
			end

			for k, v in ipairs(self.Sorted) do
				if k == #self.Sorted then continue end
				table.insert(tbl, v)
			end

			self.Sorted = tbl
			self:InvalidateLayout()

			self.Reports[index].PaintOver = function(self)
				if self:IsLineSelected() then
					self.Columns[2]:SetTextColor(color_white)
					self.Columns[3]:SetTextColor(color_white)
					self.Columns[5]:SetTextColor(color_white)
					self.Columns[7]:SetTextColor(color_white)
				else
					self.Columns[2]:SetTextColor(report.adminReport and Color(190, 190, 0) or Color(0, 190, 0))
					self.Columns[3]:SetTextColor(Color(190, 0, 0))
					self.Columns[7]:SetTextColor(colors[report.status])

					if report.chat_open then
						self.Columns[5]:SetTextColor(Color(100 + math.abs(math.sin(CurTime()) * 155), 0, 0))
					else
						self.Columns[5]:SetTextColor(color_black)
					end
				end
			end

			self.Reports[index].OnRightClick = function(self)
				TakeAction()
			end
		else
			self.Reports[index] = false
		end
	else
		self.Reports[index].status = report.status
		self.Reports[index].index = report.index

		if report.status == RDM_MANAGER_FINISHED and not show_finished:GetBool() then
			return self:UpdateAllReports()
		else
			for k, v in ipairs(self.Reports[index].Columns) do
				self.Reports[index]:SetValue(k, tbl[k])
			end
		end

		self.Reports[index].CanceledIcon:SetImage(report.canceled and "icon16/tick.png" or "icon16/cross.png")

		if report.conclusion then
			local selected = Damagelog.SelectedReport

			if selected and selected.index == report.index and selected.previous == report.previous then
				self.Conclusion:SetText(report.conclusion)
			end
		end

		self.Reports[index].PaintOver = function(self)
			if self:IsLineSelected() then
				self.Columns[2]:SetTextColor(color_white)
				self.Columns[3]:SetTextColor(color_white)
				self.Columns[5]:SetTextColor(color_white)
				self.Columns[7]:SetTextColor(color_white)
			else
				self.Columns[2]:SetTextColor(report.adminReport and Color(190, 190, 0) or Color(0, 190, 0))
				self.Columns[3]:SetTextColor(Color(190, 0, 0))
				self.Columns[7]:SetTextColor(colors[report.status])

				if report.chat_open then
					self.Columns[5]:SetTextColor(Color(100 + math.abs(math.sin(CurTime()) * 155), 0, 0))
				else
					self.Columns[5]:SetTextColor(color_black)
				end
			end
		end
	end

	return self.Reports[index]
end

function PANEL:AddReport(index)
	return self:UpdateReport(index)
end

function PANEL:UpdateAllReports()
	self:Clear()
	table.Empty(self.Reports)
	if not self.ReportsTable then return end

	for i = 1, #self.ReportsTable do
		self:AddReport(i)
	end

	if Damagelog.SelectedReport then
		local selected_current = not Damagelog.SelectedReport.Previous
		local current = not self.Previous

		if Damagelog.SelectedReport.status != RDM_MANAGER_FINISHED and not show_finished:GetBool() then
			for k, v in pairs(self.Lines) do
				v:SetSelected(false)
			end

			Damagelog.SelectedReport = nil
			Damagelog:UpdateReportTexts()
		elseif selected_current == current then
			for k, v in pairs(self.Lines) do
				if Damagelog.SelectedReport.index == v.index then
					v:SetSelected(true)
					break
				end
			end
		end

		if Damagelog.SelectedReport then
			local report = Damagelog.SelectedReport
			local conclusion = report.conclusion

			if conclusion then
				self.Conclusion:SetText(conclusion)
			else
				self.Conclusion:SetText(TTTLogTranslate(GetDMGLogLang, "NoConclusion"))
			end

			if not report.response and report.chat_opened then
				Damagelog.DisableResponse(true)
			else
				Damagelog.DisableResponse(false)
			end
		end

		Damagelog:UpdateReportTexts()
	end
end

function PANEL:OnRowSelected(index, line)
	Damagelog.SelectedReport = self.ReportsTable[line.index]
	Damagelog:UpdateReportTexts()
	local report = Damagelog.SelectedReport

	if not report.response and report.chat_opened then
		Damagelog.DisableResponse(true)
	else
		Damagelog.DisableResponse(false)
	end

	local conclusion = Damagelog.SelectedReport.conclusion

	if conclusion then
		self.Conclusion:SetText(conclusion)
	else
		self.Conclusion:SetText(TTTLogTranslate(GetDMGLogLang, "NoConclusion"))
	end

	if Damagelog.SelectedReport.previous then
		if Damagelog.CurrentReports:GetSelected()[1] then
			Damagelog.CurrentReports:GetSelected()[1]:SetSelected(false)
		end
	else
		if Damagelog.PreviousReports:GetSelected()[1] then
			Damagelog.PreviousReports:GetSelected()[1]:SetSelected(false)
		end
	end
end

vgui.Register("RDM_Manager_ListView", PANEL, "DListView")

net.Receive("DL_NewReport", function()
	local tbl = net.ReadTable()
	local index = table.insert(Damagelog.Reports.Current, tbl)
	Damagelog.Reports.Current[index].index = index

	if IsValid(Damagelog.CurrentReports) then
		Damagelog.CurrentReports:AddReport(index)
	end
end)

net.Receive("DL_UpdateReport", function()
	local previous = net.ReadUInt(1) == 1
	local index = net.ReadUInt(8)
	local updated = net.ReadTable()
	updated.index = index

	if previous then
		Damagelog.Reports.Previous[index] = updated

		if IsValid(Damagelog.PreviousReports) then
			Damagelog.PreviousReports:UpdateReport(index)
		end
	else
		Damagelog.Reports.Current[index] = updated

		if IsValid(Damagelog.CurrentReports) then
			Damagelog.CurrentReports:UpdateReport(index)
		end
	end

	if Damagelog.SelectedReport and Damagelog.SelectedReport.index == index and ((not Damagelog.SelectedReport.previous and not previous) or Damagelog.SelectedReport.previous == previous) then
		Damagelog.SelectedReport = updated
	end

	if IsValid(Damagelog.CurrentReports) then
		Damagelog:UpdateReportTexts()
	end
end)

net.Receive("DL_UpdateReports", function()
	Damagelog.SelectedReport = nil
	local size = net.ReadUInt(32)
	local data = net.ReadData(size)
	if not data then return end
	local json = util.Decompress(data)
	if not json then return end
	Damagelog.Reports = util.JSONToTable(json)

	if IsValid(Damagelog.CurrentReports) then
		Damagelog.CurrentReports:UpdateAllReports()
	end

	if IsValid(Damagelog.PreviousReports) then
		Damagelog.PreviousReports:UpdateAllReports()
	end
end)

local function DrawStatusMenuOption(id, menu)
	menu:AddOption(status[id], function()
		net.Start("DL_UpdateStatus")
		net.WriteUInt(Damagelog.SelectedReport.previous and 1 or 0, 1)
		net.WriteUInt(Damagelog.SelectedReport.index, 16)
		net.WriteUInt(id, 4)
		net.SendToServer()
	end):SetImage(icons[id])
end

function Damagelog:DrawRDMManager(x, y)
	if LocalPlayer():CanUseRDMManager() and Damagelog.RDM_Manager_Enabled then
		local Manager = vgui.Create("DPanelList")
		Manager:SetSpacing(10)
		local Background = vgui.Create("ColoredBox")
		Background:SetHeight(170)
		Background:SetColor(Color(90, 90, 95))
		local ReportsSheet = vgui.Create("DPropertySheet", Background)
		ReportsSheet:SetPos(5, 5)
		ReportsSheet:SetSize(630, 160)
		self.CurrentReports = vgui.Create("RDM_Manager_ListView")
		self.CurrentReports:SetReportsTable(Damagelog.Reports.Current)
		self.CurrentReports.Previous = false
		ReportsSheet:AddSheet(TTTLogTranslate(GetDMGLogLang, "Reports"), self.CurrentReports, "icon16/zoom.png")
		self.PreviousReports = vgui.Create("RDM_Manager_ListView")
		self.PreviousReports:SetReportsTable(Damagelog.Reports.Previous)
		self.PreviousReports.Previous = true
		ReportsSheet:AddSheet(TTTLogTranslate(GetDMGLogLang, "PreviousMapReports"), self.PreviousReports, "icon16/world.png")
		local ShowFinished = vgui.Create("DCheckBoxLabel", Background)
		ShowFinished:SetText(TTTLogTranslate(GetDMGLogLang, "ShowFinishedReports"))
		ShowFinished:SetConVar("rdm_manager_show_finished")
		ShowFinished:SizeToContents()
		ShowFinished:SetPos(235, 7)
		local TakeActionB = vgui.Create("DButton", Background)
		TakeActionB:SetText(TTTLogTranslate(GetDMGLogLang, "TakeAction"))
		TakeActionB:SetPos(470, 4)
		TakeActionB:SetSize(80, 18)

		TakeActionB.Think = function(self)
			self:SetEnabled(Damagelog.SelectedReport)
		end

		TakeActionB.DoClick = function(self)
			TakeAction()
		end

		local SetState = vgui.Create("DButton", Background)
		SetState:SetText(TTTLogTranslate(GetDMGLogLang, "SStatus"))
		SetState:SetPos(555, 4)
		SetState:SetSize(80, 18)

		SetState.Think = function(self)
			self:SetEnabled(Damagelog.SelectedReport)
		end

		SetState.DoClick = function()
			local menu = DermaMenu()
			local attacker = player.GetBySteamID(Damagelog.SelectedReport.attacker)
			DrawStatusMenuOption(RDM_MANAGER_WAITING, menu)
			DrawStatusMenuOption(RDM_MANAGER_PROGRESS, menu)
			DrawStatusMenuOption(RDM_MANAGER_FINISHED, menu)
			menu:Open()
		end

		local CreateReport = vgui.Create("DButton", Background)
		CreateReport:SetText(TTTLogTranslate(GetDMGLogLang, "CreateReport"))
		CreateReport:SetPos(385, 4)
		CreateReport:SetSize(80, 18)
		CreateReport.DoClick = function()
			RunConsoleCommand("dmglogs_startreport")
		end

		Manager:AddItem(Background)
		local VictimInfos = vgui.Create("DPanel")
		VictimInfos:SetHeight(110)
		VictimInfos.isAdmin = false

		VictimInfos.Paint = function(panel, w, h)
			local bar_height = 27
			if panel.isAdmin then
				surface.SetDrawColor(200, 200, 30)
			else
				surface.SetDrawColor(30, 200, 30)
			end
			surface.DrawRect(0, 0, (w / 2), bar_height)
			if panel.isAdmin then
				draw.SimpleText(TTTLogTranslate(GetDMGLogLang, "AdminsMessage"), "DL_RDM_Manager", w / 4, bar_height / 2, Color(0, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			else
				draw.SimpleText(TTTLogTranslate(GetDMGLogLang, "VictimsReport"), "DL_RDM_Manager", w / 4, bar_height / 2, Color(0, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			surface.SetDrawColor(220, 30, 30)
			surface.DrawRect((w / 2) + 1, 0, (w / 2), bar_height)
			draw.SimpleText(TTTLogTranslate(GetDMGLogLang, "ReportedPlayerResponse"), "DL_RDM_Manager", (w / 2) + 1 + (w / 4), bar_height / 2, Color(0, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			surface.SetDrawColor(0, 0, 0)
			surface.DrawOutlinedRect(0, 0, w, h)
			surface.DrawLine(w / 2, 0, w / 2, h)
			surface.DrawLine(0, 27, w, bar_height)

			if panel.DisableR then
				surface.SetDrawColor(color_trablack)
				surface.DrawRect((w / 2) + 1, 0, (w / 2), h)
			end
		end

		local VictimMessage = vgui.Create("DTextEntry", VictimInfos)
		VictimMessage:SetMultiline(true)
		VictimMessage:SetKeyboardInputEnabled(false)
		VictimMessage:SetPos(1, 27)
		VictimMessage:SetSize(319, 82)
		local KillerMessage = vgui.Create("DTextEntry", VictimInfos)
		KillerMessage:SetMultiline(true)
		KillerMessage:SetKeyboardInputEnabled(false)
		KillerMessage:SetPos(319, 27)
		KillerMessage:SetSize(319, 82)

		KillerMessage.PaintOver = function(self, w, h)
			if self.DisableR then
				surface.SetDrawColor(color_trablack)
				surface.DrawRect(0, 0, w, h)
				surface.SetFont("DL_ResponseDisabled")
				local text = TTTLogTranslate(GetDMGLogLang, "ChatOpened")
				local wt, ht = surface.GetTextSize(text)
				wt = wt
				surface.SetTextColor(color_white)
				surface.SetTextPos(w / 2 - (wt - 14) / 2, h / 3 - ht / 2 + 10)
				surface.DrawText(text)
				surface.SetMaterial(Material("icon16/exclamation.png"))
				surface.SetDrawColor(color_white)
				surface.DrawTexturedRect(w / 2 - wt / 2 - 14, h / 3 - ht / 2 + 10, 16, 16)
			end
		end

		self.CurrentReports:SetOuputs(VictimMessage, KillerMessage)
		self.PreviousReports:SetOuputs(VictimMessage, KillerMessage)
		Manager:AddItem(VictimInfos)
		local VictimLogs
		local VictimLogsForm
		local Conclusion = vgui.Create("DPanel")
		surface.SetFont("DL_Conclusion")
		local cx, cy = surface.GetTextSize(TTTLogTranslate(GetDMGLogLang, "Conclusion") .. ":")
		local cm = 5

		Conclusion.PaintOver = function(panel, w, h)
			if not panel.t1 then return end
			surface.SetDrawColor(color_black)
			surface.DrawLine(0, 0, w - 1, 0)
			surface.DrawLine(w - 1, 0, w - 1, h - 1)
			surface.DrawLine(w - 1, h - 1, 0, h - 1)
			surface.DrawLine(0, h - 1, 0, 0)
			surface.SetFont("DL_Conclusion")
			surface.SetTextPos(cm, panel.t2 and (h / 3 - cy / 2) or (h / 2 - cy / 2))
			surface.SetTextColor(Color(0, 108, 155))
			surface.DrawText(TTTLogTranslate(GetDMGLogLang, "Conclusion") .. ":")
			surface.SetFont("DL_ConclusionText")
			surface.SetTextColor(color_black)
			local ty1 = surface.GetTextSize(panel.t1)
			surface.SetTextPos(cx + 2 * cm, panel.t2 and (h / 3 - cy / 2) or (h / 2 - cy / 2))
			surface.DrawText(panel.t1)

			if panel.t2 then
				local ty2 = surface.GetTextSize(panel.t2)
				surface.SetTextPos(cm, 2 * h / 3 - ty2 / 2)
				surface.DrawText(panel.t2)
			end
		end

		Conclusion.SetText = function(pnl, t)
			pnl.Text = t
			local t1, t2 = AdjustText(t, "DL_ConclusionText", pnl:GetWide() - cx - cm * 3)
			pnl.t1 = t1
			pnl.t2 = nil

			if t2 then
				pnl.t2 = t2
				pnl:SetHeight(45)
				KillerMessage:SetHeight(97)
				VictimMessage:SetHeight(97)
				VictimInfos:SetHeight(125)

				if VictimLogs then
					VictimLogs:SetHeight(215)
				end
			else
				pnl:SetHeight(30)
				KillerMessage:SetHeight(82)
				VictimMessage:SetHeight(82)
				VictimInfos:SetHeight(110)

				if VictimLogs then
					VictimLogs:SetHeight(245)
				end
			end

			if VictimLogsForm then
				VictimLogsForm:PerformLayout()
			end

			Manager:PerformLayout()
		end

		Conclusion.SetDefaultText = function(pnl)
			pnl:SetText(TTTLogTranslate(GetDMGLogLang, "NoSelectedReport"))
		end

		Conclusion.ApplySchemeSettings = function(pnl)
			if pnl.Text then
				pnl:SetText(pnl.Text)
			end
		end

		Conclusion:SetHeight(45)
		self.CurrentReports.Conclusion = Conclusion
		self.PreviousReports.Conclusion = Conclusion
		Manager:AddItem(Conclusion)
		VictimLogsForm = vgui.Create("DForm")
		VictimLogsForm.SetExpanded = function() end
		VictimLogsForm:SetName(TTTLogTranslate(GetDMGLogLang, "LogsBeforeVictim"))
		VictimLogs = vgui.Create("DListView")
		VictimLogs:AddColumn(TTTLogTranslate(GetDMGLogLang, "Time")):SetFixedWidth(40)
		VictimLogs:AddColumn(TTTLogTranslate(GetDMGLogLang, "Type")):SetFixedWidth(40)
		VictimLogs:AddColumn(TTTLogTranslate(GetDMGLogLang, "Event")):SetFixedWidth(559)
		VictimLogs:SetHeight(300)

		Damagelog.UpdateReportTexts = function()
			local selected = Damagelog.SelectedReport

			if not selected then
				VictimInfos.isAdmin = false
				VictimMessage:SetText("")
				KillerMessage:SetText("")
			else
				VictimInfos.isAdmin = selected.adminReport
				if selected.chatReport then
					VictimMessage:SetText(TTTLogTranslate(GetDMGLogLang, "ChatOpenNoMessage"))
				else
					VictimMessage:SetText(selected.message)
				end
				KillerMessage:SetText(selected.response or TTTLogTranslate(GetDMGLogLang, "NoResponseYet"))
			end

			VictimLogs:Clear()

			if selected and selected.logs then
				Damagelog:SetListViewTable(VictimLogs, selected.logs, false)
			end
		end

		Damagelog.DisableResponse = function(disable)
			VictimInfos.DisableR = disable
			KillerMessage.DisableR = disable
		end

		VictimLogsForm:AddItem(VictimLogs)
		VictimLogsForm.Items[1]:DockPadding(0, 0, 0, 0)
		Manager:AddItem(VictimLogsForm)
		self.Tabs:AddSheet(TTTLogTranslate(GetDMGLogLang, "RDMManag"), Manager, "icon16/magnifier.png", false, false)
		Conclusion:SetDefaultText()
		self.CurrentReports:UpdateAllReports()
		self.PreviousReports:UpdateAllReports()
	end
end

local PANEL = {}

function PANEL:Init()

	self.Distance = 25
	self.Dimension = 240

	self:SetSize(500, 260)
	self:SetDraggable(true)
	self:Center()
	self:MakePopup()

	self.SlayList = vgui.Create("DPanelList", self)
	self.SlayList:SetPos(self.Distance/2, self.Distance * 1.5)
	self.SlayList:SetSize(self.Dimension, self.Dimension)
	self.SlayList:SetSpacing(5)
	self.SlayList:EnableHorizontal(false)
	self.SlayList:EnableVerticalScrollbar(true)

	local SlayNum = vgui.Create("DLabel", self)
	SlayNum:SetPos(self.Distance/2 + 5, self.Dimension/2.5 + 65)
	SlayNum:SetSize(self.Distance * 4.65 , 25)
	SlayNum:SetText("1")

	self.Slays = {}
	self.NumSlays = 1

	for i = 1, 3 do
		local slay = vgui.Create("DCheckBoxLabel")
		local txt = i .. " slay"
		if i > 1 then
			txt = txt .. "s"
		end
		slay.Number = i
		slay:SetText(txt)
		slay:SetValue(i == 1 and 1 or 0)
		slay:SizeToContents()
		function slay.OnChange(slay, val)
			if val then
				for _, otherSlay in ipairs(self.Slays) do
					if otherSlay != slay then
						otherSlay:SetValue(0)
					end
				end
				self.NumSlays = slay.Number
				SlayNum:SetText(tostring(self.NumSlays))
			end
		end
		table.insert(self.Slays, slay)
		self.SlayList:AddItem(slay)
	end

	self.Reasons = {}

	local reasons1 = {
		Damagelog.Autoslay_DefaultReason1,
		Damagelog.Autoslay_DefaultReason2,
		Damagelog.Autoslay_DefaultReason3,
		Damagelog.Autoslay_DefaultReason4,
		Damagelog.Autoslay_DefaultReason5,
		Damagelog.Autoslay_DefaultReason6
	}

	self:AddReasonRow(self.Distance/2 + self.Dimension/2, self.Distance*1.5,
		self.Dimension, self.Dimension/2, reasons1)

	local reasons2 = {
		Damagelog.Autoslay_DefaultReason7,
		Damagelog.Autoslay_DefaultReason8,
		Damagelog.Autoslay_DefaultReason9,
		Damagelog.Autoslay_DefaultReason10,
		Damagelog.Autoslay_DefaultReason11,
		Damagelog.Autoslay_DefaultReason12
	}

	self:AddReasonRow(self.Distance + self.Dimension * 1.25, self.Distance*1.5,
		self.Dimension, self.Dimension/2, reasons2)

	local DLabel = vgui.Create("DLabel", self)
	DLabel:SetPos(self.Distance/2, self.Dimension/2.5 + 5)
	DLabel:SetSize(self.Distance * 4.65 , 25)

	DLabel:SetText(TTTLogTranslate(GetDMGLogLang, "GoingToSlay"))
	self.NameLabel = vgui.Create("DLabel", self)
	self.NameLabel:SetPos(self.Distance/2 + 5, self.Dimension/2.5 + 25)
	self.NameLabel:SetSize(self.Distance * 4.65 - 15, 25)
	self.NameLabel:SetText("")

	local DLabel = vgui.Create("DLabel", self)
	DLabel:SetPos(self.Distance/2, self.Dimension/2.5 + 45)
	DLabel:SetSize(self.Distance * 4.65 , 25)
	DLabel:SetText(TTTLogTranslate(GetDMGLogLang, "ThisOften"))

	self.Reason = vgui.Create("DLabel", self )
	self.Reason:SetPos(self.Distance/2,self.Dimension*2/3 + 31)
	self.Reason:SetSize(self:GetWide() - self.Distance/2, 30)
	self.Reason:SetText(TTTLogTranslate(GetDMGLogLang, "Reason"))

	self.CREnable = vgui.Create("DCheckBox", self)
	self.CREnable:SetPos(self.Distance/2 + self.Dimension/2 ,self.Dimension*2/3 + 5)
	self.CREnable:SetValue(1)
	function self.CREnable.OnChange(panel, reasonTxt)
		self:UpdateReason()
	end

	self.CustomReason = vgui.Create("DTextEntry", self)
	self.CustomReason:SetPos(self.Distance/2 + self.Dimension/2 + 25, self.Dimension*2/3)
	self.CustomReason:SetSize(self.Dimension*1.5 - 35, 25)
	self.CustomReason:SetText(TTTLogTranslate(GetDMGLogLang, "DefaultReason"))
	self.CustomReason.OnChange = function(panel)
		self:UpdateReason()
	end
	self.CustomReason.OnEnter = function(panel)
		self.Button:DoClick()
	end
	self.CustomReason:RequestFocus()
	self.CustomReason:SelectAll()

	self.Button = vgui.Create("DButton", self)
	if ulx and mode == 2 then
		self.Button:SetText("ajail!")
	else
		self.Button:SetText("aslay!")
	end
	self.Button:SetPos(self.Distance/4,self.Dimension*2/3 + 60)
	self.Button:SetSize(self:GetWide() - self.Distance/2 , 30)

	self:UpdateReason()

end

function PANEL:SetPlayer(reported, ply, steamid, report)
	if ulx then
		self:SetTitle(string.format(TTTLogTranslate(GetDMGLogLang, (mode == 1 and "Autoslaying" or "Autojailing")), (reported and report.attacker_nick or report.victim_nick)))
	else
		self:SetTitle(string.format(TTTLogTranslate(GetDMGLogLang, "Autoslaying"), (reported and report.attacker_nick or report.victim_nick)))
	end
	self.NameLabel:SetText(reported and report.attacker_nick or report.victim_nick)
	self.Button.DoClick = function(panel)
		if IsValid(ply) then
			if ulx then
				RunConsoleCommand("ulx", mode == 1 and "aslay" or "ajail", ply:Nick(), tostring(self.NumSlays), self.CurrentReason)
			else
				serverguard.command.Run("aslay", false, ply:Nick(), self.NumSlays, self.CurrentReason)
			end
			self.SetConclusion(ply:Nick(), self.NumSlays, self.CurrentReason)
		else
			if ulx then
				RunConsoleCommand("ulx", mode == 1 and "aslayid" or "ajailid", (reported and report.attacker) or (not reported and report.victim), tostring(self.NumSlays), self.CurrentReason)
				self.SetConclusion((reported and report.attacker_nick) or (not reported and report.victim_nick), self.NumSlays, self.CurrentReason)
			else
				Damagelog:Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(GetDMGLogLang, "VictimReportedDisconnected"), 2, "buttons/weapon_cant_buy.wav")
			end
		end
		self:Close()
	end
end

function PANEL:UpdateReason()
	local reason = ""
	local CRAdded = false
	if self.CREnable:GetChecked() then
		reason = reason .. self.CustomReason:GetText()
		CRAdded = true
	end
	local first = true
	for index, label in ipairs(self.Reasons) do
		if label:GetChecked() then
			if CRAdded or (not first) then
				reason = reason .. " + "
				CRAdded = false
			end
			reason = reason .. label:GetText()
			if first then
				first = false
			end
		end
	end
	self.CurrentReason = reason
	self.Reason:SetText(TTTLogTranslate(GetDMGLogLang, "Reason")..reason)
end

function PANEL:PaintOver(w, h)
	surface.SetDrawColor(color_white)
	surface.DrawLine(self.Distance/2 + self.Dimension/2 - 10,
		self.Distance * 1.5 - 1,
		self.Distance/2 + self.Dimension/2 - 10,
		self.Distance * 1.5 + self.Dimension * 2/3  - 6)
	surface.DrawLine(self.Distance/2 - 5,
		self.Dimension/2.5 + 5,
		self.Distance * 4.85,
		self.Dimension/2.5 + 5)
	surface.DrawLine(self.Distance/2 - 5,
		self.Dimension*2/3 + 31,
		w * 23/24 + 5,
		self.Dimension*2/3 + 31)
end

function PANEL:AddReasonRow(x, y, w, h, reasons)

	local DermaList = vgui.Create("DPanelList", self)
	DermaList:SetPos(x, y)
	DermaList:SetSize(w, h)
	DermaList:SetSpacing(5)
	DermaList:EnableHorizontal(false)
	DermaList:EnableVerticalScrollbar(true)

	for _, reason in ipairs(reasons) do
		local checkBox = vgui.Create("DCheckBoxLabel")
		checkBox:SetText(reason)
		checkBox:SetValue(0)
		checkBox:SizeToContents()
		function checkBox.OnChange(panel)
			if self.CustomReason:GetValue() == TTTLogTranslate(GetDMGLogLang, "DefaultReason") then
				self.CREnable:SetChecked(false)
			end
			self:UpdateReason()
		end
		table.insert(self.Reasons, checkBox)
		DermaList:AddItem(checkBox)
	end

end

vgui.Register("RDM_Manager_Slay_Reason", PANEL, "DFrame")


local PANEL = {}

PANEL.MINUTES = 1
PANEL.HOURS = 2
PANEL.DAYS = 3

function PANEL:Init()

	self.Distance = 25
	self.Dimension = 240

	self:SetSize(500, 260)
	self:SetDraggable(true)
	self:Center()
	self:MakePopup()

	self.BanPanel = vgui.Create("DPanelList", self)
	self.BanPanel:SetPos(self.Distance/2, self.Distance * 1.5)
	self.BanPanel:SetSize(self.Dimension/3 + 20, self.Dimension/3)
	self.BanPanel:SetSpacing(5)
	self.BanPanel:EnableHorizontal(false)
	self.BanPanel:EnableVerticalScrollbar(true)

	self.BanTime = vgui.Create("DTextEntry", self.BanPanel)
	self.BanTime:SetSize(40/3.5, 20)
	self.BanTime:SetText("50")
	self.BanPanel:AddItem(self.BanTime)

	self.Minutes = vgui.Create("DCheckBoxLabel")
	self.Minutes:SetText(TTTLogTranslate(GetDMGLogLang, "Minutes"))
	self.Minutes:SetValue(1)
	self.Minutes:SizeToContents()
	self.CurrentBanType = self.MINUTES
	self.Minutes.OnChange = function(panel)
		if panel:GetChecked() then
			self.CurrentBanType = self.MINUTES
			self.Hours:SetValue(0)
			self.Days:SetValue(0)
			self:UpdateBanTime()
		end
	end
	self.BanPanel:AddItem(self.Minutes)

	self.Hours = vgui.Create("DCheckBoxLabel")
	self.Hours:SetText(TTTLogTranslate(GetDMGLogLang, "Hours"))
	self.Hours:SetValue(0)
	self.Hours:SizeToContents()
	self.Hours.OnChange = function(panel)
		if panel:GetChecked() then
			self.CurrentBanType = self.HOURS
			self.Minutes:SetValue(0)
			self.Days:SetValue(0)
			self:UpdateBanTime()
		end
	end
	self.BanPanel:AddItem(self.Hours)

	self.Days = vgui.Create("DCheckBoxLabel")
	self.Days:SetText(TTTLogTranslate(GetDMGLogLang, "Days"))
	self.Days:SetValue(0)
	self.Days:SizeToContents()
	self.Days.OnChange = function(panel)
		if panel:GetChecked() then
			self.CurrentBanType = self.DAYS
			self.Hours:SetValue(0)
			self.Minutes:SetValue(0)
			self:UpdateBanTime()
		end
	end
	self.BanPanel:AddItem(self.Days)

	self.Reasons = {}

	local reasons1 = {
		Damagelog.Ban_DefaultReason1,
		Damagelog.Ban_DefaultReason2,
		Damagelog.Ban_DefaultReason3,
		Damagelog.Ban_DefaultReason4,
		Damagelog.Ban_DefaultReason5,
		Damagelog.Ban_DefaultReason6
	}

	self:AddReasonRow(self.Distance/2 + self.Dimension/2, self.Distance*1.5,
		self.Dimension, self.Dimension/2, reasons1)

	local reasons2 = {
		Damagelog.Ban_DefaultReason7,
		Damagelog.Ban_DefaultReason8,
		Damagelog.Ban_DefaultReason9,
		Damagelog.Ban_DefaultReason10,
		Damagelog.Ban_DefaultReason11,
		Damagelog.Ban_DefaultReason12
	}

	self:AddReasonRow(self.Distance + self.Dimension * 1.25, self.Distance*1.5,
		self.Dimension, self.Dimension/2, reasons2)

	local DLabel  = vgui.Create("DLabel", self)
	DLabel:SetPos(self.Distance/2, self.Dimension/2.5 + 35)
	DLabel:SetText(TTTLogTranslate(GetDMGLogLang, "GoingToBan"))
	DLabel:SizeToContents()

	self.NameLabel= vgui.Create("DLabel", self)
	self.NameLabel:SetPos(self.Distance/2 + 5, self.Dimension/2.5 + 48)
	self.NameLabel:SetSize(self.Distance * 4.65 , 25)
	self.NameLabel:SetText("")

	self.TimeLabel = vgui.Create("DLabel", self)
	self.TimeLabel:SetPos(self.Distance/2, self.Dimension/2.5 + 67)
	self.TimeLabel:SetSize(self.Distance * 4.65 , 25)
	self.TimeLabel:SetText(TTTLogTranslate(GetDMGLogLang, "forspace"))

	self.Reason = vgui.Create("DLabel", self )
	self.Reason:SetPos(self.Distance/2,self.Dimension*2/3 + 31)
	self.Reason:SetSize(self:GetWide() - self.Distance/2, 30)
	self.Reason:SetText(TTTLogTranslate(GetDMGLogLang, "Reason"))

	self.CREnable = vgui.Create("DCheckBox", self)
	self.CREnable:SetPos(self.Distance/2 + self.Dimension/2 ,self.Dimension*2/3 + 5)
	self.CREnable:SetValue(1)
	function self.CREnable.OnChange(panel, reasonTxt)
		self:UpdateReason()
	end

	self.CustomReason = vgui.Create("DTextEntry", self)
	self.CustomReason:SetPos(self.Distance/2 + self.Dimension/2 + 25, self.Dimension*2/3)
	self.CustomReason:SetSize(self.Dimension*1.5 - 35, 25)
	self.CustomReason:SetText(TTTLogTranslate(GetDMGLogLang, "DefaultReason"))
	self.CustomReason.OnChange = function(panel)
		self:UpdateReason()
	end
	self.CustomReason.OnEnter = function(panel)
		self.Button:DoClick()
	end
	self.CustomReason:RequestFocus()
	self.CustomReason:SelectAll()

	self.Button = vgui.Create("DButton", self)
	self.Button:SetText("Ban")
	self.Button:SetPos(self.Distance/4,self.Dimension*2/3 + 60)
	self.Button:SetSize(self:GetWide() - self.Distance/2 , 30)

	self:UpdateBanTime()
	self:UpdateReason()

end

function PANEL:UpdateBanTime()
	local banTime = tonumber(self.BanTime:GetValue()) or 0
	if banTime == 0 then
		self.BanTimeNumber = 0
		self.TimeLabel:SetText(TTTLogTranslate(GetDMGLogLang, "Permanently"))
	elseif self.CurrentBanType == self.MINUTES then
		self.BanTimeNumber = banTime
		self.TimeLabel:SetText(string.format(TTTLogTranslate(GetDMGLogLang, "ForMinutes"), banTime))
	elseif self.CurrentBanType == self.HOURS then
		self.BanTimeNumber = 60 * banTime
		self.TimeLabel:SetText(string.format(TTTLogTranslate(GetDMGLogLang, "ForHours"), banTime))
	else
		self.BanTimeNumber = 1440 * banTime
		self.TimeLabel:SetText(string.format(TTTLogTranslate(GetDMGLogLang, "ForDays"), banTime))
	end
end

function PANEL:SetPlayer(reported, ply, steamid, report)
	self:SetTitle("Banning "..(reported and report.attacker_nick or report.victim_nick))
	self.NameLabel:SetText(reported and report.attacker_nick or report.victim_nick)
	self.Button.DoClick = function(panel)
		if IsValid(ply) then
			if ulx then
				RunConsoleCommand("ulx", "ban", ply:Nick(), tostring(self.BanTimeNumber), self.CurrentReason)
			else
				serverguard.command.Run("ban", false, ply:Nick(), self.BanTimeNumber, self.CurrentReason)
			end
			self.SetConclusion(ply:Nick(), self.TimeLabel:GetText(), self.CurrentReason)
		else
			if ulx then
				RunConsoleCommand("ulx", "banid", (reported and report.attacker) or (not reported and report.victim), tostring(self.BanTimeNumber), self.CurrentReason)
				self.SetConclusion((reported and report.attacker_nick) or (not reported and report.victim_nick), self.TimeLabel:GetText(), self.CurrentReason)
			else
				Damagelog:Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(GetDMGLogLang, "VictimReportedDisconnected"), 2, "buttons/weapon_cant_buy.wav")
			end
		end
		self:Close()
	end
end

function PANEL:UpdateReason()
	local reason = ""
	local CRAdded = false
	if self.CREnable:GetChecked() then
		reason = reason .. self.CustomReason:GetText()
		CRAdded = true
	end
	local first = true
	for index, label in ipairs(self.Reasons) do
		if label:GetChecked() then
			if CRAdded or (not first) then
				reason = reason .. " + "
				CRAdded = false
			end
			reason = reason .. label:GetText()
			if first then
				first = false
			end
		end
	end
	self.CurrentReason = reason
	self.Reason:SetText(TTTLogTranslate(GetDMGLogLang, "Reason")..reason)
end

function PANEL:PaintOver(w, h)
	surface.SetDrawColor(color_white)
	surface.DrawLine(self.Distance/2 + self.Dimension/2 - 10,
		self.Distance * 1.5 - 1,
		self.Distance/2 + self.Dimension/2 - 10,
		self.Distance * 1.5 + self.Dimension * 2/3  - 6)
	surface.DrawLine(self.Distance/2 - 5,
		self.Dimension/2 + 5,
		self.Distance * 4.85,
		self.Dimension/2 + 5)
	surface.DrawLine(self.Distance/2 - 5,
		self.Dimension*2/3 + 31,
		w * 23/24 + 5,
		self.Dimension*2/3 + 31)
end

function PANEL:AddReasonRow(x, y, w, h, reasons)

	local DermaList = vgui.Create("DPanelList", self)
	DermaList:SetPos(x, y)
	DermaList:SetSize(w, h)
	DermaList:SetSpacing(5)
	DermaList:EnableHorizontal(false)
	DermaList:EnableVerticalScrollbar(true)

	for _, reason in ipairs(reasons) do
		local checkBox = vgui.Create("DCheckBoxLabel")
		checkBox:SetText(reason)
		checkBox:SetValue(0)
		checkBox:SizeToContents()
		function checkBox.OnChange(panel)
			if self.CustomReason:GetValue() == TTTLogTranslate(GetDMGLogLang, "DefaultReason") then
				self.CREnable:SetChecked(false)
			end
			self:UpdateReason()
		end
		table.insert(self.Reasons, checkBox)
		DermaList:AddItem(checkBox)
	end

end

vgui.Register("RDM_Manager_Ban_Reason", PANEL, "DFrame")
