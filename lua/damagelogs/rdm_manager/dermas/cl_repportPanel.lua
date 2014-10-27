local PANEL = {};

local report_states = {
	"Waiting",
	"In progress",
	"Finished"
};
local state = report_states

function PANEL:Init()
	Damagelog.rdmReporter.panel = self;
	
	self:SetSpacing(10);
	
	self.ManagerSelection = vgui.Create("ColoredBox");
	self.ManagerSelection:SetHeight(170);
	self.ManagerSelection:SetColor(Color(90, 90, 95));
	
	self.reportSheet = vgui.Create("DPropertySheet", self.ManagerSelection)
	
	self.reportList = vgui.Create("DListView", self.reportSheet);
	self.reportList:AddColumn("Victim"):SetFixedWidth(107);
	self.reportList:AddColumn("Reported player"):SetFixedWidth(107);
	self.reportList:AddColumn("Round"):SetFixedWidth(54);
	self.reportList:AddColumn("Time"):SetFixedWidth(72);
	self.reportList:AddColumn("Status"):SetFixedWidth(190);
	self.reportList:AddColumn("Canceled"):SetFixedWidth(83);
	self.reportList.OnRowSelected = function (panel, lineID, line)
		Damagelog.rdmReporter.histPanel = line.index;
		Damagelog.rdmReporter.prevReport = false
		self:Update();
	end;
	self.reportList.OnRowRightClick = function()
		local report = Damagelog.rdmReporter:GetSelectedReport();
		local menu = DermaMenu();

		local actions, smpnl = menu:AddSubMenu("Take Action");
		self:AddActionMenuOpts(actions, report.attacker, report.ply);
		smpnl:SetIcon("icon16/wand.png");

		local states, smpnl = menu:AddSubMenu("Set Status");
		self:AddStateMenuOpts(states, report.index);
		smpnl:SetIcon("icon16/report.png");

		menu:Open();
	end;
	self.reportSheet:AddSheet("Reports", self.reportList, "icon16/zoom.png")
	
	self.prevReportList = vgui.Create("DListView", self.reportSheet);
	self.prevReportList:AddColumn("Victim"):SetFixedWidth(107);
	self.prevReportList:AddColumn("Reported player"):SetFixedWidth(107);
	self.prevReportList:AddColumn("Round"):SetFixedWidth(54);
	self.prevReportList:AddColumn("Time"):SetFixedWidth(72);
	self.prevReportList:AddColumn("Status"):SetFixedWidth(190);
	self.prevReportList:AddColumn("Canceled"):SetFixedWidth(83);
	self.prevReportList.OnRowSelected = function (panel, lineID, line)
		Damagelog.rdmReporter.histPanel = line.index;
		Damagelog.rdmReporter.prevReport = true
		self:Update();
	end;
	self.prevReportList.OnRowRightClick = function()
		local report = Damagelog.rdmReporter:GetSelectedReport();
		local menu = DermaMenu();

		local actions, smpnl = menu:AddSubMenu("Take Action");
		self:AddActionMenuOpts(actions, report.attacker, report.ply);
		smpnl:SetIcon("icon16/wand.png");

		local states, smpnl = menu:AddSubMenu("Set Status");
		self:AddStateMenuOpts(states, report.index);
		smpnl:SetIcon("icon16/report.png");

		menu:Open();
	end;
	self.reportSheet:AddSheet("Previous map's reports", self.prevReportList, "icon16/world.png")
				
	self.removeReport = vgui.Create("DButton", self.ManagerSelection);
	self.removeReport:SetText("Take Action");
	self.removeReport:SetDisabled(true);
	self.removeReport.DoClick = function()
		local report = Damagelog.rdmReporter:GetSelectedReport();
		local menu = DermaMenu();
		self:AddActionMenuOpts(menu, report.attacker, report.ply);
		menu:Open();
	end
	
	self.setState = vgui.Create("DButton", self.ManagerSelection);
	self.setState:SetText("Set Status");
	self.setState:SetDisabled(true);
	self.setState.DoClick = function()
		local menuPanel = DermaMenu();
		local report = Damagelog.rdmReporter:GetSelectedReport();

		self:AddStateMenuOpts(menuPanel, report.index)

		menuPanel:Open();
	end;
	
	self:AddItem(self.ManagerSelection);
			
	self.VictimInfos = vgui.Create("DPanel");
	self.VictimInfos:SetHeight(160);

	self.VictimInfos.Paint = function(panel, w, h)

		local bar_height = 27

		surface.SetDrawColor(30, 200, 30);
		surface.DrawRect(0, 0, (w/2), bar_height);
		draw.SimpleText("Victim's report", "DL_RDM_Manager", w/4, bar_height/2, Color(0,0,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER);

		surface.SetDrawColor(220, 30, 30);
		surface.DrawRect((w/2)+1, 0, (w/2), bar_height);
		draw.SimpleText("Reported player's response", "DL_RDM_Manager", (w/2) + 1 + (w/4), bar_height/2, Color(0,0,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER);

		surface.SetDrawColor(0, 0, 0);
		surface.DrawOutlinedRect(0, 0, w, h);
		surface.DrawLine(w/2, 0, w/2, h);
		surface.DrawLine(0, 27, w, bar_height);
	end;
		
	self.victim_message = vgui.Create("DTextEntry", self.VictimInfos);
	self.victim_message:SetMultiline(true);
	self.victim_message:SetKeyboardInputEnabled(false);
		
	self.killer_message = vgui.Create("DTextEntry", self.VictimInfos);
	self.killer_message:SetMultiline(true);
	self.killer_message:SetKeyboardInputEnabled(false);
	
	self:AddItem(self.VictimInfos);
	
	self.VictimLogs = vgui.Create("DForm");
	self.VictimLogs:SetName("Logs before the victim's death");
	
	self._VictimLogs = vgui.Create("DListView");
	self._VictimLogs:AddColumn("Time"):SetFixedWidth(40);
	self._VictimLogs:AddColumn("Type"):SetFixedWidth(40);
	self._VictimLogs:AddColumn("Event"):SetFixedWidth(555);
	self._VictimLogs:SetHeight(230);
	self.VictimLogs:AddItem(self._VictimLogs);
	
	self:AddItem(self.VictimLogs);

	self:Update();
end;

function PANEL:AddActionMenuOpts(menuPanel, attacker, victim)
	menuPanel:AddOption("Force the reported player to respond", function()
		if IsValid(attacker) then
			RunConsoleCommand("DLRDM_ForceVictim", tostring(attacker:EntIndex()))
		else
			Derma_Message("The reported player isn't valid! (disconnected?)", "Error", "OK")
		end
	end):SetImage("icon16/clock_red.png")
	if ulx then
		if Damagelog.Use_MySQL and Damagelog.Enable_Autoslay then
			local slaynr_pnl = vgui.Create("DMenuOption", menuPanel)
			local slaynr = DermaMenu(menuPanel)
			slaynr:SetVisible(false)
			slaynr_pnl:SetSubMenu(slaynr)
			slaynr_pnl:SetText("Autoslay")
			slaynr_pnl:SetImage("icon16/lightning_go.png")
			menuPanel:AddPanel(slaynr_pnl)
			slaynr:AddOption("Victim", function()
				if IsValid(victim) then
					Derma_StringRequest("Reason", "Please type the reason as to why you want to slay "..victim:Nick(), "", function(txt)
						RunConsoleCommand("ulx", "autoslay", victim:Nick(), "1", txt)
					end)
				else
					Derma_Message("The victim isn't valid! (disconnected?)", "Error", "OK")
				end
			end):SetImage("icon16/user.png")
			slaynr:AddOption("Reported player", function()
				if IsValid(attacker) then
					Derma_StringRequest("Reason", "Please type the reason as to why you want to slay "..attacker:Nick(), "", function(txt)
						RunConsoleCommand("ulx", "autoslay", attacker:Nick(), "1", txt)
					end)
				else
					Derma_Message("The reported player isn't valid! (disconnected?)", "Error", "OK")
				end
			end):SetImage("icon16/user_delete.png")			
		elseif ulx.slaynr then
			local slaynr_pnl = vgui.Create("DMenuOption", menuPanel)
			local slaynr = DermaMenu(menuPanel)
			slaynr:SetVisible(false)
			slaynr_pnl:SetSubMenu(slaynr)
			slaynr_pnl:SetText("Slay next round")
			slaynr_pnl:SetImage("icon16/lightning_go.png")
			menuPanel:AddPanel(slaynr_pnl)
			slaynr:AddOption("Victim", function()
				if IsValid(victim) then
					RunConsoleCommand("ulx", "slaynr", victim:Nick())
				else
					Derma_Message("The victim isn't valid! (disconnected?)", "Error", "OK")
				end
			end):SetImage("icon16/user.png")
			slaynr:AddOption("Reported player", function()
				if IsValid(attacker) then
					RunConsoleCommand("ulx", "slaynr", attacker:Nick())
				else
					Derma_Message("The reported player isn't valid! (disconnected?)", "Error", "OK")
				end
			end):SetImage("icon16/user_delete.png")
		end
		menuPanel:AddOption("Slay the reported player", function()
			if IsValid(attacker) then
				RunConsoleCommand("ulx", "slay", attacker:Nick())
			else
				Derma_Message("The reported player isn't valid! (disconnected?)", "Error", "OK")
			end
		end):SetImage("icon16/lightning.png")
	end
	hook.Call("DamagelogsAddMenuActions", gmod.GetGamemode(), menuPanel, attacker, victim)
end;

function PANEL:AddStateMenuOpts(menu, index)
	for k, v in pairs(report_states) do
		menu:AddOption(v, function()
			local previous = Damagelog.rdmReporter.prevReport
			RunConsoleCommand("DLRDM_State", tostring(index), tostring(k), previous and "1" or "0");
		end);
	end;
end;

function PANEL:Update()
	self.reportList:Clear();
	self.prevReportList:Clear()

	local report, hist = Damagelog.rdmReporter:GetSelectedReport();
	local reports = Damagelog.rdmReporter:GetAll();
	
	local previous_reports = Damagelog.previous_reports

	for i=0, #reports - 1 do
		local v = reports[#reports - i];
		if (v) then
			v.time = v.time or 0;
			v.round = v.round or 0;
			local time = util.SimpleTime(math.max(0, v.time), "%02i:%02i");

			local statename = state[v.state] or tostring(v.state)
			if IsValid(v.state_ply) then
				statename = statename.." by "..v.state_ply:Nick()
			end
			local canceled = "No answer yet"
			if v.forbid then
				canceled = "Yes"
			elseif v.noforbid then
				canceled = "No"
			end
			local line = self.reportList:AddLine(v.plyName, v.attackerName, v.round, time, statename, canceled);
			line.PaintOver = function(self)
				if self:IsLineSelected() then return end
				self.Columns[1]:SetTextColor(Color(0, 190, 0))
				self.Columns[2]:SetTextColor(Color(190, 0, 0))
				if v.state == 1 then
					self.Columns[5]:SetTextColor(Color(100,100, 0))
				elseif v.state == 2 then
					self.Columns[5]:SetTextColor(Color(0,0,190))
				elseif v.state == 3 then
					self.Columns[5]:SetTextColor(Color(0,190, 0))
				end
			end
			line.index = v.index;

			line:SetSelected(not Damagelog.rdmReporter.prevReport and hist == v.index)
		end;
	end;
	
	for k,v in ipairs(previous_reports or {}) do
	v.time = v.time or 0;
		v.round = v.round or 0;
		local time = util.SimpleTime(math.max(0, v.time), "%02i:%02i");

		local statename = state[v.state] or tostring(v.state)
		if IsValid(v.state_ply) then
			statename = statename.." by "..v.state_ply:Nick()
		end
		local canceled = "No answer yet"
		if v.forbid then
			canceled = "Yes"
		elseif v.noforbid then
			canceled = "No"
		end
		local line = self.prevReportList:AddLine(v.plyName, v.attackerName, v.round, time, statename, canceled);
		line.PaintOver = function(self)
			if self:IsLineSelected() then return end
			self.Columns[1]:SetTextColor(Color(0, 190, 0))
			self.Columns[2]:SetTextColor(Color(190, 0, 0))
			if v.state == 1 then
				self.Columns[5]:SetTextColor(Color(100,100, 0))
			elseif v.state == 2 then
				self.Columns[5]:SetTextColor(Color(0,0,190))
			elseif v.state == 3 then
				self.Columns[5]:SetTextColor(Color(0,190, 0))
			end
		end
		line.index = v.index;

		line:SetSelected(Damagelog.rdmReporter.prevReport and hist == v.index)
	end

	if report then
		self.removeReport:SetDisabled(false);
		self.setState:SetDisabled(false);

		self.victim_message:SetText(report.message or "");
		self.killer_message:SetText(report.attackerMessage or "");
		
		if report.lastLogs then
			self._VictimLogs:Clear()
			Damagelog:SetListViewTable(self._VictimLogs, report.lastLogs, true)
		end
	end;
end;

function PANEL:PerformLayout()
	self.reportSheet:SetSize(630, 160);
	self.reportSheet:SetPos(5, 5);

	self.setState:SetPos(510, 4);
	self.setState:SetSize(125, 18);

	self.removeReport:SetPos(380, 4);
	self.removeReport:SetSize(125, 18);

	self.victim_message:SetPos(1, 27);
	self.victim_message:SetSize(639/2, 132);

	self.killer_message:SetPos(639/2, 27);
	self.killer_message:SetSize(639/2, 132);

	self.VictimLogs.Items[1]:DockPadding(0,5,0,0)

	DPanelList.PerformLayout(self);
end

vgui.Register("DLRDMManag", PANEL, "DPanelList");
