local color_what = Color(255, 0, 0, 100)
local color_darkblue = Color(25, 25, 220)
local color_orange = Color(255, 128, 0)

function Damagelog:SetLineMenu(item, infos, tbl, roles, text, old_logs)
	item.ShowTooLong = function(_, b)
		item.ShowLong = b
	end
	item.ShowCopy = function(_, b, steamid1, steamid2)
		item.Copy = b
		item.steamid1 = steamid1
		item.steamid2 = steamid2
	end
	item.ShowDamageInfos = function(_, ply1, ply2)
		item.DamageInfos = true
		item.ply1 = ply1
		item.ply2 = ply2
	end
	item.ShowDeathScene = function(_, ply1, ply2, id)
		item.DeathScene = true
		item.ply1 = ply1
		item.ply2 = ply2
		item.sceneid = id
	end
	item.text = text
	item.old_logs = old_logs
	item.OnRightClick = function()
		if not item.ShowLong and not item.Copy and not item.DamageInfos then return end
		local menu = DermaMenu()
		local pnl = vgui.Create("DMenuOption", menu)
		local copy = DermaMenu(menu)
		copy:SetVisible(false)
		pnl:SetSubMenu(copy)
		pnl:SetText(TTTLogTranslate(GetDMGLogLang, "Copy"))
		pnl:SetImage("icon16/tab_edit.png")
		menu:AddPanel(pnl)
		copy:AddOption(TTTLogTranslate(GetDMGLogLang, "Lines"), function()
			local full_text = ""
			local append = false
			for _,line in pairs(item:GetListView():GetSelected()) do
			if append then
					full_text = full_text .. "\n"
				end
				full_text = full_text .. "[" .. line:GetColumnText(1) .. "] " .. line:GetColumnText(3)
				append = true
			end
			SetClipboardText(full_text)
		end)
		if item.Copy then
			copy:AddOption(TTTLogTranslate(GetDMGLogLang, "SteamIDof")..item.steamid1[1], function()
				SetClipboardText(item.steamid1[2])
			end)
			if item.steamid2 then
				copy:AddOption(TTTLogTranslate(GetDMGLogLang, "SteamIDof")..item.steamid2[1], function()
					SetClipboardText(item.steamid2[2])
				end)
			end
		end
		if item.DamageInfos then
			menu:AddOption(TTTLogTranslate(GetDMGLogLang, "ShowDamageInfos"), function()
				if item.old_logs then
					local found, result = self:FindFromOldLogs(tbl.time, item.ply1, item.ply2)
					self:SetDamageInfosLV(self.OldDamageInfo, roles, tbl.ply1, tbl.ply2, tbl.time, tbl.time-10, found and result)
					self.DamageInfoForm:Toggle()
				else
					net.Start("DL_AskDamageInfos")
					net.WriteUInt(tbl.time, 32)
					net.WriteUInt(item.ply1, 32)
					net.WriteUInt(item.ply2, 32)
					if tbl.round == nil then
						net.WriteUInt(self.SelectedRound, 32)
					else
						net.WriteUInt(tbl.round, 32)
					end
					net.SendToServer()
				end
			end):SetImage("icon16/gun.png")
		end
		if item.DeathScene then
			menu:AddOption(TTTLogTranslate(GetDMGLogLang, "ShowDeathScene"), function()
				net.Start("DL_AskDeathScene")
				net.WriteUInt(item.sceneid, 32)
				net.WriteUInt(item.ply1, 32)
				net.WriteUInt(item.ply2, 32)
				net.SendToServer()
			end):SetImage("icon16/television.png")
		end
		if item.ShowLong then
			menu:AddOption(TTTLogTranslate(GetDMGLogLang, "FullDisplay"), function()
				Derma_Message(item.text, TTTLogTranslate(GetDMGLogLang, "FullDisplay"), TTTLogTranslate(GetDMGLogLang, "Close"))
			end):SetImage("icon16/eye.png")
		end
		menu:Open()
	end
	infos:RightClick(item, tbl.infos, roles, text)
end

function Damagelog:AddLogsLine(listview, tbl, roles, nofilters, old)
	if type(tbl) != "table" then return end
	local infos = self.events[tbl.id]
	if not infos then return end
	if (not nofilters) and (not infos:IsAllowed(tbl.infos, roles)) then return end
	local text = infos:ToString(tbl.infos, roles)
	local item = listview:AddLine(util.SimpleTime(tbl.time, "%02i:%02i"), infos.Type, text, "")
	if tbl.infos.icon then
		if tbl.infos.icon[1] then
			local image = vgui.Create("DImage", item.Columns[4])
			image:SetImage(tbl.infos.icon[1])
			image:SetSize(16, 16)
			image:SetPos(6, 1)
		end
		if tbl.infos.icon[2] then
			item:SetTooltip(TTTLogTranslate(GetDMGLogLang, "VictimShotFirst"))
		end
	end
	function item:PaintOver(w,h)
		if not self:IsSelected() and infos:Highlight(item, tbl.infos, text) then
			surface.SetDrawColor(color_what)
			surface.DrawRect(0, 0, w, h)
		else
			for k,v in pairs(item.Columns) do
				v:SetTextColor(infos:GetColor(tbl.infos, roles))
			end
		end
	end
	self:SetLineMenu(item, infos, tbl, roles, text, old)
	return true
end

function Damagelog:SetListViewTable(listview, tbl, nofilters, old)
	if not tbl or not tbl.logs then return end
	if #tbl.logs > 0 then
		local added = false
		for k,v in ipairs(tbl.logs) do
			local line_added = self:AddLogsLine(listview, v, tbl.roles, nofilters, old)
			if not added and line_added then
				added = true
			end
		end
		if not added then
			listview:AddLine("", "", TTTLogTranslate(GetDMGLogLang, "EmptyLogsFilters"))
		end
	else
		listview:AddLine("", "", TTTLogTranslate(GetDMGLogLang, "EmptyLogs"))
	end
end

function Damagelog:SetRolesListView(listview, tbl)
	listview:Clear()
	if not tbl then return end
	for k,v in pairs(tbl) do
		if not GetConVar("ttt_dmglogs_showinnocents"):GetBool() and v.role == ROLE_INNOCENT then continue end
		self:AddRoleLine(listview, v.nick, v.role)
	end
end

local role_colors = {
	[0] = Color(0, 200, 0),
	[1] = Color(200, 0, 0),
	[2] = Color(0, 0, 200)
}

function Damagelog:AddRoleLine(listview, nick, role)
	if (role != 5) then
		local item = listview:AddLine(nick, self:StrRole(role), "")
		function item:PaintOver()
			for k,v in pairs(item.Columns) do
				v:SetTextColor(role_colors[role])
			end
		end
		item.Nick = nick
		item.Round = self.SelectedRound
		local sync_ent = self:GetSyncEnt()
		item.Think = function(panel)
			if GetRoundState() == ROUND_ACTIVE and sync_ent:GetPlayedRounds() == panel.Round then
				local ent = self.RoleNicks and self.RoleNicks[panel.Nick]
				if IsValid(ent) then
					panel:SetColumnText(3, ent:Alive() and not (ent.IsGhost and ent:IsGhost()) and not ent:IsSpec() and TTTLogTranslate(GetDMGLogLang, "Yes") or TTTLogTranslate(GetDMGLogLang, "No"))
				else
					panel:SetColumnText(3, TTTLogTranslate(GetDMGLogLang, "ChatDisconnected"))
				end
			else
				panel:SetColumnText(3, TTTLogTranslate(GetDMGLogLang, "RoundEnded"))
			end
		end
	end
end


local shoot_colors = {
    [Color(46,46,46)] = true,
	[Color(66,66,66)] = true,
	[Color(125,125,125)] = true,
	[Color(255,6,13)] = true,
	[Color(0,0,128)] = true,
	[Color(0,0,205)] = true,
	[Color(79,209,204)] = true,
	[Color(165,42,42)] = true,
	[Color(238,59,59)] = true,
	[Color(210,105,30)] = true,
	[Color(255,165,79)] = true,
	[Color(107,66,38)] = true,
	[Color(166,128,100)] = true,
	[Color(0,100,0)] = true,
	[Color(34,139,34)] = true,
	[Color(124,252,0)] = true,
	[Color(78,328,148)] = true,
	[Color(139,10,80)] = true,
	[Color(205,16,118)] = true,
	[Color(205,85,85)] = true,
	[Color(110,6,250)] = true,
	[Color(30,235,0)] = true,
	[Color(205,149,12)] = true,
	[Color(0,0,250)] = true,
	[Color(219,150,50)] = true,
	[Color(255,36,0)] = true,
	[Color(205,104,57)] = true,
	[Color(191,62,255)] = true,
	[Color(99,86,126)] = true,
	[Color(133,99,99)] = true
}

function Damagelog:SetDamageInfosLV(listview, roles, att, victim, beg, t, result)
	if not IsValid(self.Menu) then return end
	for k,v in pairs(shoot_colors) do
		shoot_colors[k] = true
	end
	if beg then
		beg = string.FormattedTime(math.Clamp(beg, 0, 999), "%02i:%02i")
	end
	if t then
		t = string.FormattedTime(t, "%02i:%02i")
	end
	listview:Clear()
	if victim and att then
		listview:AddLine(string.format(TTTLogTranslate(GetDMGLogLang, "DamageInfosBetween"), victim, att, beg, t))
	end
	if not result or table.Count(result) <= 0 then
		listview:AddLine(TTTLogTranslate(GetDMGLogLang, "EmptyLogs"))
	else
		local nums = {}
		local used_nicks = {}
		for k,v in pairs(result) do
			table.insert(nums, k)
		end
		table.sort(nums)
		local players = {}
		for k,v in ipairs(nums) do
			local info = result[v]
			local color
			for s,i in pairs(info) do
				if att and victim then
					if not players[1] then
						players[1] = i[1]
					else
						if not players[2] then
							players[2] = i[1]
						end
					end
				else
					if not used_nicks[i[1]] then
						local found = false
						for k,v in RandomPairs(shoot_colors) do
							if v and not found then
								color = k
								found = true
							end
						end
						if found then
							shoot_colors[color] = false
							used_nicks[i[1]] = color
						else
							used_nicks[i[1]] = COLOR_WHITE
						end
					else
						color = used_nicks[i[1]]
					end
				end
				local item
				if i[2] == "crowbartir" then -- Currently unused
					item = listview:AddLine(string.format(TTTLogTranslate(GetDMGLogLang, "CrowbarSwung"), string.FormattedTime(v, "%02i:%02i"), self:InfoFromID(roles, i[1]).nick))
				elseif i[2] == "crowbarpouss" then -- Currently unused
					item = listview:AddLine(string.format(TTTLogTranslate(GetDMGLogLang, "HasPushed"), string.FormattedTime(v, "%02i:%02i"), self:InfoFromID(roles, i[1]).nick, self:InfoFromID(roles,i[3]).nick))
				else
					wep = Damagelog:GetWeaponName(i[2]) or TTTLogTranslate(GetDMGLogLang, "UnknownWeapon")
					item = listview:AddLine(string.format(TTTLogTranslate(GetDMGLogLang, "HasShot"), string.FormattedTime(v, "%02i:%02i"), self:InfoFromID(roles,i[1]).nick, wep))
				end
				item.PaintOver = function()
					if att and victim then
						if i[1] == players[1] then
							item.Columns[1]:SetTextColor(color_darkblue)
						elseif i[1] == players[2] then
							item.Columns[1]:SetTextColor(color_orange)
						end
					else
						item.Columns[1]:SetTextColor(color)
					end
				end
			end
		end
	end
	self.DamageInfoBox:Toggle()
end