dmglog.IncludeSharedFile('sh_event.lua')
dmglog.IncludeSharedFile('sh_event_player.lua')
dmglog.IncludeSharedFile('sh_round_events.lua')

dmglog.IncludeSharedFile('events/damage.lua')

if SERVER
    include('sv_round_events.lua')