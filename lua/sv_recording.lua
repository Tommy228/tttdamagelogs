
util.AddNetworkString("DL_AskDeathScene")
util.AddNetworkString("DL_SendDeathScene")

Damagelog.Records = {}
Damagelog.Death_Scenes = {}
Damagelog.SceneID = 0

hook.Add("TTTBeginRound", "TTTBeginRound_SpecDMRecord", function()
	table.Empty(Damagelog.Records)
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