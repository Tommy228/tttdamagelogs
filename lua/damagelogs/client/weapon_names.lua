Damagelog.NamesTable = Damagelog.NamesTable or {}

function Damagelog:GetWeaponName(class)
    return self.NamesTable[class] or TTTLogTranslate(GetDMGLogLang, class) or class
end

local function UpdateWeaponNames()
    table.Empty(Damagelog.NamesTable)
    local entsList = {}
    table.Add(entsList, weapons.GetList())
    table.Add(entsList, scripted_ents.GetList())
    for k,v in pairs(entsList) do
        local printName = v.PrintName
        local class = v.ClassName
        if (not class) or (not printName) then continue end
        local translated = LANG.TryTranslation(printName)
        if not translated then
            translated = LANG.TryTranslation(class)
        end
        Damagelog.NamesTable[class] = translated or printName
    end
end
hook.Add("TTTLanguageChanged", "DL_WeaponNames", UpdateWeaponNames)

-- I kinda missed stupid codes like this
local function GetLangInitFunction()
    local LangInit = LANG.Init
    function LANG.Init(...)
        local res = LangInit(...)
        -- "It ain't stupid if it works", they say
        UpdateWeaponNames()
        return res
    end
end
hook.Add("Initialize", "DL_WeaponNames", GetLangInitFunction)