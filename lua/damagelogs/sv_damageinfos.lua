
util.AddNetworkString("DL_AskDamageInfos")
util.AddNetworkString("DL_SendDamageInfos")
util.AddNetworkString("DL_AskShootLogs")
util.AddNetworkString("DL_SendShootLogs")

function Damagelog:shootCallback(weapon)
	if not self.Time then return end
	local owner = (IsPlayer(weapon.Owner) and weapon.Owner or nil) or (IsPlayer(weapon:GetOwner()) and weapon:GetOwner() or nil) or (IsValid(weapon) and weapon or nil)
	if owner == nil then MsgN("No weapon or owner!") return end
	local nick = (IsValid(owner) and owner.Nick and owner:Nick() or "NoOwner")
	local class = (IsValid(weapon) and weapon:GetClass() or "NoClass")
	local info = {nick, class}
	if GetRoundState() == ROUND_ACTIVE then
		if !self.ShootTables[self.CurrentRound][self.Time] then
			self.ShootTables[self.CurrentRound][self.Time] =  {}
		end
		table.insert(self.ShootTables[self.CurrentRound][self.Time], info)
		local length = #Damagelog.Records
		if length > 0 and Damagelog.Records[length][nick] then
			local sound = weapon.Primary and weapon.Primary.Sound
			if sound then
				Damagelog.Records[length][nick].shot = sound
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
			Damagelog.Records[length][nick].trace = { trace.StartPos, trace.HitPos }
		end
	end
end
	 
function Damagelog:DamagelogInfos()
	for k,v in pairs(weapons.GetList()) do		
		if v.Base == "weapon_tttbase" then
			if not v.PrimaryAttack then
				v.PrimaryAttack = function(wep)
					wep.BaseClass.PrimaryAttack(wep)
					if wep.BaseClass.CanPrimaryAttack(wep) and IsValid(wep.Owner) then
						self:shootCallback(wep)
					end
				end
			else
				local oldprimary = v.PrimaryAttack
				v.PrimaryAttack = function(wep)
					oldprimary(wep)
					Damagelog:shootCallback(wep)
				end
			end
		end
	end
end

hook.Add("Initialize", "Initialize_DamagelogInfos", function()	
	Damagelog:DamagelogInfos()
end)

function Damagelog:SendDamageInfos(ply, t, att, victim, round)
	local results = {}
	local found = false
	for k,v in pairs(self.ShootTables[round] or {}) do
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
	if found then
		net.Start("DL_SendDamageInfos")
		net.WriteUInt(0,1)
		net.WriteUInt(beg, 32)
		net.WriteUInt(t, 32)
		net.WriteTable(results)
		net.WriteString(victim)
		net.WriteString(att)
		net.Send(ply)
	else 
		net.Start("DL_SendDamageInfos")
		net.WriteUInt(1,1)
		net.WriteUInt(beg, 32)
		net.WriteUInt(t, 32)
		net.WriteString(victim)
		net.WriteString(att)
		net.Send(ply)
    end
end 

net.Receive("DL_AskDamageInfos", function(_, ply)
	local time = net.ReadUInt(32)
	local attacker = net.ReadString()
	local victim = net.ReadString()
	local round = net.ReadUInt(32)
	Damagelog:SendDamageInfos(ply, time, attacker, victim, round)
end)

local orderedPairs = Damagelog.orderedPairs
net.Receive("DL_AskShootLogs", function(_, ply)
	local round = net.ReadUInt(8)
	if not ply:CanUseDamagelog() and round == Damagelog:GetSyncEnt():GetPlayedRounds() then return end
	local data = Damagelog.ShootTables[round]
	if not data then return end
	data = table.Copy(data)
	local count = table.Count(data)
	local i = 0
	if count <= 0 then
		net.Start("DL_SendShootLogs")
		net.WriteUInt(0, 32)
		net.WriteTable({"empty"})
		net.WriteUInt(1, 1)
		net.Send(ply)
	else
		for k,v in orderedPairs(data) do
			i = i + 1
			net.Start("DL_SendShootLogs")
			net.WriteUInt(k, 32)
			net.WriteTable(v)
			net.WriteUInt(i == count and 1 or 0, 1)
			net.Send(ply)
		end
	end
end)
