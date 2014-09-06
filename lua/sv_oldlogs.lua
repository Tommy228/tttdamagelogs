
util.AddNetworkString("DL_AskLogsList")
util.AddNetworkString("DL_AskOldLog")
util.AddNetworkString("DL_SendOldLog")
util.AddNetworkString("DL_SendLogsList")

Damagelog.available_logs = {}
Damagelog.previous_reports = {}

local limit = os.time() - Damagelog.LogDays*24*60*60

local function HandleLogsRow(data)
	local d = string.Explode(" ", os.date("%Y %m %d", data.date))
	local year = tonumber(d[1])
	if not Damagelog.available_logs[year] then
		Damagelog.available_logs[year] = {}
	end
	local month = tonumber(d[2])
	if not Damagelog.available_logs[year][month] then
		Damagelog.available_logs[year][month] = {}
	end		
	local day = tonumber(d[3])
	if not Damagelog.available_logs[year][month][day] then
		Damagelog.available_logs[year][month][day] = {}
	end	
	Damagelog.available_logs[year][month][day][data.date] = data.map	
end

local function HandlePreviousReports(data)
	data.id = tonumber(data.id)
	local report = data.report
	local decoded = util.JSONToTable(data.report)
	decoded.index = data.id
	decoded.round = -1
	table.insert(Damagelog.previous_reports, decoded)
	local respond = {
		message = decoded.message,
		victim = decoded.plyName,
		round = -1,
		time = decoded.time,
		report = data.id,
		index = data.id
	}
	local steamID = decoded.attackerSteam
	if not decoded.attackerMessage then
		if not Damagelog.rdmReporter.prevRespond[steamID] then
			Damagelog.rdmReporter.prevRespond[steamID] = {}
		end
		table.insert(Damagelog.rdmReporter.prevRespond[steamID], respond)
	end
end

local function GetLogsCount_SQLite()
	return sql.QueryValue("SELECT COUNT(id) FROM damagelog_oldlogs;")
end

if Damagelog.Use_MySQL then
	require("mysqloo")
	include("config/mysqloo.lua")
	Damagelog.MySQL_Error = nil
	file.Delete("damagelog/mysql_error.txt")
	local info = Damagelog.MySQL_Informations
	Damagelog.database = mysqloo.connect(info.ip, info.username, info.password, info.database, info.port)
	Damagelog.database.onConnected = function(self)
		Damagelog.MySQL_Connected = true
		local create_table1 = self:query([[CREATE TABLE IF NOT EXISTS damagelog_oldlogs (
			id INT UNSIGNED NOT NULL AUTO_INCREMENT,
			date INTEGER NOT NULL,
			map TINYTEXT NOT NULL,
			round TINYINT NOT NULL,
			damagelog BLOB NOT NULL,
			PRIMARY KEY (id));
		]])
		create_table1:start()
		local create_table2 = self:query([[CREATE TABLE IF NOT EXISTS damagelog_weapons (
			class varchar(255) NOT NULL,
			name varchar(255) NOT NULL,
			PRIMARY KEY (class));
		]])
		create_table2:start()
		local create_table3 = self:query([[CREATE TABLE IF NOT EXISTS damagelog_previousreports (
			id INT UNSIGNED NOT NULL AUTO_INCREMENT,
			_index TINYINT UNSIGNED NOT NULL,
			report TEXT NOT NULL,
			PRIMARY KEY (id));
		]])
		create_table3:start()
		local list = self:query("SELECT date, map, round FROM damagelog_oldlogs;")
		list.onData = function(query, data)
			HandleLogsRow(data)
		end
		list:start()
		local previous_reports = self:query("SELECT * FROM damagelog_previousreports ORDER BY id;")
		previous_reports.onData = function(query, data)
		end
		previous_reports.onSuccess = function()
			Damagelog:TruncateReports()
		end
		previous_reports:start()
		local delete_old = self:query("DELETE FROM damagelog_oldlogs WHERE date <= "..limit..";")
		delete_old:start()
		Damagelog:GetWepTable()
	end
	Damagelog.database.onConnectionFailed = function(self, err)
		file.Write("damagelog/mysql_error.txt", err)
		Damagelog.MySQL_Error = err
	end
else
	if not sql.TableExists("damagelog_oldlogs") then
		sql.Query([[CREATE TABLE IF NOT EXISTS damagelog_oldlogs (
			id INT UNSIGNED NOT NULL PRIMARY KEY,
			date INTEGER NOT NULL,
			map TINYTEXT NOT NULL,
			round TINYINT NOT NULL,
			damagelog TEXT);
		]])
	end
	if not sql.TableExists("damagelog_weapons") then
		sql.Query([[CREATE TABLE IF NOT EXISTS damagelog_weapons (
			class varchar(255) NOT NULL,
			name varchar(255) NOT NULL,
			PRIMARY KEY (class));
		]])
	end
	if not sql.TableExists("damagelog_previousreports") then
		sql.Query([[CREATE TABLE IF NOT EXISTS damagelog_previousreports (
			id INT UNSIGNED NOT NULL PRIMARY KEY,
			_index TINYINT UNSIGNED NOT NULL,
			report TEXT NOT NULL);
		]])
	end
	local old_logs_count = GetLogsCount_SQLite() 
	if tonumber(old_logs_count) then
		for i=1, old_logs_count do
			local row = sql.QueryRow("SELECT date, map, round FROM damagelog_oldlogs WHERE id = "..tostring(i).." AND damagelog IS NOT NULL;")
			if row then
				HandleLogsRow(row)
			end
		end
	end
	local previous_reports_count = sql.QueryValue("SELECT COUNT(id) FROM damagelog_previousreports;")
	if tonumber(previous_reports_count) then
		for i=1, previous_reports_count do
			local row = sql.QueryRow("SELECT * FROM damagelog_previousreports WHERE id = "..tostring(i).." ORDER BY id;")
			if row then
				HandlePreviousReports(row)
			end
		end
	end
	sql.Query("UPDATE damagelog_oldlogs SET damagelog = NULL WHERE date <= "..limit..";")
	Damagelog:GetWepTable()
end

if file.Exists("damagelog/damagelog_lastroundmap.txt", "DATA") then
	Damagelog.last_round_map = tonumber(file.Read("damagelog/damagelog_lastroundmap.txt", "DATA"))
	file.Delete("damagelog/damagelog_lastroundmap.txt")
end

hook.Add("TTTEndRound", "Damagelog_EndRound", function()
	if Damagelog.DamageTable and (Damagelog.ShootTables and Damagelog.ShootTables[Damagelog.CurrentRound]) then
		local logs = {
			DamageTable = Damagelog.DamageTable,
			ShootTable = Damagelog.ShootTables[Damagelog.CurrentRound],
			Infos = Damagelog.OldLogsInfos
		}
		logs = util.TableToJSON(logs)
		local t = os.time()
		if Damagelog.Use_MySQL and Damagelog.MySQL_Connected then
			local insert = string.format("INSERT INTO damagelog_oldlogs(`date`, `round`, `map`, `damagelog`) VALUES(%i, %i, \"%s\", COMPRESS(%s));",
				t, Damagelog.CurrentRound, game.GetMap(), sql.SQLStr(logs))
			local query = Damagelog.database:query(insert)
			query:start()
		elseif not Damagelog.Use_MySQL then
			local insert = string.format("INSERT INTO damagelog_oldlogs(`id`, `date`, `round`, `map`, `damagelog`) VALUES(%i, %i, %i, \"%s\", %s);",
				GetLogsCount_SQLite() + 1, t, Damagelog.CurrentRound, game.GetMap(), sql.SQLStr(logs))
			sql.Query(insert)
		end
		file.Write("damagelog/damagelog_lastroundmap.txt", tostring(t))
	end
end)

net.Receive("DL_AskLogsList", function(_,ply)
	net.Start("DL_SendLogsList")
	net.WriteTable(Damagelog.available_logs or {})
	net.Send(ply)
end)

local function SendLogs(ply, compressed, cancel)
	net.Start("DL_SendOldLog")
	if cancel then
		net.WriteUInt(0,1)
	else
		net.WriteUInt(1,1)
		net.WriteUInt(#compressed, 32)
		net.WriteData(compressed, #compressed)		
	end
	net.Send(ply)
end

net.Receive("DL_AskOldLog", function(_,ply)
	local _time = net.ReadUInt(32)
	if Damagelog.Use_MySQL and Damagelog.MySQL_Connected then
		local query = Damagelog.database:query("SELECT UNCOMPRESS(damagelog) FROM damagelog_oldlogs WHERE date = ".._time..";")
		query.onSuccess = function(self)
			local data = self:getData()
			net.Start("DL_SendOldLog")
			if data[1] and data[1]["UNCOMPRESS(damagelog)"] then
				local compressed = util.Compress(data[1]["UNCOMPRESS(damagelog)"])
				SendLogs(ply, compressed, false)
			else
				SendLogs(ply, nil, true)
			end
			net.Send(ply)
		end
		query:start()
	elseif not Damagelog.Use_MySQL then
		local query = sql.QueryValue("SELECT damagelog FROM damagelog_oldlogs WHERE date = ".._time..";")
		net.Start("DL_SendOldLog")
		if query then
			SendLogs(ply, util.Compress(query), false)
		else
			SendLogs(ply, nil, true)
		end
	end
end)
