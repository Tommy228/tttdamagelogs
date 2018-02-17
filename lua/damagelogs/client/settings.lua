CreateClientConVar("ttt_dmglogs_rdmpopups", "1", FCVAR_ARCHIVE)
CreateClientConVar("ttt_dmglogs_currentround", "0", FCVAR_ARCHIVE)
CreateClientConVar("ttt_dmglogs_updatenotifications", "1", FCVAR_ARCHIVE)
CreateClientConVar("ttt_dmglogs_showpending", "1", FCVAR_ARCHIVE)
CreateClientConVar("ttt_dmglogs_enablesound", "1", FCVAR_ARCHIVE)
CreateClientConVar("ttt_dmglogs_enablesoundoutside", "0", FCVAR_ARCHIVE)

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
	if Damagelog.ForcedLanguage == "" then
		dmgLang:SetDisabled(false)
		dmgLang:ChooseOption(string.upper(string.sub(GetConVar("ttt_dmglogs_language"):GetString(),1,1))..string.sub(GetConVar("ttt_dmglogs_language"):GetString(),2,100))
	else
		dmgLang:SetDisabled(true)
		dmgLang:SetTooltip(TTTLogTranslate(GetDMGLogLang, "ForcedLanguage"))
		dmgLang:ChooseOption(string.upper(string.sub(Damagelog.ForcedLanguage,1,1))..string.sub(Damagelog.ForcedLanguage,2,100))
	end

	dmgLang.OnSelect = function(panel, index, value, data, Damagelog)
		local currentLanguage = GetConVar("ttt_dmglogs_language"):GetString()
		local newLang = string.lower(value)
		if currentLanguage == newLang then return end
		RunConsoleCommand("ttt_dmglogs_language", newLang)
	end

	dgui:AddItem(dmgLang)

	dgui:CheckBox(TTTLogTranslate(GetDMGLogLang, "UpdateNotifications"), "ttt_dmglogs_updatenotifications")
	dgui:CheckBox(TTTLogTranslate(GetDMGLogLang, "RDMuponRDM"), "ttt_dmglogs_rdmpopups")
	dgui:CheckBox(TTTLogTranslate(GetDMGLogLang, "CurrentRoundLogs"), "ttt_dmglogs_currentround")
	dgui:CheckBox(TTTLogTranslate(GetDMGLogLang, "ShowPendingReports"), "ttt_dmglogs_showpending")
	dgui:CheckBox(TTTLogTranslate(GetDMGLogLang, "EnableSound"), "ttt_dmglogs_enablesound")
	dgui:CheckBox(TTTLogTranslate(GetDMGLogLang, "OutsideNotification"), "ttt_dmglogs_enablesoundoutside")
	dsettings:AddItem(dgui)

	local colorSettings = vgui.Create("DForm")
	colorSettings:SetName(TTTLogTranslate(GetDMGLogLang, "Colors"))

	local colorChoice = vgui.Create("DComboBox")

	for k,v in pairs(Damagelog.colors) do
		colorChoice:AddChoice(TTTLogTranslate(GetDMGLogLang, k), k)
	end
	colorChoice:ChooseOptionID(1)

	colorSettings:AddItem(colorChoice)
	local colorMixer = vgui.Create("DColorMixer")
	colorMixer:SetHeight(200)
	local found = false

	colorChoice.OnSelect = function(panel, index, value, data)
		colorMixer:SetColor(Damagelog.colors[data].Custom)
		selectedcolor = data
	end

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

	dtabs:AddSheet("Damagelogs", dsettings, "icon16/table_gear.png", false, false, TTTLogTranslate(GetDMGLogLang, "DamagelogMenuSettings"))
end)