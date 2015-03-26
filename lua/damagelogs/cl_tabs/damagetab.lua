
CreateClientConVar("ttt_dmglogs_showinnocents", "0", true, true)

cvars.AddChangeCallback("ttt_dmglogs_showinnocents", function(name, old, new)
	if IsValid(Damagelog.Menu) then
		Damagelog:SetRolesListView(Damagelog.Roles, Damagelog.CurrentRoles)
	end
end)

surface.CreateFont("DL_Highlight", {
	font = "Verdana",
	size = 13
})

local PANEL = {}

function PANEL:SetPlayer(nick)
	self.Text = nick
	surface.SetFont("DL_Highlight")
	local xtext, ytext = surface.GetTextSize(self.Text)
	self:SetSize(xtext+25, ytext+4)
	self.Close = vgui.Create("TipsButton", self)
	self.Close.Colors = {
		default = COLOR_LGRAY,
		hover = Color(0, 100, 200),
		press = COLOR_BLUE
	}
	self.Close:SetPos(xtext + 10, 2)
	self.Close:SetSize(13, 13)
	self.Close:SetText("")
	self.Close.PaintOver = function(self, w, h)
		surface.SetFont("DermaDefault")
		local x,y = surface.GetTextSize("X")
		surface.SetTextPos(w/2 - x/2 + 1, h/2 - y/2)
		surface.DrawText("X")
	end
	self.Close.DoClick = function()
		for k,v in pairs(Damagelog.Highlighted) do
			if v == self.Text then
				table.remove(Damagelog.Highlighted, k)
				Damagelog.PlayerSelect:UpdatePlayers()
				break
			end
		end
	end
	self.SizeX = xtext + 25
end

function PANEL:Paint(w,h)
	if not self.Text then return end
	surface.SetDrawColor(Color(242, 242, 242))
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(Color(0, 50, 200))
	surface.DrawLine(0, 0, w-1, 0)
	surface.DrawLine(w-1, 0, w-1, h-1)
	surface.DrawLine(w-1, h-1, 0, h-1)
	surface.DrawLine(0, h-1, 0, 0)
	surface.SetFont("DL_Highlight")
	surface.SetTextColor(color_black)
	surface.SetTextPos(3, 1)
	surface.DrawText(self.Text)
end

derma.DefineControl("DL_FiltersPlayer", "", PANEL, "DPanel")

local cur_selected

Damagelog.Highlighted = Damagelog.Highlighted or {}

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
	self.Panel:SetSize(x-40, 195)
	self.PanelOptions = vgui.Create("DPanelList", self.Panel)
	self.PanelOptions:SetSpacing(7)
	self.PanelOptions:StretchToParent(12, 5, 0, 0)
		
	local forms = {}
		
	self.RF = vgui.Create("DForm", self.PanelOptions)
	self.RF:SetName("Round selection/filters")
	self.RoundPanel = vgui.Create("DPanel")
	self.RoundPanel:SetHeight(90)
	self.RoundPanel.Paint = function() end
	
	self.Round = vgui.Create("DComboBox", self.RoundPanel)
	self.Round:SetSize(500, 22)
	self.Round:SetPos(0, 0)
	local old_click = self.Round.DoClick
	self.Round.DoClick = function(panel)
		local sync_ent = self:GetSyncEnt()
		if IsValid(sync_ent) and (sync_ent:GetLastRoundMapExists() or sync_ent:GetPlayedRounds() > 0) then
			return old_click(panel)
		end
	end
	
	self.Filters = vgui.Create("DButton", self.RoundPanel)
	self.Filters:SetText("Edit filters")
	self.Filters:SetPos(505, 0)
	self.Filters:SetSize(85, 22)
	self.Filters.DoClick = function(self)
		local filters = DermaMenu()
		for k,v in pairs(Damagelog.filters) do
			local value = Damagelog.filter_settings[k]
			local option = filters:AddOption(k, function()
				Damagelog.filter_settings[k] = not Damagelog.filter_settings[k]
				Damagelog:SaveFilters()
				askLogs()
			end)
			option:SetIcon(value and "icon16/accept.png" or "icon16/delete.png")
		end
		filters:Open()
	end
	
	self.PlayerSelect = vgui.Create("DPanel", self.RoundPanel)
	self.PlayerSelect:SetPos(0, 30)
	self.PlayerSelect:SetSize(590 ,60)
	self.PlayerSelect.Panels = {}
	self.PlayerSelect.UpdatePlayers = function(self)
		for k,v in pairs(self.Panels) do
			v:Remove()
		end
		table.Empty(self.Panels)
		if #Damagelog.Highlighted > 0 then
			Damagelog.PS_Label:SetText(Damagelog.PS_Label.Text)
			surface.SetFont("DL_Highlight")
			local x = surface.GetTextSize(Damagelog.PS_Label.Text)
			x = x + 10
			for k,v in ipairs(Damagelog.Highlighted) do
				local ply = vgui.Create("DL_FiltersPlayer", self)
				table.insert(self.Panels, ply)
				ply:SetPlayer(v)
				ply:SetPos(x, 8)
				x = x + ply.SizeX + 5
			end
		else
			Damagelog.PS_Label:SetText(Damagelog.PS_Label.Text.." none")
		end
	end
	
	self.PS_Label = vgui.Create("DLabel", self.PlayerSelect)
	self.PS_Label.Text = "Currently highlighted players:"
	self.PS_Label:SetFont("DL_Highlight")
	self.PS_Label:SetTextColor(color_black)
	self.PS_Label:SetText(self.PS_Label.Text.." none")
	self.PS_Label:SetPos(5, 10)
	self.PS_Label:SizeToContents()
	
	self.PlayersCombo = vgui.Create("DComboBox", self.PlayerSelect)
	self.PlayersCombo:SetPos(5, 30)
	self.PlayersCombo:SetSize(490, 20)
	self.PlayersCombo:AddChoice("No players.", NULL)
	self.PlayersCombo.Update = function(self)
		self:Clear()
		for k,v in pairs(self.Players) do
			self:AddChoice(k)
		end
		if table.Count(self.Players) > 0 then
			self:ChooseOptionID(1)
			self:SetDisabled(false)
		else
			self:SetDisabled(true)
		end
	end
	self.PlayersCombo.FirstSelect = true
	self.PlayersCombo.OnSelect = function(self, index, value, data)
		self.CurrentlySelected = value
	end
	self.PlayersCombo:SetDisabled(true)
	
	self.Highlight = vgui.Create("DButton", self.PlayerSelect)
	self.Highlight:SetPos(500, 30)
	self.Highlight:SetSize(80, 20)
	self.Highlight:SetText("Highlight")
	self.Highlight.DoClick = function(self)
		local selected = Damagelog.PlayersCombo.CurrentlySelected
		if table.HasValue(Damagelog.Highlighted, selected) then return end
		if #Damagelog.Highlighted >= 3 then
			Derma_Message("You can't highlight more than 3 players at once!", "Error", "OK")
		else
			table.insert(Damagelog.Highlighted, selected)
			Damagelog.PlayerSelect:UpdatePlayers()
		end
	end
	
	self.RF:AddItem(self.RoundPanel)
	
	self.PanelOptions:AddItem(self.RF)
	self.RF:SetHeight(150)
	self.RF:SetExpanded(true)
			
	table.insert(forms, self.RF)
		
	self.DamageInfoBox = vgui.Create("DForm", self.PanelOptions)
	self.DamageInfoBox:SetName("Damage information")
	self.DamageInfo = vgui.Create("DListView")
	self.DamageInfo:SetHeight(90)
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
	self.Roles:SetHeight(90)
	self.RoleInfos:AddItem(self.Roles)	
	self.PanelOptions:AddItem(self.RoleInfos)
	self.RoleInfos:SetHeight(350)
	self.RoleInfos:SetExpanded(false)

	local show_innocents = vgui.Create("DCheckBoxLabel", self.RoleInfos)
	show_innocents:SetPos(465, 3)
	show_innocents:SetText("Show innocent players")
	show_innocents:SetTextColor(color_white)
	show_innocents:SetConVar("ttt_dmglogs_showinnocents")
	show_innocents:SizeToContents()
	
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
	self.Damagelog:SetHeight(415)
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
	local LastChoise = 0
	if LastMapExists then
		self.Round:AddChoice("Last round of the previous map", -1)
		LastChoise = LastChoise + 1
		if PlayedRounds <= 0 then
			self.SelectedRound = -1
			askLogs()
			self.Round:ChooseOptionID(1)
		end
	end
	if PlayedRounds > 1 or (LocalPlayer():CanUseDamagelog() and PlayedRounds > 0) then
		local i_count = 1
		if PlayedRounds > 10 then
			i_count = PlayedRounds - 10
		end
		if not LocalPlayer():CanUseDamagelog() then
			PlayedRounds = PlayedRounds - 1
		end
		for i = i_count, PlayedRounds do
			if i == PlayedRounds and LocalPlayer():CanUseDamagelog() then
				self.Round:AddChoice("Current Round", i)
			else
				self.Round:AddChoice("Round "..tostring(i), i)
			end
			LastChoise = LastChoise + 1
		end
		if not LocalPlayer():CanUseDamagelog() or (GetConVar("ttt_dmglogs_currentround"):GetBool() or not LocalPlayer():IsActive()) then
			self.Round:ChooseOptionID(LastChoise)
				else
			self.Round:ChooseOptionID(LastChoise-1 > 0 and LastChoise-1 or LastChoise)
		end
		askLogs()
	elseif not LastMapExists then
		self.Round:AddChoice("No available logs for the current map")
		self.Round:ChooseOptionID(1)
	end
	self.Round.OpenMenu = function(self, pControlOpener)
		if pControlOpener then
			if pControlOpener == self.TextEntry then
				return
			end
		end
		if #self.Choices == 0 then return end
		if IsValid(self.Menu) then
			self.Menu:Remove()
			self.Menu = nil
		end
		self.Menu = DermaMenu()
		local sorted = {}
		for k,v in pairs(self.Choices) do table.insert(sorted, { id = k, data = v }) end
		for k,v in pairs(sorted, "data") do
			self.Menu:AddOption(v.data, function() self:ChooseOption( v.data, v.id ) end)
		end
		local x, y = self:LocalToScreen(0, self:GetTall())
		self.Menu:SetMinimumWidth(self:GetWide())
		self.Menu:Open(x, y, false, self)
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
	self.CurrentRoles = tbl
	self:SetRolesListView(self.Roles, tbl)
end
net.Receive("DL_SendRoles", function()
	local tbl = net.ReadTable()
	Damagelog.RoleNicks = {}
	for k,v in pairs(player.GetAll()) do
		Damagelog.RoleNicks[v:Nick()] = v
	end
	if IsValid(Damagelog.Menu) then
		Damagelog.Highlighted = {}
		if Damagelog.PlayerSelect and Damagelog.PlayerSelect.UpdatePlayers then
			Damagelog.PlayerSelect:UpdatePlayers()
		end
		Damagelog.PlayersCombo.Players = tbl
		Damagelog.PlayersCombo:Update()
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
	if not IsValid(LocalPlayer()) then return end -- sometimes happens while joining
	if not LocalPlayer().CanUseDamagelog then return end
	if not LocalPlayer():CanUseDamagelog() then return end
	if IsValid(Damagelog.Damagelog) then
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