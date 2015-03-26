
local function CreateCommand()

	if not Damagelog.Enable_Autoslay then return end
	if not ulx then return end

	function ulx.autoslay(calling_ply, target, rounds, reason)
		Damagelog:SetSlays(calling_ply, target:SteamID(), rounds, reason, target)
	end
	
	function ulx.autoslayid(calling_ply, target, rounds, reason)
		if ULib.isValidSteamID(target) then
			for k,v in pairs(player.GetAll()) do
				if v:SteamID() == target then
					ulx.autoslay(calling_ply, v, rounds, reason)
					return
				end
			end
			Damagelog:SetSlays(calling_ply, target, rounds, reason, false)
		else
			ULib.tsayError(calling_ply, "Invalid steamid.", true)
		end
	end
	
	local autoslay = ulx.command("TTT", "ulx aslay", ulx.autoslay, "!aslay" )
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
		default = Damagelog.Autoslay_DefaultReason,
		ULib.cmds.optional,
		ULib.cmds.takeRestOfLine
	})
	autoslay:defaultAccess(ULib.ACCESS_ADMIN)
	autoslay:help("Slays the target for a specified number of rounds. Set the rounds to 0 to cancel the slay.")
	
	local autoslayid = ulx.command("TTT", "ulx aslayid", ulx.autoslayid, "!aslayid" )
	autoslayid:addParam({ 
		type=ULib.cmds.StringArg, 
		hint="steamid"
	})
	autoslayid:addParam({ 
		type=ULib.cmds.NumArg,
		min = 0,
		default = 1, 
		hint= "rounds (0 to cancel slay)", 
		ULib.cmds.optional, 
		ULib.cmds.round 
	})
	autoslayid:addParam({ 
		type=ULib.cmds.StringArg, 
		hint="slay reason", 
		default = Damagelog.Autoslay_DefaultReason,
		ULib.cmds.optional,
		ULib.cmds.takeRestOfLine
	})
	autoslayid:defaultAccess(ULib.ACCESS_ADMIN)
	autoslayid:help("Slays a steamid for a specified number of rounds. Set the rounds to 0 to cancel the slay.")
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
		if not IsValid(ply) or not list or not reason or not _time then return end
		chat.AddText(Color(255, 62, 62), ply:Nick(), color_white, " has been autoslain by ",  Color(98, 176, 255), list.." ", color_white, _time.." ago with the reason: '"..reason.."'.")
	end)
	
	net.Receive("DL_AutoSlaysLeft", function()
		local ply = net.ReadEntity()
		local slays = net.ReadUInt(32)
		if not IsValid(ply) or not slays then return end
		ply.AutoslaysLeft = slays
	end)
	
	net.Receive("DL_PlayerLeft", function()
		local nick = net.ReadString()
		local steamid = net.ReadString()
		local slays = net.ReadUInt(32)
		if not nick or not steamid or not slays then return end
		chat.AddText(Color(255,62,62), nick.."("..steamid..") has disconnected with "..slays.." autoslay"..(slays > 1 and "s" or "").." left!")
	end)
end
