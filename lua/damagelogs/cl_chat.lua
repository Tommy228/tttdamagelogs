surface.CreateFont("DL_ChatCategory", {
	font = "DermaDefault",
	size = 17,
	weight = 700
})

surface.CreateFont("DL_ChatFont", {
	font = "DermaDefault",
	size = 17
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
	self.Admins:SetCategoryName("Administrators")
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

Damagelog.CurrentChats = Damagelog.CurrentChats or {}

function Damagelog:StartChat(report, admins, victim, attacker, players, history)
	
	local Chat = vgui.Create("DFrame")
	Chat:SetSize(600, 350)
	Chat:SetTitle("Damagelog's private chat system")
	Chat:Center()
	Chat.RID = report
	table.insert(self.CurrentChats, Chat)
	Chat:SetDeleteOnClose(false)
	
	Chat.OnRemove = function()
		for k,v in pairs(self.CurrentChats) do
			if v == Chat then
				table.remove(self.CurrentChats, k)
			end
		end
	end
	
	local List = vgui.Create("DL_ChatList", Chat)
	List:SetPos(2, 26)
	List:SetSize(152, Chat:GetTall() - 27)
	for k,v in ipairs(admins) do
		List:AddPlayer(v, DAMAGELOG_ADMIN)
	end
	List:AddPlayer(victim, DAMAGELOG_VICTIM)
	List:AddPlayer(attacker, DAMAGELOG_REPORTED)
	for k,v in ipairs(players) do
		List:AddPlayer(v, DAMAGELOG_OTHER)
	end
	
	Chat.AddPlayer = function(self, ply, category)
		List:AddPlayer(ply, category)
	end
		
	local Sheet = vgui.Create("DPropertySheet", Chat)
	Sheet:SetPos(List:GetWide()+2, 25)
	Sheet:SetSize(Chat:GetWide() - List:GetWide() - 4, Chat:GetTall() - 26)
	Sheet.PaintOver = function(self, w, h)
		surface.SetDrawColor(color_black)
		surface.DrawLine(0, 5, 0, 30)
	end
		
	local ChatBox = vgui.Create("DPanel")
	ChatBox.Paint = function(self, w, h)
		surface.SetDrawColor(Color(101, 100, 105, 255))
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(Color(220, 220, 220, 255))
		surface.DrawRect(0, h - 35, w, 35)
	end
	
	local RichText = vgui.Create("RichText", ChatBox)
	RichText:SetPos(5, 10)
	RichText:SetSize(Sheet:GetWide() - 25, Sheet:GetTall() - 90)
	RichText.AddText = function(self, nick, color, text)
		self.m_FontName = "DL_ChatFont"
		self:SetFontInternal("DL_ChatFont")	
		self:InsertColorChange(color.r, color.g, color.b, color.a or 255)
		self:AppendText(nick.. ": ")
		self:InsertColorChange(255, 255, 255, 255)
		self:AppendText(text.."\n")
	end
	Chat.RichText = RichText
	
	timer.Simple(0.1, function()
		for k,v in ipairs(history) do
			RichText:AddText(v.nick, v.color, v.msg)
		end
	end)
	
	Sheet:AddSheet("Chatbox", ChatBox, "icon16/application_view_list.png")
	
	local TextEntry = vgui.Create("DTextEntry", ChatBox)
	local Send = vgui.Create("DButton", ChatBox)
	
	local function SendMessage(msg)
		if #msg == 0 or #msg > 200 then return end
		net.Start("DL_SendChatMessage")
		net.WriteUInt(report, 32)
		net.WriteString(msg)
		net.SendToServer()
		TextEntry:SetText("")
		TextEntry:RequestFocus()
	end
	
	TextEntry:SetPos(3, Sheet:GetTall() - 65)
	TextEntry:SetSize(Sheet:GetWide() - 80, 25)
	TextEntry.OnEnter = function(self)
		SendMessage(self:GetValue())
	end
	TextEntry:RequestFocus()
		
	Send:SetPos(Sheet:GetWide() - 75, Sheet:GetTall() - 65)
	Send:SetSize(55, 25)
	Send:SetText("Send")
	Send.DoClick = function()
		SendMessage(TextEntry:GetValue())
	end
		
	Chat:MakePopup()
	
end

net.Receive("DL_BroadcastMessage", function()
	local id = net.ReadUInt(32)
	local ply = net.ReadEntity()
	local color = net.ReadColor()
	local message = net.ReadString()
	if not id or not IsValid(ply) or not color or not message then return end
	for k,v in pairs(CurrentChats) do
		if v.RID == id then
			if not v:IsVisible() then
				if not v.MissingMessages then 
					v.MissingMessages = 1
				else
					v.MissingMessages = v.MissingMessages + 1
				end
			end
			v.RichText:AddText(ply:Nick(), color, message)
			break
		end
	end
end)

net.Receive("DL_OpenChat", function()

	local report = net.ReadUInt(32)
	local admin = net.ReadEntity()
	local victim = net.ReadEntity()
	local attacker = net.ReadEntity()
	
	if not report or not IsValid(admin) or not IsValid(victim) or not IsValid(attacker) then return end
	
	Damagelog:StartChat(report, { admin }, victim, attacker, {}, {})

end)

net.Receive("DL_JoinChatCL", function()

	local is_joining = net.ReadUInt(1) == 1
	
	if is_joining then
		
		local id = net.ReadUInt(32)
		local size = net.ReadUInt(32)
		local compressed = net.ReadData(size)
		local not_compressed = util.Decompress(compressed)
		local history = util.JSONToTable(not_compressed)
		local tbl = net.ReadTable()
						
		Damagelog:StartChat(id, tbl.admins, tbl.victim, tbl.attacker, tbl.players, history)
		
	else
	
		local id = net.ReadUInt(32)
		local ply = net.ReadEntity()
		local category = net.ReadUInt(32)
		
		local chat = CurrentChats[id]
		if not chat then return end
		
		chat:AddPlayer(ply, category)
		
	end
			
end)

local drawing = false

hook.Add("TTTBeginRound", "Damagelog_Chat", function()
	drawing = false
end)

local exclamation = Material("icon16/exclamation.png")

hook.Add("HUDPaint", "Damagelog_Chat", function()

	if IsValid(LocalPlayer()) then
	
		local wr, hr = 150, 40
		local w, h = ScrW()/2, ScrH() - 50
			
		if not drawing and #Damagelog.CurrentChats > 0 then
			TIPS.Hide()
			drawing = true
			if Damagelog.ChatButton then
				Damagelog.ChatButton:Remove()
			end
			Damagelog.ChatButton = vgui.Create("DButton")
			Damagelog.ChatButton:SetSize(16, 16)
			Damagelog.ChatButton:SetPos(w + wr/2 - Damagelog.ChatButton:GetWide() - 10, h - Damagelog.ChatButton:GetTall()/2)
			Damagelog.ChatButton:SetText("")
			Damagelog.ChatButton.TextI = "▲"
			Damagelog.ChatButton.PaintOver = function(self, w, h)
				surface.SetFont("DermaDefault")
				local text = self.TextI
				local wt, ht = surface.GetTextSize(text)
				surface.SetTextPos(w/2 - wt/2 + 2, h/2 - ht/2)
				surface.DrawText(text)
			end
		elseif drawing and #Damagelog.CurrentChats == 0 then
			if LocalPlayer():IsSpec() then
				TIPS.Show()
			end
			drawing = false
			Damagelog.ChatButton:Remove()
		end
		
		if #Damagelog.CurrentChats > 0 then
			
			surface.SetDrawColor(Color(171, 181, 198, 200))
			surface.DrawRect(w - wr/2, h - hr/2, wr, hr)
			surface.SetDrawColor(color_black)
			surface.DrawLine(w - wr/2, h - hr/2, w + wr/2, h - hr/2)
			surface.DrawLine(w + wr/2, h - hr/2, w + wr/2, h + hr/2)
			surface.DrawLine(w + wr/2, h + hr/2, w - wr/2, h + hr/2)
			surface.DrawLine(w - wr/2, h + hr/2, w - wr/2, h - hr/2)
			
			surface.SetTextColor(color_black)
			surface.SetFont("DL_ChatCategory")
			local text = tostring(#Damagelog.CurrentChats).." active chat(s)"
			local wt, ht = surface.GetTextSize(text)
			surface.SetTextPos(w - wr/2 + 10, h - ht/2)
			surface.DrawText(text)
			
			local missing_messages = 0
			for k,v in pairs(Damagelog.CurrentChats) do
				if v.MissingMessages then
					missing_messages = missing_messages + v.MissingMessages
				end
			end
			
			if missing_messages > 0 then
				
				surface.SetDrawColor(Color(92, 127, 183))
				Damagelog.DrawCircle(w + wr/2, h-hr/2, 13, 50)
				
				surface.SetFont("DL_ChatCategory")
				surface.SetTextPos(w + wr/2 - 4, h-hr/2 - 8)
				surface.SetTextColor(color_white)
				surface.DrawText(tostring(missing_messages))
			
			end
			
		end
	
	end

end)