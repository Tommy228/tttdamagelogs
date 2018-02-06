function Damagelog:DrawShootsTab()
	self.Shoots = vgui.Create("DPanelList")
	self.Shoots:SetSpacing(10)
	self.ShootsRefresh = vgui.Create("DButton")
	self.ShootsRefresh:SetText(TTTLogTranslate(GetDMGLogLang, "Refresh"))

	self.ShootsRefresh.DoClick = function()
		if not tonumber(self.SelectedRound) then return end
		self.ShootTableTemp = {}
		self.ReceivingST = true
		self.ShootsList:Clear()
		self.ShootsList:AddLine(TTTLogTranslate(GetDMGLogLang, "Loading"))
		net.Start("DL_AskShootLogs")
		net.WriteInt(self.SelectedRound, 8)
		net.SendToServer()
	end

	self.Shoots:AddItem(self.ShootsRefresh)
	self.ShootsList = vgui.Create("DListView")
	self.ShootsList:SetHeight(575)
	self.ShootColumn = self.ShootsList:AddColumn("")
	self.ShootColumn.UpdateText = function(shootColumn)
		shootColumn:SetName(TTTLogTranslate(GetDMGLogLang, "CurrentRoundSelected")..self.Round:GetValue())
	end
	self.ShootColumn:UpdateText()
	self.Shoots:AddItem(self.ShootsList)
	self.ShootsList.OnRowRightClick = function()
		local Menu = DermaMenu()
		Menu:Open()
		Menu:AddOption(TTTLogTranslate(GetDMGLogLang, "CopyLines"), function()
			local full_text = ""
			local append = false
			for _, line in pairs(Damagelog.ShootsList:GetSelected()) do
				if append then
					full_text = full_text .. "\n"
				end
				full_text = full_text .. line:GetColumnText(1)
				append = true
			end
			SetClipboardText(full_text)
		end):SetImage("icon16/tab_edit.png")
	end
	self.Tabs:AddSheet(TTTLogTranslate(GetDMGLogLang, "SLogs"), self.Shoots, "icon16/page_white_find.png", false, false)
end

net.Receive("DL_SendShootLogs", function()
	local roles = net.ReadTable()
	local data = net.ReadTable()
	if IsValid(Damagelog.ShootsList) then
		Damagelog.ShootsList:Clear()
		Damagelog:SetDamageInfosLV(Damagelog.ShootsList, roles, nil, nil, nil, nil, data)
	end
end)
