
Damagelog = Damagelog or {}

Damagelog.VERSION = "2.4.0"

if not file.IsDir("damagelog", "DATA") then
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
	include("damagelogs/sv_damagelog.lua")
else
	include("damagelogs/cl_damagelog.lua")
end
