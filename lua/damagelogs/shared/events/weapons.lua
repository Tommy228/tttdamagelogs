if SERVER then
	Damagelog:EventHook("TTTOrderedEquipment")
else
	Damagelog:AddFilter("filter_show_purchases", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("color_purchases", Color(128, 0, 128, 255))
end

local event = {}

event.Type = "WEP"

function event:TTTOrderedEquipment(ply, ent, is_item)
	self.CallEvent({
		[1] = ply:GetDamagelogID(),
		[2] = is_item,
		[3] = ent
	})
end

if CLIENT then
	hook.Add("Initialize", "Damagelog_InitializeEventWeapon", function()
		event.Equips = {
			[EQUIP_RADAR] = TTTLogTranslate(GetDMGLogLang, "Radar"),
			[EQUIP_ARMOR] = TTTLogTranslate(GetDMGLogLang, "Armor"),
			[EQUIP_DISGUISE] = TTTLogTranslate(GetDMGLogLang, "Disguiser")
		}
	end)
end

function event:ToString(v, roles)
	local weapon = Damagelog.weapon_table[v[3]] or tostring(v[3])
	if tonumber(weapon) then
		weapon = tonumber(weapon)
		if event.Equips[weapon] then
			weapon = event.Equips[weapon]
		end
	elseif string.sub(weapon, 1, 6) == "Weapon" then
		weapon = TTTLogTranslate(GetDMGLogLang, weapon)
	end
	local ply = Damagelog:InfoFromID(roles, v[1])
	return string.format(TTTLogTranslate(GetDMGLogLang, "HasBought"), ply.nick, Damagelog:StrRole(ply.role), weapon) 
end

function event:IsAllowed(tbl)
	return Damagelog.filter_settings["filter_show_purchases"]
end

function event:Highlight(line, tbl, text)
	return table.HasValue(Damagelog.Highlighted, tbl[1])
end

function event:GetColor(tbl)
	return Damagelog:GetColor("color_purchases")
end

function event:RightClick(line, tbl, roles, text)
	line:ShowTooLong(true)
	local ply = Damagelog:InfoFromID(roles, tbl[1])
	line:ShowCopy(true,{ ply.nick, util.SteamIDFrom64(ply.steamid64) })
end

Damagelog:AddEvent(event)