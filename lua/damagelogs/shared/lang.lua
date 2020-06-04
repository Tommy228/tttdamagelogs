DamagelogLang = DamagelogLang or {}

for _, v in pairs(file.Find("damagelogs/shared/lang/*.lua", "LUA")) do
    local f = "damagelogs/shared/lang/" .. v

    if SERVER then
        AddCSLuaFile(f)
    end

    include(f)
end

function TTTLogTranslate(GetDMGLogLang, phrase, nomissing)
    local f = GetDMGLogLang

    if Damagelog.ForcedLanguage == "" then
        if not DamagelogLang[f] then
            f = "english"
        end
    else
        f = Damagelog.ForcedLanguage
    end

    return DamagelogLang[f][phrase] or DamagelogLang["english"][phrase] or LANG.TryTranslation(phrase) or not nomissing and "Missing: " .. tostring(phrase)
end