
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

hook.Add("Initialize", "Damagelogs_ULXEdit", function()

local logEcho                   = ulx.convar( "logEcho", "2", "Echo mode 0-Off 1-Anonymous 2-Full", ULib.ACCESS_SUPERADMIN )
local logEchoColors             = ulx.convar( "logEchoColors", "1", "Whether or not echoed commands in chat are colored", ULib.ACCESS_SUPERADMIN )
local logEchoColorDefault       = ulx.convar( "logEchoColorDefault", "151 211 255", "The default text color (RGB)", ULib.ACCESS_SUPERADMIN )
local logEchoColorConsole       = ulx.convar( "logEchoColorConsole", "0 0 0", "The color that Console gets when using actions", ULib.ACCESS_SUPERADMIN )
local logEchoColorSelf          = ulx.convar( "logEchoColorSelf", "75 0 130", "The color for yourself in echoes", ULib.ACCESS_SUPERADMIN )
local logEchoColorEveryone      = ulx.convar( "logEchoColorEveryone", "0 128 128", "The color to use when everyone is targeted in echoes", ULib.ACCESS_SUPERADMIN )
local logEchoColorPlayerAsGroup = ulx.convar( "logEchoColorPlayerAsGroup", "1", "Whether or not to use group colors for players.", ULib.ACCESS_SUPERADMIN )
local logEchoColorPlayer        = ulx.convar( "logEchoColorPlayer", "255 255 0", "The color to use for players when ulx logEchoColorPlayerAsGroup is set to 0.", ULib.ACCESS_SUPERADMIN )
local logEchoColorMisc          = ulx.convar( "logEchoColorMisc", "0 255 0", "The color for anything else in echoes", ULib.ACCESS_SUPERADMIN )
local logFile                   = ulx.convar( "logFile", "1", "Log to file (Can still echo if off). This is a global setting, nothing will be logged to file with this off.", ULib.ACCESS_SUPERADMIN )
local logEvents                 = ulx.convar( "logEvents", "1", "Log events (player connect, disconnect, death)", ULib.ACCESS_SUPERADMIN )
local logChat                   = ulx.convar( "logChat", "1", "Log player chat", ULib.ACCESS_SUPERADMIN )
local logSpawns                 = ulx.convar( "logSpawns", "1", "Log when players spawn objects (props, effects, etc)", ULib.ACCESS_SUPERADMIN )
local logSpawnsEcho             = ulx.convar( "logSpawnsEcho", "1", "Echo spawns to players in server. -1 = Off, 0 = Console only, 1 = Admins only, 2 = All players. (Echoes to console)", ULib.ACCESS_SUPERADMIN )
local logJoinLeaveEcho          = ulx.convar( "logJoinLeaveEcho", "1", "Echo players leaves and joins to admins in the server (useful for banning minges)", ULib.ACCESS_SUPERADMIN )
local logDir                    = ulx.convar( "logDir", "ulx_logs", "The log dir under garrysmod/data", ULib.ACCESS_SUPERADMIN )

local default_color
local console_color
local self_color
local misc_color
local everyone_color
local player_color

local function updateColors()
	local cvars = { logEchoColorDefault, logEchoColorConsole, logEchoColorSelf, logEchoColorEveryone, logEchoColorPlayer, logEchoColorMisc }
	for i=1, #cvars do
		local cvar = cvars[ i ]
		local pieces = ULib.explode( "%s+", cvar:GetString() )
		if not #pieces == 3 then Msg( "Warning: Tried to set ulx log color cvar with bad data\n" ) return end
		local color = Color( tonumber( pieces[ 1 ] ), tonumber( pieces[ 2 ] ), tonumber( pieces[ 3 ] ) )

		if cvar == logEchoColorDefault then default_color = color
		elseif cvar == logEchoColorConsole then console_color = color
		elseif cvar == logEchoColorSelf then self_color = color
		elseif cvar == logEchoColorEveryone then everyone_color = color
		elseif cvar == logEchoColorPlayer then player_color = color
		elseif cvar == logEchoColorMisc then misc_color = color
		end
	end
end
hook.Add( ulx.HOOK_ULXDONELOADING, "UpdateEchoColors", updateColors )

local function cvarChanged( sv_cvar, cl_cvar, ply, old_value, new_value )
	sv_cvar = sv_cvar:lower()
	if not sv_cvar:find( "^ulx_logechocolor" ) then return end
	if sv_cvar ~= "ulx_logechocolorplayerasgroup" then timer.Simple( 0.1, updateColors ) end
end
hook.Add( ULib.HOOK_REPCVARCHANGED, "ULXCheckLogColorCvar", cvarChanged )

local function plyColor( target_ply, showing_ply )
	if not target_ply:IsValid() then
		return console_color
	elseif showing_ply == target_ply then
		return self_color
	elseif logEchoColorPlayerAsGroup:GetBool() then
		return team.GetColor( target_ply:Team() )
	else
		return player_color
	end
end

local function makePlayerList( calling_ply, target_list, showing_ply, use_self_suffix, is_admin_part )
	local players = player.GetAll()
	-- Is the calling player acting anonymously in the eyes of the player this is being showed to?
	local anonymous = showing_ply ~= "CONSOLE" and not ULib.ucl.query( showing_ply, seeanonymousechoAccess ) and logEcho:GetInt() == 1

	if #players > 1 and #target_list == #players then
		return { everyone_color, "Everyone" }
	elseif is_admin_part then
		local target = target_list[ 1 ] -- Only one target here
		if anonymous and target ~= showing_ply then
			return { everyone_color, "(Someone)" }
		elseif not target:IsValid() then
			return { console_color, "(Console)" }
		end
	end

	local strs = {}

	-- Put self, then them to the front of the list.
	table.sort( target_list, function( ply_a, ply_b )
		if ply_a == showing_ply then return true end
		if ply_b == showing_ply then return false end
		if ply_a == calling_ply then return true end
		if ply_b == calling_ply then return false end
		return ply_a:Nick() < ply_b:Nick()
	end )

	for i=1, #target_list do
		local target = target_list[ i ]
		table.insert( strs, plyColor( target, showing_ply ) )
		if target == showing_ply then
			if not use_self_suffix or calling_ply ~= showing_ply then
				table.insert( strs, "You" )
			else
				table.insert( strs, "Yourself" )
			end
		elseif not use_self_suffix or calling_ply ~= target_list[ i ] or anonymous then
			table.insert( strs, target_list[ i ]:IsValid() and target_list[ i ]:Nick() or "(Console)" )
		else
			table.insert( strs, "Themself" )
		end
		table.insert( strs, default_color )
		table.insert( strs, "," )
	end

	-- Remove last comma and coloring
	table.remove( strs )
	table.remove( strs )

	return strs
end

local function insertToAll( t, data )
	for i=1, #t do
		table.insert( t[ i ], data )
	end
end


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
end)
