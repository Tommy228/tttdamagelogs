dmglog.Events = dmglog.Events or {}

class dmglog.Event

    ToString: () => ''

dmglog.RegisterEvent = (event) ->
    id = table.insert(dmglog.Events, event)
    event.__class.id = id

dmglog.CallEvent = (event) ->
    currentRound = dmglog.eventsHandler\GetCurrentRound!
    currentRound\AddEvent(event)  