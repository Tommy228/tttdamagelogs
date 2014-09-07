
util.AddNetworkString("DL_AskWeaponTable")
util.AddNetworkString("DL_SendWeaponTable")
util.AddNetworkString("DL_AddWeapon")
util.AddNetworkString("DL_RemoveWeapon")
util.AddNetworkString("DL_WeaponTableDefault")
	
function Damagelog:SaveWeaponTable(callback)
	if Damagelog.Use_MySQL and Damagelog.MySQL_Connected then
		local truncate = Damagelog.database:query("TRUNCATE TABLE damagelog_weapons")
		truncate.onSuccess = function()
			local tbl = {}
			local count = 0
			for k,v in pairs(Damagelog.weapon_table) do
				count = count + 1
				table.insert(tbl, k)
			end
			local i = 0
			local function NextQuery()
				i = i + 1
				if i >= count then 
					if callback then
						callback()
					end
					return 
				end
				local key = tbl[i]
				local query = Damagelog.database:query("INSERT INTO damagelog_weapons(`class`, `name`) VALUES("..sql.SQLStr(key)..","..sql.SQLStr(Damagelog.weapon_table[key])..");")
				query.onSuccess = function(q2)
					q2.callback()
				end
				query.callback = NextQuery
				query:start()
			end
			NextQuery()	
		end
		truncate:start()
	elseif not Damagelog.Use_MySQL then
		sql.Query("DELETE FROM damagelog_weapons;")
		for k,v in pairs(Damagelog.weapon_table) do
			sql.Query("INSERT INTO damagelog_weapons(`class`, `name`) VALUES("..sql.SQLStr(k)..","..sql.SQLStr(v)..");")
		end
		if callback then callback() end
	end
end

Damagelog.weapon_table = {}

function Damagelog:GetWepTable()
	if Damagelog.Use_MySQL and Damagelog.MySQL_Connected then
		local querycount = Damagelog.database:query("SELECT COUNT(class) FROM damagelog_weapons;")
		querycount.onSuccess = function(q)
			local data = q:getData()
			if data[1] then
				local count = tonumber(data[1]["COUNT(class)"])
				if count and count <= 0 then
					Damagelog.weapon_table = table.Copy(Damagelog.weapon_table_default)
					Damagelog:SaveWeaponTable()
				else
					local query = Damagelog.database:query("SELECT * FROM damagelog_weapons;")
					query.onData = function(q2, data)
						Damagelog.weapon_table[data.class] = data.name
					end
					query:start()
				end
			end
		end
		querycount:start()
	elseif not Damagelog.Use_MySQL then
		local count = sql.QueryValue("SELECT COUNT(rowid) FROM damagelog_weapons;")
		if tonumber(count) <= 0 then
			Damagelog.weapon_table = table.Copy(Damagelog.weapon_table_default)
			Damagelog:SaveWeaponTable()
		else
			for i=1, tonumber(count) do
				local row = sql.QueryRow("SELECT class,name FROM damagelog_weapons WHERE rowid = "..i..";")
				Damagelog.weapon_table[row.class] = row.name
			end
		end
	end
end

hook.Add("PlayerInitialSpawn", "Damagelog_PlayerInitialSpawn", function(ply)
	net.Start("DL_SendWeaponTable")
	net.WriteUInt(1,1)
	net.WriteTable(Damagelog.weapon_table)
	net.Send(ply)
end)

net.Receive("DL_AddWeapon", function(_, ply)
	if not ply:IsSuperAdmin() then return end
	local class = net.ReadString()
	local name = net.ReadString()
	if class and name then
		Damagelog.weapon_table[class] = name
		net.Start("DL_SendWeaponTable")
		net.WriteUInt(0,1)
		net.WriteString(class)
		net.WriteString(name)
		net.Broadcast()
		Damagelog:SaveWeaponTable()
	end
end)

net.Receive("DL_RemoveWeapon", function(_,ply)
	if not ply:IsSuperAdmin() then return end
	local classes = net.ReadTable()
	for k,v in pairs(classes) do
		Damagelog.weapon_table[v] = nil
	end
	Damagelog:SaveWeaponTable(function()
		net.Start("DL_SendWeaponTable")
		net.WriteUInt(1,1)
		net.WriteTable(Damagelog.weapon_table)
		net.Broadcast()
	end)
end)

net.Receive("DL_WeaponTableDefault", function(_,ply)
	if not ply:IsSuperAdmin() then return end
	Damagelog.weapon_table = Damagelog.weapon_table_default
	Damagelog:SaveWeaponTable(function()
		net.Start("DL_SendWeaponTable")
		net.WriteUInt(1,1)
		net.WriteTable(Damagelog.weapon_table)
		net.Broadcast()
	end)
end)
