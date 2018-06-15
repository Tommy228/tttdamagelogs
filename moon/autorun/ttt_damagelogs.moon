AddCSLuaFile()

export dmglog = {}

include('tttdamagelogs/sh_main.lua')

if SERVER  
  AddCSLuaFile('tttdamagelogs/sh_main.lua')
  AddCSLuaFile('tttdamagelogs/cl_main.lua')
  include('tttdamagelogs/sv_main.lua')
else
  include('tttdamagelogs/cl_main.lua')