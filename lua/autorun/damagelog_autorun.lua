-- if engine.ActiveGamemode() == 'terrortown' then
	Damagelog = Damagelog or {}
	Damagelog.VERSION = "3.1.0"

	if not file.Exists("damagelog", "DATA") then
		file.CreateDir("damagelog")
	end

	Damagelog.User_rights = Damagelog.User_rights or {}
	Damagelog.RDM_Manager_Rights = Damagelog.RDM_Manager_Rights or {}

	function Damagelog:AddUser(user, rights, rdm_manager)
		self.User_rights[user] = rights
		self.RDM_Manager_Rights[user] = rdm_manager
	end

	if SERVER then
		AddCSLuaFile()
		AddCSLuaFile("damagelogs/client/init.lua")
		include("damagelogs/server/init.lua")
	else
		include("damagelogs/client/init.lua")
	end
-- else
	-- print("Gamemode is not TTT")
-- end
