
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
	ply:SetNWInt("Autoslays_left", sql.Query("SELECT slays FROM damagelog_autoslay WHERE steamid = '"..steamid.."' LIMIT 1;") or 0)
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

local function NetworkSlays(steamid, number)
	for k,v in pairs(player.GetAll()) do
		if v:SteamID() == steamid then
			v:SetNWInt("Autoslays_left", number)
			return
		end
	end
end

function Damagelog:SetSlays(admin, steamid, slays, reason, target)
	if reason == "" then
		reason = "No reason specified"
	end
	if slays == 0 then
	    sql.Query("DELETE FROM damagelog_autoslay WHERE ply = '"..steamid.."';")
		local name = self:GetName(steamid)
		if target then
			ulx.fancyLogAdminDamagelogs(admin, "#A removed the autoslays of #T.", target)
		else
			ulx.fancyLogAdminDamagelogs(admin, "#A removed the autoslays of #s.", steamid)
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
				local list = self:CreateSlayList(new_steamids)
				local nick = self:GetName(steamid)
				if target then
					ulx.fancyLogAdminDamagelogs(admin, "#A changed the reason of #T's autoslay to : '#s'. He was already autoslain "..slays.." time(s) by #s.", target, reason, list)
				else
					ulx.fancyLogAdminDamagelogs(admin, "#A changed the reason of #s's autoslay to : '#s'. He was already autoslain "..slays.." time(s) by #s.", steamid, reason, list)
				end
			else
				local difference = slays - old_slays
				sql.Query(string.format("UPDATE damagelog_autoslay SET admins = %s, slays = %i, reason = %s, time = %s WHERE ply = '%s' LIMIT 1;", sql.SQLStr(new_admins), slays, sql.SQLStr(reason), tostring(os.time()), steamid))
				local list = self:CreateSlayList(new_steamids)
				local nick = self:GetName(steamid)
				if target then
					ulx.fancyLogAdminDamagelogs(admin, "#A "..(difference > 0 and "added " or "removed ")..math.abs(difference).." slays to #T for the reason : '#s'. He was previously autoslain "..old_slays.." time(s) by #s.", target, reason, list)
				else
					ulx.fancyLogAdminDamagelogs(admin, "#A "..(difference > 0 and "added " or "removed ")..math.abs(difference).." slays to #s for the reason : '#s'. He was previously autoslain "..old_slays.." time(s) by #s.", steamid, reason, list)
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
				ulx.fancyLogAdminDamagelogs(admin, "#A added "..slays.." autoslays to #T with the reason : '#s'", target, reason)
			else
				ulx.fancyLogAdminDamagelogs(admin, "#A added "..slays.." autoslays to #s with the reason : '#s'", steamid, reason)
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
				else
					sql.Query("UPDATE damagelog_autoslay SET slays = slays - 1 WHERE ply = '"..v:SteamID().."';")
					NetworkSlays(steamid, slays - 1)
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
					ply:SetCleanRound(false)
					ply:SetNWBool("body_found", true)
					CORPSE.SetFound(v.server_ragdoll, true)
					v.server_ragdoll:Remove()
				end
			end
		end
	end	
end)

-- as much as I hate doing this
function ulx.fancyLogAdminDamagelogs( calling_ply, format, ... )
	local use_self_suffix = false
	local hide_echo = false
	local players = {}
	if logEcho:GetInt() ~= 0 then
		players = player.GetAll()
	end
	local arg_pos = 1
	local args = { ... }
	if type( format ) == "boolean" then
		hide_echo = format
		format = args[ 1 ]
	 	arg_pos = arg_pos + 1
	end

	if type( format ) == "table" then
		players = format
		format = args[ 1 ]
		arg_pos = arg_pos + 1
	end

	if hide_echo then
		for i=#players, 1, -1 do
			if not ULib.ucl.query( players[ i ], hiddenechoAccess ) and players[ i ] ~= calling_ply then
				table.remove( players, i )
			end
		end
	end
	table.insert( players, "CONSOLE" ) -- Dummy player used for logging and printing to dedicated console window

	local playerStrs = {}
	for i=1, #players do
		playerStrs[ i ] = {}
	end

	if hide_echo then
		insertToAll( playerStrs, default_color )
		insertToAll( playerStrs, "(SILENT) " )
	end

	local no_targets = false
	format:gsub( "([^#]*)#([%.%d]*[%a])([^#]*)", function( prefix, tag, postfix )
		if prefix and prefix ~= "" then
			insertToAll( playerStrs, default_color )
			insertToAll( playerStrs, prefix )
		end

		local specifier = tag:sub( -1, -1 )
		local arg = args[ arg_pos ]
		arg_pos = arg_pos + 1
		local color, str
		if specifier == "T" or specifier == "P" or (specifier == "A" and calling_ply) then
			if specifier == "A" then
				arg_pos = arg_pos - 1 -- This doesn't have an arg since it's at the start
				arg = { calling_ply }
			elseif type( arg ) ~= "table" then
				arg = { arg }
			end

			if #arg == 0 then no_targets = true end -- NO PLAYERS, NO LOG!!

			for i=1, #players do
				table.Add( playerStrs[ i ], makePlayerList( calling_ply, arg, players[ i ], use_self_suffix, specifier == "A" ) )
			end
			use_self_suffix = true
		else
			insertToAll( playerStrs, misc_color )
			insertToAll( playerStrs, string.format( "%" .. tag, arg ) )
		end

		if postfix and postfix ~= "" then
			insertToAll( playerStrs, default_color )
			insertToAll( playerStrs, postfix )
		end
	end )

	if no_targets then -- We don't want to log if there's nothing being targeted
		return
	end

	for i=1, #players do
		if not logEchoColors:GetBool() or players[ i ] == "CONSOLE" then -- They don't want coloring :)
			for j=#playerStrs[ i ], 1, -1 do
				if type( playerStrs[ i ][ j ] ) == "table" then
					table.remove( playerStrs[ i ], j )
				end
			end
		end

		if players[ i ] ~= "CONSOLE" and not players[i]:IsActive() then
			ULib.tsayColor( players[ i ], true, unpack( playerStrs[ i ] ) )
		else
			local msg = table.concat( playerStrs[ i ] )
			if game.IsDedicated() then
				Msg( msg .. "\n" )
			end

			if logFile:GetBool() then
				ulx.logString( msg, true )
			end
		end
	end
end
