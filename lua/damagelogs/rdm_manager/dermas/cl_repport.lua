local PANEL = {};

function PANEL:Init()
	--self:SetBackgroundBlur(true);
	self:SetDeleteOnClose(true);
	self:SetTitle("RDM Report");
	
	self.reportList = vgui.Create("DPanel", self);
	
	self.logList = vgui.Create("DListView", self)
		
	self.columnSheet = vgui.Create("DPropertySheet", self);
	self.columnSheet:AddSheet("Report", self.reportList, "icon16/report_user.png");
	self.columnSheet:AddSheet("Logs before your death", self.logList, "icon16/application_view_list.png");
	
	local infoTyps = vgui.Create("azInfoText", self.reportList);
	infoTyps:SetText("False reports will get you punished");
	infoTyps:SetInfoColor("red");
	infoTyps:SetPos(2,5);
	infoTyps:SetSize(582, 24);
		
	local pSelectionLabel = vgui.Create("DLabel", self.reportList);
	pSelectionLabel:SetText("Select a player to report:");
	pSelectionLabel:SetDark(true);
	pSelectionLabel:SizeToContents();
	pSelectionLabel:SetPos(3, 43);
		
	local id_ents = {};
	local currentSelection;
	self.playerSelection = vgui.Create("DComboBox", self.reportList);
	self.playerSelection:SetPos(2, 60);
	self.playerSelection:SetSize(582, 23);
	self.playerSelection.OnSelect = function(panel, choice, data)
		currentSelection = id_ents[choice];
	end;
	
	local selected = false;
	
	local killer = LocalPlayer():GetNWEntity("DL_Killer")
	if IsValid(killer) then
		local line = self.playerSelection:AddChoice("Killer :"..killer:Nick());
		self.playerSelection:ChooseOptionID(line);
		selected = true;
		id_ents[line] = killer;
		currentSelection = killer;
	end
	
	for k,v in pairs(player.GetAll()) do
		if v == LocalPlayer() or v == killer then continue end;
		local line = self.playerSelection:AddChoice(v:Nick());
		id_ents[line] = v;
	end;
	if not selected and #player.GetAll() > 0 then
		self.playerSelection:ChooseOptionID(1);
		currentSelection = player.GetAll()[1] != LocalPlayer() and player.GetAll()[1] or player.GetAll()[2];
	end;
		
	local counterChar = vgui.Create("DLabel", self.reportList);
	local textEntry = vgui.Create("DTextEntry", self.reportList);
	local button = vgui.Create("DButton", self.reportList);
	
	counterChar:SetText("500 characters left");
	counterChar:SetPos(2, 100)
	counterChar:SetDark(true);
	counterChar:SizeToContents();
	
	textEntry:SetPos(2,115)
	textEntry:SetMultiline(true);
	textEntry:SetSize(582, 130);
	
	button:SetText("Submit");
	button:SetPos(2, 250)
	button:SetSize(582, 28)
	
	function textEntry:SetRealValue(text)
		self:SetValue(text);
		self:SetCaretPos( string.len(text) );
	end;
	
	function textEntry:Think()
		local text = self:GetValue();
		
		counterChar:SetText(500 - string.len(text) .." characters left");
		counterChar:SizeToContents();
		
		if (string.len(text) > 500) then
			self:SetRealValue( string.sub(text, 0, 500) );
			
			surface.PlaySound("common/talk.wav");
		end;
	end;
	
	function button.DoClick(button)
		net.Start("RDMAdd");
			net.WriteString(string.sub(textEntry:GetValue(), 0, 500));
			net.WriteEntity(currentSelection);
		net.SendToServer();
		
		self:Close(); self:Remove();
		
		gui.EnableScreenClicker(false);
	end;

end;

function PANEL:Think()
	self:SetSize(610,350);
	self:Center()
end;

function PANEL:Populate(logs)
	self.logList:Clear();
	
	self.logList:SetHeight(300);
	self.logList:AddColumn("Time"):SetFixedWidth(40);
	self.logList:AddColumn("Type"):SetFixedWidth(40);
	self.logList:AddColumn("Event")

	if logs then
		Damagelog:SetListViewTable(self.logList, logs, false)
	end
end;

function PANEL:PerformLayout()
	self.columnSheet:StretchToParent(4, 28, 4, 4);
	
	DFrame.PerformLayout(self);
end;

vgui.Register("DLRepport", PANEL, "DFrame");
