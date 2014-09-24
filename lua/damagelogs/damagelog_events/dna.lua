

if SERVER then
	Damagelog:EventHook("TTTFoundDNA")
else
	Damagelog:AddFilter("Show DNA", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("DNA", Color(0,255,0))
end

local event = {}

event.Type = "DNA"

function event:TTTFoundDNA(ply, dna_owner, ent)
	local name = ent:GetClass()
	if name == "prop_ragdoll" then
		name = CORPSE.GetPlayerNick(ent, "<Player disconnected>")
	end
	self.CallEvent({
		[1] = ply:Nick(),
		[2] = ply:GetRole(),
		[3] = ply:SteamID(),
		[4] = dna_owner:Nick(),
		[5] = dna_owner:GetRole(),
		[6] = dna_owner:SteamID(),
		[7] = name
	})
end

function event:ToString(v)
	local ent = Damagelog.weapon_table[v[7]] or tostring(v[7])
	return string.format("%s [%s] has retreived the DNA of %s [%s] from the body of %s", v[1], Damagelog:StrRole(v[2]), v[4], Damagelog:StrRole(v[5]), ent)
end

function event:IsAllowed(tbl)
	local pfilter = Damagelog.filter_settings["Filter by player"]
	if pfilter then
		if not (tbl[6] == pfilter or tbl[3] == pfilter) then
			return false
		end
	end
	local dfilter = Damagelog.filter_settings["Show DNA"]
	if not dfilter then return false end
	return true
end

function event:GetColor(tbl)
	return Damagelog:GetColor("DNA")
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)
	line:ShowCopy(true, { tbl[1], tbl[3] }, { tbl[4], tbl[6] })
end

Damagelog:AddEvent(event)