dmglog.events = dmglog.events or {} -- todo rename

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

    ShouldBeDisplayed: (text, roundPlayers) =>
        if @@filters
            for filter in *@@filters
                if not filter\Enabled! or filter.predicate(self, text, roundPlayers)
                    return false
        return true

    @AddServerHook: (hookName, callback) =>
        hook.Add(hookName, "TTTDamagelogs_Event_#{@id}", callback)

    @AddFilter:
        do
            if CLIENT
                (name, defaultValue, translationKey, predicate) =>
                    if not @filters
                        @filters = {}
                    filter = dmglog.CreateFilter(name, defaultValue, translationKey, predicate)
                    table.insert(@filters, filter)
            else
                () => -- NO-OP        

    @AddBasicFilter: (name, defaultValue, translationkey) =>
        predicate = () -> true
        @AddFilter(name, defaultValue, translationkey, predicate)

dmglog.RegisterEvent = (event) ->
    id = table.insert(dmglog.events, event)
    event.__class.id = id  
    return event
 
dmglog.CallEvent = (event) ->
    currentRound = dmglog.eventsHandler\GetCurrentRound!
    currentRound\AddEvent(event)