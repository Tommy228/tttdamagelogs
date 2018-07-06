AddCSLuaFile('sh_include_helpers.lua')
include('sh_include_helpers.lua')

modules = {
    'utils'
    'debug'
    'menu'
    'mysql'
    'damagetab'
    'translations'
    'events'
}

for module in *modules
    dmglog.IncludeModule(module)