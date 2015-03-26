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

local loading = {}
local function LoadLogs(node)
	if node.received or node.receiving then return end
	node.receiving = true
	local id = table.insert(loading, node)
	net.Start("DL_AskOldLogRounds")
	net.WriteUInt(id, 32)
	net.WriteUInt(node.year, 32)
	net.WriteUInt(node.month, 32)
	net.WriteUInt(node.day, 32)
	net.SendToServer()
end

net.Receive("DL_SendOldLogRounds", function()
	local id = net.ReadUInt(32)
	local list = net.ReadTable()
	local node = loading[id]
	if not node then return end
	if #list <= 0 then
		node:AddNode("Nothing found")
	else
		local dates = {}
		for k,v in pairs(list) do
			local _time = string.Explode(",", os.date("%H,%M", v.date))
			local hour = _time[1]
			hour = tonumber(hour)
			v.min = tonumber(_time[2])
			if not dates[hour] then
				dates[hour] = { v }
			end
			table.insert(dates[hour], v)
		end
		for i=0, 24 do
			local hour = dates[i]
			if not hour then continue end
			local node = node:AddNode(i.."h")
			table.SortByMember(hour, "date")
			node.rounds = hour
			node.hour = i
			node.min = hour.min
		end
	end
end)

function Damagelog:DrawOldLogs()

	self.CurSelectedRound = nil

	self.OldLogs = vgui.Create("DPanel")
	self.OldLogs.UpdateDates = function()
		local older = string.Explode(",", os.date("%y,%m,%d,%H,%M", self.OlderDate))
		local latest = string.Explode(",", os.date("%y,%m,%d,%H,%M", self.LatestDate))
		for k,v in pairs({older, latest}) do
			for _,data in pairs(v) do
				v[_] = tonumber(data)
			end
		end
		local years = latest[1] - older[1]
		for i=0, years do
			local year = latest[1] - i
			local node_year = self.DateChoice:AddNode("20"..tostring(year))
			node_year.year = year
			local start_range
			local end_range
			if years == 0 then
				start_range = older[2]
				end_range = latest[2]
			elseif year == latest[1] then
				start_range = 1
				end_range = latest[2]
			elseif year == older[1] then
				start_range = older[2]
				end_range = 12
			else
				start_range = 1
				end_range = 12
			end
			for i=start_range, end_range do
				local month = monthnames[i]
				local node_month = node_year:AddNode(month)
				node_month.year = year
				node_month.month = i
				node_month.received = false
				local number_of_days
				if i == 2 then
					local real_year = 2000 + year
					if (real_year) % 4 == 0 and not (real_year % 100 == 0 and real_year % 400 != 0) then
						number_of_days = 29
					else
						number_of_days = 28
					end
				else
					number_of_days =  (i % 2 == 0) and 31 or 30
				end
				for d=1, number_of_days do
					local day = node_month:AddNode(tostring(d))
					day.year = node_month.year
					day.month = node_month.month
					day.day = d
					day:SetForceShowExpander(true)
					day.old_SetExpanded = day.SetExpanded
					day.SetExpanded = function(pnl, expand, animation)
						if expand then LoadLogs(day) end
						return pnl.old_SetExpanded(pnl, expand, animation)
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
		if selected.rounds then
			self.RoundChoice:Clear()
			round_column:SetName("Rounds of "..selected.hour.."h")
			for k,v in ipairs(selected.rounds) do
				local line = self.RoundChoice:AddLine("min"..v.min.." : "..v.map)
				line.time = v.date
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
				Derma_Message("Please select only one round!", "Error", "OK")
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
	local received = net.ReadUInt(1) == 1
	if not received then return end
	Damagelog.OlderDate = net.ReadUInt(32)
	Damagelog.LatestDate = net.ReadUInt(32)
	if IsValid(Damagelog.OldLogs) then
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
