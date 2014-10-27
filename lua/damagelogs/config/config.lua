

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

-- Commands to open the report and response menu. Don't forget the quotation marks

Damagelog.RDM_Manager_Command = "!report"


--[[ Set to true if you want to enable MySQL (it needs to be configured on config/mysqloo.lua)
	Setting it to false will make the logs use SQLite (garrysmod/sv.db)
]]--

Damagelog.Use_MySQL = false

-- Enable advanced autoslay (WIP). MySQL and ULX users only! The command is !autoslay

Damagelog.Enable_Autoslay = false

-- The number of days the logs last on the database (to avoid lags when opening the menu)

Damagelog.LogDays = 31
