

--[[ User rights. 

	NOTE : After the 2.0 update, everyone can open the logs to view the logs of the previous rounds.

	The default level is 1 if your rank isn't here.
	
	1 and 2 : Can't view logs of the active rounds
	3 : Can view the logs of the active rounds as a spectator
	4 : Can always view the logs of the active ranks
	
	The third argument is the RDM Manager access. Set it to true or false.
]]--

Damagelog:AddUser("superadmin", 4, true)
Damagelog:AddUser("admin", 4, true)
Damagelog:AddUser("operator", 1, false)
Damagelog:AddUser("user", 1, false)
Damagelog:AddUser("guest", 1, false)

-- The F-key

Damagelog.Key = KEY_F8

--[[ A message is shown when an alive player opens the menu
	1 : if you want to only show it to superadmins
	2 : to let others see that you have abusive admins
]]--

Damagelog.AbuseMessageMode = 1

-- true to enable the RDM Manager, false to disable it

Damagelog.RDM_Manager_Enabled = true

-- Command to open the report menu. Don't forget the quotation marks

Damagelog.RDM_Manager_Command = "!report"

-- Command to open the respond menu while you're alive

Damagelog.Respond_Command = "!respond"

--[[ Set to true if you want to enable MySQL (it needs to be configured on config/mysqloo.lua)
	Setting it to false will make the logs use SQLite (garrysmod/sv.db)
]]--

Damagelog.Use_MySQL = false

--[[ Enables the !aslay and !aslayid command for ULX, designed to work with the logs.
Works like that : !aslay target number_of_slays reason
Example : !aslay tommy228 2 RDMing a traitor
Example : !aslayid STEAM_0:0:1234567 2 RDMing a traitor
]]--

Damagelog.Enable_Autoslay = true

-- Force autoslain players to be innocents (overrides SelectRoles)

Damagelog.Autoslay_ForceRole = false

-- Default autoslay reason

Damagelog.Autoslay_DefaultReason = "No reason specified"

-- The number of days the logs last on the database (to avoid lags when opening the menu)

Damagelog.LogDays = 31
