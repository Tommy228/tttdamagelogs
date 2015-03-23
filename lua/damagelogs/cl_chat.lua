surface.CreateFont("DL_ChatCategory", {
	font = "DermaDefault",
	size = 17,
	weight = 700
})

surface.CreateFont("DL_ChatPlayer", {
	font = "DermaDefault",
	size = 16,
	weight = 600
})

local PANEL = {}

function PANEL:SetPlayer(ply, playertype)
	self.Player = ply
	self.PlayerName = ply:Nick()
	self.Avatar = vgui.Create("AvatarImage", self)
	self.Avatar:SetSize(32, 32)
	self.Avatar:SetPos(5, 0)
	self.Avatar:CenterVertical()
	self.Avatar:SetPlayer(self.Player, 32)
	self.PlayerType = playertype
end

function PANEL:Paint(w, h)
	surface.SetTextColor(color_black)
	surface.SetFont("DL_ChatPlayer")
	surface.SetTextPos(40, 0)
	surface.DrawText(self.PlayerName)
	surface.SetFont("DL_ChatPlayer")
	surface.SetTextPos(40, 16)
	if self.PlayerType == DAMAGELOG_REPORTED then
		surface.SetTextColor(Color(190, 18, 29))
		surface.DrawText("Reported")
	elseif self.PlayerType == DAMAGELOG_VICTIM then
		surface.SetTextColor(Color(18, 190, 29))
		surface.DrawText("Victim")
	elseif self.PlayerType == DAMAGELOG_ADMIN then
		surface.SetTextColor(Color(160, 160, 0))
		surface.DrawText("Admin")
	end
end

vgui.Register("DL_ChatPlayer", PANEL, "DPanel")

local PANEL = {}

function PANEL:Init()
	self.List = vgui.Create("DPanelList", self)
	self.List:SetSpacing(2)
	self.List:SetPos(0, 25)
	self.List:SetSize(self:GetWide(), self:GetTall() - 20)
end

function PANEL:SetCategoryName(name)
	self.Name = name
end

function PANEL:AddPlayer(ply, playertype)
	local panel = vgui.Create("DL_ChatPlayer", self)
	panel:SetHeight(30)
	panel:SetPlayer(ply, playertype)
	self.List:AddItem(panel)
	if not self.Players then 
		self.Players = { ply }
	else --elseif not table.HasValue(self.Players, ply) then
		table.insert(self.Players, ply)
	end
end

function PANEL:Paint()
	if not self.Name then return end
	surface.SetFont("DL_ChatCategory")
	surface.SetTextColor(Color(150, 150, 150))
	surface.SetTextPos(5, 5)
	surface.DrawText(self.Name)
end

vgui.Register("DL_ChatCategory", PANEL, "DPanel")

local PANEL = {}

function PANEL:Init()
	self.Normal = vgui.Create("DL_ChatCategory", self)
	self.Normal:SetCategoryName("Players")
	self.Admins = vgui.Create("DL_ChatCategory", self)
	self.Admins:SetCategoryName("Administraitors")
end

function PANEL:AddPlayer(ply, playertype)
	if playertype == DAMAGELOG_ADMIN then
		self.Admins:AddPlayer(ply, playertype)
	else
		self.Normal:AddPlayer(ply, playertype)
	end
	self.Normal:SetSize(self:GetWide(), #(self.Normal.Players or {}) * 32 + 25)
	self.Normal.List:SetSize(self:GetWide(), self.Normal:GetTall() - 25)
	self.Admins:SetPos(0, self.Normal:GetTall() + 2)
	self.Admins:SetSize(self:GetWide(), #(self.Admins.Players or {}) * 32 + 25)
	self.Admins.List:SetSize(self:GetWide(), self.Admins:GetTall() - 25)
end

function PANEL:RemovePlayer(ply)
end

function PANEL:Paint(w, h)
	local background = Color(235, 240, 243)
	surface.SetDrawColor(background)
	surface.DrawRect(0, 0, w, h-10)
	surface.DrawRect(w-10, h-10, w, h)
	draw.RoundedBox(4, 0, h-12, w-8, 12, background)
end

vgui.Register("DL_ChatList", PANEL, "DPanelList")

function Damagelog:StartChat(admin, victim, attacker)
	
	local Chat = vgui.Create("DFrame")
	Chat:SetSize(600, 350)
	Chat:SetTitle("Damagelog's private chat system")
	Chat:Center()
	
	local List = vgui.Create("DL_ChatList", Chat)
	List:SetPos(2, 26)
	List:SetSize(152, Chat:GetTall() - 27)
	List:AddPlayer(admin, DAMAGELOG_ADMIN)
	List:AddPlayer(victim, DAMAGELOG_VICTIM)
	List:AddPlayer(attacker, DAMAGELOG_REPORTED)
		
	local Sheet = vgui.Create("DPropertySheet", Chat)
	Sheet:SetPos(List:GetWide()+2, 25)
	Sheet:SetSize(Chat:GetWide() - List:GetWide() - 4, Chat:GetTall() - 26)
	Sheet.PaintOver = function(self, w, h)
		surface.SetDrawColor(color_black)
		surface.DrawLine(0, 5, 0, 30)
	end
		
	local ChatBox = vgui.Create("DPanel")
	ChatBox.Paint = function(self, w, h)
		surface.SetDrawColor(Color( 101, 100, 105, 255 ))
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(Color( 220, 220, 220, 255 ))
		surface.DrawRect(0, h - 55, w, 55)
	end
		
	Sheet:AddSheet("Chatbox", ChatBox, "icon16/application_view_list.png")
	
	local TextEntry = vgui.Create("DTextEntry", ChatBox)
	TextEntry:SetPos(3, Sheet:GetTall() - 84)
	TextEntry:SetSize(Sheet:GetWide() - 80, 25)
		
	Chat:MakePopup()
	
end

net.Receive("DL_OpenChat", function()

	local admin = net.ReadEntity()
	local victim = net.ReadEntity()
	local attacker = net.ReadEntity()
	
	Damagelog:StartChat(admin, victim, attacker)

end)