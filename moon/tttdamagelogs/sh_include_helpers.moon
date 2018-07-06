dmglog.IncludeSharedFile = (file) ->
    AddCSLuaFile(file)
    return include(file)

dmglog.IncludeClientFile = (file) ->
    AddCSLuaFile(file) if SERVER
    return include(file) if CLIENT

dmglog.IncludeServerFile = (file) ->
    return include(file) if SERVER

dmglog.IncludeModule = (name) ->
    initFilePath = "modules/#{name}/sh_init.lua"
    dmglog.IncludeSharedFile(initFilePath)