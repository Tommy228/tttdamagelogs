dmglog.IncludeSharedFile('sh_event.lua')
dmglog.IncludeSharedFile('sh_round_player.lua')
dmglog.IncludeSharedFile('sh_round_players.lua')
dmglog.IncludeSharedFile('sh_round_events.lua')
dmglog.IncludeSharedFile('sh_networking.lua')

dmglog.IncludeSharedFile('events/damage.lua')

if SERVER
    include('sv_events_handler.lua')