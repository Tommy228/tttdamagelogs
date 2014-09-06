local PANEL = {};

function PANEL:Init()
	self:SetDeleteOnClose(true);
	self:SetTitle("You have been reported! Please answer to all your reports.");
	self:ShowCloseButton(false)
	self:SetSize(610,350);
			
	self.columnSheet = vgui.Create("DColumnSheet", self);
	self.columnSheet.Navigation:SetWidth(150);

	self.listPanel = {};

	self:Rebuild();
	self:Center();
end;

function PANEL:Rebuild()
	//self.columnSheet:Clear();  
	
	local tbl = {}
	tbl.current = Damagelog.rdmReporter.respond
	tbl.previous = Damagelog.rdmReporter.respondPrev

	for _,reports in pairs(tbl) do
	
		for k, v in pairs(reports) do
		
			local panelList = vgui.Create("DPanelList", self);
			panelList:SetPadding(3);
			panelList:SetSpacing(2); 

			panelList.Paint = function(listeRepport, w, h)
				draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50, 255));
			end;

			v.time = v.time or 0;
			v.round = v.round or 0;
			local time = util.SimpleTime(math.max(0, v.time), "%02i:%02i");

			local infoTyps = vgui.Create("azInfoText", self);
			infoTyps:SetText(v.victim.. " reported you"..(_ == "previous" and " on the previous map " or "").."at "..time.." after round "..v.round..".");
			infoTyps:SetInfoColor("blue");
			panelList:AddItem(infoTyps);

			local messageEntry = vgui.Create("DTextEntry", self)
			messageEntry:SetMultiline(true);
			messageEntry:SetHeight(100);
			messageEntry:SetText(v.message or "");
			messageEntry:SetDisabled(true);
			messageEntry:SetEditable(false);
			panelList:AddItem(messageEntry);

			local textEntry = vgui.Create("DTextEntry", self)
			textEntry:SetMultiline(true);
			textEntry:SetHeight(150);
			panelList:AddItem(textEntry);

			function textEntry:SetRealValue(text)
				self:SetValue(text);
				self:SetCaretPos( string.len(text) );
			end;
		
			function textEntry:Think()
				local text = self:GetValue();
				local size = #text
				
				if (size > 500) then
					self:SetRealValue( string.sub(text, 0, 500) );
				
					surface.PlaySound("common/talk.wav");
				end;
			end;

			local buton = vgui.Create("DButton", self);
			buton:SetText("Send");
			buton.DoClick = function()
			
				local text = textEntry:GetValue();
				local size = #text
				if size < 10 then
					infoTyps:SetText("A minimum of 10 characters are required!");
					infoTyps:SetInfoColor("red");
					if timer.Exists("TimerRespond") then
						timer.Destroy("TimerRespond")
					end
					timer.Create("TimerRespond", 5, 1, function()
						if infoTyps and infoTyps:IsValid() then
							infoTyps:SetText(v.victim.. " reported you"..(_ == "previous" and " on the previous map " or "").."at "..time.." after round "..v.round..".");
							infoTyps:SetInfoColor("blue");
						end
					end)
					return
				end
				
				net.Start("RDMRespond")
					net.WriteString(string.sub(textEntry:GetValue(), 0, 500));
					net.WriteUInt(_ == "previous" and 1 or 0, 1)
					net.WriteUInt(v.index, 8);
				net.SendToServer();

				if _ == "previous" then
					table.remove(Damagelog.rdmReporter.respondPrev, k);
				else
					table.remove(Damagelog.rdmReporter.respond, k);
				end

				buton:SetDisabled(true);

				infoTyps:SetText("Your response has been submitted!");
				infoTyps:SetInfoColor("orange");

				if #Damagelog.rdmReporter.respond == 0 and #Damagelog.rdmReporter.respondPrev == 0 then
					self:Close(); self:Remove();
					Damagelog.notify:AddMessage("Your response has been submitted!", "icon16/information.png");
					gui.EnableScreenClicker(false);
				end;
			end

			panelList:AddItem(buton);

			table.insert(self.listPanel, panelList);

			self.columnSheet:AddSheet(v.victim, panelList, "icon16/report_user.png");
			
		end
			
	end

end;

function PANEL:PerformLayout()
	self.columnSheet:StretchToParent(4, 28, 4, 4);

	for k, v in pairs(self.listPanel) do
		if (ValidPanel(v)) then
			v:StretchToParent(4, 4, 4, 4);
		end;
	end;
	
	DFrame.PerformLayout(self);
end;

vgui.Register("DLRespond", PANEL, "DFrame");
