
util.AddNetworkString("DL_SlayMessage")
util.AddNetworkString("DL_AutoSlay")

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
	local name = ply:Nick()
	local query = sql.QueryValue("SELECT name FROM damagelog_names WHERE steamid = '"..steamid.."' LIMIT 1;")
	if not query then
		sql.Query("INSERT INTO damagelog_names (`steamid`, `name`) VALUES('"..steamid.."', "..sql.SQLStr(name)..");")
	elseif query != name then
		sql.Query("UPDATE damagelog_names SET name = "..sql.SQLStr(name).." WHERE steamid = '"..steamid.."' LIMIT 1;")
	end
	ply:SetNWInt("Autoslays_left", sql.Query("SELECT sum(slays) FROM damagelog_autoslay WHERE steamid = '"..steamid.."';") or 0)
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
		if math.ceil(t/60) == 1 then return "one minute" else return math.ceil(t/60).." minutes" end
	elseif t < 24*3600 then
		if math.ceil(t/3600) == 1 then return "one hour" else return math.ceil(t/3600).." hours" end
	elseif t < 24*3600* 7 then
		if math.ceil(t/(24*3600)) == 1 then return "one day" else return math.ceil(t/(24*3600)).." days" end
	elseif t < 24*3600*30 then
		if math.ceil(t/(24*3600*7)) == 1 then return "one week" else return math.ceil(t/(24*3600*7)).." weeks" end
	else
		if math.ceil(t/(24*3600*30)) == 1 then return "one month" else return math.ceil(t/(24*3600*30)).." months" end
	end
end

local function NetworkSlays(steamid)
	NetworkSlays(steamid, sql.Query("SELECT sum(slays) FROM damagelog_autoslay WHERE steamid = '"..steamid.."';") or 0)
end

local function NetworkSlays(steamid, number)
	for k,v in pairs(player.GetAll()) do
		if v:SteamID() == steamid then
			v:SetNWInt("Autoslays_left", number)
			return
		end
	end
end

function Damagelog:AddSlays(admin, steamid, slays, reason, target)
	if reason == "" then
		reason = "No reason specified"
	end
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
		ulx.fancyLogAdmin(admin, "#A added "..slays.." autoslays to #T with the reason : '#s'", steamid, reason)
	end
	NetworkSlays(steamid)
end

function Damagelog:RemoveSlays(admin, steamid, slays, target)
	local slays_to_remove = slays
	local slays_removed = 0
	while slays_to_remove > 0 do
		local data = sql.QueryRow("SELECT *,rowid FROM damagelog_autoslay WHERE ply = '"..steamid.."' ORDER BY time DESC LIMIT 1;")
		if data then
			local slays_found = tonumber(data.slays)
			local rowid = data.rowid
			if slays_found > slays_to_remove then -- found more, than i need to remove
				slays_removed = slays_removed + slays_to_remove
				slays_found = slays_found - slays_to_remove
				slays_to_remove = 0
				sql.Query("UPDATE damagelog_autoslay SET slays = '"..slays_found.."' WHERE ply = '"..steamid.."' AND rowid = '"..rowid.."';")
			else -- found equal or less than i need to remove
				slays_to_remove = slays_to_remove - slays_found
				slays_removed = slays_removed + slays_found
				sql.Query("DELETE FROM damagelog_autoslay WHERE ply = '"..steamid.."' AND rowid = '"..rowid.."';")
			end
		else -- no slays found
			slays_to_remove = 0
		end
	end
	if target then
		ulx.fancyLogAdmin(admin, "#A removed "..slays_removed.." autoslays from #T.", target)
	else
		ulx.fancyLogAdmin(admin, "#A removed "..slays_removed.." autoslays from #T.", steamid)
	end
	NetworkSlays(steamid)
end

hook.Add("TTTBeginRound", "Damagelog_AutoSlay", function()
	for k,v in pairs(player.GetAll()) do
		if v:IsActive() then
			timer.Simple(1, function()
				v:SetNWBool("PlayedSRound", true)
			end)
			local data = sql.QueryRow("SELECT *,rowid FROM damagelog_autoslay WHERE ply = '"..v:SteamID().."' ORDER BY time ASC LIMIT 1;")
			if data then
				v:Kill()
				local admins = util.JSONToTable(data.admins) or {}
				local slays = data.slays
				local reason = data.reason
				local _time = data.time
				local rowid = tonumber(data.rowid)
				slays = slays - 1
				if slays <= 0 then
					sql.Query("DELETE FROM damagelog_autoslay WHERE ply = '"..v:SteamID().."' AND rowid = '"..rowid.."';")
				else
					sql.Query("UPDATE damagelog_autoslay SET slays = slays - 1 WHERE ply = '"..v:SteamID().."' AND rowid = '"..rowid.."';")
				end
				NetworkSlays(steamid)
				local list = Damagelog:CreateSlayList(admins)
				net.Start("DL_AutoSlay")
				net.WriteEntity(v)
				net.WriteString(list)
				net.WriteString(reason)
				net.WriteString(Damagelog:FormatTime(tonumber(os.time()) - tonumber(_time)))
				net.Broadcast()
				if IsValid(v.server_ragdoll) then
					local ply = player.GetByUniqueID(v.server_ragdoll.uqid)
					ply:SetCleanRound(false)
					ply:SetNWBool("body_found", true)
					CORPSE.SetFound(v.server_ragdoll, true)
					v.server_ragdoll:Remove()
				end
			end
		end
	end	
end)
