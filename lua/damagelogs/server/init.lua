AddCSLuaFile("damagelogs/config/config.lua")
AddCSLuaFile("damagelogs/shared/lang.lua")
AddCSLuaFile("damagelogs/shared/notify.lua")
AddCSLuaFile("damagelogs/client/info_label.lua")
AddCSLuaFile("damagelogs/shared/sync.lua")
AddCSLuaFile("damagelogs/shared/events.lua")
AddCSLuaFile("damagelogs/client/weapon_names.lua")
AddCSLuaFile("damagelogs/shared/privileges.lua")
AddCSLuaFile("damagelogs/client/tabs/damagetab.lua")
AddCSLuaFile("damagelogs/client/tabs/rdm_manager.lua")
AddCSLuaFile("damagelogs/client/tabs/shoots.lua")
AddCSLuaFile("damagelogs/client/tabs/old_logs.lua")
AddCSLuaFile("damagelogs/client/colors.lua")
AddCSLuaFile("damagelogs/client/filters.lua")
AddCSLuaFile("damagelogs/client/drawcircle.lua")
AddCSLuaFile("damagelogs/client/listview.lua")
AddCSLuaFile("damagelogs/client/recording.lua")
AddCSLuaFile("damagelogs/client/settings.lua")
AddCSLuaFile("damagelogs/shared/autoslay.lua")
include("damagelogs/config/config.lua")
include("damagelogs/config/mysqloo.lua")
include("damagelogs/shared/lang.lua")
include("damagelogs/server/oldlogs.lua")
include("damagelogs/shared/notify.lua")
include("damagelogs/shared/sync.lua")
include("damagelogs/shared/events.lua")
include("damagelogs/shared/privileges.lua")
include("damagelogs/server/damageinfos.lua")
include("damagelogs/server/recording.lua")
include("damagelogs/server/autoslay.lua")
include("damagelogs/shared/autoslay.lua")
include("damagelogs/server/discord.lua")

-- Building error reporting
-- Damagelog:Error(debug.getinfo(1).source, debug.getinfo(1).currentline, "connection error")
function Damagelog:Error(file, line, strg)
	print("Damagelogs: ERROR - " .. file .. " (" .. line .. ") - " .. strg)
end

if Damagelog.RDM_Manager_Enabled then
	AddCSLuaFile("damagelogs/client/rdm_manager.lua")
	AddCSLuaFile("damagelogs/client/chat.lua")
	AddCSLuaFile("damagelogs/shared/rdm_manager.lua")
	AddCSLuaFile("damagelogs/shared/chat.lua")
	if Damagelog.UseWorkshop then
		resource.AddWorkshop("1129792694")
	else
		resource.AddFile("sound/damagelogs/vote_failure.wav")
		resource.AddFile("sound/damagelogs/vote_yes.wav")
		resource.AddFile("sound/damagelogs/vote_no.wav")
	end
	include("damagelogs/server/rdm_manager.lua")
	include("damagelogs/server/chat.lua")
	include("damagelogs/shared/rdm_manager.lua")
	include("damagelogs/shared/chat.lua")
end
-- Including Net Messages
util.AddNetworkString("DL_AskDamagelog")
util.AddNetworkString("DL_SendDamagelog")
util.AddNetworkString("DL_RefreshDamagelog")
util.AddNetworkString("DL_InformSuperAdmins")
util.AddNetworkString("DL_Ded")
util.AddNetworkString("DL_SendLang")
Damagelog.DamageTable = Damagelog.DamageTable or {}
Damagelog.OldTables = Damagelog.OldTables or {}
Damagelog.ShootTables = Damagelog.ShootTables or {}
Damagelog.Roles = Damagelog.Roles or {}
Damagelog.SceneRounds = Damagelog.SceneRounds or {}

net.Receive("DL_SendLang", function(_, ply)
	ply.DMGLogLang = net.ReadString()
end)

local Player = FindMetaTable("Player")

function Player:GetDamagelogID()
	return self.DamagelogID or -1
end

function Player:SetDamagelogID(id)
	self.DamagelogID = id
end

function Player:AddToDamagelogRoles(spawned)
	local id = table.insert(Damagelog.Roles[#Damagelog.Roles], {
		role = (spawned and 4) or (self:IsSpec() and 5) or self:GetRole(),
		steamid64 = self:SteamID64(),
		nick = self:Nick()
	})
	self:SetDamagelogID(id)
end

function Damagelog:TTTBeginRound()

	self.Time = 0

	if not timer.Exists("Damagelog_Timer") then
		timer.Create("Damagelog_Timer", 1, 0, function()
			self.Time = self.Time + 1
		end)
	end

	if IsValid(self:GetSyncEnt()) then
		local rounds = self:GetSyncEnt():GetPlayedRounds()
		self:GetSyncEnt():SetPlayedRounds(rounds + 1)

		if self.add_old then
			self.OldTables[rounds] = table.Copy(self.DamageTable)
		else
			self.add_old = true
		end

		self.ShootTables[rounds + 1] = {}
		self.Roles[rounds + 1] = {}

		for k,v in ipairs(player.GetAll()) do
			v:AddToDamagelogRoles()
		end

		self.CurrentRound = rounds + 1
	end

	table.Empty(self.DamageTable)

end

hook.Add("TTTBeginRound", "TTTBeginRound_Damagelog", function()
	Damagelog:TTTBeginRound()
end)

hook.Add("PlayerInitialSpawn", "PlayerInitialSpawn_Damagelog", function(ply)
	if GetRoundState() == ROUND_ACTIVE then
		local steamid64 = ply:SteamID64()
		local found = false
		for k,v in pairs(Damagelog.Roles[#Damagelog.Roles]) do
			if v.steamid64 == steamid64 then
				found = true
				ply:SetDamagelogID(k)
				break
			end
		end
		if not found then
			ply:AddToDamagelogRoles(true)
		end
	end
end)

-- rip from TTT
-- this one will return a string
function Damagelog:WeaponFromDmg(dmg)
	local inf = dmg:GetInflictor()
	local wep = nil

	if IsValid(inf) then
		if inf:IsWeapon() or inf.Projectile then
			wep = inf
		elseif dmg:IsDamageType(DMG_BLAST) then
			wep = "DMG_BLAST"
		elseif dmg:IsDamageType(DMG_DIRECT) or dmg:IsDamageType(DMG_BURN) then
			wep = "DMG_BURN"
		elseif dmg:IsDamageType(DMG_CRUSH) then
			wep = "DMG_CRUSH"
		elseif dmg:IsDamageType(DMG_SLASH) then
			wep = "DMG_SLASH"
		elseif dmg:IsDamageType(DMG_CLUB) then
			wep = "DMG_CLUB"
		elseif dmg:IsDamageType(DMG_SHOCK) then
			wep = "DMG_SHOCK"
		elseif dmg:IsDamageType(DMG_ENERGYBEAM) then
			wep = "DMG_ENERGYBEAM"
		elseif dmg:IsDamageType(DMG_SONIC) then
			wep = "DMG_SONIC"
		elseif dmg:IsDamageType(DMG_PHYSGUN) then
			wep = "DMG_PHYSGUN"
		elseif inf:IsPlayer() then
			wep = inf:GetActiveWeapon()

			if not IsValid(wep) then
				wep = IsValid(inf.dying_wep) and inf.dying_wep
			end
		end
	end

	if type(wep) ~= "string" then
		return IsValid(wep) and wep:GetClass()
	else
		return wep
	end
end

function Damagelog:SendDamagelog(ply, round)

	if self.MySQL_Error and not ply.DL_MySQL_Error then
		Damagelog:Error(debug.getinfo(1).source, debug.getinfo(1).currentline, "mysql connection error")
		ply.DL_MySQL_Error = true
	end

	local damage_send = {}
	local roles = self.Roles[round]
	local current = false

	if round == -1 then

		if not self.last_round_map then return end

		if not Damagelog.PreviousMap then

			if Damagelog.Use_MySQL then

				local query = self.database:query("SELECT damagelog FROM damagelog_oldlogs_v3 WHERE date = " .. self.last_round_map)

				query.onSuccess = function(q)
					local data = q:getData()
					if data and data[1] then
						local encoded = data[1]["damagelog"]
						local decoded = util.JSONToTable(encoded)
						if not decoded then
							decoded = {
								Roles = {},
								ShootTables = {},
								DamageTable = {}
							}
						end
						self:TransferLogs(decoded.DamageTable, ply, round, decoded.Roles)
						Damagelog.PreviousMap = decoded
					end
				end

				query:start()

			else

				local query = sql.QueryValue("SELECT damagelog FROM damagelog_oldlogs_v3 WHERE date = " .. self.last_round_map)
				if not query then return end
				local decoded = util.JSONToTable(query)
				if not decoded then
					decoded = {
						Roles = {},
						ShootTables = {},
						DamageTable = {}
					}
				end
				self:TransferLogs(decoded.DamageTable, ply, round, decoded.Roles)
				Damagelog.PreviousMap = decoded

			end

		else

			self:TransferLogs(Damagelog.PreviousMap.DamageTable, ply, round, Damagelog.PreviousMap.Roles)

		end

	else

		if round == self:GetSyncEnt():GetPlayedRounds() then
			if not ply:CanUseDamagelog() then return end
			damage_send = self.DamageTable
			current = true
		else
			damage_send = self.OldTables[round]
		end

		self:TransferLogs(damage_send, ply, round, roles, current)

	end

end

function Damagelog:TransferLogs(damage_send, ply, round, roles, current)

	local count = #damage_send

	net.Start("DL_SendDamagelog")
	net.WriteTable(roles or {})
	net.WriteUInt(count, 32)
	for k,v in ipairs(damage_send) do
		net.WriteTable(v)
	end
	net.Send(ply)

	if current and ply:IsActive() then
		net.Start("DL_InformSuperAdmins")
		net.WriteString(ply:Nick())
		if self.AbuseMessageMode == 1 then
			net.Send(player.GetHumans())
		else
			local superadmins = {}
			for k,v in ipairs(player.GetHumans()) do
				if v:IsSuperAdmin() then
					table.insert(superadmins, v)
				end
			end
			net.Send(superadmins)
		end
	end
end

net.Receive("DL_AskDamagelog", function(_, ply)
	local roundnumber = net.ReadInt(32)
	if (roundnumber and roundnumber > -2) then --Because -1 is the last round from previous map
		Damagelog:SendDamagelog(ply, roundnumber)
	else
		Damagelog:Error(debug.getinfo(1).source, debug.getinfo(1).currentline, "Roundnumber invalid or negative")
	end
end)

hook.Add("PlayerDeath", "Damagelog_PlayerDeathLastLogs", function(ply)

	if GetRoundState() != ROUND_ACTIVE then return end

	local found_dmg = {}
	local count = #Damagelog.DamageTable
	for i = count, 1, -1 do
		local line = Damagelog.DamageTable[i]
		if !Damagelog.Time or line.time < Damagelog.Time - 10 then break end
		table.insert(found_dmg, line)
	end

	ply.DeathDmgLog = {
		logs = table.Reverse(found_dmg),
		roles = Damagelog.Roles[#Damagelog.Roles]
	}

end)
