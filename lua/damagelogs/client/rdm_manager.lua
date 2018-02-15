Damagelog.Reports = Damagelog.Reports or {
	Current = {},
	Previous = {}
}
local function AAText(text, font, x, y, color, align)
	draw.SimpleText(text, font, x + 1, y + 1, Color(0, 0, 0, math.min(color.a, 120)), align)
	draw.SimpleText(text, font, x + 2, y + 2, Color(0, 0, 0, math.min(color.a, 50)), align)
	draw.SimpleText(text, font, x, y, color, align)
end

surface.CreateFont("RDM_Manager_Player", {
	font = "DermaLarge",
	size = 17
})

surface.CreateFont("RDM_Manager_DNA", {
	font = "DermaLarge",
	size = 14
})

Damagelog.ReportsQueue = Damagelog.ReportsQueue or {}
local ReportFrame

local function BuildReportFrame(report)

	if IsValid(ReportFrame) and report then
		for k,v in pairs(Damagelog.ReportsQueue) do
			if v.index == report.index and v.previous == report.previous then return end
		end
		ReportFrame:AddReport(report)
	else
		local found = false

		for k, v in pairs(Damagelog.ReportsQueue) do
			if not v.finished then
				found = true
				break
			end
		end


			if not found then return end

		net.Start("DL_Answering")
		net.SendToServer()
		ReportFrame = vgui.Create("DFrame")
		ReportFrame:SetDeleteOnClose(true)
		ReportFrame:SetTitle(TTTLogTranslate(GetDMGLogLang, "BeenReported"))
		ReportFrame:ShowCloseButton(false)
		ReportFrame:SetSize(610, 345)
		ReportFrame:Center()
		local ColumnSheet = vgui.Create("DColumnSheet", ReportFrame)
		ColumnSheet:StretchToParent(4, 28, 4, 4)
		ColumnSheet.Navigation:SetWidth(150)

		ReportFrame.AddReport = function(ReportFrame, report)

			local current = not report.previous
			local PanelList = vgui.Create("DPanelList")
			PanelList:SetPadding(3)
			PanelList:SetSpacing(2)

			PanelList.Paint = function(self, w, h)
				draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50, 255))
			end

			local Info = vgui.Create("Damagelog_InfoLabel")
			local txt = ""
			local nick = report.adminReport and TTTLogTranslate(GetDMGLogLang, "AnAdministrator") or report.victim_nick
			if current then
				txt = string.format(TTTLogTranslate(GetDMGLogLang, "HasReportedCurrentRound"), nick, (report.round or "?"))
			else
				txt = string.format(TTTLogTranslate(GetDMGLogLang, "HasReportedPreviousMap"), nick)
			end
			Info:SetText(txt)
			Info:SetInfoColor("blue")
			PanelList:AddItem(Info)
			local MessageEntry = vgui.Create("DTextEntry", BuildReportFrame)
			MessageEntry:SetMultiline(true)
			MessageEntry:SetHeight(100)
			MessageEntry:SetText(report.message or "")
			MessageEntry:SetEnabled(false)
			MessageEntry:SetEditable(false)
			PanelList:AddItem(MessageEntry)
			local TextEntry = vgui.Create("DTextEntry")
			TextEntry:SetMultiline(true)
			TextEntry:SetHeight(150)
			PanelList:AddItem(TextEntry)
			local Button = vgui.Create("DButton")
			Button:SetText(TTTLogTranslate(GetDMGLogLang, "Send"))

			Button.DoClick = function()
				local text = string.Trim(TextEntry:GetValue())
				local size = #text:gsub("[^%g\128-\191\208-\210 ]+", ""):gsub("%s+", " ")

				if size < 10 then
					Info:SetText(TTTLogTranslate(GetDMGLogLang, "MinCharacters"))
					Info:SetInfoColor("red")

					if timer.Exists("TimerRespond") then
						timer.Remove("TimerRespond")
					end

					timer.Create("TimerRespond", 5, 1, function()
						if IsValid(Info) then
							Info:SetText(report.victim_nick .. " " .. TTTLogTranslate(GetDMGLogLang, "ReportedYou") .. (current and (" " .. TTTLogTranslate(GetDMGLogLang, "AfterRound") .. " " .. (report.round or "?")) or " " .. TTTLogTranslate(GetDMGLogLang, "PreviousMap")))
							Info:SetInfoColor("blue")
						end
					end)
				else
					report.finished = true
					Button:SetEnabled(false)
					Info:SetText(TTTLogTranslate(GetDMGLogLang, "ResponseSubmitted"))
					Info:SetInfoColor("orange")
					net.Start("DL_SendAnswer")
					net.WriteUInt(current and 1 or 0, 1)
					net.WriteString(text)
					net.WriteUInt(report.index, 16)
					net.SendToServer()

					for k,v in pairs(Damagelog.ReportsQueue) do
						if not v.finished then
							for _, sheet in pairs(ColumnSheet.Items) do
								if sheet.Button != ColumnSheet:GetActiveButton() then
									ColumnSheet:SetActiveButton(sheet.Button)
									break
								end
							end
							return
						end
					end

					ReportFrame:Close()
					ReportFrame:Remove()
					Damagelog:Notify(DAMAGELOG_NOTIFY_INFO, TTTLogTranslate(GetDMGLogLang, "ResponseSubmitted"), 4, "")
				end
			end

			PanelList:AddItem(Button)
			local title = report.adminReport and string.format(TTTLogTranslate(GetDMGLogLang, "AdminReportID"), report.index) or report.victim_nick
			ColumnSheet:AddSheet(title, PanelList, "icon16/report_user.png")
			PanelList:SetSize(430, 310)
		end

		for _, report in ipairs(Damagelog.ReportsQueue) do
			if report.finished then continue end
			ReportFrame:AddReport(report)
		end

		ReportFrame:PerformLayout()
		ReportFrame:MakePopup()
	end
end

local PANEL = {}

function PANEL:Init()
	self.ava = vgui.Create("AvatarImage", self)
	self.ava:SetSize(23, 23)
	self.ava:SetPos(4, 4)
end

function PANEL:SetPlayer(ply)
	self.ply = ply
	self:SetAvatarPlayer(ply)
end

function PANEL:SetNick(nick)
	self.ply = nil
	self.nick = nick
end

function PANEL:SetAvatarPlayer(ply)
	self.ava:SetPlayer(ply)
end

function PANEL:Paint(w, h)
	local col = {
		r = 40,
		g = 40,
		b = 40
	}

	local col_selected = {
		r = 204,
		g = 204,
		b = 51
	}

	if not self:CheckValidity() then return end

	if not self.Selected then
		draw.RoundedBox(0, 0, 0, w, h, Color(13, 14, 15, 255))
		draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(col.r + 40, col.g + 40, col.b + 40, 255))
		draw.RoundedBox(0, 2, 2, w - 4, h - 4, Color(col.r, col.g, col.b, 255))
	else
		draw.RoundedBox(0, 0, 0, w, h, Color(13, 14, 15, 255))
		draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(col_selected.r + 40, col_selected.g + 40, col_selected.b + 40, 255))
		draw.RoundedBox(0, 2, 2, w - 4, h - 4, Color(col_selected.r, col_selected.g, col_selected.b, 255))
	end

	local c = color_white

	if not self.Selected and self.is_killer then
		c = Color(255, 100, 100)
	end

	AAText((self.is_killer and "(" .. TTTLogTranslate(GetDMGLogLang, "Killer") .. ") " or "") .. (self.nick or self.ply:Nick()), "RDM_Manager_Player", 35, 7, c, TEXT_ALIGN_LEFT)
end

function PANEL:Think()
	if self.nick then return end
	self:CheckValidity()
end

function PANEL:CheckValidity()
	if self.nick then return true end
	if not IsValid(self.ply) then
		self:Remove()
		return false
	end
	return true
end

function PANEL:OnMousePressed(mc)
	if not self.Selected then
		self.Selected = true
		if self.OnSelected then
			self:OnSelected()
		end
	end
end

vgui.Register("Damagelog_Player", PANEL, "DPanel")

function Damagelog:ReportWindow(found, deathLogs, previousReports, currentReports, dnas)

	local isAdmin = LocalPlayer():CanUseRDMManager()

	local w, h = 610, 290
	local Frame = vgui.Create("DFrame")
	Frame:SetTitle("RDM Manager - " .. TTTLogTranslate(GetDMGLogLang, "ReportPlayer"))
	Frame:SetSize(w, h)
	Frame:Center()
	Frame:MakePopup()
	local Tabs = vgui.Create("DPropertySheet", Frame)
	Tabs:StretchToParent(4, 25, 4, 4)
	local ReportPanel = vgui.Create("DPanel")
	local InfoLabel = vgui.Create("Damagelog_InfoLabel", ReportPanel)
	InfoLabel:SetText(TTTLogTranslate(GetDMGLogLang, "FalseReports"))
	InfoLabel:SetInfoColor("red")
	InfoLabel:SetPos(4, 2)
	InfoLabel:SetSize(578, 24)
	local UserList = vgui.Create("DPanelList", ReportPanel)
	UserList:SetPos(5, 30)
	UserList:SetSize(200, 190)

	UserList.Paint = function(self, w, h)
		surface.SetDrawColor(Color(52, 73, 94))
		surface.DrawRect(0, 0, w, h)
	end

	UserList:EnableVerticalScrollbar(true)
	local cur_selected
	local DNAMessage

	local function UpdateDNAMessage(ply)

		if not IsValid(ply) then return end

		local msg, colour
		if dnas[ply] == true then
			msg = string.format(TTTLogTranslate(GetDMGLogLang, "ReportHadDNA"), ply:Nick())
			colour = Color(20, 130, 20)
		elseif dnas[ply] == false then
			msg = string.format(TTTLogTranslate(GetDMGLogLang, "ReportNoDNA"), ply:Nick())
			colour = color_black
		else
			msg = string.format(TTTLogTranslate(GetDMGLogLang, "ReportNoDNAInfo"), ply:Nick())
			colour = color_black
		end

		DNAMessage:SetTextColor(colour)
		DNAMessage:SetText(msg)
		DNAMessage:SizeToContents()
		surface.SetFont("RDM_Manager_DNA")
		local h = select(2, surface.GetTextSize(msg))
		DNAMessage:SetPos(35, DNAMessage:GetParent():GetTall()/2 - h/2)
	end

	UserList.AddPlayer = function(pnl, pl, is_killer, killer_valid)
		if not IsValid(pl) then return end
		local ply = vgui.Create("Damagelog_Player")
		ply:SetSize(0, 30)
		ply:SetPlayer(pl)
		ply.is_killer = is_killer
		ply:SetAvatarPlayer(pl)
		ply.OnSelected = function(ply)
			for k,v in pairs(pnl:GetItems()) do
				if v.Selected and v != ply then
					v.Selected = false
				end
			end
			cur_selected = ply
			UpdateDNAMessage(cur_selected.ply)
		end
		pnl:AddItem(ply)

		if is_killer or not cur_selected then
			cur_selected = ply
			ply.Selected = true
		end
	end

	local killer = LocalPlayer():GetNWEntity("DL_Killer")

	if IsValid(killer) then
		UserList:AddPlayer(killer, true)
	end

	for k, v in ipairs(player.GetHumans()) do
		if v == killer or  v == LocalPlayer() then continue end
		UserList:AddPlayer(v, false)
	end

	local Label = vgui.Create("DLabel", ReportPanel)
	Label:SetTextColor(color_black)
	Label:SetText(TTTLogTranslate(GetDMGLogLang, "ExplainSituation"))
	Label:SizeToContents()
	Label:SetPos(210, 30)

	local Entry = vgui.Create("DTextEntry", ReportPanel)
	Entry:SetPos(210, 47)
	Entry:SetSize(370, 85)
	Entry:SetMultiline(true)

	local DNAPanel = vgui.Create("DPanel", ReportPanel)
	DNAPanel:SetPos(210, 138)
	DNAPanel:SetSize(370, 25)
	DNAPanel.Paint = function(DNAPanel, w, h)
		surface.SetDrawColor(color_black)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(Color(225, 225, 225))
		surface.DrawRect(1, 1, w-2, h-2)
	end

	local DNAIcon = vgui.Create("DImage", DNAPanel)
	DNAIcon:SetImage("icon16/chart_line.png")
	DNAIcon:SetSize(16, 16)
	DNAIcon:SetPos(10, 0)
	DNAIcon:CenterVertical()

	DNAMessage = vgui.Create("DLabel", DNAPanel)
	DNAMessage:SetFont("RDM_Manager_DNA")
	if cur_selected and IsValid(cur_selected.ply) then
		UpdateDNAMessage(cur_selected.ply)
	end

	local Type = vgui.Create("DComboBox", ReportPanel)
	Type:SetPos(210, 168)
	Type:SetSize(370, 20)

	Type:AddChoice(TTTLogTranslate(GetDMGLogLang, "StandardReport"), DAMAGELOG_REPORT_STANDARD, true)
	Type:AddChoice(TTTLogTranslate(GetDMGLogLang, "StandardAdminReport"), DAMAGELOG_REPORT_ADMIN)
	Type:AddChoice(TTTLogTranslate(GetDMGLogLang, "AdvancedAdminReportForce"), DAMAGELOG_REPORT_FORCE)
	Type:AddChoice(TTTLogTranslate(GetDMGLogLang, "AdvancedAdminReportChat"), DAMAGELOG_REPORT_CHAT)

	Type.OnSelect = function(Type, data, text)
		if data == DAMAGELOG_REPORT_CHAT then
			Entry:SetText("")
			Entry:SetDisabled(true)
		elseif Entry:GetDisabled() then
			Entry:SetDisabled(false)
		end
	end

	if not isAdmin then
		Type:SetDisabled(true)
	end

	local Submit = vgui.Create("DButton", ReportPanel)
	Submit:SetText(TTTLogTranslate(GetDMGLogLang, "Submit"))
	Submit:SetPos(210, 195)
	Submit:SetSize(370, 25)

	Submit.Think = function(self)
		local characters = #Entry:GetText():gsub("[^%g\128-\191\208-\210 ]+", ""):gsub("%s+", " ")
		local disable = characters < 10 or not cur_selected

		if disable and select(2, Type:GetSelected()) != DAMAGELOG_REPORT_CHAT then
			Submit:SetEnabled(false)
			Submit:SetText(TTTLogTranslate(GetDMGLogLang, "NotEnoughCharacters"))
		else
			Submit:SetEnabled(true)
			if found then
				Submit:SetText(TTTLogTranslate(GetDMGLogLang, "Submit"))
			elseif not found then
				Submit:SetText(TTTLogTranslate(GetDMGLogLang, "SubmitEvenWithNoStaff"))
			end
		end
	end

	Submit.DoClick = function(self)
		if not IsValid(cur_selected) then return end
		local ply = cur_selected.ply
		if not IsValid(ply) then return end
		net.Start("DL_ReportPlayer")
		net.WriteEntity(ply)
		net.WriteString(Entry:GetText())
		if not isAdmin then
			net.WriteUInt(DAMAGELOG_REPORT_STANDARD, 3)
		else
			local reportType = select(2, Type:GetSelected())
			net.WriteUInt(reportType, 3)
		end
		net.SendToServer()
		Frame:Close()
		Frame:Remove()
	end

	Tabs:AddSheet(TTTLogTranslate(GetDMGLogLang, "ReportPlayer"), ReportPanel, "icon16/report_user.png")

	local MReportsPanel = vgui.Create("DPanel")
	Tabs:AddSheet(TTTLogTranslate(GetDMGLogLang, "ViewPreviousReports"), MReportsPanel, "icon16/page_find.png")

	local RoundsList = vgui.Create("DPanelList", MReportsPanel)
	RoundsList.Paint = function(RoundsList, w, h)
		surface.SetDrawColor(Color(52, 73, 94))
		surface.DrawRect(0, 0, w, h)
	end
	self.ReportsInfo = vgui.Create("DPanel", MReportsPanel)

	local VictimInfos = vgui.Create("DPanel", self.ReportsInfo)
	VictimInfos:SetHeight(100)

	VictimInfos.Paint = function(panel, w, h)
		local bar_height = 27
		surface.SetDrawColor(30, 200, 30)
		surface.DrawRect(0, 0, (w / 2), bar_height)
		draw.SimpleText(TTTLogTranslate(GetDMGLogLang, "YourReport"), "DL_RDM_Manager", w / 4, bar_height / 2, Color(0, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		surface.SetDrawColor(220, 30, 30)
		surface.DrawRect((w / 2) + 1, 0, (w / 2), bar_height)
		draw.SimpleText(TTTLogTranslate(GetDMGLogLang, "PlayerResponse"), "DL_RDM_Manager", (w / 2) + 1 + (w / 4), bar_height / 2, Color(0, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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
	VictimMessage:SetVerticalScrollbarEnabled(true)

	local KillerMessage = vgui.Create("DTextEntry", VictimInfos)
	KillerMessage:SetMultiline(true)
	KillerMessage:SetKeyboardInputEnabled(false)
	KillerMessage:SetVerticalScrollbarEnabled(true)

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

	local chat_status = vgui.Create("DLabel", self.ReportsInfo)
	local text = TTTLogTranslate(GetDMGLogLang, "ChatOpenedShort")
	chat_status:SetText(text)
	surface.SetFont("DL_RDM_Manager")
	local textWidth = select(1, surface.GetTextSize(text))
	chat_status:SetVisible(false)
	chat_status:SetFont("DL_RDM_Manager")
	chat_status:SizeToContents()
	chat_status:SetTextColor(Color(30, 30, 230))

	local status = vgui.Create("DLabel", self.ReportsInfo)
	local statusText = TTTLogTranslate(GetDMGLogLang, "Status") .. ":"
	status:SetText(statusText)
	status:SetTextColor(color_black)
	status:SetPos(10, 10)
	status:SetFont("DL_RDM_Manager")
	status:SizeToContents()

	surface.SetFont("DL_RDM_Manager")
	local statusW, statusH = surface.GetTextSize(statusText)
	local icon = vgui.Create("DImage", self.ReportsInfo)
	icon:SetSize(16, 16)
	icon:SetImage("icon16/exclamation.png")
	icon:SetPos(13 + statusW, 10)

	local curStatus = vgui.Create("DLabel", self.ReportsInfo)
	curStatus:SetTextColor(color_black)
	curStatus:SetPos(32 + statusW, 10)
	curStatus:SetFont("DL_RDM_Manager")
	curStatus:SetText("("..TTTLogTranslate(GetDMGLogLang, "NoLoadedReport")..")")
	curStatus:SizeToContents()

	local conclusionPanel = vgui.Create("DPanel", self.ReportsInfo)
	conclusionPanel:SetPos(10, VictimInfos:GetTall() + 40)
	conclusionPanel.Paint = function(conclusionPanel, w, h)
		surface.SetDrawColor(color_black)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(Color(225, 225, 225))
		surface.DrawRect(1, 1, w-2, h-2)
	end

	local conclusion = vgui.Create("DLabel", conclusionPanel)
	conclusion:SetTextColor(Color(0, 108, 155))
	conclusion:SetFont("DL_RDM_Manager")
	conclusion:SetText(TTTLogTranslate(GetDMGLogLang, "Conclusion") .. " :")
	conclusion:SizeToContents()
	conclusion:SetPos(5, 5)

	local conclusionText =  vgui.Create("DLabel", conclusionPanel)
	conclusionText:SetTextColor(color_black)
	conclusionText:SetFont("DL_RDM_Manager")
	conclusionText:SetText("("..TTTLogTranslate(GetDMGLogLang, "NoLoadedReport")..")")
	conclusionText:SizeToContents()
	conclusionText:SetPos(5, 25)

	local cancel = vgui.Create("DButton", self.ReportsInfo)
	cancel:SetText(TTTLogTranslate(GetDMGLogLang, "CancelReport"))
	cancel:SetDisabled(true)

	self.ReportsInfo.ViewLogs = function(panel, tbl)
		VictimMessage:SetText(tbl.message)
		KillerMessage:SetText(tbl.response or TTTLogTranslate(GetDMGLogLang, "NoResponseYet"))
		curStatus:SetText(RDM_MANAGER_STATUS[tbl.status])
		if tbl.conclusion then
			conclusionText:SetText(tbl.conclusion)
		else
			conclusionText:SetText(TTTLogTranslate(GetDMGLogLang, "NoConclusion"))
		end
		conclusionText:SizeToContents()
		icon:SetImage(RDM_MANAGER_ICONS[tbl.status])
		if tbl.canceled then
			cancel:SetDisabled(true)
			cancel:SetText(TTTLogTranslate(GetDMGLogLang, "ReportCanceled"))
		else
			cancel:SetText(TTTLogTranslate(GetDMGLogLang, "CancelReport"))
			cancel:SetDisabled(false)
			cancel.DoClick = function(cancel)
				net.Start("DL_GetForgive")
				net.WriteUInt(1, 1)
				net.WriteUInt(tbl.previous and 1 or 0, 1)
				net.WriteUInt(tbl.index, 16)
				net.SendToServer()
			end
		end
		chat_status:SetVisible(tbl.chat_open or tbl.chat_opened)
	end

	MReportsPanel.ApplySchemeSettings = function()
		local roundsW = MReportsPanel:GetWide() / 3
		RoundsList:SetSize(roundsW, MReportsPanel:GetTall())
		RoundsList:SetPos(0, 0)
		self.ReportsInfo:SetSize(MReportsPanel:GetWide() - roundsW - 2, MReportsPanel:GetTall())
		self.ReportsInfo:SetPos(roundsW + 2, 0)
		VictimInfos:SetWidth(self.ReportsInfo:GetWide() - 20)
		local boxW = VictimInfos:GetWide() / 2
		KillerMessage:SetSize(boxW, VictimInfos:GetTall() - 27)
		VictimMessage:SetSize(boxW + 1, VictimInfos:GetTall() - 27)
		VictimMessage:SetPos(0, 27)
		KillerMessage:SetPos(boxW, 27)
		VictimInfos:SetPos(0, 35)
		VictimInfos:CenterHorizontal()
		conclusionPanel:SetSize(self.ReportsInfo:GetWide() - 20, 47)
		cancel:SetSize(self.ReportsInfo:GetWide() - 20, 25)
		cancel:SetPos(10, select(2, conclusionPanel:GetPos()) + conclusionPanel:GetTall() + 5)
		chat_status:SetPos(self.ReportsInfo:GetWide() - textWidth - 10, 10)
	end

	local buttons = {}

	local first = true

	if #previousReports > 0 then

		local form = vgui.Create("DForm")
		form.Paint = function() end
		form.SetExpanded = function() end
		form:SetName(TTTLogTranslate(GetDMGLogLang, "PreviousMapReports"))
		form:SetPadding(0)
		form:SetSpacing(0)
		for _,report in ipairs(previousReports) do
			local button = vgui.Create("Damagelog_Player")
			button.report = report
			button:SetHeight(30)
			button:SetNick(report.attackerName)
			for k,v in ipairs(player.GetHumans()) do
				if v:SteamID() == report.attackerID then
					button:SetAvatarPlayer(v)
					break
				end
			end
			local id = table.insert(buttons, button)
			button.OnSelected = function(button)
				self.ReportsInfo.ViewingPrevious = true
				self.ReportsInfo.CurrentIndex = button.report.index
				net.Start("DL_AskOwnReportInfo")
				net.WriteUInt(1, 1)
				net.WriteUInt(button.report.index, 16)
				net.SendToServer()
				for k,v in pairs(buttons) do
					if k != id then
						v.Selected = false
					end
				end
			end
			button.Selected = false
			form:AddItem(button)
		end
		RoundsList:AddItem(form)
		for k,v in pairs(form.Items) do
			v:DockPadding(0, 0, 0, 0)
		end

	end

	if table.Count(currentReports) > 0 then

		local order = {}
		for k,v in pairs(currentReports) do
			table.insert(order, k)
		end
		table.sort(order, function(a, b)
			return a > b
		end)

		for _, key in ipairs(order) do
			local round = currentReports[key]
			local roundForm = vgui.Create("DForm")
			roundForm.Paint = function() end
			roundForm.SetExpanded = function() end
			roundForm:SetName(TTTLogTranslate(GetDMGLogLang, "Round").." "..key)
			roundForm:SetPadding(0)
			roundForm:SetSpacing(0)
			for _,report in pairs(round) do
				local button = vgui.Create("Damagelog_Player")
				button.report = report
				button:SetHeight(30)
				button:SetNick(report.attackerName)
				for k,v in ipairs(player.GetHumans()) do
					if v:SteamID() == report.attackerID then
						button:SetAvatarPlayer(v)
						break
					end
				end
				local id = table.insert(buttons, button)
				button.OnSelected = function(button)
					self.ReportsInfo.ViewingPrevious = false
					self.ReportsInfo.CurrentIndex = button.report.index
					net.Start("DL_AskOwnReportInfo")
					net.WriteUInt(0, 1)
					net.WriteUInt(button.report.index, 16)
					net.SendToServer()
					for k,v in pairs(buttons) do
						if k != id then
							v.Selected = false
						end
					end
				end
				button.Selected = false
				if first then
					button:OnMousePressed()
					first = false
				end
				roundForm:AddItem(button)
			end
			for k,v in pairs(roundForm.Items) do
				v:DockPadding(0, 0, 0, 0)
			end
			roundForm:InvalidateLayout()
			roundForm:SizeToContents()
			RoundsList:AddItem(roundForm)
		end

	end

	if first and buttons[1] then
		buttons[1]:OnMousePressed()
	end

	if (Damagelog.User_rights[LocalPlayer():GetUserGroup()] or 2) >= 2 then
		local Logs = vgui.Create("DListView")
		Logs:AddColumn(TTTLogTranslate(GetDMGLogLang, "Time")):SetFixedWidth(40)
		Logs:AddColumn(TTTLogTranslate(GetDMGLogLang, "Type")):SetFixedWidth(40)
		Logs:AddColumn(TTTLogTranslate(GetDMGLogLang, "Event"))

		if deathLogs then
			self:SetListViewTable(Logs, deathLogs, false)
		else
			Logs:AddLine("", "", TTTLogTranslate(GetDMGLogLang, "Nothinghere"))
		end

		Tabs:AddSheet(TTTLogTranslate(GetDMGLogLang, "LogsBeforeDeath"), Logs, "icon16/application_view_list.png")
	end
end

net.Receive("DL_SendOwnReportInfo", function()
	local tbl = net.ReadTable()
	if not IsValid(Damagelog.ReportsInfo) then return end
	if tbl.previous and not Damagelog.ReportsInfo.ViewingPrevious then return end
	if tbl.index != Damagelog.ReportsInfo.CurrentIndex then return end
	Damagelog.ReportsInfo:ViewLogs(tbl)
end)

net.Receive("DL_AllowReport", function()
	local found = net.ReadBool()
	local got_deathLogs = net.ReadUInt(1) == 1
	local deathLogs = got_deathLogs and net.ReadTable() or false
	local previousReports = net.ReadTable()
	local currentReports = net.ReadTable()

	local dnas = {}
	local playerCount = net.ReadUInt(8)
	for i=1, playerCount do
		local ply = net.ReadEntity()
		dnas[ply] = net.ReadUInt(1) == 1
	end

	Damagelog:ReportWindow(found,deathLogs, previousReports, currentReports, dnas)
end)

net.Receive("DL_SendReport", function()
	local report = net.ReadTable()

	if IsValid(ReportFrame) then
		BuildReportFrame(report)
		Damagelog.ReportsQueue[#Damagelog.ReportsQueue + 1] = report
	else
		Damagelog.ReportsQueue[#Damagelog.ReportsQueue + 1] = report

		if not LocalPlayer().IsActive or not LocalPlayer():IsActive() then
			BuildReportFrame(report)
		end
	end
end)

net.Receive("DL_Death", function()
	if not IsValid(ReportFrame) then
		BuildReportFrame()
	end
end)

net.Receive("DL_SendForgive", function()
	local previous = net.ReadUInt(1) == 1
	local canceled = net.ReadUInt(1) == 1
	local index = net.ReadUInt(16)
	local nick = net.ReadString()
	local text = net.ReadString()
	local answer = vgui.Create("DFrame")
	answer:ShowCloseButton(false)
	answer:SetSize(400, 175)
	answer:SetTitle(TTTLogTranslate(GetDMGLogLang, "MessageFrom") .. " " .. nick .. " " .. TTTLogTranslate(GetDMGLogLang, "AboutYourReport"))
	answer:Center()
	answer:MakePopup()

	local bonus = 0

	if canceled then
		local InfoLabel = vgui.Create("Damagelog_InfoLabel", answer)
		InfoLabel:SetText(TTTLogTranslate(GetDMGLogLang, "AlreadyCanceled"))
		InfoLabel:SetInfoColor("blue")
		InfoLabel:SetPos(4, 30)
		InfoLabel:SetSize(answer:GetWide() - 8, 24)
		bonus = 28
	end

	answer:SetHeight(answer:GetTall() + bonus)

	local message = vgui.Create("DTextEntry", answer)
	message:SetSize(390, 100)
	message:SetPos(5, 30 + bonus)
	message:SetText(text)
	message:SetEditable(false)
	message:SetMultiline(true)

	if not canceled then
		local forgive = vgui.Create("DButton", answer)
		forgive:SetText(TTTLogTranslate(GetDMGLogLang, "Forgive"))
		forgive:SetPos(5, 135)
		forgive:SetSize(195, 30)

		forgive.DoClick = function(self)
			net.Start("DL_GetForgive")
			net.WriteUInt(1, 1)
			net.WriteUInt(previous and 1 or 0, 1)
			net.WriteUInt(index, 16)
			net.SendToServer()
			answer:Close()
		end
	end

	local nope = vgui.Create("DButton", answer)
	nope:SetText(canceled and TTTLogTranslate(GetDMGLogLang, "Close") or TTTLogTranslate(GetDMGLogLang, "KeepReport"))
	nope:SetPos(208, 135 + bonus)
	nope:SetSize(188, 30)

	nope.DoClick = function(self)
		if not canceled then
			net.Start("DL_GetForgive")
			net.WriteUInt(0, 1)
			net.WriteUInt(previous and 1 or 0, 1)
			net.WriteUInt(index, 16)
			net.SendToServer()
		end
		answer:Close()
	end
end)

net.Receive("DL_Answering_global", function(_len)
	if LocalPlayer().IsActive and not LocalPlayer():IsActive() then
		chat.AddText(Color(255, 62, 62), net.ReadString(), color_white, " " .. TTTLogTranslate(GetDMGLogLang, "IsAnswering"))
	end
end)

surface.CreateFont("DL_PendingNumber", {
	font = "DermaLarge",
	size = 25
})

surface.CreateFont("DL_PendingText", {
	font = "DermaLarge",
	size = 16
})

local m = 5
local showPending = GetConVar("ttt_dmglogs_showpending")
local syncEnt
hook.Add("HUDPaint", "DamagelogPendingReports", function()

	if not LocalPlayer():CanUseRDMManager() or LocalPlayer():IsActive() or not showPending:GetBool() then return end

	local alpha = #Damagelog.Notifications > 0 and 30 or 255

	if not IsValid(syncEnt) then
		syncEnt = Damagelog:GetSyncEnt()
		if not IsValid(syncEnt) then return end
	end

	local pendingReports = syncEnt:GetPendingReports()
	if pendingReports < 1 then return end
	pendingReports = tostring(pendingReports)

	local textTop = TTTLogTranslate(GetDMGLogLang, "PendingTop")
	local textBottom = TTTLogTranslate(GetDMGLogLang, "ReportsBottom")

	surface.SetFont("DL_PendingText")

	local topWidth, topHeight = surface.GetTextSize(textTop)
	local bottomWidth, bottomHeight = surface.GetTextSize(textBottom)
	local maxWidth = math.max(topWidth, bottomWidth)

	surface.SetFont("DL_PendingNumber")
	local numberWidth, numberHeight = surface.GetTextSize(pendingReports)

	local w, h = numberWidth + maxWidth + 3*m, numberHeight + 2*m

	local screenWidth, screenHeight = ScrW(), ScrH()
	local x, y = screenWidth - w, ScrH()*0.2 + h/2

	surface.SetDrawColor(Color(32, 32, 32, alpha))
	surface.DrawRect(x, y, w, h)

	surface.SetDrawColor(Color(51, 102, 153, alpha))
	surface.DrawRect(x + 1, y + 1, w, h - 2)

	surface.SetTextColor(Color(255, 255, 255, alpha))
	surface.SetTextPos(x + m, y + h/2 - numberHeight/2)
	surface.DrawText(pendingReports)

	surface.SetFont("DL_PendingText")

	surface.SetTextPos(x  + numberWidth + m + (w - numberWidth) / 2  - topWidth/2, y + h/3 - topHeight/2)
	surface.DrawText(textTop)

	surface.SetTextPos(x  + numberWidth + m + (w - numberWidth) / 2  - bottomWidth/2, y + 2*h/3 - bottomHeight/2)
	surface.DrawText(textBottom)

end)
