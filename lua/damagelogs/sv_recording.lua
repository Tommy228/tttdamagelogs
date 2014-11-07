
util.AddNetworkString("DL_AskDeathScene")
util.AddNetworkString("DL_SendDeathScene")
util.AddNetworkString("DL_UpdateLogEnt")

Damagelog.Records = Damagelog.Records or {}
Damagelog.Death_Scenes = Damagelog.Death_Scenes or {}
Damagelog.SceneID = Damagelog.SceneID or 0

local magneto_ents = {}

hook.Add("TTTBeginRound", "TTTBeginRound_SpecDMRecord", function()
	table.Empty(magneto_ents)
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
	
	for k,v in pairs(magneto_ents) do
		if CurTime() - v.last_saw > 15 then
			v.record = false
		end
	end

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
			tbl[v:Nick()] = {
				pos = v:GetPos(),
				ang = v:GetAngles(),
				sequence = v:GetSequence(),
				hp = v:Health(),
				wep = IsValid(wep) and wep:GetClass() or "<no wep>",
				role = v:GetRole()
			}
			if IsValid(wep) and wep:GetClass() == "weapon_zm_carry" and IsValid(wep.EntHolding) then
				local found = false
				for k,v in pairs(magneto_ents) do
					if v.ent == wep.EntHolding then
						found = k
						break
					end
				end
				if found then
					magneto_ents[found].last_saw = CurTime()
					magneto_ents[found].record = true
				else
					table.insert(magneto_ents, {
						ent = wep.EntHolding,
						record = true,
						last_saw = CurTime()
					})
				end
			end
		end
	end
	
	for k,v in pairs(magneto_ents) do
		if v.record and IsValid(v.ent) then
			table.insert(tbl, v.ent:EntIndex(), {
				model = v.ent:GetModel(),
				pos = v.ent:GetPos(),
				ang = v.ent:GetAngles()
			})
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

hook.Add("Initialize", "DamagelogRecording", function()
	local old_think = GAMEMODE.KeyPress
	function GAMEMODE:KeyPress(ply, key)
		if not (ply.SpectatingLog and (key == IN_ATTACK or key == IN_ATTACK2)) then
			return old_think(self, ply, key)
		end
	end
end)