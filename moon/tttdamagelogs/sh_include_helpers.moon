dmglog.IncludeSharedFile = (file) ->
    include(file)
    AddCSLuaFile(file)

dmglog.IncludeClientFile = (file) ->
    include(file) if CLIENT
    AddCSLuaFile(file) if SERVER

dmglog.IncludeServerFile = (file) ->
    include(file) if SERVER

dmglog.IncludeModule = (name) ->
    initFilePath = "modules/#{name}/sh_init.lua"
    dmglog.IncludeSharedFile(initFilePath)




