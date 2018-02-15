
if SERVER then
	Damagelog:EventHook("TTTPlayerRadioCommand")
else
	Damagelog:AddFilter("filter_show_radiocommands", DAMAGELOG_FILTER_BOOL, false)
	Damagelog:AddFilter("filter_show_radiokos", DAMAGELOG_FILTER_BOOL, false)
	Damagelog:AddColor("color_defaultradio", Color(182,182,182))
	Damagelog:AddColor("color_kosradio", Color(255,0,0))
end

local event = {}

event.Type = "RADIO"

function event:TTTPlayerRadioCommand(ply, msg_name, msg_target)

	local name
	local name_role = false
	local target_steamid = false

	if isstring(msg_target) then
		name = msg_target
	else
		if IsValid(msg_target) then
			if msg_target:IsPlayer() then
				name = msg_target:Nick()
				name_role = msg_target:GetRole()
				target_steamid = msg_target:SteamID()
			elseif msg_target:GetClass() == "prop_ragdoll" then
				name = TTTLogTranslate(GetDMGLogLang, "CorpseOf")..CORPSE.GetPlayerNick(msg_target, TTTLogTranslate(GetDMGLogLang, "DisconnectedPlayer"))
				name_role = "disconnected"
			end
		end
	end

	if name then
		self.CallEvent({
			[1] = ply:GetDamagelogID(),
			[2] = msg_name,
			[3] = name,
			[4] = name_role,
			[5] = target_steamid
		})
	end
end

function event:ToString(v, roles)

	-- copied localization from cl_voice.lua
	local targetply = true
	local param = v[3]
	local lang_param = LANG.GetNameParam(param)
	if lang_param then
		if lang_param == "quick_corpse_id" then
			-- special case where nested translation is needed
			param = LANG.GetPTranslation(lang_param, {player = v[5]})
		else
			param = LANG.GetTranslation(lang_param)
		end
	elseif LANG.GetRawTranslation(param) then
			targetply = false
			param = LANG.GetTranslation(param)
	end

	local text = LANG.GetPTranslation(v[2], {player = param})

	if lang_param then
		text = util.Capitalize(text)
	end

	local targetrole = ""
	if targetply then
		targetrole = " ["..Damagelog:StrRole(v[4]).."]"
	end
	local ply = Damagelog:InfoFromID(roles, v[1])
	return string.format(TTTLogTranslate(GetDMGLogLang, "RadioUsed"), ply.nick, Damagelog:StrRole(ply.role), text, targetrole)
end

function event:IsAllowed(tbl, roles)
	local ply = Damagelog:InfoFromID(roles, tbl[1])
	if tbl[2] != "quick_traitor" then
		return Damagelog.filter_settings["filter_show_radiocommands"]
	else
		return Damagelog.filter_settings["filter_show_radiokos"]
	end
end

function event:Highlight(line, tbl, text)
	if table.HasValue(Damagelog.Highlighted, tbl[1]) or table.HasValue(Damagelog.Highlighted, tbl[5]) then
		return true
	end
	return false
end

function event:GetColor(tbl, roles)
	local ply = Damagelog:InfoFromID(roles, tbl[1])
	if tbl[2] != "quick_traitor" then
		return Damagelog:GetColor("color_defaultradio")
	else
		return Damagelog:GetColor("color_kosradio")
	end
end

function event:RightClick(line, tbl, roles, text)
	line:ShowTooLong(true)
	local ply = Damagelog:InfoFromID(roles, tbl[1])
	if not tbl[5] then
		line:ShowCopy(true, { ply.nick, util.SteamIDFrom64(ply.steamid64) })
	else
		line:ShowCopy(true,  { ply.nick, util.SteamIDFrom64(ply.steamid64) }, { tbl[3], tbl[5] })
	end
end

Damagelog:AddEvent(event)