dmglog.AddLanguage = (name using nil) ->
    print("langs/#{name}.lua")
    AddCSLuaFile("langs/#{name}.lua")