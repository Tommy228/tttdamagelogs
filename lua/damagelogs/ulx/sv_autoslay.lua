
util.AddNetworkString("DL_SlayMessage")
util.AddNetworkString("DL_AutoSlay")

function Damagelog:AutoSlaySQL()
	if self.Use_MySQL and self.MySQL_Connected then
		local query = self.database:query([[CREATE TABLE IF NOT EXISTS damagelog_autoslay (
			id INT UNSIGNED NOT NULL AUTO_INCREMENT,
			ply varchar(255) NOT NULL,
			admins tinytext NOT NULL,
			slays SMALLINT UNSIGNED NOT NULL,
			reason tinytext NOT NULL,
			time BIGINT UNSIGNED NOT NULL,
			PRIMARY KEY(id))
		]])
		query:start()
		local query_names = self.database:query([[CREATE TABLE IF NOT EXISTS damagelog_names (
			id INT UNSIGNED NOT NULL AUTO_INCREMENT,
			steamid varchar(255),
			name varchar(255),
			PRIMARY KEY(id))
		]])
		query_names:start()
	end
end

hook.Add("PlayerAuthed", "DamagelogNames", function(ply, steamid, uniqueid)
	local name = ply:Nick()
	if Damagelog.Use_MySQL and Damagelog.MySQL_Connected then
		local query = Damagelog.database:query("SELECT name FROM damagelog_names WHERE steamid = '"..steamid.."';")
		query.onSuccess = function(self)
			local data = self:getData()
			if not data[1] then
				local insert = Damagelog.database:query("INSERT INTO damagelog_names (`steamid`, `name`) VALUES('"..steamid.."', "..sql.SQLStr(name)..");")
				insert:start()
			elseif data[1].name != ply:Nick() then
				local update = Damagelog.database:query("UPDATE damagelog_names SET name = "..sql.SQLStr(name).." WHERE steamid = '"..steamid.."';")
				update:start()
			end
		end
		query:start()
	end
end)

function Damagelog:GetName(steamid, callback)
	for k,v in pairs(player.GetAll()) do
		if v:SteamID() == steamid then
			callback(v:Nick())
			return
		end
	end
	local query = Damagelog.database:query("SELECT name FROM damagelog_names WHERE steamid = '"..steamid.."';")
	query.onSuccess = function(self)
		local data = self:getData()
		self.callback(data[1] and data[1].name or "<Name not found>")
	end
	query.callback = callback
	query:start()
end

function Damagelog.SlayMessage(ply, message)
	net.Start("DL_SlayMessage")
	net.WriteString(message)
	net.Send(ply)
end

function Damagelog:CreateSlayList(tbl, func)
	local result = ""
	if #tbl == 0 then
		func("<Error>")
	elseif #tbl == 1 then
		self:GetName(tbl[1], func)
	else
		local k = 0
		local function Next()
			k = k + 1
		    local v = tbl[k]
			self:GetName(v, function(nick)
				if k == #tbl then 
			        result = result.." and "..nick
					func(result)
				elseif k == 1 then 
			        result = name
					Next()
			    else 
			        result = result..", "..nick
					Next()
			    end
		    end)
	    end
		Next()
	end
end

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


function Damagelog:SetSlays(admin, steamid, slays, reason)
	if slays == 0 then
	    local query_remove = Damagelog.database:query("DELETE FROM damagelog_autoslay WHERE ply = '"..steamid.."'")
		query_remove.onSuccess = function(query)
			self:GetName(steamid, function(nick)
				Damagelog.SlayMessage(admin, nick.." will not be slain.")
            end)
		end
		query_remove:start()
	else
	    local query_exists = Damagelog.database:query("SELECT * FROM damagelog_autoslay WHERE ply = '"..steamid.."'")
	    query_exists.onSuccess = function(q)
		    local data = q:getData()[1]
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
				    local query = Damagelog.database:query("UPDATE damagelog_autoslay SET admins = "..sql.SQLStr(util.TableToJSON(new_steamids))..", reason = "..sql.SQLStr(reason)..", time = "..os.time().." WHERE ply = '"..steamid.."'")
				    query.onSuccess = function() 
						self:CreateSlayList(old_steamids, function(list)
							self:GetName(steamid, function(nick)
								self.SlayMessage(admin, nick.." was already autoslain "..tostring(slays).." time(s) by "..list..". The reason has been changed to '"..reason.."'.")
							end)
						end)
				    end
				    query:start()
			    else
				    local difference = slays - old_slays
					local query = Damagelog.database:query(string.format("UPDATE damagelog_autoslay SET admins = %s, slays = %i, reason = %s, time = %s WHERE ply = '%s'", sql.SQLStr(new_admins), slays, sql.SQLStr(reason), tostring(os.time()), steamid))
					query.onSuccess = function()
						self:CreateSlayList(old_steamids, function(list)
							self:GetName(steamid, function(nick)
								self.SlayMessage(admin, "You have "..(difference > 0 and "added " or "removed ")..tostring(math.abs(difference)).." autoslays to "..nick..". He was previously autoslain "..old_slays.." time(s) by "..list..".")
							end)
						end)
					end
					query:start()
				end
		    else
			    local admins
			    if IsValid(admin) and type(admin) == "Player" then
				    admins = util.TableToJSON( { admin:SteamID() } )
				else
				    admins = util.TableToJSON( { "Console" } )
				end
			    local query = Damagelog.database:query(string.format("INSERT INTO damagelog_autoslay (`admins`, `ply`, `slays`, `reason`, `time`) VALUES (%s, '%s', %i, %s, %s)", sql.SQLStr(admins), steamid, slays, sql.SQLStr(reason), tostring(os.time())))
				query.onSuccess = function(q)
				    self:GetName(steamid, function(nick)
					    self.SlayMessage(admin, nick.." will be slain "..slays.." times for '"..reason.."'.")
					end)
				end
				query:start()
			end
		end
		query_exists:start()
	end
end

hook.Add("TTTBeginRound", "Damagelog_AutoSlay", function()
	if Damagelog.Use_MySQL and Damagelog.MySQL_Connected then
		for k,v in pairs(player.GetAll()) do
			local query = Damagelog.database:query("SELECT * FROM damagelog_autoslay WHERE ply = '"..v:SteamID().."'")
			query.onSuccess = function(q)
				if q:getData() and q:getData()[1] then
					v:Kill()
					local data = q:getData()[1]
					local admins = util.JSONToTable(data.admins) or {}
					local slays = data.slays
					local reason = data.reason
					local _time = data.time
					slays = slays - 1
					if slays <= 0 then
						local query2 = Damagelog.database:query("DELETE FROM damagelog_autoslay WHERE ply = '"..v:SteamID().."'")
						query2:start()
					else
						local query2 = Damagelog.database:query("UPDATE damagelog_autoslay SET slays = slays - 1 WHERE ply = '"..v:SteamID().."'")
						query2:start()
					end
					Damagelog:CreateSlayList(admins, function(list)
						net.Start("DL_AutoSlay")
						net.WriteEntity(v)
						net.WriteString(list)
						net.WriteString(reason)
						net.WriteString(Damagelog:FormatTime(tonumber(os.time()) - tonumber(_time)))
						net.Broadcast()
					end)
				end
			end
			query:start()
		end
	end	
end)