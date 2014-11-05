include("sh_notify.lua");
include("dermas/cl_infolabel.lua");
include("dermas/cl_respond.lua");
include("dermas/cl_repport.lua");
include("dermas/cl_repportPanel.lua");

Damagelog.rdmReporter = Damagelog.rdmReporter or {};
Damagelog.rdmReporter.stored = Damagelog.rdmReporter.stored or {};
Damagelog.rdmReporter.respond = Damagelog.rdmReporter.respond or {};
Damagelog.rdmReporter.histPanel = Damagelog.rdmReporter.histPanel or 0;

function Damagelog.rdmReporter:GetSelectedReport()
	if not self.prevReport then
		if (self.stored[self.histPanel]) then
			return self.stored[self.histPanel], self.histPanel;
		end
	else
		if Damagelog.previous_reports[self.histPanel] then
			return Damagelog.previous_reports[self.histPanel], self.histPanel;
		end
	end
end;

function Damagelog.rdmReporter:GetAll()
	return self.stored;
end;

hook.Add("OnPlayerChat", "DLRDM_Command", function(ply, text, teamOnly, isDead)
	text = text:lower();

	if (text == Damagelog.RDM_Manager_Command) then
		if (ply == LocalPlayer()) then
			if (LocalPlayer():Alive() and GetRoundState() == ROUND_ACTIVE) then
				chat.AddText(Color(255, 62, 62), "You can't report RDMs when you are alive!");
			else
				RunConsoleCommand("DLRDM_Repport");
			end;
		end;

		return true;
	end;

	if (text == Damagelog.RDM_Manager_Respond) then
		if (ply == LocalPlayer()) then
			RunConsoleCommand("DLRDM_SendRespond");
		end;

		return true;
	end;
end);

net.Receive("RDMAdd", function(len)
	local recue = net.ReadTable();

	if (recue.index) then
		recue.round = recue.round or 0;
		recue.time = recue.time or 0;
		recue.attackerMessage = recue.attackerMessage or "No response yet";

		Damagelog.rdmReporter.stored[recue.index] = recue;
		
		if (ValidPanel(Damagelog.rdmReporter.panel)) then
			Damagelog.rdmReporter.panel:Update();
		end;
	end;
end);

net.Receive("RDMRespond", function(len, ply)
	local liste = net.ReadTable();
	local previous = net.ReadTable()
	if #liste <= 0 and #previous <= 0 then return end
	local count = table.Count(liste) + table.Count(previous)

	-- if not cvars.Bool("ttt_dmglogs_rdmpopups") then return end

	Damagelog.rdmReporter.respond = liste;
	Damagelog.rdmReporter.respondPrev = previous;
	Damagelog.notify:AddMessage("You have "..count.." unresolved reports!");

	if (ValidPanel(Damagelog.rdmReporter.RespondPanel)) then
		Damagelog.rdmReporter.RespondPanel:Close();
		Damagelog.rdmReporter.RespondPanel:Remove();
	end;
	
	Damagelog.rdmReporter.RespondPanel = vgui.Create("DLRespond");
	Damagelog.rdmReporter.RespondPanel:MakePopup();
end);

net.Receive("DLRDM_Start", function()
	local tbl
	if net.ReadUInt(1) == 1 then
		tbl = net.ReadTable()
	end
	if (ValidPanel(Damagelog.RepportPanel)) then
		Damagelog.RepportPanel:Close();
		Damagelog.RepportPanel:Remove();
	end;
	
	Damagelog.RepportPanel = vgui.Create("DLRepport");
	Damagelog.RepportPanel:Populate(tbl);
	Damagelog.RepportPanel:MakePopup();
end);

usermessage.Hook("DLRDM_Remove", function(msg)
	local index = msg:ReadShort();

	Damagelog.rdmReporter.stored[index] = nil;

	if (ValidPanel(Damagelog.rdmReporter.panel)) then
		Damagelog.rdmReporter.panel:Update();
	end;
end);

net.Receive("DL_PreviousReports", function()
	Damagelog.previous_reports = net.ReadTable()
	for k,v in pairs(Damagelog.previous_reports) do
		for _,ply in pairs(player.GetAll()) do
			if ply:SteamID() == v.state_ply_steamid then
				v.state_ply = ply
			end
		end
	end
	if (ValidPanel(Damagelog.rdmReporter.panel)) then
		Damagelog.rdmReporter.panel:Update();
	end;
end)

net.Receive("RDMApologise", function()
	local nick = net.ReadString()
	local steamid = net.ReadString()
	local plymessage = net.ReadString()
	if not nick or not steamid or not plymessage then return end
	local answer = vgui.Create("DFrame")
	answer:SetSize(400, 275)
	answer:SetTitle("Message from "..nick.." about your report.")
	answer:Center()
	answer:MakePopup()
	local message = vgui.Create("RichText", answer)
	message:SetSize(390, 200)
	message:SetPos(3, 30)
	message:InsertColorChange(0,0,0,0)
	message:AppendText(plymessage)
	message.Done = false
	message.Paint = function(self, w, h)
		surface.SetDrawColor(color_white)
		surface.DrawRect(0,0,w,h)
	end
	local pardonner = vgui.Create("DButton", answer)
	pardonner:SetText("Cancel")
	pardonner:SetPos(3, 235)
	pardonner:SetSize(195, 30)
	pardonner.DoClick = function(self)
		net.Start("forbid")
		net.WriteString(steamid)
		net.SendToServer()
		answer:Close()
	end
	local demander_sanction = vgui.Create("DButton", answer)
	demander_sanction:SetText("Keep the report")
	demander_sanction:SetPos(205, 235)
	demander_sanction:SetSize(188, 30)
	demander_sanction.DoClick = function(self)
		net.Start("noforbid")
		net.WriteString(steamid)
		net.SendToServer()
		answer:Close()
	end
end)