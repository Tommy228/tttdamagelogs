surface.CreateFont("DL_RDM_Manager", {
	font = "DermaLarge",
	size = 20
})

surface.CreateFont("DL_Conclusion", {
	font = "DermaLarge",
	size = 18,
	weight = 600
})

surface.CreateFont("DL_ConclusionText", {
	font = "DermaLarge",
	size = 18
})

surface.CreateFont("DL_ResponseDisabled", {
	font = "DermaLarge",
	size = 16
})

local color_trablack = Color(0, 0, 0, 240)
local mode = Damagelog.ULX_AutoslayMode

local function AdjustText(str, font, w)
	surface.SetFont(font)
	local size = surface.GetTextSize(str)

	if size <= w then
		return str
	else
		local last_space
		local i = 0

		for k, v in pairs(string.ToTable(str)) do
			local _w = surface.GetTextSize(v)
			i = i + _w

			if i > w then
				local sep = last_space or k

				return string.Left(str, sep), string.Right(str, #str - sep)
			end

			if v == " " then
				last_space = k
			end
		end
	end
end

local show_finished = CreateClientConVar("rdm_manager_show_finished", "1", FCVAR_ARCHIVE)

cvars.AddChangeCallback("rdm_manager_show_finished", function(name, old, new)
	if IsValid(Damagelog.CurrentReports) then
		Damagelog.CurrentReports:UpdateAllReports()
	end

	if IsValid(Damagelog.PreviousReports) then
		Damagelog.PreviousReports:UpdateAllReports()
	end
end)

local status = {
	[RDM_MANAGER_WAITING] = TTTLogTranslate(GetDMGLogLang, "RDMWaiting"),
	[RDM_MANAGER_PROGRESS] = TTTLogTranslate(GetDMGLogLang, "RDMInProgress"),
	[RDM_MANAGER_FINISHED] = TTTLogTranslate(GetDMGLogLang, "RDMFinished")
}

RDM_MANAGER_STATUS = status

local icons = {
	[RDM_MANAGER_WAITING] = "icon16/clock.png",
	[RDM_MANAGER_PROGRESS] = "icon16/arrow_refresh.png",
	[RDM_MANAGER_FINISHED] = "icon16/accept.png"
}

RDM_MANAGER_ICONS = icons

local colors = {
	[RDM_MANAGER_PROGRESS] = Color(0, 0, 190),
	[RDM_MANAGER_FINISHED] = Color(0, 190, 0),
	[RDM_MANAGER_WAITING] = Color(100, 100, 100)
}

local function TakeAction()
	local report = Damagelog.SelectedReport
	if not report then return end
	local current = not report.previous
	local attacker = player.GetBySteamID(report.attacker)
	local victim = player.GetBySteamID(report.victim)
	local menuPanel = DermaMenu()

	menuPanel:AddOption(TTTLogTranslate(GetDMGLogLang, "RDMSetConclusion"), function()
		Derma_StringRequest(TTTLogTranslate(GetDMGLogLang, "RDMConclusion"), TTTLogTranslate(GetDMGLogLang, "RDMWriteConclusion"), "", function(txt)
			if #txt > 0 and #txt < 200 then
				net.Start("DL_Conclusion")
				net.WriteUInt(0, 1)
				net.WriteUInt(report.previous and 1 or 0, 1)
				net.WriteUInt(report.index, 16)
				net.WriteString(txt)
				net.SendToServer()
			end
		end)
	end):SetImage("icon16/comment.png")

	if not report.response then
		menuPanel:AddOption(TTTLogTranslate(GetDMGLogLang, "RDMForceRespond"), function()
			if IsValid(attacker) then
				net.Start("DL_ForceRespond")
				net.WriteUInt(report.index, 16)
				net.WriteUInt(current and 0 or 1, 1)
				net.SendToServer()
			else
				Derma_Message(TTTLogTranslate(GetDMGLogLang, "RDMNotValid"), TTTLogTranslate(GetDMGLogLang, "Error"), "OK")
			end
		end):SetImage("icon16/clock_red.png")
	end

	if not report.previous then

		if not report.chat_open then

			menuPanel:AddOption(report.chat_opened and TTTLogTranslate(GetDMGLogLang, "ViewChat") or TTTLogTranslate(GetDMGLogLang, "OpenChat"), function()
				if not report.chat_opened then
					net.Start("DL_StartChat")
					net.WriteUInt(report.index, 32)
					net.SendToServer()

					if not report.response then
						Damagelog.DisableResponse(true)
					end

					if report.status == RDM_MANAGER_WAITING then
						net.Start("DL_UpdateStatus")
						net.WriteUInt(report.previous and 1 or 0, 1)
						net.WriteUInt(report.index, 16)
						net.WriteUInt(RDM_MANAGER_PROGRESS, 4)
						net.SendToServer()
					end

				else
					net.Start("DL_ViewChat")
					net.WriteUInt(report.index, 32)
					net.SendToServer()					
				end
			end):SetImage("icon16/application_view_list.png")

		else

			menuPanel:AddOption(TTTLogTranslate(GetDMGLogLang, "JoinChat"), function()
				net.Start("DL_JoinChat")
				net.WriteUInt(report.index, 32)
				net.SendToServer()
			end):SetImage("icon16/application_go.png")

		end

	end

	menuPanel:AddOption(TTTLogTranslate(GetDMGLogLang, "RDMDeathScene"), function()
		local found = false
		local roles = Damagelog.Roles[report.round]
		local victimID = util.SteamIDTo64(report.victim)
		local attackerID = util.SteamIDTo64(report.attacker)
		for k, v in pairs(report.logs or {}) do
			if IsValid(Damagelog.events[v.id]) and Damagelog.events[v.id].type == "KILL" then
				local infos = v.infos
				local ent = Damagelog:InfoFromID(roles, infos[1])
				local att = Damagelog:InfoFromID(roles, infos[2])
				if ent.steamid64 == victimID and att.steamid64 == attackerID then
					net.Start("DL_AskDeathScene")
					net.WriteUInt(infos[4], 32)
					net.WriteUInt(infos[2], 32)
					net.WriteUInt(infos[1], 32)
					net.WriteString(report.attacker)
					net.SendToServer()
					found = true
					break
				end
			end
		end
		if not found then
			Derma_Message(TTTLogTranslate(GetDMGLogLang, "DeathSceneNotFound"), TTTLogTranslate(GetDMGLogLang, "Error"), "OK")
		end
	end):SetImage("icon16/television.png")

	if serverguard or ulx then
	
		if serverguard or (ulx and (mode == 1 or mode == 2)) then
			local function SetConclusion(ply, num, reason)
				net.Start("DL_Conclusion")
				net.WriteUInt(1, 1)
				net.WriteUInt(report.previous and 1 or 0, 1)
				net.WriteUInt(report.index, 16)
				net.WriteString("("..TTTLogTranslate(DMGLogLang, "Automatic")..") " .. ply .. (mode == 1 and " autoslain " or " autojailed ") .. num .. " times for " .. reason .. ".")
				net.SendToServer()
			end
			
			local slaynr_pnl = vgui.Create("DMenuOption", menuPanel)
			local slaynr = DermaMenu(menuPanel)
			slaynr:SetVisible(false)
			slaynr_pnl:SetSubMenu(slaynr)
			local txt = "Slay next round"
			if ulx and mode == 2 then
				txt = "Jail next round"
			end
			slaynr_pnl:SetText(txt)
			slaynr_pnl:SetImage("icon16/lightning_go.png")
			menuPanel:AddPanel(slaynr_pnl)
			slaynr:AddOption("Reported player", function()
				slaytyp = report.attacker_nick
				slaytypiger = "atta"
				RDMslay()
			end):SetImage("icon16/user_delete.png")
			slaynr:AddOption("Victim", function()
				slaytyp = report.victim_nick
				slaytypiger = "vict"
				RDMslay()
			end):SetImage("icon16/user.png")
			function RDMslay()
				local DermaPanel = vgui.Create( "DFrame" )
				local weite = 500
				local hoehe = 260
				local abstand = 25
				local groesse = 240
				local rdm1 = Damagelog.Autoslay_DefaultReason1
				local rdm2 = Damagelog.Autoslay_DefaultReason2
				local rdm3 = Damagelog.Autoslay_DefaultReason3
				local rdm4 = Damagelog.Autoslay_DefaultReason4
				local rdm5 = Damagelog.Autoslay_DefaultReason5
				local rdm6 = Damagelog.Autoslay_DefaultReason6
				local rdm7 = Damagelog.Autoslay_DefaultReason7
				local rdm8 = Damagelog.Autoslay_DefaultReason8
				local rdm9 = Damagelog.Autoslay_DefaultReason9
				local rdm10 = Damagelog.Autoslay_DefaultReason10
				local rdm11 = Damagelog.Autoslay_DefaultReason11
				local rdm12 = Damagelog.Autoslay_DefaultReason12
				DermaPanel:SetPos( ScrW()/2-weite/2,ScrH()/2-hoehe/2 )
				DermaPanel:SetSize( weite, hoehe )
				if ulx and mode == 2 then
					DermaPanel:SetTitle( "Jailing" )
				else
					DermaPanel:SetTitle( "Slaying" )
				end
				DermaPanel:SetVisible( true )
				DermaPanel:SetDraggable( true )
				DermaPanel:ShowCloseButton( true )
				DermaPanel:MakePopup()
				 
				DermaList = vgui.Create( "DPanelList", DermaPanel )
				DermaList:SetPos( abstand/2,abstand*1.5)
				DermaList:SetSize( groesse, groesse/3 )
				DermaList:SetSpacing( 5 )
				DermaList:EnableHorizontal( false )
				DermaList:EnableVerticalScrollbar( true )
				
				 
					local one_slay = vgui.Create( "DCheckBoxLabel" )
					one_slay:SetText( "1 slay" )
					one_slay:SetValue( 1 )
					one_slay:SizeToContents()
				DermaList:AddItem( one_slay )
				 
					local two_slay = vgui.Create( "DCheckBoxLabel" )
					two_slay:SetText( "2 slays" )
					two_slay:SetValue( 0 )
					two_slay:SizeToContents()
				DermaList:AddItem( two_slay )
				 
					local three_slay = vgui.Create( "DCheckBoxLabel" )
					three_slay:SetText( "3 slays" )
					three_slay:SetValue( 0 )
					three_slay:SizeToContents()
				DermaList:AddItem( three_slay )
				
				anzahl = 1
				
				local DLabel = vgui.Create( "DLabel", DermaPanel )
				DLabel:SetPos( abstand/2 + 5, groesse/2.5 + 65 )
				DLabel:SetSize( abstand * 4.65 , 25 )
				DLabel:SetText( "1" )
				
				function one_slay:OnChange( val1 )
					if val1 then
						two_slay:SetValue(0)
						three_slay:SetValue(0)
						anzahl = 1
						DLabel:SetText( anzahl )
					end
				end
				function two_slay:OnChange( val1 )
					if val1 then
						one_slay:SetValue(0)
						three_slay:SetValue(0)
						anzahl = 2
						DLabel:SetText( anzahl )
					end
				end
				function three_slay:OnChange( val1 )
					if val1 then
						two_slay:SetValue(0)
						one_slay:SetValue(0)
						anzahl = 3
						DLabel:SetText( anzahl )
					end
				end
				
				DermaList = vgui.Create( "DPanelList", DermaPanel )
				DermaList:SetPos( abstand/2 + groesse/2,abstand*1.5)
				DermaList:SetSize( groesse, groesse/2 )
				DermaList:SetSpacing( 5 )
				DermaList:EnableHorizontal( false )
				DermaList:EnableVerticalScrollbar( true )
				 
					local rdmr_1 = vgui.Create( "DCheckBoxLabel" )
					rdmr_1:SetText( rdm1 )
					rdmr_1:SetValue( 0 )
					rdmr_1:SizeToContents()
				DermaList:AddItem( rdmr_1 )
				
				
					local rdmr_2 = vgui.Create( "DCheckBoxLabel" )
					rdmr_2:SetText( rdm2 )
					rdmr_2:SetValue( 0 )
					rdmr_2:SizeToContents()
				DermaList:AddItem( rdmr_2 )
				 
					local rdmr_3 = vgui.Create( "DCheckBoxLabel" )
					rdmr_3:SetText( rdm3 )
					rdmr_3:SetValue( 0 )
					rdmr_3:SizeToContents()
				DermaList:AddItem( rdmr_3 )
				 
					local rdmr_4 = vgui.Create( "DCheckBoxLabel" )
					rdmr_4:SetText( rdm4 )
					rdmr_4:SetValue( 0 )
					rdmr_4:SizeToContents()
				DermaList:AddItem( rdmr_4 )
				 
					local rdmr_5 = vgui.Create( "DCheckBoxLabel" )
					rdmr_5:SetText( rdm5 )
					rdmr_5:SetValue( 0 )
					rdmr_5:SizeToContents()
				DermaList:AddItem( rdmr_5 )
				
					local rdmr_6 = vgui.Create( "DCheckBoxLabel" )
					rdmr_6:SetText( rdm6 )
					rdmr_6:SetValue( 0 )
					rdmr_6:SizeToContents()
				DermaList:AddItem( rdmr_6 )
				
				DermaList = vgui.Create( "DPanelList", DermaPanel )
				DermaList:SetPos( abstand + groesse * 1.25, abstand*1.5)
				DermaList:SetSize( groesse, groesse/2 )
				DermaList:SetSpacing( 5 )
				DermaList:EnableHorizontal( false )
				DermaList:EnableVerticalScrollbar( true )
				 
				 
					local rdmr_7 = vgui.Create( "DCheckBoxLabel" )
					rdmr_7:SetText( rdm7 )
					rdmr_7:SetValue( 0 )
					rdmr_7:SizeToContents()
				DermaList:AddItem( rdmr_7 )
				 
					local rdmr_8 = vgui.Create( "DCheckBoxLabel" )
					rdmr_8:SetText( rdm8 )
					rdmr_8:SetValue( 0 )
					rdmr_8:SizeToContents()
				DermaList:AddItem( rdmr_8 )
				 
					local rdmr_9 = vgui.Create( "DCheckBoxLabel" )
					rdmr_9:SetText( rdm9 )
					rdmr_9:SetValue( 0 )
					rdmr_9:SizeToContents()
				DermaList:AddItem( rdmr_9 )
				 
					local rdmr_10 = vgui.Create( "DCheckBoxLabel" )
					rdmr_10:SetText( rdm10 )
					rdmr_10:SetValue( 0 )
					rdmr_10:SizeToContents()
				DermaList:AddItem( rdmr_10 )
				
					local rdmr_11 = vgui.Create( "DCheckBoxLabel" )
					rdmr_11:SetText( rdm11 )
					rdmr_11:SetValue( 0 )
					rdmr_11:SizeToContents()
				DermaList:AddItem( rdmr_11 )
				
					local rdmr_12 = vgui.Create( "DCheckBoxLabel" )
					rdmr_12:SetText( rdm12 )
					rdmr_12:SetValue( 0 )
					rdmr_12:SizeToContents()
				DermaList:AddItem( rdmr_12 )
				
				
				reasonhauraus = true
				local DermaACheckbox = vgui.Create( "DCheckBox", DermaPanel )
				DermaACheckbox:SetPos( abstand/2 + groesse/2 ,groesse*2/3 + 5)
				DermaACheckbox:SetValue( 1 )
				function DermaACheckbox:OnChange( reasonjanein )
					if reasonjanein then
						reasonhauraus = true
						reasonupdate()
					else
						reasonhauraus = false
						reasonupdate()
					end
				end
				
				local Shape = vgui.Create( "DShape", DermaPanel )
				Shape:SetType( "Rect" )
				Shape:SetPos( abstand/2 + groesse/2 - 10 ,abstand*1.5 - 5)
				Shape:SetColor( Color( 255, 255, 255, 255 ) )
				Shape:SetSize( 1, groesse*2/3 )
				
				local Shape = vgui.Create( "DShape", DermaPanel )
				Shape:SetType( "Rect" )
				Shape:SetPos( abstand/2 - 5, groesse/2.5 + 5)
				Shape:SetColor( Color( 255, 255, 255, 255 ) )
				Shape:SetSize( abstand * 4.65 , 1 )
				
				local Shape = vgui.Create( "DShape", DermaPanel )
				Shape:SetType( "Rect" )
				Shape:SetPos( abstand/2 - 5, groesse*2/3 + 31 )
				Shape:SetColor( Color( 255, 255, 255, 255 ) )
				Shape:SetSize( weite*23/24 + 5, 1 )
				
				local DLabel = vgui.Create( "DLabel", DermaPanel )
				DLabel:SetPos( abstand/2, groesse/2.5 + 5 )
				DLabel:SetSize( abstand * 4.65 , 25 )
				DLabel:SetText( "You are going to slay" )
				
				local DLabel = vgui.Create( "DLabel", DermaPanel )
				DLabel:SetPos( abstand/2 + 5, groesse/2.5 + 25 )
				DLabel:SetSize( abstand * 4.65 - 15, 25 )
				DLabel:SetText( slaytyp )
				
				local DLabel = vgui.Create( "DLabel", DermaPanel )
				DLabel:SetPos( abstand/2, groesse/2.5 + 45 )
				DLabel:SetSize( abstand * 4.65 , 25 )
				DLabel:SetText( "this often:" )
				
				local DLabelr = vgui.Create( "DLabel", DermaPanel )
				DLabelr:SetPos( abstand/2,groesse*2/3 + 31)				
				DLabelr:SetSize( weite - abstand/2, 30 )	
				DLabelr:SetText( "Reason: " )
				
				res1 = false
				res2 = false
				res3 = false
				res4 = false
				res5 = false
				res6 = false
				res7 = false
				res8 = false
				res9 = false
				res10 = false
				res11 = false
				res12 = false
				
				function rdmr_1:OnChange( rees1 )
					if rees1 then
						res1 = true
					else
						res1 = false
					end
					reasonupdate()
				end
				
				function rdmr_2:OnChange( rees2 )
					if rees2 then
						res2 = true
					else
						res2 = false
					end
					reasonupdate()
				end
				
				function rdmr_3:OnChange( rees3 )
					if rees3 then
						res3 = true
					else
						res3 = false
					end
					reasonupdate()
				end
				
				function rdmr_4:OnChange( rees4 )
					if rees4 then
						res4 = true
					else
						res4 = false
					end
					reasonupdate()
				end
				
				function rdmr_5:OnChange( rees5 )
					if rees5 then
						res5 = true
					else
						res5 = false
					end
					reasonupdate()
				end
				
				function rdmr_6:OnChange( rees6 )
					if rees6 then
						res6 = true
					else
						res6 = false
					end
					reasonupdate()
				end
				
				function rdmr_7:OnChange( rees7 )
					if rees7 then
						res7 = true
					else
						res7 = false
					end
					reasonupdate()
				end
				
				function rdmr_8:OnChange( rees8 )
					if rees8 then
						res8 = true
					else
						res8 = false
					end
					reasonupdate()
				end
				
				function rdmr_9:OnChange( rees9 )
					if rees9 then
						res9 = true
					else
						res9 = false
					end
					reasonupdate()
				end
				
				function rdmr_10:OnChange( rees10 )
					if rees10 then
						res10 = true
					else
						res10 = false
					end
					reasonupdate()
				end
				
				function rdmr_11:OnChange( rees11 )
					if rees11 then
						res11 = true
					else
						res11 = false
					end
					reasonupdate()
				end
				
				function rdmr_12:OnChange( rees12 )
					if rees12 then
						res12 = true
					else
						res12 = false
					end
					reasonupdate()
				end
				
				changed = false
				
				local TexwtEntry = vgui.Create( "DTextEntry", DermaPanel )
				TexwtEntry:SetPos( abstand/2 + groesse/2 + 25 ,groesse*2/3)
				TexwtEntry:SetSize( groesse*1.5 - 35, 25 )
				TexwtEntry:SetText( "another reason" )
				TexwtEntry.OnEnter = function( self )
					postings()
				end
				textreason = ""
				function TexwtEntry:OnChange()
					changed = true
					reasonupdate()
				end
				
				function reasonupdate()
					reason5 = "Reason: "
					if res1 then
						reason5 = "Reason: "..rdm1
					end
					if res2 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm2
						else
							reason5 = reason5.." + " ..rdm2
						end
					end 
					if res3 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm3
						else
							reason5 = reason5.." + " ..rdm3
						end
					end 
					if res4 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm4
						else
							reason5 = reason5.." + " ..rdm4
						end
					end 
					if res5 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm5
						else
							reason5 = reason5.." + " ..rdm5
						end
					end 
					if res6 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm6
						else
							reason5 = reason5.." + " ..rdm6
						end
					end 
					if res7 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm7
						else
							reason5 = reason5.." + " ..rdm7
						end
					end 
					if res8 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm8
						else
							reason5 = reason5.." + " ..rdm8
						end
					end 
					if res9 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm9
						else
							reason5 = reason5.." + " ..rdm9
						end
					end 
					if res10 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm10
						else
							reason5 = reason5.." + " ..rdm10
						end
					end 
					if res11 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm11
						else
							reason5 = reason5.." + " ..rdm11
						end
					end 
					if res12 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm12
						else
							reason5 = reason5.." + " ..rdm12
						end
					end 
					if reasonhauraus then
						if changed then
							if reason5 == "Reason: " then
								reason5 = "Reason: "..TexwtEntry:GetValue()
							else
								reason5 = reason5.." + " ..TexwtEntry:GetValue()
							end
						end
					end
					DLabelr:SetText(reason5)
					reason5 = "Reason: "
				end
				
				function postings()
					reason4 = " "
					if res1 then
						reason4 = rdm1
					end
					if res2 then
						if reason4 == " " then
							reason4 = rdm2
						else
							reason4 = reason4.." + " ..rdm2
						end
					end 
					if res3 then
						if reason4 == " " then
							reason4 = rdm3
						else
							reason4 = reason4.." + " ..rdm3
						end
					end 
					if res4 then
						if reason4 == " " then
							reason4 = rdm4
						else
							reason4 = reason4.." + " ..rdm4
						end
					end 
					if res5 then
						if reason4 == " " then
							reason4 = rdm5
						else
							reason4 = reason4.." + " ..rdm5
						end
					end 
					if res6 then
						if reason4 == " " then
							reason4 = rdm6
						else
							reason4 = reason4.." + " ..rdm6
						end
					end 
					if res7 then
						if reason4 == " " then
							reason4 = rdm7
						else
							reason4 = reason4.." + " ..rdm7
						end
					end 
					if res8 then
						if reason4 == " " then
							reason4 = rdm8
						else
							reason4 = reason4.." + " ..rdm8
						end
					end 
					if res9 then
						if reason4 == " " then
							reason4 = rdm9
						else
							reason4 = reason4.." + " ..rdm9
						end
					end 
					if res10 then
						if reason4 == " " then
							reason4 = rdm10
						else
							reason4 = reason4.." + " ..rdm10
						end
					end 
					if res11 then
						if reason4 == " " then
							reason4 = rdm11
						else
							reason4 = reason4.." + " ..rdm11
						end
					end 
					if res12 then
						if reason4 == " " then
							reason4 = rdm12
						else
							reason4 = reason4.." + " ..rdm12
						end
					end 
					if reasonhauraus then
						if changed then
							if reason4 == " " then
								reason4 = TexwtEntry:GetValue()
							else
								reason4 = reason4.." + " ..TexwtEntry:GetValue()
							end
						end
					end
					if slaytypiger == "atta" then
						local ply = attacker
						local plyid = report.attacker
					elseif slaytypiger == "vict" then
						local ply = victim
						local plyid = report.victim
					end
					if IsValid(ply) then
						if ulx then
							RunConsoleCommand("ulx", mode == 1 and "aslay" or "ajail", slaytyp, anzahl, reason4)
						else
							serverguard.command.Run("aslay", false, slaytyp, anzahl, reason4)
						end
						SetConclusion(slaytyp, anzahl, reason4)
					else
						if ulx then
							RunConsoleCommand("ulx", mode == 1 and "aslayid" or "ajailid", plyid, anzahl, reason4)
							SetConclusion(slaytyp, anzahl, reason4)
						else
							Damagelog:Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(GetDMGLogLang, "VictimReportedDisconnected"), 2, "buttons/weapon_cant_buy.wav")
						end
					end
					reason4 = " "
					DermaPanel:Close()
				end
				
				local DermaButton = vgui.Create( "DButton" )	
				DermaButton:SetParent( DermaPanel )
				if ulx and mode == 2 then
					DermaButton:SetText( "ajail!" )	
				else
					DermaButton:SetText( "aslay!" )	
				end							 
				DermaButton:SetPos( abstand/4,groesse*2/3 + 60)				
				DermaButton:SetSize( weite - abstand/2 , 30 )				 
				DermaButton.DoClick = function()			 
					postings()			
				end
			end
		end
		
		menuPanel:AddOption("Slay the reported player now", function()
			if IsValid(attacker) then
				if ulx then
					RunConsoleCommand("ulx", "slay", attacker:Nick())
				else
					serverguard.command.Run("slay", false, ply:Nick())
				end
			else
				Damagelog:Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(GetDMGLogLang, "RDMNotValid"), 2, "buttons/weapon_cant_buy.wav")
			end
		end):SetImage("icon16/lightning.png")
		
		local slaynr_pnl = vgui.Create("DMenuOption", menuPanel)
			local slaynr = DermaMenu(menuPanel)
			slaynr:SetVisible(false)
			slaynr_pnl:SetSubMenu(slaynr)
			slaynr_pnl:SetText("Send message to")
			slaynr_pnl:SetImage("icon16/user_edit.png")
			menuPanel:AddPanel(slaynr_pnl)
			slaynr:AddOption("Reported player", function()
				if IsValid(attacker) then
					Derma_StringRequest("private message", "What would you like to say to "..attacker:Nick().."?", "", function(nachricht)
						if ulx then
							RunConsoleCommand("ulx", "psay", attacker:Nick(), Damagelog.PrivateMessagePrefix.." "..nachricht)
						else
							--[[add serverguard private message-command here
							variables:
							playername: attacker:Nick()
							message: Damagelog.PrivateMessagePrefix.." "..nachricht
							]]
						end
					end)
				else
					Damagelog:Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(GetDMGLogLang, "VictimReportedDisconnected"), 2, "buttons/weapon_cant_buy.wav")
				end
			end):SetImage("icon16/user_delete.png")
			slaynr:AddOption("Victim", function()
				if IsValid(victim) then
					Derma_StringRequest("private message", "What would you like to say to "..victim:Nick().."?", "", function(nachricht)
						if ulx then
							RunConsoleCommand("ulx", "psay", victim:Nick(), Damagelog.PrivateMessagePrefix.." "..nachricht)
						else
							--[[add serverguard private message-command here
							variables:
							playername: victim:Nick()
							message: Damagelog.PrivateMessagePrefix.." "..nachricht
							]]
						end
					end)
				else
					Damagelog:Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(GetDMGLogLang, "VictimReportedDisconnected"), 2, "buttons/weapon_cant_buy.wav")
				end
			end):SetImage("icon16/user.png")
		
		local slaynr_pnl = vgui.Create("DMenuOption", menuPanel)
			local slaynr = DermaMenu(menuPanel)
			slaynr:SetVisible(false)
			slaynr_pnl:SetSubMenu(slaynr)
			slaynr_pnl:SetText("Ban player")
			slaynr_pnl:SetImage("icon16/bomb.png")
			menuPanel:AddPanel(slaynr_pnl)
			slaynr:AddOption("Reported player", function()
				slaytyp2 = report.attacker_nick
				slaytypiger2 = "atta"
				baning()
			end):SetImage("icon16/user_delete.png")
			slaynr:AddOption("Victim", function()
				slaytyp2 = report.victim_nick
				slaytypiger2 = "vict"
				baning()
			end):SetImage("icon16/user.png")
			local function SetConclusion2(ply, num, reason)
				net.Start("DL_Conclusion")
				net.WriteUInt(1,1)
				net.WriteUInt(report.previous and 1 or 0, 1)
				net.WriteUInt(report.index, 16)
				net.WriteString("(Auto) "..ply.." banned "..num.." for "..reason..".")
				net.SendToServer()
			end
			function baning()
				local DermaPanel = vgui.Create( "DFrame" )
				local weite = 500
				local hoehe = 260
				local abstand = 25
				local groesse = 240
				local rdm1 = Damagelog.Ban_DefaultReason1
				local rdm2 = Damagelog.Ban_DefaultReason2
				local rdm3 = Damagelog.Ban_DefaultReason3
				local rdm4 = Damagelog.Ban_DefaultReason4
				local rdm5 = Damagelog.Ban_DefaultReason5
				local rdm6 = Damagelog.Ban_DefaultReason6
				local rdm7 = Damagelog.Ban_DefaultReason7
				local rdm8 = Damagelog.Ban_DefaultReason8
				local rdm9 = Damagelog.Ban_DefaultReason9
				local rdm10 = Damagelog.Ban_DefaultReason10
				local rdm11 = Damagelog.Ban_DefaultReason11
				local rdm12 = Damagelog.Ban_DefaultReason12
				DermaPanel:SetPos( ScrW()/2-weite/2,ScrH()/2-hoehe/2 )
				DermaPanel:SetSize( weite, hoehe )
				DermaPanel:SetTitle( "ban" )
				DermaPanel:SetVisible( true )
				DermaPanel:SetDraggable( true )
				DermaPanel:ShowCloseButton( true )
				DermaPanel:MakePopup()
				 
				DermaList = vgui.Create( "DPanelList", DermaPanel )
				DermaList:SetPos( abstand/2,abstand*1.5)
				DermaList:SetSize( groesse/3+20, groesse/3 )
				DermaList:SetSpacing( 5 )
				DermaList:EnableHorizontal( false )
				DermaList:EnableVerticalScrollbar( true )
				
				local laeng = vgui.Create( "DTextEntry", DermaPanel )
				laeng:SetSize(40/3.5,20)
				laeng:SetText( "0" )
				DermaList:AddItem( laeng )
				 
					local one_slay = vgui.Create( "DCheckBoxLabel" )
					one_slay:SetText( "hours" )
					one_slay:SetValue( 1 )
					one_slay:SizeToContents()
				DermaList:AddItem( one_slay )
				 
					local two_slay = vgui.Create( "DCheckBoxLabel" )
					two_slay:SetText( "days" )
					two_slay:SetValue( 0 )
					two_slay:SizeToContents()
				DermaList:AddItem( two_slay )
				 
					local three_slay = vgui.Create( "DCheckBoxLabel" )
					three_slay:SetText( "weeks" )
					three_slay:SetValue( 0 )
					three_slay:SizeToContents()
				DermaList:AddItem( three_slay )
				
				anzahl = "h"
				
				
				
				function one_slay:OnChange( val1 )
					if val1 then
						two_slay:SetValue(0)
						three_slay:SetValue(0)
						anzahl = "h"
					end
				end
				function two_slay:OnChange( val1 )
					if val1 then
						one_slay:SetValue(0)
						three_slay:SetValue(0)
						anzahl = "d"
					end
				end
				function three_slay:OnChange( val1 )
					if val1 then
						two_slay:SetValue(0)
						one_slay:SetValue(0)
						anzahl = "w"
					end
				end
				
				DermaList = vgui.Create( "DPanelList", DermaPanel )
				DermaList:SetPos( abstand/2 + groesse/2,abstand*1.5)
				DermaList:SetSize( groesse, groesse/2 )
				DermaList:SetSpacing( 5 )
				DermaList:EnableHorizontal( false )
				DermaList:EnableVerticalScrollbar( true )
				 
					local rdmr_1 = vgui.Create( "DCheckBoxLabel" )
					rdmr_1:SetText( rdm1 )
					rdmr_1:SetValue( 0 )
					rdmr_1:SizeToContents()
				DermaList:AddItem( rdmr_1 )
				
				
					local rdmr_2 = vgui.Create( "DCheckBoxLabel" )
					rdmr_2:SetText( rdm2 )
					rdmr_2:SetValue( 0 )
					rdmr_2:SizeToContents()
				DermaList:AddItem( rdmr_2 )
				 
					local rdmr_3 = vgui.Create( "DCheckBoxLabel" )
					rdmr_3:SetText( rdm3 )
					rdmr_3:SetValue( 0 )
					rdmr_3:SizeToContents()
				DermaList:AddItem( rdmr_3 )
				 
					local rdmr_4 = vgui.Create( "DCheckBoxLabel" )
					rdmr_4:SetText( rdm4 )
					rdmr_4:SetValue( 0 )
					rdmr_4:SizeToContents()
				DermaList:AddItem( rdmr_4 )
				 
					local rdmr_5 = vgui.Create( "DCheckBoxLabel" )
					rdmr_5:SetText( rdm5 )
					rdmr_5:SetValue( 0 )
					rdmr_5:SizeToContents()
				DermaList:AddItem( rdmr_5 )
				
					local rdmr_6 = vgui.Create( "DCheckBoxLabel" )
					rdmr_6:SetText( rdm6 )
					rdmr_6:SetValue( 0 )
					rdmr_6:SizeToContents()
				DermaList:AddItem( rdmr_6 )
				
				DermaList = vgui.Create( "DPanelList", DermaPanel )
				DermaList:SetPos( abstand + groesse * 1.25, abstand*1.5)
				DermaList:SetSize( groesse, groesse/2 )
				DermaList:SetSpacing( 5 )
				DermaList:EnableHorizontal( false )
				DermaList:EnableVerticalScrollbar( true )
				 
				 
					local rdmr_7 = vgui.Create( "DCheckBoxLabel" )
					rdmr_7:SetText( rdm7 )
					rdmr_7:SetValue( 0 )
					rdmr_7:SizeToContents()
				DermaList:AddItem( rdmr_7 )
				 
					local rdmr_8 = vgui.Create( "DCheckBoxLabel" )
					rdmr_8:SetText( rdm8 )
					rdmr_8:SetValue( 0 )
					rdmr_8:SizeToContents()
				DermaList:AddItem( rdmr_8 )
				 
					local rdmr_9 = vgui.Create( "DCheckBoxLabel" )
					rdmr_9:SetText( rdm9 )
					rdmr_9:SetValue( 0 )
					rdmr_9:SizeToContents()
				DermaList:AddItem( rdmr_9 )
				 
					local rdmr_10 = vgui.Create( "DCheckBoxLabel" )
					rdmr_10:SetText( rdm10 )
					rdmr_10:SetValue( 0 )
					rdmr_10:SizeToContents()
				DermaList:AddItem( rdmr_10 )
				
					local rdmr_11 = vgui.Create( "DCheckBoxLabel" )
					rdmr_11:SetText( rdm11 )
					rdmr_11:SetValue( 0 )
					rdmr_11:SizeToContents()
				DermaList:AddItem( rdmr_11 )
				
					local rdmr_12 = vgui.Create( "DCheckBoxLabel" )
					rdmr_12:SetText( rdm12 )
					rdmr_12:SetValue( 0 )
					rdmr_12:SizeToContents()
				DermaList:AddItem( rdmr_12 )
				
				
				reasonhauraus = true
				local DermaACheckbox = vgui.Create( "DCheckBox", DermaPanel )
				DermaACheckbox:SetPos( abstand/2 + groesse/2 ,groesse*2/3 + 5)
				DermaACheckbox:SetValue( 1 )
				function DermaACheckbox:OnChange( reasonjanein )
					if reasonjanein then
						reasonhauraus = true
						reasonupdate2()
					else
						reasonhauraus = false
						reasonupdate2()
					end
				end

				local Shape = vgui.Create( "DShape", DermaPanel )
				Shape:SetType( "Rect" )
				Shape:SetPos( abstand/2 + groesse/2 - 10 ,abstand*1.5 - 5)
				Shape:SetColor( Color( 255, 255, 255, 255 ) )
				Shape:SetSize( 1, groesse*2/3 )
				
				local Shape = vgui.Create( "DShape", DermaPanel )
				Shape:SetType( "Rect" )
				Shape:SetPos( abstand/2 - 5, groesse/2.5 + 40)
				Shape:SetColor( Color( 255, 255, 255, 255 ) )
				Shape:SetSize( abstand * 4.65 , 1 )
				
				local Shape = vgui.Create( "DShape", DermaPanel )
				Shape:SetType( "Rect" )
				Shape:SetPos( abstand/2 - 5, groesse*2/3 + 31 )
				Shape:SetColor( Color( 255, 255, 255, 255 ) )
				Shape:SetSize( weite*23/24 + 5, 1 )
				
				local DLabel = vgui.Create( "DLabel", DermaPanel )
				DLabel:SetPos( abstand/2, groesse/2.5 + 45 )
				DLabel:SetSize( abstand * 4.65 , 25 )
				DLabel:SetText( "You're going to ban" )
				
				local DLabel = vgui.Create( "DLabel", DermaPanel )
				DLabel:SetPos( abstand/2 + 5, groesse/2.5 + 65 )
				DLabel:SetSize( abstand * 4.65 - 15, 25 )
				DLabel:SetText( slaytyp2 )
				
				local DLabelr = vgui.Create( "DLabel", DermaPanel )
				DLabelr:SetPos( abstand/2,groesse*2/3 + 31)				
				DLabelr:SetSize( weite - abstand/2, 30 )	
				DLabelr:SetText( "Reason: " )
				
				res1 = false
				res2 = false
				res3 = false
				res4 = false
				res5 = false
				res6 = false
				res7 = false
				res8 = false
				res9 = false
				res10 = false
				res11 = false
				res12 = false
				
				function rdmr_1:OnChange( rees1 )
					if rees1 then
						res1 = true
					else
						res1 = false
					end
					reasonupdate2()
				end
				
				function rdmr_2:OnChange( rees2 )
					if rees2 then
						res2 = true
					else
						res2 = false
					end
					reasonupdate2()
				end
				
				function rdmr_3:OnChange( rees3 )
					if rees3 then
						res3 = true
					else
						res3 = false
					end
					reasonupdate2()
				end
				
				function rdmr_4:OnChange( rees4 )
					if rees4 then
						res4 = true
					else
						res4 = false
					end
					reasonupdate2()
				end
				
				function rdmr_5:OnChange( rees5 )
					if rees5 then
						res5 = true
					else
						res5 = false
					end
					reasonupdate2()
				end
				
				function rdmr_6:OnChange( rees6 )
					if rees6 then
						res6 = true
					else
						res6 = false
					end
					reasonupdate2()
				end
				
				function rdmr_7:OnChange( rees7 )
					if rees7 then
						res7 = true
					else
						res7 = false
					end
					reasonupdate2()
				end
				
				function rdmr_8:OnChange( rees8 )
					if rees8 then
						res8 = true
					else
						res8 = false
					end
					reasonupdate2()
				end
				
				function rdmr_9:OnChange( rees9 )
					if rees9 then
						res9 = true
					else
						res9 = false
					end
					reasonupdate2()
				end
				
				function rdmr_10:OnChange( rees10 )
					if rees10 then
						res10 = true
					else
						res10 = false
					end
					reasonupdate2()
				end
				
				function rdmr_11:OnChange( rees11 )
					if rees11 then
						res11 = true
					else
						res11 = false
					end
					reasonupdate2()
				end
				
				function rdmr_12:OnChange( rees12 )
					if rees12 then
						res12 = true
					else
						res12 = false
					end
					reasonupdate2()
				end
				
				changed = false
				
				local TexwtEntry = vgui.Create( "DTextEntry", DermaPanel )
				TexwtEntry:SetPos( abstand/2 + groesse/2 + 25,groesse*2/3)
				TexwtEntry:SetSize( groesse*1.5 - 35, 25 )
				TexwtEntry:SetText( "another reason" )
				TexwtEntry.OnEnter = function( self )
					postings2()
				end
				textreason = ""
				function TexwtEntry:OnChange()
					changed = true
					reasonupdate2()
				end
				
				function reasonupdate2()
					reason5 = "Reason: "
					if res1 then
						reason5 = "Reason: "..rdm1
					end
					if res2 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm2
						else
							reason5 = reason5.." + " ..rdm2
						end
					end 
					if res3 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm3
						else
							reason5 = reason5.." + " ..rdm3
						end
					end 
					if res4 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm4
						else
							reason5 = reason5.." + " ..rdm4
						end
					end 
					if res5 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm5
						else
							reason5 = reason5.." + " ..rdm5
						end
					end 
					if res6 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm6
						else
							reason5 = reason5.." + " ..rdm6
						end
					end 
					if res7 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm7
						else
							reason5 = reason5.." + " ..rdm7
						end
					end 
					if res8 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm8
						else
							reason5 = reason5.." + " ..rdm8
						end
					end 
					if res9 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm9
						else
							reason5 = reason5.." + " ..rdm9
						end
					end 
					if res10 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm10
						else
							reason5 = reason5.." + " ..rdm10
						end
					end 
					if res11 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm11
						else
							reason5 = reason5.." + " ..rdm11
						end
					end 
					if res12 then
						if reason5 == "Reason: " then
							reason5 = "Reason: "..rdm12
						else
							reason5 = reason5.." + " ..rdm12
						end
					end 
					if reasonhauraus then
						if changed then
							if reason5 == "Reason: " then
								reason5 = "Reason: "..TexwtEntry:GetValue()
							else
								reason5 = reason5.." + " ..TexwtEntry:GetValue()
							end
						end
					end
					DLabelr:SetText(reason5)
					reason5 = "Reason: "
				end
				
				function postings2()
					reason4 = " "
					if res1 then
						reason4 = rdm1
					end
					if res2 then
						if reason4 == " " then
							reason4 = rdm2
						else
							reason4 = reason4.." + " ..rdm2
						end
					end 
					if res3 then
						if reason4 == " " then
							reason4 = rdm3
						else
							reason4 = reason4.." + " ..rdm3
						end
					end 
					if res4 then
						if reason4 == " " then
							reason4 = rdm4
						else
							reason4 = reason4.." + " ..rdm4
						end
					end 
					if res5 then
						if reason4 == " " then
							reason4 = rdm5
						else
							reason4 = reason4.." + " ..rdm5
						end
					end 
					if res6 then
						if reason4 == " " then
							reason4 = rdm6
						else
							reason4 = reason4.." + " ..rdm6
						end
					end 
					if res7 then
						if reason4 == " " then
							reason4 = rdm7
						else
							reason4 = reason4.." + " ..rdm7
						end
					end 
					if res8 then
						if reason4 == " " then
							reason4 = rdm8
						else
							reason4 = reason4.." + " ..rdm8
						end
					end 
					if res9 then
						if reason4 == " " then
							reason4 = rdm9
						else
							reason4 = reason4.." + " ..rdm9
						end
					end 
					if res10 then
						if reason4 == " " then
							reason4 = rdm10
						else
							reason4 = reason4.." + " ..rdm10
						end
					end 
					if res11 then
						if reason4 == " " then
							reason4 = rdm11
						else
							reason4 = reason4.." + " ..rdm11
						end
					end 
					if res12 then
						if reason4 == " " then
							reason4 = rdm12
						else
							reason4 = reason4.." + " ..rdm12
						end
					end 
					if reasonhauraus then
						if changed then
							if reason4 == " " then
								reason4 = TexwtEntry:GetValue()
							else
								reason4 = reason4.." + " ..TexwtEntry:GetValue()
							end
						end
					end
					
					if slaytypiger2 == "atta" then
						play = attacker
						play2 = report.attacker
					elseif slaytypiger2 == "vict" then
						play = victim
						play2 = report.victim
					end
					
					if IsValid(play) then
						if ulx then
							LocalPlayer():ConCommand('ulx ban "'..slaytyp2..'" '..laeng:GetValue()..''..anzahl..' '..reason4)
						else
							--[[add serverguard ban-command here
							variables:
							playername: slaytyp2
							reason: reason4
							lenght: laeng:GetValue()..''..anzahl
							]]
						end
					else
						if ulx then
							LocalPlayer():ConCommand("ulx banid "..play2.." "..laeng:GetValue()..""..anzahl.." "..reason4)
						else
							--[[add serverguard banid-command here
							variables:
							steamid: play2
							reason: reason4
							lenght: laeng:GetValue()..''..anzahl
							]]
						end
					end
					if tostring(laeng:GetValue()) == "0" then
						SetConclusion2(slaytyp2, "permanently", reason4)
					else
						SetConclusion2(slaytyp2, "for "..laeng:GetValue()..""..anzahl, reason4)
					end
					reason4 = " "
					DermaPanel:Close()
				end
				
				local DermaButton = vgui.Create( "DButton" )	
				DermaButton:SetParent( DermaPanel )			 
				DermaButton:SetText( "Ban!" )				 
				DermaButton:SetPos( abstand/4,groesse*2/3 + 60)				
				DermaButton:SetSize( weite - abstand/2 , 30 )				 
				DermaButton.DoClick = function()			 
					postings2()			
				end
			end
			
			local slaynr_pnl = vgui.Create("DMenuOption", menuPanel)
			local slaynr = DermaMenu(menuPanel)
			slaynr:SetVisible(false)
			slaynr_pnl:SetSubMenu(slaynr)
			local txt = "Remove autoslays of" 
			if ulx and mode == 2 then
				txt = "Remove autojails of"
			elseif serverguard then
				txt = "Remove 1 autoslay from"
			end
			slaynr_pnl:SetText(txt)
			slaynr_pnl:SetImage("icon16/cancel.png")
			menuPanel:AddPanel(slaynr_pnl)

			slaynr:AddOption("The reported player", function()
				if IsValid(attacker) then
					if ulx then
						RunConsoleCommand("ulx", mode == 1 and "aslay" or "ajail", attacker:Nick(), "0")
					else
						serverguard.command.Run("raslay", false, attacker:Nick())
					end
				else
					if ulx then
						RunConsoleCommand("ulx", mode == 1 and "aslayid" or "ajailid", report.attacker, "0")
					else
						Damagelog:Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(GetDMGLogLang, "VictimReportedDisconnected"), 2, "buttons/weapon_cant_buy.wav")
					end
				end
			end):SetImage("icon16/user_delete.png")

			slaynr:AddOption("The victim", function()
				if IsValid(victim) then
					if ulx then
						RunConsoleCommand("ulx", mode == 1 and "aslay" or "ajail", victim:Nick(), "0")
					else
						serverguard.command.Run("raslay", false, victim:Nick())
					end
				else
					if ulx then
						RunConsoleCommand("ulx", mode == 1 and "aslayid" or "ajailid", report.victim, "0")
					else
						Damagelog:Notify(DAMAGELOG_NOTIFY_ALERT, TTTLogTranslate(GetDMGLogLang, "VictimReportedDisconnected"), 2, "buttons/weapon_cant_buy.wav")
					end					
				end
			end):SetImage("icon16/user.png")
	end
	
	menuPanel:Open()
end
local PANEL = {}

function PANEL:Init()
	self:SetMultiSelect(false)
	self.IDWidth = 25
	self.VictimWidth = 105
	self.ReportedPlayerWidth = 105
	self.RoundWidth = 49
	self.ResponseStatusWidth = 110
	self.CanceledWidth = 55
	self.StatusWidth = 174
	self.CanceledPos = self.IDWidth + self.ReportedPlayerWidth + self.VictimWidth + self.RoundWidth + self.ResponseStatusWidth
	self:AddColumn("ID"):SetFixedWidth(self.IDWidth)
	self:AddColumn(TTTLogTranslate(GetDMGLogLang, "Victim")):SetFixedWidth(self.VictimWidth)
	self:AddColumn(TTTLogTranslate(GetDMGLogLang, "ReportedPlayer")):SetFixedWidth(self.ReportedPlayerWidth)
	self:AddColumn(TTTLogTranslate(GetDMGLogLang, "Round")):SetFixedWidth(self.RoundWidth)
	self:AddColumn(TTTLogTranslate(GetDMGLogLang, "ResponseStatus")):SetFixedWidth(self.ResponseStatusWidth)
	self:AddColumn(TTTLogTranslate(GetDMGLogLang, "Canceled")):SetFixedWidth(self.CanceledWidth)
	self:AddColumn(TTTLogTranslate(GetDMGLogLang, "Status")):SetFixedWidth(self.StatusWidth)
	self.Reports = {}
end

function PANEL:SetOuputs(victim, killer)
	self.VictimOutput = victim
	self.KillerOuput = killer
end

function PANEL:SetReportsTable(tbl)
	self.ReportsTable = tbl
end

function PANEL:GetStatus(report)
	local str = status[report.status]

	if report.status == RDM_MANAGER_FINISHED and report.autoStatus then
		str = TTTLogTranslate(GetDMGLogLang, "RDMManagerAuto").." "..str
	end	

	if (report.status == RDM_MANAGER_FINISHED or report.status == RDM_MANAGER_PROGRESS) and report.admin then
		str = str .. " " .. TTTLogTranslate(GetDMGLogLang, "By") .. " " .. report.admin
	end

	return str
end

function PANEL:UpdateReport(index)
	local report = self.ReportsTable[index]
	if not report then return end
	local str
	if report.chat_open then
		str = "Chat active"
	elseif report.chat_opened then
		str = "Chat opened"
	else
		str = report.response and TTTLogTranslate(GetDMGLogLang, "RDMResponded") or TTTLogTranslate(GetDMGLogLang, "RDMWaitingAttacker")
	end
	local tbl = { 
		report.index, 
		report.adminReport and "N/A (Admin Report)" or report.victim_nick, 
		report.attacker_nick, 
		report.round or "?", 
		str, 
		report.adminReport and "N/A" or "";
		self:GetStatus(report)
	}

	if not self.Reports[index] then
		if report.status != RDM_MANAGER_FINISHED or show_finished:GetBool() then
			self.Reports[index] = self:AddLine(unpack(tbl))
			self.Reports[index].status = report.status
			self.Reports[index].index = report.index
			local tbl = {self.Reports[index]}

			self.Reports[index].CanceledIcon = vgui.Create("DImage", self.Reports[index])
			self.Reports[index].CanceledIcon:SetSize(16, 16)
			self.Reports[index].CanceledIcon:SetImage(report.canceled and "icon16/tick.png" or "icon16/cross.png")
			self.Reports[index].CanceledIcon:SetPos(self.CanceledPos + self.CanceledWidth / 2 - 10)

			if report.adminReport then
				self.Reports[index].CanceledIcon:SetVisible(false)
			end

			for k, v in ipairs(self.Sorted) do
				if k == #self.Sorted then continue end
				table.insert(tbl, v)
			end

			self.Sorted = tbl
			self:InvalidateLayout()

			self.Reports[index].PaintOver = function(self)
				if self:IsLineSelected() then
					self.Columns[2]:SetTextColor(color_white)
					self.Columns[3]:SetTextColor(color_white)
					self.Columns[5]:SetTextColor(color_white)
					self.Columns[7]:SetTextColor(color_white)
				else
					self.Columns[2]:SetTextColor(report.adminReport and Color(190, 190, 0) or Color(0, 190, 0))
					self.Columns[3]:SetTextColor(Color(190, 0, 0))
					self.Columns[7]:SetTextColor(colors[report.status])

					if report.chat_open then
						self.Columns[5]:SetTextColor(Color(100 + math.abs(math.sin(CurTime()) * 155), 0, 0))
					else
						self.Columns[5]:SetTextColor(color_black)
					end
				end
			end

			self.Reports[index].OnRightClick = function(self)
				TakeAction()
			end
		else
			self.Reports[index] = false
		end
	else
		self.Reports[index].status = report.status
		self.Reports[index].index = report.index

		if report.status == RDM_MANAGER_FINISHED and not show_finished:GetBool() then
			return self:UpdateAllReports()
		else
			for k, v in ipairs(self.Reports[index].Columns) do
				self.Reports[index]:SetValue(k, tbl[k])
			end
		end

		self.Reports[index].CanceledIcon:SetImage(report.canceled and "icon16/tick.png" or "icon16/cross.png")

		if report.conclusion then
			local selected = Damagelog.SelectedReport

			if selected and selected.index == report.index and selected.previous == report.previous then
				self.Conclusion:SetText(report.conclusion)
			end
		end
	end

	return self.Reports[index]
end

function PANEL:AddReport(index)
	return self:UpdateReport(index)
end

function PANEL:UpdateAllReports()
	self:Clear()
	table.Empty(self.Reports)
	if not self.ReportsTable then return end

	for i = 1, #self.ReportsTable do
		self:AddReport(i)
	end

	if Damagelog.SelectedReport then
		local selected_current = not Damagelog.SelectedReport.Previous
		local current = not self.Previous

		if Damagelog.SelectedReport.status != RDM_MANAGER_FINISHED and not show_finished:GetBool() then
			for k, v in pairs(self.Lines) do
				v:SetSelected(false)
			end

			Damagelog.SelectedReport = nil
			Damagelog:UpdateReportTexts()
		elseif selected_current == current then
			for k, v in pairs(self.Lines) do
				if Damagelog.SelectedReport.index == v.index then
					v:SetSelected(true)
					break
				end
			end
		end

		if Damagelog.SelectedReport then
			local report = Damagelog.SelectedReport
			local conclusion = report.conclusion

			if conclusion then
				self.Conclusion:SetText(conclusion)
			else
				self.Conclusion:SetText(TTTLogTranslate(GetDMGLogLang, "NoConclusion"))
			end

			if not report.response and report.chat_opened then
				Damagelog.DisableResponse(true)
			else
				Damagelog.DisableResponse(false)
			end
		end

		Damagelog:UpdateReportTexts()
	end
end

function PANEL:OnRowSelected(index, line)
	Damagelog.SelectedReport = self.ReportsTable[line.index]
	Damagelog:UpdateReportTexts()
	local report = Damagelog.SelectedReport

	if not report.response and report.chat_opened then
		Damagelog.DisableResponse(true)
	else
		Damagelog.DisableResponse(false)
	end

	local conclusion = Damagelog.SelectedReport.conclusion

	if conclusion then
		self.Conclusion:SetText(conclusion)
	else
		self.Conclusion:SetText(TTTLogTranslate(GetDMGLogLang, "NoConclusion"))
	end

	if Damagelog.SelectedReport.previous then
		if Damagelog.CurrentReports:GetSelected()[1] then
			Damagelog.CurrentReports:GetSelected()[1]:SetSelected(false)
		end
	else
		if Damagelog.PreviousReports:GetSelected()[1] then
			Damagelog.PreviousReports:GetSelected()[1]:SetSelected(false)
		end
	end
end

vgui.Register("RDM_Manager_ListView", PANEL, "DListView")

net.Receive("DL_NewReport", function()
	local tbl = net.ReadTable()
	local index = table.insert(Damagelog.Reports.Current, tbl)
	Damagelog.Reports.Current[index].index = index

	if IsValid(Damagelog.CurrentReports) then
		Damagelog.CurrentReports:AddReport(index)
	end
end)

net.Receive("DL_UpdateReport", function()
	local previous = net.ReadUInt(1) == 1
	local index = net.ReadUInt(8)
	local updated = net.ReadTable()
	updated.index = index

	if previous then
		Damagelog.Reports.Previous[index] = updated

		if IsValid(Damagelog.PreviousReports) then
			Damagelog.PreviousReports:UpdateReport(index)
		end
	else
		Damagelog.Reports.Current[index] = updated

		if IsValid(Damagelog.CurrentReports) then
			Damagelog.CurrentReports:UpdateReport(index)
		end
	end

	if Damagelog.SelectedReport and Damagelog.SelectedReport.index == index and ((not Damagelog.SelectedReport.previous and not previous) or Damagelog.SelectedReport.previous == previous) then
		Damagelog.SelectedReport = updated
	end

	if IsValid(Damagelog.CurrentReports) then
		Damagelog:UpdateReportTexts()
	end
end)

net.Receive("DL_UpdateReports", function()
	Damagelog.SelectedReport = nil
	local size = net.ReadUInt(32)
	local data = net.ReadData(size)
	if not data then return end
	local json = util.Decompress(data)
	if not json then return end
	Damagelog.Reports = util.JSONToTable(json)

	if IsValid(Damagelog.CurrentReports) then
		Damagelog.CurrentReports:UpdateAllReports()
	end

	if IsValid(Damagelog.PreviousReports) then
		Damagelog.PreviousReports:UpdateAllReports()
	end
end)

local function DrawStatusMenuOption(id, menu)
	menu:AddOption(status[id], function()
		net.Start("DL_UpdateStatus")
		net.WriteUInt(Damagelog.SelectedReport.previous and 1 or 0, 1)
		net.WriteUInt(Damagelog.SelectedReport.index, 16)
		net.WriteUInt(id, 4)
		net.SendToServer()
	end):SetImage(icons[id])
end

function Damagelog:DrawRDMManager(x, y)
	if LocalPlayer():CanUseRDMManager() and Damagelog.RDM_Manager_Enabled then
		local Manager = vgui.Create("DPanelList")
		Manager:SetSpacing(10)
		local Background = vgui.Create("ColoredBox")
		Background:SetHeight(170)
		Background:SetColor(Color(90, 90, 95))
		local ReportsSheet = vgui.Create("DPropertySheet", Background)
		ReportsSheet:SetPos(5, 5)
		ReportsSheet:SetSize(630, 160)
		self.CurrentReports = vgui.Create("RDM_Manager_ListView")
		self.CurrentReports:SetReportsTable(Damagelog.Reports.Current)
		self.CurrentReports.Previous = false
		ReportsSheet:AddSheet(TTTLogTranslate(GetDMGLogLang, "Reports"), self.CurrentReports, "icon16/zoom.png")
		self.PreviousReports = vgui.Create("RDM_Manager_ListView")
		self.PreviousReports:SetReportsTable(Damagelog.Reports.Previous)
		self.PreviousReports.Previous = true
		ReportsSheet:AddSheet(TTTLogTranslate(GetDMGLogLang, "PreviousMapReports"), self.PreviousReports, "icon16/world.png")
		local ShowFinished = vgui.Create("DCheckBoxLabel", Background)
		ShowFinished:SetText(TTTLogTranslate(GetDMGLogLang, "ShowFinishedReports"))
		ShowFinished:SetConVar("rdm_manager_show_finished")
		ShowFinished:SizeToContents()
		ShowFinished:SetPos(235, 7)
		local TakeActionB = vgui.Create("DButton", Background)
		TakeActionB:SetText(TTTLogTranslate(GetDMGLogLang, "TakeAction"))
		TakeActionB:SetPos(470, 4)
		TakeActionB:SetSize(80, 18)

		TakeActionB.Think = function(self)
			self:SetEnabled(Damagelog.SelectedReport)
		end

		TakeActionB.DoClick = function(self)
			TakeAction()
		end

		local SetState = vgui.Create("DButton", Background)
		SetState:SetText(TTTLogTranslate(GetDMGLogLang, "SStatus"))
		SetState:SetPos(555, 4)
		SetState:SetSize(80, 18)

		SetState.Think = function(self)
			self:SetEnabled(Damagelog.SelectedReport)
		end

		SetState.DoClick = function()
			local menu = DermaMenu()
			local attacker = player.GetBySteamID(Damagelog.SelectedReport.attacker)
			DrawStatusMenuOption(RDM_MANAGER_WAITING, menu)
			DrawStatusMenuOption(RDM_MANAGER_PROGRESS, menu)
			DrawStatusMenuOption(RDM_MANAGER_FINISHED, menu)
			menu:Open()
		end

		local CreateReport = vgui.Create("DButton", Background)
		CreateReport:SetText(TTTLogTranslate(GetDMGLogLang, "CreateReport"))
		CreateReport:SetPos(385, 4)
		CreateReport:SetSize(80, 18)
		CreateReport.DoClick = function()
			RunConsoleCommand("dmglogs_startreport")
		end

		Manager:AddItem(Background)
		local VictimInfos = vgui.Create("DPanel")
		VictimInfos:SetHeight(110)
		VictimInfos.isAdmin = false

		VictimInfos.Paint = function(panel, w, h)
			local bar_height = 27
			if panel.isAdmin then 
				surface.SetDrawColor(200, 200, 30)
			else
				surface.SetDrawColor(30, 200, 30)
			end
			surface.DrawRect(0, 0, (w / 2), bar_height)
			if panel.isAdmin then
				draw.SimpleText(TTTLogTranslate(GetDMGLogLang, "AdminsMessage"), "DL_RDM_Manager", w / 4, bar_height / 2, Color(0, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)				
			else
				draw.SimpleText(TTTLogTranslate(GetDMGLogLang, "VictimsReport"), "DL_RDM_Manager", w / 4, bar_height / 2, Color(0, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			surface.SetDrawColor(220, 30, 30)
			surface.DrawRect((w / 2) + 1, 0, (w / 2), bar_height)
			draw.SimpleText(TTTLogTranslate(GetDMGLogLang, "ReportedPlayerResponse"), "DL_RDM_Manager", (w / 2) + 1 + (w / 4), bar_height / 2, Color(0, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			surface.SetDrawColor(0, 0, 0)
			surface.DrawOutlinedRect(0, 0, w, h)
			surface.DrawLine(w / 2, 0, w / 2, h)
			surface.DrawLine(0, 27, w, bar_height)

			if panel.DisableR then
				surface.SetDrawColor(color_trablack)
				surface.DrawRect((w / 2) + 1, 0, (w / 2), h)
			end
		end

		local VictimMessage = vgui.Create("DTextEntry", VictimInfos)
		VictimMessage:SetMultiline(true)
		VictimMessage:SetKeyboardInputEnabled(false)
		VictimMessage:SetPos(1, 27)
		VictimMessage:SetSize(319, 82)
		local KillerMessage = vgui.Create("DTextEntry", VictimInfos)
		KillerMessage:SetMultiline(true)
		KillerMessage:SetKeyboardInputEnabled(false)
		KillerMessage:SetPos(319, 27)
		KillerMessage:SetSize(319, 82)

		KillerMessage.PaintOver = function(self, w, h)
			if self.DisableR then
				surface.SetDrawColor(color_trablack)
				surface.DrawRect(0, 0, w, h)
				surface.SetFont("DL_ResponseDisabled")
				local text = TTTLogTranslate(GetDMGLogLang, "ChatOpened")
				local wt, ht = surface.GetTextSize(text)
				wt = wt
				surface.SetTextColor(color_white)
				surface.SetTextPos(w / 2 - (wt - 14) / 2, h / 3 - ht / 2 + 10)
				surface.DrawText(text)
				surface.SetMaterial(Material("icon16/exclamation.png"))
				surface.SetDrawColor(color_white)
				surface.DrawTexturedRect(w / 2 - wt / 2 - 14, h / 3 - ht / 2 + 10, 16, 16)
			end
		end

		self.CurrentReports:SetOuputs(VictimMessage, KillerMessage)
		self.PreviousReports:SetOuputs(VictimMessage, KillerMessage)
		Manager:AddItem(VictimInfos)
		local VictimLogs
		local VictimLogsForm
		local Conclusion = vgui.Create("DPanel")
		surface.SetFont("DL_Conclusion")
		local cx, cy = surface.GetTextSize(TTTLogTranslate(GetDMGLogLang, "Conclusion") .. ":")
		local cm = 5

		Conclusion.PaintOver = function(panel, w, h)
			if not panel.t1 then return end
			surface.SetDrawColor(color_black)
			surface.DrawLine(0, 0, w - 1, 0)
			surface.DrawLine(w - 1, 0, w - 1, h - 1)
			surface.DrawLine(w - 1, h - 1, 0, h - 1)
			surface.DrawLine(0, h - 1, 0, 0)
			surface.SetFont("DL_Conclusion")
			surface.SetTextPos(cm, panel.t2 and (h / 3 - cy / 2) or (h / 2 - cy / 2))
			surface.SetTextColor(Color(0, 108, 155))
			surface.DrawText(TTTLogTranslate(GetDMGLogLang, "Conclusion") .. ":")
			surface.SetFont("DL_ConclusionText")
			surface.SetTextColor(color_black)
			local ty1 = surface.GetTextSize(panel.t1)
			surface.SetTextPos(cx + 2 * cm, panel.t2 and (h / 3 - cy / 2) or (h / 2 - cy / 2))
			surface.DrawText(panel.t1)

			if panel.t2 then
				local ty2 = surface.GetTextSize(panel.t2)
				surface.SetTextPos(cm, 2 * h / 3 - ty2 / 2)
				surface.DrawText(panel.t2)
			end
		end

		Conclusion.SetText = function(pnl, t)
			pnl.Text = t
			local t1, t2 = AdjustText(t, "DL_ConclusionText", pnl:GetWide() - cx - cm * 3)
			pnl.t1 = t1
			pnl.t2 = nil

			if t2 then
				pnl.t2 = t2
				pnl:SetHeight(45)
				KillerMessage:SetHeight(97)
				VictimMessage:SetHeight(97)
				VictimInfos:SetHeight(125)

				if VictimLogs then
					VictimLogs:SetHeight(215)
				end
			else
				pnl:SetHeight(30)
				KillerMessage:SetHeight(82)
				VictimMessage:SetHeight(82)
				VictimInfos:SetHeight(110)

				if VictimLogs then
					VictimLogs:SetHeight(245)
				end
			end

			if VictimLogsForm then
				VictimLogsForm:PerformLayout()
			end

			Manager:PerformLayout()
		end

		Conclusion.SetDefaultText = function(pnl)
			pnl:SetText(TTTLogTranslate(GetDMGLogLang, "NoSelectedReport"))
		end

		Conclusion.ApplySchemeSettings = function(pnl)
			if pnl.Text then
				pnl:SetText(pnl.Text)
			end
		end

		Conclusion:SetHeight(45)
		self.CurrentReports.Conclusion = Conclusion
		self.PreviousReports.Conclusion = Conclusion
		Manager:AddItem(Conclusion)
		VictimLogsForm = vgui.Create("DForm")
		VictimLogsForm.SetExpanded = function() end
		VictimLogsForm:SetName(TTTLogTranslate(GetDMGLogLang, "LogsBeforeVictim"))
		VictimLogs = vgui.Create("DListView")
		VictimLogs:AddColumn(TTTLogTranslate(GetDMGLogLang, "Time")):SetFixedWidth(40)
		VictimLogs:AddColumn(TTTLogTranslate(GetDMGLogLang, "Type")):SetFixedWidth(40)
		VictimLogs:AddColumn(TTTLogTranslate(GetDMGLogLang, "Event")):SetFixedWidth(559)
		VictimLogs:SetHeight(300)

		Damagelog.UpdateReportTexts = function()
			local selected = Damagelog.SelectedReport

			if not selected then
				VictimInfos.isAdmin = false
				VictimMessage:SetText("")
				KillerMessage:SetText("")
			else
				VictimInfos.isAdmin = selected.adminReport
				if selected.chatReport then
					VictimMessage:SetText(TTTLogTranslate(GetDMGLogLang, "ChatOpenNoMessage"))
				else
					VictimMessage:SetText(selected.message)
				end
				KillerMessage:SetText(selected.response or TTTLogTranslate(GetDMGLogLang, "NoResponseYet"))
			end

			VictimLogs:Clear()

			if selected and selected.logs then
				Damagelog:SetListViewTable(VictimLogs, selected.logs, false)
			end
		end

		Damagelog.DisableResponse = function(disable)
			VictimInfos.DisableR = disable
			KillerMessage.DisableR = disable
		end

		VictimLogsForm:AddItem(VictimLogs)
		VictimLogsForm.Items[1]:DockPadding(0, 0, 0, 0)
		Manager:AddItem(VictimLogsForm)
		self.Tabs:AddSheet(TTTLogTranslate(GetDMGLogLang, "RDMManag"), Manager, "icon16/magnifier.png", false, false)
		Conclusion:SetDefaultText()
		self.CurrentReports:UpdateAllReports()
		self.PreviousReports:UpdateAllReports()
	end
end
