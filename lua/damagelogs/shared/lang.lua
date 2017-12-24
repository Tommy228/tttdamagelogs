DamagelogLang = DamagelogLang or {}

for k,v in pairs(file.Find("damagelogs/shared/lang/*.lua", "LUA")) do
	local f = "damagelogs/shared/lang/"..v
	if SERVER then
		AddCSLuaFile(f)
	end
	include(f)
end

function TTTLogTranslate(GetDMGLogLang, phrase)
	local f = GetDMGLogLang
	if Damagelog.ForcedLanguage == "" then
		if !DamagelogLang[f] then
			f = "english"
		end
	else
		f = Damagelog.ForcedLanguage
	end
	return DamagelogLang[f][phrase] or "Missing: "..tostring(phrase)
end
