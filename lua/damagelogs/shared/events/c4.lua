if SERVER then
	Damagelog:EventHook("Initialize")
	Damagelog:EventHook("TTTC4Arm")
	Damagelog:EventHook("TTTC4Disarm")
	Damagelog:EventHook("TTTC4Destroyed")
	Damagelog:EventHook("TTTC4Pickup")
else
	Damagelog:AddFilter("filter_show_c4", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("color_c4", Color(128, 64, 0))
end

local event = {}

event.Type = "C4"

function event:TTTC4Arm(bomb, ply)
	event.CallEvent({
		[1] = 1,
		[2] = ply:Nick(),
		[3] = ply:GetRole(),
		[4] = ply:SteamID(),
		[5] = IsValid(bomb:GetOwner()) and bomb:GetOwner():Nick() or "<Disconnected>"
	})
end

function event:TTTC4Disarm(bomb, result, ply)
	event.CallEvent({
		[1] = 2,
		[2] = ply:Nick(),
		[3] = ply:GetRole(),
		[4] = ply:SteamID(),
		[5] = IsValid(bomb:GetOwner()) and bomb:GetOwner():Nick() or "<Disconnected>",
		[6] = result
	})
end

function event:TTTC4Destroyed(bomb, ply)
	event.CallEvent({
		[1] = 5,
		[2] = ply:Nick(),
		[3] = ply:GetRole(),
		[4] = ply:SteamID(),
		[5] = IsValid(bomb:GetOwner()) and bomb:GetOwner():Nick() or "<Disconnected>"
	})
end

function event:TTTC4Pickup(bomb, ply)
	event.CallEvent({
		[1] = 3,
		[2] = ply:Nick(),
		[3] = ply:GetRole(),
		[4] = ply:SteamID(),
		[5] = IsValid(bomb:GetOwner()) and bomb:GetOwner():Nick() or "<Disconnected>"
	})
end

function event:Initialize()
	for k,v in pairs(weapons.GetList()) do
		if v.ClassName == "weapon_ttt_c4" then
			local old_stick = v.BombStick
			local old_drop = v.BombDrop
			local function LogC4(bomb)
				event.CallEvent({
					[1] = 4,
					[2] = bomb.Owner:Nick(),
					[3] = bomb.Owner:GetRole(),
					[4] = bomb.Owner:SteamID()
				})
			end
			v.BombStick = function(bomb)
				LogC4(bomb)
				old_stick(bomb)
			end
			v.BombDrop = function(bomb)
				LogC4(bomb)
				old_drop(bomb)
			end
		end
	end
end

function event:ToString(v)
	if v[1] == 1 then
		return string.format(TTTLogTranslate(GetDMGLogLang, "C4Armed"), v[2], Damagelog:StrRole(v[3]), v[5])
	elseif v[1] == 2 then
		return string.format(TTTLogTranslate(GetDMGLogLang, "C4Disarmed"), v[2], Damagelog:StrRole(v[3]), v[5], v[6] and TTTLogTranslate(GetDMGLogLang, "with") or TTTLogTranslate(GetDMGLogLang, "without"))
	elseif v[1] == 3 then
		return string.format(TTTLogTranslate(GetDMGLogLang, "C4PickedUp"), v[2], Damagelog:StrRole(v[3]), v[5])
	elseif v[1] == 4 then
		return string.format(TTTLogTranslate(GetDMGLogLang, "C4Planted"), v[2], Damagelog:StrRole(v[3]))
	elseif v[1] == 5 then
		return string.format(TTTLogTranslate(GetDMGLogLang, "C4Destroyed"), v[2], Damagelog:StrRole(v[3]), v[5])
	end
end

function event:IsAllowed(tbl)
	return Damagelog.filter_settings["filter_show_c4"]
end

function event:Highlight(line, tbl, text)
	return table.HasValue(Damagelog.Highlighted, tbl[3])
end

function event:GetColor(tbl)
	return Damagelog:GetColor("color_c4")
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)
	line:ShowCopy(true, { tbl[2], tbl[4] })
end

Damagelog:AddEvent(event)