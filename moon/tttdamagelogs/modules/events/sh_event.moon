dmglog.Events = dmglog.Events or {}

class dmglog.Event

    new: (roundTime) =>
        if roundTime
            @roundTime = roundTime
        else if SERVER
            currentRound = dmglog.eventsHandler\GetCurrentRound!
            @roundTime = currentRound.currentTime

    ToString: () => ''

    GetRoleString: (role) =>
        return string.lower(dmglog.GetTranslatedRoleString(role))

    SetDisplayedTypeKey: (key) =>
        if CLIENT
            @displayedType = dmglog.GetTranslation(key)

    @AddServerHook: (hookName, callback) =>
        hook.Add(hookName, "TTTDamagelogs_Event_#{@__class.id}", callback)

dmglog.RegisterEvent = (event) ->
    id = table.insert(dmglog.Events, event)
    event.__class.id = id
    return event

dmglog.CallEvent = (event) ->
    currentRound = dmglog.eventsHandler\GetCurrentRound!
    currentRound\AddEvent(event)