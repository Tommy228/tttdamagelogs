PANEL =

    Init: () =>
        @AddColumn(dmglog.GetTranslation('listview_time'))\SetFixedWidth(40)
        @AddColumn(dmglog.GetTranslation('listview_type'))\SetFixedWidth(40)
        @AddColumn(dmglog.GetTranslation('listview_event'))\SetFixedWidth(529)
        @AddColumn('')\SetFixedWidth(30)

    DisplayRoundEvents: (roundEvents) =>
        for roundEvent in *roundEvents.eventsList
            displayedRoundTime = string.FormattedTime(roundEvent.roundTime, "%02i:%02i")
            displayedType = roundEvent.displayedType
            text = roundEvent\ToString(roundEvents.roundPlayers)
            @AddLine(displayedRoundTime, displayedType, text)

vgui.Register('DamagelogListView', PANEL, 'DListView')