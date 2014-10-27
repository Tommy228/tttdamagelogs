
util.AddNetworkString("DL_SendStats")

local day = tonumber(os.date("%d"))
local month = tonumber(os.date("%m"))
local year = tonumber(os.date("%y"))

function Damagelog:StatisticsSQL()
	if self.Use_MySQL and self.MySQL_Connected then
		local query = self.database:query([[CREATE TABLE IF NOT EXISTS damagelog_statistics(
			id INT UNSIGNED NOT NULL AUTO_INCREMENT,
			year SMALLINT UNSIGNED NOT NULL,
			month TINYINT UNSIGNED NOT NULL,
			day TINYINT UNSIGNED NOT NULL,
			_key varchar(255) NOT NULL,
			_value INT NOT NULL,
			PRIMARY KEY(id))
		]])
		query.onSuccess = function()
			local exists = self.database:query("SELECT * FROM damagelog_statistics WHERE day = "..day.." AND month = "..month.." AND year = "..year.." LIMIT 1;")
			exists.onSuccess = function(q)
				local data = q:getData()
				if #data <= 0 then
					local keys = {
						"normal_damages",
						"team_damages",
						"normal_kills",
						"team_kills"
					}
					for k,v in pairs(keys) do
						local insert = self.database:query("INSERT INTO damagelog_statistics(`year`, `month`, `day`, `_key`, `_value`) VALUES("..year..","..month..","..day..",'"..v.."', 0);")
						insert:start()
					end
				end
			end
			exists:start()
			local month_query
			if month-1 <= 0 then
				month_query = "SELECT * FROM damagelog_statistics WHERE month = "..month.." OR (month = 12 AND year = "..(year-1)..")"
			else
				month_query = "SELECT * FROM damagelog_statistics WHERE month = "..month.." OR month = "..(month-1)
			end
			local month_select = self.database:query(month_query)
			month_select.onSuccess = function(q)
				local data = q:getData()
				self.month_stats = {}
				local temp_stats = {}
				for k,v in pairs(data) do
					local index = util.TableToJSON({
						day = v.day,
						month = v.month,
						year = v.year
					})
					if not temp_stats[index] then
						temp_stats[index] = {}
					end
					temp_stats[index][v._key] = v._value
				end
				for k,v in pairs(temp_stats) do
					local total_damages = v.normal_damages + v.team_damages
					local percent_teamdamages = 0
					if total_damages > 0 then
						percent_teamdamages = math.Round(100*v.team_damages/(total_damages))
					end
					local total_kills = v.normal_kills + v.team_kills
					local percent_teamkills = 0
					if total_kills > 0 then
						percent_teamkills = math.Round(100*v.team_kills/total_kills)
					end
					self.month_stats[k] = {
						teamkills = percent_teamkills,
						teamdamages = percent_teamdamages
					}
				end
				self.month_stats_json = util.Compress(util.TableToJSON(self.month_stats))
			end
			month_select:start()
		end
		query:start()
	else
		if not sql.TableExists("damagelog_statistics") then
			sql.Query([[CREATE TABLE damagelog_statistics(
				year SMALLINT UNSIGNED NOT NULL,
				month TINYINT UNSIGNED NOT NULL,
				day TINYINT UNSIGNED NOT NULL,
				_key varchar(255) NOT NULL,
				_value INT NOT NULL)
			]])
		end
		local exists = sql.Query("SELECT * FROM damagelog_statistics WHERE day = "..day.." AND month = "..month.." AND year = "..year.." LIMIT 1;")
		if not exists then
			local keys = {
				"normal_damages",
				"team_damages",
				"normal_kills",
				"team_kills"
			}
			for k,v in pairs(keys) do
				sql.Query("INSERT INTO damagelog_statistics(`year`, `month`, `day`, `_key`, `_value`) VALUES("..year..","..month..","..day..",'"..v.."', 0);")
			end
		else
			local month_query
			if month-1 <= 0 then
				month_query = "SELECT * FROM damagelog_statistics WHERE month = "..month.." OR (month = 12 AND year = "..(year-1)..")"
			else
				month_query = "SELECT * FROM damagelog_statistics WHERE month = "..month.." OR month = "..(month-1)
			end
			local data = sql.Query(month_query)
			self.month_stats = {}
			local temp_stats = {}
			for k,v in pairs(data) do
				local index = util.TableToJSON({
					day = v.day,
					month = v.month,
					year = v.year
				})
				if not temp_stats[index] then
					temp_stats[index] = {}
				end
				temp_stats[index][v._key] = v._value
			end
			for k,v in pairs(temp_stats) do
				local total_damages = v.normal_damages + v.team_damages
				local percent_teamdamages = 0
				if total_damages > 0 then
					percent_teamdamages = math.Round(100*v.team_damages/(total_damages))
				end
				local total_kills = v.normal_kills + v.team_kills
				local percent_teamkills = 0
				if total_kills > 0 then
					percent_teamkills = math.Round(100*v.team_kills/total_kills)
				end
				self.month_stats[k] = {
					teamkills = percent_teamkills,
					teamdamages = percent_teamdamages
				}
			end
			self.month_stats_json = util.Compress(util.TableToJSON(self.month_stats))			
		end
	end
end

hook.Add("PlayerAuthed", "Damagelog_statistics", function(ply)
	if Damagelog.month_stats_json then
		local length = #Damagelog.month_stats_json
		net.Start("DL_SendStats")
		net.WriteUInt(length, 32)
		net.WriteData(Damagelog.month_stats_json, length)
		net.Send(ply)
	end
end)


function Damagelog:AddToStats(key, incr)
	local querystr = "UPDATE damagelog_statistics SET _value = _value + "..incr.." WHERE _key = '"..key.."'"
	if self.Use_MySQL and self.MySQL_Connected then
		local query = self.database:query(querystr)
		query:start()
	else
		sql.Query(querystr)
	end
end

hook.Add("TTTBeginRound", "DamagelogStatistics", function()
	Damagelog.TeamDamages = 0
	Damagelog.NormalDamages = 0
	Damagelog.TeamKills = 0
	Damagelog.NormalKills = 0
end)

hook.Add("TTTEndRound", "DamagelogStatistics", function()
	Damagelog:AddToStats("team_damages", Damagelog.TeamDamages)
	Damagelog:AddToStats("normal_damages", Damagelog.NormalDamages)
	Damagelog:AddToStats("team_kills", Damagelog.TeamKills)
	Damagelog:AddToStats("normal_kills", Damagelog.NormalKills)
end)