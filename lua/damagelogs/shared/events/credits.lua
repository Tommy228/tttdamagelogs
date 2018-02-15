if SERVER then
	Damagelog:EventHook("TTTAddCredits")
	Damagelog:EventHook("Initialize")
else
	Damagelog:AddFilter("filter_show_credits", DAMAGELOG_FILTER_BOOL, false)
	Damagelog:AddColor("color_credits", Color(255,155,0))
end

local event = {}

event.Type = "CRED"

function event:TTTAddCredits(ply, credits)
	if credits == 0 then return end
	self.CallEvent({
		[1] = ply:GetDamagelogID(),
		[2] = credits
	})
end

function event:Initialize()
	local plymeta = FindMetaTable( "Player" )
	if not plymeta then Error("FAILED TO FIND PLAYER TABLE") return end
	function plymeta:AddCredits(amt)
		self:SetCredits(self:GetCredits() + amt)
		hook.Call("TTTAddCredits", GAMEMODE, self, amt)
	end
end

function event:ToString(v, roles)
	local ply = Damagelog:InfoFromID(roles, v[1])
	return string.format(TTTLogTranslate(GetDMGLogLang, "UsedCredits"), ply.nick, Damagelog:StrRole(ply.role), v[2]>0 and TTTLogTranslate(GetDMGLogLang, "received") or TTTLogTranslate(GetDMGLogLang, "used"), v[2]>0 and v[2] or -v[2], v[2] > 1 and "s" or "")
end

function event:IsAllowed(tbl)
	return Damagelog.filter_settings["filter_show_credits"]
end

function event:Highlight(line, tbl, text)
	return table.HasValue(Damagelog.Highlighted, tbl[1])
end

function event:GetColor(tbl)
	return Damagelog:GetColor("color_credits")
end

function event:RightClick(line, tbl, roles, text)
	line:ShowTooLong(true)
	local ply = Damagelog:InfoFromID(roles, tbl[1])
	line:ShowCopy(true,{ ply.nick, util.SteamIDFrom64(ply.steamid64) })
end

Damagelog:AddEvent(event)
