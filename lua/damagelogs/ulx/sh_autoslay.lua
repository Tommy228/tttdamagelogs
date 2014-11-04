
local function CreateCommand()

	if not Damagelog.Enable_Autoslay then return end
	if not ulx then return end

	function ulx.autoslay(calling_ply, target, rounds, reason)
		Damagelog:SetSlays(calling_ply, target:SteamID(), rounds, reason, target)
	end
	
	local autoslay = ulx.command("TTT", "ulx autoslay", ulx.autoslay, "!autoslay" )
	autoslay:addParam({ type=ULib.cmds.PlayerArg })
	autoslay:addParam({ 
		type=ULib.cmds.NumArg,
		min = 0,
		default = 1, 
		hint= "rounds (0 to cancel slay)", 
		ULib.cmds.optional, 
		ULib.cmds.round 
	})
	autoslay:addParam({ 
		type=ULib.cmds.StringArg, 
		hint="slay reason", 
		default = "No reason specified",
		ULib.cmds.optional,
		ULib.cmds.takeRestOfLine
	})
	autoslay:defaultAccess(ULib.ACCESS_ADMIN)
	autoslay:help("Slays the targets for a specified number of rounds. Set the rounds to 0 to cancel the slay.")
end
hook.Add("Initialize", "AutoSlay", CreateCommand)

if CLIENT then

	function Damagelog.SlayMessage()
		chat.AddText(Color(255,128,0), "[Autoslay] ", Color(255,128,64), net.ReadString())
	end
	net.Receive("DL_SlayMessage", Damagelog.SlayMessage)
	
	net.Receive("DL_AutoSlay", function()
		local ply = net.ReadEntity()
		local list = net.ReadString()
		local reason = net.ReadString()
		local _time = net.ReadString()
		chat.AddText(Color(255, 62, 62), ply:Nick(), color_white, " has been autoslain by ",  Color(98, 176, 255), list.." ", color_white, _time.." ago with the reason : '"..reason.."'.")
	end)
end
