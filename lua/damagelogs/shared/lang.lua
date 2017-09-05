DamagelogLang = DamagelogLang or {}

for k,v in pairs(file.Find("damagelogs/shared/lang/*.lua", "LUA")) do
	f = "damagelogs/shared/lang/"..v
	if SERVER then
		AddCSLuaFile(f)
	end
	include(f)
end

function TTTLogTranslate(GetDMGLogLang, phrase)
	f = GetDMGLogLang
	if !DamagelogLang[f] then
		f = "english"
	end
	return DamagelogLang[f][phrase] or "Missing: "..tostring(phrase)
end