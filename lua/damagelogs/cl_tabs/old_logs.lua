local monthnames = {
	"January",
	"February",
	"March",
	"April",
	"May",
	"June",
	"July",
	"August",
	"September",
	"October",
	"November",
	"December"
}

surface.CreateFont("DL_OldLogsFont", {
	font = "DermaLarge",
	size = 20
})

function Damagelog:DrawOldLogs()

	self.CurSelectedRound = nil

	self.OldLogs = vgui.Create("DPanel")
	self.OldLogs.UpdateDates = function()
		for year,months in pairs(self.CurLogsTable) do
			local year_node = self.DateChoice:AddNode(year)
			year_node.year = tonumber(year)
			for month,days in pairs(months) do				
				if not monthnames[tonumber(month)] then continue end
				local month_node = year_node:AddNode(monthnames[tonumber(month)])
				month_node.year = year_node.year
				month_node.month = tonumber(month)
				for day,maps in pairs(days) do
					local day_node = month_node:AddNode(day)
					day_node.year = month_node.year
					day_node.month = month_node.month
					day_node.day = tonumber(day)
					local times = {}
					for _time, map in pairs(maps) do
						table.insert(times, _time)
					end
					table.sort(times)
					local created_nodes = {}
					for k,v in ipairs(times) do
						local hour = os.date("%H", v)
						if not created_nodes[hour] then
							created_nodes[hour] = day_node:AddNode(hour.."h")
							created_nodes[hour].hour = hour
							created_nodes[hour].dates = { {v,maps[v]} }
							created_nodes[hour].year = day_node.year
							created_nodes[hour].month = day_node.month
							created_nodes[hour].day = day_node.day
						else
							table.insert(created_nodes[hour].dates, {v,maps[v]})
						end
					end
				end
			end
		end
	end
	
	local panel_list = vgui.Create("DPanelList", self.OldLogs)
	panel_list:SetPos(15, 60)
	panel_list:SetSize(609, 355)
	panel_list:SetSpacing(10)
	panel_list.Paint = function() end
	
	local forms = {}
	
	local player_info = vgui.Create("DForm")
	player_info:SetName("Player information")
	player_info:SetHeight(300)
	table.insert(forms, player_info)
	self.PlayerList = vgui.Create("DListView")
	self.PlayerList:SetHeight(130)
	self.PlayerList:AddColumn("Player")
	self.PlayerList:AddColumn("SteamID")
	self.PlayerList:AddColumn("Role")
	player_info:AddItem(self.PlayerList)
	panel_list:AddItem(player_info)
	
	self.DamageInfoForm = vgui.Create("DForm")
	self.DamageInfoForm:SetName("Damage information")
	self.DamageInfoForm:SetHeight(300)
	self.DamageInfoForm:SetExpanded(false)
	table.insert(forms, self.DamageInfoForm)
	self.OldDamageInfo = vgui.Create("DListView")
	self.OldDamageInfo:SetHeight(130)
	self.OldDamageInfo:AddColumn("Damage information")
	self.DamageInfoForm:AddItem(self.OldDamageInfo)
	panel_list:AddItem(self.DamageInfoForm)
	
	for k,v in pairs(forms) do
		local old_toggle = v.Toggle
		v.Toggle = function(self)
			if self:GetExpanded() then 
				return 
			else
				for _,s in pairs(forms) do
					if s:GetExpanded() then
						old_toggle(s)
					end
				end
			end
			return old_toggle(v)
		end
	end
	
	local date_panel = vgui.Create("DPanel", self.OldLogs)
	date_panel:SetPos(10, -225)
	date_panel:SetSize(620, 275)
	date_panel.Paint = function(panel,x,y)
		surface.SetDrawColor(Color(150,150,150))
		surface.DrawRect(0, 0, x,y)
	end
	
	local date = vgui.Create("DLabel", date_panel)
	date:SetFont("DL_OldLogsFont")
	date:SetText("Select a date:")
	date:SizeToContents()
	date:SetPos(20, 7)

	local round = vgui.Create("DLabel", date_panel)
	round:SetFont("DL_OldLogsFont")
	round:SetText("Select a round:")
	round:SizeToContents()
	round:SetPos(320, 7)
	
	self.DateChoice = vgui.Create("DTree", date_panel)
	self.DateChoice:SetPos(10, 35)
	self.DateChoice:SetSize(290, 190)
	
	self.RoundChoice = vgui.Create("DListView", date_panel)
	self.RoundChoice:SetPos(315, 35)
	self.RoundChoice:SetSize(290, 190)
	local round_column = self.RoundChoice:AddColumn("")
	
	self.DateChoice.OnNodeSelected = function(panel, selected)
		if selected.hour then
			self.RoundChoice:Clear()
			round_column:SetName("Rounds of "..selected.hour.."h")
			for k,v in ipairs(selected.dates) do
				local line = self.RoundChoice:AddLine("min"..os.date("%M", v[1]).." : "..v[2])
				line.time = v[1]
			end
		end
	end	
	
	self.LoadLogs = vgui.Create("DButton", date_panel)
	self.LoadLogs:SetPos(10, 235)
	self.LoadLogs:SetSize(597, 30)
	self.LoadLogs:SetText("Select a round to load")
	self.LoadLogs.DoClick = function(panel)
		if panel.MoveTop or panel.MoveBot then return end
		if panel.Top then
			panel.MoveBot = true
		elseif panel.Bot then
			if #self.RoundChoice:GetSelected() == 0 then
				Derma_Message("Please select a round!", "Error", "OK")
				return
			end
			if #self.RoundChoice:GetSelected() > 1 then
				Derma_Message("Please only select one round!", "Error", "OK")
				return
			end
			net.Start("DL_AskOldLog")
			net.WriteUInt(self.RoundChoice:GetSelected()[1].time, 32)
			net.SendToServer()
			panel.MoveTop = true
		end
	end
	self.LoadLogs.Bot = false
	self.LoadLogs.Top = true
	self.LoadLogs.Think = function(panel)
		if panel.MoveTop then
			local x,y = date_panel:GetPos()
			if y > -225 then
				date_panel:SetPos(x, y-6)
			else
				panel.Top = true
				panel.Bot = false
				panel.MoveTop = false
				panel:SetText("Select a round to load")
			end
		elseif panel.MoveBot then
			local x,y = date_panel:GetPos()
			if y < 0 then
				date_panel:SetPos(x, y+6)
			else
				panel.Top = false
				panel.Bot = true
				panel.MoveBot = false
				panel:SetText("Load the logs of the selected round")
			end
		end
	end
	
	self.OldDamagelog = vgui.Create("DListView", self.OldLogs)
	self.OldDamagelog:SetPos(0, 280)
	self.OldDamagelog:SetSize(639, 329)
	self.OldDamagelog:AddColumn("Time"):SetFixedWidth(40)
	self.OldDamagelog:AddColumn("Type"):SetFixedWidth(40)
	self.OldDamagelog.EventColumn = self.OldDamagelog:AddColumn("Event")
	self.OldDamagelog.EventColumn:SetFixedWidth(529)
	self.OldDamagelog.IconColumn = self.OldDamagelog:AddColumn("")
	self.OldDamagelog.IconColumn:SetFixedWidth(30)
	self.OldDamagelog.Think = function(panel)
		if panel.VBar.Enabled and not panel.Scrollbar then
			panel.EventColumn:SetFixedWidth(509)
			panel.IconColumn:SetFixedWidth(50)
			panel.Scrollbar = true
		elseif not panel.VBar.Enabled and panel.Scrollbar then
			panel.EventColumn:SetFixedWidth(529)
			panel.IconColumn:SetFixedWidth(30)
			panel.Scrollbar = false
		end
	end
	
	self.Tabs:AddSheet("Old logs", self.OldLogs, "icon16/calendar_view_week.png", false, false)
	
	net.Start("DL_AskLogsList")
	net.SendToServer()
	
end

net.Receive("DL_SendLogsList", function()
	Damagelog.CurLogsTable = net.ReadTable()
	if ValidPanel(Damagelog.OldLogs) then
		Damagelog.OldLogs:UpdateDates()
	end
end)

net.Receive("DL_SendOldLog", function()
	local exists = net.ReadUInt(1) == 1
	if exists then
		local size = net.ReadUInt(32)
		local data = net.ReadData(size)
		-- dataception
		if data then
			data = util.Decompress(data)
			if data then
				data = util.JSONToTable(data)
				if data then
					Damagelog.OldDamagelog:Clear()
					Damagelog.OldShootTables = data.ShootTable
					Damagelog:SetListViewTable(Damagelog.OldDamagelog, data.DamageTable, false, true)
					if data.Infos then
						Damagelog.PlayerList:Clear()
						for k,v in pairs(data.Infos) do
							local item = Damagelog.PlayerList:AddLine(k, v.steamid, Damagelog:StrRole(v.role))
							item.steamid = v.steamid
							item.OnRightClick = function()
								local copy = DermaMenu()
								copy:AddOption("Copy SteamID", function()
									SetClipboardText(item.steamid)
								end):SetImage("icon16/tab_edit.png")
								copy:Open()
							end
						end
					end
				end
			end
		end
	end
end)


function Damagelog:FindFromOldLogs(t, att, victim, round)
	local results = {}
	local found = false
	for k,v in pairs(self.OldShootTables or {}) do
	    if k >= t - 10 and k <= t then
		    for s,i in pairs(v) do
		        if i[1] == victim or i[1] == att then
		            if results[k] == nil then
					    table.insert(results, k, {})
					end
					table.insert(results[k], i)
			        found = true
				end
			end
		end
	end
	return found, results
end 
