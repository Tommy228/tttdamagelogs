
Damagelog.Reports = Damagelog.Reports or {
	Current = {},
	Previous = {}
}

local function AAText(text, font, x, y, color, align)
	draw.SimpleText(text, font, x+1, y+1, Color(0,0,0,math.min(color.a,120)), align)
	draw.SimpleText(text, font, x+2, y+2, Color(0,0,0,math.min(color.a,50)), align)
	draw.SimpleText(text, font, x, y, color, align)
end

surface.CreateFont("RDM_Manager_Player", {
	font = "DermaLarge",
	size = 17
})

Damagelog.ReportsQueue = Damagelog.ReportsQueue or {}

local ReportFrame

local function BuildReportFrame(report)
	
	if ReportFrame and ReportFrame:IsValid() then
	
		if report then
			ReportFrame:AddReport(report)
		end
		
	else
	
		local found = false
		for k,v in pairs(Damagelog.ReportsQueue) do
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
		ReportFrame:SetTitle("You have been reported! Please answer all your reports.")
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
			Info:SetText(report.victim_nick.. " reported you"..(current and (" after the round "..(report.round or "?")) or " on the previous map "))
			Info:SetInfoColor("blue")
			PanelList:AddItem(Info)

			local MessageEntry = vgui.Create("DTextEntry", self)
			MessageEntry:SetMultiline(true)
			MessageEntry:SetHeight(100)
			MessageEntry:SetText(report.message or "")
			MessageEntry:SetDisabled(true)
			MessageEntry:SetEditable(false)
			PanelList:AddItem(MessageEntry)

			local TextEntry = vgui.Create("DTextEntry")
			TextEntry:SetMultiline(true)
			TextEntry:SetHeight(150)
			PanelList:AddItem(TextEntry)

			local Button = vgui.Create("DButton")
			Button:SetText("Send")
			Button.DoClick = function()
				local text = string.Trim(TextEntry:GetValue())
				local size = #text
				if size < 10 then
					Info:SetText("A minimum of 10 characters are required!");
					Info:SetInfoColor("red");
					if timer.Exists("TimerRespond") then
						timer.Destroy("TimerRespond")
					end
					timer.Create("TimerRespond", 5, 1, function()
						if Info and Info:IsValid() then
							Info:SetText(report.victim_nick.. " reported you"..(current and (" after the round "..(report.round or "?")) or " on the previous map "))
							Info:SetInfoColor("blue");
						end
					end)
				else
					report.finished = true
					Button:SetDisabled(true)
					Info:SetText("Your response has been submitted!")
					Info:SetInfoColor("orange")
					net.Start("DL_SendAnswer")
					net.WriteUInt(current and 1 or 0, 1)
					net.WriteString(text)
					net.WriteUInt(report.index, 16)
					net.SendToServer()
					for k,v in pairs(Damagelog.ReportsQueue) do
						if not v.finished then return end
					end
					ReportFrame:Close()
					ReportFrame:Remove()
					Damagelog:Notify(DAMAGELOG_NOTIFY_INFO, "Your response has been submitted!", 4, "")
				end
			end

			PanelList:AddItem(Button)

			ColumnSheet:AddSheet(report.victim_nick, PanelList, "icon16/report_user.png")
			
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

function Damagelog:ReportWindow(tbl)

	local w,h = 610, 290
	
	local Frame = vgui.Create("DFrame")
	Frame:SetTitle("RDM Manager - Reporting a player")
	Frame:SetSize(w,h)
	Frame:Center()

	local Tabs = vgui.Create("DPropertySheet", Frame)
	Tabs:StretchToParent(4, 25, 4, 4)
		
	local ReportPanel = vgui.Create("DPanel")
	
	local InfoLabel = vgui.Create("Damagelog_InfoLabel", ReportPanel);
	InfoLabel:SetText("False reports will get you punished")
	InfoLabel:SetInfoColor("red")
	InfoLabel:SetPos(4,2)
	InfoLabel:SetSize(578, 24)
	
	local UserList = vgui.Create("DPanelList", ReportPanel)
	UserList:SetPos(5, 30)
	UserList:SetSize(200, 190)
	UserList.Paint = function(self, w, h)
		surface.SetDrawColor(Color(52, 73, 94))
		surface.DrawRect(0,0,w,h)
	end
	UserList:EnableVerticalScrollbar(true)
	local cur_selected
	UserList.AddPlayer = function(pnl, pl, is_killer, killer_valid)  
		if not IsValid(pl) then return end
		local ply = vgui.Create("DPanel")
		ply:SetSize(0, 30) 
		local alpha = 255
		local col = { r = 40, g = 40, b = 40 }
		local col_selected = { r = 204, g = 204, b = 51 }
		ply.pl = pl
		local function checkValidity()
			if not IsValid(pl) then
				ply:Remove()
				return false
			end	
			return true
		end
		ply.Think = function(self)
			checkValidity()
		end
		ply.Paint = function(self, w, h)
			if not checkValidity() then return end
			if cur_selected != ply then
				draw.RoundedBox(0, 0, 0, w, h, Color(13, 14, 15, alpha))
				draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(col.r + 40, col.g + 40, col.b + 40, alpha))
				draw.RoundedBox(0, 2, 2, w - 4, h - 4, Color(col.r, col.g, col.b, alpha))
			else
				draw.RoundedBox(0, 0, 0, w, h, Color(13, 14, 15, alpha))
				draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(col_selected.r + 40, col_selected.g + 40, col_selected.b + 40, alpha))
				draw.RoundedBox(0, 2, 2, w - 4, h - 4, Color(col_selected.r, col_selected.g, col_selected.b, alpha))
			end
			local c = color_white
			if cur_selected != self and is_killer then
				c = Color(255, 100, 100)
			end
			AAText((is_killer and "(killer) " or "")..pl:Nick(), "RDM_Manager_Player", 35, 7, c, TEXT_ALIGN_LEFT)
		end
		ply.OnMousePressed = function(pnl, mc)
			if mc == MOUSE_LEFT and cur_selected != ply then
				cur_selected = ply  
			end
		end
		local ava = vgui.Create("AvatarImage", ply)
		ava:SetSize(23, 23)
		ava:SetPlayer(pl, 32)
		ava:SetPos(4, 4)
		pnl:AddItem(ply)
		if is_killer or not cur_selected then
			cur_selected = ply
		end
	end
	local killer = LocalPlayer():GetNWEntity("DL_Killer")
	if IsValid(killer) then
		UserList:AddPlayer(killer, true)
	end
	for k,v in pairs(player.GetAll()) do
		if v == killer or v == LocalPlayer() then continue end
		UserList:AddPlayer(v, false)
	end
	
	local Label = vgui.Create("DLabel", ReportPanel)
	Label:SetTextColor(color_black)
	Label:SetText("Explain the situation. At least 10 characters are required.")
	Label:SizeToContents()
	Label:SetPos(210, 30)
	
	local Entry = vgui.Create("DTextEntry", ReportPanel)
	Entry:SetPos(210, 47)
	Entry:SetSize(370, 145)
	Entry:SetMultiline(true)
	
	local Submit = vgui.Create("DButton", ReportPanel)
	Submit:SetText("Submit")
	Submit:SetPos(210, 195)
	Submit:SetSize(370, 25)
	Submit.Think = function(self)
		local characters = string.len(string.Trim(Entry:GetText()))
		local disable = characters < 10 or not cur_selected
		Submit:SetDisabled(disable)
		Submit:SetText(disable and "Not enough characters to submit" or "Submit")
	end
	Submit.DoClick = function(self)
		local ply = cur_selected.pl
		if not IsValid(ply) then return end
		net.Start("DL_ReportPlayer")
		net.WriteEntity(ply)
		net.WriteString(Entry:GetText())
		net.SendToServer()
		Frame:Close()
		Frame:Remove()
	end
	
	Tabs:AddSheet("Report an user", ReportPanel, "icon16/report_user.png")
	
	local Logs = vgui.Create("DListView")
	
	Logs:AddColumn("Time"):SetFixedWidth(40);
	Logs:AddColumn("Type"):SetFixedWidth(40);
	Logs:AddColumn("Event")
	
	if tbl then
		self:SetListViewTable(Logs, tbl, false)
	end
	
	Tabs:AddSheet("Logs before your death", Logs, "icon16/application_view_list.png")
	
	Frame:MakePopup()
	
end

net.Receive("DL_AllowReport", function()
	local got_tbl, tbl = net.ReadUInt(1) == 1, false
	if got_tbl then
		tbl = net.ReadTable()
	end
	Damagelog:ReportWindow(tbl)
end)

net.Receive("DL_SendReport", function()
	local report = net.ReadTable()
	table.insert(Damagelog.ReportsQueue, report)
	if not LocalPlayer().IsActive or not LocalPlayer():IsActive() then
		BuildReportFrame(report)
	end
end)

net.Receive("DL_Death", function()
	BuildReportFrame()
end)

net.Receive("DL_SendForgive", function()
	local previous = net.ReadUInt(1) == 1
	local index = net.ReadUInt(16)
	local nick = net.ReadString()
	local text = net.ReadString()
	local answer = vgui.Create("DFrame")
	answer:ShowCloseButton(false)
	answer:SetSize(400, 275)
	answer:SetTitle("Message from "..nick.." about your report.")
	answer:Center()
	answer:MakePopup()
	local message = vgui.Create("DTextEntry", answer)
	message:SetSize(390, 200)
	message:SetPos(3, 30)
	message:SetText(text)
	message:SetEditable(false)
	message:SetMultiline(true)
	local forgive = vgui.Create("DButton", answer)
	forgive:SetText("Forgive")
	forgive:SetPos(3, 235)
	forgive:SetSize(195, 30)
	forgive.DoClick = function(self)
		net.Start("DL_GetForgive")
		net.WriteUInt(1,1)
		net.WriteUInt(previous and 1 or 0, 1)
		net.WriteUInt(index, 16)
		net.SendToServer()
		answer:Close()
	end
	local nope = vgui.Create("DButton", answer)
	nope:SetText("Keep the report")
	nope:SetPos(205, 235)
	nope:SetSize(188, 30)
	nope.DoClick = function(self)
		net.Start("DL_GetForgive")
		net.WriteUInt(0,1)
		net.WriteUInt(previous and 1 or 0, 1)
		net.WriteUInt(index, 16)
		net.SendToServer()
		answer:Close()
	end
end)

net.Receive("DL_Answering_global", function(_len)
	local nick = net.ReadString()
	local ply = LocalPlayer()
	if not ply:IsActive() then
		chat.AddText(Color(255,62,62), nick, color_white, " is answering to their reports.")
	end
end)
