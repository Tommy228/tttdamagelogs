IncludeModule = (name using nil) ->
    initFilePath = "modules/#{name}/sh_init.lua"
    include(initFilePath)
    AddCSLuaFile(initFilePath)

IncludeModule('menu')
IncludeModule('damagetab')
IncludeModule('translations')
IncludeModule('events')