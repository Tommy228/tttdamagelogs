CreateClientConVar("ttt_dmglogs_rdmpopups", "1", FCVAR_ARCHIVE)
CreateClientConVar("ttt_dmglogs_currentround", "0", FCVAR_ARCHIVE)
CreateClientConVar("ttt_dmglogs_outsidenotification", "1", FCVAR_ARCHIVE)

hook.Add("TTTSettingsTabs", "DamagelogsTTTSettingsTab", function(dtabs)

	local padding = dtabs:GetPadding()

	padding = padding * 2

	local dsettings = vgui.Create("DPanelList", dtabs)
	dsettings:StretchToParent(0,0,padding,0)
	dsettings:EnableVerticalScrollbar(true)
	dsettings:SetPadding(10)
	dsettings:SetSpacing(10)

	do
		local dgui = vgui.Create("DForm", dsettings)
		dgui:SetName("General settings")

		local cb = nil

		dgui:CheckBox("Enable RDM Manager popups upon RDM", "ttt_dmglogs_rdmpopups")
		
		dgui:CheckBox("Open the current round by default if you're alive and allowed to open the logs", "ttt_dmglogs_currentround")
		
		dgui:CheckBox("Enable notification sound outside of the game", "ttt_dmglogs_outsidenotification")

		dsettings:AddItem(dgui)

	end

	dtabs:AddSheet("Damagelogs", dsettings, "icon16/table_gear.png", false, false, "Damagelog menu settings")
end)