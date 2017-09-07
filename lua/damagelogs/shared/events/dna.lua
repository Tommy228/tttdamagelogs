if SERVER then
	Damagelog:EventHook("TTTFoundDNA")
else
	Damagelog:AddFilter("filter_show_dna", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("color_dna", Color(20,200,20))
end

local event = {}

event.Type = "DNA"

function event:TTTFoundDNA(ply, dna_owner, ent)
	local name = ent:GetClass()
	if name == "prop_ragdoll" then
		name = CORPSE.GetPlayerNick(ent, TTTLogTranslate(GetDMGLogLang, "PlayerDisconnected")) .. TTTLogTranslate(GetDMGLogLang, "sbody") -- Think of a better translation way since it's always english
	end
	self.CallEvent({
		[1] = ply:GetDamagelogID(),
		[2] = dna_owner:GetDamagelogID(),
		[3] = name
	})
end

function event:ToString(v, roles)
	local ply = Damagelog:InfoFromID(roles, v[1])
	local dna_owner = Damagelog:InfoFromID(roles, v[2])
	local ent = Damagelog:GetWeaponName(v[3]) or v[3]
	return string.format(TTTLogTranslate(GetDMGLogLang, "DNAretrieved"), ply.nick, Damagelog:StrRole(ply.role), dna_owner.nick, Damagelog:StrRole(dna_owner.role), ent)
end

function event:IsAllowed(tbl)
	return Damagelog.filter_settings["filter_show_dna"]
end

function event:Highlight(line, tbl, text)
	if table.HasValue(Damagelog.Highlighted, tbl[1]) or table.HasValue(Damagelog.Highlighted, tbl[2]) then
		return true
	end
	return false
end

function event:GetColor(tbl)
	return Damagelog:GetColor("color_dna")
end

function event:RightClick(line, tbl, roles, text)
	line:ShowTooLong(true)
	local ply = Damagelog:InfoFromID(roles, tbl[1])
	local dna_owner = Damagelog:InfoFromID(roles, tbl[2])
	line:ShowCopy(true, { ply.nick, util.SteamIDFrom64(ply.steamid64) }, { dna_owner.nick, util.SteamIDFrom64(dna_owner.steamid64) })
end

Damagelog:AddEvent(event)