CreateClientConVar("ttt_dmglogs_rdmpopups", "1", FCVAR_ARCHIVE)
CreateClientConVar("ttt_dmglogs_currentround", "0", FCVAR_ARCHIVE)
CreateClientConVar("ttt_dmglogs_outsidenotification", "1", FCVAR_ARCHIVE)
CreateClientConVar("ttt_dmglogs_updatenotifications", "1", FCVAR_ARCHIVE)
CreateClientConVar("ttt_dmglogs_showpending", "1", FCVAR_ARCHIVE)

local color_lightgreen = Color(50, 255, 50)

hook.Add("TTTSettingsTabs", "DamagelogsTTTSettingsTab", function(dtabs)

	local padding = dtabs:GetPadding() * 2
	local dsettings = vgui.Create("DPanelList", dtabs)
	dsettings:StretchToParent(0,0,padding,0)
	dsettings:EnableVerticalScrollbar(true)
	dsettings:SetPadding(10)
	dsettings:SetSpacing(10)

	local dgui = vgui.Create("DForm", dsettings)
	dgui:SetName(TTTLogTranslate(GetDMGLogLang, "Generalsettings"))
	local selectedcolor
	
	local dmgLang = vgui.Create("DComboBox")
	
	for k,v in pairs(DamagelogLang) do
		dmgLang:AddChoice(string.upper(string.sub(k,1,1))..string.sub(k,2,100))
	end

	dmgLang:ChooseOption(string.upper(string.sub(GetConVar("ttt_dmglog_language"):GetString(),1,1))..string.sub(GetConVar("ttt_dmglog_language"):GetString(),2,100))

	dmgLang.OnSelect = function(panel, index, value, data, Damagelog)
		local currentLanguage = GetConVar("ttt_dmglog_language"):GetString()
		local newLang = string.lower(value)
		if currentLanguage == newLang then return end
		RunConsoleCommand("ttt_dmglog_language", newLang)
	end

	dgui:AddItem(dmgLang)

	dgui:CheckBox(TTTLogTranslate(GetDMGLogLang, "UpdateNotifications"), "ttt_dmglogs_updatenotifications")
	dgui:CheckBox(TTTLogTranslate(GetDMGLogLang, "RDMuponRDM"), "ttt_dmglogs_rdmpopups")
	dgui:CheckBox(TTTLogTranslate(GetDMGLogLang, "CurrentRoundLogs"), "ttt_dmglogs_currentround")
	dgui:CheckBox(TTTLogTranslate(GetDMGLogLang, "OutsideNotification"), "ttt_dmglogs_outsidenotification")
	dgui:CheckBox(TTTLogTranslate(GetDMGLogLang, "ShowPendingReports"), "ttt_dmglogs_showpending")
	dsettings:AddItem(dgui)

	local colorSettings = vgui.Create("DForm")
	colorSettings:SetName(TTTLogTranslate(GetDMGLogLang, "Colors"))

	local colorChoice = vgui.Create("DComboBox")

	for k,v in pairs(Damagelog.colors) do
		colorChoice:AddChoice(TTTLogTranslate(GetDMGLogLang, k), k)
	end
	colorChoice:ChooseOptionID(1)

	colorChoice.OnSelect = function(panel, index, value, data)
		colorMixer:SetColor(Damagelog.colors[data].Custom)
		selectedcolor = data
	end

	colorSettings:AddItem(colorChoice)
	local colorMixer = vgui.Create("DColorMixer")
	colorMixer:SetHeight(200)
	local found = false

	for k,v in pairs(Damagelog.colors) do
		if not found then
			colorMixer:SetColor(v.Custom)
			selectedcolor = k
			found = true
			break
		end
	end

	colorSettings:AddItem(colorMixer)
	local saveColor = vgui.Create("DButton")
	saveColor:SetText(TTTLogTranslate(GetDMGLogLang, "Save"))

	saveColor.DoClick = function()
		local c = colorMixer:GetColor()
		Damagelog.colors[selectedcolor].Custom = c
		Damagelog:SaveColors()
	end

	colorSettings:AddItem(saveColor)
	local defaultcolor = vgui.Create("DButton")
	defaultcolor:SetText(TTTLogTranslate(GetDMGLogLang, "SetDefault"))

	defaultcolor.DoClick = function()
		local c = Damagelog.colors[selectedcolor].Default
		colorMixer:SetColor(c)
		Damagelog.colors[selectedcolor].Custom = c
		Damagelog:SaveColors()
	end

	colorSettings:AddItem(defaultcolor)
	
	dsettings:AddItem(colorSettings)

	local weaponForm = vgui.Create("DForm")
	weaponForm:SetName(TTTLogTranslate(GetDMGLogLang, "EditNames"))
	local addWeapon = vgui.Create("DButton")
	addWeapon:SetText(TTTLogTranslate(GetDMGLogLang, "AddWeapon"))

	addWeapon.DoClick = function()
		if not LocalPlayer():IsSuperAdmin() then return end

		Derma_StringRequest(TTTLogTranslate(GetDMGLogLang, "WeaponID"), TTTLogTranslate(GetDMGLogLang, "WeaponNameExample"), "weapon_", function(class)
			Derma_StringRequest(TTTLogTranslate(GetDMGLogLang, "WeaponDisplayName"), TTTLogTranslate(GetDMGLogLang, "WeaponDisplayExample"), "", function(name)
				net.Start("DL_AddWeapon")
				net.WriteString(class)
				net.WriteString(name)
				net.SendToServer()
			end, function() end, "OK", TTTLogTranslate(GetDMGLogLang, "Cancel"))
		end, function() end, "OK", TTTLogTranslate(GetDMGLogLang, "Cancel"))
	end

	weaponForm:AddItem(addWeapon)
	local removeWeapon = vgui.Create("DButton")
	removeWeapon:SetText(TTTLogTranslate(GetDMGLogLang, "RemoveSelectedWeapons"))

	removeWeapon.DoClick = function()
		if not LocalPlayer():IsSuperAdmin() then return end
		local classes = {}

		for k, v in pairs(Damagelog.WepListview:GetSelected()) do
			table.insert(classes, v:GetValue(1))
		end

		net.Start("DL_RemoveWeapon")
		net.WriteTable(classes)
		net.SendToServer()
	end

	weaponForm:AddItem(removeWeapon)
	local defautTable = vgui.Create("DButton")
	defautTable:SetText(TTTLogTranslate(GetDMGLogLang, "ResetDefault"))

	defautTable.DoClick = function()
		if not LocalPlayer():IsSuperAdmin() then return end

		Derma_Query(TTTLogTranslate(GetDMGLogLang, "ResetDefault") .. "?", TTTLogTranslate(GetDMGLogLang, "Yoursure"), TTTLogTranslate(GetDMGLogLang, "Yes"), function()
			net.Start("DL_WeaponTableDefault")
			net.SendToServer()
		end, TTTLogTranslate(GetDMGLogLang, "No"), function() end)
	end

	weaponForm:AddItem(defautTable)
	local wepListview = vgui.Create("DListView")
	wepListview:SetHeight(136)
	wepListview:AddColumn(TTTLogTranslate(GetDMGLogLang, "WeaponEntityID"))
	wepListview:AddColumn(TTTLogTranslate(GetDMGLogLang, "DisplayName"))

	wepListview.Update = function(panel)
		panel:Clear()

		for k, v in pairs(Damagelog.weapon_table) do
			local line = panel:AddLine(k, TTTLogTranslate(GetDMGLogLang, v))

			if not Damagelog.weapon_table_default[k] then
				line.PaintOver = function()
					line.Columns[1]:SetTextColor(color_lightgreen)
					line.Columns[2]:SetTextColor(color_lightgreen)
				end
			end
		end
	end

	wepListview:Update()
	weaponForm:AddItem(wepListview)
	dsettings:AddItem(weaponForm)
	if !LocalPlayer():IsSuperAdmin() then
		weaponForm:Toggle()
	end

	dtabs:AddSheet("Damagelogs", dsettings, "icon16/table_gear.png", false, false, TTTLogTranslate(GetDMGLogLang, "DamagelogMenuSettings"))
end)

net.Receive("DL_SendWeaponTable", function()
	local full = net.ReadUInt(1) == 1

	if full then
		Damagelog.weapon_table = net.ReadTable()
	else
		Damagelog.weapon_table[net.ReadString()] = net.ReadString()
	end

	if IsValid(Damagelog.WepListview) then
		Damagelog.WepListview:Update()
	end
end)
