
util.AddNetworkString("DL_AskDeathScene")
util.AddNetworkString("DL_SendDeathScene")
util.AddNetworkString("DL_UpdateLogEnt")

Damagelog.Records = Damagelog.Records or {}
Damagelog.Death_Scenes = Damagelog.Death_Scenes or {}
Damagelog.SceneID = Damagelog.SceneID or 0

hook.Add("TTTBeginRound", "TTTBeginRound_SpecDMRecord", function()
	table.Empty(Damagelog.Records)
	for k,ply in pairs(player.GetAll()) do
		ply.SpectatingLog = false
	end
end)

timer.Create("SpecDM_Recording", 0.2, 0, function()

	if not GetRoundState or GetRoundState() != ROUND_ACTIVE then return end

	if #Damagelog.Records >= 50 then
		table.remove(Damagelog.Records, 1)
	end
	
	local tbl = {}

	for k,v in pairs(player.GetAll()) do
		if not v:IsActive() then 
			local rag = v.server_ragdoll
			if IsValid(rag) then
				local pos,ang = rag:GetPos(), rag:GetAngles()
				tbl[v:Nick()] = {
					corpse = true,
					pos = pos,
					ang = ang,
					found = CORPSE.GetFound(rag, false)
				}
			end
		else
			local wep = v:GetActiveWeapon()
			wep = IsValid(wep) and wep:GetClass()
			tbl[v:Nick()] = {
				pos = v:GetPos(),
				ang = v:GetAngles(),
				sequence = v:GetSequence(),
				hp = v:Health(),
				wep = wep,
				role = v:GetRole()
			}
		end
	end

	table.insert(Damagelog.Records, tbl)

end)

net.Receive("DL_AskDeathScene", function(_, ply)
	local ID = net.ReadUInt(32)
	local ply1 = net.ReadString()
	local ply2 = net.ReadString()
	local scene = Damagelog.Death_Scenes[ID]
	if scene then
		local encoded = util.TableToJSON(scene)
		local compressed = util.Compress(encoded)
		net.Start("DL_SendDeathScene")
		net.WriteString(ply1)
		net.WriteString(ply2)
		net.WriteUInt(#compressed, 32)
		net.WriteData(compressed, #compressed)
		net.Send(ply)
	end
end)

local Player = FindMetaTable("Player")

function Player:CreateLogEnt()
	local ent = ents.Create("prop_dynamic")
	ent:SetModel("models/error.mdl")
	ent:Spawn()
	ent:Activate()
	ent:SetSolid(SOLID_NONE)
	ent:SetMoveType(MOVETYPE_NONE)
	ent:SetRenderMode(RENDERMODE_NONE)
	ent:SetOwner(self)
	self.LogEnt = ent
end

hook.Add("PlayerInitialSpawn","DamagelogRecording", function(ply)
	ply:CreateLogEnt()
end)

net.Receive("DL_UpdateLogEnt", function(_len, ply)
	local pos, first
	local disable = net.ReadUInt(1) == 0
	if not disable then
		pos = net.ReadVector()
		first = net.ReadUInt(1) == 1
	end
	if not ply:IsSpec() then return end
	if not IsValid(ply.LogEnt) then return end
	if disable then
		ply:SpectateEntity(nil)
		ply:Spectate(OBS_MODE_ROAMING)
		ply.SpectatingLog = false
	else
		pos = pos + Vector(0, 0, 45)
		ply.LogEnt:SetPos(pos)
		ply.SpectatingLog = true
		if first then
			ply:SpectateEntity(ply.LogEnt)
			ply:Spectate(OBS_MODE_CHASE)
		end
	end
end)

hook.Add("Initialize", "DamagelogRecording", function()
	local old_think = GAMEMODE.KeyPress
	function GAMEMODE:KeyPress(ply, key)
		if not (ply.SpectatingLog and (key == IN_ATTACK or key == IN_ATTACK2)) then
			return old_think(self, ply, key)
		end
	end
end)