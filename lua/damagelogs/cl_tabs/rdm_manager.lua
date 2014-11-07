
surface.CreateFont("DL_RDM_Manager", {
	font = "DermaLarge",
	size = 20
})

local show_finished = CreateClientConVar("rdm_manager_show_finished", "1", FCVAR_ARCHIVE)

cvars.AddChangeCallback("rdm_manager_show_finished", function(name, old, new)
	if Damagelog.CurrentReports and Damagelog.CurrentReports:IsValid() then
		Damagelog.CurrentReports:UpdateAllReports()
	end
	if Damagelog.PreviousReports and Damagelog.PreviousReports:IsValid() then
		Damagelog.PreviousReports:UpdateAllReports()
	end
end)

local status = {
	[RDM_MANAGER_WAITING] = "Waiting",
	[RDM_MANAGER_PROGRESS] = "In progress",
	[RDM_MANAGER_FINISHED] = "Finished",
	[RDM_MANAGER_CANCELED] = "Canceled by the victim"
}

local icons = {
	[RDM_MANAGER_WAITING] = "icon16/clock.png",
	[RDM_MANAGER_PROGRESS] = "icon16/arrow_refresh.png",
	[RDM_MANAGER_FINISHED] = "icon16/accept.png"
}

local colors = {
	[RDM_MANAGER_WAITING] = Color(100,100, 0),
	[RDM_MANAGER_PROGRESS] = Color(0,0,190),
	[RDM_MANAGER_FINISHED] = Color(0,190, 0),
	[RDM_MANAGER_CANCELED] = Color(100, 100, 100)
}

local function GetBySteamID(steamid)
	for k,v in pairs(player.GetAll()) do
		if v:SteamID() == steamid then
			return v
		end
	end
end

local function TakeAction()
	local report = Damagelog.SelectedReport
	if not report then return end
	local current = not report.previous
	local attacker = GetBySteamID(report.attacker)
	local victim = GetBySteamID(report.victim)
	local menuPanel = DermaMenu()
	menuPanel:AddOption("Force the reported player to respond", function()
		if IsValid(attacker) then
			net.Start("DL_ForceRespond")
			net.WriteUInt(report.index, 4)
			net.WriteUInt(current and 0 or 1, 1)
			net.SendToServer()
		else
			Derma_Message("The reported player isn't valid! (disconnected?)", "Error", "OK")
		end
	end):SetImage("icon16/clock_red.png")
	menuPanel:AddOption("View Death Scene", function()
		local found = false
		PrintTable(report.logs)
		for k,v in pairs(report.logs or {}) do
			print(v[6], report.victim, v[7], report.attacker)
			if v.type == "KILL" then
				local infos = v.infos
				if infos[6] == report.victim and infos[7] == report.attacker then
					net.Start("DL_AskDeathScene")
					net.WriteUInt(infos[8], 32)
					net.WriteString(report.victim)
					net.WriteString(report.attacker)
					net.SendToServer()
					found = true
					break
				end
			end
		end
		if not found then
			Derma_Message("Could not find the Death Scene", "Error", "OK")
		end
	end):SetImage("icon16/television.png")
	if ulx then
		if Damagelog.Enable_Autoslay then
			menuPanel:AddOption("Autoslay the reported player", function()
				if IsValid(attacker) then
					Derma_StringRequest("Reason", "Please type the reason as to why you want to slay "..attacker:Nick(), "", function(txt)
						RunConsoleCommand("ulx", "autoslay", attacker:Nick(), "1", txt)
					end)
				else
					Derma_Message("The reported player isn't valid! (disconnected?)", "Error", "OK")
				end
			end):SetImage("icon16/user_delete.png")
			menuPanel:AddOption("Remove slays of the reported player", function()
				if IsValid(attacker) then
					RunConsoleCommand("ulx", "autoslay", attacker:Nick(), "0")
				else
					Derma_Message("The reported player isn't valid! (disconnected?)", "Error", "OK")
				end
			end):SetImage("icon16/user_edit.png")
		end
		menuPanel:AddOption("Slay the reported player now", function()
			if IsValid(attacker) then
				RunConsoleCommand("ulx", "slay", attacker:Nick())
			else
				Derma_Message("The reported player isn't valid! (disconnected?)", "Error", "OK")
			end
		end):SetImage("icon16/lightning.png")
	end
	menuPanel:Open()
end


local PANEL = {}

function PANEL:Init()
	self:SetMultiSelect(false)
	self:AddColumn("id"):SetFixedWidth(34)
	self:AddColumn("Victim"):SetFixedWidth(105)
	self:AddColumn("Reported player"):SetFixedWidth(105)
	self:AddColumn("Round"):SetFixedWidth(54)
	self:AddColumn("Autoslay status"):SetFixedWidth(135)
	self:AddColumn("Status"):SetFixedWidth(180)
	self.Reports = {}
end

function PANEL:SetOuputs(victim, killer)
	self.VictimOutput = victim
	self.KillerOuput = killer
end

function PANEL:SetReportsTable(tbl)
	self.ReportsTable = tbl
end

function PANEL:GetAttackerSlays(report)
	for k,v in pairs(player.GetAll()) do
		local steamid = v:IsBot() and "BOT" or v:SteamID()
		if steamid == report.attacker then
			local slays = v:GetNWInt("Autoslays_left", 0)
			if slays <= 0 then
				return v:Nick().." not slain"
			else
				return v:Nick().." slain "..slays.." times"
			end
		end
	end
	return "Player not found"
end

function PANEL:GetStatus(report)
	local str = status[report.status]
	if (report.status == RDM_MANAGER_FINISHED or report.status == RDM_MANAGER_PROGRESS) and report.admin then
		str = str.." by "..report.admin
	end
	return str
end

function PANEL:UpdateReport(index)
	local report = self.ReportsTable[index]
	local tbl = {
		report.index,
		report.victim_nick,
		report.attacker_nick,
		report.round or "?",
		self:GetAttackerSlays(report),
		self:GetStatus(report)
	}
	if not self.Reports[index] then
		if report.status != RDM_MANAGER_FINISHED or show_finished:GetBool() then
			self.Reports[index] = self:AddLine(unpack(tbl))
			self.Reports[index].status = report.status
			self.Reports[index].index = report.index
			local tbl = { self.Reports[index] }
			for k,v in ipairs(self.Sorted) do
				if k == #self.Sorted then continue end
				table.insert(tbl, v)
			end
			self.Sorted = tbl
			self:InvalidateLayout()
			self.Reports[index].PaintOver = function(self)
				if self:IsLineSelected() then 
					self.Columns[2]:SetTextColor(color_white)
					self.Columns[3]:SetTextColor(color_white)
					self.Columns[6]:SetTextColor(color_white)
				else
					self.Columns[2]:SetTextColor(Color(0, 190, 0))
					self.Columns[3]:SetTextColor(Color(190, 0, 0))
					self.Columns[6]:SetTextColor(colors[self.status] or color_white)
				end
			end
			self.Reports[index].OnRightClick = function(self)
				TakeAction()
			end
			self.Reports[index].Think = function(pnl)
				self.Reports[pnl.index]:SetValue(5, self:GetAttackerSlays(report))
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
			for k,v in ipairs(self.Reports[index].Columns) do
				self.Reports[index]:SetValue(k, tbl[k])
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
	for i=1, #self.ReportsTable do
		self:AddReport(i)
	end
	if Damagelog.SelectedReport then
		local selected_current = not Damagelog.SelectedReport.Previous
		local current = not self.Previous
		if Damagelog.SelectedReport.status == RDM_MANAGER_FINISHED and not show_finished:GetBool() then
			for k,v in pairs(self.Lines) do
				v:SetSelected(false)
			end
			Damagelog.SelectedReport = nil
			Damagelog:UpdateReportTexts()
		elseif selected_current == current then
			for k,v in pairs(self.Lines) do
				if Damagelog.SelectedReport.index == v.index then
					v:SetSelected(true)
					break
				end
			end
		end
		Damagelog:UpdateReportTexts()
	end
end

function PANEL:OnRowSelected(index, line)
	Damagelog.SelectedReport = self.ReportsTable[line.index]
	Damagelog:UpdateReportTexts()
end

vgui.Register("RDM_Manager_ListView", PANEL, "DListView")

net.Receive("DL_NewReport", function()
	local tbl = net.ReadTable()
	local index = table.insert(Damagelog.Reports.Current, tbl)
	Damagelog.Reports.Current[index].index = index
	if Damagelog.CurrentReports and Damagelog.CurrentReports:IsValid() then
		Damagelog.CurrentReports:AddReport(index)
	end
end)

net.Receive("DL_UpdateReport", function()
	local previous = net.ReadUInt(1) == 1
	local index = net.ReadUInt(4)
	local updated = net.ReadTable()
	updated.index = index
	if previous then
		Damagelog.Reports.Previous[index] = updated
		if Damagelog.PreviousReports and Damagelog.PreviousReports:IsValid() then
			Damagelog.PreviousReports:UpdateReport(index)
		end
	else
		Damagelog.Reports.Current[index] = updated
		if Damagelog.CurrentReports and Damagelog.CurrentReports:IsValid() then
			Damagelog.CurrentReports:UpdateReport(index)
		end
	end
end)

net.Receive("DL_UpdateReports", function()
	Damagelog.SelectedReport = nil
	Damagelog.Reports = net.ReadTable()
	if Damagelog.CurrentReports and Damagelog.CurrentReports:IsValid() then
		Damagelog.CurrentReports:UpdateAllReports()
	end	
	if Damagelog.PreviousReports and Damagelog.PreviousReports:IsValid() then
		Damagelog.PreviousReports:UpdateAllReports()
	end		
end)

function Damagelog:DrawRDMManager(x,y)
	if LocalPlayer():CanUseRDMManager() and Damagelog.RDM_Manager_Enabled then
		
		local Manager = vgui.Create("DPanelList");
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
		ReportsSheet:AddSheet("Reports", self.CurrentReports, "icon16/zoom.png")
		
		self.PreviousReports = vgui.Create("RDM_Manager_ListView")
		self.PreviousReports:SetReportsTable(Damagelog.Reports.Previous)
		self.PreviousReports.Previous = true
		ReportsSheet:AddSheet("Previous map reports", self.PreviousReports, "icon16/world.png")
	
		local ShowFinished = vgui.Create("DCheckBoxLabel", Background)
		ShowFinished:SetText("Show finished reports")
		ShowFinished:SetConVar("rdm_manager_show_finished")
		ShowFinished:SizeToContents()
		ShowFinished:SetPos(235, 7)
	
		local TakeActionB = vgui.Create("DButton", Background)
		TakeActionB:SetText("Take Action")
		TakeActionB:SetPos(380, 4)
		TakeActionB:SetSize(125, 18)
		TakeActionB.Think = function(self)
			self:SetDisabled(not Damagelog.SelectedReport or Damagelog.SelectedReport.status == RDM_MANAGER_CANCELED)
		end
		TakeActionB.DoClick = function(self)
			TakeAction()
		end
	
		local SetState = vgui.Create("DButton", Background)
		SetState:SetText("Set Status")
		SetState:SetPos(510, 4)
		SetState:SetSize(125, 18)
		SetState.Think = function(self)
			self:SetDisabled(not Damagelog.SelectedReport or Damagelog.SelectedReport.status == RDM_MANAGER_CANCELED)
		end
		SetState.DoClick = function()
			local menu = DermaMenu()
			for k,v in ipairs(status) do
				if k == RDM_MANAGER_CANCELED then continue end
				menu:AddOption(v, function()
					net.Start("DL_UpdateStatus")
					net.WriteUInt(Damagelog.SelectedReport.previous and 1 or 0, 1)
					net.WriteUInt(Damagelog.SelectedReport.index, 4)
					net.WriteUInt(k, 4)
					net.SendToServer()
				end):SetImage(icons[k])
			end
			menu:Open()
		end
		
		Manager:AddItem(Background)
		
		local VictimInfos = vgui.Create("DPanel")
		VictimInfos:SetHeight(160)
		VictimInfos.Paint = function(panel, w, h)
			local bar_height = 27
			surface.SetDrawColor(30, 200, 30);
			surface.DrawRect(0, 0, (w/2), bar_height);
			draw.SimpleText("Victim's report", "DL_RDM_Manager", w/4, bar_height/2, Color(0,0,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER);
			surface.SetDrawColor(220, 30, 30);
			surface.DrawRect((w/2)+1, 0, (w/2), bar_height);
			draw.SimpleText("Reported player's response", "DL_RDM_Manager", (w/2) + 1 + (w/4), bar_height/2, Color(0,0,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER);
			surface.SetDrawColor(0, 0, 0);
			surface.DrawOutlinedRect(0, 0, w, h);
			surface.DrawLine(w/2, 0, w/2, h);
			surface.DrawLine(0, 27, w, bar_height);
		end
		
		local VictimMessage = vgui.Create("DTextEntry", VictimInfos);
		VictimMessage:SetMultiline(true);
		VictimMessage:SetKeyboardInputEnabled(false);
		VictimMessage:SetPos(1, 27)
		VictimMessage:SetSize(319, 132)
		
		local KillerMessage = vgui.Create("DTextEntry", VictimInfos);
		KillerMessage:SetMultiline(true);
		KillerMessage:SetKeyboardInputEnabled(false);
		KillerMessage:SetPos(319, 27)
		KillerMessage:SetSize(319, 132)
		
		self.CurrentReports:SetOuputs(VictimMessage, KillerMessage)
		self.PreviousReports:SetOuputs(VictimMessage, KillerMessage)

		Manager:AddItem(VictimInfos)
		
		local VictimLogsForm = vgui.Create("DForm")
		VictimLogsForm.SetExpanded = function() end
		VictimLogsForm:SetName("Logs before the victim's death")
	
		local VictimLogs = vgui.Create("DListView")
		VictimLogs:AddColumn("Time"):SetFixedWidth(40)
		VictimLogs:AddColumn("Type"):SetFixedWidth(40)
		VictimLogs:AddColumn("Event"):SetFixedWidth(539)
		VictimLogs:SetHeight(220)
		
		Damagelog.UpdateReportTexts = function()
			local selected = Damagelog.SelectedReport
			if not selected then
				VictimMessage:SetText("")
				KillerMessage:SetText("")
			else
				VictimMessage:SetText(selected.message)
				KillerMessage:SetText(selected.response or "No response yet")
			end
			VictimLogs:Clear()
			if selected.logs then
				Damagelog:SetListViewTable(VictimLogs, selected.logs, false)
			end
		end
		
		VictimLogsForm:AddItem(VictimLogs)
	
		Manager:AddItem(VictimLogsForm)
		
		self.Tabs:AddSheet("RDM Manager", Manager, "icon16/magnifier.png", false, false)	
		
		self.CurrentReports:UpdateAllReports()
		self.PreviousReports:UpdateAllReports()
	end
end

