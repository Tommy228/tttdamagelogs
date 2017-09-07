
local function CreateCommand()

	if not ulx then return end

	local mode = Damagelog.ULX_AutoslayMode

	if mode != 1 and mode != 2 then return end
	local aslay = mode == 1

	function ulx.autoslay(calling_ply, target, rounds, reason)
		Damagelog:SetSlays(calling_ply, target:SteamID(), rounds, reason, target)
	end

	function ulx.autoslayid(calling_ply, target, rounds, reason)
		if ULib.isValidSteamID(target) then
			for k,v in ipairs(player.GetHumans()) do
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

	function ulx.cslays(calling_ply, target)
		local data = sql.QueryRow("SELECT * FROM damagelog_autoslay WHERE ply = '"..target:SteamID().."' LIMIT 1;")
		local txt = aslay and "slays" or "jails"
		local p = "has"
		if calling_ply == target then
			p = "have"
		end
		if data then
			ulx.fancyLogAdmin(admin, "#T "..p.." "..data.slays.." "..txt.." left with the reason : #s", target, data.reason)
		else
			ulx.fancyLogAdmin(admin, "#T "..p.." no "..txt.." left.", target)
		end
	end

	function ulx.cslaysid(calling_ply, steamid)
		if not ULib.isValidSteamID(steamid) then
			ULib.tsayError(calling_ply, "Invalid steamid.", true)
			return
		end
		local data = sql.QueryRow("SELECT * FROM damagelog_autoslay WHERE ply = '"..steamid.."' LIMIT 1;")
		local txt = aslay and "slays" or "jails"
		if data then
			ulx.fancyLogAdmin(admin, "#s has "..data.slays.." "..txt.." left with the reason : #s", steamid, data.reason)
		else
			ulx.fancyLogAdmin(admin, "#s has no "..txt.." left.", steamid)
		end
	end

	local autoslay = ulx.command("TTT", aslay and "ulx aslay" or "ulx ajail", ulx.autoslay, aslay and "!aslay" or "!ajail")
	autoslay:addParam({ type=ULib.cmds.PlayerArg })
	autoslay:addParam({
		type = ULib.cmds.NumArg,
		min = 0,
		default = 1,
		hint = "rounds (0 to cancel slay)",
		ULib.cmds.optional,
		ULib.cmds.round
	})
	autoslay:addParam({
		type = ULib.cmds.StringArg,
		hint = aslay and "slay reason" or "jail reason",
		default = Damagelog.Autoslay_DefaultReason,
		ULib.cmds.optional,
		ULib.cmds.takeRestOfLine
	})
	autoslay:defaultAccess(ULib.ACCESS_ADMIN)
	local help
	if aslay then
		help = "Slays the target for a specified number of rounds. Set the rounds to 0 to cancel the slay."
	else
		help = "Jails the target for a specified number of rounds. Set the rounds to 0 to cancel the jails."
	end
	autoslay:help(help)

	local autoslayid = ulx.command("TTT", aslay and "ulx aslayid" or "ulx ajailid", ulx.autoslayid, aslay and "!aslayid" or "!ajailid")
	autoslayid:addParam({
		type = ULib.cmds.StringArg,
		hint ="steamid"
	})
	autoslayid:addParam({
		type = ULib.cmds.NumArg,
		min = 0,
		default = 1,
		hint = aslay and "rounds (0 to cancel slay)" or "rounds (0 to cancel jails)",
		ULib.cmds.optional,
		ULib.cmds.round
	})
	autoslayid:addParam({
		type = ULib.cmds.StringArg,
		hint = aslay and "slay reason" or "jail reason",
		default = Damagelog.Autoslay_DefaultReason,
		ULib.cmds.optional,
		ULib.cmds.takeRestOfLine
	})
	autoslayid:defaultAccess(ULib.ACCESS_ADMIN)
	if aslay then
		help = "Slays the steamid for a specified number of rounds. Set the rounds to 0 to cancel the slay."
	else
		help = "Jails the steamid for a specified number of rounds. Set the rounds to 0 to cancel the jails."
	end
	autoslayid:help(help)

	local cslays = ulx.command("TTT", aslay and "ulx cslays" or "ulx cjails", ulx.cslays, aslay and "!cslays" or "!cjails")
	cslays:addParam({ type=ULib.cmds.PlayerArg })

	local cslaysid = ulx.command("TTT", aslay and "ulx cslaysid" or "ulx cjailsid", ulx.cslaysid, aslay and "!cslaysid" or "!cjailsid")
	cslaysid:addParam({
		type = ULib.cmds.StringArg,
		hint ="steamid"
	})
end
hook.Add("Initialize", "AutoSlay", CreateCommand)

hook.Add("ShouldCollide", "ShouldCollide_Ghost", function(ent1, ent2)
	if IsValid(ent1) and IsValid(ent2) then
		if ent1:IsPlayer() and not ent1.jail and ent2.jailWall then
			return false
		end
		if ent2:IsPlayer() and not ent2.jail and ent1.jailWall then
			return false
		end
	end
end)

if CLIENT then

	local mode = Damagelog.ULX_AutoslayMode

	if mode != 1 and mode != 2 then return end
	local aslay = mode == 1

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
		local text = aslay and " has been autoslain by " or " has been autojailed by "
		chat.AddText(Color(255, 62, 62), ply:Nick(), color_white, text, color_lightblue, list.." ", color_white, _time.." ago with the reason: '"..reason.."'.")
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
		local auto = aslay and " autoslay" or " autojail"
		chat.AddText(Color(255,62,62), nick.."("..steamid..") has disconnected with "..slays..auto..(slays > 1 and "s" or "").." left!")
	end)

	local ents = {}
	net.Receive("SendJails", function()
		local count = net.ReadUInt(32)
		local walls = {}
		for i=1, count do
			table.insert(walls, net.ReadEntity())
		end
		for k,v in pairs(walls) do
			table.insert(ents, v)
		end
	end)
	hook.Add("Think", "JailWalls", function()
		local function CheckWalls()
			local found = false
			for k,v in pairs(ents) do
				if IsValid(v) then
					v:SetCustomCollisionCheck(true)
					v.jailWall = true
					table.remove(ents, k)
					found = true
					break
				end
			end
			if found then
				CheckWalls()
			end
		end
		CheckWalls()
	end)

end
