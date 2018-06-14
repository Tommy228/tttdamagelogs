dmglog.IncludeSharedFile = (file) ->
    include(file)
    AddCSLuaFile(file)

IncludeModule = (name) ->
    initFilePath = "modules/#{name}/sh_init.lua"
    dmglog.IncludeSharedFile(initFilePath)

IncludeModule('menu')
IncludeModule('damagetab')
IncludeModule('translations')
IncludeModule('events')