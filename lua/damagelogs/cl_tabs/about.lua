-- inb4 half of the servers removing this entire tab, credits or the donate button
-- really nice after all the time I spent working on the menu

surface.CreateFont("DL_About_Title", {
	font = "DermaLarge",
	size = 21
})

surface.CreateFont("DL_About_Text", {
	font = "DermaLarge",
	size = 18
})

function Damagelog:About()

	local panel = vgui.Create("DPanel")

	local rdm_manager_title = vgui.Create("DLabel", panel)
	rdm_manager_title:SetFont("DL_About_Title")
	rdm_manager_title:SetText("About the RDM Manager")
	rdm_manager_title:SetTextColor(Color(0,0,0))
	rdm_manager_title:SetPos(10, 10)
	rdm_manager_title:SizeToContents()
	
	local rdm_manager = vgui.Create("DLabel", panel)
	rdm_manager:SetFont("DL_About_Text")
	rdm_manager:SetText([[The RDM manager is a passive system built into the damage logs that allows admins to deal 
with RDM in a timely fashion. When a report is filed, each party involved will be able to write 
what happened and the victim will have access to the portion of the damage logs involving their 
death. The accused will not be able to write their side of the story until they die, or the round 
ends. The victim can view the accused's message and decide to forgive him or not. Admins will be able to veiw the report, along with any pertinent logs. As an admin, you can 
then take action against the participants. It is recommended that you discuss how the manager 
will work with your admins carefully, so that it isn't abused, or used incorrectly.]])
	rdm_manager:SetTextColor(Color(0,0,0))
	rdm_manager:SetPos(10, 35)
	rdm_manager:SizeToContents()	

	local credits_title = vgui.Create("DLabel", panel)
	credits_title:SetFont("DL_About_Title")
	credits_title:SetText("Credits")
	credits_title:SetTextColor(Color(0,0,0))
	credits_title:SetPos(10, 170)
	credits_title:SizeToContents()
	
	local credits = vgui.Create("DLabel", panel)
	credits:SetFont("DL_About_Text")
	credits:SetText([[-Tommy228 for coding the menu.
-Azarym, Hobbes and Pandaman09 for their help.
-Short Circuit for fixing a few grammatical and spelling mistakes out of OCD.]])
	credits:SetTextColor(Color(0,0,0))
	credits:SetPos(10, 195)
	credits:SizeToContents()
		
	self.Tabs:AddSheet("About", panel, "icon16/information.png", false, false)

end
