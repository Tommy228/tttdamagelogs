local mdl = Model("models/player/arctic.mdl")
CreateClientConVar("ttt_dmglogs_slowmo", "0", FCVAR_ARCHIVE)
CreateClientConVar("ttt_dmglogs_ds_showothers", "1", FCVAR_ARCHIVE)
local i = 1
local current_scene
local roles
local models = {}
local props = {}
local last_curtime
local victim
local attacker
local playedsounds = {}
local ttt_specdm_hook
local current_spec
local previous_spec
local paused
local color_grey = Color(150, 150, 150)

local color_effect = {
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0,
	["$pp_colour_addb"] = 0,
	["$pp_colour_brightness"] = 0,
	["$pp_colour_contrast"] = 1,
	["$pp_colour_colour"] = 0,
	["$pp_colour_mulr"] = 0.,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0
}

hook.Add("Initialize", "GetSpecDMHook", function()
	local tbl = hook.GetTable().Think

	if tbl then
		ttt_specdm_hook = tbl.Think_Ghost
	end
end)

surface.CreateFont("DL_Shots_Title", {
	font = "DermaLarge",
	size = 18
})

local function CreateShotsPanel()

	local w, h = 400, 200

	local Frame = vgui.Create("DPanel")
	Frame:SetSize(w, h)
	Frame.PaintOver = function(self, w, h)
		surface.SetDrawColor(color_black)
		surface.DrawLine(0, 0, w - 1, 0)
		surface.DrawLine(w - 1, 0, w - 1, h - 1)
		surface.DrawLine(w - 1, h - 1, 0, h - 1)
		surface.DrawLine(0, h - 1, 0, 0)
	end
	Frame:SetPos(ScrW() - w)
	Frame:CenterVertical()

	local Close = vgui.Create("DButton", Frame)
	Close:SetText("X")
	Close:SetSize(20, 20)
	Close:SetPos(w - 25, 5)
	Close.DoClick = function()
		Frame:SetVisible(false)
	end

	local Title = vgui.Create("DLabel", Frame)
	Title:SetPos(0, 10)
	Title:SetFont("DL_Shots_Title")
	Title:SetTextColor(color_black)
	Title:SetText(TTTLogTranslate(GetDMGLogLang, "DeathShotsInfo"))
	Title:SizeToContents()
	Title:CenterHorizontal()

	local ShowOthers = vgui.Create("DCheckBoxLabel", Frame)
	ShowOthers:SetText(TTTLogTranslate(GetDMGLogLang, "ShowAllPlayers"))
	ShowOthers:SetConVar("ttt_dmglogs_ds_showothers")
	ShowOthers:SetPos(10, 35)
	ShowOthers:SetTextColor(color_black)
	ShowOthers:SizeToContents()

	local Info = vgui.Create("DListView", Frame)
	Info:StretchToParent(10, 60, 10, 10)
	Info:AddColumn("")
	Info.UpdateProgress = function(Info, progress)
		local current_second = math.Round(progress * 0.2, 1) + 1
		for k,v in ipairs(Info:GetLines()) do
			local second = Info.LinesInfo[k]
			if not second then continue end
			local diff = current_second - second
			v:SetSelected(diff < 0.2 and diff > 0)
		end
	end
	Info.LinesInfo = {}

	Frame.SetInfo = function(Frame)
		if not current_scene then return end
		Info:Clear()
		table.Empty(Info.LinesInfo)
		local showAll = GetConVar("ttt_dmglogs_ds_showothers"):GetBool()
		local size = #current_scene
		local current_second = 1
		for i=1, size do
			local moment = current_scene[i]
			current_second = current_second + 0.2
			for id, tbl in ipairs(moment) do
				if not tbl.shot then continue end
				if not showAll and id != victim and id != attacker then continue end
				local nick = Damagelog:InfoFromID(roles, id).nick
				local wep = Damagelog:GetWeaponName(tbl.wep) or TTTLogTranslate(GetDMGLogLang, "UnknownWeapon")
				local line = Info:AddLine(string.format(TTTLogTranslate(GetDMGLogLang, "HasShot"), current_second.."s", nick, wep))
				if id == victim then
					line.col = Color(20, 150, 20)
				elseif id == attacker then
					line.col = Color(200, 20, 20)
				else
					line.col = color_black
				end
				line.PaintOver = function(line)
					if line:IsLineSelected() then
						line.Columns[1]:SetTextColor(color_white)
					else
						line.Columns[1]:SetTextColor(line.col)
					end
				end
				table.insert(Info.LinesInfo, current_second)
			end
		end
	end

	Frame.UpdateProgress = function(Frame, progress)
		Info:UpdateProgress(progress)
	end

	Frame:SetVisible(false)

	return Frame

end

local Frame
hook.Add("Initialize", "DeathSceneFrame", function()
	Frame = CreateShotsPanel()
	Damagelog.DeathSceneInitialized = true
end)

if Damagelog.DeathSceneInitialized then
	Frame = CreateShotsPanel()
end

cvars.AddChangeCallback("ttt_dmglogs_ds_showothers", function()
	if IsValid(Frame) then
		Frame:SetInfo()
	end
end)

function Damagelog:CreateDSPanel()
	if IsValid(self.DSPanel) then
		self.DSPanel:Remove()
	end

	local w, h = 500, 100
	self.DSPanel = vgui.Create("DPanel")
	self.DSPanel:SetSize(w, h)
	self.DSPanel:SetPos(nil, ScrH() - (h + 20))
	self.DSPanel:CenterHorizontal()

	self.DSPanel.PaintOver = function(self, w, h)
		surface.SetDrawColor(color_black)
		surface.DrawLine(0, 0, w - 1, 0)
		surface.DrawLine(w - 1, 0, w - 1, h - 1)
		surface.DrawLine(w - 1, h - 1, 0, h - 1)
		surface.DrawLine(0, h - 1, 0, 0)
		surface.SetDrawColor(color_grey)
		surface.DrawLine(120, 10, 120, h - 10)
	end

	local margin = 5
	local w_button, h_button = 100, h / 3 - (4 * margin) / 3
	local free, spectate_victim
	local spectate_attacker = vgui.Create("DButton", self.DSPanel)
	spectate_attacker:SetPos(margin, margin)
	spectate_attacker:SetSize(w_button, h_button)
	spectate_attacker:SetText(TTTLogTranslate(GetDMGLogLang, "SpectateAttacker"))
	spectate_attacker:SetEnabled(false)

	spectate_attacker.DoClick = function()
		current_spec = attacker
		spectate_victim:SetEnabled(true)
		free:SetEnabled(true)
		spectate_attacker:SetEnabled(false)
	end

	spectate_victim = vgui.Create("DButton", self.DSPanel)
	spectate_victim:SetPos(margin, h_button + margin * 2)
	spectate_victim:SetSize(w_button, h_button)
	spectate_victim:SetText(TTTLogTranslate(GetDMGLogLang, "SpectateVictim"))

	spectate_victim.DoClick = function()
		current_spec = victim
		spectate_victim:SetEnabled(false)
		free:SetEnabled(true)
		spectate_attacker:SetEnabled(true)
	end

	free = vgui.Create("DButton", self.DSPanel)
	free:SetPos(margin, h_button * 2 + margin * 3)
	free:SetSize(w_button, h_button)
	free:SetText(TTTLogTranslate(GetDMGLogLang, "FreeMode"))

	free.DoClick = function()
		current_spec = 0
		spectate_victim:SetEnabled(true)
		free:SetEnabled(false)
		spectate_attacker:SetEnabled(true)
	end

	local note = vgui.Create("DLabel", self.DSPanel)
	note:SetText(TTTLogTranslate(GetDMGLogLang, "EnableMouse"))
	note:SetTextColor(color_black)
	note:SetPos(140, 10)
	note:SizeToContents()
	self.DS_Progress = vgui.Create("DSlider", self.DSPanel)
	self.DS_Progress:SetPos(140, 38)
	self.DS_Progress:SetSize(w - 160, 20)
	Derma_Hook(self.DS_Progress, "Paint", "Paint", "NumSlider")
	local play = vgui.Create("DButton", self.DSPanel)
	play:SetPos(140, h - 35)
	play:SetSize(25, 25)
	play:SetText("")
	play.Icon = vgui.Create("DImage", play)
	play.Icon:SetSize(16, 16)
	play.Icon:Center()
	play.Icon:SetImage("icon16/control_pause_blue.png")

	play.DoClick = function()
		if paused then
			play.Icon:SetImage("icon16/control_pause_blue.png")
			paused = false
		else
			play.Icon:SetImage("icon16/control_play_blue.png")
			paused = true
		end
	end

	self.DS_Play = play
	local replay = vgui.Create("DButton", self.DSPanel)
	replay:SetPos(170, h - 35)
	replay:SetSize(25, 25)
	replay:SetText("")
	replay.Icon = vgui.Create("DImage", replay)
	replay.Icon:SetSize(16, 16)
	replay.Icon:Center()
	replay.Icon:SetImage("icon16/control_repeat_blue.png")

	local showShots = vgui.Create("DButton", self.DSPanel)
	showShots:SetPos(200, h - 35)
	showShots:SetSize(25, 25)
	showShots:SetText("")
	showShots.Icon = vgui.Create("DImage", showShots)
	showShots.Icon:SetSize(16, 16)
	showShots.Icon:Center()
	showShots.Icon:SetImage("icon16/gun.png")
	showShots.DoClick = function()
		Frame:SetVisible(not Frame:IsVisible())
	end

	self.DS_Replay = replay

	local slowmo = vgui.Create("DCheckBoxLabel", self.DSPanel)
	slowmo:SetText(TTTLogTranslate(GetDMGLogLang, "EnableSlowMotion"))
	slowmo:SetConVar("ttt_dmglogs_slowmo")
	slowmo:SetPos(w - 125, h - 30)
	slowmo:SetTextColor(color_black)
	slowmo:SizeToContents()

	local stop = vgui.Create("DButton", self.DSPanel)
	stop:SetText("X")
	stop:SetSize(20, 20)
	stop:SetPos(w - 25, 5)

	stop.DoClick = function()
		self:StopRecording()
	end

end

net.Receive("DL_SendDeathScene", function()
	victim = net.ReadUInt(32)
	attacker = net.ReadUInt(32)
	roles = net.ReadTable()
	local sceneSize = net.ReadUInt(32)
	local sceneString = net.ReadData(sceneSize)
	sceneString = util.Decompress(sceneString)
	current_scene = util.JSONToTable(sceneString)

	Damagelog:CreateDSPanel()

	i = 1
	models = {}
	props = {}
	playedsounds = {}
	current_spec = nil
	previous_spec = nil

	if IsValid(Damagelog.Menu) then
		Damagelog.Menu:SetVisible(false)
	end

	Frame:SetInfo()

	paused = false
end)

local attacker_mat = Material("cable/redlaser")
local neutral_mat = Material("cable/blue_elec")
local victim_mat = Material("cable/green")

hook.Add("RenderScreenspaceEffects", "DeathScene_Damagelog", function()
	if current_scene then
		DrawColorModify(color_effect)
		cam.Start3D(EyePos(), EyeAngles())

		for k, v in pairs(models) do
			if not IsValid(v) then continue end
			render.SuppressEngineLighting(true)
			local color = Color(125, 125, 255)
			local shot_mat = neutral_mat
			cam.IgnoreZ(true)

			if k == attacker then
				color = Color(255, 125, 125)
				shot_mat = attacker_mat
			elseif k == victim then
				color = Color(125, 255, 125)
				shot_mat = victim_mat
			end

			render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
			v:DrawModel()
			render.SetColorModulation(1, 1, 1)
			cam.IgnoreZ(false)

			if v.traces then
				render.SetMaterial(shot_mat)

				for k, v in pairs(v.traces) do
					if v then
						render.DrawBeam(v[1], v[2], 2, 0, 0, color)
					end
				end
			end

			render.SuppressEngineLighting(false)
		end

		for k, v in pairs(props) do
			if not IsValid(v) then continue end
			render.SuppressEngineLighting(true)
			render.SetColorModulation(0.6, 0.4, 0)
			cam.IgnoreZ(true)
			v:DrawModel()
			render.SetColorModulation(1, 1, 1)
			cam.IgnoreZ(false)
			render.SuppressEngineLighting(false)
		end

		cam.End3D()
	end
end)

hook.Add("HUDPaint", "Scene_Record", function()
	if current_scene then
		surface.SetFont("TabLarge")

		for id, model in pairs(models) do
			local nick = Damagelog:InfoFromID(roles, id).nick
			if model.corpse then
				local pos = model.pos:ToScreen()
				if IsOffScreen(pos) then continue end

				if model.found then
					surface.SetTextColor(Color(255, 200, 15))
				else
					surface.SetTextColor(Color(255, 0, 0))
				end

				local text = nick .. TTTLogTranslate(GetDMGLogLang, "scorpse") .. (model.found and "(ID)" or "(UnID)")
				local w = surface.GetTextSize(text)
				surface.SetTextPos(pos.x - w / 2, pos.y)
				surface.DrawText(text)
			else
				local pos = model:GetPos() + Vector(0, 0, 100)
				pos = pos:ToScreen()
				if IsOffScreen(pos) then continue end
				local wep = model.wep

				if wep then
					local wepEntityName = Damagelog:GetWeaponName(wep) or wep
					if wepEntityName then
						wep = wepEntityName
					else
						TTTLogTranslate(GetDMGLogLang, "UnknownWeapon")
					end
				else
					wep = TTTLogTranslate(GetDMGLogLang, "NoWeapon")
				end

				local w = surface.GetTextSize(wep)
				surface.SetTextColor(color_white)
				surface.SetTextPos(pos.x - w / 2, pos.y)
				surface.DrawText(wep)
				local _, healthcolor = util.HealthToString(model.hp or 100)
				nick = nick .. " [" .. Damagelog:StrRole(model.role) .. "]"
				local w2, h2 = surface.GetTextSize(nick)
				surface.SetTextColor(healthcolor)
				surface.SetTextPos(pos.x - w2 / 2, pos.y - h2 - 5)
				surface.DrawText(nick)
			end
		end

		return
	end
end)

hook.Add("Think", "Think_Record", function()
	for k, v in pairs(models) do
		if not IsValid(v) then continue end

		if v.move_x and v.move_y and v.spin then
			v:SetPoseParameter("move_x", v.move_x)
			v:SetPoseParameter("move_y", v.move_y)
			v:SetPoseParameter("spin_yaw", v.spin)
		end

		v:FrameAdvance(FrameTime())
	end

	if current_scene and (not last_curtime or (last_curtime and (CurTime() - last_curtime) >= 0.01)) then
		gui.EnableScreenClicker(input.IsKeyDown(KEY_C))

		for k, v in ipairs(player.GetHumans()) do
			v:SetNoDraw(true)
		end

		local slowmo = GetConVar("ttt_dmglogs_slowmo"):GetBool()

		if not paused and not Damagelog.DS_Progress:IsEditing() then
			if slowmo then
				i = i + 0.03
			else
				i = i + 0.08
			end
		end

		Damagelog.DS_Progress.TranslateValues = function(self, x, y)
			i = #current_scene * x

			return x, y
		end

		Damagelog.DS_Replay.DoClick = function()
			i = 1
		end

		if i < 1 then
			i = 1
		end

		local progress = #current_scene - (#current_scene - i)

		if progress > #current_scene then
			progress = #current_scene
		end

		Frame:UpdateProgress(i)

		Damagelog.DS_Progress:SetSlideX(progress / #current_scene)
		Damagelog.DS_Progress:SetSlideY(0.5)
		last_curtime = CurTime()
		local scene = current_scene[math.floor(i)]
		local next_scene = current_scene[math.ceil(i)]

		if scene then
			for k, v in pairs(models) do
				if not scene[k] then
					if IsValid(v) then
						v:Remove()
					end

					models[k] = nil
				end
			end

			for k, v in pairs(props) do
				if not scene[k] then
					v:Remove()
					props[k] = nil
				end
			end
		else
			if not paused and Damagelog.DS_Play.Icon:GetImage() == "icon16/control_pause_blue.png" then
				Damagelog.DS_Play:DoClick()
			end
		end

		local changed = false

		if not current_spec and not previous_spec then
			current_spec = attacker
			previous_spec = attacker
			changed = true
		end

		if current_spec != previous_spec then
			previous_spec = current_spec
			changed = true
		end

		if changed and current_spec == 0 then
			net.Start("DL_UpdateLogEnt")
			net.WriteUInt(0, 1)
			net.SendToServer()
		end

		for k, v in pairs(scene or {}) do
			if v.prop then
				if not props[k] then
					props[k] = ClientsideModel(v.model or "", RENDERGROUP_TRANSLUCENT)
				end

				local vector = v.pos
				local angle = v.ang

				if next_scene and next_scene[k] then
					local percent = math.ceil(i) - i
					vector = LerpVector(percent, next_scene[k].pos, v.pos)
					angle = LerpAngle(percent, next_scene[k].ang, v.ang)
				end

				props[k]:SetPos(vector)
				props[k]:SetAngles(angle)
				continue
			end

			if models[k] and v.corpse and not models[k].corpse then
				if IsValid(models[k]) then
					models[k]:Remove()
				end

				models[k] = nil
			end

			if not IsValid(models[k]) then
				if not v.corpse then
					models[k] = ClientsideModel(mdl, RENDERGROUP_TRANSLUCENT)
					models[k]:AddEffects(EF_NODRAW)
					models[k].role = v.role
				else
					models[k] = {
						corpse = true
					}
				end
			end

			if v.corpse then
				models[k].pos = v.pos
				models[k].ang = v.ang
				models[k].found = v.found
			else
				local vector = v.pos
				local angle = v.ang

				if next_scene and next_scene[k] and next_scene[k].pos and next_scene[k].ang then
					local percent = math.ceil(i) - i
					vector = LerpVector(percent, next_scene[k].pos, v.pos)
					angle = LerpAngle(percent, next_scene[k].ang, v.ang)
				end

				models[k].wep = v.wep
				models[k].hp = v.hp

				if models[k].SetSequence then
					models[k]:SetSequence(v.sequence)
				end

				if paused then
					models[k]:SetPlaybackRate(0)
				elseif slowmo then
					models[k]:SetPlaybackRate(0.4)
				else
					models[k]:SetPlaybackRate(1)
				end

				models[k].move_x = vector.x
				models[k].move_y = vector.y
				models[k].spin = angle.z
				models[k].move_yaw = v.move_yaw
				models[k]:SetPos(vector)
				models[k]:SetAngles(angle)
			end
		end

		if scene and playedsounds ~= scene then
			for k, v in pairs(scene) do
				if v.shot then
					local playedSound = v.wep == "weapon_zm_improvised" and "Weapon_Crowbar.Single" or v.shot
					models[k]:EmitSound(playedSound, 100, 100)
				end

				if v.trace then
					if not models[k].traces then
						models[k].traces = {}
					end

					local index = table.insert(models[k].traces, v.trace)

					timer.Simple(0.2, function()
						if models[k] and models[k].traces then
							models[k].traces[index] = false
						end
					end)
				end
			end

			playedsounds = scene
		end
	end
end)

function Damagelog:IsRecording()
	return current_scene and true or false
end

function Damagelog:StopRecording()
	self.DSPanel:Remove()
	net.Start("DL_UpdateLogEnt")
	net.WriteUInt(0, 1)
	net.SendToServer()

	for k, v in pairs(models) do
		if IsValid(v) then
			v:Remove()
		end
	end

	for k, v in pairs(props) do
		if IsValid(v) then
			v:Remove()
		end
	end

	table.Empty(models)
	table.Empty(props)
	current_scene = nil
	i = 1
	playedsounds = {}

	if ttt_specdm_hook then
		hook.Add("Think", "Think_Ghost", ttt_specdm_hook)
	end

	for k, v in ipairs(player.GetHumans()) do
		v:SetNoDraw(false)
	end

	gui.EnableScreenClicker(false)

	if IsValid(self.Menu) then
		self.Menu:SetVisible(true)
	end

	if IsValid(Frame) then
		Frame:SetVisible(false)
	end

end

hook.Add("OnContextMenuOpen", "Recording", function()
	if current_scene then return false end
end)

local ViewHullMins = Vector(-8, -8, -8)
local ViewHullMaxs = Vector(8, 8, 8)

local function GetThirdPersonCameraPos(origin, angles)
	origin = origin + Vector(0, 0, 50)
	local allplayers = player.GetAll()

	local tr = util.TraceHull({
		start = origin,
	endpos = origin + angles:Forward() * -92,
	mask = MASK_SHOT,
	filter = allplayers,
	mins = ViewHullMins,
	maxs = ViewHullMaxs
})

return tr.HitPos + tr.HitNormal * 3, angles
end

hook.Add("CalcView", "Death_Scene", function(pl, origin, angles, fov, znear, zfar)
	if current_scene then
		for k, v in pairs(models) do
			if not IsValid(v) or current_spec ~= k then continue end
			origin = GetThirdPersonCameraPos(v:GetPos(), angles)

			return GAMEMODE.BaseClass.CalcView(GAMEMODE, pl, origin, angles, fov, znear, zfar)
		end
	end
end)
