
util.AddNetworkString("DL_SlayMessage")
util.AddNetworkString("DL_AutoSlay")
util.AddNetworkString("DL_AutoslaysLeft")
util.AddNetworkString("DL_PlayerLeft")

if not sql.TableExists("damagelog_autoslay") then
	sql.Query([[CREATE TABLE damagelog_autoslay (
		ply varchar(255) NOT NULL,
		admins tinytext NOT NULL,
		slays SMALLINT UNSIGNED NOT NULL,
		reason tinytext NOT NULL,
		time BIGINT UNSIGNED NOT NULL)
	]])
end
if not sql.TableExists("damagelog_names") then
	sql.Query([[CREATE TABLE damagelog_names (
		steamid varchar(255),
		name varchar(255))
	]])
end

hook.Add("PlayerAuthed", "DamagelogNames", function(ply, steamid, uniqueid)
	for k,v in pairs(player.GetAll()) do
		if v == ply then continue end
		net.Start("DL_AutoslaysLeft")
		net.WriteEntity(v)
		net.WriteUInt(v.AutoslaysLeft or 0, 32)
		net.Broadcast()
	end
	local name = ply:Nick()
	local query = sql.QueryValue("SELECT name FROM damagelog_names WHERE steamid = '"..steamid.."' LIMIT 1;")
	if not query then
		sql.Query("INSERT INTO damagelog_names (`steamid`, `name`) VALUES('"..steamid.."', "..sql.SQLStr(name)..");")
	elseif query != name then
		sql.Query("UPDATE damagelog_names SET name = "..sql.SQLStr(name).." WHERE steamid = '"..steamid.."' LIMIT 1;")
	end
	local c = sql.Query("SELECT slays FROM damagelog_autoslay WHERE steamid = '"..steamid.."' LIMIT 1;")
	if not tonumber(c) then c = 0 end
	ply.AutoslaysLeft = c
	net.Start("DL_AutoslaysLeft")
	net.WriteEntity(ply)
	net.WriteUInt(c, 32)
	net.Broadcast()
end)

function Damagelog:GetName(steamid)
	for k,v in pairs(player.GetAll()) do
		if v:SteamID() == steamid then
			return v:Nick()
		end
	end
	local query = sql.QueryValue("SELECT name FROM damagelog_names WHERE steamid = '"..steamid.."' LIMIT 1;")
	return query or "<Error>"
end

function Damagelog.SlayMessage(ply, message)
	net.Start("DL_SlayMessage")
	net.WriteString(message)
	net.Send(ply)
end

function Damagelog:CreateSlayList(tbl)
	if #tbl == 1 then
		return self:GetName(tbl[1])
	else
		local result = ""
		for i=1, #tbl do
			if i == #tbl then 
				result = result.." and "..self:GetName(tbl[i]) 
			elseif i == 1 then 
				result = self:GetName(tbl[i]) 
			else 
				result = result..", "..self:GetName(tbl[i])
			end
		end
		return result
	end
end

-- ty evolve
function Damagelog:FormatTime(t)
	if t < 0 then
		return "Forever"
	elseif t < 60 then
		if t == 1 then return "one second" else return t.." seconds" end
	elseif t < 3600 then
		if math.Round(t/60) == 1 then return "one minute" else return math.Round(t/60).." minutes" end
	elseif t < 24*3600 then
		if math.Round(t/3600) == 1 then return "one hour" else return math.Round(t/3600).." hours" end
	elseif t < 24*3600* 7 then
		if math.Round(t/(24*3600)) == 1 then return "one day" else return math.Round(t/(24*3600)).." days" end
	elseif t < 24*3600*30 then
		if math.Round(t/(24*3600*7)) == 1 then return "one week" else return math.Round(t/(24*3600*7)).." weeks" end
	else
		if math.Round(t/(24*3600*30)) == 1 then return "one month" else return math.Round(t/(24*3600*30)).." months" end
	end
end

local function NetworkSlays(steamid, number)
	for k,v in pairs(player.GetAll()) do
		if v:SteamID() == steamid then
			v.AutoslaysLeft = number
			net.Start("DL_AutoslaysLeft")
			net.WriteEntity(v)
			net.WriteUInt(number, 32)
			net.Broadcast()
			return
		end
	end
end

function Damagelog:SetSlays(admin, steamid, slays, reason, target)
	if reason == "" then
		reason = Damagelog.Autoslay_DefaultReason
	end
	if slays == 0 then
	    sql.Query("DELETE FROM damagelog_autoslay WHERE ply = '"..steamid.."';")
		local name = self:GetName(steamid)
		if target then
			ulx.fancyLogAdmin(admin, "#A removed the autoslays of #T.", target)
		else
			ulx.fancyLogAdmin(admin, "#A removed the autoslays of #s.", steamid)
		end
		NetworkSlays(steamid, 0)
	else
	    local data = sql.QueryRow("SELECT * FROM damagelog_autoslay WHERE ply = '"..steamid.."' LIMIT 1;")
		if data then
			local adminid
			if IsValid(admin) and type(admin) == "Player" then
				adminid = admin:SteamID()
			else
				adminid = "Console"
			end
			local old_slays = tonumber(data.slays)
			local old_steamids = util.JSONToTable(data.admins) or {}
		    local new_steamids = table.Copy(old_steamids)
	        if not table.HasValue(new_steamids, adminid) then
			    table.insert(new_steamids, adminid)
			end
		    if old_slays == slays then
				sql.Query("UPDATE damagelog_autoslay SET admins = "..sql.SQLStr(util.TableToJSON(new_steamids))..", reason = "..sql.SQLStr(reason)..", time = "..os.time().." WHERE ply = '"..steamid.."' LIMIT 1;")
				local list = self:CreateSlayList(old_steamids)
				local nick = self:GetName(steamid)
				if target then
					ulx.fancyLogAdmin(admin, "#A changed the reason of #T's autoslay to : '#s'. He was already autoslain "..slays.." time(s) by #s.", target, reason, list)
				else
					ulx.fancyLogAdmin(admin, "#A changed the reason of #s's autoslay to : '#s'. He was already autoslain "..slays.." time(s) by #s.", steamid, reason, list)
				end
			else
				local difference = slays - old_slays
				sql.Query(string.format("UPDATE damagelog_autoslay SET admins = %s, slays = %i, reason = %s, time = %s WHERE ply = '%s' LIMIT 1;", sql.SQLStr(new_admins), slays, sql.SQLStr(reason), tostring(os.time()), steamid))
				local list = self:CreateSlayList(old_steamids)
				local nick = self:GetName(steamid)
				if target then
					ulx.fancyLogAdmin(admin, "#A "..(difference > 0 and "added " or "removed ")..math.abs(difference).." slays to #T for the reason : '#s'. He was previously autoslain "..old_slays.." time(s) by #s.", target, reason, list)
				else
					ulx.fancyLogAdmin(admin, "#A "..(difference > 0 and "added " or "removed ")..math.abs(difference).." slays to #s for the reason : '#s'. He was previously autoslain "..old_slays.." time(s) by #s.", steamid, reason, list)
				end
				NetworkSlays(steamid, slays)
			end
		else
			local admins
			if IsValid(admin) and type(admin) == "Player" then
			    admins = util.TableToJSON( { admin:SteamID() } )
			else
			    admins = util.TableToJSON( { "Console" } )
			end
			sql.Query(string.format("INSERT INTO damagelog_autoslay (`admins`, `ply`, `slays`, `reason`, `time`) VALUES (%s, '%s', %i, %s, %s)", sql.SQLStr(admins), steamid, slays, sql.SQLStr(reason), tostring(os.time())))
			if target then
				ulx.fancyLogAdmin(admin, "#A added "..slays.." autoslays to #T with the reason : '#s'", target, reason)
			else
				ulx.fancyLogAdmin(admin, "#A added "..slays.." autoslays to #s with the reason : '#s'", steamid, reason)
			end
			NetworkSlays(steamid, slays)
		end
	end
end

hook.Add("TTTBeginRound", "Damagelog_AutoSlay", function()
	for k,v in pairs(player.GetAll()) do
		if v:IsActive() then
			timer.Simple(1, function()
				v:SetNWBool("PlayedSRound", true)
			end)
			local data = sql.QueryRow("SELECT * FROM damagelog_autoslay WHERE ply = '"..v:SteamID().."' LIMIT 1;")
			if data then
				v:Kill()
				local admins = util.JSONToTable(data.admins) or {}
				local slays = data.slays
				local reason = data.reason
				local _time = data.time
				slays = slays - 1
				if slays <= 0 then
					sql.Query("DELETE FROM damagelog_autoslay WHERE ply = '"..v:SteamID().."';")
					NetworkSlays(steamid, 0)
					v.AutoslaysLeft = 0
				else
					sql.Query("UPDATE damagelog_autoslay SET slays = slays - 1 WHERE ply = '"..v:SteamID().."';")
					NetworkSlays(steamid, slays - 1)
					if tonumber(v.AutoslaysLeft) then
						v.AutoslaysLeft = v.AutoslaysLeft - 1
					end
				end
				local list = Damagelog:CreateSlayList(admins)
				net.Start("DL_AutoSlay")
				net.WriteEntity(v)
				net.WriteString(list)
				net.WriteString(reason)
				net.WriteString(Damagelog:FormatTime(tonumber(os.time()) - tonumber(_time)))
				net.Broadcast()
				if IsValid(v.server_ragdoll) then
					local ply = player.GetByUniqueID(v.server_ragdoll.uqid)
					if not IsValid(ply) then return end
					ply:SetCleanRound(false)
					ply:SetNWBool("body_found", true)
					CORPSE.SetFound(v.server_ragdoll, true)
					v.server_ragdoll:Remove()
				end
			end
		end
	end	
end)

hook.Add("PlayerDisconnected", "Autoslay_Message", function(ply)
	if tonumber(ply.AutoslaysLeft) and ply.AutoslaysLeft > 0 then
		net.Start("DL_PlayerLeft")
		net.WriteString(ply:Nick())
		net.WriteString(ply:SteamID())
		net.WriteUInt(ply.AutoslaysLeft, 32)
		net.Broadcast()
	end
end)

if Damagelog.Autoslay_ForceRole then

	hook.Add("Initialize", "Autoslay_ForceRole", function()

		local function GetTraitorCount(ply_count)
			local traitor_count = math.floor(ply_count * GetConVar("ttt_traitor_pct"):GetFloat())
			traitor_count = math.Clamp(traitor_count, 1, GetConVar("ttt_traitor_max"):GetInt())
			return traitor_count
		end

		local function GetDetectiveCount(ply_count)
			if ply_count < GetConVar("ttt_detective_min_players"):GetInt() then return 0 end
			local det_count = math.floor(ply_count * GetConVar("ttt_detective_pct"):GetFloat())
			det_count = math.Clamp(det_count, 1, GetConVar("ttt_detective_max"):GetInt())
			return det_count
		end
	
		function SelectRoles()
			local choices = {}
			local prev_roles = {
				[ROLE_INNOCENT] = {},
				[ROLE_TRAITOR] = {},
				[ROLE_DETECTIVE] = {}
			};
			if not GAMEMODE.LastRole then GAMEMODE.LastRole = {} end
			for k,v in pairs(player.GetAll()) do
				if IsValid(v) and (not v:IsSpec()) and not (v.AutoslaysLeft and tonumber(v.AutoslaysLeft) > 0) then
					local r = GAMEMODE.LastRole[v:UniqueID()] or v:GetRole() or ROLE_INNOCENT
					table.insert(prev_roles[r], v)
					table.insert(choices, v)
				end
				v:SetRole(ROLE_INNOCENT)
			end
			local choice_count = #choices
			local traitor_count = GetTraitorCount(choice_count)
			local det_count = GetDetectiveCount(choice_count)
			if choice_count == 0 then return end
			local ts = 0
			while ts < traitor_count do
				local pick = math.random(1, #choices)
				local pply = choices[pick]
				if IsValid(pply) and ((not table.HasValue(prev_roles[ROLE_TRAITOR], pply)) or (math.random(1, 3) == 2)) then
					pply:SetRole(ROLE_TRAITOR)
					table.remove(choices, pick)
					ts = ts + 1
				end
			end
			local ds = 0
			local min_karma = GetConVarNumber("ttt_detective_karma_min") or 0
			while (ds < det_count) and (#choices >= 1) do
				if #choices <= (det_count - ds) then
					for k, pply in pairs(choices) do
						if IsValid(pply) then
							pply:SetRole(ROLE_DETECTIVE)
						end
					end
					break
				end
				local pick = math.random(1, #choices)
				local pply = choices[pick]
				if (IsValid(pply) and ((pply:GetBaseKarma() > min_karma and table.HasValue(prev_roles[ROLE_INNOCENT], pply)) or math.random(1,3) == 2)) then
					if not pply:GetAvoidDetective() then
						pply:SetRole(ROLE_DETECTIVE)
						ds = ds + 1
					end
					table.remove(choices, pick)
				end
			end
			GAMEMODE.LastRole = {}
			for _, ply in pairs(player.GetAll()) do
				ply:SetDefaultCredits()
				GAMEMODE.LastRole[ply:UniqueID()] = ply:GetRole()
			end
		end
	
	end)
	
end
