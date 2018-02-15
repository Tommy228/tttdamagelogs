
util.AddNetworkString("DL_AskDamageInfos")
util.AddNetworkString("DL_SendDamageInfos")
util.AddNetworkString("DL_AskShootLogs")
util.AddNetworkString("DL_SendShootLogs")

function Damagelog:shootCallback(weapon)
	if not self.Time then return end
	local owner = weapon.Owner or weapon:GetOwner()
	if !IsValid(owner) then return end
	local id = owner:GetDamagelogID()
	if id == -1 then return end
	local class = (IsValid(weapon) and weapon:GetClass() or "NoClass")
	local info = {id, class}
	if GetRoundState() == ROUND_ACTIVE then
		if !self.ShootTables[self.CurrentRound][self.Time] then
			self.ShootTables[self.CurrentRound][self.Time] =  {}
		end
		table.insert(self.ShootTables[self.CurrentRound][self.Time], info)
		local length = #Damagelog.Records
		if length > 0 and Damagelog.Records[length][id] then
			local sound = weapon.Primary and weapon.Primary.Sound
			if sound then
				Damagelog.Records[length][id].shot = sound
			end
			local td
			if owner == weapon then
				td = {
					start = owner:GetPos(),
					entpos = owner:GetPos() + owner:GetAngles():Forward() * 10000,
					filter = {owner},
				}
			else
				td = util.GetPlayerTrace(owner)
			end
			local trace = util.TraceLine(td)
			Damagelog.Records[length][id].trace = { trace.StartPos, trace.HitPos }
		end
	end
end

hook.Add("EntityFireBullets", "BulletsCallback_DamagelogInfos", function(ent, data)
	if not IsValid(ent) or not ent:IsPlayer() then return end
	local wep = ent:GetActiveWeapon()
	if IsValid(wep) and wep.Base == "weapon_tttbase" then
		Damagelog:shootCallback(wep)
	end
end)

function Damagelog:SendDamageInfos(ply, t, att, victim, round)
	local results = {}
	local found = false
	local data
	if round == -1 then
		data = Damagelog.PreviousMap.ShootTable
	else
		data = Damagelog.ShootTables[round]
	end
	if not data then return end
	for k,v in pairs(data) do
	    if k >= t - 10 and k <= t then
		    for s,i in pairs(v) do
		        if i[1] == victim or i[1] == att then
		            if results[k] == nil then
					    table.insert(results, k, {})
					end
					table.insert(results[k], i)
			        found = true
				end
			end
		end
	end
	local beg = t - 10
	local victimNick = self:InfoFromID(self.Roles[round], victim).nick
	local attNick = self:InfoFromID(self.Roles[round], att).nick
	net.Start("DL_SendDamageInfos")
	net.WriteUInt(beg, 32)
	net.WriteUInt(t, 32)
	net.WriteString(victimNick)
	net.WriteString(attNick)
	net.WriteUInt(victim, 32)
	net.WriteUInt(att, 32)
	if found then
		net.WriteUInt(1, 1)
		net.WriteTable(results)
	else
		net.WriteUInt(0, 1)
	end
	net.Send(ply)
end

net.Receive("DL_AskDamageInfos", function(_, ply)
	local time = net.ReadUInt(32)
	local attacker = net.ReadUInt(32)
	local victim = net.ReadUInt(32)
	local round = net.ReadUInt(32)
	Damagelog:SendDamageInfos(ply, time, attacker, victim, round)
end)

net.Receive("DL_AskShootLogs", function(_, ply)
	local round = net.ReadInt(8)
	if not ply:CanUseDamagelog() and round == Damagelog:GetSyncEnt():GetPlayedRounds() then return end
	local data, roles
	if round == -1 then
		data = Damagelog.PreviousMap.ShootTable
		roles = Damagelog.PreviousMap.Roles
	else
		data = Damagelog.ShootTables[round]
		roles = Damagelog.Roles[round]
	end
	if not roles or not data then return end
	net.Start("DL_SendShootLogs")
	net.WriteTable(roles)
	net.WriteTable(data)
	net.Send(ply)
end)
