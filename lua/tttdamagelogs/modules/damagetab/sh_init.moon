AddCSLuaFile('cl_damagetab.lua')
AddCSLuaFile('vgui/cl_selection_panel.lua')
AddCSLuaFile('vgui/cl_dmglogs_view.lua')

if CLIENT
    include('cl_damagetab.lua')
    include('vgui/cl_selection_panel.lua')
    include('vgui/cl_dmglogs_view.lua')