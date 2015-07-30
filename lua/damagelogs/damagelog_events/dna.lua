

if SERVER then
	Damagelog:EventHook("TTTFoundDNA")
else
	Damagelog:AddFilter("Show DNA", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("DNA", Color(0,255,0))
end

local event = {}

event.Type = "DNA"

function event:TTTFoundDNA(ply, dna_owner, ent)
	local name = (IsValid(ent) and ent:GetClass() or "No Body") -- this should NEVER return "no body" but just in case
	if name == "prop_ragdoll" then
		name = CORPSE.GetPlayerNick(ent, "<Player disconnected>")
	end
	self.CallEvent({
		[1] = (IsValid(ply) and ply:Nick() or "<Disconnected Retriever>"),
		[2] = (IsValid(ply) and ply:GetRole() or "disconnected"),
		[3] = (IsValid(ply) and ply:SteamID() or "<Disconnected Retriever>"),
		[4] = (IsValid(dna_owner) and dna_owner:Nick() or "<Disconnected Victim>"),
		[5] = (IsValid(dna_owner) and dna_owner:GetRole() or "disconnected"),
		[6] = (IsValid(dna_owner) and dna_owner:SteamID() or "<Disconnected Victim>"),
		[7] = name
	})
end

function event:ToString(v)
	local ent = Damagelog.weapon_table[v[7]] or tostring(v[7])
	return string.format("%s [%s] has retrieved the DNA of %s [%s] from %s's body", v[1], Damagelog:StrRole(v[2]), v[4], Damagelog:StrRole(v[5]), ent)
end

function event:IsAllowed(tbl)
	return Damagelog.filter_settings["Show DNA"]
end

function event:Highlight(line, tbl, text)
	if table.HasValue(Damagelog.Highlighted, tbl[1]) or table.HasValue(Damagelog.Highlighted, tbl[4]) then
		return true
	end
	return false
end

function event:GetColor(tbl)
	return Damagelog:GetColor("DNA")
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)
	line:ShowCopy(true, { tbl[1], tbl[3] }, { tbl[4], tbl[6] })
end

Damagelog:AddEvent(event)