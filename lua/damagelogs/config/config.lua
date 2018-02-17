--[[ User rights.

	First argument: name of usergroup (e. g. "user" or "admin").

	Second argument: access level. Default value is 2 (will be used if a usergroup isn't here).
	1 : Can't view 'Logs before your death' tab in !report frame
	2 : Can't view logs of active rounds
	3 : Can view logs of active rounds as a spectator
	4 : Can always view logs of active rounds

	Everyone can view logs of previous rounds.

	Third argument: access to RDM Manager tab in Damagelogs (true/false).
]]--

Damagelog:AddUser("owner", 4, true)
Damagelog:AddUser("founder", 4, true)
Damagelog:AddUser("superadmin", 4, true)
Damagelog:AddUser("admin", 4, true)
Damagelog:AddUser("operator", 3, false)
Damagelog:AddUser("user", 2, false)

-- The F-key

Damagelog.Key = KEY_F8

--[[ Is a message shown when an alive player opens the menu?
	0 : if you want to only show it to superadmins
	1 : to let others see that you have abusive admins
]]--

Damagelog.AbuseMessageMode = 0

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

--[[ Autoslay and Autojail Mode
REQUIRES ULX ! If you are using ServerGuard, set this to 0 (it will use ServerGuard's autoslay automatically)
- 0 : Disables autoslay
- 1 : Enables the !aslay and !aslayid command for ULX, designed to work with the logs.
	  Works like that : !aslay target number_of_slays reason
	  Example : !aslay tommy228 2 RDMing a traitor
	  Example : !aslayid STEAM_0:0:1234567 2 RDMing a traitor
- 2 : Enables the autojail system instead of autoslay. Replaces the !aslay and !aslay commands by !ajail and !ajailid
]]--

Damagelog.ULX_AutoslayMode = 1

-- Force autoslain players to be innocents (ULX only)
-- Do not enable this if another addon interferes with roles (Pointshop roles for example)

Damagelog.ULX_Autoslay_ForceRole = true

-- Default autoslay reasons (ULX and ServerGuard)

Damagelog.Autoslay_DefaultReason1 = "random kill"
Damagelog.Autoslay_DefaultReason2 = "multiple random kills"
Damagelog.Autoslay_DefaultReason3 = "random damage"
Damagelog.Autoslay_DefaultReason4 = "multiple random damage"
Damagelog.Autoslay_DefaultReason5 = "teamkill"
Damagelog.Autoslay_DefaultReason6 = "needless report"
Damagelog.Autoslay_DefaultReason7 = "unfitting answer"
Damagelog.Autoslay_DefaultReason8 = "unfitting language"
Damagelog.Autoslay_DefaultReason9 = "lying"
Damagelog.Autoslay_DefaultReason10 = "propkill"
Damagelog.Autoslay_DefaultReason11 = "teaming"
Damagelog.Autoslay_DefaultReason12 = "random kos"

-- Default ban reasons (ULX and ServerGuard)

Damagelog.Ban_DefaultReason1 = "random kill"
Damagelog.Ban_DefaultReason2 = "multiple random kills"
Damagelog.Ban_DefaultReason3 = "random damage"
Damagelog.Ban_DefaultReason4 = "multiple random damage"
Damagelog.Ban_DefaultReason5 = "unfitting answer"
Damagelog.Ban_DefaultReason6 = "unfitting answers"
Damagelog.Ban_DefaultReason7 = "unfitting language"
Damagelog.Ban_DefaultReason8 = "teaming"
Damagelog.Ban_DefaultReason9 = "ghosting"
Damagelog.Ban_DefaultReason10 = "rude"
Damagelog.Ban_DefaultReason11 = "cheating"
Damagelog.Ban_DefaultReason12 = "spam"

-- The number of days the logs last on the database (to avoid lags when opening the menu)

Damagelog.LogDays = 61

-- Hide the Donate button on the top-right corner

Damagelog.HideDonateButton = false

-- Use the Workshop to download content files

Damagelog.UseWorkshop = true

-- Force a language - When empty use user-defined language

Damagelog.ForcedLanguage = ""

-- Allow reports even with no staff online

Damagelog.NoStaffReports = false

-- Allow more than 2 reports per round

Damagelog.MoreReportsPerRound = false

-- Allow reports before playing

Damagelog.ReportsBeforePlaying = false

-- Private message prefix from RDM Manager

Damagelog.PrivateMessagePrefix = "[RDM Manager]"

-- Discord Webhooks
-- You can create a webhook on your Discord server that will automatically post messages when a report is created.

-- Webhook mode:
-- 0 - disabled
-- 1 - create messages for new reports when there are no admins online
-- 2 - create messages for every report
Damagelog.DiscordWebhookMode = 0
-- Don't forget to set the value of "ttt_dmglogs_discordurl" convar to your webhook URL in server.cfg