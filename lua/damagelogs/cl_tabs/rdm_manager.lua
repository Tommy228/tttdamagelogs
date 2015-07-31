
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


local function AdjustText(str, font, w)
	surface.SetFont(font)
	local size = surface.GetTextSize(str)
	if size <= w then
		return str
	else
		local last_space
		local i = 0
		for k,v in pairs(string.ToTable(str)) do
			local _w,h = surface.GetTextSize(v)
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
	if Damagelog.CurrentReports and Damagelog.CurrentReports:IsValid() then
		Damagelog.CurrentReports:UpdateAllReports()
	end
	if Damagelog.PreviousReports and Damagelog.PreviousReports:IsValid() then
		Damagelog.PreviousReports:UpdateAllReports()
	end
end)

local status = {
	[RDM_MANAGER_WAITING_FOR_ATTACKER] = "Waiting for reported player",
	[RDM_MANAGER_WAITING_FOR_VICTIM] = "Waiting for victim",
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
	[RDM_MANAGER_WAITING_FOR_ATTACKER] = Color(100,100, 0),
	[RDM_MANAGER_WAITING_FOR_VICTIM] = Color(100,100, 0),
	[RDM_MANAGER_WAITING] = Color(100,100, 0),
	[RDM_MANAGER_PROGRESS] = Color(0,0,190),
	[RDM_MANAGER_FINISHED] = Color(0,190, 0),
	[RDM_MANAGER_CANCELED] = Color(100, 100, 100)
}

local function TakeAction()
	local report = Damagelog.SelectedReport
	if not report then return end
	local current = not report.previous
	local attacker = player.GetBySteamID(report.attacker)
	local victim = player.GetBySteamID(report.victim)
	local menuPanel = DermaMenu()
	menuPanel:AddOption("Set conclusion", function()
		if report.status != RDM_MANAGER_FINISHED then
			Damagelog:Notify(DAMAGELOG_NOTIFY_ALERT, "This report is not finished!", 3, "buttons/weapon_cant_buy.wav")
			return
		end
		Derma_StringRequest("Conclusion", "Please write the conclusion for this report", "", function(txt)
			if #txt > 0 and #txt < 200 then
				net.Start("DL_Conclusion")
				net.WriteUInt(0,1)
				net.WriteUInt(report.previous and 1 or 0, 1)
				net.WriteUInt(report.index, 16)
				net.WriteString(txt)
				net.SendToServer()
			end
		end)
	end):SetImage("icon16/comment.png")
	if report.status == RDM_MANAGER_WAITING_FOR_ATTACKER then
		menuPanel:AddOption("Force the reported player to respond", function()
			if IsValid(attacker) then
				net.Start("DL_ForceRespond")
				net.WriteUInt(report.index, 16)
				net.WriteUInt(current and 0 or 1, 1)
				net.SendToServer()
			else
				Derma_Message("The reported player isn't valid! (disconnected?)", "Error", "OK")
			end
		end):SetImage("icon16/clock_red.png")
	end
	if report.status == RDM_MANAGER_PROGRESS then
		if not report.chat_open then
			menuPanel:AddOption(report.chat_opened and "Reopen chat" or "Open chat", function()
				net.Start("DL_StartChat")
				net.WriteUInt(report.index, 32)
				net.SendToServer()
				if not report.response then
					Damagelog.DisableResponse(true)
				end
			end):SetImage("icon16/application_view_list.png")
		else
			menuPanel:AddOption("Join chat", function()
				net.Start("DL_JoinChat")
				net.WriteUInt(report.index, 32)
				net.SendToServer()
			end):SetImage("icon16/application_go.png")
		end
	end
	menuPanel:AddOption("View Death Scene", function()
		local found = false
		for k,v in pairs(report.logs or {}) do
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
			local slaynr_pnl = vgui.Create("DMenuOption", menuPanel)
			local slaynr = DermaMenu(menuPanel)
			slaynr:SetVisible(false)
			slaynr_pnl:SetSubMenu(slaynr)
			slaynr_pnl:SetText("Slay next round")
			slaynr_pnl:SetImage("icon16/lightning_go.png")
			menuPanel:AddPanel(slaynr_pnl)
			local function SetConclusion(ply, num, reason)
				net.Start("DL_Conclusion")
				net.WriteUInt(1,1)
				net.WriteUInt(report.previous and 1 or 0, 1)
				net.WriteUInt(report.index, 16)
				net.WriteString("(Auto) "..ply.." slain "..num.." times for "..reason..".")
				net.SendToServer()
			end
			local function AddSlayPlayer(reported)
				local ply_pnl = vgui.Create("DMenuOption", slaynr)
				local ply = DermaMenu(ply_pnl)
				ply:SetVisible(false)
				ply_pnl:SetSubMenu(ply)
				ply_pnl:SetText(reported and "Reported player" or "Victim")
				ply_pnl:SetImage(reported and "icon16/user_delete.png" or "icon16/user.png")
				slaynr:AddPanel(ply_pnl)
				for k,v in ipairs( {"bullet_green.png", "bullet_yellow.png", "bullet_red.png"} )do
					local numbers_pnl = vgui.Create("DMenuOption", ply)
					local numbers = DermaMenu(numbers_pnl)
					numbers:SetVisible(false)
					numbers_pnl:SetSubMenu(numbers)
					numbers_pnl:SetText(k.." times")
					numbers_pnl:SetImage("icon16/"..v)
					ply:AddPanel(numbers_pnl)
					numbers:AddOption("Default reason", function()
						local ply = (reported and attacker) or (not reported and victim)
						if IsValid(ply) then
							RunConsoleCommand("ulx", "aslay", ply:Nick(), tostring(k))
							SetConclusion(ply:Nick(), k, "the default reason")
						else
							RunConsoleCommand("ulx", "aslayid", (reported and report.attacker) or (not reported and report.victim), tostring(k))
							SetConclusion((reported and report.attacker_nick) or (not reported and report.victim_nick), k, "the default reason")
						end
					end):SetImage("icon16/mouse.png")
					numbers:AddOption("Set reason...", function()
						local nick = (reported and report.attacker_nick) or (not reported and report.victim_nick)
						Derma_StringRequest("Reason", "Please type the reason why you want to slay "..nick, "", function(txt)
							local ply = (reported and attacker) or (not reported and victim)
							if IsValid(ply) then
								RunConsoleCommand("ulx", "aslay", ply:Nick(), tostring(k), txt)
								SetConclusion(ply:Nick(), k, "\""..txt.."\"")
							else
								RunConsoleCommand("ulx", "aslayid", (reported and report.attacker) or (not reported and report.victim), tostring(k), txt)
								SetConclusion((reported and report.attacker_nick) or (not reported and report.victim_nick), k, "\""..txt.."\"")
							end
						end)
					end):SetImage("icon16/page_edit.png")
				end
			end
			AddSlayPlayer(true)
			AddSlayPlayer(false)
		end
		menuPanel:AddOption("Slay the reported player now", function()
			if IsValid(attacker) then
				RunConsoleCommand("ulx", "slay", attacker:Nick())
			else
				Derma_Message("The reported player isn't valid! (disconnected?)", "Error", "OK")
			end
		end):SetImage("icon16/lightning.png")
		local slaynr_pnl = vgui.Create("DMenuOption", menuPanel)
		local slaynr = DermaMenu(menuPanel)
		slaynr:SetVisible(false)
		slaynr_pnl:SetSubMenu(slaynr)
		slaynr_pnl:SetText("Remove slays of")
		slaynr_pnl:SetImage("icon16/cancel.png")
		menuPanel:AddPanel(slaynr_pnl)
		slaynr:AddOption("The reported player", function()
			if IsValid(attacker) then
				RunConsoleCommand("ulx", "aslay", attacker:Nick(), "0")
			else
				RunConsoleCommand("ulx", "aslayid", report.attacker, "0")
			end
		end):SetImage("icon16/user_delete.png")
		slaynr:AddOption("The victim", function()
			if IsValid(victim) then
				RunConsoleCommand("ulx", "aslay", victim:Nick(), "0")
			else
				RunConsoleCommand("ulx", "aslayid", report.victim, "0")
			end
		end):SetImage("icon16/user.png")
	end
	menuPanel:Open() 
end


local PANEL = {}

function PANEL:Init()
	self:SetMultiSelect(false)
	self:AddColumn("ID"):SetFixedWidth(34)
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
			local slays = v.AutoslaysLeft or 0
			if tonumber(slays) <= 0 then
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
	if report.chat_open then
		str = str.." (in chat)"
	end
	return str
end

function PANEL:UpdateReport(index)
	local report = self.ReportsTable[index]
	if not report then return end
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
					if report.chat_open then
						self.Columns[6]:SetTextColor(Color(100 + math.abs(math.sin(CurTime()) * 155), 0, 0))
					else
						self.Columns[6]:SetTextColor(colors[self.status] or color_white)
					end
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
		if report.conclusion then
			local selected = Damagelog.SelectedReport
			if selected and selected.index == report.index and selected.previous == report.previous then
				self.Conclusion:SetText(report.conclusion)
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
		if Damagelog.SelectedReport then
			local report = Damagelog.SelectedReport
			local conclusion = report.conclusion
			if conclusion then
				self.Conclusion:SetText(conclusion)
			else
				self.Conclusion:SetText("No conclusion for the selected report.")
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
		self.Conclusion:SetText("No conclusion for the selected report.")
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
	if Damagelog.CurrentReports and Damagelog.CurrentReports:IsValid() then
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
		if Damagelog.PreviousReports and Damagelog.PreviousReports:IsValid() then
			Damagelog.PreviousReports:UpdateReport(index)
		end
	else
		Damagelog.Reports.Current[index] = updated
		if Damagelog.CurrentReports and Damagelog.CurrentReports:IsValid() then
			Damagelog.CurrentReports:UpdateReport(index)
		end
	end
	if Damagelog.SelectedReport then
		if Damagelog.SelectedReport.index == index and ((not Damagelog.SelectedReport.previous and not previous) or Damagelog.SelectedReport.previous == previous) then
			Damagelog.SelectedReport = updated
		end
	end
	if Damagelog.CurrentReports and Damagelog.CurrentReports:IsValid() then
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
	if Damagelog.CurrentReports and Damagelog.CurrentReports:IsValid() then
		Damagelog.CurrentReports:UpdateAllReports()
	end	
	if Damagelog.PreviousReports and Damagelog.PreviousReports:IsValid() then
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
			self:SetDisabled(not Damagelog.SelectedReport)
		end
		TakeActionB.DoClick = function(self)
			TakeAction()
		end
	
		local SetState = vgui.Create("DButton", Background)
		SetState:SetText("Set Status")
		SetState:SetPos(510, 4)
		SetState:SetSize(125, 18)
		SetState.Think = function(self)
			self:SetDisabled(not Damagelog.SelectedReport)
		end
		SetState.DoClick = function()
			local menu = DermaMenu()
			local attacker = player.GetBySteamID(Damagelog.SelectedReport.attacker)
			if not IsValid(attacker) and (Damagelog.SelectedReport.status == RDM_MANAGER_WAITING_FOR_ATTACKER or Damagelog.SelectedReport.status == RDM_MANAGER_WAITING_FOR_VICTIM) then
				DrawStatusMenuOption(RDM_MANAGER_PROGRESS, menu)
			end
			if Damagelog.SelectedReport.status == RDM_MANAGER_WAITING then
				DrawStatusMenuOption(RDM_MANAGER_PROGRESS, menu)
			end
			if Damagelog.SelectedReport.status == RDM_MANAGER_PROGRESS then
				if IsValid(attacker) then
					DrawStatusMenuOption(RDM_MANAGER_WAITING, menu)
				end
				DrawStatusMenuOption(RDM_MANAGER_FINISHED, menu)
			end
			if Damagelog.SelectedReport.status == RDM_MANAGER_FINISHED then
				DrawStatusMenuOption(RDM_MANAGER_PROGRESS, menu)
			end
			menu:Open()
		end
		
		Manager:AddItem(Background)
		
		local VictimInfos = vgui.Create("DPanel")
		VictimInfos:SetHeight(110)
		VictimInfos.Paint = function(panel, w, h)
			local bar_height = 27
			surface.SetDrawColor(30, 200, 30)
			surface.DrawRect(0, 0, (w/2), bar_height)
			draw.SimpleText("Victim's report", "DL_RDM_Manager", w/4, bar_height/2, Color(0,0,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			surface.SetDrawColor(220, 30, 30)
			surface.DrawRect((w/2)+1, 0, (w/2), bar_height)
			draw.SimpleText("Reported player's response", "DL_RDM_Manager", (w/2) + 1 + (w/4), bar_height/2, Color(0,0,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			surface.SetDrawColor(0, 0, 0)
			surface.DrawOutlinedRect(0, 0, w, h)
			surface.DrawLine(w/2, 0, w/2, h)
			surface.DrawLine(0, 27, w, bar_height)
			if panel.DisableR then
				surface.SetDrawColor(Color(0, 0, 0, 240))
				surface.DrawRect((w/2)+1, 0, (w/2), h)
			end
		end
		
		local VictimMessage = vgui.Create("DTextEntry", VictimInfos);
		VictimMessage:SetMultiline(true);
		VictimMessage:SetKeyboardInputEnabled(false);
		VictimMessage:SetPos(1, 27)
		VictimMessage:SetSize(319, 82)
		
		local KillerMessage = vgui.Create("DTextEntry", VictimInfos);
		KillerMessage:SetMultiline(true);
		KillerMessage:SetKeyboardInputEnabled(false);
		KillerMessage:SetPos(319, 27)
		KillerMessage:SetSize(319, 82)
		KillerMessage.PaintOver = function(self, w, h)
			if self.DisableR then
				surface.SetDrawColor(Color(0, 0, 0, 240))
				surface.DrawRect(0, 0, w, h)
				surface.SetFont("DL_ResponseDisabled")
				local text = "Chat opened, player's response disabled"
				local wt, ht = surface.GetTextSize(text)
				wt = wt
				surface.SetTextColor(color_white)
				surface.SetTextPos(w/2 - (wt-14)/2, h/3 - ht/2 + 10)
				surface.DrawText(text)
				surface.SetMaterial(Material("icon16/exclamation.png"))
				surface.SetDrawColor(color_white)
				surface.DrawTexturedRect(w/2 - wt/2 - 14, h/3 - ht/2 + 10, 16, 16)
			end
		end
		
		self.CurrentReports:SetOuputs(VictimMessage, KillerMessage)
		self.PreviousReports:SetOuputs(VictimMessage, KillerMessage)

		Manager:AddItem(VictimInfos)
		
		local VictimLogs
		local VictimLogsForm
		
		local Conclusion = vgui.Create("DPanel")
		surface.SetFont("DL_Conclusion")
		local cx,cy = surface.GetTextSize("Conclusion :")
		local cm = 5
		Conclusion.PaintOver = function(panel, w, h)
			if not panel.t1 then return end
			surface.SetDrawColor(color_black)
			surface.DrawLine(0, 0, w-1, 0)
			surface.DrawLine(w-1, 0, w-1, h-1)
			surface.DrawLine(w-1, h-1, 0, h-1)
			surface.DrawLine(0, h-1, 0, 0)
			surface.SetFont("DL_Conclusion")
			surface.SetTextPos(cm, panel.t2 and (h/3 - cy/2) or (h/2 - cy/2))
			surface.SetTextColor(Color(0, 108, 155))
			surface.DrawText("Conclusion : ")
			surface.SetFont("DL_ConclusionText")
			surface.SetTextColor(color_black)
			local tx1, ty1 = surface.GetTextSize(panel.t1)
			surface.SetTextPos(cx + 2*cm, panel.t2 and (h/3 - ty1/2) or h/2 - ty1/2)
			surface.DrawText(panel.t1)
			if panel.t2 then
				local tx2, ty2 = surface.GetTextSize(panel.t2)
				surface.SetTextPos(cm, 2*h/3 - ty2/2)
				surface.DrawText(panel.t2)
			end
		end
		Conclusion.SetText = function(pnl, t)
			pnl.Text = t
			local t1, t2 = AdjustText(t, "DL_ConclusionText", pnl:GetWide() - cx - cm*3)
			pnl.t1 = t1
			pnl.t2 = nil
			if t2 then
				pnl.t2 = t2
				pnl:SetHeight(45)
				KillerMessage:SetHeight(97)
				VictimMessage:SetHeight(97)
				VictimInfos:SetHeight(125)
				if VictimLogs then
					VictimLogs:SetHeight(205)
				end
			else
				pnl:SetHeight(30)
				KillerMessage:SetHeight(82)
				VictimMessage:SetHeight(82)
				VictimInfos:SetHeight(110)
				if VictimLogs then
					VictimLogs:SetHeight(230)
				end
			end
			if VictimLogsForm then
				VictimLogsForm:PerformLayout()
			end
			Manager:PerformLayout()
		end
		Conclusion.SetDefaultText = function(pnl)
			pnl:SetText("No selected report.")
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
		VictimLogsForm:SetName("Logs before victim's death")
	
		VictimLogs = vgui.Create("DListView")
		VictimLogs:AddColumn("Time"):SetFixedWidth(40)
		VictimLogs:AddColumn("Type"):SetFixedWidth(40)
		VictimLogs:AddColumn("Event"):SetFixedWidth(539)
		VictimLogs:SetHeight(230)
		
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
			if selected and selected.logs then
				Damagelog:SetListViewTable(VictimLogs, selected.logs, false)
			end
		end
		
		Damagelog.DisableResponse = function(disable)
			VictimInfos.DisableR = disable
			KillerMessage.DisableR = disable
		end
		
		VictimLogsForm:AddItem(VictimLogs)
	
		Manager:AddItem(VictimLogsForm)
		
		self.Tabs:AddSheet("RDM Manager", Manager, "icon16/magnifier.png", false, false)	
		
		Conclusion:SetDefaultText()
		self.CurrentReports:UpdateAllReports()
		self.PreviousReports:UpdateAllReports()
	end
end

