AddCSLuaFile('cl_translations_service.lua')
AddCSLuaFile('sh_translations_service.lua')

if CLIENT
    include('cl_translations_service.lua')

if SERVER
    include('sv_translations_service.lua')

include('sh_translations_service.lua')