if SERVER then
	Damagelog:EventHook("TTTPlayerRadioCommand")
else
	Damagelog:AddFilter("Show Radio commands", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("Radio Command Default", Color(182,182,182))
	Damagelog:AddColor("Radio Command TeamKOS", Color(255,0,0))
end

local event = {}

event.Type = "RADIO"

function event:TTTPlayerRadioCommand(ply, msg_name, msg_target)

	local name
	local name_role = false
	local target_steamid = false

	-- translation of strings is clientside?
	if isstring(msg_target) then
		name = msg_target
	else
		if IsValid(msg_target) then
			if msg_target:IsPlayer() then
				name = msg_target:Nick()
				name_role = msg_target:GetRole()
				target_steamid = msg_target:SteamID()
			elseif msg_target:GetClass() == "prop_ragdoll" then
				name = "corpse of "
				name = name..CORPSE.GetPlayerNick(msg_target, "<Player disconnected>")
			end
		end
	end

	self.CallEvent({
		[1] = (IsValid(ply) and ply:Nick() or "<Disconnected Retriever>"),
		[2] = (IsValid(ply) and ply:GetRole() or "disconnected"),
		[3] = (IsValid(ply) and ply:SteamID() or "<Disconnected Retriever>"),
		[4] = msg_name,
		[5] = name,
		[6] = name_role,
		[7] = target_steamid
	})
end

function event:ToString(v)
	if not v[6] then
		return string.format("%s [%s] used the radio with %s on %s.", v[1], Damagelog:StrRole(v[2]), v[4], v[5])
	else
		return string.format("%s [%s] used the radio with %s on %s [%s].", v[1], Damagelog:StrRole(v[2]), v[4], v[5], Damagelog:StrRole(v[6]))
	end
end

function event:IsAllowed(tbl)
	return Damagelog.filter_settings["Show TTTRadio"]
end

function event:Highlight(line, tbl, text)
	if table.HasValue(Damagelog.Highlighted, tbl[1]) or table.HasValue(Damagelog.Highlighted, tbl[5]) then
		return true
	end
	return false
end

function event:GetColor(tbl)
	if not tbl[6] then
		return Damagelog:GetColor("TTTRadio")
	end
	if tbl[4] == "quick_traitor" and tbl[2] == tbl[6] then
		return Damagelog:GetColor("Radio Command TeamKOS")
	else
		return Damagelog:GetColor("Radio Command Default")
	end
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)
	if not tbl[6] then
		line:ShowCopy(true, { tbl[1], tbl[3] })
	else
		line:ShowCopy(true, { tbl[1], tbl[3] }, { tbl[5], tbl[7] })
	end
end

Damagelog:AddEvent(event)