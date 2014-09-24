local function AAText(text, font, x, y, color, align)
    draw.SimpleText(text, font, x+1, y+1, Color(0,0,0,math.min(color.a,120)), align)
    draw.SimpleText(text, font, x+2, y+2, Color(0,0,0,math.min(color.a,50)), align)
    draw.SimpleText(text, font, x, y, color, align)
end

local cur_selected

function Damagelog:DrawDamageTab(x, y)

	local function askLogs()
		if not self.SelectedRound then return end
		self.Damagelog:Clear()
		self.Damagelog:AddLine("", "", "Loading...")
		self.loading = {}
		self.receiving = true
		net.Start("DL_AskDamagelog")
		net.WriteInt(self.SelectedRound, 32)
		net.SendToServer()
	end
	
	self.DamageTab = vgui.Create("DListLayout")
	
	self.Panel = self.DamageTab:Add("DPanel")
	self.Panel:SetSize(x-40, 240)
	self.PanelOptions = vgui.Create("DPanelList", self.Panel)
	self.PanelOptions:SetSpacing(7)
	self.PanelOptions:StretchToParent(12, 5, 0, 0)
		
	local forms = {}
		
	self.RF = vgui.Create("DForm", self.PanelOptions)
	self.RF:SetName("Round selection/filters")
	self.Round = vgui.Create("DComboBox")
	local old_click = self.Round.DoClick
	self.Round.DoClick = function(panel)
		local sync_ent = self:GetSyncEnt()
		if IsValid(sync_ent) and (sync_ent:GetLastRoundMapExists() or sync_ent:GetPlayedRounds() > 0) then
			return old_click(panel)
		end
	end
	self.RF:AddItem(self.Round)
	self.Filters = vgui.Create("DListView")
	self.RF:AddItem(self.Filters)
	self.Filters:SetHeight(105)
	self.Filters:AddColumn("Filter")
	self.Filters:AddColumn("Current settings")
	
	local last_selection
	local function updateFilters(refresh)
		self.Filters:Clear()
		for k,v in pairs(self.filters) do
			local setting = self.filter_settings[k]
			if setting != nil then
				local str, color = self:SettingToStr(v, setting)
				local line = self.Filters:AddLine(k, str)
				if color then
					line.PaintOver = function(panel)
						if not panel:IsLineSelected() then
							panel.Columns[2]:SetTextColor(color)
						else
							panel.Columns[2]:SetTextColor(Color(255, 255, 255))
						end
					end
				end
				line.OnRightClick = function()
					last_selection = k
					local menu = DermaMenu()
					if v == DAMAGELOG_FILTER_BOOL then
						menu:AddOption(setting and "disable" or "enable", function()
							self.filter_settings[k] = not self.filter_settings[k]
							self:SaveFilters()
							updateFilters(true)
						end)
					elseif v == DAMAGELOG_FILTER_PLAYER then
						menu:AddOption("Select a player", function()
							self.DamageTab:SetDisabled(true)
							local selection = vgui.Create("DFrame")
							selection:SetTitle("Select player")
							selection:SetSize(270, 400)
							selection:SetDraggable(false)
							selection:Center()
							selection:MakePopup()
							selection.Think = function(panel)
								panel:MoveToFront()
							end
							hook.Add("Think", "Damagelog_SelectionThink", function()
								if not IsValid(selection) then
									self.DamageTab:SetDisabled(false)
									hook.Remove("Think", "Damagelog_SelectionThink")
								end
							end)
							local button = vgui.Create("DButton", selection)
							button:SetText("Filter selected player")
							button:SetSize(255, 25)
							button:SetPos(0, 28)
							button:CenterHorizontal()
							local plist = vgui.Create("DPanelList", selection)
							plist:SetPos(0, 60)
							plist:SetSize(255, 340)
							plist:CenterHorizontal()
							plist:EnableVerticalScrollbar(true)
							local cur_selected
							plist.AddPlayer = function(pnl, pl)  
								local pl = pl
								if not IsValid(pl) then return end
								if not IsValid(pnl) then return end
								local ply = vgui.Create("DPanel")
								ply:SetSize(0, 30) 
								local alpha = 140
								local col = { r = 40, g = 40, b = 40 }
								local col_selected = { r = 204, g = 204, b = 51 }
								ply.pl = pl
								local function checkValidity()
									if not IsValid(pl) then
										ply:Remove()
										pnl:Clear(false)
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
									AAText(pl:Nick(), "GModNotify", 40, 7, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT)
								end
								ply.OnMousePressed = function(pnl, mc)
									if mc == MOUSE_LEFT and cur_selected != ply then
										cur_selected = ply  
									end
								end
								local ava = vgui.Create("AvatarImage", ply)
								ava:SetSize(24, 24)
								ava:SetPlayer(pl, 32)
								ava:SetPos(4, 4)
								pnl:AddItem(ply) 
							end
							for k,v in pairs(player.GetAll()) do
								plist:AddPlayer(v)
							end
							button.DoClick = function()
								if IsValid(cur_selected) and IsValid(cur_selected.pl) then
									self.filter_settings[k] = cur_selected.pl:SteamID()
									selection:Remove()
									updateFilters(true)
								end
							end
						end)
						menu:AddOption("Clear", function()
							self.filter_settings[k] = false
							updateFilters(true)
						end)
					end
					menu:Open()
				end
				if k == last_selection then
					line:SetSelected(true)
				end
			end
		end
		if refresh then
			askLogs()
		end
	end
	updateFilters(false)
	
	self.PanelOptions:AddItem(self.RF)
	self.RF:SetHeight(350)
	self.RF:SetExpanded(true)
			
	table.insert(forms, self.RF)
		
	self.DamageInfoBox = vgui.Create("DForm", self.PanelOptions)
	self.DamageInfoBox:SetName("Damage information")
	self.DamageInfo = vgui.Create("DListView")
	self.DamageInfo:SetHeight(130)
	self.DamageInfo:AddColumn("Damage information").DoClick = function() end
	self.DamageInfoBox:AddItem(self.DamageInfo)
	self.PanelOptions:AddItem(self.DamageInfoBox)
	self.DamageInfoBox:SetHeight(350)
	self.DamageInfoBox:SetExpanded(false)
			
	table.insert(forms, self.DamageInfoBox)
			
	self.RoleInfos = vgui.Create("DForm", self.PanelOptions)
	self.RoleInfos:SetName("Roles")
	self.Roles = vgui.Create("DListView")
	self.Roles:AddColumn("Player")
	self.Roles:AddColumn("Role")
	self.Roles:AddColumn("Alive?")
	self.Roles:SetHeight(130)
	self.RoleInfos:AddItem(self.Roles)	
	self.PanelOptions:AddItem(self.RoleInfos)
	self.RoleInfos:SetHeight(350)
	self.RoleInfos:SetExpanded(false)

	table.insert(forms, self.RoleInfos)
			
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
			
	self.Damagelog = self.DamageTab:Add("DListView")
	self.Damagelog:SetHeight(370)
	self.Damagelog:AddColumn("Time"):SetFixedWidth(40)
	self.Damagelog:AddColumn("Type"):SetFixedWidth(40)
	self.Damagelog.EventColumn = self.Damagelog:AddColumn("Event")
	self.Damagelog.EventColumn:SetFixedWidth(529)
	self.Damagelog.IconColumn = self.Damagelog:AddColumn("")
	self.Damagelog.IconColumn:SetFixedWidth(30)
	self.Damagelog.Think = function(panel)
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

	self.Tabs:AddSheet("Damagelog", self.DamageTab, "icon16/application_view_detail.png")

	local sync_ent = self:GetSyncEnt()
	if not IsValid(sync_ent) then
		return
	end
	
	self.Round.FirstSelect = true
	self.Round.OnSelect = function(_, value, index, data)
		self.SelectedRound = data
		if self.Round.FirstSelect then
			self.Round.FirstSelect = false
			return
		end
		askLogs()
	end
	
	local PlayedRounds = sync_ent:GetPlayedRounds()
	local LastMapExists = sync_ent:GetLastRoundMapExists()
	if LastMapExists then
		self.Round:AddChoice("Last round of the previous map", -1)
		if PlayedRounds <= 0 then
			self.SelectedRound = -1
			askLogs()
			self.Round:ChooseOptionID(1)
		end
	end
	if PlayedRounds > 0 then
		local i_count = 1
		if PlayedRounds > 10 then
			i_count = PlayedRounds - 10
		end
		for i = i_count, PlayedRounds do
			if i == PlayedRounds then
				self.Round:AddChoice("Current Round", i)
			else
				self.Round:AddChoice("Round "..tostring(i), i)
			end
		end
		if PlayedRounds <= 10 then
			self.Round:ChooseOptionID(PlayedRounds)
		else
			self.Round:ChooseOptionID(11)
		end
		self.SelectedRound = PlayedRounds
		askLogs()
	elseif not LastMapExists then
		self.Round:AddChoice("No available logs for the current map")
		self.Round:ChooseOptionID(1)
	end
end

function Damagelog:ReceiveLogs(empty, tbl, last)
	if not self.receiving then return end
	if not IsValid(self.Menu) then return end
	self.Damagelog:Clear()
	if empty then
		self.Damagelog:AddLine("", "", "Nothing here...")
	else
		table.insert(self.loading, tbl)
		if last then
			self:FinishedLoading()
		end
	end
end
net.Receive("DL_SendDamagelog", function()
	local empty = net.ReadUInt(1) == 1
	if empty then
		Damagelog:ReceiveLogs(true)
	else
		local tbl = net.ReadTable()
		local last = net.ReadUInt(1) == 1
		Damagelog:ReceiveLogs(false, tbl, last)
	end
end)

function Damagelog:FinishedLoading()
	self.receiving = false
	self:SetListViewTable(self.Damagelog, self.loading)
end

function Damagelog:ReceiveRoles(tbl)
	if not IsValid(self.Menu) then return end
	self:SetRolesListView(self.Roles, tbl)
end
net.Receive("DL_SendRoles", function()
	local tbl = net.ReadTable()
	Damagelog.RoleNicks = {}
	for k,v in pairs(player.GetAll()) do
		Damagelog.RoleNicks[v:Nick()] = v
	end
	Damagelog:ReceiveRoles(tbl)
	Damagelog.RoleEnts = {}
end)

net.Receive("DL_SendDamageInfos", function()
	local empty = net.ReadUInt(1) == 1
	local beg = net.ReadUInt(32)
	local t = net.ReadUInt(32)
	local result
	if not empty then
		result = net.ReadTable()
	end
	local victim = net.ReadString()
	local att = net.ReadString()
	Damagelog:SetDamageInfosLV(Damagelog.DamageInfo, att, victim, beg, t, result)
end)

net.Receive("DL_RefreshDamagelog", function()
	local tbl = net.ReadTable()
	if not LocalPlayer():CanUseDamagelog() then return end
	if ValidPanel(Damagelog.Damagelog) then
		local lines = Damagelog.Damagelog:GetLines()
		if lines[1] and lines[1]:GetValue(3) == "Nothing here..." then
			Damagelog.Damagelog:Clear()
		end
		local rounds = Damagelog:GetSyncEnt():GetPlayedRounds()
		if rounds == Damagelog.SelectedRound then
			Damagelog:AddLogsLine(Damagelog.Damagelog, tbl)
		end
	end
end)
