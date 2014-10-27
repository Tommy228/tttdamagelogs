
local mdl = Model("models/player/arctic.mdl")

local i = 1
local current_scene
local models = {}
local last_curtime
local victim
local attacker
local playedsounds = {}

local color_effect = {
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg" ] = 0,
	["$pp_colour_addb" ] = 0,
	["$pp_colour_brightness" ] = 0,
	["$pp_colour_contrast" ] = 1,
	["$pp_colour_colour" ] = 0,
	["$pp_colour_mulr" ] = 0.,
	["$pp_colour_mulg" ] = 0,
	["$pp_colour_mulb" ] = 0
}

net.Receive("DL_SendDeathScene", function()
	victim = net.ReadString()
	attacker = net.ReadString()
	local length = net.ReadUInt(32)
	local compressed = net.ReadData(length)
	local encoded = util.Decompress(compressed)
	local data = util.JSONToTable(encoded)
	i = 1
	current_scene = data
	models = {}
	playedsounds = {}
	if IsValid(Damagelog.Menu) then
		Damagelog.Menu:SetVisible(false)
	end
end)

local attacker_mat = Material("cable/redlaser")
local neutral_mat = Material("cable/blue_elec")
local victim_mat = Material("cable/green")

hook.Add("RenderScreenspaceEffects", "DeathScene_Damagelog", function()
	if current_scene then
		DrawColorModify(color_effect)
		cam.Start3D(EyePos(), EyeAngles())
		for k,v in pairs(models) do
			if not IsValid(v) then continue end
			render.SuppressEngineLighting(true)
			local color = Color(125, 125, 255)
			local shot_mat = neutral_mat
			local matsize = 5
			cam.IgnoreZ(true)
			if k == attacker then
				color = Color(255, 125, 125)
				shot_mat = attacker_mat
				matsize = 4
			elseif k == victim then
				color = Color(125, 255, 125)
				shot_mat = victim_mat
				matsize = 2
			end
			render.SetColorModulation(color.r/255, color.g/255, color.b/255)
			v:DrawModel()
			render.SetColorModulation(1, 1, 1)
			cam.IgnoreZ(false)
			if v.traces then
				render.SetMaterial(shot_mat)
				for k,v in pairs(v.traces) do
					if v then
						render.DrawBeam(v[1], v[2], 2, 0, 0, color)
					end
				end
			end
			render.SuppressEngineLighting(false)
		end
		cam.End3D()
	end
end)

hook.Add("HUDPaint", "Scene_Record", function()

	if current_scene then
		surface.SetFont("TabLarge")
		for nick,model in pairs(models) do
			if model.corpse then
				local pos = model.pos:ToScreen()
				if IsOffScreen(pos) then continue end
				if not found then
					surface.SetTextColor(Color(255, 200, 15))
				else
					surface.SetTextColor(color_white)
				end
				local text = nick.."'s corpse"
				local w,h = surface.GetTextSize(text)
				surface.SetTextPos(pos.x - w/2, pos.y)
				surface.DrawText(text)
			else
				local pos = model:GetPos() + Vector(0, 0, 100)
				pos = pos:ToScreen()
				if IsOffScreen(pos) then continue end
				local wep = model.wep
				if wep then
					local name = Damagelog.weapon_table[wep]
					if name then
						wep = name
					end
				else
					wep = "<No weapon>"
				end
				local w,h = surface.GetTextSize(wep)
				surface.SetTextColor(color_white)
				surface.SetTextPos(pos.x - w/2, pos.y)
				surface.DrawText(wep)
				local _, healthcolor = util.HealthToString(model.hp or 100)
				nick = nick.." ["..Damagelog:StrRole(model.role).."]"
				local w2,h2 = surface.GetTextSize(nick)
				surface.SetTextColor(healthcolor)
				surface.SetTextPos(pos.x - w2/2, pos.y - h2 - 5)
				surface.DrawText(nick)
			end
		end
		return
	end

end)

hook.Add("Think", "Think_Record", function()
	for k,v in pairs(models) do
		if not IsValid(v) then continue end
		if v.move_x and v.move_y and v.spin then
			v:SetPoseParameter("move_x", v.move_x)
			v:SetPoseParameter("move_y", v.move_y)
			v:SetPoseParameter("spin_yaw", v.spin)
		end
		v:FrameAdvance(FrameTime())
	end
	if current_scene and (not last_curtime or (last_curtime and (CurTime() - last_curtime) >= 0.01)) then
		i = i + 0.08
		last_curtime = CurTime()
		local scene = current_scene[math.floor(i)]
		local next_scene = current_scene[math.ceil(i)]
		if not scene then
			timer.Simple(5, function()
				Damagelog:StopRecording()
				if IsValid(Damagelog.Menu) then
					Damagelog.Menu:SetVisible(true)
				end
			end)
		else
			for k,v in pairs(models) do
				if not scene[k] then
					v:Remove()
					models[k] = nil
				end
			end
			for k,v in pairs(scene) do
				if models[k] and v.corpse and not models[k].corpse then
					if IsValid(models[k]) then
						models[k]:Remove()
					end
					models[k] = nil
				end
				if not models[k] then
					if not v.corpse then
						models[k] = ClientsideModel(mdl, RENDERGROUP_TRANSLUCENT)
						models[k]:AddEffects(EF_NODRAW)
						models[k].role = v.role
					else
						models[k] = { corpse = true }
					end
				end
				if v.corpse then
					models[k].pos = v.pos
					models[k].ang = v.ang
				else
					local vector = v.pos
					local angle = v.ang
					if next_scene and next_scene[k] then
						local percent = math.ceil(i) - i
						vector = LerpVector(percent, next_scene[k].pos, v.pos)
						angle = LerpAngle(percent, next_scene[k].ang, v.ang)
					end
					models[k].wep = v.wep
					models[k].hp = v.hp
					if models[k].SetSequence then
						models[k]:SetSequence(v.sequence)
					end
					models[k].move_x = vector.x
					models[k].move_y = vector.y
					models[k].spin = angle.z
					models[k].move_yaw = v.move_yaw
					models[k]:SetPos(vector)
					models[k]:SetAngles(angle)
				end
			end
			if not playedsounds[scene] then
				for k,v in pairs(scene) do
					if v.shot then
						models[k]:EmitSound(v.shot, 100, 100)
					end
					if v.trace then
						if not models[k].traces then
							models[k].traces = {}
						end
						local index = table.insert(models[k].traces, v.trace)
						timer.Simple(0.2, function()
							if models[k].traces then
								models[k].traces[index] = false
							end
						end)
					end
				end
				playedsounds[scene] = true
			end
		end
	end
end)

function Damagelog:IsRecording()
	return current_scene and true or false
end

function Damagelog:StopRecording()
	for k,v in pairs(models) do
		if IsValid(v) then
			v:Remove()
		end
	end
	table.Empty(models)
	current_scene = nil
	i = 1
	playedsounds = {}
end
