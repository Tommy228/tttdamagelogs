local PANEL = {};
local GRADIENT = surface.GetTextureID("gui/gradient_down");

function PANEL:Init()
	self:SetPos(4, 4);
	self:SetSize(self:GetWide() - 8, 24);
	self:SetBackgroundColor(Color(139, 174, 179, 255));
	
	self.icon = vgui.Create("DImage", self);
	self.icon:SetImage("icon16/comment.png");
	self.icon:SizeToContents();
	
	self.label = vgui.Create("DLabel", self);
	self.label:SetText("");
	self.label:SetTextColor(color_white);
	self.label:SetExpensiveShadow(1, Color(0, 0, 0, 150));
end;

function PANEL:PerformLayout(w, h)
	self.icon:SetPos(4, 4);
	
	if (self.textToLeft) then
		if (self.icon:IsVisible()) then
			self.label:SetPos(self.icon.x + 8, h / 2 - self.label:GetTall() / 2);
		else
			self.label:SetPos(8, h / 2 - h / 2);
		end;
	else
		self.label:SetPos(w / 2 - self.label:GetWide() / 2, h / 2 - self.label:GetTall() / 2);
	end;
	
	derma.SkinHook("Layout", "Panel", self);
end;

function PANEL:Paint(w, h)
	if (self:GetPaintBackground()) then
		local width, height = self:GetSize();
		local x, y = 0, 0;
		
		if (self:IsDepressed()) then
			height = height - 4;
			width = width - 4;
			x = x + 2;
			y = y + 2;
		end;

		local color = self:GetBackgroundColor();

		if (self:IsButton() and self:IsHovered()) then
			color = Color(255, 255, 255, 50);
		end;

		local cornerSize = 4;
		local gradientAlpha = math.min(color.a, 100);
		draw.RoundedBox(cornerSize, x, y, width, height, Color(color.r, color.g, color.b, color.a * 0.75));
		
		if (x + cornerSize < x + width and y + cornerSize < y + height) then
			surface.SetDrawColor(gradientAlpha, gradientAlpha, gradientAlpha, gradientAlpha);
			surface.SetTexture(GRADIENT);
			surface.DrawTexturedRect(x + cornerSize, y + cornerSize, width - (cornerSize * 2), height - (cornerSize * 2));
		end;
	end	
	
	return true;
end;

function PANEL:SetTextToLeft()
	self.textToLeft = true;
end;

function PANEL:SetText(text)
	self.label:SetText(text);
	self.label:SizeToContents();
end;

function PANEL:SetButton(isButton)
	self.isButton = isButton;
end;

function PANEL:IsButton()
	return self.isButton;
end;

function PANEL:SetDepressed(isDepressed)
	self.isDepressed = isDepressed;
end;

function PANEL:IsDepressed()
	return self.isDepressed;
end;

function PANEL:SetHovered(isHovered)
	self.isHovered = isHovered;
end;

function PANEL:IsHovered()
	return self.isHovered;
end;

function PANEL:SetTextColor(color)
	self.label:SetTextColor(color);
end;

function PANEL:OnMousePressed(mouseCode)
	if (self:IsButton()) then
		self:SetDepressed(true);
		self:MouseCapture(true);
	end;
end;

function PANEL:OnMouseReleased(mouseCode)
	if (self:IsButton() and self:IsDepressed()
	and self:IsHovered()) then
		if (self.DoClick) then
			surface.PlaySound("ui/buttonclick.wav");
			self:DoClick();
		end;
	end;
	
	self:SetDepressed(false);
	self:MouseCapture(false);
end;

function PANEL:OnCursorEntered()
	self:SetHovered(true);
end;

function PANEL:OnCursorExited()
	self:SetHovered(false);
end;

function PANEL:SetShowIcon(showIcon)
	self.icon:SetVisible(showIcon);
end;

function PANEL:SetIcon(icon)
	self.icon:SetImage(icon);
	self.icon:SizeToContents();
	self.icon:SetVisible(true);
end;

function PANEL:SetInfoColor(color)
	if (color == "red") then
		self:SetBackgroundColor(Color(179, 46, 49, 255));
		self:SetIcon("icon16/exclamation.png");
	elseif (color == "orange") then
		self:SetBackgroundColor(Color(223, 154, 72, 255));
		self:SetIcon("icon16/error.png");
	elseif (color == "green") then
		self:SetBackgroundColor(Color(139, 215, 113, 255));
		self:SetIcon("icon16/tick.png");
	elseif (color == "blue") then
		self:SetBackgroundColor(Color(139, 174, 179, 255));
		self:SetIcon("icon16/information.png");
	else
		self:SetShowIcon(false);
		self:SetBackgroundColor(color);
	end;
end;
	
vgui.Register("azInfoText", PANEL, "DPanel");
